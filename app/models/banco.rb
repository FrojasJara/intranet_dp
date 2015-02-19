# encoding: utf-8
class Banco 
	include DataMapper::Resource
	include DataMapper::Timestamps
	include DataMapper::Historylog

	property 	:id,			Serial
	property 	:nombre, 		String, 	:required => true
	property 	:codigo, 		Integer
  
	timestamps 	:at
    property 	:deleted_at, 	ParanoidDateTime

    property 	:siaa_id,		Integer
	has n, 		:abono
end