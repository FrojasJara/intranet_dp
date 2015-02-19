# coding: utf-8
class ModelosAntiguos::Prorroga 
    include DataMapper::Resource

    def self.default_repository_name
        :db_antigua 
    end
    
    storage_names[:db_antigua] = 'prorrogas'

    property :id_pr,            Serial
    property :rut_al,           Integer
    property :letra_pl,         Integer
    property :id_se,            Integer
    property :fh_prorroga_pr,   Date

    property :fh_trans_pr,      String
    property :user_pr,          String
    property :rut_em,           Integer

    def fecha_emision
       self.fh_trans_pr.nil? ? nil : self.fh_trans_pr.split(".").first.to_datetime 
    end
end

