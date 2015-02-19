class Reportes::Vicerrectoria


	def self.obtener_alumnos_matriculados filtros
		attrs_alumnos = %w[id anio_ingreso semestre jornada estado_academico es_trabajador usuario_id]
		attrs_datos_personales = %w[id rut email primer_nombre segundo_nombre apellido_paterno apellido_materno fecha_nacimiento estado_civil sexo]
		
		estado_academico = filtros[:estado_alumno].to_i
		sede_id  		 = filtros[:sede_id].to_i
		plan_estudio_id  = filtros[:plan_estudio_id].to_i

		
		#alumnos = Alumno.all(:fields => attrs_alumnos, :estado_academico => estado )
		alumnos = Alumno.all(:alumno_plan_estudio => {:plan_estudio_id => plan_estudio_id,:estado  => estado_academico}, :alumno_plan_estudio => {:institucion_sede_plan => {:plan_estudio_id => plan_estudio_id }})
		#puts "ALUMNOS #{alumnos.inspect}"


		alumnos_map = map_alumnos(alumnos)

		matriculados_map  = map_alumnos_plan_estudio alumnos, sede_id, plan_estudio_id

		datos_personales_map = map_datos_personales(alumnos, attrs_datos_personales)
		
		items = []
		rtrn = []

		alumnos_map.each do |a|
			datos_personales_map.each do |dp|
				items << dp[0].merge(a[0]) if dp[0][:id_usuario] == a[0][:usuario_id]
			end
		end
		rtrn = items
		aux = []
		rtrn.each do |i|
			i[:matriculas] = []
			matriculados_map.each do |m|
				i[:matriculas] << m[0] if m[0][:id_alumno] == i[:id_alumno] 
			end
		aux << i
		end
		aux

		rescue #Exception => e
			#puts "PROBLEMA #{e.message.inspect}"
			aux = []
	end

	
	#TODO: Mejorar Parametrizacion Consultas
	private


	def self.map_alumnos(alumnos, cond = {})

		#puts alumnos.inspect

		map_alumnos = alumnos.map do |x| 
						#puts x.inspect
						[{
							:id_alumno => x.id, 
							:anio_ingreso_institucion => x.anio_ingreso, 
							#:semestre_actual => x.semestre, 
							#:jornada_actual => x.jornada, 
							#TODO: Descomentar cuando se conosca el estado de los alumnos
							#:estado_academico => Alumno::constant_name(:ESTADOS_ACADEMICOS ,x.estado_academico), 
							#:es_trabajador => x.es_trabajador ? 'Si' : 'No',
							:usuario_id => x.usuario_id
							}]
					end
		map_alumnos		
	end

	def self.map_alumnos_plan_estudio(alumnos, sede_id, plan_estudio_id)
		#alumnos = AlumnoPlanEstudio.all(:alumno => alumnos, :institucion_sede_plan => )

 		plan_estudio = PlanEstudio.all(:institucion_sede_plan => {:institucion_sede => {:sede_id => sede_id}}, :id => plan_estudio_id)
 		
 		alumnos = AlumnoPlanEstudio.all(:institucion_sede_plan => {:plan_estudio => plan_estudio}, :alumno => alumnos)
		
		map_alumnos = alumnos.map do |x| 
								[{
									:id_alumno_plan_estudio => x.id, 
									:anio_ingreso_plan => x.anio_ingreso,
									#:estado_plan => Alumno::constant_name(:ESTADOS_ACADEMICOS, x.estado),
									:semestre_plan => x.semestre,
									#:tipo_ingreso_plan => Alumno::constant_name(:TIPOS_INGRESO, x.tipo_ingreso),
									:asig_aprobadas_plan => x.aprobadas,
									:asig_reprobadas_plan => x.reprobadas,
									:asig_abandonadas_plan => x.abandonadas,
									:asig_convalidadas_plan => x.convalidadas,
									:asig_homologadas_plan => x.homologadas,													
									:id_alumno => x.alumno_id 
								}]
							end	
		map_alumnos
	end

	def self.map_datos_personales(alumnos,attrs, cond = {})
		datos_personales = Usuario.all(:fields => attrs, :alumno => alumnos)

		map_datos_personales = datos_personales.map do |x|
										[{
											id_usuario: x.id,
											rut: x.rut,
											email: x.email,
											primer_nombre: x.primer_nombre,
											segundo_nombre: x.segundo_nombre,
											apellido_paterno: x.apellido_paterno,
											apellido_materno: x.apellido_materno,
											fecha_nacimiento: x.fecha_nacimiento,
											#estado_civil: Usuario::constant_name(:ESTADOS_CIVILES, x.estado_civil),
											#sexo: Usuario::constant_name(:SEXOS, x.sexo)

										}]
									end
		map_datos_personales
	end
end