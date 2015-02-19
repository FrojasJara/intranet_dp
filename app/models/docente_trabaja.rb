# encoding: utf-8
class DocenteTrabaja
	include DataMapper::Resource
	include DataMapper::Timestamps
	include DataMapper::Historylog

	storage_names[:default] = 'docentes_trabajan'

	property 	:id,			Serial

	belongs_to 	:docente
	belongs_to 	:institucion_sede_plan

	timestamps 	:at
    property 	:deleted_at, 	ParanoidDateTime
end