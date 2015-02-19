# encoding: utf-8
class HerramientasController < ApplicationController

	def buscar_alumno
		@items = []
		
		if (f = params[:busqueda] )
			raise Excepciones::DatosNoExistentesError, "Debe ingresar un valor" if params[:busqueda].blank?

			conditions = condicion_buscar_nombre_o_rut f

			if Usuario.count(tipo: Usuario::ESTUDIANTE, conditions: conditions) > 150
				flash.now[:error] = "Su búsqueda es muy amplia, por favor busque con rut o nombre y apellido"
			else
				@items = Usuario.all(
	                   		conditions: 	conditions, 
		                   	tipo: 			Usuario::ESTUDIANTE, 
		                   	fields: 		[	:id, :rut, 
		                   						:primer_nombre, :segundo_nombre, :apellido_paterno, :apellido_materno, 
		                   						:domicilio, :villa_poblacion, 
		                   						:codigo_area_telefono, :telefono_fijo, :telefono_movil]
					    )
			end
		end
	rescue Excepciones::DatosNoExistentesError => e
        flash.now[:error] = "#{e.message}"
	end

	def buscar_docente
		@items = []

		if (f = params[:busqueda])
			conditions = condicion_buscar_nombre_o_rut f

			if Usuario.count(tipo: Usuario::DOCENTE, conditions: conditions) > 150
				flash.now[:error] = "Su búsqueda es muy amplia, por favor busque con rut o nombre y apellido"
			else
				@items = Usuario.all(
				            conditions: 	conditions, 
		                   	tipo: 			Usuario::DOCENTE, 
		                   	fields: 		[	:id, :rut, 
		                   						:primer_nombre, :segundo_nombre, :apellido_paterno, :apellido_materno, 
		                   						:domicilio, :villa_poblacion, 
		                   						:codigo_area_telefono, :telefono_fijo, :telefono_movil])
			end
		end		
	end

	def buscar_apoderado
		@items = []

		if (f = params[:busqueda] )
			conditions = condicion_buscar_nombre_o_rut f

			if Usuario.count(conditions: conditions, :apoderado.not => nil) > 150 
				flash.now[:error] = "Su búsqueda es muy amplia, por favor busque con rut o nombre y apellido"
			else
				@items = Usuario.all(
	                   		conditions: 	conditions, 
	                   		:apoderado.not => nil,
		                   	fields: 		[	:id, :rut, 
		                   						:primer_nombre, :segundo_nombre, :apellido_paterno, :apellido_materno, 
		                   						:domicilio, :villa_poblacion, 
		                   						:codigo_area_telefono, :telefono_fijo, :telefono_movil]
					    )
			end
		end
	end

	def buscar_seccion

	end

	def buscar_lista_seccion
		@items = []


		prms = params[:busqueda]
		
		if prms && prms.has_key?(:carrera)
			institucion_sede_plan = InstitucionSedePlan.get prms[:carrera]
			@plan_estudio = PlanEstudio.first(institucion_sede_plan: institucion_sede_plan, fields: [:id, :titulo_profesional])
			@plan_estudio_id = @plan_estudio.id

			asignaturas = Asignatura.all( fields: [:id, :nombre], plan_estudio_id: @plan_estudio_id )

			
			@plan_estudio = @plan_estudio.titulo_profesional

			periodos = Periodo.all
			secciones_dictadas = SeccionDictada.all( asignatura_id: asignaturas.map {|x| x.id} )
			secciones = secciones_dictadas.seccion
			docentes = secciones.docentes(fields: [:usuario_id])
			datos_personales = Usuario.all fields: [:id, :primer_nombre, :apellido_paterno], id: docentes.map{|x| x.usuario_id}

			secciones_dictadas.each do |sd|
				seccion = secciones.select {|x| x.id == sd.seccion_id}.first
				periodo = periodos.select {|x| x.id == seccion.periodo_id}.first
				asignatura = asignaturas.select {|x| x.id == sd.asignatura_id}.first
				docente = docentes.select{|x| x.id == seccion.docente_id}.first
				profesor = nil
				docente_id = 0
				unless docente.blank?
					nc = (datos_personales.select{|x| x.id == docente.usuario_id}.first)
					docente_id = nc.id
					profesor = nc.nombre_corto unless nc.blank?
				end
				
				@items << 	{
								anio: periodo.anio,
								semestre: periodo.semestre,
								periodo: "#{periodo.anio}-#{periodo.semestre}",
								nombre: asignatura.nombre,
								numero: seccion.numero,
								profesor: profesor,
								docente_id: docente_id,
								seccion_id: seccion.id,
								asignatura_id: asignatura.id
							}
			end

			@items = @items.sort{|a, b| [b[:anio], b[:semestre]] <=> [a[:anio], a[:semestre]] }
		end	

		render layout: false
	end

	def editar_alumno
		@usuario = Usuario.first :rut => params[:rut].to_s
		
		@paises = Pais.all
		@regiones = Region.all
		@comunas = Comuna.all
	end

	def editar_apoderado
		user = Usuario.first :rut => params[:rut].to_s
		
		@usuario = Usuario.first :id => user.alumno.apoderado.usuario_id;

		@paises = Pais.all
		@regiones = Region.all
		@comunas = Comuna.all
	end

	def editar_apoderado2
		@usuario = Usuario.first :rut => params[:rut].to_s

		@paises = Pais.all
		@regiones = Region.all
		@comunas = Comuna.all
	end

	def actualizar_alumno
		id = params[:id].to_i
		usuario = Usuario.get id
		
		usuario.update params[:usuario]
		usuario.alumno.update params[:alumno]
		
		flash[:notice] = "Usuario Actualizado exitósamente."
		redirect_to editar_alumno_herramientas_path usuario.rut
		rescue Exception => e
		flash[:error] = "Error de edición, verifique los campos ingresados."
		redirect_to editar_alumno_herramientas_path usuario.rut
	end

	def actualizar_apoderado
		id = params[:id].to_i
		usuario = Usuario.get id

		usuario.update params[:usuario]
		
		flash[:notice] = "Usuario Actualizado exitósamente."
		redirect_to editar_apoderado2_herramientas_path usuario.rut
		rescue 
		flash[:error] = "Error de edición, verifique los campos ingresados."
		redirect_to editar_apoderado2_herramientas_path usuario.rut
	end

	def actualizar_apoderado2
		id = params[:id].to_i
		usuario = Usuario.get id

		usuario.update params[:usuario]
		
		flash[:notice] = "Usuario Actualizado exitósamente."
		redirect_to editar_apoderado2_herramientas_path usuario.rut
		rescue 
		flash[:error] = "Error de edición, verifique los campos ingresados."
		redirect_to editar_apoderado2_herramientas_path usuario.rut
	end

	private
	def condicion_buscar_nombre_o_rut str
		palabras = str.split(" ")
			

		conditions = ['rut LIKE ? OR (', "%#{str}%"]

		if palabras.length == 2
			conditions[0] << ' (primer_nombre LIKE ? AND apellido_paterno LIKE ?) OR '
			conditions << "%#{palabras.first}%"
			conditions << "%#{palabras.second}%"

			conditions[0] << ' (primer_nombre LIKE ? AND apellido_paterno LIKE ?)'
			conditions << "%#{palabras.second}%"
			conditions << "%#{palabras.first}%"
		else
			first = true
			palabras.each do |p|
				conditions[0] << (first ? '' : ' OR ') << ' primer_nombre LIKE ? '
				conditions << "%#{p}%"

				conditions[0] << ' OR apellido_paterno LIKE ? '
				conditions << "%#{p}%"	
				first = false
			end

		end
		
		conditions[0] << ')'

		return conditions
	end

	
end