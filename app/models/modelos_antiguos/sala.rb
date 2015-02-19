class ModelosAntiguos::Sala
    include DataMapper::Resource

    def self.default_repository_name
        :db_antigua 
    end
    
    storage_names[:db_antigua] = 'salas'

    property :id_sl,            Serial
    property :id_se,            Integer
    property :sem_sl,           Integer
    property :ano_sl,           Integer
    property :nombre_sl,        String
    property :alias_sl,         String
    property :capacidad_sl,     Integer
    property :piso_sl,          Integer

end