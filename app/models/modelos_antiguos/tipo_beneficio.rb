# coding: utf-8
class ModelosAntiguos::TipoBeneficio
    include DataMapper::Resource

    def self.default_repository_name
        :db_antigua 
    end

    storage_names[:db_antigua] = 'tipos_beneficios'

    property :id_tb,                Serial
    property :nombre_tb,            String
    property :descuento,			Boolean
    property :beneficio,			Boolean
    property :beca,					Boolean


    def tipo
    	return Descuento::DESCUENTO if descuento
    	return Descuento::BENEFICIO if beneficio
    	return Descuento::BECA if beca

	   0
    end


end

