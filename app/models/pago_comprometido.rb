# encoding: utf-8
require "date"

class PagoComprometido
    include DataMapper::Resource
    include DataMapper::Timestamps
    #include DataMapper::Historylog

    storage_names[:default] = 'pagos_comprometidos'

    # CENTROS DE COSTO
    MATRICULA       = 1
    ARANCEL         = 2
    NORMATIVA       = 3
    CENTROS_COSTOS = [:MATRICULA, :ARANCEL, :NORMATIVA]

    # TIPO_CUOTAS
    PAGARE = 1
    CHEQUE = 2
    TIPOS_CUOTAS = [
            :PAGARE,
            :CHEQUE
    ]

    #ESTADOS
    PAGADO                  = 1
    ATRASADO                = 2
    COMPROMETIDO            = 3 
    CHEQUE_PROTESTADO       = 4
    CHEQUE_PERDIDO          = 5
    REPACTADO               = 6
    COMPROMETIDO_CON_ABONOS = 7
    ANULADO                 = 8

    ESTADOS = [
        :PAGADO,
        :ATRASADO,
        :COMPROMETIDO,
        :CHEQUE_PROTESTADO,
        :CHEQUE_PERDIDO,
        :REPACTADO,
        :COMPROMETIDO_CON_ABONOS,
        :ANULADO
    ]

    property        :id,                            Serial
    property        :numero_cuota,                  Integer,        :min => 1
    property        :tipo_cuota,                    Integer
    property        :estado,                        Integer
    property        :fecha_vencimiento,             Date
    property        :fecha_ultimo_abono,            Date
    property        :fecha_pago_realizado,          Date
    property        :fecha_anulacion,               DateTime

    property        :siaa_id,                       Integer
    property        :siaa_id_plan,                  Integer
    property        :siaa_id_pago,                  Integer
    property        :siaa_id_interes,               Integer
    property        :siaa_id_sede_sync,             Integer


    property        :monto,                         Integer#,       :required => true, :min => 1
    property        :saldo,                         Integer,        :default => 0, :min => 0
    property        :centro_costo,                  Integer,        :required => true

    timestamps      :at
    property        :deleted_at,                    ParanoidDateTime

    # => Relacion con las instituciones del instituto
    belongs_to      :institucion_sede
    belongs_to      :plan_pago
    belongs_to      :pagare,                        :required => false # [JM] DEbe ser true

    belongs_to      :ejecutivo_matriculas,          required: false

    has n,          :abonos
    has n,          :cobranzas
    has n,          :prorrogas
    has 1,          :cobranza

    def diferencia_dias date = nil
        _prorroga = prorrogas(:order => [:fecha.desc], :limit => 1)

        if date.nil?
            date = fecha_vencimiento     
        end

        date = date.to_s[0..15]
        dd = (Date.today - date.to_date).to_i
        return dd

        rescue DataMapper::SaveFailureError => e
    end

    def diferencia_dias_prorroga date = nil
        _prorroga = prorrogas(:order => [:fecha.desc], :limit => 1)

        if date.nil?
            date = fecha_vencimiento     
        end

        date = _prorroga.first.fecha if _prorroga.first.fecha > date

        dd = (Date.today - date).to_i

        return dd

        rescue DataMapper::SaveFailureError => e
    end

    def tiene_prorroga? pc_id
        pro = Prorroga.last :pago_comprometido_id => pc_id

        unless pro.blank?
            return true
        else 
            return false
        end
    end

    def fecha_vencimiento_con_prorroga
        date = fecha_vencimiento 
        
        _prorroga = prorrogas(:order => [:fecha.desc], :limit => 1)

        unless _prorroga.blank?
            date = _prorroga.last.fecha if _prorroga.last.fecha > date
        end

        date
    end

    def porcentaje_prorroga
        date = fecha_vencimiento 
        
        _prorroga = prorrogas(:order => [:fecha.desc], :limit => 1)

        unless _prorroga.blank?
            porcentaje = _prorroga.last.porcentaje if _prorroga.last.fecha > date
        end

        return !porcentaje.blank? ? porcentaje : 0
    end

    def interes(tope = 10000)
        ultimo = abonos.first(:estado.not => ANULADO, :order => [:saldo.asc], :limit => 1)

        _prorroga = prorrogas(:order => [:fecha.desc], :limit => 1)


        if _prorroga.blank?
            unless ultimo.blank?
                unless fecha_vencimiento.blank?
                    if(ultimo.fecha >= fecha_vencimiento)
                        diferencia = diferencia_dias(ultimo.fecha)
                    else
                        diferencia = diferencia_dias(fecha_vencimiento)
                    end
                else
                    diferencia = diferencia_dias(ultimo.fecha)
                end
            else
                diferencia = diferencia_dias(nil)
            end

            if diferencia <= 3
                diferencia = 0
            end

            _interes = diferencia *  (ultimo.blank? ? monto : ultimo.saldo) * 0.001
        else
            unless ultimo.blank?
                unless fecha_vencimiento.blank?
                    if ultimo.fecha >= fecha_vencimiento
                        diferencia = diferencia_dias(ultimo.fecha)
                        diferencia2 = diferencia_dias_prorroga(ultimo.fecha)
                    else
                        diferencia = diferencia_dias(fecha_vencimiento)
                        diferencia2 = diferencia_dias_prorroga(fecha_vencimiento)
                    end
                else
                    diferencia = diferencia_dias(ultimo.fecha)
                    diferencia2 = diferencia_dias(ultimo.fecha)
                end
            else
                diferencia = diferencia_dias(nil)
                diferencia2 = diferencia_dias_prorroga(nil)
            end

            if diferencia <= 3 
                diferencia = 0 
            end
            if diferencia2 <= 0 
                diferencia2 = 0 
            end

            if diferencia2 == 0
                pp = porcentaje_prorroga

                _interes = diferencia * (ultimo.blank? ? monto : ultimo.saldo) * 0.001 
                _interes = _interes - (diferencia * (ultimo.blank? ? monto : ultimo.saldo) * 0.001 * pp/100)
            else
                _interes = diferencia * (ultimo.blank? ? monto : ultimo.saldo) * 0.001
            end   
            
        end
        

        if !ultimo.blank? && !ultimo.monto.eql?(0)
            _interes += ultimo.saldo_interes
        end

        #interes = interes - abonos.sum(:interes) unless abonos.blank?
        _interes > tope ? tope : _interes
    end

    def acumulado(_interes = nil)
        _interes = interes if _interes.nil?
        _saldo = saldo
        
        ( _interes.round + _saldo ).to_i
    end

    def estado_cobranza

        _prorroga = prorrogas(:order => [:fecha.desc], :limit => 1)

        if _prorroga.blank?
            dd = diferencia_dias                
        else
            if diferencia_dias_prorroga > 0
                dd = diferencia_dias  
            else 
                dd = 0
            end
        end

        if dd > 0
            return "Atrasado por #{dd} días" if estado.eql?(ATRASADO)
        end
        #return "Faltan #{diferencia_dias} días" if estado.eql?(COMPROMETIDO)||estado.eql?(COMPROMETIDO_CON_ABONOS)

        return ""
    end

    def total_abonos
        suma = abonos.blank? ? 0 : abonos(:estado.not => ANULADO).sum(:monto)

        suma.blank? ? 0 : suma
    end

    def pagado?
        estado.eql? PAGADO
    end

    def atrasada?
        return false if tipo_cuota.nil?
        hoy = Date.today
        tipo_cuota == PagoComprometido::PAGARE and ![PagoComprometido::PAGADO, PagoComprometido::ANULADO].include?(estado) and hoy > fecha_vencimiento
    end

    def tiene_cobranza? pc_id
        cob = Cobranza.last :pago_comprometido_id => pc_id

        unless cob.blank?
            return true
        else 
            return false
        end
    end
end