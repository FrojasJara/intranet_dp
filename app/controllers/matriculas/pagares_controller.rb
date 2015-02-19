# encoding: utf-8
require "date"

class Matriculas::PagaresController < ApplicationController

	helper_method :current_url

	before_filter :iniciar

	def anular_sustituir
		pagare = Pagare.get! params[:pagare_id]
		@existe_pagare = true

		raise Excepciones::OperacionNoPermitidaError, "No esta autorizado para anular el pagaré N° #{pagare.numero}." if not pagare.ejecutivo_matriculas_puede_anular? @ejecutivo_matriculas.id
		raise Excepciones::OperacionNoPermitidaError, "No está utorizado para anular el pagaré Nº #{pagare.numero}, ya que presenta cuotas abonadas" if pagare.cuotas.abonos.count(:estado => PagoComprometido::PAGADO) > 0
		
		@puede_anularse = true

		@alumno, @pagare = pagare.detalle
		@centros_costos = PagoComprometido::CENTROS_COSTOS
		@mensaje = %{
			Se anularán tanto el pagaré como sus cuotas. ESTE PROCEDIMIENTO ES IRREVERSIBLE.
			Luego de este procedimiento, se deberá generar nuevamente la versión descargables PDF del contrato y del pagaré.
		}	

	rescue Excepciones::OperacionNoPermitidaError => e
		flash.now[:error] = e.message
		@puede_anularse = false 
		
	rescue DataMapper::ObjectNotFoundError => e
		flash.now[:error] = "El pagaré Nº #{params[:pagare_id]} no existe."
		@existe_pagare = false
	end

	def registrar_anulacion_sustitucion
		pagare_antiguo = Pagare.anular_sustituir params[:pagare_id], params[:pagare], params[:cuotas], @ejecutivo_matriculas.id
		flash[:notice] = "El pagaré ha sido anulado y sustituído exitósamente. Ahora debe generar nuevamente las versiones descargables PDF del contrato y del nuevo pagare."
		redirect_to matriculas_ver_path pagare_antiguo.plan_pago.matricula_plan_id

	rescue Excepciones::OperacionNoPermitidaError => e
		flash[:error] = e.message
		redirect_to matriculas_pagare_ver_path params[:pagare_id]

	rescue DataMapper::SaveFailureError => e
		puts e.resource.errors.inspect
		flash[:error] = "Ha ocurrido un error al tratar de anular el pagaré. Por favor, inténtelo mas tarde."
		redirect_to matriculas_pagare_anular_sustituir_path params[:pagare_id]

	rescue DataMapper::ObjectNotFoundError => e
		flash[:error] = "El pagaré Nº #{params[:pagare_id]} no existe."
		redirect_to matriculas_pagare_buscar_por_numero_path.

	rescue Exception => e
		flash[:error] = Excepciones::ERROR_DESCONOCIDO
		redirect_to matriculas_pagare_anular_path params[:pagare_id]
	end

	def editar
		pagare = Pagare.get! params[:pagare_id]
		@existe_pagare = true

		raise Excepciones::OperacionNoPermitidaError, "No esta autorizado para editar el pagaré N° #{pagare.numero}." if not pagare.ejecutivo_matriculas_puede_anular? @ejecutivo_matriculas.id
		#raise Excepciones::OperacionNoPermitidaError, "No está utorizado para editar el pagaré Nº #{pagare.numero}, ya que presenta cuotas abonadas" if pagare.cuotas.abonos.count(:estado => PagoComprometido::PAGADO) > 0
		
		@puede_anularse = true

		@alumno, @pagare = pagare.detalle
		@centros_costos = PagoComprometido::CENTROS_COSTOS
		@medios_pago = MedioPago.all(fields: [:id, :nombre], slug: ['efectivo', 'tarjeta-credito', 'tarjeta-debito'])
		@mensaje = %{
			Puede modificar las cuotas del Plan de Pago, incluir cuotas de matrículas y modificar el monto total del plan de pagos.<br />
			El monto a ingresar para el nuevo Plan de Pagos debe ser <strong>CON DESCUENTO DE ARANCEL</strong><br />
			<strong>Si existen pagos a alguna de las cuotas estas serán eliminadas como también sus respectivas boletas.</strong><br />
			<strong>Una vez terminado el proceso debe generar el contrato y pagaré</strong>
		}	

		rescue Excepciones::OperacionNoPermitidaError => e
			flash.now[:error] = e.message
			@puede_anularse = false 
			
		rescue DataMapper::ObjectNotFoundError => e
			flash.now[:error] = "El pagaré Nº #{params[:pagare_id]} no existe."
			@existe_pagare = false
	end

	def guardar_edicion
		matricula_plan = PlanPago.editar_plan_pago params[:cuotas], params[:pagare], params[:documento_venta], params[:matricula], params[:pagare_id]


		redirect_to matriculas_ver_path(matricula_plan)

        rescue Exception => e
            flash[:error] = e.message
            log_error e
            redirect_to matriculas_pagare_editar_path(params[:pagare_id])            
	end

	def buscar_por_numero
		@q = params[:q]
		alias current_url matriculas_pagare_buscar_por_numero_path

		@etiqueta = "Número del pagaré"
		if not @q.nil?
			pagare = Pagare.buscar_por_numero @q
			redirect_to matriculas_ver_path pagare.plan_pago.matricula_plan_id, :anchor => "pagare-#{pagare.id}"
		end

		rescue DataMapper::ObjectNotFoundError => e
			flash.now[:error] = "El pagaré Nº #{@q} no existe."
	end

	def buscar_por_rut
		@q = params[:q]
		alias current_url matriculas_pagare_buscar_por_rut_path

		@etiqueta = "Rut del alumno"
		if not @q.nil?
			@pagares = Pagare.buscar_por_rut @q
			raise Excepciones::DatosNoExistentesError, "No existe ningún pagaré registrado a un alumno con rut #{@q}." if @pagares.empty?
			@existen_datos = true
		end

		rescue Excepciones::DatosNoExistentesError => e
			flash.now[:error] = e.message
			@existen_datos = false
	end

	private

	def iniciar
		@usuario = current_user_object
		@ejecutivo_matriculas = @usuario.ejecutivo_matriculas
	end
end