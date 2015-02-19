# encoding: utf-8
class AsistenteSocial::GestionExalumnoController < ApplicationController

	def buscar_alumno
        unless params[:busqueda].blank?
            @usuario = Usuario.first rut: params[:busqueda]
            raise Excepciones::DatosNoExistentesError, "El Rut ingresado no existe" if @usuario.blank?
            raise Excepciones::DatosNoExistentesError, "El Rut ingresado no tiene un alumno asociado" if @usuario.alumno.blank?
            @alumno = @usuario.alumno 
            @alumno_plan_estudios = AlumnoPlanEstudio.all(
                                                        :fields => [:id, :alumno_id, :estado, :institucion_sede_plan_id ],
                                                        :alumno_id => @alumno.id
														)
            raise Excepciones::DatosNoExistentesError, "El Alumno no cuenta con un plan estudio en estado egresado" if @alumno_plan_estudios.blank?

        end

        rescue Excepciones::DatosNoExistentesError => e
            flash[:error] = e.message
    end

    def ingresar_antecedente
    	
        unless params[:alumno_plan_estudio_id].blank?
        	@alumno_plan_estudio 	= AlumnoPlanEstudio.first id: params[:alumno_plan_estudio_id].to_i
        	@usuario 				= @alumno_plan_estudio.alumno.datos_personales
        	@us_apoderado 			= @usuario.alumno.apoderado.datos_personales
        	@periodos				= Periodo.all(fields: [:id,:anio,:semestre], :order => [ :anio.desc ])
        	@antecedentes           = Egresado.all(:alumno_plan_estudio_id => @alumno_plan_estudio.id) 

        end
        rescue Excepciones::DatosNoExistentesError => e
            flash[:error] = e.message
            redirect_to asistente_social_buscar_alumno_path
    end

    def registrar_antecedente
    	unless params[:antecedente].blank?
            begin
                Egresado.create params[:antecedente]
                flash[:notice] = "Antecedentes Exalumnos ingresado correctamente"
            rescue Exception => e
                flash[:error] = "Por favor complete toda la información correctamente"
            end
        end
        redirect_to asistente_social_ingresar_antecedente_path(params[:antecedente][:alumno_plan_estudio_id].to_i)
    end
    def eliminar_antecedente
    	alum_pl_es = params[:alumno_plan_estudio_id]
		Egresado.transaction do
			e = Egresado.get params[:egresado_id]	
			if e.usuario.id == current_user_object.id
				e.destroy
			end
		end
		flash[:notice] = "Antecedente eliminado correctamente"
		redirect_to asistente_social_ingresar_antecedente_path(alum_pl_es)
    	rescue Exception => e 
    		flash[:error] = "Ocurrió un error al intentar eliminar el antecedente" 
    		redirect_to asistente_social_ingresar_antecedente_path(alum_pl_es)
    	
    end
    def show
        @instituciones_sedes = InstitucionSede.all(:institucion_id => 1)
        @periodos            = Periodo.all(:order => [:anio.desc])
        unless params[:institucion_sede_id].blank?
            @periodo            = Periodo.first id: params[:periodo_id].to_i
            institucion_sede    = InstitucionSede.first id: params[:institucion_sede_id].to_i
            @sede               = institucion_sede.sede
            @acciones           = true
            @antecedentes  = Egresado.all(
                                            :periodo_id => @periodo.id,
                                            :alumno_plan_estudio => {
                                                :institucion_sede_plan => {
                                                    :institucion_sede_id => institucion_sede.id
                                                }
                                            }       
                                        )

            raise Excepciones::DatosNoExistentesError, "No se encontraron resultados para el periodo e institución seleccionados" if @antecedentes.blank?          
        end
        rescue Excepciones::DatosNoExistentesError => e
            flash[:error] = e.message
        rescue Exception => e
            flash[:error] = "Error inesperado favor vuelva a intentarlo #{e}"
    end
end