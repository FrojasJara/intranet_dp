# encoding: utf-8
class BitacoraCobranza
	include DataMapper::Resource
	include DataMapper::Timestamps
    include DataMapper::Historylog

    storage_names[:default] = 'bitacora_cobranzas'

    TELEFONICA                   = 1
    TELEFONICA_Y_EMAIL           = 2
    SOLO_EMAIL                   = 3
    NO_CONTESTA_TELEFONO_Y_EMAIL = 4
    TELEFONO_INEXISTENTE_Y_EMAIL = 5
    TELEFONO_CAMBIO_Y_EMAIL      = 6
    CARTA                        = 9
    PRESENCIAL                   = 7
    OTRO                         = 8 

    TIPOS = [
        :TELEFONICA,
        :TELEFONICA_Y_EMAIL,
        :SOLO_EMAIL,
        :NO_CONTESTA_TELEFONO_Y_EMAIL,
        :TELEFONO_INEXISTENTE_Y_EMAIL,
        :TELEFONO_CAMBIO_Y_EMAIL,
        :CARTA,
        :PRESENCIAL,
        :OTRO
    ]

    ADMINISTRATIVA = 1
    ACADEMICA = 2

    PROCEDENCIAS = [
        :ADMINISTRATIVA,
        :ACADEMICA
    ]

    property    :id,                        Serial
    property    :fecha,                     Date
    property    :observacion,               Text
    property 	:tipo,						Integer

    timestamps  :at
    property    :deleted_at,                ParanoidDateTime

    property    :siaa_id,                   Integer
    property    :procedencia,               Integer

    belongs_to :alumno_plan_estudio
    belongs_to :usuario
    belongs_to :periodo
end