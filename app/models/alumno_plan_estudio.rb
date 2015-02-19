# encoding: utf-8
class AlumnoPlanEstudio
	include DataMapper::Resource
	include DataMapper::Timestamps
	include DataMapper::Historylog
	include DataMapper::Utils

	# Estados académicos del Alumno

	#        PENDIENTE            = 1  
	#        REGULAR              = 2  Alumno cursando una matricula
	#        REGULAR_CON_ABANDONO = 3
	#        CON_PERDIDA          = 4  Alumno que pierde la carrera
	#        SIN_MATRICULA        = 5  Alumno listo para matricularse
	#        SIN_INSCRIPCION      = 6  Alumno listo para inscribir ramos
	#        POSTERGADO           = 7  Deja de estudiar por un tiempo y luego regresa
	#        CONGELADO            = 8
	#        ANULADO              = 9  Alumno que anula su plan de estudio
	#        NCR                  = 10
	#        EGRESADO             = 11 Continuidad de estudios de la carrera técnica al IP
	#        TITULADO             = 12 Cuando pasa de Tecnico a IP
	#        EXALUMNO             = 13
	#        RETIRADO             = 14 Cuando un alumno deja de estudiar (Para cambios carrera)
	#        DESERTOR             = 15
	#        PROMOVIDO            = 16 Paso de curso en el CEIA/Preu
	#        REPITENCIA           = 17 
	#        CONVALIDADO          = 18 Reconocimiento de ramos en otra carrera
	#        TRASLADADO           = 19 Cambia de sede


	property 	:id,				Serial
	property 	:anio_ingreso, 		Integer, :required => true, :min => 1950, :max => 9999
	property 	:estado, 			Integer, :required => true, :default => Alumno::SIN_INSCRIPCION
	property 	:semestre, 			Integer, :required => true, :default => 0, :min => 0, :max => 15
	property 	:tipo_ingreso,		Integer, :required => true, :default => Alumno::NORMAL
	property 	:es_trabajador,		Boolean, :required => true,	:default => false
	# Contadores
	property	:aprobadas,			Integer, :required => true,	:default => 0
	property	:reprobadas,		Integer, :required => true,	:default => 0
	property 	:abandonadas,		Integer, :required => true,	:default => 0
	property 	:convalidadas, 		Integer, :required => true,	:default => 0
	property 	:homologadas, 		Integer, :required => true,	:default => 0
	property    :siaa_id,           Integer
    property    :siaa_updated_at,   DateTime
    property    :siaa_id_sede_sync, Integer


	timestamps 	:at

	has n, 		:alumno_trabajador
	# => Matricula asociada
  	has n, 		:matricula_plan
  	# => Los pagos comprometidos en su plan de estudio 
    has n, 		:links_secciones_inscritas, "AlumnoInscritoSeccion"
    has n, 		:pagares
    has n, 		:documentos_venta, 			"DocumentoVenta"

	belongs_to 	:institucion_sede_plan
	belongs_to 	:alumno
	belongs_to 	:periodo
	belongs_to  :convalidacion_homologacion, required: false

	has n, 		:secciones_cursadas, "SeccionDictada", :through => :links_secciones_inscritas, :via => :seccion_dictada

    has n, 		:abono
    has n,      :certificado
    has n,		:egresado

	#has 1, :institucion_externa 
    def plan_estudio
    	institucion_sede_plan.plan_estudio
    end

    def institucion_sede
    	institucion_sede_plan.institucion_sede.nombre
    end
	
	def estado_alumno id
		var = nil
		id  = id -1

		Alumno::ESTADOS_ACADEMICOS.each_with_index do |index,item|
			if item == id
				var = index
			end
		end

		return var
	end
end