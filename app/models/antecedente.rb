# encoding: utf-8
class Antecedente
    include DataMapper::Resource
    include DataMapper::Timestamps
    include DataMapper::Historylog

    PROFESIONAL     = 1
    DIPLOMADO       = 2
    MAGISTER        = 3
    DOCTORADO       = 4
    TIPOS_FORMACION           = [:PROFESIONAL, :DIPLOMADO, :MAGISTER, :DOCTORADO]

    ACADEMICA       = 1
    LABORAL         = 2
    DOCENCIA        = 3
    PERSONAL        = 4
    OTROS           = 5

    TIPOS_ANTECEDENTES = [:ACADEMICA, :LABORAL, :DOCENCIA, :PERSONAL, :OTROS]


    property    :id,                        Serial
    property    :lugar,                     String, :length => 256
    property    :tipo_formacion,            Integer
    property    :tipo_antecedente,          Integer
    property    :desde,                     String
    property    :hasta,                     String
    property    :descripcion,               String, :length => 100
    property    :detalle,                   Text

    timestamps  :at
    property    :deleted_at,    ParanoidDateTime

    belongs_to  :universidad,   :required => false 
    belongs_to  :docente
end