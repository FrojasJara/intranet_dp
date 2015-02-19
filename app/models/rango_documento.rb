# encoding: utf-8
class RangoDocumento
    include DataMapper::Resource
    include DataMapper::Timestamps
    include DataMapper::Historylog
            
    BOLETA  = 1
    FACTURA = 2
    PAGARE  = 3
    TIPOS   = [
        :BOLETA,
        :FACTURA,
        :PAGARE
    ]

    IP                  = 1
    CFT                 = 2
    DISTANCIA           = 3
    DISTANCIA_DEPOSITO  = 4
    CEIA                = 5
    PREU                = 6
    OTEC                = 7

    TALONARIOS_DISTANCIA = [
        DISTANCIA, DISTANCIA_DEPOSITO
    ]

    TALONARIOS_PRESENCIALES = [
        IP, CFT, CEIA, PREU, OTEC
    ]

    CENTRO_COSTOS = [
        :IP,
        :CFT,
        :DISTANCIA,
        :DISTANCIA_DEPOSITO,
        :CEIA,
        :PREU,
        :OTEC
    ]

    #ESTADOS EJECUTIVO MATRICULAS
    
    HABILITADO    = 1
    DESHABILITADO = 2

    ESTADOS   = [
        :HABILITADO,
        :DESHABILITADO
    ]

    property    :id,               Serial
    property    :inicio,           Integer,        min: 1
    property    :fin,              Integer,        min: 1

    property    :tipo,             Integer
    property    :centro_costos,    Integer
    property    :nombre,           String
    property    :fecha_recepcion,  DateTime
    

    timestamps  :at

    belongs_to  :ejecutivo_matriculas
    belongs_to  :institucion_sede

end