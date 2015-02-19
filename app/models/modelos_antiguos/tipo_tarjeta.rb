# coding: utf-8
class ModelosAntiguos::TipoTarjeta 
    include DataMapper::Resource

    def self.default_repository_name
        :db_antigua 
    end

    storage_names[:db_antigua] = 'tipos_tarjetas'

    property :id_tt,                Serial
    property :nombre_tt,            String


end

