# coding: utf-8
class ModelosAntiguos::Nota 
    include DataMapper::Resource

    def self.default_repository_name
        :db_antigua 
    end
    
    storage_names[:db_antigua] = 'notas'

    property :oid,              Serial
    property :rut_al,           Integer
    property :id_ca,            Integer
    property :id_as,            Integer
    property :seccion_no,       Integer
    property :nro_ce,           Integer
    property :id_se,            Integer
    property :sem_no,           Integer
    property :ano_no,           Integer
    property :id_te,            Integer
    property :id_tn,            Integer
    property :id_or,            Integer
    property :fh_no,            Date
    property :nota_no,          Float
    
end

