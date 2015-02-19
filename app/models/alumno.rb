# encoding: utf-8
class Alumno
    include DataMapper::Resource
    include DataMapper::Timestamps
    include DataMapper::Historylog
    include DataMapper::Utils

    # Tipos de ingreso
    NORMAL        = 1
    CONVALIDACION = 2
    HOMOLOGACION  = 3
    TRASLADO      = 4
    
    TIPOS_INGRESO = [
        :NORMAL,
        :CONVALIDACION,
        :HOMOLOGACION,
        :TRASLADO
    ]

    #Documentos presentados
    CERTIFICADO_NACIMIENTO = 1
    LICENCIA_E_MEDIA       = 2
    CERTIFICADO_TITULO     = 3

    DOCUMENTOS             = [
        :CERTIFICADO_NACIMIENTO, 
        :LICENCIA_E_MEDIA, 
        :CERTIFICADO_TITULO
    ]

    #Establecimiento educacional
    MUNICIPAL     = 1
    SUBVENCIONADA = 2
    PRIVADA       = 3
    CFT           = 4
    CEIA          = 5
    IP            = 6
    
    EST_EDUCACIONALES = [
        :MUNICIPAL, 
        :SUBVENCIONADA, 
        :PRIVADA, 
        :CFT, 
        :CEIA,
        :IP
    ]

    #Tipo establecimiento educacional
    CIENTÍFICO_HUMANISTA = 1
    TÉCNICO              = 2
    COMERCIAL            = 3
    
    TIPO_EST_EDUCACIONALES = [
        :CIENTÍFICO_HUMANISTA, 
        :TÉCNICO, 
        :COMERCIAL
    ]

    # Estados académicos del Alumno
    PENDIENTE            = 1
    REGULAR              = 2
    REGULAR_CON_ABANDONO = 3
    CON_PERDIDA          = 4
    SIN_MATRICULA        = 5
    SIN_INSCRIPCION      = 6
    POSTERGADO           = 7
    CONGELADO            = 8
    ANULADO              = 9
    NCR                  = 10
    EGRESADO             = 11 # 
    TITULADO             = 12 # Cuando pasa de Tecnico a IP
    EXALUMNO             = 13
    RETIRADO             = 14 # Cuando un alumno deja de estudiar y se cambia de carrera
    DESERTOR             = 15
    PROMOVIDO            = 16 # Sirve para CEIA
    REPITENCIA           = 17
    CONVALIDADO          = 18
    TRASLADADO           = 19

    ESTADOS_ACADEMICOS = [
        :PENDIENTE,
        :REGULAR,
        :REGULAR_CON_ABANDONO,
        :CON_PERDIDA,
        :SIN_MATRICULA,
        :SIN_INSCRIPCION,
        :POSTERGADO,
        :CONGELADO,
        :ANULADO,
        :NCR,
        :EGRESADO,
        :TITULADO,
        :EXALUMNO,
        :RETIRADO,
        :DESERTOR,
        :PROMOVIDO,
        :REPITENCIA,
        :CONVALIDADO,
        :TRASLADADO
    ]

    # Estados de carreras vigentes
    CARRERAS_VIGENTES = [
        REGULAR, REGULAR_CON_ABANDONO
    ]

    # Referenciados como constantes para obtener valor numerico
    ALUMNOS_SUPERIORES_MATRICULABLES = [
        #REGULAR, 
        REGULAR_CON_ABANDONO, 
        SIN_MATRICULA
        #ANULADO,

        # Solo para continuidad, desde CFT a IP carrera profesional
        #EGRESADO
    ]

    # Estados financieros del alumno
    MOROSO = 1
    AL_DIA = 2

    ESTADOS_FINANCIEROS = [
        :MOROSO,
        :AL_DIA
    ]

    NUEVO    = 1
    SUPERIOR = 2
    
    TIPOS = [
        :NUEVO,
        :SUPERIOR
    ]

    property    :id,                                Serial
    property    :anio_ingreso,                      Integer, :required => true, :min => 1950, :max => 9999

    property    :ingresos,                          Integer, :required => true, :min => 1, :default => 1
    property    :establecimiento_educacional,       Integer, :required => true
    property    :tipo_establecimiento_educacional,  Integer, :required => true
    property    :tiene_certificado_nacimiento,      Boolean, :required => true
    property    :tiene_certificado_titulo,          Boolean, :required => true
    property    :tiene_licencia_e_media,            Boolean, :required => true

    property    :siaa_id,                           Integer
    property    :siaa_updated_at,                   DateTime
    property    :siaa_id_sede_sync,                 Integer

    timestamps  :at
    property    :deleted_at,                        ParanoidDateTime

    # Acceso a los datos personales
    belongs_to      :datos_personales, "Usuario", :child_key => "usuario_id"
    belongs_to      :apoderado, required: false
    
    has n,          :alumno_plan_estudio
    has n,          :links_carreras_estudiadas, "InstitucionSedePlan", :through => :alumno_plan_estudio, :via => :institucion_sede_plan
    
    # Obtener las carreras estudiadas por el alumno
    def planes_estudiados plan_consultado_id = nil
            data = {}

            # "AlumnoPlanEstudio"
            links_carreras  = alumno_plan_estudio :fields => [:id, :alumno_id, :institucion_sede_plan_id]
            # "PlanEstudio" 
            carreras = PlanEstudio.all(
                    :fields => [:id, :nombre],
                    :institucion_sede_plan => links_carreras.institucion_sede_plan
            )

            data[:planes_estudiados] = []
            links_carreras.each do |item|
                    # "PlanEstudio"
                    carrera = carreras.select{ |carrera| carrera.id == item.institucion_sede_plan.plan_estudio_id }.first

                    data[:planes_estudiados] << {
                            :alumno_plan_estudio_id         => item.id,
                            :alumno_plan_estudio            => item,
                            :plan_estudio                   => carrera
                    }
            end

            data[:planes_estudiados] = data[:planes_estudiados].sort_by{|e| e[:created_at]}.reverse

            # Los datos del plan seleccionado
            if not plan_consultado_id.nil?
                    plan_consultado = AlumnoPlanEstudio.get plan_consultado_id
            else
                    plan_consultado = AlumnoPlanEstudio.get data[:planes_estudiados][0][:alumno_plan_estudio_id]
            end

            data[:plan_consultado] = {}
            data[:plan_consultado][:inscripcion] = plan_consultado
            data[:plan_consultado][:institucion_sede] = plan_consultado.institucion_sede
            data[:plan_consultado][:institucion_sede_plan] = plan_consultado.institucion_sede_plan

            data[:plan_consultado][:nombre] = data[:planes_estudiados].select{ |plan| plan[:alumno_plan_estudio_id] == plan_consultado.id }.first[:plan_estudio].nombre
            data[:plan_consultado][:id] = data[:planes_estudiados].select{ |plan| plan[:alumno_plan_estudio_id] == plan_consultado.id }.first[:plan_estudio].id
            return data
    end

    def horario alumno_plan_estudio_id; Alumnos::Horario.horario alumno_plan_estudio_id end

    def calificaciones alumno_plan_estudio_id, periodo_id; Alumnos::CalificacionParcial.calificaciones alumno_plan_estudio_id, periodo_id end

    def asistencias alumno_plan_estudio_id, periodo_id; Alumnos::Asistencia.asistencias alumno_plan_estudio_id, periodo_id end

    def trabajos alumno_plan_estudio_id; Alumnos::AlumnoTrabajador.trabajos alumno_plan_estudio_id end

    def matriculas alumno_plan_estudio_id; Alumnos::MatriculaPlan.matriculas alumno_plan_estudio_id end

    def asignaturas_abandonadas alumno_plan_estudio_id; Alumnos::Asignatura.asignaturas_abandonadas alumno_plan_estudio_id end

    def asignaturas_inscritas alumno_plan_estudio_id; Alumnos::Asignatura.asignaturas_inscritas alumno_plan_estudio_id end

    def asignaturas_cursadas alumno_plan_estudio_id, periodo_id; Alumnos::Asignatura.asignaturas_cursadas alumno_plan_estudio_id, periodo_id end

    def asignaturas_abandonables alumno_plan_estudio_id; Alumnos::Asignatura.asignaturas_abandonables alumno_plan_estudio_id end

    def registrar_abandono_asignaturas inscripciones

            # Verificamos que se pueda abandonar asignaturas
            carrera = plan_con_asignaturas_abandonables
            if carrera.nil?
                    raise Excepciones::OperacionNoPermitidaException, Excepciones::ALUMNO_NO_PUEDE_ABANDONAR_ASIGNATURAS
            end

            Alumno.transaction do
                    # Actualizar contador en "AlumnoPlanEstudio"
                    plan_estudiado = carrera
                    abandonadas = plan_estudiado.abandonadas + 1
                    plan_estudiado.update :abandonadas => abandonadas, :estado => Alumno::REGULAR_CON_ABANDONO

                    # Actualiza estado de inscripciones en "AlumnoInscritoSeccion"
                    inscripcion = AlumnoInscritoSeccion.get inscripciones[0]
                    inscripcion.update :estado => AlumnoInscritoSeccion::ABANDONADA

                    # Actualizar contador en "Seccion"
                    seccion = inscripcion.seccion_dictada.seccion
                    abandonados = seccion.alumnos_abandonados
                    seccion.update :alumnos_abandonados => abandonados + 1
            end     
    end
            
    def registrar_inscripcion_asignaturas links_secciones, carrera_inscrita
            # Debe poder inscribir asignaturas
            carrera = AlumnoPlanEstudio.get carrera_inscrita.delete("id")
            if not carrera.estado == Alumno::SIN_INSCRIPCION
                    raise Excepciones::OperacionNoPermitidaError, "Su estado académico no le permite inscribir asignaturas."
            end

            secciones = Seccion.all :links_secciones_dictadas => { :id => links_secciones }
            asignaturas = Asignatura.all(:fields => [:id, :semestre], :links_secciones_dictadas => { :id => links_secciones })
            Alumno.transaction do
                    # Guardar registros "AlumnoInscritoSeccion"
                    links_secciones.each do |link_seccion_id|
                        puts link_seccion_id.inspect.red
                        puts carrera.links_secciones_inscritas.inspect.red
                        carrera.links_secciones_inscritas.create(:seccion_dictada_id => link_seccion_id.to_i, :estado => AlumnoInscritoSeccion::INSCRITA)
                    end
                    # Guardar registros "Secciones"
                    secciones.each { |seccion| seccion.alumnos_inscritos += 1; seccion.save }
                    maximo_semestre = asignaturas.map{ |a| a.semestre }.max
                    carrera_inscrita["semestre"] = maximo_semestre if maximo_semestre >  carrera.semestre
                    # Se actualiza el estado de la inscripcion de la carrera (REGULAR) y su semestre
                    carrera.update carrera_inscrita
            end

            matricula_vigente = carrera.matricula_plan.last(:estado => MatriculaPlan::VIGENTE)
            plan_pago_vigente = matricula_vigente.planes_pago.last(:estado => MatriculaPlan::VIGENTE)
            nivel = plan_pago_vigente.nivel
            nuevo_nivel = nivel + 1
            plan_pago_vigente.update(:nivel => nuevo_nivel)

    end

    def generar_inscripcion_asignaturas alumno_plan_estudio_id, periodo_id; Alumnos::Asignatura.generar_inscripcion_asignaturas alumno_plan_estudio_id, periodo_id end

    def informe_curricular alumno_plan_estudio_id; Alumnos::Asignatura.informe_curricular alumno_plan_estudio_id end
    
    def malla_curricular alumno_plan_estudio_id; Alumnos::Asignatura.malla_curricular alumno_plan_estudio_id end

    def self.alumno_id_desde_usuario_id usuario_id
            a = Alumno.first fields: [:id], usuario_id: usuario_id

            a.blank? ? nil : a.id
    end
end