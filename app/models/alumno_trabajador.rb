# encoding: utf-8
class AlumnoTrabajador
	include DataMapper::Resource
	include DataMapper::Timestamps
	include DataMapper::Historylog

	storage_names[:default] = 'alumnos_trabajadores'

	property 	:id, 			Serial
	timestamps 	:at
    property 	:deleted_at, 	ParanoidDateTime


	belongs_to 	:alumno_plan_estudio
	belongs_to 	:periodo
end