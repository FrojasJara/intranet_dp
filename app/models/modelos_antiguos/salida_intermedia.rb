class ModelosAntiguos::SalidaIntermedia
    include DataMapper::Resource

    def self.default_repository_name
        :db_antigua 
    end
    
    storage_names[:db_antigua] = 'salida_intermedia'

    property :oid,              Serial
    property :rut_al,           Integer
    property :id_ca,            Integer
    property :sem_si,           Integer
    property :ano_si,           Integer
    property :id_tp,            Integer

    belongs_to :alumno, "ModelosAntiguos::Persona", :parent_key => "rut_pe", :child_key => "rut_al"
end