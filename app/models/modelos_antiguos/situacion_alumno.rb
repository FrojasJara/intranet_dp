# coding: utf-8
class ModelosAntiguos::SituacionAlumno 

    include DataMapper::Resource

    def self.default_repository_name
        :db_antigua 
    end

    storage_names[:db_antigua] = 'situaciones_alumnos'

    property :id_sa, Integer, :key => true
    property :rut_al, String, :key => true
    property :fh_sa, DateTime
    property :id_si, Integer, :key => true
    property :nro_doc_sa, Integer
    property :id_ca, Integer, :key => true
    property :sem_sa, Integer
    property :ano_sa, Integer
    property :fh_trans_sa, DateTime
    property :user_sa, String, :length => 60
    property :ip_sa, String
    property :rut_em, String
    property :id_se, Integer
    property :id_cs, Integer
    property :obs_sa, String

    belongs_to :alumno, "ModelosAntiguos::Persona", :parent_key => "rut_pe", :child_key => "rut_al"
    belongs_to :carrera, "ModelosAntiguos::Carrera", :parent_key => "id_ca", :child_key => "id_ca"    

    
end

