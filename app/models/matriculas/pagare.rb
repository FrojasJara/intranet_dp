# encoding: utf-8
class Matriculas::Pagare

	def self.buscar_por_numero q
		pagare = Pagare.first :numero => q
		raise DataMapper::ObjectNotFoundError if pagare.nil?
		pagare
	end

	def self.buscar_por_rut q
		cantidad_limite = Rails.configuration.cantidad_limite_busqueda

		pagares = Pagare.all(
			:alumno_plan_estudio => {
				:alumno => {
					:datos_personales => {
						:rut 	=> q
					}
				}
			}
		)

		raise Excepciones::DemasiadosDatosException, "Por favor, trate de acotar los parámetros de su búsqueda" if pagares.size > cantidad_limite

		planes_pago = pagares.plan_pago
		matriculas = planes_pago.matricula_plan
		inscripciones_carrera = matriculas.alumno_plan_estudio
		alumnos = inscripciones_carrera.alumno
		usuarios_alumno = alumnos.datos_personales
		ejecutivos = pagares.ejecutivo_matriculas
		usuarios_ejecutivos = ejecutivos.datos_personales

		data = []

		instituciones_sedes_planes = inscripciones_carrera.institucion_sede_plan
		carreras = instituciones_sedes_planes.plan_estudio
		instituciones_sedes = instituciones_sedes_planes.institucion_sede
		instituciones = instituciones_sedes.institucion
		sedes = instituciones_sedes.sede

		pagares.each do |pagare|
			item = {}

			item[:pagare] 				= pagare
			ejecutivo 					= ejecutivos.select{ |ejecutivo| ejecutivo.id == pagare.ejecutivo_matriculas_id }.first
			item[:usuario_ejecutivo] 	= usuarios_ejecutivos.select{ |u_ejecutivo| u_ejecutivo.id == ejecutivo.usuario_id }.first
			item[:plan_pago] 			= planes_pago.select{ |plan| plan.id == pagare.plan_pago_id }.first
			item[:matricula] 			= matriculas.select{ |matricula| matricula.id == item[:plan_pago].matricula_plan_id }.first
			inscripcion_carrera 		= inscripciones_carrera.select{ |inscripcion| inscripcion.id == item[:matricula].alumno_plan_estudio_id }.first
			alumno 						= alumnos.select{ |a| a.id == inscripcion_carrera.alumno_id }.first
			item[:usuario_alumno]		= usuarios_alumno.select{ |usuario| usuario.id == alumno.usuario_id }.first
			institucion_sede_plan 		= instituciones_sedes_planes.select{ |i| i.id == inscripcion_carrera.institucion_sede_plan_id }.first
			item[:plan_estudio] 		= carreras.select{ |carrera| carrera.id == institucion_sede_plan.plan_estudio_id }.first
			institucion_sede 			= instituciones_sedes.select{ |i| i.id == institucion_sede_plan.institucion_sede_id }.first
			item[:sede] 				= sedes.select{ |sede| sede.id == institucion_sede.sede_id }.first
			item[:institucion] 			= instituciones.select{ |institucion| institucion.id == institucion_sede.institucion_id }.first

			data << item
		end

		data
	end

	def self.detalle pagare_id
		data1 = {}
		data2 = {}

		pagare = Pagare.get pagare_id
		cuotas = pagare.cuotas(:order => [:numero_cuota.asc]).group_by{ |cuota| cuota.numero_cuota }
		matricula = pagare.plan_pago.matricula_plan
		alumno_plan_estudio = pagare.alumno_plan_estudio
		usuario_alumno = alumno_plan_estudio.alumno.datos_personales
		institucion_sede_plan = alumno_plan_estudio.institucion_sede_plan
		institucion_sede = institucion_sede_plan.institucion_sede
		carrera = institucion_sede_plan.plan_estudio
		institucion = institucion_sede.nombre

		data1[:pagare] 		= pagare
		data1[:cuotas] 		= cuotas.map do |cuota, pagos|
			{
				:pagos 		=> pagos,
				:total 		=> pagos.map{ |pago| pago.monto }.inject(:+)
			}
		end
		data1[:matricula] 	= matricula

		data2[:alumno_plan_estudio] = alumno_plan_estudio
		data2[:carrera] 			= carrera
		data2[:institucion] 		= institucion
		data2[:usuario_alumno] 	= usuario_alumno

		return data2, data1
	end
end