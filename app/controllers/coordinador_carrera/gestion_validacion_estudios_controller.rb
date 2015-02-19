# encoding: utf-8
class CoordinadorCarrera::GestionValidacionEstudiosController < ApplicationController
    protect_from_forgery :except => [
                                        :ver_acta_convalidacion
                                    ]

	def ver_acta_convalidacion
		unless params[:busqueda].blank?
            @usuario = Usuario.first rut: params[:busqueda]
            raise Excepciones::DatosNoExistentesError, "El Rut ingresado no existe" if @usuario.blank?
            raise Excepciones::DatosNoExistentesError, "El Rut ingresado no tiene un alumno asociado" if @usuario.alumno.blank?
        	
        	@alumno = @usuario.alumno 
        	@alumno_plan_estudios = AlumnoPlanEstudio.all(
                                                        :fields => [:id, :alumno_id, :estado, :institucion_sede_plan_id ],
                                                        :estado => [Alumno::REGULAR, Alumno::SIN_INSCRIPCION],
                                                        :alumno_id => @alumno.id
                                                        )

        end
        unless params[:alumno_plan_estudio_id].blank?
            @alumno_plan_estudio_seleccionado = AlumnoPlanEstudio.first id: params[:alumno_plan_estudio_id].to_i
            raise Excepciones::DatosNoExistentesError, "No cuenta con un plan de estudio vigente" if @alumno_plan_estudio_seleccionado.blank?
            @datos_validacion = AlumnoInscritoSeccion.all(
                                                        :alumno_plan_estudio_id => @alumno_plan_estudio_seleccionado.id,
                                                        :estado => [AlumnoInscritoSeccion::CONVALIDADA, AlumnoInscritoSeccion::HOMOLOGADA]
                                                        )
            @usuario = Usuario.find_by_id(current_user[:id])
            @institucion_sede = @alumno_plan_estudio_seleccionado.institucion_sede_plan.institucion_sede
            @vicerrector = Usuario.first rol_id: 10
            raise Excepciones::DatosNoExistentesError, "No cuenta con validaciones de estudio" if @datos_validacion.blank?
        end
        rescue Excepciones::DatosNoExistentesError => e
            flash[:error] = e.message 
	end

end