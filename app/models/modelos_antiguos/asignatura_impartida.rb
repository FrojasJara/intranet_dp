# coding: utf-8
class ModelosAntiguos::AsignaturaImpartida 
    include DataMapper::Resource

    def self.default_repository_name
        :db_antigua 
    end
    
    storage_names[:db_antigua] = 'asignaturas_impartidas'

    property :oid,              Serial
    property :id_ca,            Integer
    property :id_as,            Integer
    property :seccion_ai,       Integer
    property :id_se,            Integer
    property :sem_ai,           Integer
    property :ano_ai,           Integer
    property :cupos_ai,         Integer
    property :user_ai,          String
    property :ip_ai,            String
    property :fh_trans_ai,      String
    property :rut_em,           Integer
    
    def fecha_transaccion
        self.fh_trans_ai.blank? ? DateTime.now : self.fh_trans_ai.split(".").first.to_datetime
    end
    def fecha_transaccion_str
        I18n.l(self.fecha_transaccion, format: :mini)
    end

    belongs_to :asignaturas, "ModelosAntiguos::Asignatura", parent_key: :id_as, child_key: :id_as
end

