# coding: utf-8
class ModelosAntiguos::Region 

    include DataMapper::Resource

    def self.default_repository_name
        :db_antigua 
    end

    storage_names[:db_antigua] = 'regiones'

    property :id_rg,               	Serial
    property :nombre_rg,           	String
    property :id_ps,				Integer
    
end