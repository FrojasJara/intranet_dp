# coding: utf-8
class ModelosAntiguos::TipoCobranza 
    include DataMapper::Resource

    def self.default_repository_name
        :db_antigua 
    end

    storage_names[:db_antigua] = 'tipos_cobranzas'

    property :id_cb,                Serial
    property :nombre_cb,            String


end

