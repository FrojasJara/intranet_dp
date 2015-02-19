# encoding: utf-8
class Carrera
    include DataMapper::Resource
    include DataMapper::Timestamps
    include DataMapper::Historylog
    
    property        :id,                                    Serial
    property        :nombre,                                String,         :length => 256
    
    
    timestamps      :at
    property        :deleted_at,                            ParanoidDateTime
    
    has n,          :PlanEstudio
    
end