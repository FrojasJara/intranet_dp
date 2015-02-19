# encoding: utf-8
class Institucion
	include DataMapper::Resource
	include DataMapper::Timestamps
	include DataMapper::Historylog

	storage_names[:default] = 'instituciones'

	IP 		= 1
	CFT 	= 2
	CEIA 	= 3
	PREU 	= 4
	OTEC 	= 5
	
	TIPOS 	= [
		:IP,
		:CFT,
		:CEIA,
		:PREU,
		:OTEC
	]

	property 	:id,			Serial
	property 	:tipo, 			Integer
	property 	:rut,			String, :length => 15
	property 	:nombre,		String, :length => 100
	property 	:razon_social, 	String, :length => 100
	
	timestamps 	:at
    property 	:deleted_at, 	ParanoidDateTime

	has n, 		:institucion_sede
end