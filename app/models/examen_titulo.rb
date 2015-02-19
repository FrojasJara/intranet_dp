# encoding: utf-8
class ExamenTitulo
    include DataMapper::Resource
    include DataMapper::Timestamps
    include DataMapper::Historylog

    storage_names[:default] = 'examenes_titulos'

    PACTADO		= 1
    APROBADA    = 2
    REPROBADA   = 3

    ESTADOS     = [
        :PACTADO, 
        :APROBADO,
        :REPROBADO 
    ]

    property    :id,			Serial
    property    :fecha,         Date
    property    :estado,        Integer

    property    :deleted_at,    ParanoidDateTime
    timestamps  :at

    belongs_to  :trabajo_titulo, "TrabajoTitulo", :child_key => "trabajo_titulo_id"
    has n,		:docentes_examinadores, "DocenteExaminador"

end