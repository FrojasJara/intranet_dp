# coding: utf-8
class ModelosAntiguos::Derecho 
    include DataMapper::Resource

    def self.default_repository_name
        :db_antigua 
    end
    
    storage_names[:db_antigua] = 'derechos'

    property :oid,              Serial
    property :rut_us,           Integer
    property :codigo_de,        String

end

