# encoding: utf-8
class AlumnoInscritoSeccion
    include DataMapper::Resource
    include DataMapper::Timestamps
    include DataMapper::Historylog

    storage_names[:default] = 'alumnos_inscritos_secciones'

    INSCRITA                    = 1
    APROBADA                    = 2
    REPROBADA                   = 3
    CONVALIDADA                 = 4
    HOMOLOGADA                  = 5
    ABANDONADA                  = 6
    REPROBADA_POR_INASISTENCIA  = 7
    REPROBADA_NCR               = 8
    ESTADOS     = [
        :INSCRITA,
        :APROBADA, 
        :REPROBADA, 
        :CONVALIDADA, 
        :HOMOLOGADA,
        :ABANDONADA,
        :REPROBADA_POR_INASISTENCIA,
        :REPROBADA_NCR
    ]

    property    :id,                            Serial  

    property    :nota_presentacion,             Float
    property    :nota_examen,                   Float
    property    :nota_examen_repeticion,        Float
    property    :nota_final,                    Float
    property    :nota_global_recuperativa,      Float

    property    :asistio_examen,                Boolean
    property    :asistio_examen_repeticion,     Boolean
    property    :asistio_global_recuperativa,   Boolean

    property    :horas_asistidas,               Integer, :default => 0
    property    :horas_ausentadas,              Integer, :default => 0
    property    :horas_justificadas,            Integer, :default => 0

    property    :estado,                        Integer
    property    :siaa_id,                       Integer
    property    :siaa_updated_at,               DateTime
    property    :siaa_id_sede_sync,             Integer

    timestamps  :at

    belongs_to  :seccion_dictada
    belongs_to  :alumno_plan_estudio
    belongs_to  :convalidacion_homologacion, required: false

    has n, :calificaciones_parciales, "CalificacionParcial"
    has n, :asistencias
    has n, :trabajo_titulo, "TrabajoTitulo"

    def asignatura
        seccion_dictada.asignatura
    end

    def asignatura_terminal?
        seccion_dictada.asignatura.tipo == Asignatura::TIPOS ? true : false
        rescue Exception => e
            return false
    end
    
    def alumno
        alumno_plan_estudio.alumno
    end

    def anio_ingreso
        alumno_plan_estudio.anio_ingreso
    end

    def seccion
        seccion_dictada.seccion
    end

    def h_asistidas
        horas_asistidas = asistencias.map(&:horas_asistidas).reduce(:+).to_f
    end

    def h_ausentadas
        horas_ausentadas = asistencias.map(&:horas_ausentadas).reduce(:+).to_f
    end

    def h_justificadas
        horas_justificadas = asistencias.map(&:horas_justificadas).reduce(:+).to_f
    end

    def horas_totales
        horas_totales = h_asistidas + h_ausentadas + h_justificadas
    end

    def porcentaje_horas_asistidas
        (100.0 * h_asistidas.to_f / horas_totales).round
    rescue FloatDomainError => e
        0
    end

    def porcentaje_horas_ausentadas
        (100.0 * h_ausentadas.to_f / horas_totales).round
    rescue FloatDomainError => e
        0
    end

    def porcentaje_horas_justificadas
        (100.0 * h_justificadas.to_f / horas_totales).round
    rescue FloatDomainError => e
        0
    end

    def np_seccion 
        self.nota_presentacion
    end

    def rinde_examen?
        if self.seccion_dictada.asignatura.tipo == 3
            return false
        else
            if self.es_alumno_distancia?
                return nota_presentacion >= CalificacionParcial::NOTA_EXAMEN_APROXIMADA ? true : false
            else
                return ((nota_presentacion >= CalificacionParcial::NOTA_EXAMEN_APROXIMADA and nota_presentacion < CalificacionParcial::NOTA_EXIMIDO_APROXIMADA) ? true : false )
            end
        end
        rescue Exception => e
            return false
    end
    def rinde_examen_repeticion?
        if self.es_alumno_distancia?
            if not self.rinde_examen?
                return false
            else
                return ((nota_presentacion * 0.4) + (nota_examen * 0.6)  < CalificacionParcial::NOTA_MINIMA_APROXIMADA)  ? true : false
            end
        else
            return ((nota_presentacion * 0.6) + (nota_examen * 0.4))  < CalificacionParcial::NOTA_MINIMA_APROXIMADA ? true : false
        end
        
        rescue Exception => e  
            return  false
    end

    def es_alumno_distancia?
        return alumno_plan_estudio.institucion_sede_plan.modalidad == InstitucionSedePlan::DISTANCIA ? true : false
    end

    def es_cft?
        return alumno_plan_estudio.institucion_sede_plan.institucion_sede.institucion.id == Institucion::CFT ? true : false
    end
end