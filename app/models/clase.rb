# encoding: utf-8
class Clase
	include DataMapper::Resource
	include DataMapper::Timestamps
	include DataMapper::Historylog

	REALIZADA 		= 1
	SUSPENDIDA 		= 2
	PLANIFICADA 	= 3
	ESTADOS 		= [
		:REALIZADA,
		:SUSPENDIDA,
		:PLANIFICADA
	]

	PLANIFICACION 	= 1
	REPROGRAMACION	= 2
	ORIGENES = [
		:PLANIFICACION,
		:REPROGRAMACION
	]

	property 	:id,							Serial
	property 	:numero, 						Integer
	property 	:horas, 						Integer
	property 	:origen, 						Integer 
    property    :estado,	               		Integer
    property    :fecha_planificada,	        	Date
    property    :fecha_registro_asistencia,	    DateTime
    property    :fecha_suspension,	        	Date

	timestamps 	:at

	belongs_to 	:seccion
	has n, :horarios_clases, "HorariosClase"
	has n, :asistencias

end