plan_pago = PlanPago.all(
							:fields => [:id, :matricula_plan_id],
							:tipo => [MatriculaPlan::PROFESIONAL_DOS_SEMESTRES, MatriculaPlan::TECNICA_DOS_SEMESTRES,MatriculaPlan::DISTANCIA_5_A_8_NIVEL, MatriculaPlan::DISTANCIA_1_A_4_NIVEL ],
							:estado => PlanPago::VIGENTE,
							:periodo_id => 3
							)

matricula = plan_pago.matricula_plan
puts "Cargando matriculas : #{plan_pago.size}"
inscripcion_alumno = AlumnoInscritoSeccion.all(
												:fields => [:id, :estado, :alumno_plan_estudio_id],
												:seccion_dictada => {:periodo_id => 3}
												)
puts "Cargando notas : #{inscripcion_alumno.size}"
listos = []
prepa = []
cont2 = 0
cont = 0
plan_pago.each do |e|
	puts "revisando : #{e.matricula_plan.alumno_plan_estudio.alumno.datos_personales.rut}"
	if e.matricula_plan.alumno_plan_estudio.estado == 2
		inscripcion_alumno.each do |i|
			if e.matricula_plan.alumno_plan_estudio.id == i.alumno_plan_estudio_id
				cont = cont + 1
				if i.estado  != 1
					cont2 = cont2 + 1
				end
			end
		end
		if cont == cont2
				listos << e.matricula_plan.alumno_plan_estudio
		end	
		cont2 = 0
		cont = 0
	end
end

puts "alumnos seleccionados : #{listos.size}"

AlumnoPlanEstudio.transaction do
	listos.each do |e|
		e.update :estado => 6
	end
end