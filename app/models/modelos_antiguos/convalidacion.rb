# coding: utf-8
class ModelosAntiguos::Convalidacion 

    include DataMapper::Resource

    def self.default_repository_name
        :db_antigua 
    end


    
    storage_names[:db_antigua] = 'convalidaciones'

    property :oid,          Integer, key: true
    property :rut_al,       Integer
    property :id_ca,        Integer
    property :id_as,        Integer
    property :fh_co,        String
    property :rut_resp_co,  Integer
    property :id_dn,        Integer #?
    property :carrera_co,   Integer
    property :id_tv,        Integer #1 Convalidacion 2 Homologacion
    property :sem_co,       Integer
    property :ano_co,       Integer
    property :id_se,        Integer
    property :carrera_co2,  String
    property :nro_docto_co, Integer
    

    belongs_to :alumno, "ModelosAntiguos::Persona", :parent_key => "rut_pe", :child_key => "rut_al"
    belongs_to :carrera, "ModelosAntiguos::Carrera", :parent_key => "id_ca", :child_key => "id_ca"    

    
    def nombre
        carrera_co2.unpack("C*").pack("U*").to_s unless carrera_co2.blank?
    end

    def tipo
        self.id_tv
    end

end

