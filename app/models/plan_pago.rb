# encoding: utf-8
class PlanPago
    include DataMapper::Resource
    include DataMapper::Timestamps
    #include DataMapper::Historylog

    storage_names[:default] = 'planes_pagos'

    URL_DOCUMENTOS = Rails.root.join("public", "documentos", "matriculas")

    VIGENTE         = 1
    FINIQUITADO     = 2
    ANULADO         = 3
    ESTADOS         = [
        :VIGENTE, :FINIQUITADO, :ANULADO
    ]

    property    :id,                                Serial
    property    :estado,                            Integer,    :default => PlanPago::VIGENTE
    property    :url_contrato,                      String,     :length => 255
    property    :fecha_anulacion,                   DateTime

    property    :tipo,                              Integer,    :default => MatriculaPlan::PROFESIONAL_DOS_SEMESTRES #required innecesario por default [AV]
    property    :matricula,                         Integer,    :default => 0,      :min => 0 # min 0 [JM]
    property    :normativa,                         Integer,    :default => 0,      :min => 0 # min 0 [JM]
    property    :arancel,                           Integer,    :default => 0,      :min => 0 # min 0 [JM]
    property    :descuento_aplicado,                Integer,    :default => 0,      :min => 0 # min 0 [JM]
    property    :monto_reconocido,                  Integer,    :default => 0,      :min => 0
    property    :repactacion,                       Integer,    :default => 0,      :min => 0
    property    :descripcion_monto_reconocido,      String,     :length => 100  
    property    :arancel_total,                     Integer,    :default => 0,      :min => 0 # min 0 [JM]
    property    :nivel,                             Integer,    :min => 1
    #property    :postdescuento_id,                  Integer,    :required => false

    property    :asignaturas_propuestas,            Integer
    property    :normativas_propuestas,             Integer
    property    :normativas_propuestas,             Integer

    property    :deleted_at,                        ParanoidDateTime
    timestamps  :at

    property    :siaa_rut_al,                       Integer
    property    :siaa_ano_ma,                       Integer
    property    :siaa_sem_ma,                       Integer
    property    :siaa_updated_at,                   DateTime

    property    :siaa_id_sede_sync,                 Integer

  
    belongs_to  :matricula_plan
    belongs_to  :ejecutivo_matriculas,              :required => false
    belongs_to  :apoderado
    belongs_to  :descuento,                         :required => false
    belongs_to  :postdescuento,   "Descuento",      :required => false, :child_key => "postdescuento_id"
    belongs_to  :periodo

    has n,      :pagos_comprometidos,   "PagoComprometido"
    has n,      :documentos_venta,      "DocumentoVenta"

    has n,      :pagares
    has n,      :situaciones, 'Situacion'

    validates_with_method :es_plan_valido?


    def self.editar_plan_pago cuotas, pagare, documento_venta, matricula, pagare_id
        pp = PlanPago.get pagare[:plan_pago_id]
        mp = pp.matricula_plan
        ape= mp.alumno_plan_estudio
        isp= ape.institucion_sede_plan
        ise= isp.institucion_sede



        PagoComprometido.transaction do
            raise Exception, 'No puede editar ya que tiene más de un pagaré' unless pp.pagares( estado: Pagare::VIGENTE ).length.eql?(1)
            
            # Elimino todo lo asociado al plan pre-edición
            unless pp.pagos_comprometidos.abonos.blank?
                docs = []
                pp.pagos_comprometidos.abonos.each {|x| docs << x.documento_venta}
                pp.pagos_comprometidos.abonos.destroy!
                docs.each {|x| x.destroy! } unless docs.blank?
            end
            
            pp.pagos_comprometidos.destroy!

            total_pagare     = 0
            cuotas_matricula = 0
            total_matricula  = 0
            cuotas_arancel   = 0
            total_arancel    = 0
            cuotas_normativa = 0
            total_normativa  = 0

            fecha_inicio     = nil
            fecha_termino    = nil

            cuotas.each do |cuota|
                tiene_abono = false
                if cuota[:abonar] == "on" # Pago con abono, no va con pagaré
                    tiene_abono = true
                    cuota.delete :abonar
                    cuota.delete :tipo_cuota
                    cuota.delete :fecha_vencimiento
                    cuota.delete :numero_cuota

                    cuota = cuota.merge({   :estado               => PagoComprometido::PAGADO,
                                            :fecha_ultimo_abono   => Date.today,
                                            :fecha_pago_realizado => Date.today,
                                            :saldo                => 0
                            })
                    total_matricula, cuotas_matricula, total_arancel, cuotas_arancel, total_normativa, cuotas_normativa = calcular_totales(cuota, total_matricula, cuotas_matricula, total_arancel, cuotas_arancel, total_normativa, cuotas_normativa)

                else # Son cuotas de pagaré
                    fecha_inicio    = cuota[:fecha_vencimiento] if fecha_inicio.nil? # || fecha_inicio < cuota[:fecha_vencimiento]
                    fecha_termino   = cuota[:fecha_vencimiento] if fecha_termino.nil? || Date.parse(fecha_termino) < Date.parse(cuota[:fecha_vencimiento])

                    total_matricula, cuotas_matricula, total_arancel, cuotas_arancel, total_normativa, cuotas_normativa = calcular_totales(cuota, total_matricula, cuotas_matricula, total_arancel, cuotas_arancel, total_normativa, cuotas_normativa)

                    total_pagare += cuota[:monto].to_i

                    cuota = cuota.merge({
                                saldo:                  cuota[:monto],
                                pagare_id:              pagare_id
                            })

                end

                pc = PagoComprometido.create cuota

                if tiene_abono
                    doc_venta_data = {  numero:                     documento_venta[:numero], 
                                        fecha_emision:              Date.today, 
                                        institucion_sede_id:        ise.id
                                    }

                    doc_venta = DocumentoVenta.first(doc_venta_data)
                    
                    if doc_venta.blank?
                        doc_venta = DocumentoVenta.create doc_venta_data.merge( { estado:                   DocumentoVenta::ENTREGADA, 
                                                                                  monto:                    cuota[:monto].to_i,
                                                                                  plan_pago_id:             pp.id,
                                                                                  ejecutivo_matriculas_id:  pagare[:ejecutivo_matriculas_id],
                                                                                  alumno_plan_estudio_id:   ape.id,
                                                                                  tipo:                     DocumentoVenta::BOLETA})          
                    else
                        doc_venta.update monto: doc_venta.monto+cuota[:monto].to_i
                    end # doc_venta.blank?
                    
                    abono = Abono.create    monto:                  cuota[:monto].to_i,  
                                            interes:                0,                         
                                            saldo:                  0,
                                            fecha:                  Date.today,          
                                            estado:                 PagoComprometido::PAGADO,
                                            medio_pago_id:          documento_venta[:medio_pago_id],
                                            pago_comprometido_id:   pc.id,
                                            documento_venta:        doc_venta,
                                            tipo_abono_id:          cuota[:centro_costo],
                                            alumno_plan_estudio_id: ape.id,
                                            ejecutivo_matriculas_id:pagare[:ejecutivo_matriculas_id]

                    pc.update estado: PagoComprometido::PAGADO

                end # if tiene_abono

                Rails.logger.info "Cuota: #{cuota.inspect}".bold
                Rails.logger.info "=======".red
            end

            pagare = Pagare.get pagare_id

            pagare.update   monto: total_pagare, cuotas_arancel: cuotas_arancel, 
                            cuotas_matricula: cuotas_matricula, cuotas_normativa: cuotas_normativa, 
                            fecha_inicio: fecha_inicio, fecha_termino: fecha_termino

            pp.update   arancel:                matricula[:arancel], 
                        arancel_total:          total_arancel, 
                        descuento_aplicado:     (matricula[:arancel].to_i - total_arancel),
                        matricula:              total_matricula,
                        normativa:              total_normativa

            #raise Exception, 'Caida'

            pp.matricula_plan
        end
    end

    def es_semestral?
        MatriculaPlan::MATRICULAS_SEMESTRALES.include? tipo
    end

    def es_plan_valido?
        if estado == PlanPago::VIGENTE
            plan_vigente = PlanPago.first :periodo_id => periodo_id, :matricula_plan_id => matricula_plan_id, :estado => PlanPago::VIGENTE, :id.not => id
            if plan_vigente.nil?
                true
            else
                return [false, "El alumno ya registra un plan de pago vigente para el periodo en cuestión"]
            end
        else
            return true
        end
    end

    def contrato
        (not url_contrato.nil?) ? url_contrato : "No creado"
    end

    def nombre_descuento
        return nil if descuento_aplicado == 0
        (not descuento_id.nil?) ? descuento.nombre : "Descuento Pago Contado"
    end

    def es_anulable?; estado == PlanPago::VIGENTE end

    def adjuntar_documentos url_contrato_, url_pagares = []
        PlanPago.transaction do
            self.url_contrato = url_contrato_
            save
            url_pagares.each do |url_pagare|
                pagare = Pagare.get url_pagare[:pagare_id]
                pagare.update :url => url_pagare[:url]
            end
        end
    end

    def pueden_generarse_documentos; url_contrato.nil? and estado == PlanPago::VIGENTE end

    def informacion_documentos_plan; Matriculas::PlanPago.informacion_documentos_plan self.id end

    def pendientes
        pc = ((pagos_comprometidos :estado.not => [PagoComprometido::PAGADO, PagoComprometido::ANULADO,PagoComprometido::REPACTADO])+(pagos_comprometidos estado: nil)).all order: [:fecha_vencimiento.asc, :numero_cuota.asc]
        
        pc
    end

    def atrasados
        data = []

        pendientes.each do |p|
            data << p if p.atrasada?
        end

        data
    end

    def deuda
        valor=0

        pendientes.each do |p|
            if p[:centro_costo] != PagoComprometido::MATRICULA
                valor = valor + p.saldo
            end
        end

        valor
    end

    def cuotas_morosas
        # SIN PRORROGA VIGENTE
        
    end

    def cuotas_prorroga
       # CON PRORROGA 
    end

    private
    def self.calcular_totales cuota, total_matricula, cuotas_matricula, total_arancel, cuotas_arancel, total_normativa, cuotas_normativa
        if cuota[:centro_costo].to_i.eql? PagoComprometido::MATRICULA
            total_matricula  += cuota[:monto].to_i
            cuotas_matricula += 1 if cuota[:abono].blank?
        end
        if cuota[:centro_costo].to_i.eql? PagoComprometido::ARANCEL
            total_arancel  += cuota[:monto].to_i
            cuotas_arancel += 1 if cuota[:abono].blank?
        end
        if cuota[:centro_costo].to_i.eql? PagoComprometido::NORMATIVA
            total_normativa  += cuota[:monto].to_i
            cuotas_normativa += 1 if cuota[:abono].blank?
        end
        
        return total_matricula, cuotas_matricula, total_arancel, cuotas_arancel, total_normativa, cuotas_normativa
    end
end
