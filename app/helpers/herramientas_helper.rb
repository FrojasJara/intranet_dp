# encoding: utf-8
module HerramientasHelper
	
	def alumno_informes_links usuario
		str = ''
		unless (ape = AlumnoPlanEstudio.last(fields: [:id], alumno: usuario.alumno)).blank?
			item = ape.id
			str << "<li>" 
			str << link_to( 'Informe curricular', alumno_obtener_informe_curricular_path(usuario_id: usuario.id, alumno_plan_estudio_id: item) )
			
			str << "</li><li>"

			str << link_to( 'Malla curricular', alumno_obtener_malla_curricular_path(usuario_id: usuario.id, alumno_plan_estudio_id: item ) )

			str << "</li>"                                                            
		end		
		str
	end

	def docente_informes_links usuario
		str = '<li>'

		str << link_to( 'Asignaturas dictadas', docente_obtener_asignaturas_dictadas_path(usuario_id: usuario.id) )

		str << "</li><li>"

		str << link_to( 'Listado de alumnos', docente_obtener_listado_alumnos_path(usuario_id: usuario.id) )
		str << "</li><li>"
		str << link_to( 'Libro de asistencia', docente_obtener_libro_asistencia_path(usuario_id: usuario.id) )
		str << "</li><li>"
		str << link_to( 'Libro de calificaciones', docente_obtener_libro_calificaciones_path(usuario_id: usuario.id) )
		str << "</li><li>"
		str << link_to( 'Libro de clases', docente_obtener_libro_clases_path(usuario_id: usuario.id) )
		str << "</li><li>"
		str << link_to( 'Asignaturas abiertas', docente_obtener_asignaturas_abiertas_path(usuario_id: usuario.id) )

		str << '</li>'
		str
	end

end