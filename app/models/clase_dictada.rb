# encoding: utf-8
class ClaseDictada
	include DataMapper::Resource
	include DataMapper::Timestamps
	include DataMapper::Historylog

	property 	:id,						Serial
	timestamps 	:at
    property 	:deleted_at, 				ParanoidDateTime

	belongs_to 	:clase
	belongs_to 	:horario
end