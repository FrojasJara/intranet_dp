# encoding: utf-8
class Alumnos::Horario

	def self.horario alumno_plan_estudio_id

		# Para tener horario, hay que tener asignaturs inscritas, o tener un plan vigente
		carrera = AlumnoPlanEstudio.get alumno_plan_estudio_id
		if not Alumno::CARRERAS_VIGENTES.include? carrera.estado
			raise Excepciones::OperacionNoPermitidaError, "Su estado académico no le permite tener un horario en el período actual."
		end

		data = []

		# "AlumnoInscritoSeccion"
		inscripciones = AlumnoInscritoSeccion.all(
			:fields => [
				:id, 
				:alumno_plan_estudio_id, 
				:seccion_dictada_id
			],
			:alumno_plan_estudio_id => alumno_plan_estudio_id,
			:estado => AlumnoInscritoSeccion::INSCRITA
		)

		if inscripciones.empty?
			raise Excepciones::DatosNoExistentesError, "No registra asignaturas inscritas para el presente período en la carrera consultada."
		end

		# "SeccionDictada"
		links_secciones = inscripciones.seccion_dictada
		# "Seccion"
		secciones = links_secciones.seccion :fields => [:id]
		# "Asignatura"
		asignaturas = links_secciones.asignatura :fields => [:id, :nombre, :codigo]
		# "Horario"
		horarios = secciones.horarios

		if horarios.empty?
			raise Excepciones::DatosNoExistentesError, "Aún no existen horarios de clases para las asignaturas inscritas."
		end

		# "BloqueHorario"
		bloques_horarios = horarios.bloque_horario

		bloques_horarios.each do |b|
			item = {}
			item[:bloque] = b
			item[:dias] = []

			Horario::DIAS.each do |dia|
				item2 = {}
				# "No se considera el Domingo"
				next if Horario.const_get(dia) == Horario::DOMINGO

				horarios_dia = horarios.select { |h| b.id == h.bloque_horario_id and h.dia == Horario.const_get(dia) }
				# "Asignaturas" en el bloque
				asignaturas_dia = []
				horarios_dia.each do |h|
					seccion = secciones.select { |s| s.id == h.seccion_id }.first
					seccion_dictada = links_secciones.select { |l| seccion.id == l.seccion_id }.first
					asignatura = asignaturas.select { |a| a.id == seccion_dictada.asignatura_id }.first
					asignaturas_dia << asignatura
				end
				item2[:asignaturas] = asignaturas_dia
				item2[:hay_clases?] = (asignaturas_dia.size > 0) ? true : false
				item2[:topon?] = (asignaturas_dia.size == 1) ? true : false

				item[:dias] << item2

			end	
			data << item	

		end
		
		data
	end

end