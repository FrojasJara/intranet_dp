# encoding: utf-8
class ElectivoDictado
    include DataMapper::Resource
    include DataMapper::Timestamps
	include DataMapper::Historylog

    storage_names[:default] = 'electivos_dictados'

    property 	:id,       		Serial
    timestamps 	:at
    property 	:deleted_at, 	ParanoidDateTime

    belongs_to 	:asignatura
    belongs_to 	:electivo
    belongs_to 	:periodo
    has n, 		:secciones_dictadas, "SeccionDictada"
end