# encoding: utf-8
class Alumnos::MatriculaPlan

	def self.matriculas alumno_plan_estudio_id
		data = []

		# "MatriculaPlan"
		matriculas = MatriculaPlan.all :alumno_plan_estudio_id => alumno_plan_estudio_id

		raise Excepciones::DatosNoExistentesError, "No registra matrículas en el plan consultado." if matriculas.empty?

		# Planes
		planes = matriculas.planes_pago		
		# "Apoderado"
		links_apoderados = Apoderado.all :fields 	=> [:id, :usuario_id], :planes_pago => planes
		# "Usuario"
		apoderados = Usuario.all(
			:fields 	=> [:id, :primer_nombre, :segundo_nombre, :apellido_paterno, :apellido_materno],
			:apoderado 	=> links_apoderados
		)

		matriculas.each do |matricula|
			planes.select{ |plan| matricula.id == plan.matricula_plan_id }.each do |plan|
				# "Apoderado"
				link_apoderado = links_apoderados.select{ |link_apoderado| link_apoderado.id == plan.apoderado_id }.first
				# "Usuario"
				apoderado = apoderados.select { |apoderado| apoderado.id == link_apoderado.usuario_id }.first
				descuento = {
					:monto 	=> plan.descuento_aplicado,
					:nombre => plan.nombre_descuento
				}				
				data << {
					:matricula 	=> matricula,
					:plan 		=> plan,
					:periodo 	=> plan.periodo,
					:descuento 	=> descuento,
					:apoderado 	=> apoderado
				}
			end
		end

		return data
	end

end