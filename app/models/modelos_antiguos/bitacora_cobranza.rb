# coding: utf-8
class ModelosAntiguos::BitacoraCobranza 
    include DataMapper::Resource

    def self.default_repository_name
        :db_antigua 
    end
    
    storage_names[:db_antigua] = 'bitacora_cobranza'

    property :id_bc,            Serial
    property :rut_al,           Integer
    property :id_ca,            Integer
    property :sem_bc,           Integer
    property :ano_bc,           Integer
    property :fh_bc,            Date
    property :detalle_bc,       String
    property :rut_em,           Integer
    property :fh_trans_bc,      String
    
    def fecha
        self.fh_trans_bc.blank? ? nil : self.fh_trans_bc.split(".").first.to_datetime
    end

    def detalle
        self.detalle_bc.unpack("C*").pack("U*") 
        rescue 
            ''
    end

end

