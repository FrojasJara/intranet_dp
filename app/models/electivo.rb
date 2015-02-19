# encoding: utf-8
class Electivo
    include DataMapper::Resource
    include DataMapper::Timestamps
    include DataMapper::Historylog

    OFRECIDO    = 1
    NO_OFRECIDO = 2
    ESTADOS     = [:OFRECIDO, :NO_OFRECIDO]

    property    :id,            Serial
    property    :nombre,        String, :length => 255
    property    :estado,        Integer, :default => self::OFRECIDO

    timestamps  :at
    property    :deleted_at,    ParanoidDateTime

    # Para el acceso a los electivos
    has n,      :link_electivos_dictados, "ElectivoDictado"
    has n,      :asignaturas, "Asignatura", :through => :link_electivos_dictados
    belongs_to  :institucion_sede

end