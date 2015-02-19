# encoding: utf-8
class PracticaProfesional
    include DataMapper::Resource
    include DataMapper::Timestamps
    include DataMapper::Historylog

    storage_names[:default] = 'practicas_profesionales'

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
    property    :lugar,   		String,             :length => 500
    property    :nota,          Float
    property    :estado,   		Integer

    property    :deleted_at,    ParanoidDateTime
    timestamps  :at

    belongs_to  :alumno_inscrito_seccion

end