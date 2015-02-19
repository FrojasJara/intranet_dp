# coding: utf-8
class ModelosAntiguos::Pago 
    include DataMapper::Resource

    def self.default_repository_name
        :db_antigua 
    end

    storage_names[:db_antigua] = 'pagos'

    property :id_pg,                Serial
    property :rut_al,               Integer
    property :letra_pl,             Integer
    property :valor_pg,             Integer
    property :saldo_pg,             Integer
    property :fh_pg,                String
    property :boleta_pg,            String
    property :nula_boleta_pg,       Boolean
    property :id_se,                Integer
    property :id_tp,                Integer
    property :rut_em,               Integer
    property :fh_entrega_compra_pg, String
    property :compra_fabricada_pg,  Boolean
    property :compra_entregada_pg,  Boolean
    property :fh_trans_pg,          String
    property :serie_ch,             String
    property :ano_pg,               Integer
    property :nulo_pago_pg,         Boolean
    property :pagare_ag,            String
    property :id_fp,                Integer
    property :id_ba,                Integer
    property :user_pg,              String
    #property :nro_cuota_cp,         


    belongs_to :tipo_pago, "ModelosAntiguos::TipoPago", :parent_key => "id_tp", :child_key => "id_tp"
    belongs_to :tipo_tarjeta, "ModelosAntiguos::TipoTarjeta", parent_key: "id_tt", child_key: "id_tt"

    def fecha
        self.fh_pg.nil? ? DateTime.now : self.fh_pg.split(".").first.to_datetime
    end

    def fecha_emision
       self.fh_entrega_compra_pg.nil? ? nil : self.fh_entrega_compra_pg.split(".").first.to_datetime 
    end

    def nombre
        self.nombre_dn.unpack("C*").pack("U*")
    end

    def estado
        return DocumentoVenta::ANULADA if nulo_pago_pg
        return DocumentoVenta::ENTREGADA if compra_entregada_pg
        return DocumentoVenta::RETENIDA if compra_fabricada_pg
        DocumentoVenta::SIN_FABRICAR
    end

    def medio_pago
        MedioPago.first(siaa_id: id_fp).id unless id_fp.blank?
        rescue
            nil
    end

    def banco
        Banco.first(siaa_id: id_ba).id unless id_ba.blank?
        rescue
            nil
    end

    def tarjeta_credito
        TarjetasCredito.first(siaa_id: id_tt) unless id_tt.blank?
        rescue
            nil
    end

    def numero_documento
        serie_ch unless serie_ch.blank?
    end

end

