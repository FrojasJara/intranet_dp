# encoding: utf-8
require "date"

class Matriculas::PagosController < ApplicationController

    helper_method :current_url

    before_filter :store_location, only: [:certificados]
    before_filter :iniciar, only: [:detalle_cajas_diarias, :ver, :abonar, :generar_certificado, :guardar_certificado, :ver_certificado, :certificados, :editar_certificado, :prorroga_guardar, :prorroga_eliminar, :editar_pago_comprometido, :ingresar, :listado_por_alumno]
    before_filter :datos_certificados, only: [:editar_certificado, :generar_certificado]
    before_filter :get_plan_pago, only: [:ver, :abonar, :ingresar]

    def detalle_cajas_diarias
        @hoy = DateTime.now.strftime "%d/%m/%Y"
        @instituciones_sedes = InstitucionSede.instituciones_en_sede @usuario.sede_id
        @modalidades = InstitucionSedePlan::MODALIDADES
        @ejecutivos = EjecutivoMatriculas.all estado: RangoDocumento::HABILITADO,
                                              datos_personales: {
                                                sede_id: @ejecutivo_matriculas.datos_personales.sede_id
                                              }
        
        alias current_url pagos_detalle_cajas_diarias_path
        @fecha = params[:fecha]
        @institucion_sede_id = params[:institucion_sede_id]
        @modalidad = params[:modalidad]
        @ejecutivo_elegido = params[:ejecutivo_id]

        if @fecha and @institucion_sede_id and @modalidad and @ejecutivo_elegido
            Date.strptime @fecha, "%d/%m/%Y" # Fecha válida ?
            @ejecutivo, @cajas, @formas_pago, @centros_costos, @documentos_venta = MatriculaPlan.detalle_cajas_diarias(
                @ejecutivo_elegido, 
                @fecha,
                @institucion_sede_id,
                @modalidad
            )

            @institucion_sede = InstitucionSede.get @institucion_sede_id
            raise Excepciones::DatosNoExistentesError if @cajas.empty?
        end

    rescue Excepciones::DatosNoExistentesError
        flash.now[:error] = "No existen documentos de venta emitidos en la fecha consultada."
        @sin_datos = true

    rescue ArgumentError => e
        flash.now[:error] = "Por favor, ingrese una fecha válida de consulta."
        @fecha_invalida = true

    ensure
        @mostrar_datos = (@fecha and @institucion_sede_id and @modalidad and not @fecha_invalida and not @sin_datos)
    end

