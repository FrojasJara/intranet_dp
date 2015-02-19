# encoding: utf-8
class SeccionDictada
	include DataMapper::Resource
	include DataMapper::Timestamps
	include DataMapper::Historylog

	storage_names[:default] = 'secciones_dictadas'

	property 	:id, 				Serial
    property 	:siaa_id_ca,        Integer
    #property 	:siaa_id_as,        Integer
    #property 	:siaa_id_se,        Integer
    #property 	:siaa_sem_ai,       Integer
    #property 	:siaa_ano_ai,       Integer
        # sem + anio = periodo

    property 	:periodo_id,		Integer

    property 	:siaa_updated_at,   DateTime
    property    :siaa_id_sede_sync, Integer

	timestamps 	:at

	belongs_to 	:asignatura
	belongs_to 	:electivo_dictado, :required => false
	belongs_to 	:seccion

	has n, 		:links_alumnos_inscritos, "AlumnoInscritoSeccion"
	has n, 		:alumnos_inscritos, "AlumnoPlanEstudio", :through => :links_alumnos_inscritos, :via => :alumno_plan_estudio

	def electivo
		electivo_dictado.electivo		
	end
end