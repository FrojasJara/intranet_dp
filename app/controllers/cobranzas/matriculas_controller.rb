# encoding: utf-8
class Cobranzas::MatriculasController < ApplicationController
    before_filter :store_location, only: [:anulacion]
    before_filter :iniciar
    protect_from_forgery :except => [:agregar_beneficio]

    def informes
        @instituciones_sedes = InstitucionSede.instituciones_en_sede @usuario.sede_id
        @instituciones_sedes_all = InstitucionSede.instituciones_en_sede_all @usuario.sede_id
        @periodos = Periodo.all order: [:anio.desc, :semestre.desc]

        @instituciones = Institucion.all fields: [:id,:nombre]
        @sedes = Sede.all fields: [:id,:nombre], id: Sede::SEDES_VIGENTES
    end

    def informe_fechas
        @p_f_i = params[:filtro][:fecha_inicio]
        @p_f_t = params[:filtro][:fecha_termino]

        if @p_f_t.blank? #solo el mismo día
            f_i     = Time.parse(@p_f_i)
            f_t     = Time.parse(@p_f_i+' 23:59:59')
        else #es un rango de fechas
            f_i     = Time.parse(@p_f_i)
            f_t     = Time.parse(@p_f_t+' 23:59:59')
        end
        
        @matricula_planes = MatriculaPlan.all :created_at => f_i..f_t, 
                            :alumno_plan_estudio => {
                                :institucion_sede_plan => {
                                    :institucion_sede_id => params[:institucion_sede_id]    
                                }
                                
                            }     
    end

    def informe_pagares
        @p_f_i = params[:filtro][:fecha_inicio2]
        @p_f_t = params[:filtro][:fecha_termino2]

        if @p_f_t.blank? #solo el mismo día
            f_i     = Time.parse(@p_f_i)
            f_t     = Time.parse(@p_f_i+' 23:59:59')
        else #es un rango de fechas
            f_i     = Time.parse(@p_f_i)
            f_t     = Time.parse(@p_f_t+' 23:59:59')
        end
        
        @pagares = Pagare.all :created_at => f_i..f_t,
                              :estado => Pagare::VIGENTE,
                              :alumno_plan_estudio => {
                                :institucion_sede_plan => {
                                    :institucion_sede => {
                                            :institucion_id => params[:institucion_id],
                                            :sede_id => params[:sede_id]
                                        },
                                    :modalidad => params[:modalidad]
                                }
                            }
    end

    def informe_pagares_detalle
        @p_f_i = params[:filtro][:fecha_inicio3]
        @p_f_t = params[:filtro][:fecha_termino3]

        if @p_f_t.blank? #solo el mismo día
            f_i     = Time.parse(@p_f_i)
            f_t     = Time.parse(@p_f_i+' 23:59:59')
        else #es un rango de fechas
            f_i     = Time.parse(@p_f_i)
            f_t     = Time.parse(@p_f_t+' 23:59:59')
        end

        @pagos = PagoComprometido.all :pagare => {
                                        :created_at => f_i..f_t,
                                        :estado => Pagare::VIGENTE,
                                        :alumno_plan_estudio => {
                                            :institucion_sede_plan => {
                                                :institucion_sede => {
                                                    :institucion_id => params[:institucion_id],
                                                    :sede_id => params[:sede_id]
                                                },
                                                :modalidad => params[:modalidad]
                                            }
                                        }
                                    }
    end

    def informe_pagares_detalle_anuladas
        @p_f_i = params[:filtro][:fecha_inicio4]
        @p_f_t = params[:filtro][:fecha_termino4]

        if @p_f_t.blank? #solo el mismo día
            f_i     = Time.parse(@p_f_i)
            f_t     = Time.parse(@p_f_i+' 23:59:59')
        else #es un rango de fechas
            f_i     = Time.parse(@p_f_i)
            f_t     = Time.parse(@p_f_t+' 23:59:59')
        end

        @pagos = PagoComprometido.all :pagare => {
                                        :alumno_plan_estudio => {
                                            :institucion_sede_plan => {
                                                :institucion_sede => {
                                                    :institucion_id => params[:institucion_id],
                                                    :sede_id => params[:sede_id]
                                                },
                                                :modalidad => params[:modalidad]
                                            }
                                        }
                                      },
                                      estado: PagoComprometido::ANULADO,
                                      fecha_anulacion: f_i..f_t
    end

    def informe_convenios
        periodo_consulta    = []
        @periodo            = Periodo.get params[:periodo_id]
        periodo_consulta    << @periodo.id

        @periodo_ant        = Periodo.get Periodo.periodo_anterior( @periodo.id )
        @periodo_anterior   = @periodo_ant.id
        periodo_consulta    << @periodo_anterior if !@periodo_anterior.blank? and @periodo.semestre.eql?(1)

        if params[:institucion_sede_id].to_i == (-1)
            institucion_sede_planes = InstitucionSedePlan.all fields: [:id]
        else 
            institucion_sede_planes = InstitucionSedePlan.all fields: [:id],
                                                            :institucion_sede_id => params[:institucion_sede_id]

            @institucion_sede = InstitucionSede.first id: params[:institucion_sede_id]
        end

        alumnos_planes_estudios = AlumnoPlanEstudio.all fields: [:id, :institucion_sede_plan_id, :alumno_id, :anio_ingreso],
                                                            :institucion_sede_plan_id => institucion_sede_planes.map(&:id),
                                                            :anio_ingreso => @periodo.anio
                                                            
        al_pl_es            = { 
                                    fields: [:id, :alumno_plan_estudio_id, :created_at],
                                    :alumno_plan_estudio_id => alumnos_planes_estudios.map(&:id).uniq
                             }
        
        if periodo_consulta.length.eql? 1
            matriculas = MatriculaPlan.all( {:periodo_id => @periodo.id}.merge(al_pl_es) ) 
        else
            matriculas = MatriculaPlan.all( {:periodo_id => @periodo.id}.merge(al_pl_es) ) + 
                         MatriculaPlan.all( {:periodo_id => @periodo_anterior, planes_pago: {:tipo => MatriculaPlan::MATRICULAS_ANUALES_VALORES} }.merge(al_pl_es) ) 
        end


        alumnos_planes_estudios    = AlumnoPlanEstudio.all fields: [:id, :institucion_sede_plan_id, :alumno_id, :anio_ingreso], id: matriculas.map(&:alumno_plan_estudio_id).uniq
        instituciones_sedes_planes = alumnos_planes_estudios.institucion_sede_plan
        planes_pagos               = matriculas.planes_pagos(fields: [:id, :nivel, :descuento_id])
        @descuentos                = planes_pagos.descuentos

        @matriculas = []

        matriculas.each do |m|
            al_pl_es = alumnos_planes_estudios.select{|x| x.id == m.alumno_plan_estudio_id}.first
            in_se_pl = instituciones_sedes_planes.select{|x| x.id == al_pl_es.institucion_sede_plan_id}.first
            pl_pg    = (pp = planes_pagos.select{|x| x.matricula_plan_id == m.id}).blank? ? nil : pp.last
            dscto    = @descuentos.select{|x| x.id == pl_pg.descuento_id}.first

            @matriculas << {
                matricula:              m,
                alumno_plan_estudio:    al_pl_es,
                plan_pago:              pl_pg,
                descuento:              dscto
            }
        end  
    end

    def informe_periodo
        periodo_consulta    = []
        @periodo            = Periodo.get params[:periodo_id]
        periodo_consulta    << @periodo.id

        @periodo_ant        = Periodo.get Periodo.periodo_anterior( @periodo.id )
        @periodo_anterior   = @periodo_ant.id
        periodo_consulta    << @periodo_anterior if !@periodo_anterior.blank?
        except_alumno = ""

        if  params[:institucion_sede_id].to_i == (-1)
            institucion_sede_planes = InstitucionSedePlan.all   fields: [:id],
                                                                alumno_plan_estudio: {
                                                                    matricula_plan: {
                                                                            periodo_id: periodo_consulta
                                                                    }
                                                                }
        else
            institucion_sede_planes = InstitucionSedePlan.all   fields: [:id],
                                                                :institucion_sede_id => params[:institucion_sede_id],
                                                                alumno_plan_estudio: {
                                                                    matricula_plan: {
                                                                            periodo_id: periodo_consulta
                                                                    }
                                                                }

            @institucion_sede = InstitucionSede.first id: params[:institucion_sede_id]
        end

        alumnos_planes_estudios    = AlumnoPlanEstudio.all fields: [:id, :institucion_sede_plan_id, :alumno_id, :anio_ingreso],
                                                           :institucion_sede_plan_id => institucion_sede_planes.map(&:id),
                                                           matricula_plan: {
                                                                periodo_id: periodo_consulta
                                                           }
                                                            
        al_pl_es = { 
                    fields: [:id, :alumno_plan_estudio_id, :created_at],
                    :alumno_plan_estudio_id => alumnos_planes_estudios.map(&:id).uniq,
                   }
        
        matriculas = MatriculaPlan.all( {:periodo_id => @periodo.id,
                                        :estado.not => [MatriculaPlan::ANULADA]}.merge(al_pl_es) ) + 
                     MatriculaPlan.all( {:periodo_id => @periodo_anterior, 
                                        :estado.not => [MatriculaPlan::ANULADA],
                                        planes_pago: {
                                            :periodo_id => @periodo_anterior, 
                                            :tipo => MatriculaPlan::MATRICULAS_ANUALES_VALORES
                                        } }.merge(al_pl_es) ) +
                     MatriculaPlan.all( {:periodo_id => @periodo_anterior, 
                                        :estado.not => [MatriculaPlan::ANULADA],
                                        planes_pago: {
                                            :periodo_id => @periodo.id, 
                                            :tipo => MatriculaPlan::MATRICULAS_SEMESTRALES
                                        } }.merge(al_pl_es) )

        alumnos_planes_estudios    = AlumnoPlanEstudio.all fields: [:id, :institucion_sede_plan_id, :alumno_id, :anio_ingreso], 
                                                           id: matriculas.map(&:alumno_plan_estudio_id).uniq,
                                                           matricula_plan: {
                                                             periodo_id: periodo_consulta
                                                           }

        alumnos                    = alumnos_planes_estudios.alumnos fields:[:id, :usuario_id], id: alumnos_planes_estudios.map(&:alumno_id).uniq
        usuarios                   = alumnos.datos_personales(fields: [:id, :rut, :primer_nombre, :segundo_nombre, :apellido_paterno, :apellido_materno])
        instituciones_sedes_planes = alumnos_planes_estudios.institucion_sede_plan
        planes_estudios            = instituciones_sedes_planes.plan_estudio(fields: [:id, :nombre])
        secciones_inscritas        = alumnos_planes_estudios.links_secciones_inscritas(fields: [:id, :alumno_plan_estudio_id], :seccion_dictada => { seccion: {:periodo => @periodo } } )
        planes_pagos               = matriculas.planes_pagos(fields: [:id, :nivel])
        pendientes                 = planes_pagos.pagos_comprometidos(fields: [:id, :monto, :saldo, :fecha_vencimiento], :estado.not => [PagoComprometido::PAGADO, PagoComprometido::ANULADO, PagoComprometido::REPACTADO])+planes_pagos.pagos_comprometidos(fields: [:id, :monto, :saldo], estado: nil)
        prorrogas                  = pendientes.prorrogas

        @matriculas = []

        matriculas.each do |m|
            except_alumno = m.alumno_plan_estudio.alumno.datos_personales.rut

            al_pl_es = alumnos_planes_estudios.select{|x| x.id == m.alumno_plan_estudio_id}.first
            al       = alumnos.select{|x| x.id == al_pl_es.alumno_id}.first
            us       = usuarios.select{|x| x.id == al.usuario_id}.first
            in_se_pl = instituciones_sedes_planes.select{|x| x.id == al_pl_es.institucion_sede_plan_id}.first
            pl_es    = planes_estudios.select{|x| x.id == in_se_pl.plan_estudio_id}.first
            sec_ins  = secciones_inscritas.select{|x| x.alumno_plan_estudio_id == al_pl_es.id}
            pl_pg    = (pp = planes_pagos.select{|x| x.matricula_plan_id == m.id}).blank? ? nil : pp.last
            pp_pend  = pendientes.select{|x| x.plan_pago_id == pl_pg.id}
            
            pendientes_incobrables = []
            pendientes_cobrables = []

            pp_pend.each do |p|
                if p.tiene_cobranza? p.id
                    if p.cobranza.tipo == Cobranza::INCOBRABLE
                        pendientes_incobrables << p
                    else
                        pendientes_cobrables << p
                    end
                else
                    pendientes_cobrables << p
                end
            end

            pp_atras = pendientes_cobrables.select{ |x| x.fecha_vencimiento != nil and x.fecha_vencimiento <= Date.today and prorrogas.select{ |p| p.pago_comprometido_id == x.id and p.fecha >= Date.today }.length.eql?(0) }

            @matriculas << {
                matricula:              m,
                alumno_plan_estudio:    al_pl_es,
                alumno:                 al,
                usuario:                us,
                plan_estudio:           pl_es,
                inscripciones:          sec_ins,
                plan_pago:              pl_pg,
                pendientes:             pp_pend,
                cobrables:              pp_atras,
                incobrables:            pendientes_incobrables,
                institucion_sede_plan:  in_se_pl
            }
        end  

        rescue Exception => e
            unless except_alumno.blank?
                flash[:error] = "El alumno de rut #{except_alumno}, presenta problemas en su información, comunicarse con sistemas "
                log_error e
            else
                flash[:error] = "Ha ocurrido un error inesperado, comunicarse con sistemas "
                log_error e
            end
            redirect_to cobranzas_matriculas_informes_path
    end

    def informe_apoderados
        # Crea arreglo para guardar periodos
        periodo_consulta    = []

        # Guarda periodo actual
        @periodo            = Periodo.get params[:periodo_id]
        periodo_consulta    << @periodo.id

        # Guarda periodo anterior
        @periodo_ant        = Periodo.get Periodo.periodo_anterior( @periodo.id )
        @periodo_anterior   = @periodo_ant.id
        periodo_consulta    << @periodo_anterior if !@periodo_anterior.blank?
        except_alumno = ''

        @institucion_sede   = InstitucionSede.first fields: [:id,:institucion_id,:sede_id],
                                                    id: params[:institucion_sede_id]                       

        alumnos_planes_estudios = AlumnoPlanEstudio.all fields: [:id],
                                                        institucion_sede_plan: {
                                                            institucion_sede_id: params[:institucion_sede_id]
                                                        },
                                                        matricula_plan: {
                                                            periodo_id: periodo_consulta
                                                        }
        
        matricula = {   
                        fields: [:id],
                        :alumno_plan_estudio_id => alumnos_planes_estudios.map(&:id).uniq
                    }
        
        matriculas = MatriculaPlan.all( {:periodo_id => @periodo.id,
                                        :estado.not => [MatriculaPlan::ANULADA]}.merge(matricula) ) + 
                     MatriculaPlan.all( {:periodo_id => @periodo_anterior, 
                                        :estado.not => [MatriculaPlan::ANULADA],
                                        planes_pago: {
                                            :periodo_id => @periodo_anterior, 
                                            :tipo => MatriculaPlan::MATRICULAS_ANUALES_VALORES
                                        } }.merge(matricula) ) +
                     MatriculaPlan.all( {:periodo_id => @periodo_anterior, 
                                        :estado.not => [MatriculaPlan::ANULADA],
                                        planes_pago: {
                                            :periodo_id => @periodo.id, 
                                            :tipo => MatriculaPlan::MATRICULAS_SEMESTRALES
                                        } }.merge(matricula) )

        @matriculas = []

        matriculas.each do |m|
            except_alumno = m.alumno_plan_estudio.alumno.datos_personales.rut
            al_pl_es = m.alumno_plan_estudio
            al       = al_pl_es.alumno(fields:[:id, :usuario_id,:apoderado_id])
            us       = al.datos_personales(fields: [:id, :rut, :primer_nombre, :segundo_nombre, :apellido_paterno, :apellido_materno])
            ap_us    = al.apoderado.datos_personales
            in_se_pl = al_pl_es.institucion_sede_plan
            pl_es    = in_se_pl.plan_estudio(fields: [:id, :nombre])
            pend     = m.planes_pago.pagos_comprometidos(fields: [:id, :monto, :saldo, :fecha_vencimiento], :estado.not => [PagoComprometido::PAGADO, PagoComprometido::ANULADO]) + m.planes_pago.pagos_comprometidos(fields: [:id, :monto, :saldo], estado: nil)
            
            pendientes_cobrables = []
            pendientes_incobrables = []

            pend.each do |p|
                if p.tiene_cobranza? p.id
                    if p.cobranza.tipo == Cobranza::INCOBRABLE
                        pendientes_incobrables << p
                    else
                        pendientes_cobrables << p
                    end
                else
                    pendientes_cobrables << p
                end
            end

            atrasad  = pendientes_cobrables.select{ |x| x.fecha_vencimiento != nil and x.fecha_vencimiento <= Date.today and pend.prorrogas.select{ |p| p.pago_comprometido_id == x.id and p.fecha >= Date.today }.length.eql?(0) }
            
            @matriculas << {
                matricula:              m,
                alumno_plan_estudio:    al_pl_es,
                institucion_sede_plan:  in_se_pl,
                alumno:                 al,
                usuario:                us,
                apoderado:              ap_us,
                plan_estudio:           pl_es,
                pendientes:             pend,
                cobrables:              atrasad,
                incobrables:            pendientes_incobrables
            }
        end 

        rescue Exception => e
            unless except_alumno.blank?
                flash[:error] = "El alumno de rut #{except_alumno}, presenta problemas en su información, comunicarse con sistemas "
                log_error e
            else
                flash[:error] = "Ha ocurrido un error inesperado, comunicarse con sistemas "
                log_error e
            end

            redirect_to cobranzas_matriculas_informes_path
    end

    def anulacion
        unless params[:busqueda].blank?
            redirect_to cobranzas_matriculas_anulacion_path(params[:busqueda])
        end
        unless params[:rut].blank?
            @us_alumno = Usuario.first rut: params[:rut]
            if @us_alumno.blank?
                flash.now[:error] = "El alumno buscado no existe" 
            else
                @items = MatriculaPlan.all alumno_plan_estudio: {
                                                :alumno => {
                                                    :usuario_id => @us_alumno.id
                                                }                
                                            }

                @alumno_plan_estudio = @items.last.alumno_plan_estudio
            end
        end
    end

    def anular
        
        matricula = MatriculaPlan.get params[:matricula_plan_id]

        raise Exception if matricula.blank?

        MatriculaPlan.transaction do
            planes_pagos = matricula.planes_pago
            unless planes_pagos.blank? 
                planes_pagos.each do |plan_pago|
                    unless plan_pago.pagos_comprometidos.blank?
                        plan_pago.pagos_comprometidos.each do |pago_comprometido|
                            raise Excepciones::ModificacionConflictiva, "Existen #{pago_comprometido.abonos.length} abonos para este Plan de Matrícula, por lo que no es factible su eliminación" if pago_comprometido.abonos.length > 0
                            pago_comprometido.update fecha_anulacion: Time.now, estado: PagoComprometido::ANULADO
                        end
                        
                        Pagare.all(plan_pago: plan_pago).each do |pagare|
                            pagare.update(fecha_anulacion: Time.now, estado: Pagare::ANULADO)
                        end
                    
                    end
                    plan_pago.update fecha_anulacion: Time.now, estado: PlanPago::ANULADO
                end
            end
            matricula.update fecha_anulacion: Time.now, estado: MatriculaPlan::ANULADA
            matricula.alumno_plan_estudio.update estado: Alumno::ANULADO
            flash[:notice] = "La matrícula y su plan de pagos fue anulado correctamente."
        end

        redirect_back_or_default
        
        rescue Excepciones::ModificacionConflictiva => e
            flash[:error] = e.message
            redirect_back_or_default   

        rescue DataMapper::SaveFailureError => e
            flash[:error] = e.resource.errors.inspect
            puts e.resource.errors.inspect
            redirect_back_or_default   

        rescue Exception => e
            flash[:error] = "Ocurrió un error al intentar eliminar los datos, intente nuevamente o contacte a los administradores."
            puts e.message.red
            redirect_back_or_default        

    end

    def edicion
        unless params[:busqueda].blank?
            redirect_to cobranzas_matriculas_edicion_path(params[:busqueda])
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

    def guardar_edicion
        p_matricula    = params[:edicion][:matricula]
        p_plan         = params[:edicion][:plan].first
        p_situacion_ac = params[:edicion][:situacion_academica]
        p_situacion_ad = params[:edicion][:situacion_administrativa]

        MatriculaPlan.transaction do

            matricula           = MatriculaPlan.get p_matricula[:id]
            alumno_plan_estudio = matricula.alumno_plan_estudio
            estado_previo       = alumno_plan_estudio.estado
            
            matricula.update(estado: p_matricula[:estado]) if matricula.estado != p_matricula[:estado]
            matricula.update(periodo_id: p_matricula[:periodo_id]) if matricula.periodo_id != p_matricula[:periodo_id]
            
            pl_pago = PlanPago.get p_plan.first.to_i

            pl_pago.update estado: p_plan.last[:estado] if p_plan.last[:estado] != pl_pago.estado
            pl_pago.update tipo: p_plan.last[:tipo] if p_plan.last[:tipo] != pl_pago.tipo
            pl_pago.update periodo_id: p_plan.last[:periodo_id] if p_plan.last[:periodo_id] != pl_pago.periodo_id

            p_plan.last[:pago_comprometido].each do |pc|
                
                pago_comprometido = PagoComprometido.get pc[0]
                pago_comprometido.update estado: pc[1][:estado]
                pago_comprometido.update centro_costo: pc[1][:centro_costo]
                pago_comprometido.update numero_cuota: pc[1][:numero_cuota].blank? ? nil : pc[1][:numero_cuota]
                
                if pc[1][:estado].to_i == PagoComprometido::ANULADO
                    pago_comprometido.update fecha_anulacion: Time.now
                else
                    pago_comprometido.update fecha_anulacion: nil
                end       
            end

            unless p_situacion_ac.blank? || p_situacion_ac[:fecha].blank? && p_situacion_ac[:numero_resolucion].blank?

                unless p_situacion_ac[:estado].eql? alumno_plan_estudio.estado
                    alumno_plan_estudio.update estado: p_situacion_ac[:estado]
                end

                sit = Situacion.new     fecha:                      p_situacion_ac[:fecha], 
                                        resolucion:                 p_situacion_ac[:numero_resolucion],
                                        observacion:                p_situacion_ac[:observacion],
                                        ejecutivo_matriculas_id:    current_user_object.ejecutivo_matriculas.id,
                                        estado:                     p_situacion_ac[:estado],
                                        estado_previo:              estado_previo,
                                        plan_pago_id:               pl_pago.id,
                                        periodo_id:                 p_matricula[:periodo_id],
                                        tipo:                       Situacion::ACADEMICO
                sit.save    

            end


            unless p_situacion_ad[:fecha].blank? && p_situacion_ad[:numero_resolucion].blank?

                sit = Situacion.new     fecha:                      p_situacion_ad[:fecha], 
                                        resolucion:                 p_situacion_ad[:numero_resolucion],
                                        observacion:                p_situacion_ad[:observacion],
                                        tipo_situacion_id:          p_situacion_ad[:tipo_situacion],
                                        ejecutivo_matriculas_id:    current_user_object.ejecutivo_matriculas.id,
                                        plan_pago_id:               pl_pago.id,
                                        periodo_id:                 p_matricula[:periodo_id],
                                        tipo:                       Situacion::ADMINISTRATIVO
                sit.save    

            end

        end

        flash[:notice] = "Se realizó la edición del plan."

        redirect_back_or_default

        rescue Exception => e
            flash[:error] = "Ocurrió un error durante la edición, comunicarse con Sistemas."
            log_error e
            redirect_back_or_default

    end

    def beneficio
        unless params[:busqueda].blank?
            redirect_to cobranzas_matriculas_beneficio_path(params[:busqueda])
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

                @descuentos = Descuento.all fields: [:id,:nombre,:porcentaje],
                                            order: :nombre,
                                            estado: Descuento::VIGENTE

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

    def postbeneficio
        unless params[:busqueda].blank?
            redirect_to cobranzas_matriculas_postbeneficio_path(params[:busqueda])
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

                @descuentos = Descuento.all fields: [:id,:nombre,:porcentaje],
                                            order: :nombre,
                                            estado: Descuento::VIGENTE

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

    def agregar_beneficio
        plan_pago = PlanPago.first id: params[:plan_pago_id].to_i
        descuento = Descuento.first id: params[:descuento_id].to_i

        mat_id = plan_pago.matricula_plan_id
        rut = plan_pago.matricula_plan.alumno_plan_estudio.alumno.datos_personales.rut

        if plan_pago.descuento_aplicado != 0
            flash[:error] = "El plan de pago ya está asociado a un descuento."
            redirect_to cobranzas_matriculas_beneficio_path(rut: rut,matricula_id: mat_id)
        else
            PlanPago.transaction do
                plan_pago.descuento_aplicado = (plan_pago.deuda * descuento.porcentaje) / 100
                plan_pago.arancel_total = plan_pago.arancel - plan_pago.descuento_aplicado
                plan_pago.descuento_id = descuento.id

                plan_pago.pagos_comprometidos(:centro_costo.not => PagoComprometido::MATRICULA).each do |cuota|
                    descuento_cuota = cuota.saldo * descuento.porcentaje / 100
                    cuota.monto = cuota.monto - descuento_cuota
                    cuota.saldo = cuota.saldo - descuento_cuota
                    cuota.save
                end

                pagare = plan_pago.pagares(estado: Pagare::VIGENTE).last
                puts pagare.inspect.blue
                
                pagare.monto = plan_pago.arancel_total
                pagare.save

                plan_pago.save
            end

            flash[:notice] = "El plan de pago se ha actualizado correctamente."
            redirect_to cobranzas_matriculas_beneficio_path(rut: rut,matricula_id: mat_id)
    
        end

        rescue Exception => e
            flash[:error] = "No se pudo agregar el beneficio, intentelo nuevamente."
            log_error e
            redirect_to cobranzas_matriculas_beneficio_path(rut: rut,matricula_id: mat_id)
    end

    def agregar_postbeneficio
        plan_pago = PlanPago.first id: params[:plan_pago_id].to_i
        postdescuento = Descuento.first id: params[:descuento_id].to_i

        mat_id = plan_pago.matricula_plan_id
        rut = plan_pago.matricula_plan.alumno_plan_estudio.alumno.datos_personales.rut

        if plan_pago.descuento_aplicado.eql?(0)
            flash[:error] = "El plan de pago no está asociado a ningun beneficio."
            redirect_to cobranzas_matriculas_postbeneficio_path(rut: rut,matricula_id: mat_id)
        else 
            unless plan_pago.postdescuento.blank?
                flash[:error] = "El plan de pago ya posee dos beneficios."
                redirect_to cobranzas_matriculas_postbeneficio_path(rut: rut,matricula_id: mat_id)
            else
                PlanPago.transaction do
                    plan_pago.descuento_aplicado += (plan_pago.deuda * postdescuento.porcentaje) / 100
                    plan_pago.arancel_total = plan_pago.arancel - plan_pago.descuento_aplicado
                    plan_pago.postdescuento_id = postdescuento.id

                    plan_pago.pagos_comprometidos(:centro_costo.not => PagoComprometido::MATRICULA).each do |cuota|
                        descuento_cuota = cuota.saldo * postdescuento.porcentaje / 100
                        cuota.monto = cuota.monto - descuento_cuota
                        cuota.saldo = cuota.saldo - descuento_cuota
                        cuota.save
                    end

                    pagare = plan_pago.pagares(estado: Pagare::VIGENTE).last
                    
                    pagare.monto = plan_pago.arancel_total
                    pagare.save

                    plan_pago.save
                end

                flash[:notice] = "El plan de pago se ha actualizado correctamente."
                redirect_to cobranzas_matriculas_postbeneficio_path(rut: rut,matricula_id: mat_id)
        
            end
        end

        rescue Exception => e
            flash[:error] = "No se pudo agregar el beneficio, intentelo nuevamente."
            log_error e
            redirect_to cobranzas_matriculas_postbeneficio_path(rut: rut,matricula_id: mat_id)
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
end