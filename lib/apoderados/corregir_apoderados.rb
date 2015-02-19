filename = Rails.public_path + "/apoderadosall.csv"
	data = 0


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
			   							ap = Apoderado.find_by_usuario_id(_apoderado.id)
			   							id_nueva = ap.id
			   							alumno.update :apoderado_id => id_nueva			   							
				   						data = data + 1
				   					end
				   				end
			   				end
			   			end
			   		end
		   			   		 	
	   			end
	   		end
		end
			
			puts "apoderados corregidos : #{data}"