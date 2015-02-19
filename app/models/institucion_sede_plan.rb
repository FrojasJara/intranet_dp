# encoding: utf-8
class InstitucionSedePlan
	include DataMapper::Resource
	include DataMapper::Timestamps
	include DataMapper::Historylog
	include DataMapper::Utils

	storage_names[:default] = 'institucion_sede_planes'

	# Estados
	ABIERTA	= 1
	CERRADA = 2
	ESTADOS = [:ABIERTA, :CERRADA]

	# Jornadas de estudio
	DIURNA 		= 1
	VESPERTINA 	= 2
	TARDE 		= 3
	JORNADAS 	= [:DIURNA, :VESPERTINA, :TARDE]
	JORNADAS_EFECTIVAS = [:DIURNA, :VESPERTINA]

	# Modalidad de estudios
	PRESENCIAL 		= 1
	DISTANCIA 		= 2
	MODALIDADES 	= [:PRESENCIAL, :DISTANCIA]

	property 	:id,				Serial
	property 	:estado, 			Integer, :required => true
	property 	:jornada, 			Integer
	property 	:modalidad, 		Integer, :required => true
	property 	:siaa_id,			Integer
	property 	:siaa_updated_at, 	DateTime
	property	:siaa_id_sede_sync,	Integer

	timestamps 	:at
 	property 	:deleted_at, 	ParanoidDateTime

	belongs_to 	:institucion_sede
	belongs_to 	:plan_estudio

	# Luego de la importacion, remover "false"
	belongs_to	:periodo, required: false
	
	has n, 		:alumno_plan_estudio
	has n,		:aranceles, "PrecioArancel"
	has n,		:matriculas, "PrecioMatricula"
	has n,		:docentes, "DocenteTrabaja"
	has n, 		:cotizaciones, "Cotizacion"



	def self.planes_alumno_nuevo periodo_id, sede_id
		Matriculas::InstitucionSedePlan.planes_alumno_nuevo periodo_id, sede_id
	end

	def self.planes_alumno_superior periodo_id, sede_id
		Matriculas::InstitucionSedePlan.planes_alumno_superior periodo_id, sede_id
	end

	def self.obtener_planes attrs = {}
		attrs[:fields] = %w[id institucion_sede_id plan_estudio_id periodo_id]
		attrs[:estado] = ABIERTA

		items = []

		planes_estudios = PlanEstudio.all fields: %w[id titulo_profesional revision anio_inicio anio_fin]

		all( fields: attrs[:fields], estado: attrs[:estado] ).each do |ipe|
			pe = planes_estudios.select{|x| x.id == ipe.plan_estudio_id}.first
			item = {
				nombre: "#{pe.titulo_profesional} [#{pe.anio_inicio} #{pe.anio_fin}] #{pe.revision}"
			}
			attrs[:fields].each do |f|
				item[f.to_sym] = ipe.send(f)
			end
			item[:anio_inicio] = (pe.anio_inicio.blank? ? 0 : pe.anio_inicio).to_i
			item[:anio_fin] = (pe.anio_fin.blank? ? 0 : pe.anio_fin).to_i

			items << item
			#puts "PLANES: #{items.inspect()}".bold
		end
		items = items.sort {|a, b| [b[:anio_fin], b[:anio_inicio]] <=> [a[:anio_fin], a[:anio_inicio]]}
		#items.sort! {|a, b| b[:anio_fin] <=> a[:anio_fin]}
	end


end
