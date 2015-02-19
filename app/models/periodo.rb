# encoding: utf-8
class Periodo
	include DataMapper::Resource
	include DataMapper::Timestamps
	include DataMapper::Historylog

	CERRADO 	= 1
	EN_CURSO 	= 2
	PROXIMO 	= 3
	ESTADOS 	= [
		:CERRADO,
		:EN_CURSO,
		:PROXIMO
	]

	property 	:id,					Serial
	property 	:anio,					Integer, :required => true, :min => 1950
	property 	:semestre,				Integer, :required => true, :min => 1#, :max => 2 [AV] Descomentar post-sync
	property 	:estado, 				Integer, :required => true
	property 	:siaa_updated_at, 		DateTime

	timestamps 	:at
    # property 	:deleted_at, 			ParanoidDateTime

	has n, 		:alumno_trabajador
	has n, 		:planes_pago, 			"PlanPago"
	has n, 		:matriculas, 			"MatriculaPlan"
	has n, 		:alumno_plan_estudio
	has n, 		:institucion_sede_plan
	has n, 		:secciones, 			"Seccion"
	has n, 		:bloque_horarios
	has n, 		:situaciones,			"Situacion"
	has n,		:egresados,				"Egresado"

	def self.en_curso
		Periodo.last :estado => Periodo::EN_CURSO
	end

	def self.proximo
		Periodo.last :estado => Periodo::PROXIMO
	end

	def nombre
		"#{anio}-#{semestre}"
	end

	def self.obtener_todos periodo_seleccionado_id = nil
		data = {}

		periodos = all(
			:fields => [:id, :anio, :semestre],
			:order => [:anio.desc, :semestre.desc]
		)

		data[:todos] = []
		periodos.each { |p| data[:todos] << p }

		if not periodo_seleccionado_id.nil?
			data[:seleccionado] = periodos.select { |p| p.id == periodo_seleccionado_id }.first
		else
			data[:seleccionado] = periodos.first estado: Periodo::EN_CURSO
		end

		data
	end

	def self.obtener_anio_periodo(duracion, semestre)
		if semestre % 2 == 0
			anio = semestre / 2
			periodo = 2
		else
			anio = semestre / 2 + 1
			periodo = 1
		end

		return "Año " + anio.to_s + " Ped. " + periodo.to_s
	end

	def self.buscar_anio_semestre(attrs, anio, semestre)
		first(:fields => attrs,:conditions => {:anio => anio, :semestre => semestre})
	end

	def self.periodo_anterior periodo_id
		periodo = Periodo.get periodo_id
		sem = 0
		ano = 0
		if periodo.semestre == 1
			sem = 2
			ano = periodo.anio - 1
		else
			sem = 1
			ano = periodo.anio
		end

		Periodo.first(:anio => ano, :semestre => sem).id
	end

	def self.lista
		all(
			:fields => [:id, :anio, :semestre],
			:order => [:anio.desc, :semestre.desc]
		)
	end
end
