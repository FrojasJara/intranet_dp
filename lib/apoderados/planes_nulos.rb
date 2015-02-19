matriculas = MatriculaPlan.all( fields:[:id], :periodo_id => 33 )
planes_pago = PlanPago.all(:periodo_id => 33)

planes_pago.each do |p|
	ma = p.matricula_plan
	if ma.id.blank?
		puts "id _plan de pago #{p.id}"
	end
end
puts "segunda prueba"

matriculas.each do |m|
	puts "probando esta matricula #{m.id}"
	if m.planes_pago.blank?
		puts "matricula erronea #{m.id}"
	end
end