# encoding: utf-8
class Universidad
    include DataMapper::Resource
    include DataMapper::Timestamps
	include DataMapper::Historylog

    storage_names[:default] = 'universidades'

    property 	:id,       		Serial
    property 	:nombre, 		String, :length => 128

    timestamps 	:at
    property 	:deleted_at, 	ParanoidDateTime

    has n, 		:antecedentes
    # Para obtener los docentes egresados de una casa de estudios
    has n, 		:docentes_egresados, "Docente", :through => :antecedentes, :via => :docente
end