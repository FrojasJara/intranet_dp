# encoding: utf-8
class Matriculas::InformesController < ApplicationController
    before_filter :iniciar

    def index
        @instituciones_sedes = InstitucionSede.instituciones_en_sede @usuario.sede_id
        @periodos = Periodo.all order: [:anio.desc, :semestre.desc],
                                :estado.not => Periodo::PROXIMO
    end

    def deuda
        periodo_consulta    = []
        @periodo            = Periodo.get params[:periodo_id]
        periodo_consulta    << @periodo.id

        @periodo_ant        = Periodo.get Periodo.periodo_anterior( @periodo.id )
        @periodo_anterior   = @periodo_ant.id
        periodo_consulta    << @periodo_anterior if !@periodo_anterior.blank?
        except_alumno = ""

        institucion_sede_planes = InstitucionSedePlan.all   fields: [:id],
                                                            :institucion_sede_id => params[:institucion_sede_id],
                                                            :plan_estudio_id => PlanEstudio::MALLAS_N_HASH[params[:malla].to_i]
                                                            

        alumnos_planes_estudios    = AlumnoPlanEstudio.all fields: [:id, :institucion_sede_plan_id, :alumno_id, :anio_ingreso],
                                                            :institucion_sede_plan_id => institucion_sede_planes.map(&:id)
                                                            
        
        al_pl_es = { 
                    fields: [:id, :alumno_plan_estudio_id, :created_at],
                    :alumno_plan_estudio_id => alumnos_planes_estudios.map(&:id).uniq
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

        alumnos                    = alumnos_planes_estudios.alumnos fields:[:id, :usuario_id], id: alumnos_planes_estudios.map(&:alumno_id).uniq
        usuarios                   = alumnos.datos_personales(fields: [:id, :rut, :primer_nombre, :segundo_nombre, :apellido_paterno, :apellido_materno])
        instituciones_sedes_planes = alumnos_planes_estudios.institucion_sede_plan
        planes_pagos               = matriculas.planes_pagos(fields: [:id, :nivel])
        pendientes                 = planes_pagos.pagos_comprometidos(fields: [:id, :monto, :fecha_vencimiento], :estado.not => [PagoComprometido::PAGADO, PagoComprometido::ANULADO])+planes_pagos.pagos_comprometidos(fields: [:id, :monto], estado: nil)
        prorrogas                  = pendientes.prorrogas
        secciones_inscritas        = alumnos_planes_estudios.links_secciones_inscritas(fields: [:id, :alumno_plan_estudio_id], :seccion_dictada => { seccion: {:periodo => @periodo } } )

        @matriculas = []

        matriculas.each do |m|
            al_pl_es = alumnos_planes_estudios.select{|x| x.id == m.alumno_plan_estudio_id}.first
            al       = alumnos.select{|x| x.id == al_pl_es.alumno_id}.first
            us       = usuarios.select{|x| x.id == al.usuario_id}.first
            in_se_pl = instituciones_sedes_planes.select{|x| x.id == al_pl_es.institucion_sede_plan_id}.first
            pl_pg    = (pp = planes_pagos.select{|x| x.matricula_plan_id == m.id}).blank? ? nil : pp.last
            pp_pend  = pendientes.select{|x| x.plan_pago_id == pl_pg.id}
            pp_atras = pp_pend.select{ |x| x.fecha_vencimiento != nil and x.fecha_vencimiento <= Date.today and prorrogas.select{ |p| p.pago_comprometido_id == x.id and p.fecha >= Date.today }.length.eql?(0) }
            sec_ins  = secciones_inscritas.select{|x| x.alumno_plan_estudio_id == al_pl_es.id}
            
            @matriculas << {
                matricula:              m,
                alumno_plan_estudio:    al_pl_es,
                alumno:                 al,
                usuario:                us,
                plan_pago:              pl_pg,
                pendientes:             pp_pend,
                atrasadas:              pp_atras,
                institucion_sede_plan:  in_se_pl,
                inscripciones:          sec_ins,
            }
        end

        rescue Exception => e
            unless except_alumno.blank?
                flash[:error] = "El alumno de rut #{except_alumno}, presenta problemas en su información, comunicarse con sistemas "
            else
                flash[:error] = "Ha ocurrido un error inesperado, comunicarse con sistemas "
                log_error e
            end
            redirect_to matriculas_informes_path
 
    end

    def lista_pagos
        if params[:pagos][:fecha_inicio].blank?
            flash[:error] = "Debe seleccionar una fecha de inicio"
            redirect_to cobranzas_tesoreria_informe_path
        else
            @f_i = params[:pagos][:fecha_inicio]
            @f_t = params[:pagos][:fecha_termino]

            if @f_t.blank? #solo el mismo día
                f_i     = Time.parse(@f_i)
                f_t     = Time.parse(@f_i+' 23:59:59')
            else #es un rango de fechas
                f_i     = Time.parse(@f_i)
                f_t     = Time.parse(@f_t+' 23:59:59')
            end
        end

        @institucion_sede = InstitucionSede.get params[:institucion_sede_id]

        documentos_venta = DocumentoVenta.all( :estado              => DocumentoVenta::ENTREGADA,
                                               :fecha_emision.gte   => f_i, 
                                               :fecha_emision.lte   => f_t, 
                                               :institucion_sede_id => params[:institucion_sede_id],
                                               :order               => [:numero.asc])

        ejecutivos    = documentos_venta.ejecutivo_matriculas
        us_ejecutivos = ejecutivos.datos_personales
        


        @tipos_abonos = TipoAbono.all(fields: [:id, :nombre])

        abonos           = Abono.all( :documento_venta_id => documentos_venta.map(&:id) )
        al_pl_es         = abonos.alumno_plan_estudio
        alumnos          = al_pl_es.alumnos
        datos_personales = alumnos.datos_personales
        ins_sed_plan     = al_pl_es.institucion_sede_plan
        planes_estudio   = ins_sed_plan.plan_estudio

        @datos = []

        documentos_venta.each do |x|

            _abonos = abonos.select{|a| a.documento_venta_id == x.id}
        
            if((_abonos.first.blank?) or (_abonos.first.alumno_plan_estudio_id.blank?))
                dp = {rut: x.rut, nombre: x.nombre_completo, carrera: x.carrera}
            else
                tmp = al_pl_es.select{|a| a.id == _abonos.first.alumno_plan_estudio_id}.first
                al  = datos_personales.select{|d| d.id == (alumnos.select{|a| a.id == tmp.alumno_id}.first).usuario_id}.first
                pl  = planes_estudio.select{|p| p.id == (ins_sed_plan.select{|i| i.id == tmp.institucion_sede_plan_id}.first).plan_estudio_id}.first

                dp = {rut: al.rut, nombre: al.nombre, carrera: pl.nombre}
            end
            @datos << {
                documento: x,
                abonos:    _abonos,
                ejecutivo: us_ejecutivos.select{|u| u.id == ejecutivos.select{|e| e.id == x.ejecutivo_matriculas_id}.first.usuario_id}.first,
                datos_personales: dp
            }
        end

    end

    def lista_pagos_anulados
        if params[:pagos][:fecha_inicio2].blank?
            flash[:error] = "Debe seleccionar una fecha de inicio"
            redirect_to cobranzas_tesoreria_informe_path
        else
            @f_i = params[:pagos][:fecha_inicio2]
            @f_t = params[:pagos][:fecha_termino2]

            if @f_t.blank? #solo el mismo día
                f_i     = Time.parse(@f_i)
                f_t     = Time.parse(@f_i+' 23:59:59')
            else #es un rango de fechas
                f_i     = Time.parse(@f_i)
                f_t     = Time.parse(@f_t+' 23:59:59')
            end
        end

        @institucion_sede = InstitucionSede.get params[:institucion_sede_id]

        documentos_venta = DocumentoVenta.all( :estado               => DocumentoVenta::ANULADA,
                                               :fecha_anulacion.gte  => f_i, 
                                               :fecha_anulacion.lte  => f_t, 
                                               :institucion_sede_id  => params[:institucion_sede_id],
                                               :order                => [:numero.asc])

        ejecutivos    = documentos_venta.ejecutivo_matriculas
        us_ejecutivos = ejecutivos.datos_personales
        


        @tipos_abonos = TipoAbono.all(fields: [:id, :nombre])

        abonos           = Abono.all( :documento_venta_id => documentos_venta.map(&:id) )
        al_pl_es         = abonos.alumno_plan_estudio
        alumnos          = al_pl_es.alumnos
        datos_personales = alumnos.datos_personales
        ins_sed_plan     = al_pl_es.institucion_sede_plan
        planes_estudio   = ins_sed_plan.plan_estudio

        @datos = []

        documentos_venta.each do |x|

            _abonos = abonos.select{|a| a.documento_venta_id == x.id}
        
            if((_abonos.first.blank?) or (_abonos.first.alumno_plan_estudio_id.blank?))
                dp = {rut: x.rut, nombre: x.nombre_completo, carrera: x.carrera}
            else
                tmp = al_pl_es.select{|a| a.id == _abonos.first.alumno_plan_estudio_id}.first
                al  = datos_personales.select{|d| d.id == (alumnos.select{|a| a.id == tmp.alumno_id}.first).usuario_id}.first
                pl  = planes_estudio.select{|p| p.id == (ins_sed_plan.select{|i| i.id == tmp.institucion_sede_plan_id}.first).plan_estudio_id}.first

                dp = {rut: al.rut, nombre: al.nombre, carrera: pl.nombre}
            end
            @datos << {
                documento: x,
                abonos:    _abonos,
                ejecutivo: us_ejecutivos.select{|u| u.id == ejecutivos.select{|e| e.id == x.ejecutivo_matriculas_id}.first.usuario_id}.first,
                datos_personales: dp
            }
        end

    end

    def prorrogas
        p_f_i = params[:prorrogas][:fecha_inicio]
        p_f_t = params[:prorrogas][:fecha_termino]

        @f_i = p_f_i
        @f_t = p_f_t

        if p_f_t.blank? #solo el mismo día
            f_i     = Time.parse(p_f_i)
            f_t     = Time.parse(p_f_i+' 23:59:59')
        else #es un rango de fechas
            f_i     = Time.parse(p_f_i)
            f_t     = Time.parse(p_f_t+' 23:59:59')
        end

        @institucion_sede = InstitucionSede.get params[:institucion_sede_id]

        institucion_sede_planes = InstitucionSedePlan.all   fields: [:id],
                                                            :institucion_sede_id => params[:institucion_sede_id],
                                                            :plan_estudio_id => PlanEstudio::MALLAS_N_HASH[params[:malla].to_i]

        alumnos_planes_estudios = AlumnoPlanEstudio.all fields: [:id, :institucion_sede_plan_id, :alumno_id, :anio_ingreso],
                                                            :institucion_sede_plan_id => institucion_sede_planes.map(&:id)

        @prorrogas = Prorroga.all created_at: f_i..f_t,
                                    pago_comprometido: {
                                        plan_pago: {
                                            matricula_plan: {
                                                alumno_plan_estudio_id: alumnos_planes_estudios.map(&:id)
                                            }
                                        }
                                    }                             
    end

    def situaciones
        p_f_i = params[:deudas][:fecha_inicio]
        p_f_t = params[:deudas][:fecha_termino]

        if p_f_t.blank? #solo el mismo día
            f_i     = Time.parse(p_f_i)
            f_t     = Time.parse(p_f_i+' 23:59:59')
        else #es un rango de fechas
            f_i     = Time.parse(p_f_i)
            f_t     = Time.parse(p_f_t+' 23:59:59')
        end

        @situaciones = Situacion.all fecha: f_i..f_t,
                                     plan_pago: {
                                        matricula_plan: {
                                            alumno_plan_estudio: {
                                                institucion_sede_plan: {
                                                    institucion_sede_id: params[:institucion_sede_id]
                                                }
                                            }
                                        }
                                     }                             
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