# coding: utf-8
class ModelosAntiguos::Prerequisito 
    include DataMapper::Resource

    def self.default_repository_name
        :db_antigua 
    end
    
    storage_names[:db_antigua] = 'prerrequisitos'

    property :oid,              Serial
    property :id_ma,            Integer
    property :id_ca,            Integer
    property :id_as,            Integer
    property :id_se,            Integer
    property :id_ca_pr,         Integer
    property :id_as_pr,         Integer

    belongs_to :asignatura_requisito, "ModelosAntiguos::Asignatura", parent_key: :id_as, child_key: :id_as_pr

end