############################### ABONOS ###################################
    def index
        unless (b = params[:busqueda]).blank?
            item = Usuario.first(rut: b)
            item = item.alumno unless item.nil?
            
            redirect_to matriculas_pagos_ver_alumno_path(b) unless item.nil?

            flash.now[:error] = "El rut ingresado no es un alumno válido."
        end
    end

    def ver

        unless @plan_pago.blank?
            @alumno_plan_estudio =@plan_pago.matricula_plan.alumno_plan_estudio
        end

        pagos_pendientes    = @plan_pago.nil? ? [] : @plan_pago.pendientes
        pagos_comprometidos = @plan_pago.nil? ? [] : @plan_pago.pagos_comprometidos(:estado.not => [PagoComprometido::ANULADO,PagoComprometido::REPACTADO], order: [:fecha_vencimiento.asc, :numero_cuota.asc])

        @lista_abonos_vigentes = pagos_comprometidos.blank? ? [] : pagos_comprometidos.abonos(:estado.not => Abono::ANULADO, order: [:created_at.asc, :saldo.desc]).to_a
        @lista_abonos = pagos_comprometidos.blank? ? [] : pagos_comprometidos.abonos(order: [:created_at.asc, :saldo.desc]).to_a

        @pagos_comprometidos = []
        @pagos_pendientes = []
        
        pagos_comprometidos.each do |pc|
            bloque_pagos_comprometidos.call(pc, @pagos_comprometidos)
        end

        pagos_pendientes.each do |pp|
            bloque_pagos_comprometidos_vigentes.call(pp, @pagos_pendientes)
        end

    end

    def bloque_pagos_comprometidos
        lambda do |pc, contenedor|

            abonos = @lista_abonos.select{|x| x.pago_comprometido_id == pc.id}

            if !pc[:estado].eql?(PagoComprometido::PAGADO) && pc.saldo == 0
                pc.update :estado => PagoComprometido::PAGADO
            end

            if pc[:estado].eql?(PagoComprometido::PAGADO) && pc[:saldo] > 0
                pc.update :estado => PagoComprometido::COMPROMETIDO
            end

            if ![PagoComprometido::ANULADO, PagoComprometido::PAGADO, PagoComprometido::REPACTADO].include?( pc.estado ) && (pc.fecha_ultimo_abono.blank? ? pc.fecha_vencimiento : pc.fecha_ultimo_abono) < Date.today
                pc.update :estado => PagoComprometido::ATRASADO
            end

            item = {
                :pago_comprometido  => pc,
                :abonos             => abonos,
                :monto_comprometido => pc.monto,
                :interes            => pc.interes(@es_distancia ? 0 : (@es_cft ? 5000 : 10000))
            }
            
            contenedor << item
        end
    end

    def bloque_pagos_comprometidos_vigentes
        lambda do |pc, contenedor|

            abonos = @lista_abonos_vigentes.select{|x| x.pago_comprometido_id == pc.id}

            item = {
                :pago_comprometido  => pc,
                :abonos             => abonos,
                :monto_comprometido => pc.monto,
                :interes            => pc.interes(@es_distancia ? 0 : (@es_cft ? 5000 : 10000))
            }
            
            contenedor << item
        end
    end

    def abonar
        @pagos_comprometidos_id = params[:abono][:pago_comprometido_id].keys
        pagos_pendientes    = @plan_pago.nil? ? [] : PagoComprometido.all( id: @pagos_comprometidos_id )

        unless @plan_pago.blank?
            @alumno_plan_estudio = @plan_pago.matricula_plan.alumno_plan_estudio
        end

        begin
            @institucion_sede_plan = @plan_pago.matricula_plan.alumno_plan_estudio.institucion_sede_plan
        rescue
            @institucion_sede_plan = nil
        end

        @lista_abonos = pagos_pendientes.blank? ? [] : pagos_pendientes.abonos(order: [:created_at.asc, :saldo.desc]).to_a



        @pagos_pendientes = []

        pagos_pendientes.each do |pp|
            bloque_pagos_comprometidos.call(pp, @pagos_pendientes)
        end
    end

    def guardar_abono
        abonos               = params[:abonos][:lista_abonos]
        usuario              = current_user_object
        ejecutivo_matriculas = usuario.ejecutivo_matriculas

        DocumentoVenta.transaction do
            ape = PlanPago.get(params[:plan_pago]).matricula_plan.alumno_plan_estudio
            
            ins = ape.institucion_sede_plan.institucion_sede.institucion_id
            sed = ejecutivo_matriculas.datos_personales.sede_id

            ins_sed = InstitucionSede.first fields: [:id],
                                            institucion_id: ins.to_i,
                                            sede_id: sed.to_i

            documento_venta = DocumentoVenta.create     estado:                 DocumentoVenta::ENTREGADA, 
                                                        tipo:                   params[:abonos][:documento_venta], 
                                                        numero:                 params[:abonos][:numero_documento],
                                                        monto:                  params[:abonos][:total_documentado],
                                                        plan_pago_id:           params[:plan_pago],
                                                        ejecutivo_matriculas:   ejecutivo_matriculas,
                                                        alumno_plan_estudio_id: ape.id,
                                                        institucion_sede_id:    ins_sed[:id]

            documento_venta.update :fecha_emision => documento_venta.created_at


            abonos.each_value do |pabonos|
                pabonos.each do |pabono|
                    pago_comprometido = PagoComprometido.get pabono[:id]
                    medio_pago = MedioPago.get pabono[:medio_pago]


                    abono = Abono.new medio_pago: medio_pago

                    if pago_comprometido.plan_pago.matricula_plan.alumno_plan_estudio.institucion_sede_plan.modalidad == InstitucionSedePlan::DISTANCIA
                        interes_pc = 0
                    elsif pago_comprometido.interes > 5000 && pago_comprometido.plan_pago.matricula_plan.alumno_plan_estudio.institucion_sede_plan.institucion_sede.institucion_id == Institucion::CFT
                        interes_pc = 5000 
                    else
                        interes_pc = pago_comprometido.interes
                    end

                    # reviso el interes pendiente para descontar del abono
                    dif = (interes_pc.round - pabono[:monto].to_f).round

                    if dif < 0 #cuando abonan más que el interés
                        abono.monto = (-dif).round #el resto queda en monto
                        abono.interes = (interes_pc).round
                    else
                        abono.monto = 0
                        abono.interes = (pabono[:monto].to_f).round #hago un abono solo al interés
                        abono.saldo_interes = (interes_pc - abono.interes).round
                    end

                    abono.saldo = (pago_comprometido.monto - pago_comprometido.total_abonos - abono.monto).round #(pago_comprometido.total_abonos + pabono[:monto].to_i)
                    pago_comprometido.saldo = (abono.saldo).round #actualizo el saldo del pago comprometido
                    pago_comprometido.saldo = 0 if pago_comprometido.saldo < 0
                    abono.saldo = 0 if abono.saldo < 0
                    
                    # cambio estado del pago, según la cantidad abonada
                    if pago_comprometido.saldo.eql?(0)
                        pago_comprometido.estado =  PagoComprometido::PAGADO
                        pago_comprometido.fecha_pago_realizado = Date.today
                    else
                        pago_comprometido.estado = PagoComprometido::COMPROMETIDO_CON_ABONOS
                    end

                    pago_comprometido.fecha_ultimo_abono = Date.today

                    abono.fecha = pago_comprometido.fecha_ultimo_abono
                    abono.pago_comprometido = pago_comprometido

                    abono.estado = medio_pago.slug.eql?("documento") ? PagoComprometido::COMPROMETIDO : PagoComprometido::PAGADO

                    abono.numero_documento = pabono[:numero_documento]# if %w(deposito documento transferencia).include? medio_pago.slug
                    abono.banco_id = pabono[:banco]# if %w(documento tarjeta-credito tarjeta-debito).include? medio_pago.slug
                    abono.fecha_documento = pabono[:fecha_documento]

                    abono.tarjetas_credito_id = pabono[:tarjetas_credito]
                    abono.tipo_abono_id = pago_comprometido.centro_costo
                    
                    
                    abono.alumno_plan_estudio_id = ape.id if ape

                    abono.ejecutivo_matriculas = ejecutivo_matriculas if ejecutivo_matriculas

                    abono.documento_venta = documento_venta
                    
                    
                    pago_comprometido.save
                    abono.save            
                end
                
            end
        end
        
        redirect_to matriculas_pagos_ver_alumno_path params[:rut], params[:plan_pago]

        rescue DataMapper::SaveFailureError => e
            log_error e
        
    end

    def editar_pago_comprometido
        @pago_comprometido = PagoComprometido.get params[:pago_comprometido_id]
    end
    def actualizar_pago_comprometido
        PagoComprometido.transaction do
            begin
                pc = params[:item][:pago_comprometido]
                pc_id = params[:pago_comprometido_id]
                @pago_comprometido = PagoComprometido.get pc_id
                @pago_comprometido.update pc

                abonos = params[:item][:abono]
                abonos.keys.each do |key|
                    puts "KEY: #{key}"
                    abono = Abono.get key
                    abono.update abonos[key]
                end

                flash[:notice] = "Se ha actualizado la información de los pagos comprometidos"
                rescue DataMapper::SaveFailureError => e
                    flash[:error] = "No se pudo actualizar la información de los pagos comprometidos"
                    log_error e
            end
        end
        redirect_to matriculas_pagos_ver_alumno_path params[:rut], @pago_comprometido.plan_pago.id

    end

    def ingresar
        
    end

    def ingresar_guardar
        abonos               = params[:abonos]
        usuario              = current_user_object
        ejecutivo_matriculas = usuario.ejecutivo_matriculas

        datos = params[:abono]
        
        institucion_sede     = InstitucionSede.first institucion_id: datos[:institucion_id],
                                                     sede_id:        current_user_object.sede_id.to_i

        DocumentoVenta.transaction do
            
            documento_venta = DocumentoVenta.create     estado:                 DocumentoVenta::ENTREGADA, 
                                                        tipo:                   datos[:documento_venta], 
                                                        numero:                 datos[:numero_documento],
                                                        fecha_emision:          Time.now,
                                                        monto:                  datos[:total_documentado],
                                                        ejecutivo_matriculas:   ejecutivo_matriculas,
                                                        institucion_sede_id:    institucion_sede.id,
                                                        rut:                    datos[:rut],
                                                        nombre_completo:        datos[:nombre_completo],
                                                        carrera:                datos[:carrera],
                                                        direccion:              datos[:direccion],
                                                        giro:                   datos[:giro],
                                                        modalidad:              datos[:modalidad]
                
            #documento_venta.update :fecha_emision => documento_venta.created_at

            abonos.each do |pabono|
            
                medio_pago = MedioPago.get pabono[:medio_pago]


                abono = Abono.new medio_pago: medio_pago, monto: pabono[:monto]
                
                abono.estado = medio_pago.slug.eql?("documento") ? PagoComprometido::COMPROMETIDO : PagoComprometido::PAGADO

                abono.numero_documento = pabono[:numero_documento]# if %w(deposito documento transferencia).include? medio_pago.slug
                abono.banco_id = pabono[:banco]# if %w(documento tarjeta-credito tarjeta-debito).include? medio_pago.slug
                abono.fecha_documento = pabono[:fecha_documento]

                abono.tarjetas_credito_id = pabono[:tarjetas_credito]
                abono.tipo_abono_id = datos[:tipo_abono]
                abono.fecha = Time.now
                
                abono.ejecutivo_matriculas = ejecutivo_matriculas if ejecutivo_matriculas

                abono.documento_venta = documento_venta
            
                abono.save            
            
                
            end
            flash[:notice] = "Pago ingresado correctamente visualizar"
        end
        
        redirect_to matriculas_pagos_ingresar_path

        rescue DataMapper::SaveFailureError => e
            log_error e
            flash[:error] = "Ocurrió un error al intentar guardar el pago"
            redirect_to matriculas_pagos_ingresar_path
        
    end

    def listado_por_alumno
        @abonos =   Abono.all(alumno_plan_estudio: {alumno: {datos_personales: {rut: params[:rut]}}}) +
                    Abono.all(documento_venta: {rut: params[:rut]})

    end
