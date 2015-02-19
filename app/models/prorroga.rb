# encoding: utf-8
class Prorroga
    include DataMapper::Resource
    include DataMapper::Timestamps
    #include DataMapper::Historylog

    property        :id,            Serial
    property		:fecha,			Date
    property 		:observacion,	Text
    property 		:siaa_id,		Integer
    property        :porcentaje,    Integer

    timestamps :at
    belongs_to :pago_comprometido
    belongs_to :ejecutivo_matriculas
end