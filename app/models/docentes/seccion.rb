# encoding: utf-8
class Docentes::Secciones

	def self.puede_ser_cerrada? seccion_id
		seccion = Seccion.get seccion_id

		if seccion.estado == Seccion::CERRADA
			raise Excepciones::OperacionNoPermitidaError, "La seccionn ya se encuentra cerrada"
		end

		inscritos = seccion.links_secciones_dictadas.links_alumnos_inscritos.count :estado => AlumnoInscritoSeccion::INSCRITA
		
		if inscritos > 0
			raise Excepciones::OperacionNoPermitidaError, "La seccionn no puede ser cerrada, ya que aún tiene alumnos sin calificación final"
		end
	end
end