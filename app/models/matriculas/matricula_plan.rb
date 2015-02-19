# encoding: utf-8
class Matriculas::MatriculaPlan

	def self.buscar_por_rut q
		data = []

		matriculas = MatriculaPlan.all(
			:alumno_plan_estudio => {
				:alumno => {
					:datos_personales => {
						:rut 		=> q
					}
				}
			}
		)

		inscripciones_plan = matriculas.alumno_plan_estudio
		alumnos = inscripciones_plan.alumno
		usuarios = alumnos.datos_personales
		instituciones_sede_plan = inscripciones_plan.institucion_sede_plan
		instituciones_sedes = instituciones_sede_plan.institucion_sede
		instituciones = instituciones_sedes.institucion
		sedes = instituciones_sedes.sede
		planes_estudio = instituciones_sede_plan.plan_estudio
		periodos = matriculas.periodo

		matriculas.each do |m|
			inscripcion_plan = inscripciones_plan.select{ |i| i.id == m.alumno_plan_estudio_id }.first
			alumno = alumnos.select{ |a| a.id == inscripcion_plan.alumno_id }.first
			usuario = usuarios.select{ |u| u.id == alumno.usuario_id }.first
			institucion_sede_plan = instituciones_sede_plan.select{ |i| i.id == inscripcion_plan.institucion_sede_plan_id }.first
			institucion_sede = instituciones_sedes.select{ |i| i.id == institucion_sede_plan.institucion_sede_id }.first
			institucion = instituciones.select{ |i| i.id == institucion_sede.institucion_id }.first
			sede = sedes.select{ |s| s.id == institucion_sede.sede_id }.first
			plan_estudio = planes_estudio.select{ |p| p.id == institucion_sede_plan.plan_estudio_id }.first
			periodo = periodos.select{ |p| p.id == m.periodo_id }.first

			data << {
				:matricula 			=> m,
				:usuario 			=> usuario,
				:inscripcion_plan 	=> inscripcion_plan,
				:plan_estudio 		=> plan_estudio,
				:sede 				=> "#{institucion.nombre} - #{sede.nombre}",
				:periodo 			=> periodo
			}
		end		

		data
	end

	def self.resumen_planes matricula_id
		data = []
		matricula = MatriculaPlan.get matricula_id

		planes = matricula.planes_pago
		plan_vigente = planes.select{ |plan| plan.estado == PlanPago::VIGENTE }.first
		pagares = planes.pagares :order => :estado.asc
		pagos_comprometidos = planes.pagos_comprometidos :order => [:numero_cuota.asc]
		abonos = pagos_comprometidos.abonos :numero_documento.not => nil, :fields => [:numero_documento]
		documentos_venta = planes.documentos_ventas

		planes.each do |plan|
			item = {}

			item[:plan] = plan
			item[:documento] = documentos_venta.select{ |documento| plan.id == documento.plan_pago_id }.first
			item[:pagares] = pagares.select{ |pagare| plan.id == pagare.plan_pago_id }
			pagos_plan = pagos_comprometidos.select{ |pago| plan.id == pago.plan_pago_id }

			# Pagos contado
			pagos_contado = pagos_plan.select { |pago| pago.estado == PagoComprometido::PAGADO and pago.tipo_cuota == nil }
			item[:pagos_contado] = pagos_contado

			# Cheques
			cheques = pagos_plan.select { |pago| pago.tipo_cuota == PagoComprometido::CHEQUE }
			item[:cheques] = cheques.map do |pago|
				{
					:pago 	=> pago,
					:abono 	=> abonos.select{ |abono| pago.id == abono.pago_comprometido_id }.first
				}
			end

			# Pagares
			pagares_plan = pagares.select{ |pagare| plan.id == pagare.plan_pago_id }
			item[:detalle_pagares] = pagares_plan.map do |pagare|
				item2 = {}
				item2[:pagare] = pagare
				cuotas = pagos_comprometidos.select{ |pago| pagare.id == pago.pagare_id }.group_by{ |pago| pago.numero_cuota }
				item2[:cuotas] = cuotas.map do |cuota, pagos|
					{
						:pagos 		=> pagos,
						:total 		=> pagos.map{ |pago| pago.monto }.inject(:+)
					}
				end
				item2
			end 

			data << item
		end

		return plan_vigente, data
	end
end