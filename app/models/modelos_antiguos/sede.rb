# coding: utf-8
class ModelosAntiguos::Sede 

    include DataMapper::Resource

    def self.default_repository_name
        :db_antigua 
    end

    storage_names[:db_antigua] = 'sedes'

    property :id_se, Serial
    property :nombre_se, String
    property :domicilio_se, String
    property :fono_se, String
    property :sector_se, String
    property :razon_social_se, String
    property :rep_legal_se, String
    property :encargado_dep_mat_se, String
    property :decreto_se, String
    property :nombre_corto_se, String
    #property :base_se, String # Chillán no tiene este campo
    property :denominado_se, String
    property :activo_se, String

    has n, :matriculas, "ModelosAntiguos::Matricula", :parent_key => "id_se", :child_key => "id_se"

    def cft?
        denominado_se == "CFT"
    end

    def ip?
        denominado_se == "IPDP"
    end
end