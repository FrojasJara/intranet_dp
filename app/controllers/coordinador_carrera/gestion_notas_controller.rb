# encoding: utf-8
class CoordinadorCarrera::GestionNotasController < ApplicationController
    before_filter :iniciar

    protect_from_forgery :except => [
                                        :buscar_planificacion,
                                        :ver_planificacion_seccion,
                                        :registrar_planificacion_seccion,
                                        :ver_notas_seccion,
										:registrar_notas_seccion,
										:ver_acta_notas,
										:registrar_modificacion_planificacion_seccion
                                    ]

	def buscar_planificacion

		

	end

	# => Mostrar la planificacion de una seccion
	def ver_planificacion_seccion
		if current_role_can?(:direccion_escuela)
			@sedes = Sede.all(id: Sede::SEDES_VIGENTES)
		else
			@sedes = Sede.all(:id => current_user[:sede_id])
		end
		@notas_planificadas = []
		
		if params.has_key?("filtro")
			
			#------> Llenar filtro donde quedo <------------------
			if current_role_can?(:direccion_escuela)
				@sedes = Sede.all(id: Sede::SEDES_VIGENTES)
			else
				@sedes = Sede.all(:id => current_user[:sede_id])
			end
			@filtro = params[:filtro]
			@carrera = PlanEstudio.all(
        									:fields => [:id, :nombre, :siaa_id_ma], 
        									:institucion_sede_plan => {
        																:institucion_sede => {:sede_id => @filtro[:sede_id] }
        																},
        									:coordinadores => {:usuario_id =>current_user[:id]},
        									:estado => PlanEstudio::VIGENTE,
                                            :order => :siaa_id_ma.asc
        								)
			@secciones_f   = Seccion.all(
                                    :fields => [:id, :jornada, :numero], 
                                    :links_secciones_dictadas => {
                                                :asignatura_id => @filtro[:asignatura_id].to_i
                                        },
                                    :institucion_sede => {:sede_id => @filtro[:sede_id]},
                                    :numero.not => [Seccion::CONVALIDADA_HOMOLOGADA, Seccion::HISTORIAL_ACADEMICO],
                                    :periodo_id => @filtro[:periodo_id].to_i
                                )
			@plan_estudio_seleccionado = PlanEstudio.find_by_id(@filtro[:plan_estudio_id].to_i)
			@asignaturas = @plan_estudio_seleccionado.asignaturas

			#------> Final del filtro <------------------
			seccion_id = params[:filtro][:seccion_id].to_i
			@seccion = Seccion.find_by_id(seccion_id)
			@asignatura = @seccion.asignatura_base
			@secciones = Seccion.all(
									:fields =>[:id, :numero, :jornada],
									:periodo_id => @filtro[:periodo_id].to_i,
									:links_secciones_dictadas => {
											:asignatura_id => @asignatura.id}
								)

			@notas_planificadas = PlanificacionCalificacion.all(
																:fields => [:id, :ponderacion, :fecha_comprometida, :numero, :tipo],
																:seccion_id => @seccion.id
															)
			
		end
	end	

	def registrar_planificacion_seccion
		planificacion_notas = params[:planificacion][:notas] 
		seccion_id = params[:planificacion][:seccion_id].to_i

		Secciones::PlanificacionesCalificaciones::guardar_planificacion_seccion planificacion_notas, seccion_id
		

		flash[:notice] = "La planificación de las notas ha sido ingresada exitosamente."
		redirect_to coordinador_carrera_ver_planificacion_seccion_path	
		
		 rescue Exception => e
		 	flash[:error] = "No ha sido posible guardar la planificacion de las notas."
		 	redirect_to coordinador_carrera_ver_planificacion_seccion_path
	end
	
	def registrar_modificacion_planificacion_seccion
		planificaciones = params[:planificacion]
		
		PlanificacionCalificacion.transaction do 
			planificaciones.each do |planificacion|
				planificacion_id = planificacion[0].to_i
				_planificacion = PlanificacionCalificacion.find_by_id(planificacion_id)
				_planificacion.numero = planificacion[1][:numero].to_i
				_planificacion.fecha_comprometida = planificacion[1][:fecha_comprometida]
				_planificacion.ponderacion = planificacion[1][:ponderacion_porcentual].to_f
				_planificacion.save
			end
		end
		flash[:notice] = "La planificación de las notas ha sido modificada exitosamente."
		redirect_to coordinador_carrera_ver_planificacion_seccion_path	
		
		 rescue Exception => e
		 	flash[:error] = "No ha sido posible guardar la planificacion de las notas."
		 	redirect_to coordinador_carrera_ver_planificacion_seccion_path
	end


	def ver_notas_seccion
		#if current_role_can?(:direccion_escuela)
		#	@sedes = Sede.all(id: Sede::SEDES_VIGENTES)
		#else
		#	@sedes = Sede.all(:id => current_user[:sede_id])
		#end

		@notas_planificadas = []
		@alumnos = []
		
		if params.has_key?("seccion_id")
			#------> Llenar filtro donde quedo <------------------
			#if current_role_can?(:direccion_escuela)
			#	@sedes = Sede.all(id: Sede::SEDES_VIGENTES)
			#else
			#	@sedes = Sede.all(:id => current_user[:sede_id])
			#end
			#@filtro = params[:filtro]
			#@carrera = PlanEstudio.all(
        	#								:fields => [:id, :nombre, :siaa_id_ma], 
        	#								:institucion_sede_plan => {
        	#															:institucion_sede => {:sede_id => @filtro[:sede_id] }
        	#															},
        	#								:coordinadores => {:usuario_id =>current_user[:id]},
        	#								:estado => PlanEstudio::VIGENTE,
            #                               :order => :siaa_id_ma.asc
        	#							)
			#@secciones_f   = Seccion.all(
            #                        :fields => [:id, :jornada, :numero], 
            #                        :links_secciones_dictadas => {
            #                                    :asignatura_id => @filtro[:asignatura_id].to_i
            #                            },
            #                        :institucion_sede => {:sede_id => @filtro[:sede_id]},
            #                        :numero.not => [Seccion::CONVALIDADA_HOMOLOGADA, Seccion::HISTORIAL_ACADEMICO],
            #                        :periodo_id => @filtro[:periodo_id].to_i
            #                    )
			#@plan_estudio_seleccionado = PlanEstudio.find_by_id(@filtro[:plan_estudio_id].to_i)
			#@asignaturas = @plan_estudio_seleccionado.asignaturas

			#------> Final del filtro <------------------
			@periodo = Periodo.find_by_id(params[:periodo_id].to_i)
			seccion_id = params[:seccion_id].to_i
			@seccion = Seccion.find_by_id(seccion_id)
			@asignatura = @seccion.asignatura_base
			@plan_estudio_seleccionado = PlanEstudio.find_by_id(@asignatura.plan_estudio_id)
			@notas_planificadas = PlanificacionCalificacion.all(
										:fields => [:id, :ponderacion, :fecha_comprometida, :numero, :tipo],
										:seccion_id => @seccion.id)
			
			if  @periodo.id == Periodo::en_curso.id
				@alumnos = AlumnoInscritoSeccion.all(
													:fields => [:id, :seccion_dictada_id, :alumno_plan_estudio_id,:estado], 
													:seccion_dictada => {
														:seccion_id => @seccion.id,
													}, 
													:alumno_plan_estudio => {
															:estado => [Alumno::REGULAR, Alumno::SIN_MATRICULA, Alumno::SIN_INSCRIPCION, Alumno::TITULADO]
													},
													:estado.not =>[AlumnoInscritoSeccion::CONVALIDADA, AlumnoInscritoSeccion::HOMOLOGADA]
												)
			else
				@alumnos = AlumnoInscritoSeccion.all(
														:fields => [:id, :seccion_dictada_id, :alumno_plan_estudio_id,:estado], 
														:seccion_dictada => {
															:seccion_id => @seccion.id,
														},
														:estado.not =>[AlumnoInscritoSeccion::CONVALIDADA, AlumnoInscritoSeccion::HOMOLOGADA]
													)
			end
		end
	end

	def registrar_notas_seccion
		seccion_id = params[:seccion_id].to_i
		periodo_id = params[:periodo_id].to_i
		notas_alumnos = params[:notas]
		notas_actualizadas = params[:notas_actualizadas]
		alumnos = []
		# => Actualizar Notas
		unless notas_actualizadas.blank?
			notas_actualizadas.each do |nota|
				CalificacionParcial.transaction do
					calificacion_parcial_id = nota[0].to_i
					calificacion = nota[1].to_f
					calificacion_parcial = CalificacionParcial.find_by_id(calificacion_parcial_id)
					calificacion_parcial.calificacion = calificacion
					calificacion_parcial.save
				end
			end
		end
		unless notas_alumnos.blank?
			# => Registrar Notas Nuevas
			periodo_id = params[:periodo_id].to_i
			seccion_id = params[:seccion_id].to_i
			notas_alumnos.each do |notas|
				alumno_inscrito_seccion_id = notas[0].to_i
				notas_alumno = notas[1].to_a
				notas_alumno.each do |nota_alumno|
					CalificacionParcial.transaction do 
						_nota_alumno = nota_alumno[0]
						_nota   = nota_alumno[1].to_f
						
						case _nota_alumno
						when "nota_examen"
							alumno = AlumnoInscritoSeccion.find_by_id(alumno_inscrito_seccion_id)
							alumno.nota_examen = _nota 
							alumno.save 

						when "nota_examen_repeticion"
							if (_nota == "NCR")
								_nota = 0.0
								alumno = AlumnoInscritoSeccion.find_by_id(alumno_inscrito_seccion_id)
								alumno.nota_examen_repeticion = _nota 
								alumno.save 
							else 
								alumno = AlumnoInscritoSeccion.find_by_id(alumno_inscrito_seccion_id)
								alumno.nota_examen_repeticion = _nota 
								alumno.save 
							end

						else
							_plan_id = nota_alumno[0].to_i
							nueva_nota = CalificacionParcial.new
							nueva_nota.calificacion  = _nota
							nueva_nota.estado = CalificacionParcial::CALIFICADA
							nueva_nota.alumno_inscrito_seccion_id = alumno_inscrito_seccion_id
							nueva_nota.planificacion_calificacion_id = _plan_id
							nueva_nota.save
						end
					end
				end
			end
		end

		flash[:notice] = "Las notas han sido ingresadas exitosamente."
		redirect_to coordinador_carrera_ver_notas_seccion_path(seccion_id,periodo_id)
		
		rescue Exception => e
			flash[:error] = "Ha ocurrido un problema, no ha sido posible ingresar las notas."
			redirect_to coordinador_carrera_ver_notas_seccion_path(seccion_id,periodo_id)
	
	end

	def calcular_np_seccion
		seccion_id = params[:seccion_id].to_i
		periodo_id = params[:periodo_id].to_i
		@seccion = Seccion.find_by_id(seccion_id)
		@secciones_dictadas = @seccion.links_secciones_dictadas
		AlumnoInscritoSeccion.transaction do
			@secciones_dictadas.each do |seccion_dictada|
				seccion_dictada.links_alumnos_inscritos.each do |alumno_inscrito|
					np_alumno = 0.0
					alumno_inscrito.calificaciones_parciales.each do |calificacion_parcial|
						np_alumno += calificacion_parcial.calificacion * calificacion_parcial.planificacion_calificacion.ponderacion
					end
					alumno_inscrito.nota_presentacion = np_alumno.round(1)
					alumno_inscrito.save
				end
			end
		end
		#actualizar_promedios @seccion

		flash[:notice] = "Las notas de presentación han sido calculadas exitosamente."
		redirect_to coordinador_carrera_ver_notas_seccion_path(seccion_id,periodo_id)
		
		rescue Exception => e
			flash[:error] = " #{e} Ha ocurrido un error y no ha sido posible calcular la nota de presentación"
			redirect_to coordinador_carrera_ver_notas_seccion_path(seccion_id,periodo_id)
	end

	def calcular_nf_seccion
		seccion_id = params[:seccion_id].to_i
		periodo_id = params[:periodo_id].to_i
		@seccion = Seccion.find_by_id(seccion_id)
		@secciones_dictadas = @seccion.links_secciones_dictadas

		AlumnoInscritoSeccion.transaction do
			@secciones_dictadas.each do |seccion_dictada|

				seccion_dictada.links_alumnos_inscritos.each do |alumno_inscrito|
					#preguntamos si el alumno tiene nota de presentacion ¡¡¡
					if !alumno_inscrito.nota_presentacion.blank?
						nf_alumno = 0.0
						_nota_ex_rep = alumno_inscrito.nota_examen_repeticion
						if alumno_inscrito.es_cft?
							if se_eximio?(alumno_inscrito)
								alumno_inscrito.nota_final = alumno_inscrito.nota_presentacion
								alumno_inscrito.estado = AlumnoInscritoSeccion::APROBADA
							end
							if a_reprobado?(alumno_inscrito)
								alumno_inscrito.nota_final = alumno_inscrito.nota_presentacion
								alumno_inscrito.estado = AlumnoInscritoSeccion::REPROBADA
							end
							if not a_reprobado?(alumno_inscrito) and not se_eximio?(alumno_inscrito) and not abandono?(alumno_inscrito)
								if (not alumno_inscrito.nota_examen.nil?) 
									if aprobo_con_examen?(alumno_inscrito)
										alumno_inscrito.nota_final = (alumno_inscrito.nota_presentacion * 0.6 + alumno_inscrito.nota_examen * 0.4).round(1)
										alumno_inscrito.estado = AlumnoInscritoSeccion::APROBADA

									elsif (not aprobo_con_examen?(alumno_inscrito)) and (not alumno_inscrito.nota_examen_repeticion.nil?)
										
										if rindio_examen_repeticion?(alumno_inscrito) 
											if aprobo_con_examen_repeticion?(alumno_inscrito)
												alumno_inscrito.nota_final = (alumno_inscrito.nota_presentacion * 0.6 + alumno_inscrito.nota_examen_repeticion * 0.4).round(1)
												alumno_inscrito.estado = AlumnoInscritoSeccion::APROBADA
											else
												alumno_inscrito.nota_final =  (alumno_inscrito.nota_presentacion * 0.6 + alumno_inscrito.nota_examen_repeticion * 0.4).round(1)
												alumno_inscrito.estado = AlumnoInscritoSeccion::REPROBADA
											end
										else
												alumno_inscrito.nota_final = (alumno_inscrito.nota_presentacion * 0.6 + alumno_inscrito.nota_examen * 0.4).round(1)
												alumno_inscrito.estado = AlumnoInscritoSeccion::REPROBADA
										end
									end

								end
							end
						else
							if alumno_inscrito.seccion_dictada.asignatura.tipo == Asignatura::TERMINAL
								if abandono?(alumno_inscrito)
										alumno_inscrito.nota_final = alumno_inscrito.nota_presentacion
										alumno_inscrito.estado = AlumnoInscritoSeccion::ABANDONADA
								else
									if alumno_inscrito.nota_presentacion > CalificacionParcial::NOTA_MINIMA_APROXIMADA
										alumno_inscrito.nota_final = alumno_inscrito.nota_presentacion
										alumno_inscrito.estado = AlumnoInscritoSeccion::APROBADA
									else
										alumno_inscrito.nota_final = alumno_inscrito.nota_presentacion
										alumno_inscrito.estado = AlumnoInscritoSeccion::REPROBADA
									end
								end
							else
								if alumno_inscrito.es_alumno_distancia?
									
									# => Si tiene nota de Examen 
									if alumno_inscrito.nota_presentacion < CalificacionParcial::NOTA_EXAMEN_APROXIMADA and alumno_inscrito.nota_presentacion > CalificacionParcial::NO_CUMPLE_REQUISITOS
										alumno_inscrito.nota_final = alumno_inscrito.nota_presentacion
										alumno_inscrito.estado = AlumnoInscritoSeccion::REPROBADA
									end

									if abandono?(alumno_inscrito)
										alumno_inscrito.nota_final = alumno_inscrito.nota_presentacion
										alumno_inscrito.estado = AlumnoInscritoSeccion::ABANDONADA
									end

									if (not alumno_inscrito.nota_examen.nil?) and (not abandono?(alumno_inscrito))
										# => Si aprueba con examen
										if aprobo_con_examen?(alumno_inscrito)
											alumno_inscrito.nota_final = (alumno_inscrito.nota_presentacion * 0.4 + alumno_inscrito.nota_examen * 0.6).round(1)
											alumno_inscrito.estado = AlumnoInscritoSeccion::APROBADA
										
										# => Si no aprueba con examen y tiene nota de Repete
										elsif (not aprobo_con_examen?(alumno_inscrito)) 
											if aprobo_con_examen_repeticion?(alumno_inscrito)
												alumno_inscrito.nota_final = CalificacionParcial::NOTA_MINIMA
												alumno_inscrito.estado = AlumnoInscritoSeccion::APROBADA
											else
												if (not alumno_inscrito.nota_examen_repeticion.nil?)
													if (alumno_inscrito.nota_examen_repeticion == CalificacionParcial::NO_CUMPLE_REQUISITOS)
														alumno_inscrito.nota_final = (alumno_inscrito.nota_presentacion * 0.4 + alumno_inscrito.nota_examen * 0.6).round(1)
														alumno_inscrito.estado = AlumnoInscritoSeccion::REPROBADA
													elsif 
														alumno_inscrito.nota_final = alumno_inscrito.nota_examen_repeticion
														alumno_inscrito.estado = AlumnoInscritoSeccion::REPROBADA
													end
												end
													
											end
										end
									end							
								else
									if se_eximio?(alumno_inscrito)
										alumno_inscrito.nota_final = alumno_inscrito.nota_presentacion
										alumno_inscrito.estado = AlumnoInscritoSeccion::APROBADA
									end

									if a_reprobado?(alumno_inscrito)
										alumno_inscrito.nota_final = alumno_inscrito.nota_presentacion
										alumno_inscrito.estado = AlumnoInscritoSeccion::REPROBADA
									end

									if abandono?(alumno_inscrito)
										alumno_inscrito.nota_final = alumno_inscrito.nota_presentacion
										alumno_inscrito.estado = AlumnoInscritoSeccion::ABANDONADA
									end

									if not a_reprobado?(alumno_inscrito) and not se_eximio?(alumno_inscrito) and not abandono?(alumno_inscrito)
										if (not alumno_inscrito.nota_examen.nil?) 
											if aprobo_con_examen?(alumno_inscrito)
												alumno_inscrito.nota_final = (alumno_inscrito.nota_presentacion * 0.6 + alumno_inscrito.nota_examen * 0.4).round(1)
												alumno_inscrito.estado = AlumnoInscritoSeccion::APROBADA

											elsif (not aprobo_con_examen?(alumno_inscrito)) and (not alumno_inscrito.nota_examen_repeticion.nil?)
												
												if rindio_examen_repeticion?(alumno_inscrito) 
													if aprobo_con_examen_repeticion?(alumno_inscrito)
														alumno_inscrito.nota_final = CalificacionParcial::NOTA_MINIMA
														alumno_inscrito.estado = AlumnoInscritoSeccion::APROBADA
													else
														alumno_inscrito.nota_final =  alumno_inscrito.nota_examen_repeticion
														alumno_inscrito.estado = AlumnoInscritoSeccion::REPROBADA
													end
												else
														alumno_inscrito.nota_final = (alumno_inscrito.nota_presentacion * 0.6 + alumno_inscrito.nota_examen * 0.4).round(1)
														alumno_inscrito.estado = AlumnoInscritoSeccion::REPROBADA
												end
											end

										end
									end
								end
							end
						end
						alumno_inscrito.save
					end
				end
			end
		end

		flash[:notice] = "Las notas Finales han sido calculadas exitosamente."
		redirect_to coordinador_carrera_ver_notas_seccion_path(seccion_id,periodo_id)
		
		rescue Exception => e
			flash[:error] = "#{e}Ha ocurrido un error y no ha sido posible calcular la nota Final"
			redirect_to coordinador_carrera_ver_notas_seccion_path(seccion_id,periodo_id)
	end
	def ver_acta_notas
		if current_role_can?(:direccion_escuela)
			@sedes = Sede.all(id: Sede::SEDES_VIGENTES)
		else
			@sedes = Sede.all(:id => current_user[:sede_id])
		end
		@alumnos = []
		if params.has_key?("filtro")
			#------> Llenar filtro donde quedo <------------------
			if current_role_can?(:direccion_escuela)
				@sedes = Sede.all(id: Sede::SEDES_VIGENTES)
			else
				@sedes = Sede.all(:id => current_user[:sede_id])
			end
			@filtro = params[:filtro]
			@carrera = PlanEstudio.all(
        									:fields => [:id, :nombre, :siaa_id_ma], 
        									:institucion_sede_plan => {
        																:institucion_sede => {:sede_id => @filtro[:sede_id] }
        																},
        									:coordinadores => {:usuario_id =>current_user[:id]},
        									:estado => PlanEstudio::VIGENTE,
                                            :order => :siaa_id_ma.asc
        								)
			@secciones_f   = Seccion.all(
                                    :fields => [:id, :jornada, :numero], 
                                    :links_secciones_dictadas => {
                                                :asignatura_id => @filtro[:asignatura_id].to_i
                                        },
                                    :institucion_sede => {:sede_id => @filtro[:sede_id]},
                                    :numero.not => [Seccion::CONVALIDADA_HOMOLOGADA, Seccion::HISTORIAL_ACADEMICO],
                                    :periodo_id => @filtro[:periodo_id].to_i
                                )
			@plan_estudio_seleccionado = PlanEstudio.find_by_id(@filtro[:plan_estudio_id].to_i)
			@asignaturas = @plan_estudio_seleccionado.asignaturas

			#------> Final del filtro <------------------
			@usuario = Usuario.find_by_id(current_user[:id])
			seccion_id = params[:filtro][:seccion_id].to_i
			asignatura_id = params[:filtro][:asignatura_id].to_i
			@asignatura = Asignatura.find_by_id(asignatura_id)
			@seccion = Seccion.find_by_id(seccion_id)
			if  @filtro[:periodo_id].to_i == Periodo::en_curso.id
				@alumnos = AlumnoInscritoSeccion.all(
													:fields => [:id, :seccion_dictada_id, :alumno_plan_estudio_id,:estado], 
													:seccion_dictada => {
														:seccion_id => @seccion.id,
													}, 
													:alumno_plan_estudio => {
															:estado => [Alumno::REGULAR, Alumno::SIN_MATRICULA, Alumno::SIN_INSCRIPCION]
													},
													:estado.not => AlumnoInscritoSeccion::ABANDONADA
												)
			else
				@alumnos = AlumnoInscritoSeccion.all(   
													:fields => [:id, :seccion_dictada_id, :alumno_plan_estudio_id,:estado],
													:seccion_dictada => {
															:seccion_id => @seccion.id
													},
													:estado.not => AlumnoInscritoSeccion::ABANDONADA

														# , 
														# :alumno_plan_estudio => {
														# 		:estado => [Alumno::REGULAR, Alumno::SIN_INSCRIPCION]
														# }
													)
			end
		end
	end

	private

	def aprobo_con_examen? alumno_inscrito
		
		if alumno_inscrito.es_alumno_distancia?
			nota_final = (alumno_inscrito.nota_presentacion * 0.4 + alumno_inscrito.nota_examen * 0.6).round(1)
		else
			nota_final = (alumno_inscrito.nota_presentacion * 0.6 + alumno_inscrito.nota_examen * 0.4).round(1)
		end

		return (nota_final >= CalificacionParcial::NOTA_MINIMA_APROXIMADA ) ? true : false
	end

	def aprobo_con_examen_repeticion? alumno_inscrito
		if not alumno_inscrito.nota_examen_repeticion.blank?
			nota_final = alumno_inscrito.nota_examen_repeticion

			return (nota_final >= CalificacionParcial::NOTA_MINIMA_APROXIMADA ) ? true : false
		else
			return false
		end
	end

	def se_eximio? alumno_inscrito
		return (alumno_inscrito.nota_presentacion).round(2) >= CalificacionParcial::NOTA_EXIMIDO_APROXIMADA ? true : false
	end

	def a_reprobado? alumno_inscrito
		return (alumno_inscrito.nota_presentacion).round(2) < CalificacionParcial::NOTA_EXAMEN_APROXIMADA ? true : false
	end

	def abandono? alumno_inscrito
		return alumno_inscrito.nota_presentacion == CalificacionParcial::NO_CUMPLE_REQUISITOS ? true : false
	end

	def rindio_examen_repeticion? alumno_inscrito
		return (alumno_inscrito.nota_examen_repeticion != 0.0 ? true : false)
	end

end