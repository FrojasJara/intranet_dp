# encoding: utf-8
class Cobranza
    include DataMapper::Resource
    include DataMapper::Timestamps
    include DataMapper::Historylog

    storage_names[:default] = 'cobranzas'

    property    :id,                        Serial
    property    :fecha,                     Date
    property    :tipo,                      Integer

    timestamps  :at
    property    :deleted_at,                ParanoidDateTime

    property    :siaa_id,                   Integer
    property    :siaa_id_sede_sync,         Integer

    belongs_to :pago_comprometido
    belongs_to :ejecutivo_matriculas
    belongs_to :institucion_sede

    # Tipos
    EXTERNA = 1
    INCOBRABLE = 2

    TIPOS = [:EXTERNA, :INCOBRABLE]

end