# coding: utf-8
class ModelosAntiguos::Beneficio 

    include DataMapper::Resource

    def self.default_repository_name
        :db_antigua 
    end

    storage_names[:db_antigua] = 'beneficios'

    property :oid,  			Serial
    property :rut_al, 			Integer, :key => true
    property :id_tb, 			Integer
    property :fh_be, 			String
    property :sem_be,			Integer
    property :ano_be,			Integer
    property :porcentaje_be, 	Float
    property :monto_be,			Integer


    def self.buscar_descuento busqueda_query
    	bus = ModelosAntiguos::Beneficio.first busqueda_query
        Descuento.first(siaa_id: bus.id_tb).id
        rescue
            nil
    end
end