########################### END ABONOS ###################################

############################# CERTIFICADOS ###############################
    def certificados
        unless params[:rut].blank?
            if @alumno.blank?
                flash.now[:info] = "El alumno no existe"
            else
                redirect_to matriculas_certificados_generar_path(@us_alumno.rut)
                
            end
        end
    end

    def editar_certificado
        
        @item = Certificado.get params[:id]
    end

    def generar_certificado
        @certificados = Certificado.all :alumno_plan_estudio => @alumno_plan_estudios
                                        
        @item = Certificado.new

        @alumno_plan_estudio = @alumno_plan_estudios.last
    end
    
    def actualizar_certificado
        c = Certificado.get params[:id]
        cert = params[:certificado]

        datos = {
            :lugar                => cert[:presentado_en], 
            :cursa                => cert[:cursa_el], 
            :observacion          => cert[:para_tramite], 
            :observacion2         => cert[:observacion],
            :linea1               => cert[:linea_1],
            :linea2               => cert[:linea_2]
        }

        c.update datos

        redirect_to matriculas_certificados_generar_path(params[:rut])
        rescue DataMapper::SaveFailureError => e
            puts e.message
            puts e.resource.errors.inspect
            flash[:error] = "Por favor, verifique los campos ingresados."
            redirect_to matriculas_certificados_generar_path(params[:rut])
    end

    def guardar_certificado # vista donde muestra el detalle del usuario y el formulario para guardar
        cert = params[:certificado]
        abonos = params[:abonos]

        ape = AlumnoPlanEstudio.get cert[:plan_estudio]
        Certificado.transaction do
            begin
                c = Certificado.new :numero               => "#{ape.periodo.anio}#{ape.periodo.semestre}#{Certificado.count + 1}",
                                    :impreso              => false, 
                                    :entregado            => false,
                                    :lugar                => cert[:presentado_en], 
                                    :cursa                => cert[:cursa_el], 
                                    :observacion          => cert[:para_tramite], 
                                    :observacion2         => cert[:observacion],
                                    :linea1               => cert[:linea_1],
                                    :linea2               => cert[:linea_2],
                                    :ejecutivo_matriculas => @ejecutivo_matriculas,
                                    :alumno_plan_estudio  => ape,
                                    :tipo_abono_id        => cert[:certificado]

                monto = 0

                unless abonos.blank?
                    abonos.each{|x| monto += x[:monto].to_i }
                end

                if monto > 0

                    d = DocumentoVenta.create   :estado               => DocumentoVenta::ENTREGADA,
                                                :tipo                 => cert[:tipo_documento],
                                                :fecha_emision        => Time.now,
                                                :numero               => cert[:numero_documento],
                                                :monto                => monto,
                                                :ejecutivo_matriculas => @ejecutivo_matriculas,
                                                :alumno_plan_estudio  => ape,
                                                :institucion_sede_id  => ape.institucion_sede_plan.institucion_sede_id

                    abonos.each do |abono|
                        a = Abono.create    :monto                => d.monto,
                                            :interes              => 0,
                                            :saldo                => 0,
                                            :fecha                => Time.now,
                                            :estado               => PagoComprometido::PAGADO,
                                            :numero_documento     => abono[:numero_documento],
                                            :fecha_documento      => abono[:fecha_documento],
                                            :medio_pago_id        => abono[:medio_pago],
                                            :banco_id             => abono[:banco],
                                            :tarjetas_credito_id  => abono[:tarjetas_credito],
                                            :documento_venta      => d,
                                            :tipo_abono_id        => cert[:certificado],
                                            :alumno_plan_estudio  => ape,
                                            :ejecutivo_matriculas => @ejecutivo_matriculas,
                                            :saldo_interes        => 0

                        c.abono = a
                    end
                end

                if c.save
                    flash[:notice] = "Certificado generado satisfactoriamente."
                end
            rescue DataObjects::Error
                flash[:error] = "Ocurrió un problema al generar el certificado."
            rescue Exception => e
                flash[:error] = "No se ha podido ingresar el certificado."
                log_error e
            end
        end
        redirect_to matriculas_certificados_generar_path(params[:rut])
    end
    
    def ver_certificado
        @certificado = Certificado.get params[:id]
        tipo_certificado = @certificado.tipo_abono.slug

        @institucion_sede_plan = @certificado.alumno_plan_estudio.institucion_sede_plan
        @institucion_sede = @institucion_sede_plan.institucion_sede
        @institucion = @institucion_sede.institucion
        @plan_estudio = @institucion_sede_plan.plan_estudio
        @vicerrector = Usuario.first sede: @institucion_sede.sede, rol_id: 10
        @periodo = Periodo::en_curso[:anio]
        @periodo_semestre  = Periodo::en_curso[:semestre]



        carpeta = "#{Certificado::URL_DOCUMENTOS}/#{@institucion_sede.id}/#{periodo_matriculable[:anio]}/#{periodo_matriculable[:semestre]}"
        fcertificado = "#{carpeta}/#{@us_alumno.rut}_#{tipo_certificado}.pdf".delete(" ")

        FileUtils.mkdir_p carpeta

        str = render_to_string("matriculas/pagos/certificados/#{tipo_certificado}", :layout => "pdf_sin_logo")

        pdf = WickedPdf.new.pdf_from_string(str, :disposition => 'inline')

        certificado = File.open(fcertificado, 'wb') do |file|
            file << pdf
        end
        
        redirect_to certificado.path.partition("public")[2]
        #render :text => str
    end

    def eliminar_certificado
        Certificado.transaction do
            begin
                c = Certificado.get params[:id]

                unless c.abono.blank?
                    abono = Abono.get c.abono_id
                    dv = DocumentoVenta.get abono.documento_venta_id
                    abono.estado = PagoComprometido::ANULADO
                    abono.save
                    dv.estado = DocumentoVenta::ANULADA
                    dv.save
                end

                if c.destroy
                    flash[:notice] = "Se ha eliminado el certificado" 
                end

            rescue DataObjects::Error
                flash[:error] = "No se pudo eliminar el certificado"
            end
        end
        
        redirect_to matriculas_certificados_generar_path(params[:rut])
    end
    def datos_certificados
        @matriculas_planes    = @alumno.alumno_plan_estudio.matricula_plan
        periodos              = @matriculas_planes.periodos
        @alumno_plan_estudios = @matriculas_planes.alumno_plan_estudio
        institucion_sede_plan = @matriculas_planes.alumno_plan_estudios.institucion_sede_plan
        plan_estudio          = @matriculas_planes.alumno_plan_estudios.institucion_sede_plan.plan_estudio
        descuentos            = @matriculas_planes.planes_pagos.descuentos
        planes_pagos          = @matriculas_planes.planes_pagos
        
        @matriculas  = []
        @matriculas_planes.each do |i|
            planes_pagos.select{|x| x.matricula_plan_id == i.id}.each do |p|

                data = {    
                    :matricula           => i,
                    :periodo             => periodos.select{|x| x.id == i.periodo_id}.first,
                    :descuento           => (d = descuentos.select{|x| x.id = p.descuento_id}).blank? ? nil : d.first,
                    :alumno_plan_estudio => @alumno_plan_estudios.select{|x| x.id == i.alumno_plan_estudio_id}.first,
                    :plan_pago           => p
                }
                data[:institucion_sede_plan] = institucion_sede_plan.select{|x| x.id == data[:alumno_plan_estudio].institucion_sede_plan_id}.first
                data[:plan_estudio]          = plan_estudio.select{|x| x.id == data[:institucion_sede_plan].plan_estudio_id}.first

                @matriculas << data

            end
            
        end
    end
