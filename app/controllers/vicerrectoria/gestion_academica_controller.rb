class Vicerrectoria::GestionAcademicaController < ApplicationController

    protect_from_forgery :except => [:crear_plan_estudio,:registrar_plan_estudio, :registrar_asignatura_plan_estudio, :agregar_asignatura_plan_estudio, :control_academico_notas]

    def crear_plan_estudio
    	@plan_estudio = PlanEstudio.new
        @periodos = Periodo.all(:fields => [:id, :anio, :semestre], :estado => [Periodo::EN_CURSO, Periodo::PROXIMO])    end

    def registrar_plan_estudio
    	plan_estudio = params[:plan_estudio]
        Vicerrectoria::PlanEstudio::guardar_nuevo_plan_estudio plan_estudio

        redirect_to lista_plan_estudios_path
    end

    # params plan_estudio_id
    def lista_plan_estudios
        @plan_estudios = PlanEstudio.all(:fields => [:id, :nombre, :anio_inicio,:duracion],
                                         :estado => [PlanEstudio::VIGENTE])  
    end
    
    def agregar_asignatura_plan_estudio
        plan_estudio_id = params[:plan_estudio_id].to_i
        @plan_estudio = PlanEstudio.first(:fields => [:id, :nombre], :id => plan_estudio_id)

        @asignaturas = Asignatura.all(:fields => [:id, :nombre, :codigo,:semestre ], :plan_estudio_id => plan_estudio_id)

    end

    def registrar_asignatura_plan_estudio
        asignatura = params[:asignatura]
        Vicerrectoria::PlanEstudio::registrar_asignatura_plan_estudio asignatura
    	
        redirect_to agregar_asignatura_plan_estudio_path(asignatura[:plan_estudio_id].to_i)
    end

    # params plan_estudio_id 
    def abrir_plan_estudio_periodo
        plan_estudio_id = params[:plan_estudio_id].to_i
        plan_estudio    = PlanEstudio.first(:fields => [:id, :nombre], :id => plan_estudio_id)
        periodo_actual  = Periodo.first(:estado => Periodo::EN_CURSO)
        periodo_proximo = Periodo.first(:estado => Periodo::PROXIMO)
        
        instituciones_sede_planes_proximos = InstitucionSedePlan.all(:periodo_id => periodo_proximo.id, :plan_estudio_id => plan_estudio_id, :estado => InstitucionSedePlan::ABIERTA)
        institucion_sede_planes_actuales   = InstitucionSedePlan.all(:periodo_id => periodo_actual.id, :plan_estudio_id => plan_estudio_id, :estado => InstitucionSedePlan::ABIERTA)
        
        @actuales  = []
        @proximos  = []
        @data       = []

        @data = {
            :periodo_actual     => periodo_actual.nombre,
            :periodo_proximo    => periodo_proximo.nombre,
            :carrera            => plan_estudio.nombre
        }
    
        institucion_sede_planes_actuales.each do |c|
            @actuales << {
                :id         => c.id,
                :carrera    => c.plan_estudio.nombre, 
                :modalidad  => c.modalidad, 
                :sede       => c.institucion_sede.nombre,
                :jornada    => c.jornada
            } 
        end

        instituciones_sede_planes_proximos.each do |c|
            @proximos << {
                :id         => c.id,
                :carrera    => c.plan_estudio.nombre, 
                :modalidad  => c.modalidad, 
                :sede       => c.institucion_sede.nombre,
                :jornada    => c.jornada
            } 

        end

    end
    
    def registrar_apertura_plan_estudio

    end

    def buscar_alumno_para_validacion
        
    end

    def ver_asignaturas_convalidadas
        
    end

    def registar_asignatura_convalidada
        
    end

    def ver_asignaturas_homologadas
        
    end

    def registrar_asignatura_homologada
        
    end

    def control_academico_notas
        @institucion_sedes = InstitucionSede.all(:fields => [:id, :sede_id, :institucion_id], :institucion_id => 1, :esta_abierta => 1)
        if params.has_key?("filtro")

            seccion_id = params[:filtro][:seccion_id].to_i
            @seccion = Seccion.find_by_id(seccion_id)
            @asignatura = @seccion.asignatura_base

            @notas_planificadas = PlanificacionCalificacion.all(
                                        :fields => [:id, :ponderacion, :fecha_comprometida, :numero, :tipo],
                                        :seccion_id => @seccion.id)
            
            #if  @filtro[:periodo_id].to_i == Periodo::en_curso.id
                @alumnos = AlumnoInscritoSeccion.all(
                                                    :fields => [:id, :seccion_dictada_id, :alumno_plan_estudio_id,:estado], 
                                                    :seccion_dictada => {
                                                        :seccion_id => @seccion.id,
                                                    }, 
                                                    :alumno_plan_estudio => {
                                                            :estado => [Alumno::REGULAR, Alumno::SIN_MATRICULA, Alumno::SIN_INSCRIPCION]
                                                    },
                                                    :estado.not =>[AlumnoInscritoSeccion::CONVALIDADA, AlumnoInscritoSeccion::HOMOLOGADA]
                                                )
            #else
            #    @alumnos = AlumnoInscritoSeccion.all(
            #                                            :fields => [:id, :seccion_dictada_id, :alumno_plan_estudio_id,:estado], 
            #                                            :seccion_dictada => {
            #                                                :seccion_id => @seccion.id,
            #                                            },
            #                                            :estado.not =>[AlumnoInscritoSeccion::CONVALIDADA, AlumnoInscritoSeccion::HOMOLOGADA]
                                                        # , 
                                                        # :alumno_plan_estudio => {
                                                        #       :estado => [Alumno::REGULAR, Alumno::SIN_INSCRIPCION]
                                                        # }
            #                                        )
            #end
        end
    end

end 