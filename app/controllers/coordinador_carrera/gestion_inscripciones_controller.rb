# encoding: utf-8
class CoordinadorCarrera::GestionInscripcionesController < ApplicationController
    before_filter :iniciar

    protect_from_forgery :except => [
                                        :inscripcion_extraordinaria, 
                                        :registrar_inscripcion_extraordinaria, 
                                        :buscar_alumno,:registrar_nueva_seccion, 
                                        :eliminar_inscripcion
                                    ]

    def buscar_alumno
        unless params[:busqueda].blank?
            usuario = Usuario.first rut: params[:busqueda]
            raise Excepciones::DatosNoExistentesError, "El Rut ingresado no existe" if usuario.blank?
            raise Excepciones::DatosNoExistentesError, "El Rut ingresado no tiene un alumno asociado" if usuario.alumno.blank?

            redirect_to inscripcion_extraordinaria_path(usuario.alumno.id)
        end

        rescue Excepciones::DatosNoExistentesError => e
            flash[:error] = e.message  
    end

    def inscripcion_extraordinaria
    	alumno = Alumno.find_by_id params[:alumno_id].to_i
        @alumno_actual = alumno
        @instituciones  = InstitucionSede.all(:fields => [:id])

    	@alumno_plan_estudios = alumno.alumno_plan_estudio
        @periodos = Periodo.all :order => :anio.desc

    	if params.has_key?("plan_estudio")
    		@alumno_plan_estudio = AlumnoPlanEstudio.find_by_id params[:plan_estudio].to_i
            @periodo = Periodo.first id: params[:periodo_id].to_i
            periodo_id = @periodo.id
    		@asignaturas = @alumno_plan_estudio.plan_estudio.asignaturas.sort_by{|i| i.semestre}

            @asignaturas_secciones = []
        
            @asignaturas.each do |i|
                _secciones_dictadas = i.links_secciones_dictadas(:periodo_id => periodo_id)

                _secciones = []        
                _secciones_dictadas.each do |sd|
                    if sd.seccion.institucion_sede.sede.id == @alumno_plan_estudio.alumno.datos_personales.sede_id
                        _secciones << {
                                        :seccion_id => sd.seccion.id, 
                                        :seccion_dictada_id => sd.id,
                                        :numero_seccion => sd.seccion.numero,
                                        :jornada_seccion => sd.seccion.jornada,
                                        :estado => false
                                    } 
                    end
                end
                _secciones_alumno = AlumnoInscritoSeccion.all(:seccion_dictada => _secciones_dictadas, :alumno_plan_estudio => @alumno_plan_estudio)
                _secciones_alumno.count
                
                _secciones_alumno.each do |i|
                    _secciones.each do |s|
                        if i.seccion_dictada_id == s[:seccion_dictada_id] and i.estado == AlumnoInscritoSeccion::INSCRITA
                            s[:estado] = true 
                            s[:alumno_inscrito_seccion_id] = i.id
                        end
                    end
                end
                @asignaturas_secciones << {
                                            :nivel_asignatura => i.semestre,
                                            :asignatura_id => i.id, 
                                            :nombre => i.nombre, 
                                            :codigo => i.codigo,
                                            :secciones => _secciones                         
                                        }

            end
    	end
    end

    def registrar_inscripcion_extraordinaria
        asignaturas  = params[:asignaturas].to_a
        alumno_plan_estudio_id = params[:alumno_plan_estudio_id].to_i
        alumno_id = params[:alumno_id].to_i
        puts asignaturas.inspect

        AlumnoInscritoSeccion.transaction do 

            asignaturas.each do |a|
                _inscripcion = AlumnoInscritoSeccion.create(
                                                        :alumno_plan_estudio_id => alumno_plan_estudio_id, 
                                                        :seccion_dictada_id => a[1].to_i,
                                                        :estado => AlumnoInscritoSeccion::INSCRITA
                                                        )

            end
            alumno_plan_estudio = AlumnoPlanEstudio.find_by_id(alumno_plan_estudio_id)
            alumno_plan_estudio.estado = Alumno::REGULAR
            alumno_plan_estudio.save
        end

        flash[:notice] = "La Inscripción Fue realizada Exitosamente"
        redirect_to inscripcion_extraordinaria_path(alumno_id)
        
        rescue DataMapper::SaveFailureError => e

            flash[:error] = "Ocurrio un problema, la inscrripcion no fue ingresada"
            redirect_to inscripcion_extraordinaria_path(alumno_id)
    end

    def registrar_nueva_seccion

        seccion = params[:seccion]
        asignatura_id = params[:seccion][:asignatura_id].to_i
        alumno_id = params[:alumno_id].to_i
        docente = nil

        Vicerrectoria::Seccion::guardar_nueva_seccion seccion,docente

        flash[:notice] = "La sección ha sido creada exitosamente, puede proceder a la inscripción."
        redirect_to inscripcion_extraordinaria_path(alumno_id)
        
        rescue Exception => e
            puts e.inspect.red
            flash[:error] = "Ha ocurrido un error, no has sido posible crear la sección."
            redirect_to inscripcion_extraordinaria_path(alumno_id)
    end

    def eliminar_inscripcion
        alumno_inscrito_seccion_id = params[:alumno_inscrito_seccion_id].to_i
        
        AlumnoPlanEstudio.transaction do 
            _inscripcion = AlumnoInscritoSeccion.find_by_id(alumno_inscrito_seccion_id)
            
            alumno_plan_estudio = _inscripcion.alumno_plan_estudio
            _inscripcion.destroy
        end
        
        flash[:notice] = "Se ha eliminado la inscripcion de asignatura del alumno."
        render :json => {:status => true}
        
        rescue Exception => e
            flash[:error] = "No ha sido posible eliminar la inscripcion del alumno."
            render :json => {:status => false}
    end
end