########################## END CERTIFICADOS #############################
############################ PRORROGAS ##################################
    def prorroga
        @pago_comprometido = PagoComprometido.get params[:pago_comprometido_id]
    end

    def prorroga_guardar
        Prorroga.transaction do
            begin
                @prorroga                         = Prorroga.new params[:prorroga]
                @prorroga.pago_comprometido_id    = params[:pago_comprometido_id]
                @prorroga.ejecutivo_matriculas_id = @ejecutivo_matriculas.id

                @prorroga.save
                flash[:notice] = "Se ha guardado la prorroga correctamente"
            rescue
                flash[:error] = "Ocurrió un error al guardar la prorroga"
            end
        end

        redirect_to matriculas_pagos_prorroga_path(params[:rut], params[:pago_comprometido_id])
    end

    def prorroga_eliminar
        Prorroga.transaction do
            begin
                @prorroga = Prorroga.get params[:prorroga_id]
                if @prorroga.ejecutivo_matriculas == @ejecutivo_matriculas
                    @prorroga.destroy

                    flash[:notice] = "La prorroga fue eliminada satisfactoriamente"
                else
                    flash[:error] = "Usted no es el ejecutivo que creó la prorroga, no puede eliminar"
                end
            rescue
                flash[:error] = "Ocurrió un error, no se pudo eliminar la prorroga"
            end
        end
        
        redirect_to matriculas_pagos_prorroga_path(params[:rut], params[:pago_comprometido_id])
    end
