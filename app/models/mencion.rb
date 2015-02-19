# encoding: utf-8
class Mencion
	include DataMapper::Resource
	include DataMapper::Timestamps
	include DataMapper::Historylog

    storage_names[:default] = 'menciones'

	property 	:id,			Serial
	property 	:nombre,		String
	property 	:duracion,		Integer
	property 	:titulo,		String

	timestamps 	:at
    property 	:deleted_at, 	ParanoidDateTime

	belongs_to 	:plan_estudio
end