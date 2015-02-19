# coding: utf-8
class ModelosAntiguos::CarreraImpartida 
    include DataMapper::Resource

    def self.default_repository_name
        :db_antigua 
    end
    
    storage_names[:db_antigua] = 'carreras_impartidas'

    property :oid,              Serial
    property :id_ca,            Integer
    property :id_se,            Integer
    property :sem_ci,           Integer
    property :ano_ci,           Integer
    property :id_jo,            Integer
    property :recibe_nuevo_ci,  Boolean
    property :vacantes,         Integer
    

end

