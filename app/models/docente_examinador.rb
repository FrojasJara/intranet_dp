# encoding: utf-8
class DocenteExaminador
    include DataMapper::Resource
    include DataMapper::Timestamps
    include DataMapper::Historylog

    storage_names[:default] = 'docentes_examinadores'

    property    :id,			     Serial
    property    :nota_expocision,    Float
    property    :nota_defensa,       Float

    property    :deleted_at,    ParanoidDateTime
    timestamps  :at

    belongs_to  :docente, "Docente", :child_key => "docente_id"
    belongs_to  :examen_titulo, "ExamenTitulo", :child_key => "examen_titulo_id"
end