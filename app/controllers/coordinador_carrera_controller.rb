# encoding: utf-8
class CoordinadorCarreraController < ApplicationController
    
    protect_from_forgery :except  => [:ver_planificacion_evaluaciones, :promover_alumno, :registar_planificacion_evaluaciones, :pase_semestral]
    before_filter :iniciar

    def inscripcion_asignaturas
        unless params[:busqueda].blank?
            usuario = Usuario.first rut: params[:busqueda]
            raise Excepciones::DatosNoExistentesError, "El Rut ingresado no existe" if usuario.blank?
            raise Excepciones::DatosNoExistentesError, "El Rut ingresado no tiene un alumno asociado" if usuario.alumno.blank?

            redirect_to alumno_generar_inscripcion_asignaturas_path(usuario.id)
        end

        rescue Excepciones::DatosNoExistentesError => e
            flash[:error] = e.message
    end

    def guarda_nivel_alumno #se llama en la inscripción de asignaturas
        msg = {status: 'error', message: ''}
        if current_role_can? :direccion_escuela
            pp = PlanPago.get params[:plan_pago_id]
            raise Excepciones::OperacionNoPermitidaError, 'No existe el plan de pago ingresado' if pp.blank?
            pp.update :nivel => params[:nivel]
            msg['status'] = 'ok'
        else
            raise Excepciones::OperacionNoPermitidaError, 'Usted no tiene los permisos para realizar esta operación'
        end

        render json: msg, layout: nil
        rescue DataMapper::SaveFailureError => e
            render json: {status: 'error', message: 'No se pudo modificar el nivel'}, layout: nil
        rescue Excepciones::OperacionNoPermitidaError => e
            render json: {status: 'error', message: e.message}, layout: nil
    end


    def secciones
        if current_role_can?(:direccion_escuela)
            @sedes = Sede.all(id: Sede::SEDES_VIGENTES)
        else
            @sedes = Sede.all(:id => current_user[:sede_id])
        end
            
        @periodos = Periodo.all order: [:anio.desc, :semestre.asc]
        
        unless params[:sede_id].blank?
            @data           = []
            f_sede          = params[:sede_id].to_i
            f_plan_estudio  = params[:plan_estudio_id].to_i
            f_periodo       = params[:periodo_id].to_i
            secciones       = Seccion.all( :periodo_id => f_periodo,
                                            :numero.not => [    
                                                        Seccion::CONVALIDADA_HOMOLOGADA,
                                                        Seccion::HISTORIAL_ACADEMICO
                                                    ],
                                            :institucion_sede => {
                                                :sede => {
                                                    :id => f_sede 
                                                }
                                            },
                                            :links_secciones_dictadas => {
                                                :asignatura => {
                                                    :plan_estudio => {
                                                        :id => f_plan_estudio
                                                    } 
                                                }
                                            }
                                        )
            @periodo           = Periodo.get params[:periodo_id]
            secciones_dictadas = secciones.links_secciones_dictadas
            asignaturas        = secciones_dictadas.asignaturas
            planes_estudio     = asignaturas.plan_estudio

            secciones.each do |seccion|
                secciones_dictadas_para_hash = []
                las_secciones = secciones_dictadas.select{|sd| sd.seccion_id == seccion.id}
                las_secciones.each do |sd|
                    @esta = sd.asignatura_id
                    @esta2 = sd.id
                    asignatura = asignaturas.select{|x| x.id == sd.asignatura_id}.first
                    secciones_dictadas_para_hash <<     {
                                                            :asignatura   => asignatura,
                                                            :plan_estudio => planes_estudio.select{|x| x.id == asignatura.plan_estudio_id}.first
                                                        }
                end

                @data <<    {
                                :seccion_id         => seccion.id,
                                :numero             => seccion.numero,
                                :estado             => seccion.estado,
                                :cupos              => seccion.cupos,
                                :jornada            => seccion.jornada,
                                :docente            => seccion.docente,
                                :alumnos_inscritos  => seccion.alumnos_inscritos,
                                :periodo            => @periodo.nombre,
                                :secciones_dictadas => secciones_dictadas_para_hash
                            }
            end

        end
        rescue Exception => e
            flash[:error] = "#{e.message}, esta seccion da problemas..... asig #{@esta}...seccio ...#{@esta2}} " 
            redirect_to coordinador_carrera_secciones_path
    end
    def ver_planificacion_evaluaciones
        seccion_id = params[:id].to_i
        @seccion = Seccion.get(seccion_id)
        @planificacion_calificaciones = PlanificacionCalificacion.all(:seccion_id => seccion_id)
    end

    def registar_planificacion_evaluaciones

        planificacion = params[:planificacion]
        nueva_planificacion = PlanificacionCalificion.new
        nueva_planificacion.seccion_id = planificacion[:seccion_id].to_i
        #nueva_planificacion.fecha = planificacion[:fecha]
        nueva_planificacion.numero = planificacion[:numero].to_i
        nueva_planificacion.nombre = planificacion[:nombre]
        nueva_planificacion.tipo = planificacion[:tipo].to_i
        nueva_planificacion.save 

        redirect_to ver_planificacion_evaluaciones(planificacion[:seccion_id].to_i)

    end

    def secciones_ver
        @seccion = Seccion.get params[:id]

        inscripciones_planes = AlumnoPlanEstudio.all(
                :links_secciones_inscritas => {
                    :seccion_dictada => {
                        :seccion_id => @seccion.id
                    }
                }
        )
        raise Excepciones::DatosNoExistentesError, "No se encuentran alumnos inscritos" if inscripciones_planes.blank?
        institucion_sede_plan      = inscripciones_planes.first.institucion_sede_plan

        alumnos                    = inscripciones_planes.alumno
        usuarios_alumno            = alumnos.datos_personales
        planes_estudio             = @seccion.links_secciones_dictadas.asignaturas.plan_estudio

        @data = []
        inscripciones_planes.each do |item|
                alumno                = alumnos.select{ |a| a.id == item.alumno_id }.first
                usuario_alumno        = usuarios_alumno.select{ |a| a.id == alumno.usuario_id }.first
                plan_estudio          = planes_estudio.select{ |a| a.id == institucion_sede_plan.plan_estudio_id }.first


                @data << {
                        :usuario             => usuario_alumno,
                        :alumno              => alumno,
                        :alumno_plan_estudio => item,
                        :plan_estudio        => plan_estudio,
                }
        end
        rescue Excepciones::DatosNoExistentesError => e
            flash[:error] = e.message
        rescue Exception => e
            flash[:error] = "error desconocido #{e.message}"
    end

    def pase_semestral
        unless params[:busqueda].blank?
            @usuario = Usuario.first rut: params[:busqueda]
            raise Excepciones::DatosNoExistentesError, "El Rut ingresado no existe" if @usuario.blank?
            raise Excepciones::DatosNoExistentesError, "El Rut ingresado no tiene un alumno asociado" if @usuario.alumno.blank?
            @alumno = @usuario.alumno 
            @alumno_plan_estudios = AlumnoPlanEstudio.all(
                                                        :fields => [:id, :alumno_id, :estado, :institucion_sede_plan_id ],
                                                        :alumno_id => @alumno.id,
                                                        :estado => [2,5,6,7,8,9]
                                                        )
        end
        unless params[:alumno_plan_estudio_id].blank?
            @alumno_plan_estudio = AlumnoPlanEstudio.get params[:alumno_plan_estudio_id].to_i
            @malla_curricular = @alumno_plan_estudio.alumno.malla_curricular params[:alumno_plan_estudio_id].to_i

                if es_periodo_transicion?
                        @periodos               = Periodo.all
                        @estados_inscripciones  = AlumnoInscritoSeccion::ESTADOS
                        institucion_sede_plan   = @alumno_plan_estudio.institucion_sede_plan
                        @jornada                = institucion_sede_plan.jornada
                        @institucion_sede_id    = institucion_sede_plan.institucion_sede_id
                end
        end
         #----------- Para cambiar estado del alumno ---------------
        unless params[:estado_elejido].blank?
            @alumno_plan_estudio = AlumnoPlanEstudio.first id: params[:alumno].to_i
            @malla_curricular = @alumno_plan_estudio.alumno.malla_curricular params[:alumno].to_i
            estado_alumno = params[:estado_elejido].to_i
            raise Excepciones::DatosNoExistentesError, "El Alumno no fue encontrado" if @alumno_plan_estudio.blank?
            raise Excepciones::DatosNoExistentesError, "NO se pudo cambiar el estado" if @alumno_plan_estudio.blank? or estado_alumno == 0
            @alumno_plan_estudio.update(:estado => estado_alumno)
            flash[:notice] = "El Alumno fue promovido exitosamente."
            if @alumno_plan_estudio.estado == 6
                redirect_to alumno_generar_inscripcion_asignaturas_path(@alumno_plan_estudio.alumno.datos_personales.id)
            
            end
        end
        rescue Excepciones::DatosNoExistentesError => e
            flash[:error] = e.message
            redirect_to coordinador_carrera_pase_semestral_path
        rescue Exception => e
            flash[:error] = "ERROR DESCONOCIDO"
            redirect_to coordinador_carrera_pase_semestral_path

    end
    def alumno_matriculado_por_carrera
        @periodos = Periodo.all order: [:anio.desc, :semestre.desc]

        @instituciones_sedes = InstitucionSede.all(
                                                    sede: {
                                                        id: Sede::SEDES_VIGENTES
                                                    },
                                                    institucion: {tipo: Institucion::IP}
                                                )
        @carreras = PlanEstudio.all(
                                    :fields => [:id, :nombre, :siaa_id_ma], 
                                    :estado => PlanEstudio::VIGENTE,
                                    :coordinadores => {:usuario_id =>current_user[:id]},
                                    :order => :nombre.asc
                                )
        unless params[:institucion_sede_id].blank?
            periodo_consulta            = []
            @institucion_sede           = InstitucionSede.get params[:institucion_sede_id]
            @plan_estudio_seleccionado  = PlanEstudio.get params[:plan_estudio_id]
            @periodo                    = Periodo.get params[:periodo_id]
            raise Excepciones::DatosNoExistentesError, "No se ingresaron todos los parametros" if @institucion_sede.blank? or @plan_estudio_seleccionado.blank? or @periodo.blank?
            periodo_consulta            << @periodo.id

            @periodo_ant                = Periodo.get Periodo.periodo_anterior( @periodo.id )
            @periodo_anterior           = @periodo_ant.id
            periodo_consulta            << @periodo_anterior if !@periodo_anterior.blank?

            institucion_sede_planes = InstitucionSedePlan.all   fields: [:id],
                                                                :institucion_sede_id => @institucion_sede.id,
                                                                alumno_plan_estudio: {
                                                                    matricula_plan: {
                                                                            periodo_id: periodo_consulta
                                                                    }
                                                                }
                                                                

            alumnos_planes_estudios = AlumnoPlanEstudio.all fields: [:id, :institucion_sede_plan_id, :alumno_id, :anio_ingreso],
                                                               :institucion_sede_plan_id => institucion_sede_planes.map(&:id),
                                                               :institucion_sede_plan => {:plan_estudio_id => @plan_estudio_seleccionado.id},
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


            alumnos_planes_estudios    = AlumnoPlanEstudio.all fields: [:id, :institucion_sede_plan_id, :alumno_id, :anio_ingreso,:estado], 
                                                               id: matriculas.map(&:alumno_plan_estudio_id).uniq,
                                                               matricula_plan: {
                                                                 periodo_id: periodo_consulta
                                                               }

            alumnos                    = alumnos_planes_estudios.alumnos fields:[:id, :usuario_id], id: alumnos_planes_estudios.map(&:alumno_id).uniq
            usuarios                   = alumnos.datos_personales(fields: [:id, :rut, :primer_nombre, :segundo_nombre, :apellido_paterno, :apellido_materno])
            instituciones_sedes_planes = alumnos_planes_estudios.institucion_sede_plan
            planes_estudios            = instituciones_sedes_planes.plan_estudio(fields: [:id, :nombre])
            secciones_inscritas        = alumnos_planes_estudios.links_secciones_inscritas(
                                                                        fields: [:id, :alumno_plan_estudio_id], 
                                                                        :seccion_dictada => { seccion: {:periodo => @periodo } }
                                                                        )
            planes_pagos               = matriculas.planes_pagos(fields: [:id, :nivel])

            @matriculas     = []
            desertores      = 0
            retirados       = 0
            regulares       = 0 
            congelados      = 0
            s_inscripcion   = 0
            s_matricula     = 0
            egresados       = 0
            titulados       = 0
            total_alumnos   = alumnos_planes_estudios.size

            matriculas.each do |m|
                al_pl_es        = alumnos_planes_estudios.select{|x| x.id == m.alumno_plan_estudio_id}.first
                desertores      = desertores    + 1 if [Alumno::DESERTOR,Alumno::POSTERGADO].include? al_pl_es.estado
                retirados       = retirados     + 1 if Alumno::RETIRADO == al_pl_es.estado
                regulares       = regulares     + 1 if Alumno::REGULAR == al_pl_es.estado 
                congelados      = congelados    + 1 if Alumno::CONGELADO == al_pl_es.estado
                s_inscripcion   = s_inscripcion + 1 if Alumno::SIN_INSCRIPCION == al_pl_es.estado
                s_matricula     = s_matricula   + 1 if Alumno::SIN_MATRICULA == al_pl_es.estado
                egresados       = egresados     + 1 if Alumno::EGRESADO == al_pl_es.estado 
                titulados       = titulados     + 1 if Alumno::TITULADO == al_pl_es.estado 
                al              = alumnos.select{|x| x.id == al_pl_es.alumno_id}.first
                us              = usuarios.select{|x| x.id == al.usuario_id}.first
                in_se_pl        = instituciones_sedes_planes.select{|x| x.id == al_pl_es.institucion_sede_plan_id}.first
                pl_es           = planes_estudios.select{|x| x.id == in_se_pl.plan_estudio_id}.first
                sec_ins         = secciones_inscritas.select{|x| x.alumno_plan_estudio_id == al_pl_es.id}
                pl_pg           = (pp = planes_pagos.select{|x| x.matricula_plan_id == m.id}).blank? ? nil : pp.last

                @matriculas << {
                    matricula:              m,
                    alumno_plan_estudio:    al_pl_es,
                    alumno:                 al,
                    usuario:                us,
                    plan_estudio:           pl_es,
                    inscripciones:          sec_ins,
                    plan_pago:              pl_pg,
                }
            end
            @estadisticas = {
                desertores:     desertores,
                retirados:      retirados,
                regulares:      regulares,
                congelados:     congelados, 
                s_inscripcion:  s_inscripcion,
                s_matricula:    s_matricula,
                egresados:      egresados,
                titulados:      titulados,
                total:          total_alumnos       
            }
            raise Excepciones::DatosNoExistentesError, "No se encontraron alumnos en la busqueda" if @matriculas.blank?

        end
        rescue Excepciones::DatosNoExistentesError => e
            flash[:error] = e.message
            redirect_to coordinador_carrera_alumno_matriculado_por_carrera_path
        rescue Exception => e
            puts e.inspect.red 
            flash[:error] = "Error desconocido"
            redirect_to coordinador_carrera_alumno_matriculado_por_carrera_path
    end
    def promover_alumno
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