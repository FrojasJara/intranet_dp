# coding: utf-8
class ModelosAntiguos::Plan 
    include DataMapper::Resource

    def self.default_repository_name
        :db_antigua 
    end

    storage_names[:db_antigua] = 'planes'

    property :letra_pl,             Serial
    #property :oid,                  Serial
    property :rut_al,               Integer
    property :plaza_pl,             Integer

    property :valor_pl,             Integer
    property :fh_venc_pl,           Date
    property :protestada_pl,        Boolean
    property :id_tp,                Integer
    property :secuencia_letra_pl,   Integer
    property :id_se,                Integer
    property :sem_pl,               Integer
    property :ano_pl,               Integer
    property :nula_letra_pl,        Boolean
    property :fh_trans_pl,          String
    property :nro_cuota_cp,         Integer
    property :pagare_ag,            Integer
    property :repactada_pl,         Boolean
    property :id_ca,                Integer
    property :user_pl,              String

    def fecha
        self.fh_trans_pl.nil? ? DateTime.now : self.fh_trans_pl.split(".").first.to_datetime
    end


    def nombre
        self.nombre_dn.unpack("C*").pack("U*")
    end

    def centro_costos
        tipo_pago = ModelosAntiguos::TipoPago.first id_tp: id_tp

        nil if tipo_pago.nil?
        return PagoComprometido::MATRICULA if tipo_pago.alias_tp.include? "MATRICULA"
        return PagoComprometido::NORMATIVA if tipo_pago.alias_tp.include? "NORMATIVA"
        return PagoComprometido::ARANCEL# if tipo_pago.alias_tp.include? "ARANCEL"

        #nil
    end

    def tipo_cuota
        pago = ModelosAntiguos::Pago.first letra_pl: letra_pl, rut_al: rut_al

        return nil if pago.nil?
        return PagoComprometido::CHEQUE unless pago.serie_ch.blank?
        return PagoComprometido::PAGARE unless pago.pagare_ag.blank?
        return nil
    end

end

