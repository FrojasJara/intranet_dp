# encoding: utf-8
class Alumnos::AlumnosController < ApplicationController

        helper_method [:current_url]

        before_filter :preparar_acciones_publicas1, only: [
                :obtener_informe_curricular,
                :obtener_malla_curricular,
                :obtener_asignaturas_abandonadas,
                :obtener_matriculas,
                :obtener_trabajos,
                :obtener_asignaturas_inscritas,
                :obtener_horario,
                :obtener_asignaturas_abandonables,
                :generar_inscripcion_asignaturas
        ]

        before_filter :preparar_acciones_publicas3, only: [
                :obtener_asignaturas_cursadas,
                :obtener_calificaciones,
                :obtener_asistencias
        ]

        before_filter :preparar_acciones_privadas1, only: [
                :registrar_abandono_asignaturas,
                :registrar_inscripcion_asignaturas
        ]

        # Forma pública 1: /carrera/:alumno_plan_estudio_id

        def obtener_informe_curricular
                alias current_url alumno_obtener_informe_curricular_path
                @informe_curricular = @alumno.informe_curricular @plan_consultado[:inscripcion].id

                if @informe_curricular.empty?
                        flash.now[:info] = "No se registran asignaturas cursadas o inscritas en el plan consultado"
                end
        end

        def obtener_malla_curricular
                alias current_url alumno_obtener_malla_curricular_path  
                @malla_curricular = @alumno.malla_curricular @plan_consultado[:inscripcion].id

                if es_periodo_transicion?
                        @periodos               = Periodo.all
                        @estados_inscripciones  = AlumnoInscritoSeccion::ESTADOS
                        institucion_sede_plan   = @plan_consultado[:institucion_sede_plan]
                        @jornada                = institucion_sede_plan.jornada
                        @institucion_sede_id    = institucion_sede_plan.institucion_sede_id
                end
        end

        def obtener_asignaturas_abandonadas
                alias current_url alumno_obtener_asignaturas_abandonadas_path           

                @asignaturas_abandonadas = @alumno.asignaturas_abandonadas @plan_consultado[:inscripcion].id
                @existen_datos = true

        rescue Excepciones::DatosNoExistentesError => e
                flash.now[:info] = e.message
                @existen_datos = false
        end

        def obtener_matriculas
                alias current_url alumno_obtener_matriculas_path
                
                @matriculas = @alumno.matriculas @plan_consultado[:inscripcion].id
                @existen_datos = true

        rescue Excepciones::DatosNoExistentesError => e
                flash.now[:info] = e.message
                @existen_datos = false
        end

        def obtener_trabajos            
                alias current_url alumno_obtener_trabajos_path

                @trabajos = @alumno.trabajos @plan_consultado[:inscripcion].id
                @existen_datos = true

        rescue Excepciones::DatosNoExistentesError => e
                flash.now[:info] = e.message
                @existen_datos = false
        end

        def obtener_asignaturas_inscritas
                alias current_url alumno_obtener_asignaturas_inscritas_path

                @asignaturas_inscritas = @alumno.asignaturas_inscritas @plan_consultado[:inscripcion].id
                @existen_datos = true           

        rescue Excepciones::OperacionNoPermitidaError => e
                flash.now[:error] = e.message
                @existen_datos = false

        rescue Excepciones::DatosNoExistentesError => e
                flash.now[:info] = e.message
                @existen_datos = false
        end

        def obtener_horario
                alias current_url alumno_obtener_horario_path

                @horario = @alumno.horario @plan_consultado[:inscripcion].id
                @existen_datos = true   

        rescue Excepciones::OperacionNoPermitidaError => e
                flash.now[:error] = e.message
                @existen_datos = false

        rescue Excepciones::DatosNoExistentesError => e
                flash.now[:info] = e.message
                @existen_datos = false
        end

        # Forma pública 3 /carrera/:alumno_plan_estudio_id/periodo/:periodo_id

        def obtener_asignaturas_cursadas
                alias current_url alumno_obtener_asignaturas_cursadas_path

                @asignaturas_cursadas = @alumno.asignaturas_cursadas @plan_consultado[:inscripcion].id, @periodo_seleccionado.id
                @existen_datos = true

        rescue Excepciones::DatosNoExistentesError => e
                flash.now[:info] = e.message
                @existen_datos = false
        end

        def obtener_calificaciones
                alias current_url alumno_obtener_calificaciones_path

                @calificaciones = @alumno.calificaciones @plan_consultado[:inscripcion].id, @periodo_seleccionado.id
                @existen_datos = true

        rescue Excepciones::DatosNoExistentesError => e
                flash.now[:info] = e.message
                @existen_datos = false
        end

        def obtener_asistencias
                alias current_url alumno_obtener_asistencias_path

                @asistencias = @alumno.asistencias @plan_consultado[:inscripcion].id, @periodo_seleccionado.id
                @existen_datos = true

        rescue Excepciones::DatosNoExistentesError => e
                flash.now[:info] = e.message
                @existen_datos = false
        end

        # Forma privada 1

        def obtener_asignaturas_abandonables                    
                alias current_url alumno_obtener_asignaturas_abandonables_path
                @asignaturas_abandonables = @alumno.asignaturas_abandonables @plan_consultado[:inscripcion].id
                @limite_asignaturas_abandonables = Rails.configuration.max_asignaturas_abandonadas
                @mensaje = "Recuerda que solo puedes abandonar como máximo #{@limite_asignaturas_abandonables} asignatura(s)."
                @puede_abandonar = true         
                
        rescue Excepciones::OperacionNoPermitidaError => e
                flash.now[:error] = e.message
                @puede_abandonar = false        
        end

        def registrar_abandono_asignaturas
                abandonadas = params[:abandonadas]

                raise Excepciones::EntradaIncorrectaException, Excepciones::ENTRADA_INCORRECTA if abandonadas.nil? 

                limite_asignaturas_abandonables = Rails.configuration.max_asignaturas_abandonadas
                raise Excepciones::EntradaIncorrectaException, Excepciones::VALIDACION_INCORRECTA if abandonadas.size < limite_asignaturas_abandonables
                
                alumno_plan_estudio_id  = get_tmp :alumno_plan_estudio_id
                @alumno.registrar_abandono_asignaturas abandonadas              
                flash[:notice] = "El abandono de asignaturas ha sido registrada exitósamente."
                redirect_to alumno_obtener_asignaturas_abandonadas_path @usuario.id

        rescue Excepciones::EntradaIncorrectaException => e
                flash[:error] = e.message
                redirect_to alumno_obtener_asignaturas_abandonables_path 

        rescue Excepciones::OperacionNoPermitidaException => e
                flash[:error] = e.message
                redirect_to alumno_obtener_asignaturas_abandonadas_path @usuario.id

        rescue DataMapper::SaveFailureError => e
                flash[:error] = Excepciones::ERROR_REGISTRO
                redirect_to alumno_obtener_asignaturas_abandonables_path

        rescue Exception => e
                flash[:error] = Excepciones::ERROR_DESCONOCIDO
                redirect_to alumno_obtener_asignaturas_abandonables_path
        end

        def generar_inscripcion_asignaturas
                alias current_url alumno_generar_inscripcion_asignaturas_path
                @propuesta_asignaturas, @matricula_vigente, @plan_vigente = @alumno.generar_inscripcion_asignaturas @plan_consultado[:inscripcion].id, periodo_en_curso[:id]
                @puede_inscribir                                          = true

                @pagos_tmp = PagoComprometido.all(
                    plan_pago: { 
                        matricula_plan: { alumno_plan_estudio: @matricula_vigente.alumno_plan_estudio }
                    },
                    :estado.not => [PagoComprometido::PAGADO, PagoComprometido::ANULADO], 
                    :fecha_vencimiento.lte => Date.today, 
                    :saldo.gte => 0,
                    fields: [:id]
                )

                @prorrogas = @pagos_tmp.prorrogas(:fecha.gte => Date.today)

                @pagos = []

                @pagos_tmp.each do |p|
                    prorrogas = @prorrogas.select{|x| x.pago_comprometido_id == p.id}

                    @pagos << p if prorrogas.blank?
                end

                if @pagos.count > 0
                    flash[:error]    = "El alumno tiene cuotas atrasadas, enviar a Departamento de Matrículas para solucionar el problema"
                    @puede_inscribir = false
                end

                @existen_secciones                                        = true
                @matricula_cobro_especial                                 = MatriculaPlan::MATRICULAS_AFECTAS_COBROS_ESPECIALES.include? @plan_vigente.tipo

                puts @plan_vigente.inspect.red
                if not @matricula_cobro_especial
                        @limite_asignaturas_inscribibles = @plan_consultado[:inscripcion].plan_estudio.maximo_asignaturas

                else
                        @limite_asignaturas_inscribibles = @plan_vigente.asignaturas_propuestas
                end

                @incluye_normativas = (@plan_vigente.normativas_propuestas.to_i > 0)

        rescue Excepciones::OperacionNoPermitidaError => e
                flash.now[:error] = e.message
                @puede_inscribir = false

        rescue DataMapper::ObjectNotFoundError => e
                flash.now[:error] = e.message
                @puede_inscribir = false

        rescue Excepciones::DatosNoExistentesError => e
                flash.now[:info] = e.message
                @puede_inscribir = true
                @existen_secciones = false
        end

        def registrar_inscripcion_asignaturas
                inscribibles           = params[:secciones_dictadas]
                carrera_inscrita       = params[:carrera_inscrita] 
                alumno_plan_estudio_id = params[:alumno_plan_estudio_id]


                @alumno.registrar_inscripcion_asignaturas inscribibles, carrera_inscrita
                flash[:notice] = "La inscripción de asignaturas ha sido registrada exitósamente."
                redirect_to alumno_obtener_asignaturas_inscritas_path @usuario.id, alumno_plan_estudio_id       

        rescue Excepciones::OperacionNoPermitidaError => e
                puts e.message
                puts e.backtrace
                flash[:error] = e.message
                redirect_to alumno_obtener_asignaturas_inscritas_path @usuario.id
        rescue DataMapper::SaveFailureError => e
                puts e.message
                puts e.backtrace
                puts e.resource.errors.inspect.blue.bold
                flash[:error] = Excepciones::ERROR_DESCONOCIDO
                redirect_to alumno_generar_inscripcion_asignaturas_path 
        rescue Exception => e
                puts e.message
                puts e.backtrace
                puts e.resource.errors.inspect.blue.bold
                flash[:error] = "ERROR DESCONOCIDO"
                redirect_to alumno_generar_inscripcion_asignaturas_path 
        end

        private

        def preparar_acciones_publicas1
                @usuario = Usuario.get params[:usuario_id].to_i
                @alumno = @usuario.alumno
                alumno_plan_estudio_id = (not params[:alumno_plan_estudio_id].nil?) ? params[:alumno_plan_estudio_id].to_i : nil                
                @planes_estudiados = @alumno.planes_estudiados alumno_plan_estudio_id
                @plan_consultado = @planes_estudiados[:plan_consultado]
        end

        def preparar_acciones_publicas2
                @usuario = Usuario.get params[:usuario_id].to_i
                @alumno = @usuario.alumno
                # La consulta se hace solo si corresponde
                @plan_consultado = @alumno.plan_vigente
        end

        def preparar_acciones_publicas3
                @usuario = Usuario.get params[:usuario_id].to_i
                @alumno = @usuario.alumno
                alumno_plan_estudio_id = (not params[:alumno_plan_estudio_id].nil?) ? params[:alumno_plan_estudio_id].to_i : nil                
                @planes_estudiados = @alumno.planes_estudiados alumno_plan_estudio_id
                @plan_consultado = @planes_estudiados[:plan_consultado]

                periodo_id = (not params[:periodo_id].nil?) ?  params[:periodo_id].to_i : nil
                periodos = Periodo.obtener_todos periodo_id
                @periodos = periodos[:todos]
                @periodo_seleccionado = periodos[:seleccionado]
        end

        def preparar_acciones_privadas1
                @usuario = Usuario.get params[:usuario_id].to_i
                @alumno = @usuario.alumno
        end
end