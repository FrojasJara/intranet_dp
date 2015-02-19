# coding: utf-8
class ModelosAntiguos::DetalleConvalidacion 

    include DataMapper::Resource

    def self.default_repository_name
        :db_antigua 
    end
    
    storage_names[:db_antigua] = 'detalle_convalidaciones'

    property :oid,          Integer, key: true
    property :id_dc,        Integer
    property :rut_al,       Integer
    property :id_se,        Integer
    property :id_ca,        Integer
    property :id_as,        Integer
    property :nom_asig_conv,String
    property :sem_dc,       Integer
    property :ano_dc,       Integer
    property :sem_cursa,    Integer
    property :ano_cursa,    Integer
    property :nota_dc,      Float

    belongs_to :alumno, "ModelosAntiguos::Persona", :parent_key => "rut_pe", :child_key => "rut_al"
    belongs_to :carrera, "ModelosAntiguos::Carrera", :parent_key => "id_ca", :child_key => "id_ca"    

    
end

