# encoding: utf-8
class Sala
	include DataMapper::Resource
	include DataMapper::Timestamps
    include DataMapper::Historylog

	property    :id,		        Serial
    property    :nombre,            String
    property    :piso,              Integer
    property    :capacidad,         Integer
    property    :es_laboratorio,    Boolean
    property    :siaa_id,           Integer
    property    :siaa_updated_at,   DateTime
    property    :siaa_id_sede_sync, Integer

    timestamps  :at
    property    :deleted_at,        ParanoidDateTime

    belongs_to  :sede
    has n,      :horarios


    def nombre_largo
        self.es_laboratorio ? "Laboratorio #{self.nombre}" : "Sala #{self.nombre}"
    end
end