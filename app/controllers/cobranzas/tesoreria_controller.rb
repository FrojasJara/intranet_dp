#encoding: utf-8

 class Cobranzas::TesoreriaController < ApplicationController
	before_filter :iniciar

	def informe
        @sedes = Sede.all id: Sede::SEDES_VIGENTES, fields: [:id, :nombre]
        @instituciones = Institucion.all fields: [:id, :nombre]

		@instituciones_sedes = InstitucionSede.instituciones_en_sede @usuario.sede_id
        @instituciones_sedes_distancia = InstitucionSede.all(:institucion_id => Institucion::IP)
        @instituciones_sedes_distancia_usuario = @instituciones_sedes_distancia.instituciones_en_sede @usuario.sede_id

        @años = Periodo.all fields: [:anio],
                            unique: true,
                            order: :anio.desc
	end

    def tesorero_diario
        if params[:filtro][:fecha_inicio].blank?
            flash[:error] = "Debe seleccionar una fecha de inicio"
            redirect_to cobranzas_tesoreria_informe_path
        else
            @f_i = params[:filtro][:fecha_inicio]
            @f_t = params[:filtro][:fecha_termino]

            if @f_t.blank? #solo el mismo día
                f_i     = Time.parse(@f_i)
                f_t     = Time.parse(@f_i+' 23:59:59')
            else #es un rango de fechas
                f_i     = Time.parse(@f_i)
                f_t     = Time.parse(@f_t+' 23:59:59')
            end

            @i_s = params[:institucion_sede_id]
            i_s = InstitucionSede.get params[:institucion_sede_id]
            @institucion_sede = i_s

            talonarios = RangoDocumento.all(:centro_costos.not => RangoDocumento::TALONARIOS_DISTANCIA, institucion_sede: i_s)

            documentos = []
            documentos_datos = []

            talonarios.each do |t|
                docs = DocumentoVenta.all(fields: [:id, :numero], 
                                          :fecha_emision => f_i..f_t, 
                                          :institucion_sede => i_s, 
                                          :numero => t.inicio..t.fin,
                                          :estado => DocumentoVenta::ENTREGADA)
                    
                if documentos.select{|d| docs.map(&:id).include? d}.blank?
                    documentos += docs.map(&:id)
                    documentos_datos += docs.map{|x| [x.id, x.numero, x]}
                end
            end

            @tipos_abonos = TipoAbono.all(fields: [:id, :nombre])

            @items = Abono.all( :documento_venta_id => documentos )

            @abonos = []

            @items.each do |x|
                @abonos << {     
                                :abono           => x, 
                                :numero          => (documentos_datos.select{|v| v[0] == x.documento_venta_id}).first.second,
                                :tipo_abono      => (ta = @tipos_abonos.select{|v| v.id == x.tipo_abono_id}).blank? ? nil : ta.first.nombre,
                                :documento_venta => (documentos_datos.select{|v| v[0] == x.documento_venta_id}).first.last
                            } 
                puts (documentos_datos.select{|v| v[0] == x.documento_venta_id}).first.last.inspect.blue
            end
            puts @abonos.inspect.red
            datos_informe
        end
    end

    def cajas_distancia
        if params[:distancia][:fecha_inicio].blank?
            flash[:error] = "Debe seleccionar una fecha de inicio"
            redirect_to cobranzas_tesoreria_informe_path
        else
            @f_i = params[:distancia][:fecha_inicio]
            @f_t = params[:distancia][:fecha_termino]

            if @f_t.blank? #solo el mismo día
                f_i     = Time.parse(@f_i)
                f_t     = Time.parse(@f_i+' 23:59:59')
            else #es un rango de fechas
                f_i     = Time.parse(@f_i)
                f_t     = Time.parse(@f_t+' 23:59:59')
            end

            @i_s = params[:institucion_sede_id]
            i_s = InstitucionSede.get params[:institucion_sede_id]
            @institucion_sede = i_s

            talonarios = RangoDocumento.all(centro_costos: eval(params[:tipo]), institucion_sede: i_s)
            
            logger.info talonarios.inspect
            documentos = []
            documentos_datos = []

            talonarios.each do |t|
                docs = DocumentoVenta.all(fields: [:id, :numero], 
                                          :fecha_emision => f_i..f_t, 
                                          :institucion_sede => i_s, 
                                          :numero => t.inicio..t.fin,
                                          :estado => DocumentoVenta::ENTREGADA)

                if documentos.select{|d| docs.map(&:id).include? d}.blank?
                    documentos += docs.map(&:id)
                    documentos_datos += docs.map{|x| [x.id, x.numero,x]}
                end
            end

            @tipos_abonos = TipoAbono.all(fields: [:id, :nombre])

            @items = Abono.all( :documento_venta_id => documentos )

            @abonos = []

            @items.each do |x|
                @abonos << {     
                                :abono => x, 
                                :numero => (documentos_datos.select{|v| v[0] == x.documento_venta_id}).first.second,
                                :tipo_abono => (ta = @tipos_abonos.select{|v| v.id == x.tipo_abono_id}).blank? ? nil : ta.first.nombre,
                                :documento_venta => (documentos_datos.select{|v| v[0] == x.documento_venta_id}).first.last
                            } 
            end
            

            datos_informe
        end
    end

    def resumen_clasificado
        if params[:resumen][:fecha_inicio].blank?
            flash[:error] = "Debe seleccionar una fecha de inicio"
            redirect_to cobranzas_tesoreria_informe_path
        else
            @f_i = params[:resumen][:fecha_inicio]
            @f_t = params[:resumen][:fecha_termino]

            if @f_t.blank? #solo el mismo día
                f_i     = Time.parse(@f_i)
                f_t     = Time.parse(@f_i+' 23:59:59')
            else #es un rango de fechas
                f_i     = Time.parse(@f_i)
                f_t     = Time.parse(@f_t+' 23:59:59')
            end

            @institucion = Institucion.first id: params[:institucion_id].to_i, fields: [:id,:nombre]
            @sede = Sede.first id: params[:sede_id].to_i, fields: [:id,:nombre]
            @modalidad = params[:modalidad]

            i_s = InstitucionSede.first institucion_id: @institucion.id,
                                        sede_id: @sede.id

            if @modalidad.to_i == InstitucionSedePlan::PRESENCIAL
                talonarios = RangoDocumento.all(:centro_costos.not => RangoDocumento::TALONARIOS_DISTANCIA, institucion_sede: i_s)
            else
                talonarios = RangoDocumento.all(centro_costos: RangoDocumento::TALONARIOS_DISTANCIA, institucion_sede: i_s)
            end

            logger.info talonarios.inspect
            documentos = []
            documentos_datos = []

            talonarios.each do |t|
                docs = DocumentoVenta.all(fields: [:id, :numero], 
                                          :fecha_emision => f_i..f_t, 
                                          :institucion_sede => i_s, 
                                          :numero => t.inicio..t.fin,
                                          :estado => DocumentoVenta::ENTREGADA)
                    
                if documentos.select{|d| docs.map(&:id).include? d}.blank?
                    documentos += docs.map(&:id)
                    documentos_datos += docs.map{|x| [x.id, x.numero,x]}
                end
            end

            @tipos_abonos = TipoAbono.all(fields: [:id, :nombre])

            @items = Abono.all( :documento_venta_id => documentos )

            @abonos = []

            @items.each do |x|
                @abonos << {     
                                :abono => x, 
                                :numero => (documentos_datos.select{|v| v[0] == x.documento_venta_id}).first.second,
                                :tipo_abono => (ta = @tipos_abonos.select{|v| v.id == x.tipo_abono_id}).blank? ? nil : ta.first.nombre,
                                :documento_venta => (documentos_datos.select{|v| v[0] == x.documento_venta_id}).first.last
                            } 
            end
            
            datos_informe2
        end
    end

    def ingresos
        
        if params[:ingresos][:fecha_inicio].blank?
            logger.info "Pasa al redirect"
            flash[:error] = "Debe seleccionar una fecha de inicio"
            redirect_to cobranzas_tesoreria_informe_path
        else
            @f_i = params[:ingresos][:fecha_inicio]
            @f_t = params[:ingresos][:fecha_termino]

            if @f_t.blank? #solo el mismo día
                f_i     = Time.parse(@f_i)
                f_t     = Time.parse(@f_i+' 23:59:59')
            else #es un rango de fechas
                f_i     = Time.parse(@f_i)
                f_t     = Time.parse(@f_t+' 23:59:59')
            end

            @institucion_sede = InstitucionSede.get params[:institucion_sede_id]

            documentos_venta = DocumentoVenta.all( :estado              => DocumentoVenta::ENTREGADA,
                                                   :fecha_emision.gte   => f_i, 
                                                   :fecha_emision.lte   => f_t, 
                                                   :institucion_sede_id => params[:institucion_sede_id],
                                                   :alumno_plan_estudio => nil,
                                                   :order               => [:fecha_emision.asc])+DocumentoVenta.all(:estado              => DocumentoVenta::ENTREGADA,
                                                   :fecha_emision.gte   => f_i, 
                                                   :fecha_emision.lte   => f_t, 
                                                   :institucion_sede_id => params[:institucion_sede_id],
                                                   :alumno_plan_estudio => {:institucion_sede_plan => { :modalidad.not => InstitucionSedePlan::DISTANCIA}},
                                                   :order               => [:fecha_emision.asc])


            @data = {}
            @monto_total = 0
            @documentos_total = 0
            unless documentos_venta.blank?

                ultima_fecha = documentos_venta.first.fecha_emision.strftime("%d/%m/%Y")

                @data[ultima_fecha] = {total: 0, documentos: [], fecha: ultima_fecha}

                documentos_venta.each do |dv|
                    if ultima_fecha != dv.fecha_emision.strftime("%d/%m/%Y")
                        ultima_fecha = dv.fecha_emision.strftime("%d/%m/%Y")
                        @data[ultima_fecha] = {total: 0, documentos: [], fecha: ultima_fecha}

                    end
                    #binding.pry
                    @data[ultima_fecha][:total]         += dv.monto
                    @data[ultima_fecha][:documentos]    << dv
                    @monto_total += dv.monto
                    @documentos_total += 1
                end
            end
        end
    end

    def comprometido_anual
        prms = params[:todos]

        @institucion = Institucion.get prms[:institucion]
        @sede        = Sede.get prms[:sede]
        @modalidad   = prms[:modalidad]
        @año         = prms[:anio]
        @tipo        = prms[:tipo]
        
        if @tipo.to_i == 1
            filtro_pagos_comprometidos = PagoComprometido.all({
                fields: [:id, :plan_pago_id, :monto, :saldo],
                :estado.not => PagoComprometido::ANULADO,
                :fecha_vencimiento.gte => Date.civil(@año.to_i, 1, 1),
                :fecha_vencimiento.lte => Date.civil(@año.to_i, 12, -1)
            })
        elsif @tipo.to_i == 2
            filtro_pagos_comprometidos = 
                PagoComprometido.all({
                    fields: [:id, :plan_pago_id, :monto, :saldo],
                    :cobranza => nil,
                    :estado.not => PagoComprometido::ANULADO,
                    :fecha_vencimiento.gte => Date.civil(@año.to_i, 1, 1),
                    :fecha_vencimiento.lte => Date.civil(@año.to_i, 12, -1),
                    :saldo.gt => 0
                }) + 
                PagoComprometido.all({
                    fields: [:id, :plan_pago_id, :monto, :saldo],
                    :cobranza => {
                        :tipo.not => Cobranza::INCOBRABLE
                    },
                    :estado.not => PagoComprometido::ANULADO,
                    :fecha_vencimiento.gte => Date.civil(@año.to_i, 1, 1),
                    :fecha_vencimiento.lte => Date.civil(@año.to_i, 12, -1),
                    :saldo.gt => 0
                })
        elsif @tipo.to_i == 3
            filtro_pagos_comprometidos = PagoComprometido.all({
                fields: [:id, :plan_pago_id, :monto, :saldo],
                :estado.not => PagoComprometido::ANULADO,
                :fecha_vencimiento.gte => Date.civil(@año.to_i, 1, 1),
                :fecha_vencimiento.lte => Date.civil(@año.to_i, 12, -1),
                :cobranza => {
                    tipo: Cobranza::INCOBRABLE
                }
            })
        end
        
        alumnos_plan_estudios = AlumnoPlanEstudio.all({
            institucion_sede_plan: {
                modalidad: prms[:modalidad],
                institucion_sede: {
                    institucion_id: prms[:institucion].to_i,
                    sede_id: prms[:sede].to_i,
                }
            },
            matricula_plan: {
                planes_pago: {
                    pagos_comprometidos: {
                        id: filtro_pagos_comprometidos.map(&:id).uniq,
                    }
                }
            }
        })

        institucion_sede_planes = alumnos_plan_estudios.institucion_sede_plan
        planes_estudios         = institucion_sede_planes.plan_estudio
        matricula_planes        = alumnos_plan_estudios.matricula_plan
        planes_pago             = matricula_planes.planes_pago
        #pagos_comprometidos     = planes_pago.pagos_comprometidos( {fields: [:id, :plan_pago_id, :monto, :saldo]}.merge filtro_pagos_comprometidos )
        pagos_comprometidos     = filtro_pagos_comprometidos
        
        @resumen = {}

        alumnos_plan_estudios.each do |ape|
            ins_se_pl = institucion_sede_planes.select{|i| i.id == ape.institucion_sede_plan_id}.first
            plan_est  = planes_estudios.select{|p| p.id == ins_se_pl.plan_estudio_id}.first
            mat_plan  = matricula_planes.select{|m| m.alumno_plan_estudio_id == ape.id}

            pl_pgs = []

            mat_plan.each do |mp|
                planes_pago.select{|pp| pp.matricula_plan_id == mp.id}.each do |pp|
                    pl_pgs << pp
                end
            end
            total_comprometido = []

            total_comprometido << 0 << 0 << 0 << 0 << 0 << 0 << 0 << 0 << 0 << 0 << 0 << 0
            
            pl_pgs.each do |pp|
                pagos_comprometidos.select{|pc| pc.plan_pago_id == pp.id}.each do |pc|
                    12.times do |x|
                        if pc.fecha_vencimiento >= Date.civil(@año.to_i, x+1, 1) and pc.fecha_vencimiento <= Date.civil(@año.to_i, x+1, -1)
                            if @tipo.to_i == 2
                                total_comprometido[x] += pc.saldo
                            else
                                total_comprometido[x] += pc.monto
                            end

                            break
                        end
                    end
                end
            end
           
            plan_est = PlanEstudio.new(id: 0, nombre: 'Sin definir') if plan_est.blank?

            if @resumen[plan_est.nombre].blank?
                @resumen[plan_est.nombre] = {
                    carrera:    "#{plan_est.nombre}",
                    alumnos:    0,
                    enero:      0,
                    febrero:    0,
                    marzo:      0,
                    abril:      0,
                    mayo:       0,
                    junio:      0,
                    julio:      0,
                    agosto:     0,
                    septiembre: 0,
                    octubre:    0,
                    noviembre:  0,
                    diciembre:  0,
                }
            end

            @resumen[plan_est.nombre][:alumnos]    += 1
            @resumen[plan_est.nombre][:enero]      += total_comprometido[0]
            @resumen[plan_est.nombre][:febrero]    += total_comprometido[1]
            @resumen[plan_est.nombre][:marzo]      += total_comprometido[2]
            @resumen[plan_est.nombre][:abril]      += total_comprometido[3]
            @resumen[plan_est.nombre][:mayo]       += total_comprometido[4]
            @resumen[plan_est.nombre][:junio]      += total_comprometido[5]
            @resumen[plan_est.nombre][:julio]      += total_comprometido[6]
            @resumen[plan_est.nombre][:agosto]     += total_comprometido[7]
            @resumen[plan_est.nombre][:septiembre] += total_comprometido[8]
            @resumen[plan_est.nombre][:octubre]    += total_comprometido[9]
            @resumen[plan_est.nombre][:noviembre]  += total_comprometido[10]
            @resumen[plan_est.nombre][:diciembre]  += total_comprometido[11] 
        end
    end

	private
	def iniciar
        @usuario              = current_user_object
        @ejecutivo_matriculas = @usuario.ejecutivo_matriculas

        unless params[:rut].blank?
            @us_alumno = Usuario.first rut: params[:rut]
            @alumno    = @us_alumno.alumno if @us_alumno
       end
	end

    def datos_informe
        @ejecutivos = @items.uniq{|x| x.ejecutivo_matriculas_id}.map{|x| x.ejecutivo_matriculas_id}
        @usuarios_ejecutivos = EjecutivoMatriculas.all(id: @ejecutivos)
        @usuarios = Usuario.all id: @usuarios_ejecutivos.map{|x| x.usuario_id}

        #debugger

        # Medios de pago
        @medios_pago        = MedioPago.validos
        @medios_pagos_array = @medios_pago.to_a.map{|m| m.attributes}
        efectivo_id         = @medios_pago.select{|m| m.slug == 'efectivo'}.first.id
        cheque_paga_id      = @medios_pago.select{|m| m.slug == 'pagare-slash-cheque'}.first.id
        documento_id        = @medios_pago.select{|m| m.slug == 'documento'}.first.id
        tar_debito_id       = @medios_pago.select{|m| m.slug == 'tarjeta-debito'}.first.id
        tar_credito_id      = @medios_pago.select{|m| m.slug == 'tarjeta-credito'}.first.id
        deposito_id         = @medios_pago.select{|m| m.slug == 'depositos'}.first.id
        transferencia_id    = @medios_pago.select{|m| m.slug == 'transferencia'}.first.id

        @datos = []

        @usuarios_ejecutivos.each do |i|
            item = {
                ejecutivo:    @usuarios.select{|x| x.id == i.usuario_id}.first.nombre_corto,
                efectivo:     @items.select{|x| x.ejecutivo_matriculas_id == i.id and x.medio_pago_id == efectivo_id}.map{|x| x.monto+x.interes}.inject(:+),
                cheque_dia:   @items.select{|x| x.ejecutivo_matriculas_id == i.id and (x.medio_pago_id == cheque_paga_id or x.medio_pago_id == documento_id) and !x.fecha_documento.blank? and x.fecha_documento <= x.created_at.to_date}.map{|x| x.monto+x.interes}.inject(:+),
                cheque_fecha: @items.select{|x| x.ejecutivo_matriculas_id == i.id and (x.medio_pago_id == cheque_paga_id or x.medio_pago_id == documento_id) and !x.fecha_documento.blank? and x.fecha_documento > x.created_at.to_date}.map{|x| x.monto+x.interes}.inject(:+),
                tarjetas:     @items.select{|x| x.ejecutivo_matriculas_id == i.id and (x.medio_pago_id == tar_debito_id or x.medio_pago_id == tar_credito_id)}.map{|x| x.monto+x.interes}.inject(:+),
                depositos:    ( (dv = @items.select{|x| x.ejecutivo_matriculas_id == i.id and x.medio_pago_id == deposito_id}.map{|x| x.monto+x.interes}).blank? ? 0 : dv.inject(:+) ) + 
                              ( (dt = @items.select{|x| x.ejecutivo_matriculas_id == i.id and x.medio_pago_id == transferencia_id}.map{|x| x.monto+x.interes}).blank? ? 0 : dt.inject(:+) )
            }

            item[:total] = item[:efectivo].to_i + item[:cheque_dia].to_i + item[:cheque_fecha].to_i + item[:tarjetas].to_i + item[:depositos].to_i

            @datos << item
        end
    end

    def datos_informe2
        items_con_plan = []
        items_sin_plan = []
        @carreras = []
        index = 0
        flag = 0

        @items.each do |item|  
            flag = 0
            unless item.alumno_plan_estudio.blank? 
                if index == 0
                    carrera = PlanEstudio.first id: item.alumno_plan_estudio.institucion_sede_plan.plan_estudio_id
                    @carreras << carrera 
                    index = 1
                else
                    @carreras.each do |c| 
                        if item.alumno_plan_estudio.institucion_sede_plan.plan_estudio_id == c.id
                            flag = 1
                        end
                    end
                    if flag == 0
                        carrera = PlanEstudio.first id: item.alumno_plan_estudio.institucion_sede_plan.plan_estudio_id
                        @carreras << carrera 
                    end
                end
                items_con_plan << item
            else
                items_sin_plan << item
            end
        end

        #debugger

        # Medios de pago
        @medios_pago        = MedioPago.validos
        @medios_pagos_array = @medios_pago.to_a.map{|m| m.attributes}
        efectivo_id         = @medios_pago.select{|m| m.slug == 'efectivo'}.first.id
        cheque_paga_id      = @medios_pago.select{|m| m.slug == 'pagare-slash-cheque'}.first.id
        documento_id        = @medios_pago.select{|m| m.slug == 'documento'}.first.id
        tar_debito_id       = @medios_pago.select{|m| m.slug == 'tarjeta-debito'}.first.id
        tar_credito_id      = @medios_pago.select{|m| m.slug == 'tarjeta-credito'}.first.id
        deposito_id         = @medios_pago.select{|m| m.slug == 'depositos'}.first.id
        transferencia_id    = @medios_pago.select{|m| m.slug == 'transferencia'}.first.id

        @datos = []

        @carreras.each do |carrera|
            item = {
                carrera:      carrera.nombre_completo,
                efectivo:     items_con_plan.select{|x| x.alumno_plan_estudio.institucion_sede_plan.plan_estudio_id == carrera.id and (x.medio_pago_id == efectivo_id)}.map{|x| x.monto+x.interes}.inject(:+),
                cheque_dia:   items_con_plan.select{|x| x.alumno_plan_estudio.institucion_sede_plan.plan_estudio_id == carrera.id and (x.medio_pago_id == cheque_paga_id or x.medio_pago_id == documento_id) and !x.fecha_documento.blank? and x.fecha_documento <= x.created_at.to_date}.map{|x| x.monto+x.interes}.inject(:+),
                cheque_fecha: items_con_plan.select{|x| x.alumno_plan_estudio.institucion_sede_plan.plan_estudio_id == carrera.id and (x.medio_pago_id == cheque_paga_id or x.medio_pago_id == documento_id) and !x.fecha_documento.blank? and x.fecha_documento > x.created_at.to_date}.map{|x| x.monto+x.interes}.inject(:+),
                tarjetas:     items_con_plan.select{|x| x.alumno_plan_estudio.institucion_sede_plan.plan_estudio_id == carrera.id and (x.medio_pago_id == tar_debito_id or x.medio_pago_id == tar_credito_id)}.map{|x| x.monto+x.interes}.inject(:+),
                depositos:    ( (dv = items_con_plan.select{|x| x.alumno_plan_estudio.institucion_sede_plan.plan_estudio_id == carrera.id and x.medio_pago_id == deposito_id}.map{|x| x.monto+x.interes}).blank? ? 0 : dv.inject(:+) ) + 
                              ( (dt = items_con_plan.select{|x| x.alumno_plan_estudio.institucion_sede_plan.plan_estudio_id == carrera.id and x.medio_pago_id == transferencia_id}.map{|x| x.monto+x.interes}).blank? ? 0 : dt.inject(:+) ),

                cuotas:       items_con_plan.select{|x| x.alumno_plan_estudio.institucion_sede_plan.plan_estudio_id == carrera.id and x.tipo_abono.especificacion == TipoAbono::CUOTA}.map{|x| x.monto}.inject(:+),
                matriculas:   items_con_plan.select{|x| x.alumno_plan_estudio.institucion_sede_plan.plan_estudio_id == carrera.id and x.tipo_abono.especificacion == TipoAbono::MATRICULA}.map{|x| x.monto}.inject(:+),
                certificados: items_con_plan.select{|x| x.alumno_plan_estudio.institucion_sede_plan.plan_estudio_id == carrera.id and x.tipo_abono.especificacion == TipoAbono::CERTIFICADO}.map{|x| x.monto}.inject(:+),
                titulos:      items_con_plan.select{|x| x.alumno_plan_estudio.institucion_sede_plan.plan_estudio_id == carrera.id and x.tipo_abono.especificacion == TipoAbono::TITULO}.map{|x| x.monto}.inject(:+),
                intereses:    items_con_plan.select{|x| x.alumno_plan_estudio.institucion_sede_plan.plan_estudio_id == carrera.id}.map{|x| x.interes}.inject(:+) 
            }

            item[:total]  = item[:efectivo].to_i + item[:cheque_dia].to_i + item[:cheque_fecha].to_i + item[:tarjetas].to_i + item[:depositos].to_i
            item[:total2] = item[:cuotas].to_i + item[:matriculas].to_i + item[:certificados].to_i + item[:titulos].to_i + item[:intereses].to_i         

            @datos << item
        end

        item = {
            carrera:      "Plan Sin Definir",
            efectivo:     items_sin_plan.select{|x| x.medio_pago_id == efectivo_id}.map{|x| x.monto+x.interes}.inject(:+),
            cheque_dia:   items_sin_plan.select{|x| (x.medio_pago_id == cheque_paga_id or x.medio_pago_id == documento_id) and x.fecha_documento <= x.created_at.to_date}.map{|x| x.monto+x.interes}.inject(:+),
            cheque_fecha: items_sin_plan.select{|x| (x.medio_pago_id == cheque_paga_id or x.medio_pago_id == documento_id) and !x.fecha_documento.blank? and x.fecha_documento > x.created_at.to_date}.map{|x| x.monto+x.interes}.inject(:+),
            tarjetas:     items_sin_plan.select{|x| (x.medio_pago_id == tar_debito_id or x.medio_pago_id == tar_credito_id)}.map{|x| x.monto+x.interes}.inject(:+),
            depositos:    ( (dv = items_sin_plan.select{|x| x.medio_pago_id == deposito_id}.map{|x| x.monto+x.interes}).blank? ? 0 : dv.inject(:+) ) + 
                          ( (dt = items_sin_plan.select{|x| x.medio_pago_id == transferencia_id}.map{|x| x.monto+x.interes}).blank? ? 0 : dt.inject(:+) ),

            cuotas:       items_sin_plan.select{|x| x.tipo_abono.especificacion == TipoAbono::CUOTA}.map{|x| x.monto}.inject(:+),
            matriculas:   items_sin_plan.select{|x| x.tipo_abono.especificacion == TipoAbono::MATRICULA}.map{|x| x.monto}.inject(:+),
            certificados: items_sin_plan.select{|x| x.tipo_abono.especificacion == TipoAbono::CERTIFICADO}.map{|x| x.monto}.inject(:+),
            titulos:      items_sin_plan.select{|x| x.tipo_abono.especificacion == TipoAbono::TITULO}.map{|x| x.monto}.inject(:+),
            intereses:    items_sin_plan.select.map{|x| x.interes}.inject(:+)  
        }

        item[:total]  = item[:efectivo].to_i + item[:cheque_dia].to_i + item[:cheque_fecha].to_i + item[:tarjetas].to_i + item[:depositos].to_i
        item[:total2] = item[:cuotas].to_i + item[:matriculas].to_i + item[:certificados].to_i + item[:titulos].to_i + item[:intereses].to_i         

        @datos << item
    end
end