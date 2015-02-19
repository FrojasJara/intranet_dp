# encoding: utf-8
class CoordinadorCarrera::GestionAcademicaController < ApplicationController
	before_filter :iniciar

	protect_from_forgery :except => [
										:emitir_expediente,
										:consultar_expediente
									]

	def emitir_expediente
		unless params[:busqueda].blank?
			@usuario = Usuario.first rut: params[:busqueda]
			raise Excepciones::DatosNoExistentesError, "El Rut ingresado no existe" if @usuario.blank?
			raise Excepciones::DatosNoExistentesError, "El Rut ingresado no tiene un alumno asociado" if @usuario.alumno.blank?
			@alumno = @usuario.alumno 
			@alumno_plan_estudios = AlumnoPlanEstudio.all(
                                                        :fields => [:id, :alumno_id, :estado, :institucion_sede_plan_id ],
                                                        :estado => [Alumno::REGULAR, Alumno::SIN_INSCRIPCION],
                                                        :alumno_id => @alumno.id
                                                        )
			raise Excepciones::DatosNoExistentesError, "El alumno no cuenta con un plan de estudio vigente o valido en la institucion" if @alumno_plan_estudios.blank?
		end
		unless params[:alumno_plan_estudio_id].blank?
			@usuario = Usuario.get params[:usuario]
			alumno = @usuario.alumno
            @alumno_plan_estudio_seleccionado = AlumnoPlanEstudio.first id: params[:alumno_plan_estudio_id].to_i
            links_secciones_inscritas = AlumnoInscritoSeccion.all(
                        :fields => [:id, :alumno_plan_estudio_id, :seccion_dictada_id],
                        :alumno_plan_estudio_id => @alumno_plan_estudio_seleccionado.id,
                        :estado => [AlumnoInscritoSeccion::INSCRITA, AlumnoInscritoSeccion::APROBADA]
                )
       		links_secciones_inscritas.each do |item|                  
                if item.asignatura.tipo == Asignatura::TERMINAL
                	@inscripcion = item
                end
            end
            raise Excepciones::DatosNoExistentesError, "El alumno no ha inscrito ninguna asignatura terminal " if @inscripcion.blank?
        	raise Excepciones::DatosNoExistentesError, "no se puede ingresar mas de un trabajo de titulo " if not @inscripcion.trabajo_titulo.blank?
        end
        rescue Excepciones::OperacionNoPermitidaError => e
        	puts e.inspect.red
        	flash[:error] = e.message
        	redirect_to coordinador_carrera_emitir_expediente_titulacion_path
		rescue Excepciones::DatosNoExistentesError => e 
			puts e.inspect.red
			flash[:error] = e.message
			redirect_to coordinador_carrera_emitir_expediente_titulacion_path
		rescue Exception => e 
			puts e.inspect.red
			flash[:error] = "Error desconocido"
			redirect_to coordinador_carrera_emitir_expediente_titulacion_path
	end

	def registrar_trabajo_titulo
		inscripcion 				= params[:inscripcion_id].to_i
		trabajo_titulo 				= params[:trabajo_titulo]
		nombre_trabajo 				= params[:trabajo_titulo][:nombre]
		nota_docente_guia 			= params[:docente_trabajo_titulo][:nota_guia].to_f
		nota_docente_informante 	= params[:docente_trabajo_titulo][:nota_informante].to_f
		comision_examinadora 		= params[:comision_examinadora]
		rut_informante 				= params[:docente_trabajo_titulo][:docente_informante].split('| ')
        profesor_informante 		= Docente.first(:datos_personales => {:rut => rut_informante[1]})
        rut_guia 					= params[:docente_trabajo_titulo][:docente_guia].split('| ')
        profesor_guia 				= Docente.first(:datos_personales => {:rut => rut_guia[1]})

		CoordinadorCarrera::TrabajoTitulo::ingresar_trabajo_titulo inscripcion,trabajo_titulo,nombre_trabajo, nota_docente_guia, nota_docente_informante, comision_examinadora, profesor_informante, profesor_guia

		redirect_to coordinador_carrera_emitir_expediente_titulacion_path
		flash[:notice] = "El trabajo de titulo se ingreso existosamene "
    	rescue Excepciones::DatosNoExistentesError => e
        	flash[:info] = e.message
        	redirect_to coordinador_carrera_emitir_expediente_titulacion_path
		rescue Exception => e 
			puts e.inspect.red
			puts log_error e
			flash[:error] = "Error de Emisión"
			redirect_to coordinador_carrera_emitir_expediente_titulacion_path

	end

	def consultar_expediente
		unless params[:busqueda].blank?
			@usuario = Usuario.first rut: params[:busqueda]
			raise Excepciones::DatosNoExistentesError, "El Rut ingresado no existe" if @usuario.blank?
			raise Excepciones::DatosNoExistentesError, "El Rut ingresado no tiene un alumno asociado" if @usuario.alumno.blank?
			@alumno = @usuario.alumno 
			@alumno_plan_estudios = AlumnoPlanEstudio.all(
                                                        :fields => [:id, :alumno_id, :estado, :institucion_sede_plan_id ],
                                                        :estado => [Alumno::REGULAR, Alumno::SIN_INSCRIPCION,Alumno::TITULADO],
                                                        :alumno_id => @alumno.id
                                                        )
			raise Excepciones::DatosNoExistentesError, "El alumno no cuenta con un plan de estudio vigente o valido en la institucion" if @alumno_plan_estudios.blank?
		end
		unless params[:alumno_plan_estudio_id].blank?
			@vicerrector = Usuario.first rol_id: 10
			@alumno_plan_estudio = AlumnoPlanEstudio.first id: params[:alumno_plan_estudio_id]
			@usuario = @alumno_plan_estudio.alumno.datos_personales
			@vicerrector = Usuario.first rol_id: 10, sede_id: @usuario.sede.id
			@pagos_tmp = PagoComprometido.all(
                    plan_pago: { 
                        matricula_plan: { alumno_plan_estudio: { id: @alumno_plan_estudio.id} }
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

            raise Excepciones::DatosNoExistentesError, "El alumno tiene cuotas atrasadas, enviar a Departamento de Matrículas para solucionar el problema" if not @pagos.blank?
			links_secciones_inscritas = AlumnoInscritoSeccion.all(
                        :fields => [:id, :alumno_plan_estudio_id, :seccion_dictada_id],
                        :alumno_plan_estudio_id => @alumno_plan_estudio.id,
                        :estado => AlumnoInscritoSeccion::APROBADA
                )
            @inscripcion = nil
       		links_secciones_inscritas.each do |item|                  
                if item.asignatura.tipo == Asignatura::TERMINAL
                	@inscripcion = item
                    if item.asignatura.semestre > 7
                        @intermedio = false
                    else
                        @intermedio = true
                    end
                end
            end

            raise Excepciones::DatosNoExistentesError, "Aun no cuenta con un trabajo de titulo aprobado " if @inscripcion.blank?
			
            @trabajo_titulo = TrabajoTitulo.first alumno_inscrito_seccion_id: @inscripcion.id
            raise Excepciones::DatosNoExistentesError, "Aun no cuenta con un trabajo de titulo ingresado " if @trabajo_titulo.blank?
            @comisiones = DocenteExaminador.all(
												examen_titulo: { 
													trabajo_titulo:{ id: @trabajo_titulo.id
																	}
																}
												)
			@docentes = DocenteTrabajoTitulo.all(
												trabajo_titulo:{ 
																id: @trabajo_titulo.id
															}
												)


            @vicerrector = Usuario.first rol_id: 10
            @data = []

            # "AlumnoInscritoSeccion"
            inscripciones = AlumnoInscritoSeccion.all(
                    :fields => [:id, :estado, :nota_final, :seccion_dictada_id, :alumno_plan_estudio_id],
                    :alumno_plan_estudio_id => @alumno_plan_estudio.id,
                    :estado => [AlumnoInscritoSeccion::APROBADA, 
                                AlumnoInscritoSeccion::HOMOLOGADA, 
                                AlumnoInscritoSeccion::CONVALIDADA
                                ]
            )
            # "SeccionDictada"
            links_secciones_cursadas = inscripciones.seccion_dictada
            # "Asignatura"
            asignaturas_cursadas = Asignatura.all(
                    :fields => [:id, :nombre, :semestre, :codigo, :plan_estudio_id],
                    :links_secciones_dictadas => links_secciones_cursadas,
                    :order => [:codigo.asc]
            )               
            # "Seccion"
            secciones_cursadas = Seccion.all(
                    :fields => [:id, :numero, :periodo_id],
                    :links_secciones_dictadas => links_secciones_cursadas
            )
            # "Periodo"
            periodos = Periodo.all :secciones => secciones_cursadas
            
            asignaturas_cursadas.each do |a|
                    item = {}
                    item[:asignatura] = a
                    item[:inscripciones] = []
                    
                    links_secciones_cursadas.select{ |lsc| a.id == lsc.asignatura_id }.each do |link_seccion|       
                            item2 = {}
                            # "AlumnoInscritoSeccion"
                            item2[:estado] = inscripciones.select{ |i| link_seccion.id == i.seccion_dictada_id }.first
                            # "Seccion"
                            seccion = secciones_cursadas.select{|s| s.id == link_seccion.seccion_id }.first
                            # "Periodo"
                            item2[:periodo] = periodos.select{|p| p.id == seccion.periodo_id}.first
                            item[:inscripciones] << item2
                    end

                    @data << item
            end
		end

		rescue Excepciones::DatosNoExistentesError => e
        	flash[:error] = e.message
        	redirect_to coordinador_carrera_consultar_expediente_titulacion_path
		rescue Exception => e 
			puts log_error e
			flash[:error] = "Error al consultar"
			redirect_to coordinador_carrera_consultar_expediente_titulacion_path

        
	end

	def avance_curricular
		@alumno_plan_estudio = AlumnoPlanEstudio.first id: params[:alumno_id]
		@usuario = @alumno_plan_estudio.alumno.datos_personales
		@vicerrector = Usuario.first rol_id: 10
        @data = []

        # "AlumnoInscritoSeccion"
        inscripciones = AlumnoInscritoSeccion.all(
                :fields                                 => [:id, :estado, :nota_final, :seccion_dictada_id, :alumno_plan_estudio_id],
                :alumno_plan_estudio_id => @alumno_plan_estudio.id,
                :estado => [AlumnoInscritoSeccion::APROBADA, 
                            AlumnoInscritoSeccion::HOMOLOGADA, 
                            AlumnoInscritoSeccion::CONVALIDADA
                            ]
        )
        inscripciones.each do |item|                  
            if item.asignatura.tipo == Asignatura::TERMINAL
                if item.asignatura.semestre > 7
                    @intermedio = false
                else
                    @intermedio = true
                end
            end
        end
        # "SeccionDictada"
        links_secciones_cursadas = inscripciones.seccion_dictada
        # "Asignatura"
        asignaturas_cursadas = Asignatura.all(
                :fields => [:id, :nombre, :semestre, :codigo, :plan_estudio_id],
                :links_secciones_dictadas => links_secciones_cursadas,
                :order => [:codigo.asc]
        )               
        # "Seccion"
        secciones_cursadas = Seccion.all(
                :fields => [:id, :numero, :periodo_id],
                :links_secciones_dictadas => links_secciones_cursadas
        )
        # "Periodo"
        periodos = Periodo.all :secciones => secciones_cursadas
        
        asignaturas_cursadas.each do |a|
                item = {}
                item[:asignatura] = a
                item[:inscripciones] = []
                
                links_secciones_cursadas.select{ |lsc| a.id == lsc.asignatura_id }.each do |link_seccion|       
                        item2 = {}
                        # "AlumnoInscritoSeccion"
                        item2[:estado] = inscripciones.select{ |i| link_seccion.id == i.seccion_dictada_id }.first
                        # "Seccion"
                        seccion = secciones_cursadas.select{|s| s.id == link_seccion.seccion_id }.first
                        # "Periodo"
                        item2[:periodo] = periodos.select{|p| p.id == seccion.periodo_id}.first
                        item[:inscripciones] << item2
                end

                @data << item
        end
	end

    def bitacora_academica
        unless params[:apl_id].blank?
            @alumno_plan_estudio_seleccionado = AlumnoPlanEstudio.first id: params[:apl_id].to_i
            @usuario = @alumno_plan_estudio_seleccionado.alumno.datos_personales
            puts "usuario #{@usuario.inspect.red}"
            @us_apoderado = Usuario.get @usuario.alumno.apoderado.datos_personales.id
            puts "apoderado #{@us_apoderado.inspect.red}"

            
            @bitacoras = BitacoraAcademica.all(
                            :alumno_plan_estudio_id => @alumno_plan_estudio_seleccionado.id,
                            :order => [:fecha.desc]
                        )
        end
        rescue Exception => e 
            puts log_error e
            flash[:error] = "Error al consultar"
        rescue Excepciones::DatosNoExistentesError => e
            flash[:error] = e.message
    end

    def registrar_bitacora_academica
        usuario  = current_user_object
        alumno_plan_estudio = params[:al_pl_es].to_i
        BitacoraAcademica.transaction do
            begin
                b = BitacoraAcademica.new params[:bitacora_academica]
                b.usuario_id                = usuario.id
                b.periodo_id                = Periodo::en_curso.id
                b.alumno_plan_estudio_id    = alumno_plan_estudio

                b.save

                flash[:notice] = "Acción guardada con Exito"
            rescue
                flash[:error] = "Ocurrió un error al intentar guardar la bitácora Academica"# << b.errors.inspect
            end

        end
        redirect_to coordinador_carrera_bitacora_academica_path(alumno_plan_estudio)
        rescue Exception => e 
            puts log_error e
            flash[:error] = "Error al consultar"
    end

    def emitir_acta_final
        trabajo_titulo_id       = params[:trabajo_titulo_id].to_i
        @trabajo_titulo         = TrabajoTitulo.find_by_id(trabajo_titulo_id)
        @carrera                = @trabajo_titulo.alumno_inscrito_seccion.alumno_plan_estudio.plan_estudio
        @alumno                 = @trabajo_titulo.alumno_inscrito_seccion.alumno.datos_personales
        @docente_guia           = @trabajo_titulo.docentes_trabajos_titulos
        alumno_plan_estudio_id  = @trabajo_titulo.alumno_inscrito_seccion.alumno_plan_estudio.id
        asignatura              = @trabajo_titulo.alumno_inscrito_seccion.seccion_dictada.asignatura
        if asignatura.semestre > 7
            @intermedio = false
        else
            @intermedio = true
        end
        
        unless alumno_plan_estudio_id.blank?
        @comisiones = DocenteExaminador.all(
                                            examen_titulo: { 
                                                trabajo_titulo:{ id: @trabajo_titulo.id
                                                                }
                                                            }
                                            )
        @docentes = DocenteTrabajoTitulo.all(
                                                trabajo_titulo:{ 
                                                                id: @trabajo_titulo.id
                                                            }
                                                )
        
            @vicerrector = Usuario.first rol_id: 10
            @alumno_plan_estudio = AlumnoPlanEstudio.first id: alumno_plan_estudio_id
            @usuario = @alumno_plan_estudio.alumno.datos_personales
            @vicerrector = Usuario.first rol_id: 10, sede_id: @usuario.sede.id
        end
    end

    def emitir_acta_examen
        trabajo_titulo_id = params[:trabajo_titulo_id].to_i
        @trabajo_titulo = TrabajoTitulo.find_by_id(trabajo_titulo_id)
        @carrera = @trabajo_titulo.alumno_inscrito_seccion.alumno_plan_estudio.plan_estudio
        @alumno = @trabajo_titulo.alumno_inscrito_seccion.alumno.datos_personales
        @docente_guia = @trabajo_titulo.docentes_trabajos_titulos
        @examen_titulo = @trabajo_titulo.examen_titulo

        alumno_plan_estudio_id = @trabajo_titulo.alumno_inscrito_seccion.alumno_plan_estudio.id
        asignatura              = @trabajo_titulo.alumno_inscrito_seccion.seccion_dictada.asignatura
        if asignatura.semestre > 7
            @intermedio = false
        else
            @intermedio = true
        end
        unless alumno_plan_estudio_id.blank?
        @comisiones = DocenteExaminador.all(
                                            examen_titulo: { 
                                                trabajo_titulo:{ id: @trabajo_titulo.id
                                                                }
                                                            }
                                            )
        @docentes = DocenteTrabajoTitulo.all(
                                                trabajo_titulo:{ 
                                                                id: @trabajo_titulo.id
                                                            }
                                                )
            @vicerrector = Usuario.first rol_id: 10
            @alumno_plan_estudio = AlumnoPlanEstudio.first id: alumno_plan_estudio_id
            @usuario = @alumno_plan_estudio.alumno.datos_personales
            @vicerrector = Usuario.first rol_id: 10, sede_id: @usuario.sede.id
        end

    end

    def emitir_expediente_practica
        
    end


end