# encoding: utf-8
class Cobranzas::PagosController < ApplicationController
    before_filter :iniciar
    protect_from_forgery :except => [:update_abono]

    def index
        unless params[:documento_venta].blank?
            b = DocumentoVenta.first numero: params[:documento_venta].to_i, 
                                     tipo: params[:tipo].to_i

            if b.blank?
                flash[:error] = "El documento de venta ingresado no existe"
            else
                redirect_to cobranzas_pagos_show_path(b.numero)
                return nil
            end
        end
    end

    
    def show
        @items = DocumentoVenta.all numero: params[:numero]

        if @items.blank?
            flash[:error] = "El documento de venta ingresado no existe"
            redirect_to cobranzas_pagos_index_path
        end
    end

    def edit
        @item = DocumentoVenta.get params[:id]

        @instituciones_sedes = InstitucionSede.all fields: [:id,:institucion_id,:sede_id],
                                                   sede_id: @usuario.sede_id

        @ejecutivos_matriculas = EjecutivoMatriculas.all fields: [:id,:usuario_id],
                                                         estado: RangoDocumento::HABILITADO,
                                                         datos_personales: {
                                                            sede_id: @usuario.sede_id
                                                         }
    end

    def update
        item = DocumentoVenta.get params[:id]
        dv = params[:documento_venta]
        i_s = InstitucionSede.first id: params[:institucion_sede].to_i

        DocumentoVenta.transaction do
            begin          
                item.fecha_emision = dv[:fecha_emision]   
                item.numero = dv[:numero]  
                item.monto = dv[:monto]
                item.ejecutivo_matriculas_id = params[:ejecutivo]  
                item.institucion_sede_id = i_s.id

                item.abonos.each do |abono|
                    abono.fecha = dv[:fecha_emision] 
                    abono.ejecutivo_matriculas_id = params[:ejecutivo]
                end

                item.save

                flash[:notice] = "Se actualizo el documento de venta"              
            rescue
                flash[:error] = "Ocurrió un error al modificar el documento de venta"
            end
        end
        redirect_to cobranzas_pagos_show_path(item.numero)
    end
    
    def update_abono
        abonos = params[:abonos]
        numero = params[:numero]

        Abono.transaction do
            begin
                abonos.each do |abono|
                    _abono = Abono.first id: abono[:id]

                    _abono.monto = abono[:monto]
                    _abono.interes = abono[:interes]
                    _abono.saldo = abono[:saldos]                    
                    _abono.save  

                    unless _abono[:pago_comprometido_id].blank?
                        pc = PagoComprometido.first id: _abono[:pago_comprometido_id]

                        pc.saldo = abono[:saldos]
                        
                        if abono[:saldos].to_i == 0
                            pc.estado = PagoComprometido::PAGADO
                        elsif abono[:saldos].to_i == pc[:monto].to_i
                            pc.estado = PagoComprometido::COMPROMETIDO
                        else
                            pc.estado = PagoComprometido::COMPROMETIDO_CON_ABONOS
                        end

                        pc.save

                    end
                end 

                flash[:notice] = "Se actualizo el documento de venta" 
            rescue
                flash[:error] = "Ocurrió un error al modificar el documento de venta"
            end
        end
        redirect_to cobranzas_pagos_show_path(numero)
    end

    def eliminar_documento_venta

        Abono.transaction do
            begin
                boleta = DocumentoVenta.first id: params[:boleta].to_i
                
                boleta.estado = DocumentoVenta::ANULADA
                boleta.fecha_anulacion = Time.now
                boleta.save
                
                boleta.abonos.each do |abono|
                    abono.estado = Abono::ANULADO

                    unless abono.pago_comprometido_id.blank?
                        pc = PagoComprometido.first id: abono[:pago_comprometido_id]

                        pc.saldo = pc.saldo + abono[:monto]

                        abonos_anteriores = pc.abonos(:estado.not => Abono::ANULADO,:documento_venta_id.not => boleta.id)

                        unless abonos_anteriores.blank?
                            pc.fecha_ultimo_abono = abonos_anteriores.last.fecha
                        else
                            pc.fecha_ultimo_abono = nil
                        end

                        pc.fecha_pago_realizado = nil

                        if pc.saldo.to_i == pc.monto.to_i
                            pc.estado = PagoComprometido::COMPROMETIDO
                        else
                            pc.estado = PagoComprometido::COMPROMETIDO_CON_ABONOS
                        end

                        pc.save
                    end

                    abono.save
                end

                flash[:notice] = "Se elimino el documento de venta "+boleta.numero.to_s

            rescue Exception => e
                flash[:error] = "Ocurrió un error al eliminar el documento de venta"
                log_error e
            end
        end
        redirect_to cobranzas_pagos_index_path
    end    

    def repactacion
        unless params[:busqueda].blank?
            redirect_to cobranzas_pagos_repactacion_path(params[:busqueda])
        end
        unless params[:rut].blank?
            @us_alumno = Usuario.first rut: params[:rut]

            if @us_alumno.blank?
                flash.now[:error] = "El alumno buscado no existe" 
            else
                store_location
                @periodos                = Periodo.lista

                if params[:matricula_id].blank?
                    matriculas          = MatriculaPlan.all alumno_plan_estudio: {
                                                    :alumno => {
                                                        :usuario_id => @us_alumno.id
                                                    }                
                                                }
                else
                    matriculas          = MatriculaPlan.all id: params[:matricula_id].to_i
                end

                @alumno_plan_estudio = matriculas.alumno_plan_estudio.last
                planes               = matriculas.planes_pagos
                pagos_comprometidos  = planes.pagos_comprometidos
                ejecutivos           = matriculas.ejecutivo_matriculas
                datos_personales     = ejecutivos.datos_personales

                
                @datos = []
                matriculas.each do |m|
                    tmp = []
                    planes.select{|p| p.matricula_plan_id == m.id}.each do |p|
                        tmp << {plan: p, pagos_comprometidos: pagos_comprometidos.select{|pc| pc.plan_pago_id == p.id}}
                    end
                    @datos << {
                        matricula: m,
                        periodo:   @periodos.select{|x| x.id == m.periodo_id}.first,
                        planes:    tmp,
                        ejecutivo: datos_personales.select{|d| d.id == ejecutivos.select{|e| e.id == m.ejecutivo_matriculas_id }.first.usuario_id}.first
                    }
                end
            end
        end
    end

    def guardar_repactacion
        puts params.inspect.red
        pagos_comprometidos = params[:repactacion][:pagos_comprometidos]
        situacion = params[:repactacion][:situacion]
        plan_pago = params[:repactacion][:plan_pago]

        Situacion.transaction do
            sit = Situacion.new fecha:                      Time.now, 
                                resolucion:                 situacion[:número_resolución],
                                observacion:                situacion[:observación],
                                tipo_situacion_id:          79,
                                ejecutivo_matriculas_id:    @ejecutivo_matriculas.id,
                                plan_pago_id:               plan_pago,
                                periodo_id:                 Periodo::en_curso.id,
                                tipo:                       Situacion::ADMINISTRATIVO
            
            sit.save  

            pagos_comprometidos.each do |pc,valor|
                if valor.to_i == 1
                    pago_comprometido = PagoComprometido.get pc
                    pago_comprometido.update estado: PagoComprometido::REPACTADO,
                                             fecha_anulacion: Time.now    
                end  
                
            end
        end  

        flash[:notice] = "La repactación de deuda se realizó correctamente."

        redirect_back_or_default

        rescue Exception => e
            flash[:error] = "Ocurrió un error durante la repactación, comunicarse con Sistemas."
            log_error e
            redirect_back_or_default

    end

    def certificado_repactacion
        plan = PlanPago.get params[:plan]
        @situacion = Situacion.first plan_pago_id: plan.id 

        @suma = params[:suma]

        periodo = plan.periodo
        @anio = periodo.anio

        alumno_plan_estudio = plan.matricula_plan.alumno_plan_estudio
        institucion_sede_plan = alumno_plan_estudio.institucion_sede_plan

        @alumno = alumno_plan_estudio.alumno.datos_personales
        @plan = institucion_sede_plan.plan_estudio.nombre

        institucion_sede = institucion_sede_plan.institucion_sede
        @sede = institucion_sede.sede.nombre
        @institucion = institucion_sede.institucion.nombre
        
        carpeta = "#{Certificado::URL_DOCUMENTOS}/#{institucion_sede.id}/#{periodo.anio}/#{periodo.semestre}"
        fcertificado = "#{carpeta}/#{@alumno.rut}_certificado-repactacion.pdf".delete(" ")

        FileUtils.mkdir_p carpeta

        str = render_to_string("matriculas/pagos/certificados/certificado-repactacion", :layout => "pdf_sin_logo")

        pdf = WickedPdf.new.pdf_from_string(str, :disposition => 'inline')

        certificado = File.open(fcertificado, 'wb') do |file|
            file << pdf
        end
        
        redirect_to certificado.path.partition("public")[2]
        #render :text => str
    end

	private
    
	def iniciar
		@usuario = current_user_object
		@ejecutivo_matriculas = @usuario.ejecutivo_matriculas
	end
end