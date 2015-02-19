# encoding: utf-8
class DocenteTrabajoTitulo
    include DataMapper::Resource
    include DataMapper::Timestamps
    include DataMapper::Historylog

    storage_names[:default] = 'docentes_trabajos_titulos'

    GUIA		= 1
    INFORMANTE  = 2

    TIPO     = [:GUIA,:INFORMANTE]

    property    :id,			Serial
    property    :nota,          Float
    property    :tipo,          Integer

    property    :deleted_at,    ParanoidDateTime
    timestamps  :at

    belongs_to  :trabajo_titulo
    belongs_to  :docente , "Docente", :child_key => "docente_id"

end