######################## END PRORROGAS ##################################
    private

    def iniciar
        @usuario              = current_user_object
        @ejecutivo_matriculas = @usuario.ejecutivo_matriculas

        unless params[:rut].blank?
            @us_alumno    = Usuario.first rut: params[:rut]
            @alumno       = @us_alumno.alumno if @us_alumno
            @apoderado    = @alumno.apoderado if @alumno
            @us_apoderado = @apoderado.datos_personales if @apoderado
        end
        rescue Exception => e
            puts e.inspect.red
    end

    def get_plan_pago
        if @alumno
            @matriculas_planes = @alumno.alumno_plan_estudio.matricula_plan 

            @planes_pago       = @matriculas_planes.planes_pago(order: :id.desc)

            @plan_pago_id      = params[:plan_pago].blank? ? 0 : params[:plan_pago].to_i
            @plan_pago         = @plan_pago_id.eql?(0) ? @planes_pago.first : PlanPago.get(@plan_pago_id)
            
            @planes_pago_anteriores = []

            @planes_pago.each do |plan|
                if @plan_pago.id.to_i != plan.id.to_i
                    @planes_pago_anteriores << plan
                end
            end

            unless @plan_pago.blank?
                @es_distancia      = @plan_pago.matricula_plan.alumno_plan_estudio.institucion_sede_plan.modalidad == InstitucionSedePlan::DISTANCIA
                @es_cft            = @plan_pago.matricula_plan.alumno_plan_estudio.institucion_sede_plan.institucion_sede.institucion_id == Institucion::CFT
            end
        end

        @medios_pago       = (MedioPago.all( fields: [:id, :nombre] ) - (MedioPago.all( slug: 'pagare' ) + MedioPago.all( slug: 'vale-vista' ) + MedioPago.all( slug: 'documento' )))
    end
end