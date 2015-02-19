# => Cambio Periodo Seccion Dictada
secciones = Seccion.all
secciones.each do |i|
    unless i.links_secciones_dictadas.nil?
        i.links_secciones_dictadas.each do |s|
            puts s.inspect.blue
        	s.periodo_id =  i.periodo_id
        	s.save
        end
    end
end
