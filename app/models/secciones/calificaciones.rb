class Secciones::Calificaciones

	def self.guardar_planificacion_seccion planificacion_notas, seccion_id
		planificacion_notas.each do |i|
			plan = i[1]
			PlanificacionCalificacion.transaction do
				planificacion = PlanificacionCalificacion.new
				planificacion.nombre = PlanificacionCalificacion::PRUEBA_PARCIAL
				planificacion.ponderacion = plan[:ponderacion].to_f
				planificacion.numero = plan[:numero].to_i
				planificacion.fecha_comprometida = Time.parse plan[:fecha_planificada]
				planificacion.estado = PlanificacionCalificacion::COMPROMETIDA
				planificacion.seccion_id = seccion_id
				planificacion.save
			end
		end
	end

end