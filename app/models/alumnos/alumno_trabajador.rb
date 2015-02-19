# encoding: utf-8
class Alumnos::AlumnoTrabajador

	def self.trabajos alumno_plan_estudio_id 
		data = []

		trabajos = AlumnoTrabajador.all :alumno_plan_estudio_id => alumno_plan_estudio_id

		raise Excepciones::DatosNoExistentesError, "No tiene registros de alumno trabajador en el plan consultado." if trabajos.empty?

		trabajos.each do |registro|
			data << {
				:registro 	=> registro,
				:periodo 	=> registro.periodo
			}
		end

		return data
	end
end