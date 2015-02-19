# encoding: utf-8
class Matriculas::CotizacionesController < ApplicationController
        before_filter :store_location, :only => :index
        before_filter :iniciar

    def index
        @instituciones = Institucion.all fields: [:id, :nombre]

        periodos = Periodo.all fields: [:id, :anio, :semestre]

        @periodos = periodos.to_a.sort!{|a,b| a.nombre <=> b.nombre}
        @periodos = @periodos.reverse

    end

    def listado

        @institucion_id  = params[:institucion]
        periodo_id       = params[:periodo]
        @carrera_nombre  = params[:carrera]
        @modalidad       = params[:modalidad]
        @sede_id         = @usuario.sede_id
        @tipo            = params[:tipo]

        @periodo = Periodo.first id: periodo_id,
                                 fields: [:id,:semestre,:anio]

        @items = Cotizacion.all tipo: @tipo.to_i,
                                institucion_sede_plan: {
                                    plan_estudio: {
                                        nombre: @carrera_nombre.to_s
                                    },
                                    modalidad: @modalidad.to_i,
                                    institucion_sede: {
                                        institucion_id: @institucion_id.to_i,
                                        sede_id: @sede_id.to_i
                                    },
                                    periodo_id: periodo_id
                                }
            
    end

    def tipo_cotizaciones
        
    end

    def new
        @tipo = params[:tipo]

        @regiones = Region.all
        @periodo_matriculable = periodo_proximo
        @periodo_en_curso     = periodo_en_curso
        
        @planes_matriculables = InstitucionSedePlan.planes_alumno_nuevo @periodo_matriculable[:id], current_user[:sede_id]
        @planes_en_curso      = InstitucionSedePlan.planes_alumno_nuevo @periodo_en_curso[:id], current_user[:sede_id]
    end

    def create
        datos = params[:cotizacion]
        institucion_sede_planes_id = params[:isp]

        datos[:ejecutivo_matriculas_id] = current_user_object.ejecutivo_matriculas.id
        datos[:medio] = nil if datos[:medio].blank?

        cotizaciones = []

        institucion_sede_planes_id.each do |isp|
            datos[:institucion_sede_plan_id] = isp
            cotizacion = Cotizacion.create datos
            cotizaciones << cotizacion
        end

        if cotizaciones.length > 1
            redirect_to show_matriculas_cotizaciones_fecha_path cotizaciones.first.created_at,datos[:nombre],datos[:apellido]
        else
            redirect_to show_matriculas_cotizaciones_path cotizaciones.first.id
        end

        rescue DataMapper::SaveFailureError => e
                flash[:error] = e.message + " " +  e.resource.errors.inspect
                redirect_to new_matriculas_cotizacion_path(tipo: datos[:tipo])
            log_error e
        rescue Exception => e
                flash[:error] = e.message
                redirect_to new_matriculas_cotizacion_path(tipo: datos[:tipo])
            log_error e
    end

    def show
        @item = Cotizacion.get params[:id]
    end

    def show_fecha
        fecha = params[:fecha].to_s[0..9]

        @items = Cotizacion.all :created_at.gte => fecha,
                                :created_at.lte => fecha+" 23:59:59",
                                nombre: params[:nombre],
                                apellido: params[:apellido]

    end

    def informes
        @instituciones = Institucion.all fields: [:id, :nombre]

        periodos = Periodo.all fields: [:id, :anio, :semestre]
        @periodos = periodos.to_a.sort!{|a,b| a.nombre <=> b.nombre}.reverse
    end

    def informe_global

        @institucion_id  = params[:institucion1]
        periodo_id       = params[:periodo1]
        @modalidad       = params[:modalidad1]
        @sede_id         = @usuario.sede_id
        @tipo            = params[:tipo1]
        @fechaIni        = params[:fecha_inicio]
        @fechaFin        = params[:fecha_termino]

        if @fechaFin.blank? #solo el mismo día
            f_i     = Time.parse(@fechaIni)
            f_t     = Time.parse(@fechaIni+' 23:59:59')
        else #es un rango de fechas
            f_i     = Time.parse(@fechaIni)
            f_t     = Time.parse(@fechaFin+' 23:59:59')
        end

        @periodo = Periodo.first id: periodo_id,
                                 fields: [:id,:semestre,:anio]

        @items = Cotizacion.all tipo: @tipo.to_i,
                                created_at: f_i..f_t,
                                institucion_sede_plan: {
                                    modalidad: @modalidad.to_i,
                                    institucion_sede: {
                                        institucion_id: @institucion_id.to_i,
                                        sede_id: @sede_id.to_i
                                    },
                                    periodo_id: periodo_id
                                }
    end

    def informe_global_carrera

        @institucion_id  = params[:institucion3]
        periodo_id       = params[:periodo3]
        @modalidad       = params[:modalidad3]
        @sede_id         = @usuario.sede_id
        @tipo            = params[:tipo3]
        @fechaIni        = params[:fecha_inicio2]
        @fechaFin        = params[:fecha_termino2]

        if @fechaFin.blank? #solo el mismo día
            f_i     = Time.parse(@fechaIni)
            f_t     = Time.parse(@fechaIni+' 23:59:59')
        else #es un rango de fechas
            f_i     = Time.parse(@fechaIni)
            f_t     = Time.parse(@fechaFin+' 23:59:59')
        end

        @periodo = Periodo.first id: periodo_id,
                                 fields: [:id,:semestre,:anio]

        items = Cotizacion.all tipo: @tipo.to_i,
                                created_at: f_i..f_t,
                                institucion_sede_plan: {
                                    modalidad: @modalidad.to_i,
                                    institucion_sede: {
                                        institucion_id: @institucion_id.to_i,
                                        sede_id: @sede_id.to_i
                                    },
                                    periodo_id: periodo_id
                                }

        @carreras      = []
        @ejecutivos    = []
        flag_carrera   = 0
        flag_ejecutivo = 0

        items.each_with_index do |item,index|  
            flag_carrera   = 0
            flag_ejecutivo = 0
            
            if index == 0
                carrera   = item.institucion_sede_plan.plan_estudio
                ejecutivo = item.ejecutivo_matriculas
                
                @carreras   << carrera 
                @ejecutivos << ejecutivo 
            else
                @carreras.each do |c| 
                    if item.institucion_sede_plan.plan_estudio_id == c.id
                        flag_carrera = 1
                    end
                end

                if flag_carrera == 0
                    carrera = item.institucion_sede_plan.plan_estudio
                    @carreras << carrera 
                end

                @ejecutivos.each do |c| 
                    if item.ejecutivo_matriculas_id == c.id
                        flag_ejecutivo = 1
                    end
                end

                if flag_ejecutivo == 0
                    ejecutivo = item.ejecutivo_matriculas
                    @ejecutivos << ejecutivo 
                end

            end
        end

        @datos = []

        @carreras.each do |carrera|
            item = {}

            item[:carrera] = carrera.nombre_completo
            item[:ejecutivos] = []
            item[:total] = 0

            @ejecutivos.each_with_index do |ejecutivo,index|
                item[:ejecutivos][index] = items.select{|x| x.institucion_sede_plan.plan_estudio_id == carrera.id && x.ejecutivo_matriculas_id == ejecutivo.id}.count
                item[:total] += item[:ejecutivos][index]
            end

            @datos << item
        end

        puts @datos.inspect.red
    end

    def informe_matriculados

        @institucion_id  = params[:institucion2]
        periodo_id       = params[:periodo2]
        @modalidad       = params[:modalidad2]
        @sede_id         = @usuario.sede_id
        @tipo            = params[:tipo2]

        @periodo = Periodo.first id: periodo_id,
                                 fields: [:id,:semestre,:anio]

        rut_cotizaciones = Cotizacion.all(fields: [:rut],
                                          tipo: @tipo.to_i,
                                          institucion_sede_plan: {
                                            periodo_id: periodo_id
                                          }).map(&:rut).uniq
        
        @periodo          = Periodo.get periodo_id
        @institucion_sede = InstitucionSede.first institucion_id: @institucion_id,
                                                  sede_id: @sede_id
        except_alumno     = ""

        institucion_sede_planes = InstitucionSedePlan.all   fields: [:id],
                                                            modalidad: @modalidad.to_i,
                                                            :institucion_sede_id => @institucion_sede[:id],
                                                            alumno_plan_estudio: {
                                                                matricula_plan: {
                                                                    periodo_id: periodo_id
                                                                }
                                                            }

        alumnos_planes_estudios    = AlumnoPlanEstudio.all fields: [:id, :institucion_sede_plan_id, :alumno_id, :anio_ingreso],
                                                           :institucion_sede_plan_id => institucion_sede_planes.map(&:id),
                                                           alumno: {
                                                                datos_personales: {
                                                                    rut: rut_cotizaciones
                                                                }
                                                           },
                                                           matricula_plan: {
                                                                periodo_id: periodo_id
                                                           }
                                                            
        al_pl_es = { 
                    fields: [:id, :alumno_plan_estudio_id, :created_at],
                    :alumno_plan_estudio_id => alumnos_planes_estudios.map(&:id).uniq
                   }
        
        matriculas = MatriculaPlan.all( {:periodo_id => @periodo.id,
                                        :estado.not => MatriculaPlan::ANULADA}.merge(al_pl_es) )

        alumnos_planes_estudios    = AlumnoPlanEstudio.all fields: [:id, :institucion_sede_plan_id, :alumno_id, :anio_ingreso], 
                                                           id: matriculas.map(&:alumno_plan_estudio_id).uniq,
                                                           matricula_plan: {
                                                             periodo_id: periodo_id
                                                           }

        alumnos                    = alumnos_planes_estudios.alumnos fields:[:id, :usuario_id], id: alumnos_planes_estudios.map(&:alumno_id).uniq
        usuarios                   = alumnos.datos_personales(fields: [:id, :rut, :primer_nombre, :segundo_nombre, :apellido_paterno, :apellido_materno])
        instituciones_sedes_planes = alumnos_planes_estudios.institucion_sede_plan
        planes_estudios            = instituciones_sedes_planes.plan_estudio(fields: [:id, :nombre])

        @matriculas = []

        matriculas.each do |m|

            al_pl_es = alumnos_planes_estudios.select{|x| x.id == m.alumno_plan_estudio_id}.first
            al       = alumnos.select{|x| x.id == al_pl_es.alumno_id}.first
            us       = usuarios.select{|x| x.id == al.usuario_id}.first
            
            except_alumno = us[:rut]

            in_se_pl = instituciones_sedes_planes.select{|x| x.id == al_pl_es.institucion_sede_plan_id}.first
            pl_es    = planes_estudios.select{|x| x.id == in_se_pl.plan_estudio_id}.first

            @matriculas << {
                matricula:              m,
                alumno_plan_estudio:    al_pl_es,
                alumno:                 al,
                usuario:                us,
                plan_estudio:           pl_es,
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
            redirect_to matriculas_cotizaciones_informes_path
    end

    def informe_matriculados_carrera

        @institucion_id  = params[:institucion4]
        periodo_id       = params[:periodo4]
        @modalidad       = params[:modalidad4]
        @sede_id         = @usuario.sede_id
        @tipo            = params[:tipo4]

        @periodo = Periodo.first id: periodo_id,
                                 fields: [:id,:semestre,:anio]

        rut_cotizaciones = Cotizacion.all(fields: [:rut],
                                          tipo: @tipo.to_i,
                                          institucion_sede_plan: {
                                            periodo_id: periodo_id
                                          }).map(&:rut).uniq
        
        @periodo          = Periodo.get periodo_id
        @institucion_sede = InstitucionSede.first institucion_id: @institucion_id,
                                                  sede_id: @sede_id
        except_alumno     = ""

        institucion_sede_planes = InstitucionSedePlan.all   fields: [:id],
                                                            modalidad: @modalidad.to_i,
                                                            :institucion_sede_id => @institucion_sede[:id],
                                                            alumno_plan_estudio: {
                                                                matricula_plan: {
                                                                    periodo_id: periodo_id
                                                                }
                                                            }

        alumnos_planes_estudios    = AlumnoPlanEstudio.all fields: [:id, :institucion_sede_plan_id, :alumno_id, :anio_ingreso],
                                                           :institucion_sede_plan_id => institucion_sede_planes.map(&:id),
                                                           alumno: {
                                                                datos_personales: {
                                                                    rut: rut_cotizaciones
                                                                }
                                                           },
                                                           matricula_plan: {
                                                                periodo_id: periodo_id
                                                           }
                                                            
        al_pl_es = { 
                    fields: [:id, :alumno_plan_estudio_id, :created_at],
                    :alumno_plan_estudio_id => alumnos_planes_estudios.map(&:id).uniq
                   }
        
        matriculas = MatriculaPlan.all( {:periodo_id => @periodo.id,
                                        :estado.not => MatriculaPlan::ANULADA}.merge(al_pl_es) )

        alumnos_planes_estudios    = AlumnoPlanEstudio.all fields: [:id, :institucion_sede_plan_id, :alumno_id, :anio_ingreso], 
                                                           id: matriculas.map(&:alumno_plan_estudio_id).uniq,
                                                           matricula_plan: {
                                                             periodo_id: periodo_id
                                                           }

        alumnos                    = alumnos_planes_estudios.alumnos fields:[:id, :usuario_id], id: alumnos_planes_estudios.map(&:alumno_id).uniq
        usuarios                   = alumnos.datos_personales(fields: [:id, :rut, :primer_nombre, :segundo_nombre, :apellido_paterno, :apellido_materno])
        instituciones_sedes_planes = alumnos_planes_estudios.institucion_sede_plan
        planes_estudios            = instituciones_sedes_planes.plan_estudio(fields: [:id, :nombre])

        @matriculas = []

        matriculas.each do |m|

            al_pl_es = alumnos_planes_estudios.select{|x| x.id == m.alumno_plan_estudio_id}.first
            al       = alumnos.select{|x| x.id == al_pl_es.alumno_id}.first
            us       = usuarios.select{|x| x.id == al.usuario_id}.first
            
            except_alumno = us[:rut]

            in_se_pl = instituciones_sedes_planes.select{|x| x.id == al_pl_es.institucion_sede_plan_id}.first
            pl_es    = planes_estudios.select{|x| x.id == in_se_pl.plan_estudio_id}.first

            @matriculas << {
                matricula:              m,
                alumno_plan_estudio:    al_pl_es,
                alumno:                 al,
                usuario:                us,
                plan_estudio:           pl_es,
                institucion_sede_plan:  in_se_pl
            }
        end  

        @carreras      = []
        @ejecutivos    = []
        flag_carrera   = 0
        flag_ejecutivo = 0

        @matriculas.each_with_index do |item,index|  
            flag_carrera   = 0
            flag_ejecutivo = 0
            
            if index == 0
                carrera   = item[:institucion_sede_plan].plan_estudio
                ejecutivo = item[:matricula].ejecutivo_matriculas
                
                @carreras   << carrera 
                @ejecutivos << ejecutivo 
            else
                @carreras.each do |c| 
                    if item[:institucion_sede_plan].plan_estudio_id == c.id
                        flag_carrera = 1
                    end
                end

                if flag_carrera == 0
                    carrera = item[:institucion_sede_plan].plan_estudio
                    @carreras << carrera 
                end

                @ejecutivos.each do |c| 
                    if item[:matricula].ejecutivo_matriculas_id == c.id
                        flag_ejecutivo = 1
                    end
                end

                if flag_ejecutivo == 0
                    ejecutivo = item[:matricula].ejecutivo_matriculas
                    @ejecutivos << ejecutivo 
                end

            end
        end

        @datos = []

        @carreras.each do |carrera|
            item = {}

            item[:carrera] = carrera.nombre_completo
            item[:ejecutivos] = []
            item[:total] = 0

            @ejecutivos.each_with_index do |ejecutivo,index|
                item[:ejecutivos][index] = @matriculas.select{|x| x[:institucion_sede_plan].plan_estudio_id == carrera.id && x[:matricula].ejecutivo_matriculas_id == ejecutivo.id}.count
                item[:total] += item[:ejecutivos][index]
            end

            @datos << item
        end

        rescue Exception => e
            unless except_alumno.blank?
                flash[:error] = "El alumno de rut #{except_alumno}, presenta problemas en su información, comunicarse con sistemas "
                log_error e
            else
                flash[:error] = "Ha ocurrido un error inesperado, comunicarse con sistemas "
                log_error e
            end
            redirect_to matriculas_cotizaciones_informes_path
    end

    def iniciar
        @usuario              = current_user_object
        @ejecutivo_matriculas = @usuario.ejecutivo_matriculas
    end

    def envio_mails_cotizacion
        cotizaciones = Cotizacion.all id: params[:cotizaciones]

        cotizaciones.each do |cotizacion|
            if(@usuario.sede_id.to_i == Sede::CONCEPCION)
                ActionCorreoCotizacion.MailCotizacionConcepcion(cotizacion,@usuario).deliver
            elsif (@usuario.sede_id.to_i == Sede::CHILLAN)
                ActionCorreoCotizacion.MailCotizacionChillan(cotizacion,@usuario).deliver
            elsif (@usuario.sede_id.to_i == Sede::NUNOA)
                ActionCorreoCotizacion.MailCotizacionNunoa(cotizacion,@usuario).deliver
            elsif (@usuario.sede_id.to_i == Sede::BOSQUE)
                ActionCorreoCotizacion.MailCotizacionBosque(cotizacion,@usuario).deliver
            else
                ActionCorreoCotizacion.MailCotizacionVina(cotizacion,@usuario).deliver
            end    
        end

        flash[:notice] = "Se ha realizado el envío de mail correctamente."
        redirect_to matriculas_cotizacion_path

        rescue Exception => e
            flash[:error] = "#{e}"
            puts e.message
            puts e.backtrace
            redirect_to matriculas_cotizacion_path

    
    end

end
