# coding: utf-8
class ModelosAntiguos::ConjuntoMalla 
    include DataMapper::Resource

    def self.default_repository_name
        :db_antigua 
    end
    
    storage_names[:db_antigua] = 'conjunto_mallas'

    property :oid,              Serial
    property :id_ma,            Integer
    property :id_ca,            Integer
    property :id_as,            Integer
    property :id_se,            Integer
    property :id_ni,            Integer
    property :hrs_sem_as,       Integer
    property :hrs_teo_as,       Integer
    property :hrs_lab_as,       Integer
    property :id_ta,            Integer
    property :id_tr,            Integer
    #property :porcentaje_as,    Integer
    

end

