# coding: utf-8
class ModelosAntiguos::Malla 
    include DataMapper::Resource

    def self.default_repository_name
        :db_antigua 
    end
    
    storage_names[:db_antigua] = 'mallas'

    property :oid,              Serial
    property :id_ma,            Integer
    property :nombre_ma,        String,  :length => 150
    property :sem_ini_ma,       Integer
    property :ano_ini_ma,       Integer
    property :sem_fin_ma,       Integer
    property :ano_fin_ma,       Integer
    property :id_ca,            Integer
    property :id_se,            Integer

    def nombre
        self.nombre.blank? ? nil : self.nombre_ma.unpack("C*").pack("U*")
    end

    belongs_to :carrera, 'ModelosAntiguos::Carrera', parent_key: :id_ca, child_key: :id_ca
    
    def self.buscar_siaa_id_ma plan_estudio
        malla = ModelosAntiguos::Malla.first    :ano_ini_ma.lte => plan_estudio.anio_inicio, :sem_ini_ma.lte => plan_estudio.semestre_inicio,
                                                :ano_fin_ma.gte => plan_estudio.anio_fin,    :sem_fin_ma.gte => plan_estudio.semestre_fin,
                                                :id_ca => plan_estudio.siaa_id_ca_concepcion
        malla.blank? ? nil : malla.id_ma                                                
    end
end

