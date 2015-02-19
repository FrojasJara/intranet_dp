# coding: utf-8
class ModelosAntiguos::TipoPlazaLetra 
    include DataMapper::Resource

    def self.default_repository_name
        :db_antigua 
    end

    storage_names[:db_antigua] = 'tipos_plazas_letras'

    property :id_pz,                Serial
    property :nombre_pz,            String


end

