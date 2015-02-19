# encoding: utf-8
class TipoAbono
    include DataMapper::Resource
    include DataMapper::Timestamps

    MATRICULAS   = 1
    CERTIFICADOS = 2
    OTROS        = 10
    TIPOS        = [:MATRICULAS, :CERTIFICADOS, :OTROS]

    MATRICULA      = 1
    CUOTA          = 2
    CERTIFICADO    = 3
    TITULO         = 4
    ESPECIFICACION  = [:MATRICULA, :CUOTA, :CERTIFICADO, :TITULO]


    property    :id,             Serial
    property    :nombre,         String, :length => 64, :required => true
    property    :alias,          String, :length => 64, :required => true
    property    :tipo,           Integer
    property    :especificacion, Integer

    property    :siaa_id,       Integer

    has n, :abonos
    has n, :certificados
    timestamps  :at

    property    :deleted_at,                            ParanoidDateTime
    property    :siaa_id,       Integer

    property    :slug,      Slug

end