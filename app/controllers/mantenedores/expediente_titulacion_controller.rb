# encoding: utf-8
class Mantenedores::ExpedienteTitulacionController < ApplicationController

	def editar
		trabajo = params[:trabajo_titulo_id]
		@trabajo = TrabajoTitulo.first(:id => trabajo)
		raise Excepciones::DatosNoExistentesError, "No se pudo encontrar trabajo de título" if @trabajo.blank?
		@alumno_plan_estudio = @trabajo.alumno_inscrito_seccion.alumno_plan_estudio
		@usuario = @alumno_plan_estudio.alumno.datos_personales
		@comisiones = DocenteExaminador.all(
											examen_titulo: {
												trabajo_titulo:{ id: @trabajo.id
																}
															}
											)
		@docentes = DocenteTrabajoTitulo.all(
											trabajo_titulo:{ 
															id: @trabajo.id
														}
											)
		@estados = TrabajoTitulo::ESTADOS
		rescue Exception => e
		 	flash[:error] = "Error desconocido"
		 	redirect_to coordinador_carrera_consultar_expediente_titulacion_path 
	end

	def registrar_modificacion
		id_trabajo = params[:trabajo_id].to_i
		trabajo_titulo = params[:trabajo_titulo]
		comisiones = params[:comision_examinadora]
		evaluadores = params[:docente_trabajo_titulo]
		puts trabajo_titulo.inspect.red
		TrabajoTitulo.transaction do 
			trabajo = TrabajoTitulo.first(:id => id_trabajo)
			trabajo.fecha = trabajo_titulo[:fecha]
			trabajo.nombre = trabajo_titulo[:nombre]
			trabajo.rol = trabajo_titulo[:rol]
			trabajo.estado = trabajo_titulo[:estado]
			trabajo.save
			unless comisiones.blank?
				comisiones.each do |i|
					id_comision = i[0].to_i
					i[1].each do |c|
						rut_docente = c[:docente_id].split('| ')
						docente = Docente.first(:datos_personales => {:rut => rut_docente[1]})
						comision = DocenteExaminador.first(:id => id_comision)
						comision.nota_expocision = c[:nota_expocision].to_f
						comision.nota_defensa = c[:nota_defensa].to_f
						comision.docente_id = docente.id
						comision.save
					end
				end
			end

			unless evaluadores.blank?
				evaluadores.each do |i|
					id_evaluador = i[0].to_i
					i[1].each do |e|
						rut_docente = e[:docente_id].split('| ')
						puts rut_docente.inspect.red
						docente = Docente.first(:datos_personales => {:rut => rut_docente[1]})
						evaluador = DocenteTrabajoTitulo.first(:id => id_evaluador)
						evaluador.nota = e[:nota]
						evaluador.docente_id = docente.id 
						evaluador.save
					end
				end
			end
		end
		flash[:notice] = "Los cambios se realizaron exitosamente."
		redirect_to coordinador_carrera_consultar_expediente_titulacion_path
		rescue Exception => e
		 	flash[:error] = "#{e.resource.errors.inspect.blue}Error desconocido"
		 	redirect_to coordinador_carrera_consultar_expediente_titulacion_path 
	end
end