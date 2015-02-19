# encoding: utf-8
class ApoyoDocente::GestionAsistenciaAlumnosController < ApplicationController

    before_filter :iniciar
        protect_from_forgery :except => [
                                        :ver_asistencia_seccion,
                                        :registrar_asistencia_seccion,
                                        :ver_asistencia_alumno,
                                        :buscar_alumno,
                                        :ver_asistencia,
                                        :ver_asistencia_nota_seccion

                                    ]
    def asistencia
        if current_role_can?(:direccion_escuela)
            @sedes = Sede.all(id: Sede::SEDES_VIGENTES)
        else
            @sedes = Sede.all(:id => current_user[:sede_id])
        end
        @alumnos = []        

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
            seccion_id = params[:filtro][:seccion_id].to_i
            @seccion = Seccion.find_by_id(seccion_id)
            @alumnos = AlumnoInscritoSeccion.all(:fields => [:id, :seccion_dictada_id, :alumno_plan_estudio_id,:estado], :seccion_dictada => {:seccion_id => @seccion.id, :periodo_id => params[:filtro][:periodo_id].to_i})
        
        end
    end

    def ver_asistencia_seccion
        if current_role_can?(:direccion_escuela)
            @sedes = Sede.all(id: Sede::SEDES_VIGENTES)
        else
            @sedes = Sede.all(:id => current_user[:sede_id])
        end
        @alumnos = []        

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
            seccion_id = params[:filtro][:seccion_id].to_i
            @seccion = Seccion.find_by_id(seccion_id)
            @alumnos = AlumnoInscritoSeccion.all(:fields => [:id, :seccion_dictada_id, :alumno_plan_estudio_id,:estado], :seccion_dictada => {:seccion_id => @seccion.id, :periodo_id => params[:filtro][:periodo_id].to_i})
        
        end
    end

    def registrar_asistencia_seccion

        asistencia = params[:alumnos]
        asistencia_actualizada = params[:alumnos_actualizado]
        unless asistencia_actualizada.blank?
            asistencia_actualizada.each do |i|
                asistencia_id = i[0].to_i
                puts asistencia_id.inspect.red
                asistencia_ac = Asistencia.find_by_id(asistencia_id)
                puts asistencia_ac.inspect.red 
                i[1].each do |a|
                    clase = Clase.find_by_id(a[:clase_id].to_i)
                    Asistencia.transaction do
                        asistencia_ac.horas_asistidas  = a[:horas].to_i
                        asistencia_ac.horas_ausentadas = clase.horas.to_i - a[:horas].to_i
                        if a[:horas].to_i == 0
                            asistencia_ac.estado = Asistencia::AUSENTADA
                        else
                            asistencia_ac.estado = Asistencia::ASISTIDA
                        end
                        asistencia_ac.save
                    end
                end
            end
        end
        unless asistencia.blank?
            asistencia.each do |i|
                 alumno_inscrito_seccion_id = i[0].to_i
                i[1].each do |a|
                    clase = Clase.find_by_id(a[:clase_id].to_i)
                    Asistencia.transaction do
                        asistencia = Asistencia.new
                        asistencia.horas_asistidas  = a[:horas].to_i
                        asistencia.horas_ausentadas = clase.horas.to_i - a[:horas].to_i
                        asistencia.alumno_inscrito_seccion_id = alumno_inscrito_seccion_id
                        asistencia.clase_id = clase.id
                        if a[:horas].to_i == 0
                            asistencia.estado = Asistencia::AUSENTADA
                        else
                            asistencia.estado = Asistencia::ASISTIDA
                        end
                        asistencia.save
                    end
                    clase.estado = Clase::REALIZADA
                    clase.save
                end
            end
        end

        flash[:notice] = "La Asistencia ha sido ingresada Exitosamente."
        redirect_to apoyo_docente_ver_asistencia_seccion_path

        rescue Exception => e
            puts e.inspect.red
            flash[:error] = "Ha ocurrido un error y no ha sido posible registrar la asistencia."
            redirect_to apoyo_docente_ver_asistencia_seccion_path
    end

    def ver_asistencias_plan_estudio

    end

    def buscar_alumno
        unless params[:busqueda].blank?
            usuario = Usuario.first rut: params[:busqueda]
            raise Excepciones::DatosNoExistentesError, "El Rut ingresado no existe" if usuario.blank?
            raise Excepciones::DatosNoExistentesError, "El Rut ingresado no tiene un alumno asociado" if usuario.alumno.blank?

            redirect_to apoyo_docente_ver_asistencia_alumno_path(usuario.alumno.id)
        end

        rescue Excepciones::DatosNoExistentesError => e
            flash[:error] = e.message  
    end

    def ver_asistencia_alumno
        alumno_id = params[:alumno_id].to_i
        
        alumno = Alumno.find_by_id alumno_id
        @alumno_actual = alumno
        @instituciones  = InstitucionSede.all(:fields => [:id])

        @alumno_plan_estudios = alumno.alumno_plan_estudio
       
        @secciones_inscritas = []

        if params.has_key?("plan_estudio")
            periodo = Periodo::en_curso
            @alumno_plan_estudio = AlumnoPlanEstudio.find_by_id params[:plan_estudio].to_i
           # @asignaturas = @alumno_plan_estudio.plan_estudio.asignaturas.sort_by{|i| i.semestre}

            @secciones_inscritas = AlumnoInscritoSeccion.all(:fields => [:id, :seccion_dictada_id, :alumno_plan_estudio_id,:estado],
                    :alumno_plan_estudio => {:id => @alumno_plan_estudio.id},
                    :seccion_dictada => {:periodo_id => periodo.id }
                    )

            @total_planificaciones  = 0
            @secciones_inscritas.each do |i|
                @total_planificaciones =  i.seccion.total_evaluaciones_planificadas if i.seccion.total_evaluaciones_planificadas > @total_planificaciones
            end
        end

    end

    def ver_asistencia
        if current_role_can?(:direccion_escuela)
            @sedes = Sede.all(id: Sede::SEDES_VIGENTES)
        else
            @sedes = Sede.all(:id => current_user[:sede_id])
        end
        @periodos = Periodo.all(:order => [:anio.desc, :semestre.desc])
        @secciones_inscritas = []
        
        # Filtro Nuevo
        if params.has_key?("filtro")
            periodo = params[:filtro][:periodo_id].to_i
            @plan_estudio = PlanEstudio.find_by_id(params[:filtro][:plan_estudio_id].to_i)
            @asignaturas = @plan_estudio.asignaturas 
            

            @secciones_inscritas = AlumnoInscritoSeccion.all(
                                                :estado.not =>[AlumnoInscritoSeccion::CONVALIDADA, AlumnoInscritoSeccion::HOMOLOGADA],
                                                :seccion_dictada => {
                                                    :periodo_id => periodo ,
                                                    :asignatura => @asignaturas,
                                                    :seccion => {
                                                        :institucion_sede => {:sede_id => params[:filtro][:sede_id].to_i }
                                                    }
                                                }
                                    )

            
            @total_planificaciones  = 0
            @secciones_inscritas.each do |i|
                @total_planificaciones =  i.seccion.total_evaluaciones_planificadas if i.seccion.total_evaluaciones_planificadas > @total_planificaciones
            end
        end
    end

    def ver_asistencia_nota_seccion
        
        if current_role_can?(:direccion_escuela)
            @sedes = Sede.all(id: Sede::SEDES_VIGENTES)
        else
            @sedes = Sede.all(:id => current_user[:sede_id])
        end
        @periodos = Periodo.all(:order => [:anio.desc, :semestre.desc])
        @secciones_inscritas = []        

        if params.has_key?("filtro")
            seccion_id = params[:filtro][:seccion_id].to_i
            periodo_id = params[:filtro][:periodo_id].to_i
            @seccion = Seccion.find_by_id(seccion_id)
            seccion_dictada = SeccionDictada.find_by_seccion_id(@seccion.id)
            @asignatura = seccion_dictada.asignatura
            @secciones_inscritas = AlumnoInscritoSeccion.all(:fields => [:id, :seccion_dictada_id, :alumno_plan_estudio_id,:estado],
                    :seccion_dictada => {:seccion_id => @seccion.id})
        
            @total_planificaciones  = 0
            @secciones_inscritas.each do |i|
                @total_planificaciones =  i.seccion.total_evaluaciones_planificadas if i.seccion.total_evaluaciones_planificadas > @total_planificaciones
            end
        end
    end

end