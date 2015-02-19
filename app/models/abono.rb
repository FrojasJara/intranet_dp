# encoding: utf-8
class Abono
    include DataMapper::Resource
    include DataMapper::Timestamps
    #include DataMapper::Historylog

    # Tipos de cheques
    CHEQUE_AL_DIA   = 100
    CHEQUE_A_FECHA  = 101

    # ESTADOS (Basados en estados de Pago Comprometido)
    PAGADO   = 1
    ANULADO  = 8

    ESTADOS = [
        :PAGADO,
        :ANULADO
    ]

    property    :id,                        Serial
    property    :monto,                     Integer,                        :required => true, :min => 0
    property    :interes,                   Integer,                        :default => 0, :min => 0
    property    :saldo,                     Integer,                        :default => 0, :min => 0
    property    :saldo_interes,             Integer,                        :default => 0, :min => 0
    property    :fecha,                     DateTime
    property    :estado,                    Integer 

    # [JM] Quite el tipo de documento, ya que esta implicito en el medio de pago
    property    :numero_documento,          String,                         :length => 32
    property    :fecha_documento,           Date
    timestamps  :at
    property    :deleted_at,                ParanoidDateTime


    property    :siaa_id,                   Integer
    property    :siaa_id_sede_sync,         Integer

    belongs_to  :medio_pago,                :required => false
    belongs_to  :banco,                     :required => false
    belongs_to  :tarjetas_credito,          :required => false
    belongs_to  :pago_comprometido,         :required => false
    belongs_to  :documento_venta
    belongs_to  :tipo_abono,                :required => false

    # Importacion
    belongs_to  :alumno_plan_estudio,       :required => false
    belongs_to  :ejecutivo_matriculas,      :required => false
    has 1,      :certificado

    def total
        monto + interes
    end

    def tipo_cheque fecha_consulta
        raise Exception if not medio_pago_id == 2

        # ATENTO A ESTE CAMBIO EN PRODUCCION
        if fecha_documento > (Date.strptime fecha_consulta, "%d/%m/%Y")
             "Cheque a Fecha"
        else
             "Cheque al día"
        end
    end

    def nombre_banco
        banco.nombre
        rescue
            nil
    end

    def nombre_medio_pago
        medio_pago.nombre
        rescue
            nil
    end

    def fecha_pago
        fecha_documento unless fecha_documento.blank?
        
        created_at
    end

end