# encoding: utf-8
class Descuento
	include DataMapper::Resource
	include DataMapper::Timestamps
	#include DataMapper::Historylog

	# TIPO BENEFICIOS
	DESCUENTO   = 1
	BENEFICIO   = 2
	BECA        = 3
	TIPOS = [:DESCUENTO, :BENEFICIO, :BECA]

	VIGENTE = 1
	NO_VIGENTE = 2
	ESTADOS = [
		:VIGENTE,
		:NO_VIGENTE
	]

	property 	:id,		    		Serial
	property 	:tipo,  				Integer, 	:required => true
	property 	:estado, 				Integer, 	:default => Descuento::VIGENTE
	property 	:nombre,   				String, 	:required => true, :length => 128
	property 	:porcentaje, 			Integer, 	:required => true, :min => 0, :max => 100
	
	property 	:siaa_id,				Integer


	timestamps 	:at
    property 	:deleted_at, 			ParanoidDateTime
	property 	:siaa_id,				Integer
	has n, 		:plan_pago
end
