# encoding: utf-8
class Coordinador
	include DataMapper::Resource
	include DataMapper::Timestamps

	storage_names[:default] = 'coordinador_carreras'

	property 	:id,			  Serial


    timestamps 	:at
    property 	:deleted_at, 	  ParanoidDateTime

    belongs_to 	:sede,              required: false
    belongs_to 	:escuela,           required: false
    belongs_to  :usuario,           required: false
    belongs_to 	:plan_estudio, 		required: false
end