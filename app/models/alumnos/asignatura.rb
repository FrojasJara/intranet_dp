# encoding: utf-8
class Alumnos::Asignatura

        def self.informe_curricular alumno_plan_estudio_id
                data = []

                # "AlumnoInscritoSeccion"
                inscripciones = AlumnoInscritoSeccion.all(
                        :fields                                 => [:id, :estado, :nota_final, :seccion_dictada_id, :alumno_plan_estudio_id],
                        :alumno_plan_estudio_id => alumno_plan_estudio_id
                )
                # "SeccionDictada"
                links_secciones_cursadas = inscripciones.seccion_dictada
                # "Asignatura"
                asignaturas_cursadas = Asignatura.all(
                        :fields => [:id, :nombre, :semestre, :codigo, :plan_estudio_id],
                        :links_secciones_dictadas => links_secciones_cursadas
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

                        data << item
                end
                                
                return data             
        end

        def self.malla_curricular alumno_plan_estudio_id 
                plan_inscrito = AlumnoPlanEstudio.get alumno_plan_estudio_id
                plan_estudio = plan_inscrito.plan_estudio

                # "Asignatura"
                asignaturas_plan = Asignatura.all(
                        :fields => [:id, :codigo, :nombre, :semestre, :caracter, :plan_estudio_id, :tipo],
                        :plan_estudio => plan_estudio
                )
                # "AlumnoInscritoSeccion"
                links_alumnos_inscritos = AlumnoInscritoSeccion.all(
                        :fields => [:id, :estado, :nota_final, :seccion_dictada_id, :alumno_plan_estudio_id],
                        :alumno_plan_estudio => plan_inscrito
                                
                )
                # "SeccionDictada"
                link_secciones_cursadas = links_alumnos_inscritos.seccion_dictada
                # "Seccion"
                secciones = Seccion.all(
                        :fields => [:id, :periodo_id, :institucion_sede_id, :docente_id],
                        :links_secciones_dictadas => link_secciones_cursadas
                )

                # "Periodo"
                periodos = Periodo.all :secciones => secciones

                data                                    = {}
                data[:duracion_plan]    = plan_estudio.duracion
                data[:malla_curricular] = []

                asignaturas_plan.each do |asignatura|

                        item    = {}
                        item[:asignatura]                               = asignatura
                        item[:nombre_real_asignatura]   = asignatura.nombre
                        item[:inscripciones]                    = []

                        # "SeccionDictada"
                        link_secciones = link_secciones_cursadas.select { |link_seccion| asignatura.id == link_seccion.asignatura_id }
                        link_secciones.each do |link_seccion|

                                item2 = {}

                                # "AlumnoInscritoSeccion"
                                item2[:inscripcion] = links_alumnos_inscritos.select{ |link_alumno|  link_seccion.id == link_alumno.seccion_dictada_id }.first
                                # "Periodo"
                                item2[:periodo] = periodos.select do |p|
                                        seccion = secciones.select { |s| s.id == link_seccion.seccion_id }.first
                                        p.id == seccion.periodo_id
                                end.first
                                # "Nombre del electivo"
                                item[:nombre_real_asignatura] = link_seccion.electivo.nombre if item[:asignatura].es_electivo?
                                item[:inscripciones] << item2
                        end
                        item[:inscripciones] = item[:inscripciones].sort{ |a,b|  (a[:periodo].semestre + a[:periodo].anio).to_i <=> (b[:periodo].semestre + b[:periodo].anio).to_i and b[:inscripcion].estado <=> a[:inscripcion].estado }
                        data[:malla_curricular] << item
                end

                return data
        end

        def self.asignaturas_abandonadas alumno_plan_estudio_id

                data = []

                inscripciones =  AlumnoInscritoSeccion.all(
                        :fields => [:id, :alumno_plan_estudio_id, :seccion_dictada_id, :updated_at],
                        :alumno_plan_estudio_id => alumno_plan_estudio_id,
                        :estado => AlumnoInscritoSeccion::ABANDONADA 
                )

                raise Excepciones::DatosNoExistentesError, "No registra asignaturas abandonadas en el plan consultado." if inscripciones.empty?

                # "SeccionDictada"
                links_secciones_abandonadas = inscripciones.seccion_dictada
                # "Seccion"
                secciones_abandonadas = links_secciones_abandonadas.seccion :fields => [:id, :periodo_id, :numero] 
                # "Periodo"
                periodos = Periodo.all :fields => [:id, :anio, :semestre], :secciones => secciones_abandonadas

                # "Asignatura"
                asignaturas_abandonadas = links_secciones_abandonadas.asignatura :fields => [:id, :nombre, :codigo]

                links_secciones_abandonadas.each do |link_seccion|
                        # "Asignatura"
                        asignatura = asignaturas_abandonadas.select { |asignatura| asignatura.id == link_seccion.asignatura_id }.first
                        # "Seccion"
                        seccion = secciones_abandonadas.select { |seccion| seccion.id == link_seccion.seccion_id }.first
                        # "Periodo"
                        periodo = periodos.select { |periodo| periodo.id == seccion.periodo_id }.first
                        # "AlumnoInscritoSeccion"
                        inscripcion = inscripciones.select { |inscripcion| inscripcion.seccion_dictada_id == link_seccion.id }.first

                        data << {
                                :asignatura     => asignatura,
                                :seccion                => seccion,
                                :periodo                => periodo,
                                :fecha                  => inscripcion.updated_at
                        }
                end

                return data
        end

        def self.asignaturas_inscritas alumno_plan_estudio_id

                # Para tener horario, hay que tener asignaturs inscritas, o tener un plan vigente
                carrera = AlumnoPlanEstudio.get alumno_plan_estudio_id
                if not Alumno::CARRERAS_VIGENTES.include? carrera.estado
                        raise Excepciones::OperacionNoPermitidaError, "Su estado académico no le permite tener asignaturas inscritas."
                end

                data = []

                # "AlumnoInscritoSeccion"
                links_secciones_inscritas = AlumnoInscritoSeccion.all(
                        :fields => [:id, :alumno_plan_estudio_id, :seccion_dictada_id],
                        :alumno_plan_estudio_id => alumno_plan_estudio_id,
                        :estado => AlumnoInscritoSeccion::INSCRITA
                ).seccion_dictada

                # "Seccion"
                secciones_inscritas = links_secciones_inscritas.seccion :fields => [:id, :docente_id, :numero, :estado]
                # "Docente"
                docentes = secciones_inscritas.docente :fields => [:id, :usuario_id]
                # "Usuario"
                usuarios = Usuario.all(
                        :fields         => [:id, :primer_nombre, :segundo_nombre, :apellido_paterno, :apellido_materno],
                        :docente        => docentes
                )

                # "Asignatura"
                asignaturas_inscritas = links_secciones_inscritas.asignatura :fields => [:id, :nombre, :codigo]
                links_secciones_inscritas.each do |link_seccion|
                        # "Asignatura"
                        asignatura = asignaturas_inscritas.select { |asignatura| asignatura.id == link_seccion.asignatura_id }.first
                        # "Seccion"
                        seccion = secciones_inscritas.select { |seccion| seccion.id == link_seccion.seccion_id }.first
                        # "Usuario"
                        if not seccion.docente_id.nil?
                                docente = docentes.select { |docente| docente.id == seccion.docente_id }.first
                                usuario = usuarios.select { |usuario| usuario.id == docente.usuario_id }.first
                        else
                                usuario = nil
                        end

                        data << {
                                :asignatura             => asignatura,
                                :seccion                => seccion,
                                :docente                => usuario,
                        }
                end

                if data.empty?
                        raise Excepciones::DatosNoExistentesError, "No registra asignaturas inscritas para el presente período en la carrera consultada."
                end

                return data
        end

        def self.asignaturas_abandonables alumno_plan_estudio_id

                # Debe ser alumno regular
                carrera = AlumnoPlanEstudio.get alumno_plan_estudio_id
                if not carrera.estado == Alumno::REGULAR
                        raise Excepciones::OperacionNoPermitidaError, "Su estado académico no le permite abandonar asignaturas."
                end

                data = {}

                # "AlumnoInscritoSeccion"
                inscripciones = AlumnoInscritoSeccion.all(
                        :fields => [:id, :alumno_plan_estudio_id, :seccion_dictada_id],
                        :estado => AlumnoInscritoSeccion::INSCRITA,
                        :alumno_plan_estudio_id => alumno_plan_estudio_id
                )

                # "SeccionDictada"
                links_secciones_inscritas = inscripciones.seccion_dictada
                # "Seccion"
                secciones = links_secciones_inscritas.seccion :fields => [:id, :numero] 
                # "Asignatura"
                asignaturas = links_secciones_inscritas.asignatura :fields => [:id, :nombre, :codigo]

                data[:abandonables] = []
                links_secciones_inscritas.each do |link_seccion|
                        # "Asignatura"
                        asignatura = asignaturas.select { |asignatura| asignatura.id == link_seccion.asignatura_id }.first
                        # "Seccion"
                        seccion = secciones.select { |seccion| seccion.id == link_seccion.seccion_id }.first
                        # "AlumnoInscritoSeccion"
                        inscripcion = inscripciones.select { |inscripcion| inscripcion.seccion_dictada_id == link_seccion.id }.first

                        data[:abandonables] << {
                                :asignatura     => asignatura,
                                :seccion                => seccion,
                                :inscripcion    => inscripcion
                        }
                end
                data[:alumno_plan_estudio_id] = alumno_plan_estudio_id

                return data
        end

        def self.asignaturas_cursadas alumno_plan_estudio_id, periodo_id
                data = []
                
                # "AlumnoInscritoSeccion"
                inscripciones = AlumnoInscritoSeccion.all(
                        :fields => [:id, :estado, :nota_final, :alumno_plan_estudio_id, :seccion_dictada_id],
                        :estado.not => AlumnoInscritoSeccion::INSCRITA,
                        :alumno_plan_estudio_id => alumno_plan_estudio_id
                )

                links_secciones_cursadas = inscripciones.seccion_dictada
                # "Seccion"
                secciones_cursadas = links_secciones_cursadas.seccion :fields => [:id, :numero], :periodo_id => periodo_id

                raise Excepciones::DatosNoExistentesError, "No registra asignaturas cursadas en el período y plan consultados." if secciones_cursadas.empty?

                # "SeccionDictada"
                links_secciones_cursadas = secciones_cursadas.links_secciones_dictadas
                # "Asignatura"
                asignaturas_cursadas = links_secciones_cursadas.asignatura :fields => [:id, :nombre, :codigo]

                links_secciones_cursadas.each do |link_seccion|
                        # "Asignatura"
                        asignatura = asignaturas_cursadas.select { |asignatura| asignatura.id == link_seccion.asignatura_id }.first
                        # "Seccion"
                        seccion = secciones_cursadas.select { |seccion| seccion.id == link_seccion.seccion_id }.first
                        # "Seccion"
                        inscripcion = inscripciones.select { |inscripcion| inscripcion.seccion_dictada_id == link_seccion.id }.first

                        data << {
                                :asignatura     => asignatura,
                                :seccion                => seccion,
                                :inscripcion    => inscripcion
                        }
                end
                return data
        end

        def self.generar_inscripcion_asignaturas alumno_plan_estudio_id, periodo_id
                # El alumno debe poder inscrbir asignaturas
                carrera = AlumnoPlanEstudio.get alumno_plan_estudio_id
                if not carrera.estado == Alumno::SIN_INSCRIPCION
                        raise Excepciones::OperacionNoPermitidaError, "Su estado académico no le permite inscribir asignaturas."
                end

                plan_estudiado        = carrera
                plan_estudio          = plan_estudiado.plan_estudio
                asignaturas_plan      = plan_estudio.asignaturas
                institucion_sede_plan = plan_estudiado.institucion_sede_plan
                institucion_sede      = institucion_sede_plan.institucion_sede
                verificar_morosidad   = Rails.configuration.verificar_morosidad_en_inscripcion_asignaturas

                data = {}
                data[:alumno_plan_estudio_id]   = plan_estudiado.id
                data[:asignaturas]                              = []

                matricula_vigente = plan_estudiado.matricula_plan.last(:estado => MatriculaPlan::VIGENTE)
                raise DataMapper::ObjectNotFoundError.new("No posee una matrícula vigente en la institución.") if matricula_vigente.nil?

                plan_pago_vigente = matricula_vigente.planes_pago.last(:estado => MatriculaPlan::VIGENTE)
                raise DataMapper::ObjectNotFoundError.new("No posee un plan de pagos vigente en la institución (1).") if plan_pago_vigente.nil?

                if plan_pago_vigente.es_semestral?
                        raise DataMapper::ObjectNotFoundError.new("No posee un plan de pagos vigente en la institución (2).") if not plan_pago_vigente.periodo_id == periodo_id
                else
                        periodo_anterior_id = Periodo.periodo_anterior periodo_id
                        #puts "periodo_anterior_id: #{periodo_anterior_id.inspect}".bold
                        #puts "plan_pago_vigente: #{plan_pago_vigente.inspect}".bold.blue
                        #puts "matricula_vigente: #{matricula_vigente.inspect}".bold.red
                        if not [periodo_id.to_i, periodo_anterior_id.to_i].include? matricula_vigente.periodo_id
                                raise DataMapper::ObjectNotFoundError.new("No posee un plan de pagos vigente en la institución (3).")    
                        end   
                end

                raise Excepciones::DatosNoExistentesError, %{
                        No posee un nivel asignado para poder inscribir asignaturas. <br /><br />
                        <a class="btn btn-info" data-toggle="modal" href="#editar_nivel">
                                <i class="icon-pencil icon-white"></i>
                                Editar nivel
                        </a><input id="plan_pago_hidden" type="hidden" name="plan_pago_id" value="#{plan_pago_vigente.id}" />
                        } if plan_pago_vigente.nivel.nil?

                # Verificacion de la morosidad solo de alumnos superiores
                if verificar_morosidad and not plan_estudiado.periodo_id == periodo_id.to_i
                        pagos_comprometidos = carrera.alumno.alumno_plan_estudio.matricula_plan(
                                                                :id.not => matricula_vigente.id
                                                        ).planes_pago.pagos_comprometidos(
                                                                fields: [:id],
                                                                :estado.not => [PagoComprometido::ANULADO, PagoComprometido::PAGADO],
                                                                :saldo.not => 0,
                                                                :fecha_vencimiento.lte => Date.today
                                                        ).length

                        raise Excepciones::OperacionNoPermitidaError, %{
                                No puede inscribir asignaturas ya que aún posee deudas de períodos anteriores. Por favor diríjase al departamento de cobranzas.
                        } if pagos_comprometidos > 0
                end

                # Verificamos si es mechon
                if plan_estudiado.semestre == 0

                        asignaturas_primer_semestre = asignaturas_plan.select {|a| a.semestre == 1 }

                        secciones_a_inscribir = Seccion.all(
                                :fields                   => [:id],
                                :institucion_sede         => institucion_sede,
                                :estado                   => Seccion::ABIERTA,
                                :jornada                  => institucion_sede_plan.jornada,
                                :links_secciones_dictadas => {
                                        :asignatura   => asignaturas_primer_semestre
                                },
                                :periodo_id               => periodo_id
                        )

                        raise Excepciones::DatosNoExistentesError, "Aún no existen secciones abiertas para poder inscribir." if secciones_a_inscribir.empty?

                        links_secciones_a_inscribir = secciones_a_inscribir.links_secciones_dictadas(:fields => [:id, :asignatura_id, :seccion_id])
                        
                        asignaturas_primer_semestre.each do |asignatura|
                                link_seccion = links_secciones_a_inscribir.select { |l| asignatura.id == l.asignatura_id }
                                next if link_seccion.nil?
                                data[:asignaturas] << {
                                        :asignatura             => asignatura,
                                        :seccion_dictada        => link_seccion,
                                        :estado                 => "vigente"
                                }
                        end
                else
                        semestres = []
                        semestre_inscribir = carrera.matricula_plan.last(:estado => MatriculaPlan::VIGENTE).planes_pago.last(:estado => PlanPago::VIGENTE).nivel
                        i = semestre_inscribir
                        step = 2
                        #validacion para alumno convalidados que tomen asignaturas de otros semestres 
                        if carrera.tipo_ingreso == 2 or carrera.tipo_ingreso == 3
                                step = 1
                        end
                        # Validacion para la gente de distancia. Pueden tomar asignaturas de semestres que no corresponden
                        step = 1 if institucion_sede_plan.modalidad == InstitucionSedePlan::DISTANCIA
                        while i > 0
                                semestres << i
                                i = i - step
                        end

                        # Asignaturas aprobadas
                        asignaturas_aprobadas = Asignatura.all(
                                :links_secciones_dictadas => {
                                        :links_alumnos_inscritos => {
                                                :estado => [AlumnoInscritoSeccion::APROBADA, AlumnoInscritoSeccion::CONVALIDADA, AlumnoInscritoSeccion::HOMOLOGADA], 
                                                :alumno_plan_estudio_id => plan_estudiado.id
                                        }
                                },
                                :plan_estudio => plan_estudio
                        )
                        
                        # Asignaturas que no han sido aprobadas/cursadas
                        asignaturas_no_aprobadas = asignaturas_plan - asignaturas_aprobadas
                        asignaturas_no_aprobadas.delete_if{ |a| a.semestre > semestre_inscribir }

                        # Asignaturas que no han sido aprobadas/cursadas que son requisitos de otras
                        asignaturas_no_aprobadas_requisitos = asignaturas_no_aprobadas.select{ |a| a.requisitos > 0 }

                        #asignaturas_reprobadas = asignaturas_reprobadas - asignaturas_aprobadas
                        asignaturas_no_aprobadas_requisitos.each { |item| asignaturas_no_aprobadas = asignaturas_no_aprobadas - item.asignaturas_dependientes }

                        asignaturas_ofrecidas = asignaturas_no_aprobadas.delete_if{ |a| not semestres.include? a.semestre }
                        secciones_a_inscribir = Seccion.all(
                                :fields                         => [:id],
                                :estado                         => Seccion::ABIERTA,
                                :institucion_sede               => institucion_sede,
                                :jornada                        => institucion_sede_plan.jornada,
                                :links_secciones_dictadas => {
                                        :asignatura             => asignaturas_no_aprobadas
                                },
                                :periodo_id                     => periodo_id
                        )

                        raise Excepciones::DatosNoExistentesError, "Aún no existen secciones abiertas para poder inscribir." if secciones_a_inscribir.empty?
                        link_secciones_a_inscribir = SeccionDictada.all :seccion => secciones_a_inscribir
                        data[:asignaturas] = asignaturas_no_aprobadas.map do |asignatura|
                                # "SeccionDictada"

                                link_seccion    = link_secciones_a_inscribir.select { |ls| asignatura.id == ls.asignatura_id }
                                # raise Excepciones::DatosNoExistentesError, "Alguna de las asignaturas que desea inscribir, no posee secciones abiertas." if link_seccion.nil?
                                next if link_seccion.nil?
                                
                                {
                                        :asignatura             => asignatura,
                                        :seccion_dictada        => link_seccion,
                                        :estado                 => (asignatura.semestre == semestre_inscribir) ? "vigente" : "atrasada"

                                }
                        end
                end

                #puts "data: #{data[:asignaturas].inspect}"
                data[:asignaturas].compact!
                return data, matricula_vigente, plan_pago_vigente
        end
end