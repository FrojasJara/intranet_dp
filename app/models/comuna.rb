# encoding: utf-8
class Comuna
    include DataMapper::Resource
    include DataMapper::Timestamps
    include DataMapper::Historylog

    property    :id,            Serial
    property    :nombre,        String

    timestamps  :at
    property    :deleted_at,    ParanoidDateTime

    has n,      :usuarios
    has n,      :cotizaciones, "Cotizacion"

    belongs_to  :provincia
    belongs_to  :region
end