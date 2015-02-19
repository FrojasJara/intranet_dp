# encoding: utf-8
class Perfil
	include DataMapper::Resource
	include DataMapper::Timestamps
	include DataMapper::Historylog
	
	storage_names[:default] = 'perfiles'


	property 	:id,			Serial

	timestamps 	:at
    property 	:deleted_at, 	ParanoidDateTime
end