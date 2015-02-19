# encoding: utf-8
class TipoCertificado
    include DataMapper::Resource
    include DataMapper::Timestamps

    storage_names[:default] = 'tipos_certificados'

    property    :id,            Serial
    property    :cargo,         String
    property    :por_defecto,   Boolean, default: false

    timestamps  :at

    belongs_to :tipo_abono
    belongs_to :sede
    belongs_to :usuario
end