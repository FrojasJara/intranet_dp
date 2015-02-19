# encoding: utf-8
class TarjetasCredito
	include DataMapper::Resource
	include DataMapper::Timestamps
	include DataMapper::Historylog

	property 	:id,			Serial
	property 	:nombre, 		String,	:required => true, :length => 50

	timestamps 	:at
    property 	:deleted_at, 	ParanoidDateTime

	has n, 		:abono

	property    :siaa_id,       Integer
end