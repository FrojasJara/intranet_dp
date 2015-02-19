class ModelosAntiguos::TipoPago
    include DataMapper::Resource

    def self.default_repository_name
        :db_antigua 
    end

    storage_names[:db_antigua] = 'tipos_pagos'

    property    :id_tp,            Serial
    property    :nombre_tp,        String
    property    :alias_tp,         String

end