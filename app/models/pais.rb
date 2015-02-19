# encoding: utf-8
class Pais
    include DataMapper::Resource
    include DataMapper::Timestamps
    include DataMapper::Historylog

    storage_names[:default] = 'paises'

    property    :id,            Serial
    property    :nombre,        String

    property    :lat,           String
    property    :lng,           String
    property    :count,         String
    property    :iso,           String
    property    :iso3,          String

    timestamps  :at
    property    :deleted_at,    ParanoidDateTime

    has n,      :region
    has n,      :usuarios
end