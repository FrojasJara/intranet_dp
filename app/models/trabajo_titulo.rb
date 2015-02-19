# encoding: utf-8
class TrabajoTitulo
    include DataMapper::Resource
    include DataMapper::Timestamps
    include DataMapper::Historylog

    storage_names[:default] = 'trabajos_titulos'

    APROBADA                    = 1
    REPROBADA                   = 2
    ANULADA   		            = 3
    EN_CURSO                  	= 4
    POSTERGADA					= 5
    ESTADOS     = [
        :APROBADA, 
        :REPROBADA, 
        :ANULADA, 
        :EN_CURSO,
        :POSTERGADA
    ]

    property    :id,            Serial
    property    :fecha,         Date
    property    :nombre,   		String,             :length => 300
    property    :rol,          	String,             :length => 50
    property    :estado,   		Integer

    property    :deleted_at,    ParanoidDateTime
    timestamps  :at

    belongs_to  :alumno_inscrito_seccion
    has 1,      :examen_titulo
    has n,      :docentes_trabajos_titulos , "DocenteTrabajoTitulo"

end