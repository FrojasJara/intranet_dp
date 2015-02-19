# encoding: utf-8
class Provincia
	include DataMapper::Resource
	include DataMapper::Timestamps
	include DataMapper::Historylog

	property 	:id,       		Serial
	property 	:nombre,   		String
	property 	:capital,  		String

	timestamps 	:at
    property 	:deleted_at, 	ParanoidDateTime

	belongs_to 	:region
	has n, 		:comunas
end