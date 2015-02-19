# coding: utf-8
class ModelosAntiguos::Comuna 

    include DataMapper::Resource

    def self.default_repository_name
        :db_antigua 
    end

    storage_names[:db_antigua] = 'comunas'

    property :id_cm, Serial
    property :id_cd, Integer
    property :nombre_cm, String, :length => 60

    has n, :personas, "ModelosAntiguos::Persona", :parent_key => "id_cm", :child_key => "id_cm"

    def buscar
    	Comuna.first :nombre.like => nombre_cm
    end
end

