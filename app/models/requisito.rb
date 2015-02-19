# encoding: utf-8
class Requisito
    include DataMapper::Resource
    include DataMapper::Timestamps
	include DataMapper::Historylog

    property 	:id, 				Serial
    property 	:siaa_id,			Integer
    property 	:siaa_updated_at,	DateTime
    property    :siaa_id_sede_sync, Integer

    timestamps 	:at
    property 	:deleted_at, 	ParanoidDateTime

    belongs_to 	:asignatura_dependiente, "Asignatura"
    belongs_to 	:asignatura_requisito, "Asignatura"

end