# coding: utf-8
class ModelosAntiguos::CalendarioEvaluacion 
    include DataMapper::Resource

    def self.default_repository_name
        :db_antigua 
    end
    
    storage_names[:db_antigua] = 'calendario_evaluaciones'

    property :oid,              Serial
    property :nro_ce,           Integer
    property :id_ca,            Integer
    property :id_as,            Integer
    property :seccion_ce,       Integer
    property :id_se,            Integer
    property :sem_ce,           Integer
    property :ano_ce,           Integer
    property :id_te,            Integer
    property :unidad_ce,        String
    property :fh_ce,            Date
    property :ponderacion_ce,   Float
    property :borrar,           Integer
    property :id_tn,            Integer
    

    def nombre
        self.nombre_as.unpack("C*").pack("U*")
    end

end

