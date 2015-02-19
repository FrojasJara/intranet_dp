# encoding: utf-8
class Matriculas::PlanPago

	def self.informacion_documentos_plan plan_pago_id
		plan = PlanPago.get! plan_pago_id

		pagares = plan.pagares :estado => Pagare::VIGENTE
		pagos_comprometidos = plan.pagos_comprometidos :order => [:numero_cuota.asc]
		abonos = pagos_comprometidos.abonos
		medios_pago = abonos.medio_pago
		bancos = abonos.banco
		t_creditos = abonos.tarjetas_credito

		data = {}

		data[:plan] = plan

		# PAGOS CONTADO
		pagos_contado = pagos_comprometidos.select{ |pago| pago.tipo_cuota == nil }
		data[:pagos_contado] = pagos_contado.map do |pago|
			item2 = {}

			item2[:pago] = pago
			item2[:abono] = abonos.select{ |abono| pago.id == abono.pago_comprometido_id }.first
			item2[:medio_pago] = medios_pago.select{ |medio| medio.id == item2[:abono].medio_pago_id }.first
			banco = bancos.select{ |banco| banco.id == item2[:abono].banco_id }.first
			t_credito = t_creditos.select{ |tarjeta| tarjeta.id == item2[:abono].tarjetas_credito_id }.first
			item2[:banco] = (not banco.nil?) ? banco.nombre : nil
			item2[:t_credito] = (not t_credito.nil?) ? t_credito.nombre : nil

			item2
		end

		# CHEQUES
		cheques = pagos_comprometidos.select{ |pago| pago.tipo_cuota == PagoComprometido::CHEQUE }
		data[:cheques] = cheques.map do |cheque|
			abono = abonos.select{ |abono| cheque.id == abono.pago_comprometido_id }.first
			{
				:pago 		=> cheque,
				:abono 		=> abono,
				:banco 		=> bancos.select{ |banco| banco.id == abono.banco_id }.first
			}
		end

		# PAGARES
		data[:pagares] = []
		pagares.each do |pagare|
			item = {}
			item[:pagare] = pagare
			
			pagos_asociados = pagos_comprometidos.select{ |pago| pagare.id == pago.pagare_id }.group_by{ |pago| pago.numero_cuota }
			item[:cuotas] = pagos_asociados.map do |cuota, pagos|
				{
					:pagos 		=> pagos,
					:total 		=> pagos.map{ |pago| pago.monto }.inject(:+)
				}
			end
			data[:pagares] << item
		end

		data[:documentos] = []
		data[:documentos] = plan.documentos_venta

		data
	end

end
