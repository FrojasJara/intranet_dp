# encoding: utf-8
class Permiso
	include DataMapper::Resource
	include DataMapper::Timestamps
	include DataMapper::Historylog

	property 	:id,			Serial

	property	:procedimiento, String
	property	:menu_opcion, String

	property 	:deleted_at, 	ParanoidDateTime
	
	timestamps 	:at
    

    belongs_to :perfil, :required => false

end