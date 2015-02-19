filename = Rails.public_path + "/apoderadosall.csv"
	data = 0
	ap = 0

	apoderados = File.open(filename, "r") 
		apoderados.each_line do |apoderado|
	    	rut_al,apellido_al,nombre_al,rut_ap,nombre_ap,apellido_ap = apoderado.chomp.split(",")
	        #p = ApoderadoOld.new(:rut_ap => rut_ap,:apellido_ap => apellido_ap,:nombre_ap => nombre_ap,:apellido_al => apellido_al,:nombre_al => nombre_al ,:rut_al => rut_al)
	    	#p.save
	   		Apoderado.transaction do

	   			_apoderado = Usuario.find_by_rut(rut_ap)
	   			_alumno = Usuario.find_by_rut(rut_al)
	   			if not _apoderado.blank?
		   			unless  _alumno.blank? 
			   			alumno = _alumno.alumno	
			   			unless alumno.blank? 
			   				unless alumno.apoderado.blank?
			   					if not alumno.apoderado.usuario_id == _apoderado.id
			   						if not alumno.apoderado.siaa_id.blank?

			   							puts  _alumno.rut
				   						data = data + 1
				   					end
				   				end
			   				end
			   			end
			   		end
		   		else
		   		 	ap = ap +1	
		   		 	
		   		 	puts "rut apoderado que no existe #{rut_ap}"
		   		 	puts "rut alumno que no existe #{rut_al}"
	   			end
	   		end
		end
			puts "apoderados que no existen #{ap}" 
			puts "apoderados incorrectos #{data}"