# coding: utf-8
class ModelosAntiguos::InscripcionAsignatura 
    include DataMapper::Resource

    def self.default_repository_name
        :db_antigua 
    end
    
    storage_names[:db_antigua] = 'inscripciones'

    property :oid,              Serial
    property :rut_al,           Integer
    property :id_ca,            Integer
    property :sem_in,           Integer
    property :ano_in,           Integer
    property :id_se,            Integer
    property :id_as,            Integer
    property :seccion_in,       Integer
    property :abandonada_in,    Boolean
    property :fh_in,            Date
    property :user_in,          String
    property :ip_in,            String
    property :fh_trans_in,      String
    property :rut_em,           Integer

    def fecha_transaccion
        self.fh_trans_in.blank? ? DateTime.now : self.fh_trans_in.split(".").first.to_datetime
    end
    
    def fecha_transaccion_str
        I18n.l(self.fecha_transaccion, format: :mini)
    end

end

