# encoding: utf-8
class Alumnos::Asistencia

	def self.asistencias alumno_plan_estudio_id, periodo_id

		data = []

		# "AlumnoInscritoSeccion"
		inscripciones = AlumnoInscritoSeccion.all(
			:fields => [
				:id, 
				:alumno_plan_estudio_id, 
				:seccion_dictada_id, 
				:horas_asistidas, 
				:horas_ausentadas, 
				:horas_justificadas,
				:estado
			],
			:alumno_plan_estudio_id => alumno_plan_estudio_id
		)

		# "SeccionDictada"
		links_secciones = inscripciones.seccion_dictada
		# "Seccion"
		secciones = links_secciones.seccion(
			:fields => [:id, :periodo_id, :numero, :estado, :clases_realizadas, :clases_suspendidas, :clases_planificadas],
			:periodo_id => periodo_id
		)

		raise Excepciones::DatosNoExistentesError, "No registra asignaturas cursadas en el período y plan consultados." if secciones.empty?

		# Borrar los objetos/informacion que no nos sirve
		id_secciones = secciones.map { |s| s.id }
		links_secciones.delete_if { |l| not id_secciones.include? l.seccion_id }
		id_links_secciones = links_secciones.map { |l| l.id }
		inscripciones.delete_if { |i| not id_links_secciones.include? i.seccion_dictada_id }

		# "Asignaturas"
		asignaturas = links_secciones.asignatura :fields => [:id, :codigo, :nombre]
		# "Clases"
		clases_secciones = secciones.clases
		# "Asistencia"
		asistencias_alumno = inscripciones.asistencias

		links_secciones.each do |link_seccion|
			# "AlumnoInscritoSeccion"
			inscripcion = inscripciones.select { |inscripcion| link_seccion.id == inscripcion.seccion_dictada_id }.first
			# "Asignatura"
			asignatura = asignaturas.select { |asignatura| asignatura.id == link_seccion.asignatura_id }.first
			# "Seccion"
			seccion = secciones.select { |seccion| seccion.id == link_seccion.seccion_id }.first

			clases = clases_secciones.select { |clase| seccion.id == clase.seccion_id }
			asistencias = []
			clases.each do |clase|
				asistencia = asistencias_alumno.select { |asistencia| clase.id == asistencia.clase_id }.first
				asistencias << {
					:clase 		=> clase,
					:registro 	=> asistencia
				}
			end
			data << {
				:inscripcion 	=> inscripcion,
				:asignatura 	=> asignatura,
				:seccion 		=> seccion,
				:asistencias 	=> asistencias
			}
		end

		data
	end

end