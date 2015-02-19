# coding: utf-8
class ModelosAntiguos::Matricula 

    include DataMapper::Resource

    def self.default_repository_name
        :db_antigua 
    end

    storage_names[:db_antigua] = 'matriculas'


    property :oid,  Serial
    property :rut_al, Integer, :key => true
    property :rut_ap, String, :key => true
    property :sem_ma, Integer, :key => true
    property :ano_ma, Integer, :key => true
    #property :fh_ma, ZonedTime
    property :fh_ma, String
    property :id_jo, Integer
    property :id_ca, Integer, :key => true
    property :rut_em, Integer
    property :id_se, Integer, :key => true
    property :user_ma, String, :length => 60
    property :ip_ma, String, :length => 60
    #property :fh_trans_ma, ZonedTime
    property :curso_ma, String, :length => 60

    belongs_to :alumno, "ModelosAntiguos::Persona", :parent_key => "rut_pe", :child_key => "rut_al"
    belongs_to :apoderado, "ModelosAntiguos::Persona", :parent_key => "rut_pe", :child_key => "rut_ap"
    belongs_to :carrera, "ModelosAntiguos::Carrera", :parent_key => "id_ca", :child_key => "id_ca"    
    belongs_to :sede, "ModelosAntiguos::Sede", :parent_key => "id_se", :child_key => "id_se"


    def fecha_matricula
        self.fh_ma.nil? ? DateTime.now : self.fh_ma.split(".").first.gsub("20011-", "2011-").to_datetime
    end

    def self.migrar(anio)
        all(:ano_ma => anio).each do |item|
            MatriculaPlan.create(
                :jornada => item.id_jo,
                :rut_al => item.rut_al
            )
        end
    end
end

