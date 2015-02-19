# encoding: utf-8
require "date"

class Matriculas::Pagos

	def self.detalle_cajas_diarias ejecutivo_matriculas_id, fecha, institucion_sede_id, modalidad
		fecha_tiempo_inicio, fecha_tiempo_final = Matriculas::Pagos.rango_consulta_caja_diaria fecha

		ejecutivo = {}
		ejecutivo[:ejecutivo] = EjecutivoMatriculas.get! ejecutivo_matriculas_id
		ejecutivo[:datos_personales] = ejecutivo[:ejecutivo].datos_personales
		ejecutivo[:rangos_documentos] = ejecutivo[:ejecutivo].rangos_documentos
		es_presencial = modalidad.to_i == InstitucionSedePlan::PRESENCIAL

		# Las personas si existen en el sistema
		documentos_ejecutivo = ejecutivo[:ejecutivo].documentos_venta(
			:fecha_emision 				=> fecha_tiempo_inicio..fecha_tiempo_final, 
			:institucion_sede_id 		=> institucion_sede_id,
			:estado.not 				=> DocumentoVenta::ANULADA, 					
			:alumno_plan_estudio_id.not	=> nil
		)

		if es_presencial
			# Las personas no existen en el sistema presenciales
			documentos_ejecutivo_anonimos_presenciales = 

				ejecutivo[:ejecutivo].documentos_venta(
					:fecha_emision 				=> fecha_tiempo_inicio..fecha_tiempo_final, 
					:institucion_sede_id 		=> institucion_sede_id, 
					:estado.not 				=> DocumentoVenta::ANULADA, 	
					:alumno_plan_estudio_id		=> nil,
					:modalidad 					=> nil
				) +
				ejecutivo[:ejecutivo].documentos_venta(
					:fecha_emision 				=> fecha_tiempo_inicio..fecha_tiempo_final, 
					:institucion_sede_id 		=> institucion_sede_id, 
					:estado.not 				=> DocumentoVenta::ANULADA, 	
					:alumno_plan_estudio_id		=> nil,
					:modalidad 					=> DocumentoVenta::PRESENCIAL
				)
		else
			# Las personas no existen en el sistema distancia
			documentos_ejecutivo_anonimos_distancia = ejecutivo[:ejecutivo].documentos_venta(
				:fecha_emision 				=> fecha_tiempo_inicio..fecha_tiempo_final, 
				:institucion_sede_id 		=> institucion_sede_id, 
				:estado.not 				=> DocumentoVenta::ANULADA, 	
				:alumno_plan_estudio_id		=> nil,
				:modalidad 					=> DocumentoVenta::DISTANCIA
			)
		end

		abonos = documentos_ejecutivo.abonos(
			:alumno_plan_estudio => { 
				:institucion_sede_plan => { 
					:modalidad 				=> modalidad
				} 
			}
		)

		if es_presencial	
			abonos_anonimos = documentos_ejecutivo_anonimos_presenciales.abonos
		else	
			abonos_anonimos = documentos_ejecutivo_anonimos_distancia.abonos	
		end

		# ATENTO A ESTE CAMBIO EN PRODUCCION
		# Tenemos que remover documentos de distancia que hayan aparecido en la consulta primera
		documentos_validos = abonos.documento_venta.map{ |d| d.id }
		documentos_ejecutivo.delete_if{ |d| not documentos_validos.include? d.id }
		valores_documentos_ejecutivos = documentos_ejecutivo.map{ |documento| { :numero => documento.numero, :tipo => documento.tipo } }
		
		if es_presencial	
			valores_documentos_ejecutivos.concat documentos_ejecutivo_anonimos_presenciales.map{ |documento| { :numero => documento.numero, :tipo => documento.tipo } }
		else
			valores_documentos_ejecutivos.concat documentos_ejecutivo_anonimos_distancia.map{ |documento| { :numero => documento.numero, :tipo => documento.tipo } }
		end
		
		ejecutivo[:rangos_documentos].delete_if do |rango|
			valores_documentos_ejecutivos.count { |valor| valor[:tipo] == rango.tipo and rango.inicio <= valor[:numero] and valor[:numero] <= rango.fin } == 0
		end
		ejecutivo[:rangos_documentos] = ejecutivo[:rangos_documentos].group_by{ |rango| rango.tipo }

		tipos_abono = abonos.tipo_abono
		inscripciones_planes = abonos.alumno_plan_estudio
		alumnos = inscripciones_planes.alumno
		usuarios_alumnos = alumnos.datos_personales
		instituciones_sedes_planes = inscripciones_planes.institucion_sede_plan
		planes_estudio = instituciones_sedes_planes.plan_estudio
		medios_pago = abonos.medio_pago

		cajas = []

		if es_presencial	
			documentos_ejecutivo.concat documentos_ejecutivo_anonimos_presenciales
			abonos.concat abonos_anonimos
		else
			documentos_ejecutivo.concat documentos_ejecutivo_anonimos_distancia
			abonos.concat abonos_anonimos
		end

		abonos.each do |abono|
			item = {}

			item[:abono] = abono
			item[:documento] = documentos_ejecutivo.select{ |documento| documento.id == abono.documento_venta_id }.first
			item[:medio_pago] = medios_pago.select{ |medio| medio.id == abono.medio_pago_id }.first

			medio_pago = medios_pago.select{ |medio| medio.id == abono.medio_pago_id }.first
			# Pagare/Cuota
			if medio_pago.id == 2
				item[:medio_pago] = abono.tipo_cheque fecha
			else
				item[:medio_pago] = medio_pago.nombre
			end

			item[:tipo_abono] = tipos_abono.select{ |t| t.id == abono.tipo_abono_id }.first

			datos_personales = {}

			# Boleta a un alumno existente
			if not abono.alumno_plan_estudio_id.nil?
				inscripcion_plan = inscripciones_planes.select{ |i| i.id == abono.alumno_plan_estudio_id }.first
				alumno = alumnos.select{ |a| a.id == inscripcion_plan.alumno_id }.first
				usuario_alumno = usuarios_alumnos.select{ |u| u.id == alumno.usuario_id }.first

				datos_personales = {
					:nombre 	=> usuario_alumno.nombre,
					:rut 		=> usuario_alumno.rut
				}

				institucion_sede_plan 	= instituciones_sedes_planes.select{ |i| i.id == inscripcion_plan.institucion_sede_plan_id }.first
				plan_estudio 			= planes_estudio.select{ |p| p.id == institucion_sede_plan.plan_estudio_id }.first.nombre
				anonimo 				= false

			# Boleta anonima
			else
				datos_personales = {
					:nombre 	=> item[:documento].nombre_completo,
					:rut 		=> item[:documento].rut
				}
				plan_estudio 	= item[:documento].carrera
				anonimo 		= true
			end

			item[:datos_personales] = datos_personales
			item[:plan_estudio] 	= plan_estudio
			item[:anonimo] 			= anonimo

			cajas << item
		end

		formas_pago = []
		formas_pago_agrupadas = cajas.group_by{ |entrada| entrada[:medio_pago] }
		formas_pago_agrupadas.each do |medio, entradas|
			item = {}

			item[:medio] = medio
			item[:total] = entradas.map{ |entrada| entrada[:abono].total }.inject(:+)

			formas_pago << item
		end

		centros_costos = []
		tipos_abono.each do |tipo|
			item = {}

			item[:centro_costo] = tipo
			item[:monto] 		= abonos.select{ |abono| tipo.id == abono.tipo_abono_id }.map{ |abono| abono.monto }.inject(:+)
			item[:interes] 		= abonos.select{ |abono| tipo.id == abono.tipo_abono_id }.map{ |abono| abono.interes }.inject(:+)

			centros_costos << item
		end

		documentos_ventas = []
		documentos_agrupados = documentos_ejecutivo.group_by{ |documento| documento.tipo } 
		documentos_agrupados.each do |tipo_documento, documentos|
			item = {}

			item[:tipo] 	= tipo_documento
			item[:total]	= documentos.map{ |documento| documento.monto }.inject(:+)

			documentos_ventas << item
		end 

		return ejecutivo, cajas, formas_pago, centros_costos, documentos_ventas
	end

	def self.rango_consulta_caja_diaria fecha
		hora_limite 		= Rails.configuration.hora_limite_caja_diaria
		fecha_tiempo_ahora 	= Time.now
		fecha_ahora 		= fecha_tiempo_ahora.to_date
		fecha_consulta 		= Date.parse fecha
		fecha_consulta_ayer = fecha_consulta - 1

		fecha_tiempo_inicio = Time.parse(fecha_consulta_ayer.to_s + hora_limite) + 1
		fecha_tiempo_final 	= Time.parse(fecha + hora_limite)

		return fecha_tiempo_inicio, fecha_tiempo_final		
	end
end