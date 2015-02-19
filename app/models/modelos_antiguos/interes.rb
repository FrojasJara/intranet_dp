# coding: utf-8
class ModelosAntiguos::Interes 
    include DataMapper::Resource

    def self.default_repository_name
        :db_antigua 
    end

    storage_names[:db_antigua] = 'intereses'

    property :oid, 					Serial
    property :fh_in, 				String
    property :rut_al, 				Integer
    property :letra_pl,				Integer
    property :valor_acumulado_in, 	Integer
    property :ano_in,				Integer
    property :id_se,				Integer

    def fecha
    	fh_in.nil? ? DateTime.now : fh_in.split(".").first.to_datetime
    end
end