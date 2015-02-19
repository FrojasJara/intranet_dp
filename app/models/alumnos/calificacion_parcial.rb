# encoding: utf-8
class Alumnos::CalificacionParcial

	def self.calificaciones alumno_plan_estudio_id, periodo_id
		data = []

		# "AlumnoInscritoSeccion"
		inscripciones = AlumnoInscritoSeccion.all(
			:fields => [
				:id, 
				:alumno_plan_estudio_id, 
				:seccion_dictada_id, 
				:nota_presentacion, 
				:nota_examen, 
				:nota_examen_repeticion, 
				:nota_final
			],
			:alumno_plan_estudio_id => alumno_plan_estudio_id
		)

		# "SeccionDictada"
		links_secciones = inscripciones.seccion_dictada
		# "Seccion"
		secciones = links_secciones.seccion :fields => [:id, :periodo_id, :numero], :periodo_id => periodo_id

		raise Excepciones::DatosNoExistentesError, "No registra asignaturas cursadas en el período y plan consultados." if secciones.empty?

		# Borrar los objetos/informacion que no nos sirve
		id_secciones = secciones.map { |s| s.id }
		links_secciones.delete_if { |l| not id_secciones.include? l.seccion_id }
		id_links_secciones = links_secciones.map { |l| l.id }
		inscripciones.delete_if { |i| not id_links_secciones.include? i.seccion_dictada_id }

		# "Asignaturas"
		asignaturas = links_secciones.asignatura :fields => [:id, :codigo, :nombre]
		# "CalificacionesParciales"
		parciales = inscripciones.calificaciones_parciales
		# "PlanificacionCalificacion"
		planificaciones = secciones.planificacion_calificaciones

		links_secciones.each do |link_seccion|
			# "AlumnoInscritoSeccion"
			inscripcion = inscripciones.select { |inscripcion| link_seccion.id == inscripcion.seccion_dictada_id }.first
			# "Asignatura"
			asignatura = asignaturas.select { |asignatura| asignatura.id == link_seccion.asignatura_id }.first
			# "Seccion"
			seccion = secciones.select { |seccion| seccion.id == link_seccion.seccion_id }.first
			# "PlanificacionCalificacion"
			planificaciones_seccion = planificaciones.select { |planificacion| seccion.id == planificacion.seccion_id }

			calificaciones = planificaciones_seccion.map do |planificacion|
				parcial = parciales.select { |parcial| planificacion.id == parcial.planificacion_calificacion_id }.first
				{
					:planificacion 	=> planificacion,
					# Puede que no exista una calificacion para la instancia evaluativa (aún)
					:parcial 		=> (not parcial.nil?) ? parcial.calificacion : nil
				}
			end

			data << {
				:inscripcion 	=> inscripcion,
				:asignatura 	=> asignatura,
				:seccion 		=> seccion,
				:calificaciones => calificaciones
			}
		end

		data
	end
end