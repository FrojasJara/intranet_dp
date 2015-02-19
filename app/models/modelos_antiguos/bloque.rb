# coding: utf-8
class ModelosAntiguos::Bloque 
    include DataMapper::Resource

    def self.default_repository_name
        :db_antigua 
    end
    
    storage_names[:db_antigua] = 'bloques'

    property :oid,              Serial
    property :id_bl,            Integer
    property :nombre_bl,        String
    property :hora_ini_bl,      String
    property :hora_fin_bl,      String
    property :id_se,            Integer
    property :id_jo,            Integer
    property :sem_bl,           Integer
    property :ano_bl,           Integer

end

