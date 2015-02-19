# encoding: utf-8
require "date"

class Matriculas::MatriculasController < ApplicationController

	PROCEDIMIENTOS = [
						{:nombre => "Matriculas", 
                        :metodos => [:generar_documentos],
                        :menus   => [:admision]
                        },
					]

	helper_method :current_url, :url_postulante, :url_alumno

	before_filter :iniciar
	before_filter :acciones_matriculas, :only => [:planes, :editar]

	def actualizar
		plan = MatriculaPlan.editar(
			params[:matricula_id], 		params[:matricula_plan], 		params[:inscripcion], 
			params[:usuario_alumno], 	params[:alumno], 				params[:documentos_alumno],
			params.key?("es_alumno"), 	params[:usuario_apoderado_id], 	params[:usuario_apoderado],
			params[:apoderado],			@ejecutivo_matriculas.id, 		current_user[:sede_id],
			params[:nivel]
		)
		flash[:notice] = "La matrícula ha sido editada exitósamente."
		redirect_to matriculas_plan_documentos_path params[:matricula_id]

	rescue DataMapper::ObjectNotFoundError => e
		flash[:error] = "La matrícula N° #{params[:matricula_id]} no existe."
		redirect_to matriculas_ver_path params[:matricula_id]
	rescue DataMapper::SaveFailureError => e
		puts e.resource.errors.inspect
		flash[:error] = "Ha ocurrido un error al tratar de editar la matrícula. Por favor, inténtelo mas tarde."
		redirect_to matriculas_editar_path params[:matricula_id]
	rescue Excepciones::OperacionNoPermitidaError => e
		flash[:error] = e.message
		redirect_to matriculas_editar_path params[:matricula_id]
	rescue Exception => e
		puts e.message
		puts e.backtrace
		flash[:error] = Excepciones::ERROR_DESCONOCIDO
		redirect_to matriculas_editar_path params[:matricula_id]
	end

	def editar
		if @existe_matricula
			raise Excepciones::OperacionNoPermitidaError, "No esta autorizado para editar la matrícula N° #{@matricula.id}" if not @matricula.ejecutivo_matriculas_puede_editar? @ejecutivo_matriculas.id
			@mensaje = %{
				Luego de este procedimiento, tendrá que volverse a generar la versión descargable PDF del contrato de prestación de servicios.
				Solo cuando corresponde y estime, deberá también ANULAR Y SUSTITUIR el pagaré.
			}

			# Datos personales del postulante y apoderado
			@estados_civiles = Usuario::ESTADOS_CIVILES
			@sexos = Usuario::SEXOS
			@regiones = Region.all
			@paises = Pais.all
			@procedencias = Alumno::EST_EDUCACIONALES
			@documentos_alumno = Alumno::DOCUMENTOS
			@documentos_apoderado = Apoderado::DOCUMENTOS
			@codigos_fijos = Utils::CodigoTelefonico::FIJOS
			@medios = Cotizacion::MEDIOS
			@plan_vigente = @planes.select{ |plan| plan.estado == PlanPago::VIGENTE }.first

			@apoderado = @alumno.apoderado
			if not @apoderado.es_alumno
				@usuario_apoderado = @apoderado.datos_personales 
			else
				@usuario_apoderado = Usuario.new
			end

			institucion_sede = @institucion_sede_plan.institucion_sede
			institucion = institucion_sede.institucion
			@es_ip_cft = [Institucion::IP, Institucion::CFT].include? institucion.tipo

			@instituciones_sedes_planes = InstitucionSedePlan.all(
				:plan_estudio 			=> @carrera,
				:institucion_sede 		=> institucion_sede,
				:periodo_id 			=> @matricula.periodo_id,
				:modalidad 				=> InstitucionSedePlan::PRESENCIAL
			)		
			@puede_editarse = true
		end

	rescue Excepciones::OperacionNoPermitidaError => e
		flash.now[:error] = e.message 
		@puede_editarse = false
	end

	def planes
	end

	def ver
		@matricula = MatriculaPlan.get! params[:matricula_id]
		@existe_matricula = true

		# Datos personales
		@inscripcion_plan = @matricula.alumno_plan_estudio
		@alumno = @inscripcion_plan.alumno
		@usuario_alumno = @alumno.datos_personales

		# Plan de estudios
		@institucion_sede_plan = @inscripcion_plan.institucion_sede_plan
		@plan = @institucion_sede_plan.plan_estudio

		# Planes de pagos y varios y plan de pago vigente
		@plan_vigente, @resumen_planes = @matricula.resumen_planes
		raise Excepciones::DatosNoExistentesException if @resumen_planes.empty?
		@existen_datos = true

	rescue DataMapper::ObjectNotFoundError => e
		flash.now[:error] = "La matrícula N° #{params[:matricula_id]} no existe."
		@existe_matricula = false

	rescue Excepciones::DatosNoExistentesException => e
		flash.now[:error] = "La matrícula N° #{@matricula.id} no presenta información de planes de pagos."
		@existen_datos = false
	end

	def matricula_nuevo_ip
		sede_id = current_user[:sede_id]

		# Datos personales del postulante y apoderado
		@estados_civiles = Usuario::ESTADOS_CIVILES
		@sexos = Usuario::SEXOS
		@regiones = Region.all
		@paises = Pais.all
		@procedencias = Alumno::EST_EDUCACIONALES
		@tipo_procedencias = Alumno::TIPO_EST_EDUCACIONALES
		@documentos_alumno = Alumno::DOCUMENTOS
		@documentos_apoderado = Apoderado::DOCUMENTOS
		@codigos_fijos = Utils::CodigoTelefonico::FIJOS
		@medios = Cotizacion::MEDIOS

		alias url_postulante ajax_postulante_obtener_ip_path

		# Datos del plan de estudio
		@planes_matriculables = InstitucionSedePlan.planes_alumno_nuevo @periodo_matriculable[:id], sede_id
		@planes_en_curso      = InstitucionSedePlan.planes_alumno_nuevo @periodo_en_curso[:id], sede_id

		# Datos para el descuento
		@descuentos = Descuento.all(estado: Descuento::VIGENTE,
									order: :nombre.asc
									).group_by { |e| e.tipo }

		# Datos de los medios de pagos
		@medios_pagos = MedioPago.all
		@bancos = Banco.all
		@tarjetas_credito = TarjetasCredito.all
		@formas_cuotas_alumno_nuevo = FormaPlanPago.plan_sin_interes
		@formas_cuotas_matriculas = FormaPlanPago.planes_matricula
		@hoy = Date.today.to_s.gsub "-", "/"
		@documentos_venta = DocumentoVenta::TIPOS
	end

	def matricula_convalidado
		sede_id = current_user[:sede_id]

		# Datos personales del postulante y apoderado
		@estados_civiles = Usuario::ESTADOS_CIVILES
		@sexos = Usuario::SEXOS
		@regiones = Region.all
		@paises = Pais.all
		@procedencias = Alumno::EST_EDUCACIONALES
		@tipo_procedencias = Alumno::TIPO_EST_EDUCACIONALES
		@documentos_alumno = Alumno::DOCUMENTOS
		@documentos_apoderado = Apoderado::DOCUMENTOS
		@codigos_fijos = Utils::CodigoTelefonico::FIJOS
		@medios = Cotizacion::MEDIOS

		alias url_postulante ajax_postulante_obtener_ip_path

		# Datos del plan de estudio
		@planes_matriculables = InstitucionSedePlan.planes_alumno_superior @periodo_matriculable[:id], sede_id
		@planes_en_curso      = InstitucionSedePlan.planes_alumno_superior @periodo_en_curso[:id], sede_id

		# Datos para el descuento
		@descuentos = Descuento.all(estado: Descuento::VIGENTE,
									order: :nombre.asc
									).group_by { |e| e.tipo }

		# Datos de los medios de pagos
		@medios_pagos = MedioPago.all
		@bancos = Banco.all
		@tarjetas_credito = TarjetasCredito.all
		@formas_cuotas_alumno_nuevo = FormaPlanPago.plan_sin_interes
		@formas_cuotas_matriculas = FormaPlanPago.planes_matricula
		@hoy = Date.today.to_s.gsub "-", "/"
		@documentos_venta = DocumentoVenta::TIPOS
	end

	def matricula_superior_ip
		# Datos personales del y apoderado
		@estados_civiles = Usuario::ESTADOS_CIVILES
		@sexos = Usuario::SEXOS
		@regiones = Region.all
		@paises = Pais.all
		@documentos_apoderado = Apoderado::DOCUMENTOS
		@codigos_fijos = Utils::CodigoTelefonico::FIJOS

		# Datos de los tipos de matrícula y descuentos
		@matriculas_profesionales 	= MatriculaPlan::PROFESIONALES
		@matriculas_tecnicas 		= MatriculaPlan::TECNICAS
		@matriculas_distancia 		= MatriculaPlan::DISTANCIA

		@descuentos = Descuento.all(estado: Descuento::VIGENTE,
									order: :nombre.asc
									).group_by { |e| e.tipo }

		@max_cantidad_cobro_asignaturas_regular = Rails.configuration.max_cantidad_cobro_asignaturas_regular
		@max_cantidad_cobro_asignaturas_terminal = Rails.configuration.max_cantidad_cobro_asignaturas_terminal
		@cobro_asignaturas_regular_factor = Rails.configuration.cobro_asignaturas_regular_factor
		@cobro_asignaturas_terminal_factor = Rails.configuration.cobro_asignaturas_terminal_factor
		@max_cantidad_normativas = Rails.configuration.max_cantidad_normativas
		@cobro_normativas_factor = Rails.configuration.cobro_normativas_factor
		@distancia_cobro_semestre_factor = Rails.configuration.cobro_semestre_distancia_factor

		alias url_alumno ajax_alumno_obtener_situacion_ip_path

		# Datos de los medios de pagos
		@medios_pagos = MedioPago.all
		@bancos = Banco.all
		@tarjetas_credito = TarjetasCredito.all
		@formas_cuotas_alumno_superior = FormaPlanPago.plan_sin_interes
		@formas_cuotas_matriculas = FormaPlanPago.planes_matricula
		@hoy = Date.today.to_s.gsub "-", "/"

		@documentos_venta = DocumentoVenta::TIPOS
	end

	def matricula_extension
		# Datos personales del y apoderado
		@estados_civiles = Usuario::ESTADOS_CIVILES
		@sexos = Usuario::SEXOS
		@regiones = Region.all
		@paises = Pais.all
		@documentos_apoderado = Apoderado::DOCUMENTOS
		@codigos_fijos = Utils::CodigoTelefonico::FIJOS

		# Matriculas consideradas en Extensiones
		@matriculas_ext_profesionales 	= MatriculaPlan::EXTENSION_PROFESIONALES
		@matriculas_ext_tecnicas 		= MatriculaPlan::EXTENSION_TECNICAS
		@matriculas_distancia 			= MatriculaPlan::DISTANCIA

		@descuentos = Descuento.all(estado: Descuento::VIGENTE,
									order: :nombre.asc
									).group_by { |e| e.tipo }
		
		@max_cantidad_cobro_asignaturas_regular = Rails.configuration.max_cantidad_cobro_asignaturas_regular
		@max_cantidad_cobro_asignaturas_terminal = Rails.configuration.max_cantidad_cobro_asignaturas_terminal
		@cobro_asignaturas_regular_factor = Rails.configuration.cobro_asignaturas_regular_factor
		@cobro_asignaturas_terminal_factor = Rails.configuration.cobro_asignaturas_terminal_factor
		@max_cantidad_normativas = Rails.configuration.max_cantidad_normativas
		@cobro_normativas_factor = Rails.configuration.cobro_normativas_factor
		@distancia_cobro_semestre_factor = Rails.configuration.cobro_semestre_distancia_factor

		alias url_alumno ajax_alumno_obtener_situacion_extension_path

		# Datos de los medios de pagos
		@medios_pagos = MedioPago.all
		@bancos = Banco.all
		@tarjetas_credito = TarjetasCredito.all
		@formas_cuotas_alumno_superior = FormaPlanPago.plan_sin_interes
		@formas_cuotas_matriculas = FormaPlanPago.planes_matricula
		@hoy = Date.today.to_s.gsub "-", "/"

		@documentos_venta = DocumentoVenta::TIPOS
	end

	def registrar_matricula_nuevo_ip
		sede_id = current_user[:sede_id]
		periodo = Periodo.first id: params["periodo"]

		unless params[:pagos_comprometidos].blank?
			params[:pagos_comprometidos].each do |pago|
				unless pago[:abono].blank?
					unless pago[:abono][:fecha].blank?
						pago[:abono][:fecha].gsub("-","/");
					end
					unless pago[:abono][:fecha_documento].blank?
						pago[:abono][:fecha_documento].gsub("-","/");
					end
				end
			end
		end

		matricula = MatriculaPlan.matricular_alumno_nuevo_ip(
			sede_id, 						params[:institucion_sede_id], 						
			params[:usuario_alumno], 		params[:usuario_postulante_id], params[:alumno],				
			params[:documentos_alumno], 	params[:usuario_apoderado], 	params[:apoderado],				
			params.key?("es_alumno"), 		periodo,				  		params[:inscripcion_plan],		
			params[:matricula_plan], 		params[:plan_pago], 			params[:pagares], 				
			params[:pagos_comprometidos],   params[:documento_venta]
		)

		flash[:notice] = "La matrícula ha sido registrada exitósamente."
		redirect_to matriculas_ver_path matricula.id

	rescue DataMapper::SaveFailureError => e
		puts e.backtrace
		puts e.resource.errors.inspect
		flash[:error] = "Por favor, verifique los campos ingresados. #{e.resource.errors.inspect}"
		redirect_to matriculas_admision_nuevo_ip_path

	rescue Exception => e
		log_error e
		flash[:error] = Excepciones::ERROR_DESCONOCIDO
		redirect_to matriculas_admision_nuevo_ip_path
	end

	def registrar_matricula_superior_ip
		sede_id = current_user[:sede_id]
		periodo = Periodo.first id: params["periodo"]

		unless params[:pagos_comprometidos].blank?
			params[:pagos_comprometidos].each do |pago|
	 			unless pago[:abono].blank?
					unless pago[:abono][:fecha].blank?
						pago[:abono][:fecha].gsub("-","/");
					end
					unless pago[:abono][:fecha_documento].blank?
						pago[:abono][:fecha_documento].gsub("-","/");
					end
				end
			end
		end

		matricula = MatriculaPlan.matricular_alumno_superior_ip(
			sede_id, 						params[:institucion_sede_id], 	params[:usuario_alumno], 	
			params[:usuario_apoderado], 	params[:apoderado],				params.key?("es_alumno"), 		
			periodo,			 			params[:matricula_plan], 		params[:plan_pago],
			params[:pagares], 				params[:pagos_comprometidos],	params[:documento_venta]
		)

		flash[:notice] = "La matrícula ha sido registrada exitósamente."
		redirect_to matriculas_ver_path matricula.id

	rescue DataMapper::SaveFailureError => e
		puts e.message
		puts e.backtrace
		puts e.resource.errors.inspect
		flash[:error] = "Por favor, verifique los campos ingresados. #{e.resource.errors.inspect}"
		redirect_to matriculas_admision_superior_ip_path

	rescue Exception => e
		log_error e
		flash[:error] = Excepciones::ERROR_DESCONOCIDO
		redirect_to matriculas_admision_superior_ip_path
	end

	def registrar_matricula_extension
		sede_id = current_user[:sede_id]
		periodo = Periodo.first id: params["periodo"]

		unless params[:pagos_comprometidos].blank?
			params[:pagos_comprometidos].each do |pago|
	 			unless pago[:abono].blank?
					unless pago[:abono][:fecha].blank?
						pago[:abono][:fecha].gsub("-","/");
					end
					unless pago[:abono][:fecha_documento].blank?
						pago[:abono][:fecha_documento].gsub("-","/");
					end
				end
			end
		end

		matricula = MatriculaPlan.matricular_alumno_extension(
			sede_id, 						params[:institucion_sede_id], 	params[:usuario_alumno], 	
			params[:usuario_apoderado], 	params[:apoderado],				params.key?("es_alumno"), 		
			periodo,			 			params[:matricula_plan], 		params[:plan_pago],
			params[:pagares], 				params[:pagos_comprometidos],	params[:documento_venta]
		)

		flash[:notice] = "La extensión ha sido registrada exitósamente."
		redirect_to matriculas_ver_path matricula.id

	rescue DataMapper::SaveFailureError => e
	 	puts e.message
	 	puts e.backtrace
	 	puts e.resource.errors.inspect
	 	flash[:error] = "Por favor, verifique los campos ingresados. #{e.resource.errors.inspect}"
	 	redirect_to matriculas_admision_extension_path

	rescue Exception => e
	 	log_error e
	 	flash[:error] = Excepciones::ERROR_DESCONOCIDO
	 	redirect_to matriculas_admision_extension_path
	end

	def registrar_matricula_convalidado
		sede_id = current_user[:sede_id]
		periodo = Periodo.first id: params["periodo"]

		unless params[:pagos_comprometidos].blank?
			params[:pagos_comprometidos].each do |pago|
	 			unless pago[:abono].blank?
					unless pago[:abono][:fecha].blank?
						pago[:abono][:fecha].gsub("-","/");
					end
					unless pago[:abono][:fecha_documento].blank?
						pago[:abono][:fecha_documento].gsub("-","/");
					end
				end
			end
		end

		matricula = MatriculaPlan.matricular_alumno_convalidado(
			sede_id, 						params[:institucion_sede_id], 						
			params[:usuario_alumno], 		params[:usuario_postulante_id], params[:alumno],				
			params[:documentos_alumno], 	params[:usuario_apoderado], 	params[:apoderado],				
			params.key?("es_alumno"), 		periodo,				  		params[:inscripcion_plan],		
			params[:matricula_plan], 		params[:plan_pago], 			params[:pagares], 				
			params[:pagos_comprometidos],   params[:documento_venta],		params[:estado_plan_anterior]
		)

		flash[:notice] = "La matrícula ha sido registrada exitósamente."
		redirect_to matriculas_ver_path matricula.id

	rescue DataMapper::SaveFailureError => e
		puts e.backtrace
		puts e.resource.errors.inspect
		flash[:error] = "Por favor, verifique los campos ingresados. #{e.resource.errors.inspect}"
		redirect_to matriculas_admision_convalidado_path

	rescue Exception => e
		log_error e
		flash[:error] = Excepciones::ERROR_DESCONOCIDO
		redirect_to matriculas_admision_convalidado_path
	end

	def buscar_por_numero
		@q = params[:q]
		alias current_url matriculas_buscar_por_numero_path

		@etiqueta = "Número de matrícula"
		if not @q.nil?
			redirect_to matriculas_ver_path @q
		end
	end

	def buscar_por_rut
		@q = params[:q]
		alias current_url matriculas_buscar_por_rut_path

		@etiqueta = "Dígitos del rut"
		if not @q.nil?
			@matriculas = MatriculaPlan.buscar_por_rut @q
			raise Excepciones::DatosNoExistentesError, "No existe ninguna matrícula registrada a un alumno con rut #{@q}" if @matriculas.empty?
			@existen_datos = true
		end

	rescue Excepciones::DatosNoExistentesError => e
		flash.now[:error] = e.message
		@existen_datos = false
	end

	private

	def iniciar
		@usuario 			  = current_user_object
		@ejecutivo_matriculas = @usuario.ejecutivo_matriculas
		@periodo_matriculable = periodo_proximo
		@periodo_en_curso     = periodo_en_curso
	end

	def acciones_matriculas
		@matricula = MatriculaPlan.get! params[:matricula_id]
		@inscripcion = @matricula.alumno_plan_estudio
		@alumno = @inscripcion.alumno
		@usuario_alumno = @alumno.datos_personales
		@institucion_sede_plan = @inscripcion.institucion_sede_plan
		@carrera = @institucion_sede_plan.plan_estudio
		@planes = @matricula.planes_pago

		@existe_matricula = true

	rescue DataMapper::ObjectNotFoundError => e
		flash.now[:error] = "La matrícula N° #{params[:matricula_id]} no existe."
		@existe_matricula = false
	end
end
