# encoding: utf-8
class BloqueHorario
	include DataMapper::Resource
	include DataMapper::Timestamps
	include DataMapper::Historylog

	storage_names[:default] = 'bloques_horarios'

	property 	:id,				Serial
	property 	:numero, 			Integer
	property 	:nombre,			String
	property 	:hora_inicio, 		String
	property 	:hora_termino, 		String
	property 	:siaa_id,			Integer
	property 	:siaa_updated_at,	DateTime
	property    :siaa_id_sede_sync, Integer
	
	timestamps 	:at
    property 	:deleted_at, 		ParanoidDateTime

	has n, 		:horarios

	belongs_to :periodo, :require =>  false
	belongs_to :sede


	def nombre
		hora_inicio + " - " + hora_termino
	end
end