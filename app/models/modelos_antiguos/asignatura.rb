# coding: utf-8
class ModelosAntiguos::Asignatura 
    include DataMapper::Resource

    def self.default_repository_name
        :db_antigua 
    end
    
    storage_names[:db_antigua] = 'asignaturas'

    property :oid,              Serial
    property :id_ca,            Integer
    property :id_as,            Integer
    property :id_se,            Integer

    property :nombre_as,        String,  :length => 150
    property :alias_as,         String,  :length => 150

    def nombre
        self.nombre_as.unpack("C*").pack("U*")
    end

end

