# encoding: utf-8
class Docentes::Libros

	def self.alumnos seccion_id
		seccion = Seccion.get! seccion_id
        data = []

        # "AlumnoInscritoSeccion"
        inscripciones_seccion = seccion.links_secciones_dictadas.links_alumnos_inscritos(
            :fields => [:id, :seccion_dictada_id, :alumno_plan_estudio_id, :estado, :nota_final]
        )

        raise Excepciones::DatosNoExistentesError, "La sección consultada no posee alumnos." if inscripciones_seccion.empty? 

        # "AlumnoPlanEstudio"
        inscripciones_plan = inscripciones_seccion.alumno_plan_estudio(
            :fields => [:id, :institucion_sede_plan_id, :alumno_id, :anio_ingreso, :periodo_id]
        )

        # "Alumno"
        alumnos = inscripciones_plan.alumno :fields => [:id, :usuario_id]
        # "Usuario"
        usuarios = alumnos.datos_personales :fields => [:id, :rut, :primer_nombre, :segundo_nombre, :apellido_paterno, :apellido_materno]
        # "InstitucionSedePlan"
        links_carreras = inscripciones_plan.institucion_sede_plan :fields => [:id, :plan_estudio_id, :periodo_id, :institucion_sede_id] 
        # "PlanEstudio"
        carreras = links_carreras.plan_estudio :fields => [:id, :nombre]

        usuarios.each do |usuario|
            item = {}
            # "Usuario"
            item[:datos] = usuario

            # "Alumno"
            alumno = alumnos.select{ |alumno| usuario.id == alumno.usuario_id }.first

            # "AlumnoPlanEstudio"
            inscripcion_plan = inscripciones_plan.select{ |inscripcion| alumno.id == inscripcion.alumno_id }.first
            item[:anio_ingreso] = inscripcion_plan.anio_ingreso

            # "AlumnoInscritoSeccion"
            item[:inscripcion] = inscripciones_seccion.select { |inscripcion| inscripcion_plan.id == inscripcion.alumno_plan_estudio_id }.first

            # "InstitucionSedePlan"
            link_carrera = links_carreras.select{ |link_carrera| link_carrera.id == inscripcion_plan.institucion_sede_plan_id }.first
            carrera = carreras.select{ |carrera| carrera.id == link_carrera.plan_estudio_id }.first
            item[:carrera] = carrera.nombre

            data << item            
        end

        data
	end

    def self.filtrar_libro_asistencia seccion_id
        seccion = Seccion.get! seccion_id
        data = {}

        # "AlumnoInscritoSeccion"
        inscripciones_seccion = seccion.links_secciones_dictadas.links_alumnos_inscritos(
            :fields     => [
                :id, 
                :seccion_dictada_id, 
                :alumno_plan_estudio_id, 
                :estado,
                :horas_asistidas,
                :horas_ausentadas,
                :horas_justificadas
            ],
            :estado.not => [
                AlumnoInscritoSeccion::CONVALIDADA, 
                AlumnoInscritoSeccion::HOMOLOGADA,
                AlumnoInscritoSeccion::ABANDONADA
            ]
        )

        raise Excepciones::DatosNoExistentesError, "La sección consultada no posee alumnos." if inscripciones_seccion.empty?
        
        # "Clase"
        clases_seccion = seccion.clases :order => [:numero.asc]
        data[:clases] = clases_seccion.map { |clase| clase }
        # "Asistencias"
        asistencias = inscripciones_seccion.asistencias
        # "AlumnoPlanEstudio"
        inscripciones_plan = AlumnoPlanEstudio.all(
            :fields                     => [:id, :alumno_id, :anio_ingreso],
            :links_secciones_inscritas  => inscripciones_seccion
        )
        inscripciones_plan.size  # Esto es necesario para la eficiencia de DataMapper

        # "Alumno"
        alumnos = inscripciones_plan.alumno :fields => [:id, :usuario_id]
        # "Usuario"
        usuarios = alumnos.datos_personales :fields => [:id, :rut, :primer_nombre, :segundo_nombre, :apellido_paterno, :apellido_materno]

        data[:alumnos] = []
        usuarios.each do |usuario|
            item = {}
            # "Usuario"
            item[:datos] = usuario

            # "Alumno"
            alumno = alumnos.select{ |alumno| usuario.id == alumno.usuario_id }.first

            # "AlumnoPlanEstudio"
            inscripcion_plan = inscripciones_plan.select{ |inscripcion| alumno.id == inscripcion.alumno_id }.first

            # "AlumnoInscritoSeccion"
            inscripcion = inscripciones_seccion.select { |inscripcion| inscripcion_plan.id == inscripcion.alumno_plan_estudio_id }.first
            item[:inscripcion] = inscripcion

            # "Asistencias"
            asistencias_alumno = asistencias.select { |registro| inscripcion.id == registro.alumno_inscrito_seccion_id }

            item[:asistencias] = clases_seccion.map do |clase| 
                asistencia = asistencias_alumno.select { |asistencia| clase.id == asistencia.clase_id }.first
                {
                    :clase          => clase,
                    :asistencia     => asistencia
                }
            end

            data[:alumnos] << item
        end

        data
    end

    def self.filtrar_libro_calificaciones seccion_id, estado_inscripciones
        seccion = Seccion.get! seccion_id
        data = {}

        links_inscripciones = seccion.links_secciones_dictadas :fields => [:id, :seccion_id]

        # "AlumnoInscritoSeccion"
        inscripciones_seccion = links_inscripciones.links_alumnos_inscritos :estado => estado_inscripciones

        raise Excepciones::DatosNoExistentesError, "La sección consultada no posee alumnos, o ya todos ellos han sido evaluados." if inscripciones_seccion.empty?

        # "AlumnoPlanEstudio"
        inscripciones_plan = inscripciones_seccion.alumno_plan_estudio :fields => [:id, :alumno_id]
        # AlumnoTrabajador
        trabajadores = inscripciones_plan.alumno_trabajador :periodo_id => seccion.periodo_id
        # "Alumno"
        alumnos = inscripciones_plan.alumno :fields => [:id, :usuario_id]
        # "Usuario"
        usuarios = alumnos.datos_personales :fields => [:id, :rut, :primer_nombre, :segundo_nombre, :apellido_paterno, :apellido_materno]
        # "PlanificacionCalificacion"
        planificacion = seccion.planificacion_calificaciones :fields => [:id, :seccion_id, :nombre, :ponderacion, :estado]

        raise Excepciones::DatosNoExistentesError, "La sección consultada no posee una planificación de calificaciones." if planificacion.empty?

        # "CalificacionesParciales"
        calificaciones_parciales = inscripciones_seccion.calificaciones_parciales

        data[:planificaciones] = planificacion.map { |p| p }

        data[:alumnos] = []
        usuarios.each do |usuario|
            item = {}
            # "Usuario"
            item[:datos] = usuario

            # Navegamos hasta llegar a "AlumnoInscritoSeccion"
            alumno = alumnos.select { |alumno| usuario.id == alumno.usuario_id }.first
            inscripcion_plan = inscripciones_plan.select { |inscripcion| alumno.id == inscripcion.alumno_id }.first
            inscripcion_seccion = inscripciones_seccion.select { |inscripcion| inscripcion_plan.id == inscripcion.alumno_plan_estudio_id }.first
            item[:inscripcion] = inscripcion_seccion
            item[:trabajador] = trabajadores.select{ |trabajador| inscripcion_plan.id == trabajador.alumno_plan_estudio_id }.first
            calificacion_justificada = false

            # "CalificacionParcial"
            item2 = []
            i = 0
            item2 = planificacion.map do |p|
                # Obtenemos las calicaciones del alumno
                calificaciones = calificaciones_parciales.select { |calificacion| inscripcion_seccion.id == calificacion.alumno_inscrito_seccion_id }
                calificacion = calificaciones.select { |calificacion| p.id == calificacion.planificacion_calificacion_id }.first
                
                if not calificacion.nil? and calificacion.estado == CalificacionParcial::JUSTIFICADA
                    calificacion_justificada = true 
                end

                {
                    :nota           => (not calificacion.nil?) ? calificacion.calificacion : nil,
                    :estado_nota    => (not calificacion.nil?) ? calificacion.estado : nil,
                    :planificacion  => p
                }      
            end
            item[:calificaciones] = item2
            item[:calificacion_justificada] = calificacion_justificada

            data[:alumnos] << item
        end

        data
    end

    def self.libro_calificaciones seccion_id
         self.filtrar_libro_calificaciones seccion_id, [
            AlumnoInscritoSeccion::INSCRITA,
            AlumnoInscritoSeccion::APROBADA,
            AlumnoInscritoSeccion::REPROBADA,
            AlumnoInscritoSeccion::ABANDONADA,
            AlumnoInscritoSeccion::REPROBADA_NCR
        ] 
    end

    def self.preparar_libro_calificaciones seccion_id
        self.filtrar_libro_calificaciones seccion_id, [AlumnoInscritoSeccion::INSCRITA]
    end

    def self.libro_asistencia seccion_id; self.filtrar_libro_asistencia seccion_id end

    def self.clases seccion_id
        seccion = Seccion.get! seccion_id
        clases = seccion.clases :order => [:numero.asc]
        raise Excepciones::DatosNoExistentesError, "La sección consultada no posee una planificación de clases." if clases.empty?
        clases
    end
end