# encoding: utf-8
class InstitucionExterna
	include DataMapper::Resource
	include DataMapper::Timestamps
	include DataMapper::Historylog

	storage_names[:default] = 'instituciones_externas'

	property 	:id,				Serial
	property 	:nombre,			String, length: 100
	property 	:codigo, 			String
	property	:domicilio,			String, length: 100
	property 	:sector,			String

	property	:siaa_id,			Integer
	property	:siaa_updated_at,	DateTime
	property    :siaa_id_sede_sync, Integer

	timestamps 	:at
    property 	:deleted_at, 	ParanoidDateTime

    has n,		:convalidacion_homologacion

end