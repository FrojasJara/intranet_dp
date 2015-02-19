# encoding: utf-8
class Region
    include DataMapper::Resource
    include DataMapper::Timestamps
    include DataMapper::Historylog

    storage_names[:default] = 'regiones'

    property    :id,            Serial
    property    :nombre,        String
    property    :numero,        String

    timestamps  :at
    property    :deleted_at,    ParanoidDateTime

    has n,      :provincias
    has n,      :comunas
    has n,      :usuarios
    has n,      :cotizaciones, "Cotizacion"
    belongs_to  :pais
  
    def self.obtener_comunas id
        comunas = Comuna.all :fields => [:id, :nombre], :region_id => id
        comunas.map { |c| {:id => c.id, :nombre => c.nombre} }
    end
end