# encoding: utf-8
class Situacion
    include DataMapper::Resource
    include DataMapper::Timestamps

    storage_names[:default] = 'situaciones'

    ACADEMICO      = 1
    ADMINISTRATIVO = 2
    TIPOS          = [:ACADEMICO, :ADMINISTRATIVO]

    property    :id,                        Serial
    property    :fecha,                     Date
    property    :resolucion,                String
    property    :observacion,               Text
    property    :estado,                    Integer
    property    :estado_previo,             Integer
    property    :tipo,                      Integer

    belongs_to  :tipo_situacion,            required: false
    belongs_to  :plan_pago
    belongs_to  :ejecutivo_matriculas
    belongs_to  :periodo

    timestamps  :at

end