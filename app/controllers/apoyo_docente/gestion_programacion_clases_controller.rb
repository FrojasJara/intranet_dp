# encoding: utf-8
class ApoyoDocente::GestionProgramacionClasesController < ApplicationController


    before_filter :iniciar
    protect_from_forgery :except => [
                                        :ver_programacion_seccion,
                                        :registrar_programacion_seccion,
                                        :ver_horarios_seccion,
                                        :registrar_horarios_seccion,
                                        :seleccionar_acta_firmas
                                    ]

    def ver_programacion_seccion
        if current_role_can?(:direccion_escuela)
            @sedes = Sede.all(id: Sede::SEDES_VIGENTES)
        else
            @sedes = Sede.all(:id => current_user[:sede_id])
        end
        @clases = []

        if params.has_key?("filtro")
            #------> Llenar filtro donde quedo <------------------
            if current_role_can?(:direccion_escuela)
                @sedes = Sede.all(id: Sede::SEDES_VIGENTES)
            else
                @sedes = Sede.all(:id => current_user[:sede_id])
            end
            @filtro = params[:filtro]
            @carrera = PlanEstudio.all(
                                            :fields => [:id, :nombre, :siaa_id_ma], 
                                            :institucion_sede_plan => {
                                                                        :institucion_sede => {:sede_id => @filtro[:sede_id] }
                                                                        },
                                            :coordinadores => {:usuario_id =>current_user[:id]},
                                            :estado => PlanEstudio::VIGENTE,
                                            :order => :siaa_id_ma.asc
                                        )
            @secciones_f   = Seccion.all(
                                    :fields => [:id, :jornada, :numero], 
                                    :links_secciones_dictadas => {
                                                :asignatura_id => @filtro[:asignatura_id].to_i
                                        },
                                    :institucion_sede => {:sede_id => @filtro[:sede_id]},
                                    :numero.not => [Seccion::CONVALIDADA_HOMOLOGADA, Seccion::HISTORIAL_ACADEMICO],
                                    :periodo_id => @filtro[:periodo_id].to_i
                                )
            @plan_estudio_seleccionado = PlanEstudio.find_by_id(@filtro[:plan_estudio_id].to_i)
            @asignaturas = @plan_estudio_seleccionado.asignaturas

            #------> Final del filtro <------------------
            @salas = Sala.all(:fields => [:id, :nombre, :sede_id],:sede_id => current_user[:sede_id])
            @bloques_horarios = BloqueHorario.all(:fields => [:id, :nombre, :hora_inicio, :hora_termino, :periodo_id, :sede_id], :sede_id => current_user[:sede_id], :periodo_id => Periodo::en_curso[:id])
            
        	seccion_id = params[:filtro][:seccion_id].to_i
        	@seccion = Seccion.find_by_id(seccion_id)
            @sede = @seccion.institucion_sede.sede.id
            @periodo = @seccion.periodo_id
            @fusion_padre = @seccion.seccion_padre
            @fusion_hija = @seccion.secciones_hijas

        	@clases = Clase.all(:fields => [:id, :seccion_id, :numero, :fecha_planificada, :horas, :estado], :seccion_id => seccion_id)
            @estados = Clase::ESTADOS
        end
        rescue Exception => e
            puts e.inspect.red
            flash[:error] = "#{e}Ha ocurrido un error y no ha sido posible registrar el horario."
            redirect_to apoyo_docente_ver_programacion_seccion_path

    end

    def registrar_programacion_seccion

		_seccion_id = params[:clase][:seccion_id].to_i
		_clases = params[:clases]
        Clase.transaction do 
    		_clases.each do |i|
    			_nueva_clase = Clase.new
    			_nueva_clase.seccion_id = _seccion_id
    			_nueva_clase.numero = i[:numero].to_i
                _nueva_clase.origen = params[:origen].to_i
    			_nueva_clase.horas = i[:horas].to_i
                _nueva_clase.estado = Clase::PLANIFICADA
    			_nueva_clase.fecha_planificada = i[:fecha_planificada]
    			_nueva_clase.save

                bloques = i[:bloque_horario]
                salas = i[:sala]
                dia = i[:dia]

                bloques.size.times do |num|
                    
                    bloque_horario_id = bloques["#{num}"].to_i
                    sala_id = salas["#{num}"].to_i
                
                    horario = Horario.create(
                                            :bloque_horario_id => bloque_horario_id,
                                            :dia => dia,
                                            :sala_id => sala_id,
                                            :seccion_id => _seccion_id
                                        )

                    horarios_clases = HorariosClase.first_or_create(
                                            :clase_id => _nueva_clase.id,
                                            :horario_id => horario.id 
                                        )
                end
            end
        end

    	flash[:notice] = "La planificación ha sido ingresada Exitosamente."
    	redirect_to apoyo_docente_ver_programacion_seccion_path

    	rescue Exception => e
            puts e.inspect.red
    		flash[:error] = "Ha ocurrido un error y no ha sido posible crear la planificación."
    		redirect_to apoyo_docente_ver_programacion_seccion_path
    end


    def ver_horarios_seccion
    	@institucion_sedes = InstitucionSede.all(:fields => [:id, :sede_id, :institucion_id], :sede_id => current_user[:sede_id])
    	@salas = Sala.all(:fields => [:id, :nombre, :sede_id],:sede_id => current_user[:sede_id])
    	@bloques_horarios = BloqueHorario.all(:fields => [:id, :nombre, :hora_inicio, :hora_termino, :periodo_id, :sede_id], :sede_id => current_user[:sede_id], :periodo_id => Periodo::en_curso[:id])
    	@horarios = []
    	@clases = []
    	if params.has_key?("filtro")
        	seccion_id = params[:filtro][:seccion_id].to_i
        	@seccion = Seccion.find_by_id(seccion_id)
        	@asignatura = @seccion.asignatura_base
        	@clases = Clase.all(:fields => [:id, :seccion_id, :numero, :fecha_planificada, :horas, :estado], :seccion_id => seccion_id)
        	@horarios = Horario.all(:fields => [:id, :dia, :bloque_horario_id, :seccion_id, :sala_id], :seccion_id => seccion_id)
            @horario_clase = HorariosClase.all(:clase => {:seccion_id => seccion_id})
        end
    	
    end

    def registrar_horarios_seccion
        seccion_id = params[:seccion_id].to_i

        clases = []
        clases = params[:horario][0]
        clases.each do |i|
            clase_id = i[0].to_i
            bloques = i[1][:bloques]
            salas = i[1][:salas]
            
            bloques.size.times do |num|

                Horario.transaction do 
                    bloque_horario_id = bloques["#{num}"].to_i
                    sala_id = salas["#{num}"].to_i
                
                    horario = Horario.create(
                                            :bloque_horario_id => bloque_horario_id,
                                            :sala_id => sala_id,
                                            :seccion_id => seccion_id
                                        )

                    horarios_clases = HorariosClase.create(
                                            :clase_id => clase_id,
                                            :horario_id => horario.id 
                                        )
                end
            end

        end
    	
        flash[:notice] = "El horario de las clases fue ingresado exitosamente."
    	redirect_to apoyo_docente_ver_horarios_seccion_path

    	rescue Exception => e
    		flash[:error] = "#{e}Ha ocurrido un error y no ha sido posible registrar el horario."
    		redirect_to apoyo_docente_ver_horarios_seccion_path
    end
    def seleccionar_acta_firmas
        if params.has_key?("fecha")
            @usuario = current_user_object
            @jornada = params[:jornada].to_i
            @fecha_clases = params[:fecha]
            @horarios = HorariosClase.all(
                                    :clase => {
                                                :fecha_planificada => @fecha_clases,
                                                :estado.not => Clase::SUSPENDIDA
                                                },
                                    :horario => {:seccion => {
                                                    :fusion_id => nil,
                                                    :jornada => @jornada,
                                                    :institucion_sede => {:sede_id => @usuario.sede_id} 
                                                }
                                            }
                                    )

            @horarios = @horarios.sort_by{|h| h.horario.bloque_horario.numero and h.clase.seccion.asignatura_base}
            raise Excepciones::DatosNoExistentesError, "No se encontraron Clases para la fecha y jornada indicada" if @horarios.blank?
        end
        rescue Excepciones::DatosNoExistentesError => e
            flash[:error] = "#{e.message}"
            apoyo_docente_acta_de_firmas_path
        rescue Exception => e
            flash[:error] = "La busqueda no se ha podido realizar #{e}"
            apoyo_docente_acta_de_firmas_path
    end
    def reprogramacion
        @seccion            = Seccion.first(:id => params[:id_seccion].to_i)
        @periodo            = @seccion.periodo_id
        @sede               = @seccion.institucion_sede.sede.id
        @salas              = Sala.all(:fields => [:id, :nombre, :sede_id],:sede_id => current_user[:sede_id])
        @bloques_horarios   = BloqueHorario.all(:fields => [:id, :nombre, :hora_inicio, :hora_termino, :periodo_id, :sede_id], :sede_id => current_user[:sede_id], :periodo_id => Periodo::en_curso[:id])

    end
end