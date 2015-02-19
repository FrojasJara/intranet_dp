# encoding: utf-8
class Cotizacion
    include DataMapper::Resource
    include DataMapper::Timestamps

    storage_names[:default] = 'cotizaciones'

    FAMILIA_O_AMIGOS = 1
    DIARIOS_REVISTAS = 2
    INTERNET         = 3
    RADIO            = 4
    LETREROS         = 5
    FLAYERS          = 6
    CHARLAS          = 7
    FERIAS           = 8
    OTROS            = 9
    
    MEDIOS           = [:FAMILIA_O_AMIGOS, :DIARIOS_REVISTAS, :INTERNET, :RADIO, :LETREROS, :FLAYERS, :CHARLAS, :FERIAS, :OTROS]

    ADMISION         = 1
    DIFUSION         = 2

    TIPOS            = [:ADMISION, :DIFUSION]


    property    :id,                    Serial
    property    :rut,                   String

    property    :email,                 String, required: false, :format => :email_address#, :length => 32 
    property    :nombre,                String
    property    :apellido,              String
    property    :domicilio,             String
    property    :villa_poblacion,       String
    property    :sector,                String, :length => 50

    property    :telefono_fijo,         String
    property    :telefono_movil,        String

    property    :medio,                 Integer
    property    :institucion_origen,    String
    property    :tipo,                  Integer, required: true

    timestamps  :at

    belongs_to  :region
    belongs_to  :comuna

    belongs_to :institucion_sede_plan
    belongs_to :ejecutivo_matriculas
end