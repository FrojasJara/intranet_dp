# encoding: utf-8
class CalculoPago
	include DataMapper::Resource
	include DataMapper::Timestamps
	include DataMapper::Historylog

	property 	:id,			Serial
	timestamps 	:at
    property 	:deleted_at, 	ParanoidDateTime
end