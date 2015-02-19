# encoding: utf-8
class Mantenedores::AlumnosController < ApplicationController

	protect_from_forgery :except => [:validar_estudios, :convalidar_asignaturas, :homologar_asignaturas, :registrar_validar_estudios]
    
    before_filter :store_location, :only => [:index]
	crud :alumno, :title_attribute => 'usuario.rut'

	def validar_estudios
		puts params.inspect
		@alumno = []
		if params.has_key?("buscar")
			rut = params[:buscar][:rut]

			@alumno = Alumno.first(:datos_personales => {:rut => rut}) 
			@datos_personales = @alumno.datos_personales
			puts "ALUMNO: #{@alumno.inspect}"
			@carrera = @alumno.plan_vigente
			puts "CARRERA: #{@carrera.inspect}"
			@tipo_ingreso = @carrera[:inscripcion].tipo_ingreso		
			@nombre_tipo_ingreso = Alumno::constant_name :TIPOS_INGRESO, @carrera[:inscripcion].tipo_ingreso

			institucion_sede_plan_id = @carrera[:inscripcion].institucion_sede_plan_id 
			plan_estudio  = PlanEstudio.all(:fields => [:id], :institucion_sede_plan => {:id => institucion_sede_plan_id })
			@asignaturas = plan_estudio[0].asignaturas

			if @tipo_ingreso == Alumno::NORMAL
				flash[:error] = "El alumno no puede ser convalidado u homologado ya que su ingreso a la institucion fue: #{@nombre_tipo_ingreso}" 
			end
		end
	end






	def registrar_validar_estudios

		tipo_ingreso = params[:tipo_ingreso].to_i
		alumno_id = params[:alumno_id].to_i
		alumno_plan_estudio_id = params[:alumno_plan_estudio_id].to_i

		institucion_origen = params[:institucion_origen]
		asignaturas_destino = params[:asignaturas_destino]
		asignaturas_origen	= params[:asignaturas_origen]

		Asignatura::validar_asignatura_alumno alumno_id, institucion_origen, asignaturas_origen, asignaturas_destinos, tipo_ingreso, current_period.id

		flash[:notice] = "La validacion ha ocurrido exitosamente."
		redirect_to validar_estudios_path
		rescue Exception => e
			flash[:error] = "La situación académica del alumno no le permite validar estudios."
			redirect_to validar_estudios_path
			puts "Exception >>>> : #{e.message}" 
	
	end

end