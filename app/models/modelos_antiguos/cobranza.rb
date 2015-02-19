# coding: utf-8
class ModelosAntiguos::Cobranza 
    include DataMapper::Resource

    def self.default_repository_name
        :db_antigua 
    end
    
    storage_names[:db_antigua] = 'cobranzas'

    property :id_cz,            Serial
    property :rut_al,           Integer
    property :letra_pl,         String
    property :id_se,            Integer
    property :fh_cz,            String
    property :observacion_cz,   String
    property :fh_nueva_cz,      String
    property :situacion_adm_cz, String
    property :situacion_aca_cz, String
    property :id_se,            Integer
    property :id_cb,            Integer
    property :id_pz,            Integer
    property :rut_em,           Integer

    belongs_to :tipo_cobranza, 'ModelosAntiguos::TipoCobranza', parent_key: :id_cb, child_key: :id_cb
    belongs_to :empleado, 'ModelosAntiguos::Persona', parent_key: :rut_pe, child_key: :rut_em
    belongs_to :tipo_plaza_letra, 'ModelosAntiguos::TipoPlazaLetra', parent_key: :id_pz, child_key: :id_pz
    
    def fecha_cobranza
        self.fh_cz.blank? ? nil : self.fh_cz.split(".").first.to_datetime
    end
    def fecha_nueva
        self.fh_nueva_cz.blank? ? nil : self.fh_nueva_cz.split(".").first.to_datetime
    end
    def fecha_transaccion_str
        I18n.l(self.fecha_transaccion, format: :mini)
    end
end

