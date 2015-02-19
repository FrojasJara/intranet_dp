class Matriculas::Ajax::PagosController < ApplicationController
	layout nil

	def abono_detalle_forma_pago
		@medio_pago = MedioPago.get params[:medio_pago_id]
		@pago_comprometido = PagoComprometido.get params[:pago_comprometido_id]
		@monto = params[:monto]
		@base_name = @pago_comprometido.blank? ? "abonos[]" : "abonos[lista_abonos][#{@pago_comprometido.id}][]" 
	end
end