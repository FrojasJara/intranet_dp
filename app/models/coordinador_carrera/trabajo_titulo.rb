class CoordinadorCarrera::TrabajoTitulo

	def self.ingresar_trabajo_titulo inscripcion,trabajo_titulo,nombre_trabajo, nota_docente_guia,  nota_docente_informante, comision_examinadora, profesor_informante, profesor_guia

		TrabajoTitulo.transaction do 

			titulo 									= TrabajoTitulo.new
			titulo.nombre 							= nombre_trabajo
			titulo.fecha 							= trabajo_titulo[:fecha]
			titulo.rol 								= trabajo_titulo[:rol]
			titulo.alumno_inscrito_seccion_id 		= inscripcion
			titulo.estado 							= TrabajoTitulo::EN_CURSO 
			titulo.save

			docente_informante 						= DocenteTrabajoTitulo.new
			docente_informante.nota 				= nota_docente_informante.to_f
			docente_informante.tipo 				= DocenteTrabajoTitulo::INFORMANTE
			docente_informante.trabajo_titulo_id 	= titulo.id
			docente_informante.docente_id 			= profesor_informante.id
			docente_informante.save 

			docente_guia 							= DocenteTrabajoTitulo.new
			docente_guia.nota 						= nota_docente_guia.to_f
			docente_guia.tipo 						= DocenteTrabajoTitulo::GUIA
			docente_guia.trabajo_titulo_id			= titulo.id
			docente_guia.docente_id 				= profesor_guia.id
			docente_guia.save 

			examen 									= ExamenTitulo.new 
			examen.estado 							= ExamenTitulo::PACTADO
			examen.fecha 							= trabajo_titulo[:fecha]
			examen.trabajo_titulo_id 				= titulo.id
			examen.save

			comision_examinadora.each do |i|
				rut 								= i[:docente].split('| ')
        		docente 							= Docente.first(:datos_personales => {:rut => rut[1]})
				comision 							= DocenteExaminador.new
				comision.examen_titulo_id 			= examen.id
				comision.nota_expocision 			= i[:nota_exposicion].to_f
				comision.nota_defensa 				= i[:nota_defensa].to_f
				comision.docente_id					= docente.id
				comision.save
			end
			nota 								= 0.0
			nota_f 								= 0.0
			nota 								= docente_informante.nota + docente_guia.nota
			nota_f 								= nota / 2
			alumno_inscrito_seccion    			= AlumnoInscritoSeccion.first(:id => inscripcion)
       		alumno_inscrito_seccion.estado 		= 2
        	alumno_inscrito_seccion.nota_final 	= nota_f
        	alumno_inscrito_seccion.save
        	alumno_plan_estudio 				= alumno_inscrito_seccion.alumno_plan_estudio
        	alumno_plan_estudio.estado			= Alumno::TITULADO
        	alumno_plan_estudio.save
			
		end
	end
end