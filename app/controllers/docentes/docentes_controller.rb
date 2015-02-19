# encoding: utf-8
class Docentes::DocentesController < ApplicationController

	helper_method [:current_url, :ajax_url]

	before_filter :preparar_acciones_publicas1, only: [
		:obtener_asignaturas_dictadas

	]
	before_filter :preparar_acciones_publicas2, only: [
		:obtener_listado_alumnos,
		:obtener_libro_asistencia,
		:obtener_libro_calificaciones,
		:obtener_libro_clases
	]

	before_filter :preparar_acciones_publicas3, only: [
		:obtener_asignaturas_abiertas
	]

	before_filter :preparar_acciones_privadas1, only: [
		:preparar_libro_calificaciones,
		:preparar_libro_asistencia,
		:preparar_cierre_seccion
	]

	before_filter :preparar_acciones_privadas2, only: [
		:registrar_libro_calificaciones,
		:registrar_libro_asistencia,
		:cerrar_seccion
	]

	# Acciones públicas - forma 1

	def obtener_asignaturas_dictadas
		alias current_url docente_obtener_asignaturas_dictadas_path

		@asignaturas_dictadas = @docente.asignaturas_dictadas @docente.id, @periodo_seleccionado.id
		@existen_datos = true

   rescue Excepciones::DatosNoExistentesError => e
        flash.now[:info] = e.message
        @existen_datos = false	
	end	

	# Acciones públicas - forma 2

	def obtener_listado_alumnos
		alias current_url docente_obtener_listado_alumnos_path

		@alumnos = @seccion.alumnos @seccion.id if not @seccion.nil? and @existe_seccion
		@existen_datos = true 

    rescue Excepciones::DatosNoExistentesError => e
        flash.now[:info] = e.message
        @existen_datos = false	
	end

	def obtener_libro_asistencia
		alias current_url docente_obtener_libro_asistencia_path

		@libro = @seccion.libro_asistencia @seccion.id if not @seccion.nil? and @existe_seccion
		@existen_datos = true 

    rescue Excepciones::DatosNoExistentesError => e
        flash.now[:info] = e.message
        @existen_datos = false	
	end

	def obtener_libro_calificaciones
		alias current_url docente_obtener_libro_calificaciones_path

		@libro = @seccion.libro_calificaciones @seccion.id if not @seccion.nil? and @existe_seccion
		@existen_datos = true 
			
    rescue Excepciones::DatosNoExistentesError => e
        flash.now[:info] = e.message
        @existen_datos = false	
	end

	def obtener_libro_clases
		
		alias current_url docente_obtener_libro_clases_path

		@libro = @seccion.obtener_clases @seccion.id if not @seccion.nil? and @existe_seccion
		@existen_datos = true 
			
    rescue Excepciones::DatosNoExistentesError => e
        flash.now[:info] = e.message
        @existen_datos = false	
	end

	# Acciones públicas - forma 3

	def obtener_asignaturas_abiertas
		@asignaturas_abiertas = @docente.asignaturas_abiertas @docente.id, periodo_en_curso[:id]
		@existen_datos = true

    rescue Excepciones::DatosNoExistentesError => e
        flash.now[:info] = e.message
        @existen_datos = false	
	end	

	# Acciones privadas - forma 1	

	def preparar_libro_calificaciones
		alias current_url docente_preparar_libro_calificaciones_path	
		
		@libro = @seccion.preparar_libro_calificaciones @seccion.id if not @seccion.nil? and @existen_secciones
		@existen_datos = true
		
    rescue Excepciones::DatosNoExistentesError => e
        flash.now[:info] = e.message
        @existen_datos = false	
	end

	def preparar_libro_asistencia
		alias current_url docente_preparar_libro_asistencia_path	

		@libro = @seccion.preparar_libro_calificaciones @seccion.id if not @seccion.nil? and @existen_secciones
		@existen_datos = true
		if not @seccion.nil?
			@libro = @seccion.preparar_libro_asistencia
			
			if @libro[:alumnos].empty?
				flash.now[:info] = "La sección consultada no registra alumnos"
			end
		end
	end	

	def preparar_cierre_seccion
		alias current_url docente_preparar_cierre_seccion_path	

		@seccion.puede_ser_cerrada? @seccion.id if not @seccion.nil? and @existen_secciones
		@existen_datos = true

    rescue Excepciones::OperacionNoPermitidaError => e
        flash.now[:info] = e.message
        @existen_datos = false	
	end	

	def registrar_libro_calificaciones
		seccion = Seccion.registrar_calificaciones(
			params[:seccion_id],
			params[:planificacion_calificacion_id], 
			params[:calificaciones_parciales], 
			params[:recuperativas],
			params[:examenes], 
			params[:finales],
		)
		flash[:notice] = "Las calificaciones ha sido registrada exitósamente"
		redirect_to docente_obtener_libro_calificaciones_path @usuario.id, seccion.id
		
	rescue DataMapper::SaveFailureError
		puts e.message
		puts e.backtrace
		puts e.resource.errors.inspect
		flash[:error] = "Ha ocurrido un error al tratar de registrar la asistencia. Inténtelo más tarde."			
		redirect_to docente_obtener_libro_calificaciones_path @usuario.id, seccion.id
	end

	def registrar_libro_asistencia
		# Extraemos todos los parametros
		seccion = Seccion.get params[:seccion_id].to_i
		asistencias = params[:asistencias].map do |item|
			inscripcion_id = item[:alumno_inscrito_seccion_id].to_i
			clase_id = item[:clase_id].to_i
			horas_clase = item[:horas_clase].to_i
			horas_asistidas = item[:horas_asistidas].to_i
			horas_ausentadas = item[:horas_clase].to_i - item[:horas_asistidas].to_i

			{
				:alumno_inscrito_seccion_id => inscripcion_id,
				:clase_id => clase_id,
				:horas_asistidas => horas_asistidas,
				:horas_ausentadas => horas_ausentadas,
				:estado => ( horas_asistidas > 0 ) ? Asistencia::ASISTIDA : Asistencia::AUSENTADA
			}
		end

		# Los guardamos
		if seccion.registrar_asistencia asistencias[0][:clase_id], asistencias
			flash[:notice] = "La asistencia ha sido registrada exitósamente"
		else
			flash[:error] = "Ha ocurrido un error al tratar de registrar la asistencia. Inténtelo más tarde."			
		end
		redirect_to docente_obtener_libro_asistencia_path @usuario.id, seccion.id
	end

	def cerrar_seccion
		seccion_id = params[:seccion_id]
		seccion = Seccion.cerrar_seccion seccion_id, periodo_en_curso[:id]
		puts "seccion: #{seccion.inspect}".bold
		redirect_to docente_obtener_libro_calificaciones_path @usuario.id, seccion.id

	rescue DataMapper::SaveFailureError
		puts e.message
		puts e.backtrace
		puts e.resource.errors.inspect
		flash[:error] = "Ha ocurrido un error al tratar de cerrar la sección. Inténtelo más tarde."			
		redirect_to docente_obtener_libro_calificaciones_path @usuario.id, seccion.id

	rescue Excepciones::DatosInconsistentesError => e
		puts e.message
		puts e.backtrace
		flash[:error] = e.message			
		redirect_to docente_preparar_cierre_seccion_path @usuario.id, seccion_id
	end

	private

	def preparar_acciones_publicas1
		@usuario = Usuario.get(params[:usuario_id])
		@docente = @usuario.docente

		periodo_id = (not params[:periodo_id].nil?) ? params[:periodo_id].to_i : nil
		todos_los_periodos = Periodo.obtener_todos periodo_id
		@periodos = todos_los_periodos[:todos]
		@periodo_seleccionado = todos_los_periodos[:seleccionado]		
	end

	def preparar_acciones_publicas2
		@usuario = Usuario.get(params[:usuario_id])
		@docente = @usuario.docente
		seccion_id = (not params[:seccion_id].nil?) ? params[:seccion_id].to_i : nil

		if not seccion_id.nil?
			@seccion = Seccion.get! seccion_id
			@asignaturas_seccion = @seccion.asignaturas_seccion
			periodo_id = @seccion.periodo_id	
			@es_presencial = (not @seccion.jornada.nil?)		
		else
			periodo_id = nil
		end

		todos_los_periodos = Periodo.obtener_todos periodo_id
		@periodos = todos_los_periodos[:todos]
		@periodo_seleccionado = todos_los_periodos[:seleccionado]

		@asignaturas = Ajax::Docente.asignaturas @docente.id, @periodo_seleccionado.id
		alias ajax_url ajax_docente_obtener_secciones_por_periodo_path
		@existe_seccion = true
		
	rescue DataMapper::ObjectNotFoundError => e
		flash.now[:error] = "La sección consultada no existe."
		@existe_seccion = false      
	end

	def preparar_acciones_publicas3
		@usuario = Usuario.get(params[:usuario_id])
		@docente = @usuario.docente	
	end


	def preparar_acciones_privadas1
		seccion_id = (not params[:seccion_id].nil?) ? params[:seccion_id].to_i : nil
		@usuario = Usuario.get(params[:usuario_id])
		@docente = @usuario.docente

		if not seccion_id.nil?
			@seccion = Seccion.get seccion_id
		end

		@asignaturas_abiertas = @docente.asignaturas_abiertas_seleccion @docente.id, periodo_en_curso[:id]
		@existen_secciones = true

    rescue Excepciones::DatosNoExistentesError => e
        flash.now[:info] = e.message
        @existen_secciones = false	
	end

	def preparar_acciones_privadas2
		@usuario = current_user_object
		@docente = @usuario.docente	
	end
end