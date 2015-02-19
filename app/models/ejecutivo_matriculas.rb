# encoding: utf-8

class EjecutivoMatriculas
    include DataMapper::Resource
    include DataMapper::Timestamps
    include DataMapper::Historylog

    property    :id,                        Serial
    timestamps  :at                         
    property    :deleted_at,                ParanoidDateTime
    property    :estado,           Boolean,        default: true

    belongs_to  :datos_personales,          "Usuario", :child_key => "usuario_id"

    has n,      :documentos_venta,          "DocumentoVenta"
    has n,      :rangos_documentos,         "RangoDocumento"
    # DEPLOY
    has n,      :matriculas,              "MatriculaPlan"
    has n,      :planes_pago,             "PlanPago"
    has n,      :pago_comprometidos
    has n,      :pagares
    has n,      :abonos
    has n,      :cotizaciones,              "Cotizacion"
    has n,      :certificados
    has n,      :cobranzas
    has n,      :prorrogas

    #ESTADOS EJECUTIVO SE ENCUENTRAN EN RANGO DOCUMENTOS
    
    # HABILITADO    = 1
    # DESHABILITADO = 2

    # ESTADOS   = [
    #     :HABILITADO,
    #     :DESHABILITADO
    # ]

    def tiene_documento tipo_documento, numero
      rangos_documentos.all( fields: [:id], tipo: tipo_documento, :inicio.lte => numero, :fin.gte => numero ).length > 0
    end

    def nombre
        'Sin definir' if datos_personales.blank?
        datos_personales.nombre_corto
    end
    # def self.documento_disponible tipo_documento

    # end
end