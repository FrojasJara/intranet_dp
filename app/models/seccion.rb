# encoding: utf-8
class Seccion
	include DataMapper::Resource
	include DataMapper::Timestamps
    include DataMapper::Historylog

	storage_names[:default] = 'secciones'

    ABIERTA     = 1
    CERRADA     = 2
    ESTADOS = [
        :ABIERTA, 
        :CERRADA
    ]
    Distancia       = nil
    DISTANCIA       = 0
    DIURNA          = 1
    VESPERTINA      = 2
    TARDE           = 3
    CONVALIDACION   = 4
    HOMOLOGACION    = 5
    JORNADAS = [
        :Distancia,
        :DISTANCIA,
        :DIURNA,
        :VESPERTINA,
        :TARDE,
        :CONVALIDACION,
        :HOMOLOGACION
    ]

    JORNADAS_PARA_FILTRO = [
        :DISTANCIA,
        :DIURNA,
        :VESPERTINA
    ]

    CONVALIDADA_HOMOLOGADA = 10 # Es el número de seccion
    HISTORIAL_ACADEMICO = 20 # es el numero cuando se arregla el historial
    NUMEROS = [
        :CONVALIDADA_HOMOLOGADA,
        :HISTORIAL_ACADEMICO
    ]

	property :id,		                    Serial
    property :estado,                       Integer
    property :cupos,                        Integer, :default => 0
    property :numero,                       Integer 
    property :jornada,                      Integer

    property :alumnos_inscritos,            Integer, :default => 0
    property :alumnos_aprobados,            Integer, :default => 0
    property :alumnos_reprobados,           Integer, :default => 0
    property :alumnos_convalidados,         Integer, :default => 0
    property :alumnos_homologados,          Integer, :default => 0
    property :alumnos_abandonados,          Integer, :default => 0

    property :clases_planificadas,          Integer, :default => 0
    property :clases_realizadas,            Integer, :default => 0
    property :clases_suspendidas,           Integer, :default => 0
    property :clases_reprogramadas,         Integer, :default => 0

    property :promedio_aprobacion,          Float
    property :promedio_reprobacion,         Float
    property :promedio_general,             Float
    property :desviacion_estandar,          Float
    property :siaa_id_ca,                   Integer
    property :siaa_id_as,                   Integer
    #property :siaa_id_se,           Integer
        # id_se = institucion_sede
    #property :siaa_sem_ai,          Integer
    #property :siaa_ano_ai,          Integer
        # sem + anio = periodo
    property :siaa_updated_at,              DateTime
    property :siaa_id_sede_sync,            Integer


    timestamps  :at

    belongs_to  :institucion_sede,      required: false
    belongs_to  :periodo
    belongs_to  :docente,               :required =>  false
    
    has n,  :links_secciones_dictadas, "SeccionDictada"
    has n,  :asignaturas, "Asignatura", :through => :links_secciones_dictadas, :via => :asignatura
    has n,  :horarios    
    has n,  :planificacion_calificaciones, "PlanificacionCalificacion"
    has n,  :clases
    
    belongs_to  :seccion_padre, "Seccion", :child_key => "fusion_id", :required => false
    has n,      :secciones_hijas, "Seccion", :child_key => "fusion_id"

    def nombre
        nombre = ""
        case self.jornada
        when Seccion::DIURNA
            nombre = "Diurna Nº #{self.numero}"
        when Seccion::VESPERTINA
            nombre = "Vespertina Nº #{self.numero}"
        when nil
            nombre = "Distancia Nº #{self.numero}"
        when Seccion::CONVALIDACION
            nombre = "Convalidacion N° #{self.numero}"
        when Seccion::HOMOLOGACION
            nombre = "HOMOLOGACION N° #{self.numero}"
        when Seccion::DISTANCIA
            nombre = "Distancia Nº #{self.numero}"
        end
        return nombre      
    end

    def preparar_libro_asistencia
        filtrar_libro_asistencia
    end    

    def registrar_asistencia clase_id, asistencias
        clase = Clase.get clase_id

        Seccion.transaction do
            # Regsitraamos las instancias de "Asistencia"
            asistencias.each { |asistencia| Asistencia.create asistencia }

            # Actualizamos la cantidad de horas en "AlumnoInscritoSeccion"
            asistencias.each_with_index do |asistencia|
                inscripcion = AlumnoInscritoSeccion.get asistencia[:alumno_inscrito_seccion_id]
                inscripcion.horas_asistidas = inscripcion.horas_asistidas + asistencia[:horas_asistidas]
                inscripcion.horas_ausentadas = inscripcion.horas_ausentadas + asistencia[:horas_ausentadas]

                inscripcion.save
            end

            # Marcamos la clase como realizada
            clase.update :estado => Clase::REALIZADA

            # Actualizamos la cantidad de clases realizadas de la seccion
            update :clases_realizadas => clases_realizadas + 1
        end

        return true
        rescue
            return false
    end

    def self.registrar_calificaciones seccion_id, planificacion_calificacion_id, parciales, recuperativas, examenes, finales
        seccion                 = Seccion.get! seccion_id
        periodo_id              = seccion.periodo_id
        es_modalidad_presencial = (not seccion.jornada.nil?)
        evaluaciones            = seccion.planificacion_calificaciones

        Seccion.transaction do

            if not planificacion_calificacion_id.blank?
                # Registramos las calificaciones parcial, si hay ...
                # Si los alumnos de distancia no envian la evaluacion, se les reprueba en ncr
                parciales.each do |_parcial| 
                    parcial = CalificacionParcial.create _parcial 
                    if not es_modalidad_presencial
                        if parcial.estado == CalificacionParcial::AUSENTADA
                            inscripcion_seccion = parcial.alumno_inscrito_seccion
                            inscripcion_carrera = inscripcion_seccion.alumno_plan_estudio

                            # Reprobamos al alumno de distancia
                            inscripcion_seccion.update :estado => AlumnoInscritoSeccion::REPROBADA_NCR, :nota_final => 1
                            reprobadas = inscripcion_carrera.reprobadas
                            inscripcion_carrera.update :reprobadas => reprobadas + 1
                        end
                    end
                end

                evaluacion = evaluaciones.get planificacion_calificacion_id            
                evaluaciones_restantes = evaluaciones.count(:estado => PlanificacionCalificacion::COMPROMETIDA)
                evaluacion.update :estado => PlanificacionCalificacion::APLICADA
            end

            # 1. Calculamos nota de presentacion, solo cuando corresponda ...
            # 2. Solo si se ha registrado la ultima evaluacion
            if evaluaciones_restantes == 1
                calificaciones_parciales = seccion.planificacion_calificaciones.calificaciones_parciales :fields => [:id, :estado, :calificacion, :alumno_inscrito_seccion_id, :planificacion_calificacion_id]
                nota_minima_aprobacion = Rails.configuration.nota_presentacion[:nota_minima_aprobacion]
                nota_minima_examen = Rails.configuration.nota_presentacion[:nota_minima_examen]

                calificaciones_parciales.alumno_inscrito_seccion(:estado => AlumnoInscritoSeccion::INSCRITA).each do |inscripcion|
                    nota_presentacion = 0.0

                    # No se calcula nota de presentacion para alguien que deba rendir la Prueba Globarl Recuperativa
                    justificada = calificaciones_parciales.select{ |c| inscripcion.id == c.alumno_inscrito_seccion_id and c.estado == CalificacionParcial::JUSTIFICADA }.first
                    next if not justificada.nil?

                    evaluaciones.each do |e|
                        calificacion = calificaciones_parciales.select{ |c| c.planificacion_calificacion_id == e.id and c.alumno_inscrito_seccion_id == inscripcion.id }.first                      
                        nota_presentacion += e.ponderacion * calificacion.calificacion
                    end

                    nuevos_valores = {}
                    nota_presentacion = nota_presentacion.round 1
                    nuevos_valores[:nota_presentacion] = nota_presentacion

                    if nota_presentacion >= nota_minima_aprobacion
                        inscripcion_carrera     = inscripcion.alumno_plan_estudio
                        es_trabajador           = inscripcion_carrera.alumno_trabajador :periodo_id => periodo_id
                        porcentaje_asistencia   = inscripcion.porcentaje_horas_asistidas

                        if not es_trabajador
                            limite_asistencia = Rails.configuration.porcentaje_asistencia_aceptada
                        else
                            limite_asistencia = Rails.configuration.porcentaje_asistencia_aceptada_trabajador
                        end

                        # Aprobado
                        if not es_modalidad_presencial or porcentaje_asistencia >= limite_asistencia
                            nuevos_valores[:estado] = AlumnoInscritoSeccion::APROBADA
                            nuevos_valores[:nota_final] = nota_presentacion
                            aprobadas = inscripcion_carrera.aprobadas
                            inscripcion_carrera.update :aprobadas => aprobadas + 1
                        
                        # Reprobado
                        else
                            nuevos_valores[:estado] = AlumnoInscritoSeccion::REPROBADA
                            nuevos_valores[:nota_final] = nota_presentacion
                            inscripcion_carrera = inscripcion.alumno_plan_estudio
                            reprobadas = inscripcion_carrera.reprobadas
                            inscripcion_carrera.update :reprobadas => reprobadas + 1                           
                        end   

                    # Reprobado
                    elsif nota_presentacion < nota_minima_examen
                        nuevos_valores[:estado] = AlumnoInscritoSeccion::REPROBADA
                        nuevos_valores[:nota_final] = nota_presentacion

                        inscripcion_carrera = inscripcion.alumno_plan_estudio
                        reprobadas = inscripcion_carrera.reprobadas
                        inscripcion_carrera.update :reprobadas => reprobadas + 1
                    end

                    inscripcion.update nuevos_valores
                end
            end

            # Registramos las pruebas globales recuperativas
            if not recuperativas.blank?
                recuperativas.each do |inscripcion|
                    _inscripcion = AlumnoInscritoSeccion.get inscripcion.delete("id")
                    calificaciones = CalificacionParcial.all :alumno_inscrito_seccion => _inscripcion
                    justificada = calificaciones.select{ |x| x.estado == CalificacionParcial::JUSTIFICADA }.first
                    calificaciones.delete justificada

                    nota_presentacion = 0.0
                    calificaciones.each do |c|
                        calificacion = c.calificacion
                        nota_presentacion += c.planificacion_calificacion.ponderacion * calificacion
                    end

                    nota_presentacion += justificada.planificacion_calificacion.ponderacion * inscripcion["nota_global_recuperativa"].to_f
                    nota_presentacion = nota_presentacion.round 1

                    nota_minima_aprobacion = Rails.configuration.nota_presentacion[:nota_minima_aprobacion]
                    nota_minima_examen = Rails.configuration.nota_presentacion[:nota_minima_examen]

                    nuevos_valores = {}
                    nuevos_valores[:nota_presentacion] = nota_presentacion

                    if nota_presentacion >= nota_minima_aprobacion
                        nuevos_valores[:estado] = AlumnoInscritoSeccion::APROBADA
                        nuevos_valores[:nota_final] = nota_presentacion

                        inscripcion_carrera = _inscripcion.alumno_plan_estudio
                        aprobadas = inscripcion_carrera.aprobadas
                        inscripcion_carrera.update :aprobadas => aprobadas + 1

                    # Reprobado
                    elsif nota_presentacion < nota_minima_examen
                        nuevos_valores[:estado] = AlumnoInscritoSeccion::REPROBADA
                        nuevos_valores[:nota_final] = nota_presentacion

                        inscripcion_carrera = _inscripcion.alumno_plan_estudio
                        reprobadas = inscripcion_carrera.reprobadas
                        inscripcion_carrera.update :reprobadas => reprobadas + 1
                    end

                    _inscripcion.update inscripcion.merge(nuevos_valores)
                end
            end


            # Registramos los examenes, si hay ...
            if not examenes.blank?
                nota_minima_aprobacion = Rails.configuration.examen[:nota_minima_aprobacion]

                if es_modalidad_presencial
                    ponderacion_examen = Rails.configuration.examen[:presencial][:ponderacion_examen]
                    ponderacion_nota_presentacion = Rails.configuration.examen[:presencial][:ponderacion_nota_presentacion]
                else
                    ponderacion_examen = Rails.configuration.examen[:distancia][:ponderacion_examen]
                    ponderacion_nota_presentacion = Rails.configuration.examen[:distancia][:ponderacion_nota_presentacion]
                end

                puts "ponderacion_examen: #{ponderacion_examen.inspect}"
                puts "ponderacion_nota_presentacion: #{ponderacion_nota_presentacion.inspect}"

                examenes.each do |item|
                    inscripcion = AlumnoInscritoSeccion.get item.delete(:alumno_inscrito_seccion_id)
                    
                    asistio = (item["asistio_examen"] == "true")

                    ponderada = (inscripcion.nota_presentacion * ponderacion_nota_presentacion + item[:nota_examen].to_f * ponderacion_examen).round(1)
                    nuevos_valores = {}
                    nuevos_valores[:nota_examen] = item[:nota_examen].to_f
                    nuevos_valores[:asistio_examen] = asistio

                    # Aprobado
                    if asistio and ponderada >= nota_minima_aprobacion
                        nuevos_valores[:nota_final] = ponderada
                        nuevos_valores[:estado] = AlumnoInscritoSeccion::APROBADA

                        inscripcion_carrera = inscripcion.alumno_plan_estudio
                        aprobadas = inscripcion_carrera.aprobadas
                        inscripcion_carrera.update :aprobadas => aprobadas + 1
                    end

                    # Si no asiste, reprueba de inmediato
                    if not asistio
                        nuevos_valores[:nota_final] = ponderada
                        nuevos_valores[:estado] = AlumnoInscritoSeccion::REPROBADA_NCR

                        inscripcion_carrera = inscripcion.alumno_plan_estudio
                        reprobadas = inscripcion_carrera.aprobadas
                        inscripcion_carrera.update :reprobadas => reprobadas + 1
                    end

                    inscripcion.update nuevos_valores
                end
            end

            # Registramos los examenes finales, si hay ...
            if not finales.blank?
                nota_minima_aprobacion = Rails.configuration.examen_repeticion[:nota_minima_aprobacion]

                finales.each do |item|
                    inscripcion = AlumnoInscritoSeccion.get item.delete(:alumno_inscrito_seccion_id)
                    
                    examen_final = item[:nota_examen_repeticion].to_f
                    nuevos_valores = {}
                    nuevos_valores[:nota_examen_repeticion] = examen_final

                    asistio = (item["asistio_examen_repeticion"] == "true")
                    nuevos_valores[:asistio_examen_repeticion] = asistio

                    if asistio
                        # Aprobado
                        if examen_final >= nota_minima_aprobacion
                            nuevos_valores[:nota_final] = nota_minima_aprobacion
                            nuevos_valores[:estado] = AlumnoInscritoSeccion::APROBADA

                            inscripcion_carrera = inscripcion.alumno_plan_estudio
                            aprobadas = inscripcion_carrera.aprobadas
                            inscripcion_carrera.update :aprobadas => aprobadas + 1

                        # Reprobado
                        else
                            nuevos_valores[:nota_final] = examen_final
                            nuevos_valores[:estado] = AlumnoInscritoSeccion::REPROBADA

                            inscripcion_carrera = inscripcion.alumno_plan_estudio
                            reprobadas = inscripcion_carrera.reprobadas
                            inscripcion_carrera.update :reprobadas => reprobadas + 1
                        end
                    else
                        nuevos_valores[:nota_final] = examen_final
                        nuevos_valores[:estado] = AlumnoInscritoSeccion::REPROBADA_NCR

                        inscripcion_carrera = inscripcion.alumno_plan_estudio
                        reprobadas = inscripcion_carrera.reprobadas
                        inscripcion_carrera.update :reprobadas => reprobadas + 1
                    end

                    inscripcion.update nuevos_valores
                end
            end
        end

        seccion
    end

    def self.cerrar_seccion seccion_id, periodo_en_curso_id
        seccion = Seccion.get! seccion_id
        
        # AlumnoInscritoSeccion
        inscripciones_seccion = seccion.links_secciones_dictadas.links_alumnos_inscritos

        # AlumnoPlanEstudio
        inscripciones_planes = inscripciones_seccion.alumno_plan_estudio

        # Periodo id anterior
        periodo_anterior_id = Periodo.periodo_anterior periodo_en_curso_id

        # MaatriculaPlan
        matriculas = inscripciones_planes.matricula_plan :estado => MatriculaPlan::VIGENTE, :periodo_id => [periodo_anterior_id, periodo_en_curso_id]

        alumnos_aprobados = inscripciones_seccion.select{ |i| i.estado == AlumnoInscritoSeccion::APROBADA }
        alumnos_reprobados = inscripciones_seccion.select{ |i| [AlumnoInscritoSeccion::REPROBADA, AlumnoInscritoSeccion::REPROBADA_POR_INASISTENCIA, AlumnoInscritoSeccion::REPROBADA_NCR].include? i.estado }
        alumnos_convalidados = inscripciones_seccion.select{ |i| i.estado == AlumnoInscritoSeccion::CONVALIDADA }.count
        alumnos_homologados = inscripciones_seccion.select{ |i| i.estado == AlumnoInscritoSeccion::HOMOLOGADA }.count
        alumnos_abandonados = inscripciones_seccion.select{ |i| i.estado == AlumnoInscritoSeccion::ABANDONADA }.count

        aprobados = alumnos_aprobados.count
        reprobados = alumnos_reprobados.count

        promedio_aprobados = (alumnos_aprobados.map{ |i| i.nota_final }.inject(:+).to_f / aprobados.to_f).round(1) if aprobados > 0
        promedio_reprobados = (alumnos_reprobados.map{ |i| i.nota_final }.inject(:+).to_f / reprobados.to_f).round(1)  if reprobados > 0
        promedio = (alumnos_aprobados.map{ |i| i.nota_final }.concat( alumnos_reprobados.map{ |i| i.nota_final } ).inject(:+) / (aprobados.to_f + reprobados.to_f)).round(1) 

        finales = []    
        # Solo si hay alumnos aprobados    
        if aprobados > 0
            finales.concat alumnos_aprobados.map{ |i| (i.nota_final - promedio)**2 }
        end
        # Solo si hay alumnos reprobados
        if reprobados > 0
            finales.concat alumnos_reprobados.map{ |i| (i.nota_final - promedio)**2 }
        end

        sumatoria = finales.inject(:+)
        desviacion = ((1.0/(aprobados + reprobados - 1) * sumatoria)**(0.5)).round(3)


        Seccion.transaction do
            # Actualizamos la seccion
            seccion.update(
                :alumnos_aprobados      => aprobados,
                :alumnos_reprobados     => reprobados,
                :alumnos_convalidados   => alumnos_convalidados,
                :alumnos_homologados    => alumnos_homologados,
                :alumnos_abandonados    => alumnos_abandonados,
                :promedio_aprobacion    => promedio_aprobados,
                :promedio_reprobacion   => promedio_reprobados,
                :promedio_general       => promedio,
                :desviacion_estandar    => desviacion,
                :estado                 => Seccion::CERRADA
            )

            # Expiramos las matriculas que correspondan
            inscripciones_planes.each do |inscripcion|
                matricula = matriculas.select{ |i| inscripcion.id == i.alumno_plan_estudio_id }.last

                # La transaccion se aborta si existen inconsistencias en la base de datos
                # El alumno debe tener una matrícula vigente
                if matricula.nil?
                    raise Excepciones::DatosInconsistentesError, "(#{inscripcion.id}) Existe un alumno dentro de la sección que presenta inconsistencias en los estados de sus matriculas, o no presenta matricula vigente alguna."
                end

                # Solo expiramos la matricula si es su segundo semestre
                matricula.update :estado => MatriculaPlan::EXPIRADA if matricula.periodo_id == periodo_anterior_id
            end
        end
        
        seccion
    end

    def estadisticas_finales tipo
    data = []
    (tipo_nota, nota_tipo = "Final", :nota_final) if tipo == 4
    (tipo_nota, nota_tipo = "Presentacion", :nota_presentacion) if tipo == 1
    (tipo_nota, nota_tipo = "Examen", :nota_examen) if tipo == 2
    (tipo_nota, nota_tipo = "Examen repeticion", :nota_examen_repeticion) if tipo == 3
        
    # AlumnoInscritoSeccion
    inscripciones = AlumnoInscritoSeccion.all( 
                                                :fields => [:id, nota_tipo],
                                                nota_tipo.not => CalificacionParcial::NO_CUMPLE_REQUISITOS,
                                                :seccion_dictada => {
                                                    :seccion_id => id
                                                    }
                                            )
    inscripciones_ncr = AlumnoInscritoSeccion.all( 
                                                :fields => [:id, nota_tipo],
                                                nota_tipo => CalificacionParcial::NO_CUMPLE_REQUISITOS,
                                                :seccion_dictada => {
                                                    :seccion_id => id
                                                    }
                                            )
    if !inscripciones.blank?
        if tipo == 4
            seccion = Seccion.get! id
            # AlumnoInscritoSeccion
            inscripciones_seccion = seccion.links_secciones_dictadas.links_alumnos_inscritos
            alumnos_aprobados = inscripciones_seccion.select{ |i| [AlumnoInscritoSeccion::APROBADA,AlumnoInscritoSeccion::CONVALIDADA,AlumnoInscritoSeccion::HOMOLOGADA].include? i.estado }
            alumnos_reprobados = inscripciones_seccion.select{ |i| [AlumnoInscritoSeccion::REPROBADA, AlumnoInscritoSeccion::REPROBADA_POR_INASISTENCIA, AlumnoInscritoSeccion::REPROBADA_NCR].include? i.estado }
            
            aprobados = alumnos_aprobados.count
            reprobados = alumnos_reprobados.count
        end
        alumnos_ncr = inscripciones_ncr.count
    # la maxima y la minima
        maxima = inscripciones.max(nota_tipo)
        minima = inscripciones.min(nota_tipo)
        #calculamos promedio y la mediana
         m_pos = inscripciones.size / 2
         mediana = inscripciones.size % 2 == 1 ? inscripciones[m_pos].nota_presentacion : inscripciones[m_pos-1].nota_presentacion if tipo == 1
         mediana = inscripciones.size % 2 == 1 ? inscripciones[m_pos].nota_examen : inscripciones[m_pos-1].nota_examen if tipo == 2
         mediana = inscripciones.size % 2 == 1 ? inscripciones[m_pos].nota_examen_repeticion : inscripciones[m_pos-1].nota_examen_repeticion if tipo == 3
         mediana = inscripciones.size % 2 == 1 ? inscripciones[m_pos].nota_final : inscripciones[m_pos-1].nota_final if tipo == 4
         promedio = inscripciones.collect(&nota_tipo).sum.to_f/inscripciones.length if inscripciones.length > 0

         #calculamos la moda / 
         f={}    
         fmax=0 
         m=nil
         f1 = 0
         f2 = 0
         f3 = 0
         f4 = 0
         f6 = 0
         f5 = 0

         inscripciones.each do |v|
            if tipo == 1
                f[v.nota_presentacion] ||= 0
                f[v.nota_presentacion] += 1
                fmax,m = f[v.nota_presentacion], v.nota_presentacion if f[v.nota_presentacion] > fmax
                
                f1 = f1+1 if v.nota_presentacion <= 2
                f2 = f2+1 if v.nota_presentacion <= 3 && v.nota_presentacion > 2
                f3 = f3+1 if v.nota_presentacion <= 4 && v.nota_presentacion > 3
                f4 = f4+1 if v.nota_presentacion <= 5 && v.nota_presentacion > 4
                f5 = f5+1 if v.nota_presentacion <= 6 && v.nota_presentacion > 5
                f6 = f6+1 if v.nota_presentacion <= 7 && v.nota_presentacion > 6
            end
            if tipo == 2
                f[v.nota_examen] ||= 0
                f[v.nota_examen] += 1
                fmax,m = f[v.nota_examen], v.nota_examen if f[v.nota_examen] > fmax
                
                f1 = f1+1 if v.nota_examen <= 2
                f2 = f2+1 if v.nota_examen <= 3 && v.nota_examen > 2
                f3 = f3+1 if v.nota_examen <= 4 && v.nota_examen > 3
                f4 = f4+1 if v.nota_examen <= 5 && v.nota_examen > 4
                f5 = f5+1 if v.nota_examen <= 6 && v.nota_examen > 5
                f6 = f6+1 if v.nota_examen <= 7 && v.nota_examen > 6
            end
            if tipo == 3
                f[v.nota_examen_repeticion] ||= 0
                f[v.nota_examen_repeticion] += 1
                fmax,m = f[v.nota_examen_repeticion], v.nota_examen_repeticion if f[v.nota_examen_repeticion] > fmax
                
                f1 = f1+1 if v.nota_examen_repeticion <= 2
                f2 = f2+1 if v.nota_examen_repeticion <= 3 && v.nota_examen_repeticion > 2
                f3 = f3+1 if v.nota_examen_repeticion <= 4 && v.nota_examen_repeticion > 3
                f4 = f4+1 if v.nota_examen_repeticion <= 5 && v.nota_examen_repeticion > 4
                f5 = f5+1 if v.nota_examen_repeticion <= 6 && v.nota_examen_repeticion > 5
                f6 = f6+1 if v.nota_examen_repeticion <= 7 && v.nota_examen_repeticion > 6
            end
            if tipo == 4
                f[v.nota_final] ||= 0
                f[v.nota_final] += 1
                fmax,m = f[v.nota_final], v.nota_final if f[v.nota_final] > fmax
                
                f1 = f1+1 if v.nota_final <= 2
                f2 = f2+1 if v.nota_final <= 3 && v.nota_final > 2
                f3 = f3+1 if v.nota_final <= 4 && v.nota_final > 3
                f4 = f4+1 if v.nota_final <= 5 && v.nota_final > 4
                f5 = f5+1 if v.nota_final <= 6 && v.nota_final > 5
                f6 = f6+1 if v.nota_final <= 7 && v.nota_final > 6
            end

         end
         data << {
                    :maxima     => maxima, 
                    :minima     => minima, 
                    :mediana    => mediana,
                    :promedio   => promedio,
                    :moda       => m,
                    :f1         => f1,
                    :f2         => f2,
                    :f3         => f3,
                    :f4         => f4,
                    :f5         => f5,
                    :f6         => f6,
                    :tipo       => tipo_nota,
                    :alumnos_ncr=> alumnos_ncr,
                    :aprobados  => aprobados,
                    :reprobados => reprobados
                }
         return data
    elsif 
        data << {
                    :maxima     => 0, 
                    :minima     => 0, 
                    :mediana    => 0,
                    :promedio   => 0,
                    :moda       => 0,
                    :f1         => 0,
                    :f2         => 0,
                    :f3         => 0,
                    :f4         => 0,
                    :f5         => 0,
                    :f6         => 0,
                    :tipo       => 0,
                    :alumnos_ncr=> 0,
                    :aprobados  => 0,
                    :reprobados => 0
                }
         return data
    end

  end

    def preparar_libro_calificaciones seccion_id; Docentes::Libros.preparar_libro_calificaciones seccion_id end

    def sigla; "S" + numero.to_s end

    def libro_calificaciones seccion_id; Docentes::Libros.libro_calificaciones seccion_id end

    def libro_asistencia seccion_id; Docentes::Libros.libro_asistencia seccion_id end

    def alumnos seccion_id; Docentes::Libros.alumnos seccion_id end

    def obtener_clases seccion_id; Docentes::Libros.clases seccion_id end

    def asignaturas_seccion; asignaturas :fields => [:id, :nombre, :codigo] end

    def puede_ser_cerrada? seccion_id; Docentes::Secciones.puede_ser_cerrada? seccion_id end


    def total_evaluaciones_planificadas
        return planificacion_calificaciones.size
    end

    def total_horas_seccion
        return clases.map(&:horas).reduce(:+) 
    end

    def asignatura_base; self.asignaturas.first; end
end