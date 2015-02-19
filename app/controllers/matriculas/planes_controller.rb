# encoding: utf-8
require "date"
require 'wordify'


class Matriculas::PlanesController < ApplicationController
	before_filter :iniciar

	def documentos
		@matricula   = MatriculaPlan.first id: params[:matricula_id]

		@inscripcion = @matricula.alumno_plan_estudio
		@alumno      = @inscripcion.alumno.datos_personales
		@carrera     = @inscripcion.institucion_sede_plan.plan_estudio
		@planes      = @matricula.planes_pago

		@mensaje = %{
			Este procedimiento generará una versión PDF descargable del contrato de prestación de servicios, y de los pagarés vigentes emitidos por este plan.
			ESTE PRCEDIMIENTO SE LLEVARÁ A CABO EN BASE A LA INFORMACIÓN ENCONTRADA EN EL SISTEMA. SI EXISTE UN PAGARÉ QUE TENGA ALGUNA CUOTA PAGADA, ESTA SERÁ DESPLEGADA.
		}

	rescue DataMapper::ObjectNotFoundError => e
		flash.now[:error] = "El plan asociado a la matricula N° #{params[:matricula_id]} no existe."
		@no_existe_plan = true
	end

	def generar_documentos
		@plan = PlanPago.get! params[:plan_id]
		@matricula = @plan.matricula_plan

		if not @plan.pueden_generarse_documentos
			raise Excepciones::OperacionNoPermitidaError, "No se ha podido generar la documentación del plan de pagos. Por favor, verifique si el plan de pagos ya posee documentación generada."
		end		 
					
		@usuario_apoderado     = @plan.apoderado.datos_personales
		alumno_plan_estudio    = @matricula.alumno_plan_estudio
		@institucion_sede_plan = alumno_plan_estudio.institucion_sede_plan
		institucion_sede       = @institucion_sede_plan.institucion_sede
		@plan_estudio          = @institucion_sede_plan.plan_estudio
		@usuario_alumno        = alumno_plan_estudio.alumno.datos_personales
		@alumno                = @usuario_alumno.alumno
		@institucion           = institucion_sede.institucion
		@sede           	   = institucion_sede.sede
		@ip                    = Institucion.first :tipo => Institucion::IP
		@ciudad                = institucion_sede.sede.ciudad
		@periodo               = @plan.periodo
		@detalle_plan          = @plan.informacion_documentos_plan
		pagares                = @detalle_plan[:pagares]
		@pagare                = Pagare.first plan_pago_id: @plan.id

		carpeta    = "#{PlanPago::URL_DOCUMENTOS}/#{institucion_sede.id}/#{periodo_matriculable[:anio]}/#{periodo_matriculable[:semestre]}"
		documentos = "#{carpeta}/#{@usuario_alumno.rut}.#{periodo_matriculable[:nombre]}".delete(" ")
		FileUtils.mkdir_p carpeta
		ts = Time.now.to_s.gsub("-", "_").gsub(" ", "_").gsub(":", "_")

		# Para probar
		#render :partials => "matriculas/planes/pagare", :locals => {:pagare => pagares.first[:pagare]}
		#return

		contrato_extension = false
		pagare_aux = nil

		# pagares
		url_pagares = []
		pagares.each do |item|
			pagare = item[:pagare]

			if !pagare.es_extension.blank?
				contrato_extension = true
				pagare_aux = pagare
			end

			case @institucion.tipo
				when Institucion::IP, Institucion::CFT then
					salida_pagare = render_to_string "matriculas/planes/pagare_cft_ip", :layout => "pdf_sin_logo", :locals => {:pagare => pagare}
				when Institucion::CEIA, Institucion::PREU, Institucion::OTEC then
					# Guarda la institución momentanemante
					institucion2 = @institucion
					# Cambia la institución a IP para efectos de impresión de pagare
					@institucion = @ip
					salida_pagare = render_to_string "matriculas/planes/pagare_preu_ceia", :layout => "pdf_sin_logo", :locals => {:pagare => pagare}
					# Regresa la institucion a la original
					@institucion = institucion2
			end

			pdf_pagare = WickedPdf.new.pdf_from_string(salida_pagare)
			url_pagare = "#{documentos}.pagare-#{pagare.numero}_#{ts}.pdf"
			pagare_file = File.open(url_pagare, 'wb') do |file|
	  			file << pdf_pagare
			end

			url_pagares << {
				:pagare_id 		=> pagare.id,
				:url 			=> pagare_file.path.partition("public")[2]
			}
		end

		# contrato
		@es_cft_ip = true

		if contrato_extension == false
			case @institucion.tipo
			when Institucion::IP then
				malla_hash = PlanEstudio.buscar_malla(@plan_estudio.id)
				@es_contruccion_o_gastronomia = [PlanEstudio::CONSTRUCCION_CIVIL, PlanEstudio::GASTRONOMIA].include? malla_hash
				salida_contrato = render_to_string "matriculas/planes/contrato_ip", :layout => "pdf_sin_logo"
			when Institucion::CFT then
				salida_contrato = render_to_string "matriculas/planes/contrato_cft", :layout => "pdf_sin_logo"
			when Institucion::CEIA then
				@es_cft_ip = false
				salida_contrato = render_to_string "matriculas/planes/contrato_ceia", :layout => "pdf_sin_logo"
			when Institucion::PREU then
				@es_cft_ip = false
				salida_contrato = render_to_string "matriculas/planes/contrato_preu", :layout => "pdf_sin_logo"
			when Institucion::OTEC then
				@es_cft_ip = false
				salida_contrato = render_to_string "matriculas/planes/contrato_otec", :layout => "pdf_sin_logo"
			end
		else
			salida_contrato = render_to_string "matriculas/planes/pagare_extendido_cft_ip", :layout => "pdf_sin_logo", :locals => {:pagare => pagare_aux}
		end

		pdf_contrato = WickedPdf.new.pdf_from_string(salida_contrato)
		url_contrato = "#{documentos}.contrato_#{ts}.pdf"
		contrato = File.open(url_contrato, 'wb') do |file|
  			file << pdf_contrato
		end

		@plan.adjuntar_documentos contrato.path.partition("public")[2], url_pagares

		flash[:notice] = "Los documentos del plan han sido creados exitósamente."
		redirect_to matriculas_ver_path @matricula.id

	rescue DataMapper::ObjectNotFoundError => e
		flash[:error] = "El plan Nº #{params[:id]} no existe."
		redirect_to matriculas_ver_path @matricula.id

	rescue DataMapper::SaveFailureError => e
		flash[:error] = e
		redirect_to matriculas_ver_path @matricula.id

	rescue Excepciones::OperacionNoPermitidaError => e
		flash[:error] = e.message
		redirect_to matriculas_ver_path @matricula.id

	rescue Exception => e
		puts e.message
		puts e.backtrace
		flash[:error] = Excepciones::ERROR_DESCONOCIDO
		redirect_to matriculas_ver_path @matricula.id
	end

	def eliminar_documentos
		plan = PlanPago.get! params[:plan_id]	
		matricula = plan.matricula_plan	 
		
		pagare = Pagare.last plan_pago_id: plan.id,
							 :estado.not => Pagare::ANULADO

		url_plan = plan.url_contrato
		plan.url_contrato = nil
		plan.save

		unless pagare.blank?
			url_pagare = pagare.url
			pagare.url = nil
			pagare.save
		end

		flash[:notice] = "Los documentos del plan han sido eliminados exitósamente."
		redirect_to matriculas_ver_path matricula.id

	rescue DataMapper::SaveFailureError => e
		plan.url_contrato = url_plan

		unless pagare.blank?
			pagare.url = url_pagare
		end

		flash[:error] = "Ha ocurrido un error al tratar de eliminar los documentos generados."
		redirect_to matriculas_ver_path matricula.id

	rescue Exception => e
		puts e.message
		puts e.backtrace
		flash[:error] = Excepciones::ERROR_DESCONOCIDO
		redirect_to matriculas_ver_path matricula.id
	end

	def iniciar
		@usuario              = current_user_object
		@ejecutivo_matriculas = @usuario.ejecutivo_matriculas
	end
end