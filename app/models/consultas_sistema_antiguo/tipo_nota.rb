# coding: utf-8
class ConsultasSistemaAntiguo::TipoNota 
    include DataMapper::Resource

    def self.default_repository_name
        :db_antigua 
    end

    PRUEBA_PARCIAL 		= 1
    PRUEBA_GLOBAL 		= 2
    EXAMEN_FINAL 		= 3
    EXAMEN_REPETICION 	= 4

    NOTA_PRESENTACION 	= 98
    NOTA_FINAL 			= 99
    NOTA_TRABAJO_TITULO	= 100
    NOTA_EXAMEN_TITULO 	= 101
    
    storage_names[:db_antigua] = 'tipos_notas'

    property :oid,             Serial
    property :id_tn,           Integer
    property :nombre_tn,       String
    
end

