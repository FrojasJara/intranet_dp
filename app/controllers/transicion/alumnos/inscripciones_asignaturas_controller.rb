# encoding: utf-8
class Transicion::Alumnos::InscripcionesAsignaturasController < ApplicationController

	def crear	
		seccion_in = params[:seccion_in]
		seccion_out = params[:seccion_out]
		_inscripcion_seccion = params[:inscripcion_seccion]

		AlumnoInscritoSeccion.transaction do
			seccion = Seccion.first_or_create seccion_in, seccion_out.merge({"periodo_id" => seccion_in["periodo_id"]})

			seccion_dictada = SeccionDictada.first_or_create({:seccion => seccion}, seccion_in["links_secciones_dictadas"][0].merge({"seccion_id" => seccion.id}))

			inscripcion_seccion = AlumnoInscritoSeccion.new _inscripcion_seccion
			inscripcion_seccion.seccion_dictada = seccion_dictada
			inscripcion_seccion.save
		end

		flash[:notice] = "La inscripción acaba de ser registrada."
		redirect_to request.referer

	rescue DataMapper::SaveFailureError => e
		flash[:error] = "Ha ocurrido un error al tratar de crear la inscripcion. Por favor, inténtelo más tarde #{e}"
		puts e.backtrace
		puts e.resource.errors.inspect
		redirect_to request.referer
	rescue Exception => e
		flash[:error] = Excepciones::ERROR_DESCONOCIDO
		puts e.backtrace
		puts e.message
		redirect_to request.referer
	end

	def eliminar
		raise Excepciones::OperacionNoPermitidaError, "No esta autorizado para realizar esta acción" if not es_periodo_transicion?
		id = params[:alumno_inscrito_seccion_id]
		inscripcion = AlumnoInscritoSeccion.get!(id)

		AlumnoInscritoSeccion.transaction do
			inscripcion.calificaciones_parciales.destroy!
			inscripcion.destroy!
		end

		flash[:notice] = "La inscripción acaba de ser eliminar junto con todas sus calificaciones."
		redirect_to request.referer

	rescue Excepciones::OperacionNoPermitidaError => e
		flash[:error] = e.message
		redirect_to request.referer
	rescue DataMapper::ObjectNotFoundError => e
		flash[:error] = "La inscripción de asignaturas consultada no existe"
		redirect_to request.referer
	rescue DataMapper::SaveFailureError => e
		flash[:error] = "Ha ocurrido un error al tratar de eliminar la inscripcion. Por favor, inténtelo más tarde"
		puts e.backtrace
		puts e.resource.errors.inspect
		redirect_to request.referer
	end

	def editar
		id = params[:alumno_inscrito_seccion_id]
		seccion_in = params[:seccion_in]
		seccion_out = params[:seccion_out]
		inscripcion_seccion = params[:inscripcion_seccion]

		AlumnoInscritoSeccion.transaction do
			seccion = Seccion.first_or_create seccion_in, seccion_out.merge({"periodo_id" => seccion_in["periodo_id"]})
			seccion_dictada = SeccionDictada.first_or_create({:seccion => seccion}, seccion_in["links_secciones_dictadas"][0].merge({"seccion_id" => seccion.id}))

			inscripcion = AlumnoInscritoSeccion.get! id
			inscripcion.update inscripcion_seccion.merge({
				"nota_presentacion" 		=> nil, 
				"nota_examen" 				=> nil, 
				"nota_examen_repeticion" 	=> nil, 
				"seccion_dictada_id" 		=> seccion_dictada.id
			})
		end

		flash[:notice] = "La inscripción acaba de ser actualizada."
		redirect_to request.referer

	rescue DataMapper::ObjectNotFoundError => e
		flash[:error] = "La inscripción de asignaturas consultada no existe"
		redirect_to request.referer
	rescue DataMapper::SaveFailureError => e
		flash[:error] = "Ha ocurrido un error al tratar de editar la inscripcion. Por favor, inténtelo más tarde"
		puts e.backtrace
		puts e.resource.errors.inspect
		redirect_to request.referer
	end
end