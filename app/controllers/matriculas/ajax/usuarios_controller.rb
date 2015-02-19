# encoding: utf-8
require 'json'

class Matriculas::Ajax::UsuariosController < ApplicationController

	layout nil

	def obtener_apoderado
		rut = params[:rut]
		apoderado = Usuario.first :rut => rut

		if apoderado.nil?
			raise Excepciones::DatosNoExistentesError, "No existen registros asociados al rut #{params[:rut]}. Puede ser registrado como apoderado."
		end

		render :json => {
			:mensaje => "La persona con rut #{params[:rut]} ya existe en la institucion y puede ser considerado como apoderado.",
			:data => {
				:id 					=> apoderado.id,
				:primer_nombre 			=> apoderado.primer_nombre,
				:segundo_nombre			=> apoderado.segundo_nombre,
				:apellido_paterno 		=> apoderado.apellido_paterno,
				:apellido_materno 		=> apoderado.apellido_materno,
				:domicilio 				=> apoderado.domicilio,
				:villa_poblacion 		=> apoderado.villa_poblacion,
				:sector 				=> apoderado.sector,
				:codigo_area_telefono	=> apoderado.codigo_area_telefono,
				:telefono_fijo 			=> apoderado.telefono_fijo,
				:telefono_movil 		=> apoderado.telefono_movil,
				:email 					=> apoderado.email,
				:region_id				=> apoderado.region_id,
				:comuna 				=> apoderado.comuna.nombre,
				:comuna_id				=> apoderado.comuna_id,
				:pais_id 				=> apoderado.pais_id
			}
		}

	rescue Excepciones::DatosNoExistentesError => e
		render :json => { :mensaje => e.message }
	end

	def obtener_apoderado_no_alumno
		rut = params[:rut_apoderado]
		id = params[:usuario_alumno_id].to_i
		apoderado = Usuario.first :rut => rut

		if apoderado.nil?
			raise Excepciones::DatosNoExistentesError, "No existen registros asociados al rut #{params[:rut]}. Puede ser registrado como apoderado."
		end

		if apoderado.id == id
			raise Excepciones::OperacionNoPermitidaError, %{La persona registrada con el rut #{rut} es el mismo alumno. Si desea que él sea apoderado de si mismo, 
				utilice la casilla de verificación "El mismo alumno es el apoderado"}
		end

		render :json => {
			:exito 		=> true,
			:mensaje 	=> "La persona con rut #{params[:rut]} ya existe en la institucion y puede ser considerado como apoderado.",
			:data 		=> {
				:id 					=> apoderado.id,
				:primer_nombre 			=> apoderado.primer_nombre,
				:segundo_nombre			=> apoderado.segundo_nombre,
				:apellido_paterno 		=> apoderado.apellido_paterno,
				:apellido_materno 		=> apoderado.apellido_materno,
				:domicilio 				=> apoderado.domicilio,
				:villa_poblacion 		=> apoderado.villa_poblacion,
				:sector					=> apoderado.sector,
				:codigo_area_telefono	=> apoderado.codigo_area_telefono,
				:telefono_fijo 			=> apoderado.telefono_fijo,
				:telefono_movil 		=> apoderado.telefono_movil,
				:email 					=> apoderado.email,
				:region_id				=> apoderado.region_id,
				:comuna 				=> apoderado.comuna.nombre,
				:pais_id 				=> apoderado.pais_id
			}
		}

	rescue Excepciones::DatosNoExistentesError => e
		render :json => { :exito => true, :mensaje => e.message }
	rescue Excepciones::OperacionNoPermitidaError => e
		render :json => { :exito => false, :mensaje => e.message }
	end

	def obtener_postulante_ip
		rut = params[:rut]
		usuario = Usuario.first :rut => rut

		# Postulante que no existe como usuario
		if usuario.nil?
			render :json => { :exito => true, :mensaje	=> "No existen registros asociados al rut #{params[:rut]}. Puede ser matriculado como alumno nuevo." }
			return
		end

		# Usuario alumno
		if usuario.tipo == Usuario::ESTUDIANTE
			alumno = usuario.alumno
			planes_estudiados = alumno.alumno_plan_estudio
			ultimo_año = planes_estudiados.periodo.max(:anio)
			ultimo_semestre = planes_estudiados.periodo.max(:semestre, :conditions => ['anio = ?',ultimo_año])

			ultimo_periodo_estudiado = Periodo.first anio:     ultimo_año,
													 semestre: ultimo_semestre
			
			ultimo_plan = planes_estudiados.select{ |plan| ultimo_periodo_estudiado.id == plan.periodo_id }.max_by{ |plan| plan.created_at }
			institucion = ultimo_plan.institucion_sede_plan.institucion_sede.institucion

				# Para efectuar continuidad de estudios de la carrera técnica al IP o cambios de sede
			if 	(ultimo_plan.estado == Alumno::EGRESADO) or (ultimo_plan.estado == Alumno::CONVALIDADO) or (ultimo_plan.estado == Alumno::TRASLADADO) or

				# Ya estudio un plan y se tituló, o la matrícula fue anulada o se retractó, o paso de curso en el CEIA/Preu
				([Alumno::TITULADO, Alumno::ANULADO, Alumno::RETIRADO, Alumno::PROMOVIDO, Alumno::REPITENCIA].include? ultimo_plan.estado)

				#Alumnos con su información en el sistema nuevo
				unless ultimo_plan.matricula_plan.blank?
					render :json => {
						:exito  		=> true,
						:es_alumno 		=> true,
						:mensaje 		=> "La persona con rut #{params[:rut]} ya existe en la institucion y puede ser matriculado nuevamente.",
						:data 			=> {
							:id 					=> usuario.id,
							:primer_nombre 			=> usuario.primer_nombre,
							:segundo_nombre			=> usuario.segundo_nombre,
							:apellido_paterno 		=> usuario.apellido_paterno,
							:apellido_materno 		=> usuario.apellido_materno,
							:fecha_nacimiento 		=> usuario.fecha_nacimiento,
							:sexo 					=> usuario.sexo,
							:estado_civil 			=> usuario.estado_civil,
							:domicilio 				=> usuario.domicilio,
							:villa_poblacion 		=> usuario.villa_poblacion,
							:sector 				=> usuario.sector,
							:codigo_area_telefono	=> usuario.codigo_area_telefono,
							:telefono_fijo 			=> usuario.telefono_fijo,
							:telefono_movil 		=> usuario.telefono_movil,
							:email 					=> usuario.email,
							:region_id				=> usuario.region_id,
							:comuna 				=> usuario.comuna.nombre,
							:pais_id 				=> usuario.pais_id,
							:alumno_id				=> alumno.id,
							:establecimiento        => alumno.establecimiento_educacional,
							:tipo_establecimiento   => alumno.tipo_establecimiento_educacional,
							:cert_nacimiento        => alumno.tiene_certificado_nacimiento,
							:cert_titulo            => alumno.tiene_certificado_titulo,
							:cert_media             => alumno.tiene_licencia_e_media,
							:estado_plan_anterior   => ultimo_plan.estado,
							:medio			        => ultimo_plan.matricula_plan.first.medio
						}
					}
				#Alumnos que tienen solo hasta su plan de estudio en el sistema
				else
					render :json => {
						:exito  		=> true,
						:es_alumno 		=> true,
						:mensaje 		=> "La persona con rut #{params[:rut]} ya existe en la institucion y puede ser matriculado nuevamente.",
						:data 			=> {
							:id 					=> usuario.id,
							:primer_nombre 			=> usuario.primer_nombre,
							:segundo_nombre			=> usuario.segundo_nombre,
							:apellido_paterno 		=> usuario.apellido_paterno,
							:apellido_materno 		=> usuario.apellido_materno,
							:fecha_nacimiento 		=> usuario.fecha_nacimiento,
							:sexo 					=> usuario.sexo,
							:estado_civil 			=> usuario.estado_civil,
							:domicilio 				=> usuario.domicilio,
							:villa_poblacion 		=> usuario.villa_poblacion,
							:sector 				=> usuario.sector,
							:codigo_area_telefono	=> usuario.codigo_area_telefono,
							:telefono_fijo 			=> usuario.telefono_fijo,
							:telefono_movil 		=> usuario.telefono_movil,
							:email 					=> usuario.email,
							:region_id				=> usuario.region_id,
							:comuna 				=> usuario.comuna.nombre,
							:pais_id 				=> usuario.pais_id,
							:alumno_id				=> alumno.id,
							:establecimiento        => alumno.establecimiento_educacional,
							:tipo_establecimiento   => alumno.tipo_establecimiento_educacional,
							:cert_nacimiento        => alumno.tiene_certificado_nacimiento,
							:cert_titulo            => alumno.tiene_certificado_titulo,
							:cert_media             => alumno.tiene_licencia_e_media,
							:estado_plan_anterior   => ultimo_plan.estado
						}
					}
				end
			else
				unless ultimo_plan.estado.blank?
					raise Excepciones::AlumnoNoMatriculable, "El estado académico (#{ultimo_plan.estado}) de la persona registrada con el rut #{params[:rut]} no le permite matricularse nuevamente."
				else
					raise Excepciones::AlumnoNoMatriculable, "El estado académico de la persona registrada con el rut #{params[:rut]} no le permite matricularse nuevamente."
				end
				
			end

		# Usuario no alumno. Administrativo, docente, y todo lo demás ...
		else
			render :json => {
				:exito  		=> true,
				:es_alumno 		=> false,
				:mensaje 		=> "La persona con rut #{params[:rut]} ya existe en la institucion y puede ser matriculado nuevamente.",
				:data 			=> {
					:id 					=> usuario.id,
					:primer_nombre 			=> usuario.primer_nombre,
					:segundo_nombre			=> usuario.segundo_nombre,
					:apellido_paterno 		=> usuario.apellido_paterno,
					:apellido_materno 		=> usuario.apellido_materno,
					:fecha_nacimiento 		=> usuario.fecha_nacimiento,
					:sexo 					=> usuario.sexo,
					:estado_civil 			=> usuario.estado_civil,
					:domicilio 				=> usuario.domicilio,
					:villa_poblacion 		=> usuario.villa_poblacion,
					:sector 				=> usuario.sector,
					:codigo_area_telefono	=> usuario.codigo_area_telefono,
					:telefono_fijo 			=> usuario.telefono_fijo,
					:telefono_movil 		=> usuario.telefono_movil,
					:email 					=> usuario.email,
					:region_id				=> usuario.region_id,
					:comuna 				=> usuario.comuna.nombre,
					:pais_id 				=> usuario.pais_id
				}
			}
		end

	rescue Excepciones::AlumnoNoMatriculable => e
		render :json => { 
			:exito 		=> false,
			:mensaje	=> e.message
		}
	end

	def obtener_situacion_alumno_ip
		rut = params[:rut]
		sede_id = current_user[:sede_id]

		@usuario_alumno = Usuario.first :rut => rut, :sede_id => sede_id
		@nombre_periodo = periodo_matriculable[:nombre]
		@codigos_fijos = Utils::CodigoTelefonico::FIJOS
		@regiones = Region.all
		@paises = Pais.all
		verificar_morosidad = Rails.configuration.verificar_morosidad_en_matriculas

		if @usuario_alumno.nil?
			raise Excepciones::DatosNoExistentesError, "No existen registros asociados al rut #{rut} o el usuario pertenece a otra sede. No puede ser matriculado como alumno superior."
		end
		
		# Filtro 1: El alumno debe ser "Alumno"
		if not @usuario_alumno.tipo == Usuario::ESTUDIANTE
			raise Excepciones::AlumnoNoMatriculable, "La persona registrada con el rut #{rut} no es estudiante."
		end

		@alumno = @usuario_alumno.alumno
		inscripciones_planes = @alumno.alumno_plan_estudio(
			:estado => Alumno::ALUMNOS_SUPERIORES_MATRICULABLES,
			:institucion_sede_plan 	=> {
				:institucion_sede 	=> {
					:institucion 	=> { :tipo 	=> [Institucion::IP, Institucion::CFT] },
					:sede_id 		=> sede_id
				},
				:periodo 			=> {
					:anio.gte 		=> @alumno.anio_ingreso
				}
			}
		)

		# Filtro 2: El alumno debe tener un plan vigente
		if inscripciones_planes.empty?
			raise Excepciones::AlumnoNoMatriculable, "El alumno con rut #{rut} no posee planes de estudio vigentes en el IP o CFT de esta sede, o su estado académico no le permite matricularse nuevamente."
		end

		@data = []

		instituciones_sedes_planes = inscripciones_planes.institucion_sede_plan
		instituciones_sedes = instituciones_sedes_planes.institucion_sede
		planes_estudio = instituciones_sedes_planes.plan_estudio
		
		# Valores monetarios actuales
		instituciones_sedes_planes_vigentes = InstitucionSedePlan.all(
			:periodo_id 		=> periodo_matriculable[:id], 
			:plan_estudio 		=> planes_estudio, 
			:institucion_sede 	=> instituciones_sedes,
			:modalidad 			=> InstitucionSedePlan::PRESENCIAL,
			:jornada 			=> instituciones_sedes_planes.map{ |i| i.jornada }
		)

		#aranceles = instituciones_sedes_planes_vigentes.aranceles :tipo_alumno => Alumno::SUPERIOR
		aranceles = PrecioArancel.all(
			:tipo_alumno 		=> Alumno::SUPERIOR,
			:modalidad			=> instituciones_sedes_planes.map{|x| x.modalidad},
			:mallas_hash 		=> instituciones_sedes_planes.map{|x| PlanEstudio.buscar_malla(x.plan_estudio_id)},
			:sede_id 			=> sede_id
		)
		
		matriculas = PrecioMatricula.all(
			:fecha_inicio.lte 	=> Date.today,
			:fecha_termino.gt 	=> Date.today,
			:tipo_alumno 		=> Alumno::SUPERIOR,
			:modalidad			=> instituciones_sedes_planes.map{|x| x.modalidad},
			:mallas_hash 		=> instituciones_sedes_planes.map{|x| PlanEstudio.buscar_malla(x.plan_estudio_id)},
			:sede_id 			=> sede_id
		)
		
		valor_error = 99999999

		inscripciones_planes.each do |inscripcion_plan|
			institucion_sede_plan = instituciones_sedes_planes.select{ |i| i.id == inscripcion_plan.institucion_sede_plan_id }.first
			plan = planes_estudio.select{ |i| i.id == institucion_sede_plan.plan_estudio_id }.first
			institucion_sede = instituciones_sedes.select{ |i| i.id == institucion_sede_plan.institucion_sede_id }.first
			
			institucion_sede_plan_vigente = instituciones_sedes_planes_vigentes.select{ |i| plan.id == i.plan_estudio_id }.first

			# Aranceles profesionales
			arancel_dos_semestres_profesional 			= nil
			arancel_dos_semestres_profesional_contado	= nil
			arancel_salida_intermedia 					= nil
			arancel_salida_intermedia_contado 			= nil

			# Aranceles tecnicos
			arancel_dos_semestres_tecnico 				= nil
			arancel_dos_semestres_tecnico_contado 		= nil
			arancel_practica_trabajo_titulo 			= nil
			arancel_practica_trabajo_titulo_contado 	= nil

			# Aranceles distancia
			arancel_distancia_1_a_4 					= nil
			arancel_distancia_5_a_8 					= nil

			repactacion 								= nil

			# Aqui se verifica la morosidad
			informacion_administrativa = {}
			if verificar_morosidad
				matriculas_plan = inscripcion_plan.matricula_plan
				ultimo_año_matricula = matriculas_plan.periodo.map(&:anio).to_a.max{ |p1, p2| p1 <=> p2}				
				ultimo_periodo_matricula = matriculas_plan.periodo(anio: ultimo_año_matricula).to_a.max{ |p1, p2| p1.anio + p1.semestre <=> p2.anio + p2.semestre }
				ultima_matricula = ultimo_periodo_matricula.matriculas(:alumno_plan_estudio => inscripcion_plan, :estado.not => MatriculaPlan::ANULADA).last
				# Ultimo plan
				ultimo_plan = ultima_matricula.planes_pago.last
				pagos     = ultimo_plan.pagos_comprometidos(:saldo.not => 0,:estado.not => [PagoComprometido::ANULADO,PagoComprometido::REPACTADO])
				repactacion = ultimo_plan.pagos_comprometidos(:estado => [PagoComprometido::REPACTADO]).sum(:saldo)
				
				repactacion = 0 if repactacion.blank?
					
				atrasados = []

				pagos.each do |pago|
					if pago.fecha_vencimiento_con_prorroga <= Date.today
						atrasados << pago
					end
				end
				
				es_moroso = atrasados.count > 0
				
				if es_moroso
					informacion_administrativa = {
						:es_moroso 		=> true,
						:matricula 		=> ultima_matricula.id,
						:plan_pago 		=> ultimo_plan.id,
						:periodo 		=> ultimo_plan.periodo.nombre,
						:pagare 		=> (not atrasados.first.pagare_id.nil?) ? atrasados.first.pagare.numero : nil,
						:cuota 			=> atrasados.first
					}
				else
					informacion_administrativa = { :es_moroso => false }
				end
			else
				informacion_administrativa = { :es_moroso => false }
			end

			case plan.nivel
			when PlanEstudio::TECNICO then
				arancel_dos_semestres_tecnico = (a = aranceles.select{ |i| 
					PlanEstudio.buscar_malla(plan.id)   == i.mallas_hash and
					#institucion_sede_plan_vigente.id 	== i.institucion_sede_plan_id and 
					i.tipo 								== MatriculaPlan::TECNICA_DOS_SEMESTRES and 
					i.contado 							== false 
				}.first).blank? ? valor_error : a.precio

				arancel_dos_semestres_tecnico_contado = (ac = aranceles.select{ |i| 
					PlanEstudio.buscar_malla(plan.id)   == i.mallas_hash and
					#institucion_sede_plan_vigente.id 	== i.institucion_sede_plan_id and 
					i.tipo 								== MatriculaPlan::TECNICA_DOS_SEMESTRES and 
					i.contado 							== true 
				}.first).blank? ? valor_error : ac.precio

				arancel_practica_trabajo_titulo = (apt = aranceles.select{ |i| 
					PlanEstudio.buscar_malla(plan.id)   == i.mallas_hash and
					#institucion_sede_plan_vigente.id 	== i.institucion_sede_plan_id and 
					i.tipo 								== MatriculaPlan::PRACTICA_TRABAJO_DE_TITULO and 
					i.contado 							== false 
				}.first).blank? ? valor_error : apt.precio

				arancel_practica_trabajo_titulo_contado = (aptc = aranceles.select{ |i| 
					PlanEstudio.buscar_malla(plan.id)   == i.mallas_hash and
					#institucion_sede_plan_vigente.id 	== i.institucion_sede_plan_id and 
					i.tipo 								== MatriculaPlan::PRACTICA_TRABAJO_DE_TITULO and 
					i.contado 							== true 
				}.first).blank? ? valor_error : aptc.precio

			when PlanEstudio::PROFESIONAL then
				case institucion_sede_plan.modalidad
				when InstitucionSedePlan::PRESENCIAL then
					arancel_dos_semestres_profesional = (tmp = aranceles.select{ |i| 
						PlanEstudio.buscar_malla(plan.id)   == i.mallas_hash and
						#institucion_sede_plan_vigente.id 	== i.institucion_sede_plan_id and 
						i.tipo 								== MatriculaPlan::PROFESIONAL_DOS_SEMESTRES and 
						i.contado 							== false 
					}.first).blank? ? valor_error : tmp.precio

					arancel_dos_semestres_profesional_contado = (tmp = aranceles.select{ |i| 
						PlanEstudio.buscar_malla(plan.id)   == i.mallas_hash and
						#institucion_sede_plan_vigente.id 	== i.institucion_sede_plan_id and 
						i.tipo 								== MatriculaPlan::PROFESIONAL_DOS_SEMESTRES and 
						i.contado 							== true 
					}.first).blank? ? valor_error : tmp.precio

					arancel_salida_intermedia = (tmp = aranceles.select{ |i| 
						PlanEstudio.buscar_malla(plan.id)   == i.mallas_hash and
						#institucion_sede_plan_vigente.id 	== i.institucion_sede_plan_id and 
						i.tipo 								== MatriculaPlan::SALIDA_INTERMEDIA and 
						i.contado 							== false 
					}.first).blank? ? valor_error : tmp.precio

					arancel_salida_intermedia_contado = (tmp = aranceles.select{ |i| 
						PlanEstudio.buscar_malla(plan.id)   == i.mallas_hash and
						#institucion_sede_plan_vigente.id 	== i.institucion_sede_plan_id and 
						i.tipo 								== MatriculaPlan::SALIDA_INTERMEDIA and 
						i.contado 							== true 
					}.first).blank? ? valor_error : tmp.precio

				when InstitucionSedePlan::DISTANCIA
					arancel_distancia_1_a_4 = (tmp = aranceles.select{ |i| 
						PlanEstudio.buscar_malla(plan.id)   == i.mallas_hash and
						#institucion_sede_plan_vigente.id 	== i.institucion_sede_plan_id and 
						i.tipo 								== MatriculaPlan::DISTANCIA_1_A_4_NIVEL and 
						i.contado 							== false 
					}.first).blank? ? valor_error : tmp.precio

					arancel_distancia_5_a_8 = (tmp = aranceles.select{ |i| 
						PlanEstudio.buscar_malla(plan.id)   == i.mallas_hash and
						#institucion_sede_plan_vigente.id 	== i.institucion_sede_plan_id and 
						i.tipo 								== MatriculaPlan::DISTANCIA_5_A_8_NIVEL and 
						i.contado 							== false 
					}.first).blank? ? valor_error : tmp.precio
					
				end
			end

			#matricula = (tmp = matriculas.select{ |i| 	institucion_sede_plan_vigente.id 	== i.institucion_sede_plan_id }.first).blank? ? valor_error : tmp.precio
			matricula = (tmp = matriculas.first).blank? ? valor_error : tmp.precio

			@data << {
				:alumno_plan_estudio 						=> inscripcion_plan,
				:institucion_sede_plan 						=> institucion_sede_plan,
				:institucion_sede 							=> institucion_sede,
				:es_moroso 									=> es_moroso,
				:plan 										=> plan,
				:repactacion 								=> repactacion,
				:matricula 									=> matricula,

				# Precios profesionales
				:arancel_dos_semestres_profesional 			=> arancel_dos_semestres_profesional,
				:arancel_dos_semestres_profesional_contado	=> arancel_dos_semestres_profesional_contado,
				:arancel_salida_intermedia 					=> arancel_salida_intermedia,
				:arancel_salida_intermedia_contado 			=> arancel_salida_intermedia_contado,

				# Precios tecnicos
				:arancel_dos_semestres_tecnico 				=> arancel_dos_semestres_tecnico,
				:arancel_dos_semestres_tecnico_contado 		=> arancel_dos_semestres_tecnico_contado,
				:arancel_practica_trabajo_titulo 			=> arancel_practica_trabajo_titulo,
				:arancel_practica_trabajo_titulo_contado 	=> arancel_practica_trabajo_titulo_contado,

				# Precios distancia
				:arancel_distancia_1_a_4 					=> arancel_distancia_1_a_4,
				:arancel_distancia_5_a_8 					=> arancel_distancia_5_a_8
			}.merge(informacion_administrativa)		
		end

	rescue Excepciones::AlumnoNoMatriculable => e
		puts e.message
		puts e.backtrace
		render :partial => 'partials/notificaciones/error', locals: { mensaje: e.message }
		return

	rescue Excepciones::DatosNoExistentesError => e
		puts e.message
		puts e.backtrace
		render :partial => 'partials/notificaciones/error', locals: { mensaje: e.message }
		return

	rescue Exception => e
		puts e.message
		puts e.backtrace
		render :partial => 'partials/notificaciones/error', locals: { mensaje: e.message }
		return
	end

	def obtener_situacion_alumno_extension
		rut = params[:rut]
		sede_id = current_user[:sede_id]

		@usuario_alumno = Usuario.first :rut => rut, :sede_id => sede_id
		@nombre_periodo = periodo_matriculable[:nombre]
		@codigos_fijos = Utils::CodigoTelefonico::FIJOS
		@regiones = Region.all
		@paises = Pais.all
		verificar_morosidad = Rails.configuration.verificar_morosidad_en_matriculas

		if @usuario_alumno.nil?
			raise Excepciones::DatosNoExistentesError, "No existen registros asociados al rut #{rut} o el usuario pertenece a otra sede. No puede ser matriculado como alumno superior."
		end
		
		# Filtro 1: El alumno debe ser "Alumno"
		if not @usuario_alumno.tipo == Usuario::ESTUDIANTE
			raise Excepciones::AlumnoNoMatriculable, "La persona registrada con el rut #{rut} no es estudiante."
		end

		@alumno = @usuario_alumno.alumno
		inscripciones_planes = @alumno.alumno_plan_estudio(
			:estado => Alumno::ALUMNOS_SUPERIORES_MATRICULABLES,
			:institucion_sede_plan 	=> {
				:institucion_sede 	=> {
					:institucion 	=> { :tipo 	=> [Institucion::IP, Institucion::CFT] },
					:sede_id 		=> sede_id
				},
				:periodo 			=> {
					:anio.gte 		=> @alumno.anio_ingreso
				}
			}
		)

		# Filtro 2: El alumno debe tener un plan vigente
		if inscripciones_planes.empty?
			raise Excepciones::AlumnoNoMatriculable, "El alumno con rut #{rut} no posee planes de estudio vigentes en el IP o CFT de esta sede, o su estado académico no le permite matricularse nuevamente."
		end

		@data = []

		instituciones_sedes_planes = inscripciones_planes.institucion_sede_plan
		instituciones_sedes = instituciones_sedes_planes.institucion_sede
		planes_estudio = instituciones_sedes_planes.plan_estudio
		
		# Valores monetarios actuales
		instituciones_sedes_planes_vigentes = InstitucionSedePlan.all(
			:periodo_id 		=> periodo_matriculable[:id], 
			:plan_estudio 		=> planes_estudio, 
			:institucion_sede 	=> instituciones_sedes,
			:modalidad 			=> InstitucionSedePlan::PRESENCIAL,
			:jornada 			=> instituciones_sedes_planes.map{ |i| i.jornada }
		)

		#aranceles = instituciones_sedes_planes_vigentes.aranceles :tipo_alumno => Alumno::SUPERIOR
		aranceles = PrecioArancel.all(
			:tipo_alumno 		=> Alumno::SUPERIOR,
			:modalidad			=> instituciones_sedes_planes.map{|x| x.modalidad},
			:mallas_hash 		=> instituciones_sedes_planes.map{|x| PlanEstudio.buscar_malla(x.plan_estudio_id)},
			:sede_id 			=> sede_id
		)
		
		matriculas = PrecioMatricula.all(
			:fecha_inicio.lte 	=> Date.today,
			:fecha_termino.gt 	=> Date.today,
			:tipo_alumno 		=> Alumno::SUPERIOR,
			:modalidad			=> instituciones_sedes_planes.map{|x| x.modalidad},
			:mallas_hash 		=> instituciones_sedes_planes.map{|x| PlanEstudio.buscar_malla(x.plan_estudio_id)},
			:sede_id 			=> sede_id
		)

		valor_error = 99999999

		inscripciones_planes.each do |inscripcion_plan|
			institucion_sede_plan = instituciones_sedes_planes.select{ |i| i.id == inscripcion_plan.institucion_sede_plan_id }.first
			plan = planes_estudio.select{ |i| i.id == institucion_sede_plan.plan_estudio_id }.first
			institucion_sede = instituciones_sedes.select{ |i| i.id == institucion_sede_plan.institucion_sede_id }.first
			
			institucion_sede_plan_vigente = instituciones_sedes_planes_vigentes.select{ |i| plan.id == i.plan_estudio_id }.first

			# Aranceles profesionales
			arancel_dos_semestres_profesional 			= nil
			arancel_dos_semestres_profesional_contado	= nil
			arancel_salida_intermedia 					= nil
			arancel_salida_intermedia_contado 			= nil

			# Aranceles tecnicos
			arancel_dos_semestres_tecnico 				= nil
			arancel_dos_semestres_tecnico_contado 		= nil
			arancel_practica_trabajo_titulo 			= nil
			arancel_practica_trabajo_titulo_contado 	= nil

			# Aranceles distancia
			arancel_distancia_1_a_4 					= nil
			arancel_distancia_5_a_8 					= nil

			repactacion 								= nil

			# Aqui se verifica la morosidad
			informacion_administrativa = {}
			if verificar_morosidad
				matriculas_plan = inscripcion_plan.matricula_plan
				ultimo_año_matricula = matriculas_plan.periodo.map(&:anio).to_a.max{ |p1, p2| p1 <=> p2}				
				ultimo_periodo_matricula = matriculas_plan.periodo(anio: ultimo_año_matricula).to_a.max{ |p1, p2| p1.anio + p1.semestre <=> p2.anio + p2.semestre }
				ultima_matricula = ultimo_periodo_matricula.matriculas(:alumno_plan_estudio => inscripcion_plan, :estado.not => MatriculaPlan::ANULADA).last
				# Ultimo plan
				ultimo_plan = ultima_matricula.planes_pago.last
				pagos     = ultimo_plan.pagos_comprometidos(:saldo.not => 0,:estado.not => [PagoComprometido::ANULADO,PagoComprometido::REPACTADO])
				repactacion = ultimo_plan.pagos_comprometidos(:estado => [PagoComprometido::REPACTADO]).sum(:saldo)
				puts ultimo_plan.inspect.blue
				repactacion = 0 if repactacion.blank?

				atrasados = []

				pagos.each do |pago|
					if pago.fecha_vencimiento_con_prorroga <= Date.today
						atrasados << pago
					end
				end
				
				es_moroso = atrasados.count > 0
				
				if es_moroso
					informacion_administrativa = {
						:es_moroso 		=> true,
						:matricula 		=> ultima_matricula.id,
						:plan_pago 		=> ultimo_plan.id,
						:periodo 		=> ultimo_plan.periodo.nombre,
						:pagare 		=> (not atrasados.first.pagare_id.nil?) ? atrasados.first.pagare.numero : nil,
						:cuota 			=> atrasados.first
					}
				else
					informacion_administrativa = { :es_moroso => false }
				end
			else
				informacion_administrativa = { :es_moroso => false }
			end

			case plan.nivel
			when PlanEstudio::TECNICO then
				arancel_dos_semestres_tecnico = (a = aranceles.select{ |i| 
					PlanEstudio.buscar_malla(plan.id)   == i.mallas_hash and
					#institucion_sede_plan_vigente.id 	== i.institucion_sede_plan_id and 
					i.tipo 								== MatriculaPlan::TECNICA_DOS_SEMESTRES and 
					i.contado 							== false 
				}.first).blank? ? valor_error : a.precio

				arancel_dos_semestres_tecnico_contado = (ac = aranceles.select{ |i| 
					PlanEstudio.buscar_malla(plan.id)   == i.mallas_hash and
					#institucion_sede_plan_vigente.id 	== i.institucion_sede_plan_id and 
					i.tipo 								== MatriculaPlan::TECNICA_DOS_SEMESTRES and 
					i.contado 							== true 
				}.first).blank? ? valor_error : ac.precio

				arancel_practica_trabajo_titulo = (apt = aranceles.select{ |i| 
					PlanEstudio.buscar_malla(plan.id)   == i.mallas_hash and
					#institucion_sede_plan_vigente.id 	== i.institucion_sede_plan_id and 
					i.tipo 								== MatriculaPlan::PRACTICA_TRABAJO_DE_TITULO and 
					i.contado 							== false 
				}.first).blank? ? valor_error : apt.precio

				arancel_practica_trabajo_titulo_contado = (aptc = aranceles.select{ |i| 
					PlanEstudio.buscar_malla(plan.id)   == i.mallas_hash and
					#institucion_sede_plan_vigente.id 	== i.institucion_sede_plan_id and 
					i.tipo 								== MatriculaPlan::PRACTICA_TRABAJO_DE_TITULO and 
					i.contado 							== true 
				}.first).blank? ? valor_error : aptc.precio

			when PlanEstudio::PROFESIONAL then
				case institucion_sede_plan.modalidad
				when InstitucionSedePlan::PRESENCIAL then
					arancel_dos_semestres_profesional = (tmp = aranceles.select{ |i| 
						PlanEstudio.buscar_malla(plan.id)   == i.mallas_hash and
						#institucion_sede_plan_vigente.id 	== i.institucion_sede_plan_id and 
						i.tipo 								== MatriculaPlan::PROFESIONAL_DOS_SEMESTRES and 
						i.contado 							== false 
					}.first).blank? ? valor_error : tmp.precio

					arancel_dos_semestres_profesional_contado = (tmp = aranceles.select{ |i| 
						PlanEstudio.buscar_malla(plan.id)   == i.mallas_hash and
						#institucion_sede_plan_vigente.id 	== i.institucion_sede_plan_id and 
						i.tipo 								== MatriculaPlan::PROFESIONAL_DOS_SEMESTRES and 
						i.contado 							== true 
					}.first).blank? ? valor_error : tmp.precio

					arancel_salida_intermedia = (tmp = aranceles.select{ |i| 
						PlanEstudio.buscar_malla(plan.id)   == i.mallas_hash and
						#institucion_sede_plan_vigente.id 	== i.institucion_sede_plan_id and 
						i.tipo 								== MatriculaPlan::SALIDA_INTERMEDIA and 
						i.contado 							== false 
					}.first).blank? ? valor_error : tmp.precio

					arancel_salida_intermedia_contado = (tmp = aranceles.select{ |i| 
						PlanEstudio.buscar_malla(plan.id)   == i.mallas_hash and
						#institucion_sede_plan_vigente.id 	== i.institucion_sede_plan_id and 
						i.tipo 								== MatriculaPlan::SALIDA_INTERMEDIA and 
						i.contado 							== true 
					}.first).blank? ? valor_error : tmp.precio

				when InstitucionSedePlan::DISTANCIA
					arancel_distancia_1_a_4 = (tmp = aranceles.select{ |i| 
						PlanEstudio.buscar_malla(plan.id)   == i.mallas_hash and
						#institucion_sede_plan_vigente.id 	== i.institucion_sede_plan_id and 
						i.tipo 								== MatriculaPlan::DISTANCIA_1_A_4_NIVEL and 
						i.contado 							== false 
					}.first).blank? ? valor_error : tmp.precio

					arancel_distancia_5_a_8 = (tmp = aranceles.select{ |i| 
						PlanEstudio.buscar_malla(plan.id)   == i.mallas_hash and
						#institucion_sede_plan_vigente.id 	== i.institucion_sede_plan_id and 
						i.tipo 								== MatriculaPlan::DISTANCIA_5_A_8_NIVEL and 
						i.contado 							== false 
					}.first).blank? ? valor_error : tmp.precio
					
				end
			end

			#matricula = (tmp = matriculas.select{ |i| 	institucion_sede_plan_vigente.id 	== i.institucion_sede_plan_id }.first).blank? ? valor_error : tmp.precio
			matricula = (tmp = matriculas.first).blank? ? valor_error : tmp.precio

			@data << {
				:alumno_plan_estudio 						=> inscripcion_plan,
				:institucion_sede_plan 						=> institucion_sede_plan,
				:institucion_sede 							=> institucion_sede,
				:es_moroso 									=> es_moroso,
				:plan 										=> plan,
				:matricula 									=> 0,
				:repactacion 								=> repactacion,
				
				# Precios profesionales
				:arancel_dos_semestres_profesional 			=> arancel_dos_semestres_profesional,
				:arancel_dos_semestres_profesional_contado	=> arancel_dos_semestres_profesional_contado,
				:arancel_salida_intermedia 					=> arancel_salida_intermedia,
				:arancel_salida_intermedia_contado 			=> arancel_salida_intermedia_contado,

				# Precios tecnicos
				:arancel_dos_semestres_tecnico 				=> arancel_dos_semestres_tecnico,
				:arancel_dos_semestres_tecnico_contado 		=> arancel_dos_semestres_tecnico_contado,
				:arancel_practica_trabajo_titulo 			=> arancel_practica_trabajo_titulo,
				:arancel_practica_trabajo_titulo_contado 	=> arancel_practica_trabajo_titulo_contado,

				# Precios distancia
				:arancel_distancia_1_a_4 					=> arancel_distancia_1_a_4,
				:arancel_distancia_5_a_8 					=> arancel_distancia_5_a_8
			}.merge(informacion_administrativa)		
		end

	rescue Excepciones::AlumnoNoMatriculable => e
		puts e.message
		puts e.backtrace
		render :partial => 'partials/notificaciones/error', locals: { mensaje: e.message }
		return

	rescue Excepciones::DatosNoExistentesError => e
		puts e.message
		puts e.backtrace
		render :partial => 'partials/notificaciones/error', locals: { mensaje: e.message }
		return

	rescue Exception => e
		puts e.message
		puts e.backtrace
		render :partial => 'partials/notificaciones/error', locals: { mensaje: e.message }
		return
	end

	def verificar_existencia_alumno
		rut = params[:rut]
		id = params[:id]
		alumno = Usuario.first :tipo => Usuario::ESTUDIANTE, :rut => rut, :id.not => id

		if alumno.nil?
			render :json => {
				:exito 		=> true,
				:mensaje 	=> "No existe otra persona registrada con el rut #{rut}. Puede continuar con el procedimiento."
			}
		else
			render :json => {
				:exito 		=> false,
				:mensaje 	=> "Ya existe una persona con el rut #{rut}."
			}
		end
		return
	end
end