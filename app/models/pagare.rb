# encoding: utf-8
require "date"

class Pagare
    include DataMapper::Resource
    include DataMapper::Timestamps
    include DataMapper::Historylog
    
    CANCELADO_POR_PAGO        = 1
    CANCELADO_POR_REPACTACION = 2
    VIGENTE                   = 3
    ANULADO                   = 4
    ESTADOS                   = [
        :CANCELADO_POR_PAGO,
        :CANCELADO_POR_REPACTACION,
        :VIGENTE,
        :ANULADO
    ]

    property    :id,                    Serial
    property    :estado,                Integer,        :default => Pagare::VIGENTE
    property    :numero,                Integer,        :required => true, :min => 1
    property    :monto,                 Integer,        default: 0#,    :required => true, :min => 1

    property    :cuotas_arancel,        Integer,        :default => 0
    property    :cuotas_matricula,      Integer,        :default => 0
    property    :cuotas_normativa,      Integer,        :default => 0

    property    :fecha_inicio,          Date,           :required => true
    property    :fecha_termino,         Date,           :required => true
    property    :fecha_termino_real,    Date
    property    :fecha_anulacion,       DateTime

    timestamps  :at
    property    :deleted_at,            ParanoidDateTime
    property    :url,                   String, :length => 256
    property    :es_extension,          Boolean,        default: false

    has n,      :cuotas,                "PagoComprometido"

    belongs_to  :plan_pago
    belongs_to  :ejecutivo_matriculas,  required: false
    belongs_to  :alumno_plan_estudio
    belongs_to  :institucion_sede
    belongs_to  :pagare, required: false

    def self.anular_sustituir pagare_antiguo_id, nuevo_pagare, cuotas, e_matriculas_id
        pagare = Pagare.get! pagare_antiguo_id

        if not pagare.ejecutivo_matriculas_puede_anular? e_matriculas_id
            raise Excepciones::OperacionNoPermitidaError, "No está utorizado para anular el pagaré Nº #{pagare.numero}."
        end
        if pagare.cuotas.abonos.count(:estado => PagoComprometido::PAGADO) > 0
            raise Excepciones::OperacionNoPermitidaError, "No está utorizado para anular el pagaré Nº #{pagare.numero}, ya que presenta cuotas abonadas"
        end

        ahora = DateTime.now
        Pagare.transaction do
            # Los documentos tienen que ser regenerados
            pagare.plan_pago.update :url_contrato => nil

            # Anulacion pagare actual
            pagare.update :fecha_anulacion => ahora, :estado => Pagare::ANULADO
            pagare.cuotas.update :fecha_anulacion => ahora, :estado => PagoComprometido::ANULADO

            # Creacion de nuevo pagare
            _nuevo_pagare = Pagare.new nuevo_pagare
            _cuotas = cuotas
            _nuevo_pagare.cuotas_arancel     = _cuotas.count { |pago| pago[:centro_costo].to_i == PagoComprometido::ARANCEL }
            _nuevo_pagare.cuotas_matricula   = _cuotas.count { |pago| pago[:centro_costo].to_i == PagoComprometido::MATRICULA }
            _nuevo_pagare.cuotas_normativa   = _cuotas.count { |pago| pago[:centro_costo].to_i == PagoComprometido::NORMATIVA }
            _nuevo_pagare.fecha_inicio       = _cuotas.min_by{ |pago| Date.parse pago["fecha_vencimiento"] }["fecha_vencimiento"]
            _nuevo_pagare.fecha_termino      = _cuotas.max_by{ |pago| Date.parse pago["fecha_vencimiento"] }["fecha_vencimiento"]
            _nuevo_pagare.save

            _cuotas.each { |pago| _nuevo_pagare.cuotas.create pago }            
        end
        pagare
    end

    def ejecutivo_matriculas_puede_anular? e_matriculas_id
        estado == Pagare::VIGENTE and created_at.to_date == Date.today and ejecutivo_matriculas_id == e_matriculas_id
    end

    def self.buscar_por_numero q; Matriculas::Pagare.buscar_por_numero q end

    def self.buscar_por_rut q; Matriculas::Pagare.buscar_por_rut q end

    def detalle; Matriculas::Pagare.detalle self.id end

end
