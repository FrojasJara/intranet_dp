# encoding: utf-8
class Horario
	include DataMapper::Resource
	include DataMapper::Timestamps
	include DataMapper::Historylog

	LUNES 		= 1
	MARTES 		= 2
	MIERCOLES 	= 3
	JUEVES 		= 4
	VIERNES 	= 5
	SABADO 		= 6
	DOMINGO 	= 7
	DIAS 		= [
		:LUNES, 
		:MARTES, 
		:MIERCOLES, 
		:JUEVES, 
		:VIERNES, 
		:SABADO, 
		:DOMINGO
	]

	property 	:id,			Serial
	property 	:dia, 			Integer  

	timestamps 	:at
    property 	:deleted_at, 	ParanoidDateTime

	belongs_to 	:bloque_horario
	belongs_to 	:seccion
	belongs_to 	:sala

	has n, :clases, "HorariosClase"
end