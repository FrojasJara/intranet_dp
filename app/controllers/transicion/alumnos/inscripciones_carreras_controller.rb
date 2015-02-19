# encoding: utf-8
class Transicion::Alumnos::InscripcionesCarrerasController < ApplicationController

	def editar
		inscripcion_carrera = AlumnoPlanEstudio.get! params[:inscripcion_plan].delete("id")
		usuario_id = params[:usuario_id]
		carrera_dictada_in = params[:carrera_dictada_in]
		carrera_dictada_out = params[:carrera_dictada_out]

		AlumnoPlanEstudio.transaction do
			carrera_dictada = InstitucionSedePlan.first_or_create carrera_dictada_in, carrera_dictada_out.merge({"jornada" => carrera_dictada_in["jornada"], "modalidad" => InstitucionSedePlan::PRESENCIAL})
			inscripcion_carrera.update :institucion_sede_plan => carrera_dictada
		end

		flash[:notice] = "La jornada ha sido cambiada exitosamente."
		redirect_to alumno_obtener_malla_curricular_path usuario_id, inscripcion_carrera.id

	rescue DataMapper::SaveFailureError => e
		flash[:error] = "Ha ocurrido un error al tratar de cambiar la jornada."
		puts e.message
		puts e.resource.errors.inspect
		redirect_to alumno_obtener_malla_curricular_path usuario_id, inscripcion_carrera.id
	rescue Exception => e
		flash[:error] = Excepiones::ERROR_DESCONOCIDO
		puts e.message
		puts e.resource.errors.inspect
		redirect_to alumno_obtener_malla_curricular_path usuario_id, inscripcion_carrera.id		
	end
end