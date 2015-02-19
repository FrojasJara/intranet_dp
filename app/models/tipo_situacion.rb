# encoding: utf-8
class TipoSituacion
    include DataMapper::Resource
    include DataMapper::Timestamps

    storage_names[:default] = 'tipos_situaciones'

    property    :id,            Serial
    property    :nombre,        String

    property    :deleted_at,    ParanoidDateTime
    timestamps  :at

end