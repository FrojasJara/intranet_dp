# encoding: utf-8
class Accion
	include DataMapper::Resource
	include DataMapper::Timestamps
	include DataMapper::Historylog

	storage_names[:default] = 'acciones'

	property 	:id,			Serial
	timestamps 	:at
    property 	:deleted_at, 	ParanoidDateTime
end