# coding: utf-8
class ModelosAntiguos::Horario 
    include DataMapper::Resource

    def self.default_repository_name
        :db_antigua 
    end
    
    storage_names[:db_antigua] = 'horarios'

    property :id_ho,            	Serial
    property :rut_pe,           	Integer
    property :id_se, 				Integer
    property :id_ca,				Integer
    property :id_as,				Integer
    property :seccion_ho,			Integer
    property :fh_ho,				String
    property :id_bl,				Integer
    property :id_sl,				Integer
    property :id_tc,				Integer
    property :sem_ho,				Integer
    property :ano_ho,				Integer
    property :activo_ho,			Integer
    property :user_ho,				String
    property :ip_ho,				String
    property :fh_trans_ho,			String
    property :rut_em,				Integer
    property :realizada_ho,			Boolean
    property :controlada_hoja_ho, 	Boolean
    property :controlada_carpeta_ho,Boolean

    belongs_to :profesor, 'ModelosAntiguos::Persona', parent_key: 'rut_pe', child_key: 'rut_pe', required: false

end

