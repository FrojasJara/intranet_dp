# encoding: utf-8
class Cobranzas::MorososController < ApplicationController
	before_filter :iniciar
	protect_from_forgery :except => [:guardar]

	def iniciar
        @usuario              = current_user_object
        @ejecutivo_matriculas = @usuario.ejecutivo_matriculas

        unless params[:rut].blank?
            @us_alumno    = Usuario.first rut: params[:rut]
            @alumno       = @us_alumno.alumno if @us_alumno
            @apoderado    = Apoderado.first id: @alumno.apoderado_id if @alumno
            @us_apoderado = Usuario.first id: @apoderado.usuario_id if @apoderado
        end
    end

	def index
		@sedes = Sede.all fields: [:id, :nombre]
		@instituciones = Institucion.all fields: [:id, :nombre]

		@planes_estudios = params[:sede].blank? ? [] : PlanEstudio.all( fields: [:id, :nombre, :revision, :anio_inicio, :anio_fin], institucion_sede_plan: {
					institucion_sede: {sede_id: params[:sede]},
					estado: PlanEstudio::VIGENTE
				}, order: [:anio_inicio.desc])
		periodos = Periodo.all fields: [:id, :anio, :semestre],
							   :estado.not => Periodo::PROXIMO

		@periodos = periodos.to_a.sort!{|a,b| a.nombre <=> b.nombre}
		@periodos = @periodos.reverse
		
		@años = Periodo.all fields: [:anio],
							unique: true,
							order: :anio.desc,
						    :estado.not => Periodo::PROXIMO
		@meses = []
		(0..11).each {|m| @meses << %w(Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre) [m]}
	end

	def todos
		prms          = params[:todos]

		@institucion  = Institucion.get prms[:institucion]
		@sede         = Sede.get prms[:sede]
		@modalidad    = prms[:modalidad]
		@periodo      = Periodo.get prms[:periodo]
		except_alumno = ""

		filtro_pagos_comprometidos = {
			:estado.not => [PagoComprometido::ANULADO, PagoComprometido::PAGADO],
			:saldo.not => 0,
			:fecha_vencimiento.lte => Date.today
		}

		filtro_institucion_sede_plan = {
			modalidad: prms[:modalidad],
			institucion_sede: {
				sede_id: prms[:sede].to_i,
				institucion_id: prms[:institucion].to_i,
			}
		}

		alumnos_plan_estudios = AlumnoPlanEstudio.all({
			institucion_sede_plan: filtro_institucion_sede_plan,
			matricula_plan: {
				periodo_id: @periodo.id,
				planes_pago: {
					pagos_comprometidos: filtro_pagos_comprometidos,
				}
			}
		})
		
		alumnos                 = alumnos_plan_estudios.alumnos
		usuarios                = alumnos.datos_personales
		institucion_sede_planes = alumnos_plan_estudios.institucion_sede_plan
		planes_estudios         = institucion_sede_planes.plan_estudio
		matricula_planes 	    = alumnos_plan_estudios.matricula_plan
		planes_pago             = matricula_planes.planes_pago( periodo_id: prms[:periodo] )
		pagos_comprometidos 	= planes_pago.pagos_comprometidos( {fields: [:plan_pago_id, :monto, :saldo]}.merge filtro_pagos_comprometidos )

		@datos = []

		alumnos_plan_estudios.each do |ape|
			except_alumno = ape.alumno.datos_personales.rut
			
			alumno    = alumnos.select{|a| a.id == ape.alumno_id}.first
			usuario   = usuarios.select{|u|  u.id == alumno.usuario_id}.first
			ins_se_pl = institucion_sede_planes.select{|i| i.id == ape.institucion_sede_plan_id}.first
			plan_est  = planes_estudios.select{|p| p.id == ins_se_pl.plan_estudio_id}.first
			mat_plan  = matricula_planes.select{|m| m.alumno_plan_estudio_id == ape.id}

			pl_pgs = []
			mat_plan.each do |mp|
				planes_pago.select{|pp| pp.matricula_plan_id == mp.id}.each do |pp|
					pl_pgs << pp
				end
			end
			total_comprometido = 0
			total_saldo        = 0
			cantidad_cuotas    = 0

			pl_pgs.each do |pp|
				pagos_comprometidos.select{|pc| pc.plan_pago_id == pp.id}.each do |pc|
					cantidad_cuotas    += 1
					total_comprometido += pc.monto
					total_saldo        += pc.saldo
				end
			end
			#

			# ape.matricula_plan.planes_pago.each do |pp|
			# 	atrs = pp.atrasados
			# 	atrasadas += atrs.to_a unless atrs.blank?
			
			# end

			@datos << {
				:rut                => usuario.rut,
				:nombres            => usuario.nombres,
				:apellidos          => usuario.apellidos,
				:email 				=> usuario.email,
				:telefono 			=> usuario.telefono_fijo_completo,
				:celular 			=> usuario.telefono_movil,
				:carrera            => "#{plan_est.nombre}",
				:anio_ingreso		=> ape.anio_ingreso,
				:nivel				=> pl_pgs.last.nivel,
				:estado				=> ape.estado_alumno(ape.estado),
				:total_comprometido => total_comprometido,
				:total_saldo        => total_saldo,
				:cantidad			=> cantidad_cuotas
			}
		end

		rescue Exception => e
    		flash[:error] = "El alumno de rut #{except_alumno}, presenta problemas en su información, comunicarse con sistemas "
    		redirect_to cobranzas_morosos_informe_path
	end

		

	def informe
		if params[:filtro][:periodo].blank? or params[:filtro][:plan_estudio].blank? or params[:filtro][:sede].blank?
			flash[:error] = "No seleccionó los filtros correspondientes"
			redirect_to cobranzas_morosos_informe_path
		end


		# @items = PagoComprometido.all(
		# 	:plan_pago => {
		# 		:matricula_plan => { 
		# 			:periodo_id => params[:filtro][:periodo],
		# 			:alumno_plan_estudio => {
		# 				:institucion_sede_plan => {
		# 					:plan_estudio_id => params[:filtro][:plan_estudio],
		# 					:institucion_sede => {
		# 						:sede_id => params[:filtro][:sede]
		# 					}
		# 				}
		# 			}
		# 		}
		# 	}
		# ).plan_pago
		# 	pagos_comprometidos: {
		# 		:fecha_vencimiento.not => nil, :fecha_pago_realizado => nil
		# 	}

		# )
		#debugger

	#	@usuarios = @items.matricula_plan.alumno_plan_estudio.alumno.datos_personales

		#debugger
	end

	def resumen
		prms = params[:todos]

		@institucion = Institucion.get prms[:institucion]
		@sede        = Sede.get prms[:sede]
		@modalidad   = prms[:modalidad]
		@año         = prms[:anio]
		@mes         = prms[:mes]

		# filtro_pagos_comprometidos = {
		# 	:estado.not => [PagoComprometido::ANULADO, PagoComprometido::PAGADO],
		# 	:saldo.not => 0,
		# 	:fecha_vencimiento.lte => Date.today
		# }

		filtro_pagos_comprometidos = {
			:estado.not => PagoComprometido::ANULADO,
			:fecha_vencimiento.gte => Date.civil(@año.to_i, @mes.to_i, 1),
			:fecha_vencimiento.lte => Date.civil(@año.to_i, @mes.to_i, -1)
		}
		
		alumnos_plan_estudios = AlumnoPlanEstudio.all({
			institucion_sede_plan: {
				modalidad: prms[:modalidad],
				institucion_sede: {
					institucion_id: prms[:institucion].to_i,
					sede_id: prms[:sede].to_i,
				}
			},
			matricula_plan: {
				planes_pago: {
					pagos_comprometidos: filtro_pagos_comprometidos
				}
			}
		})

		#alumnos                 = alumnos_plan_estudios.alumnos
		#usuarios                = alumnos.datos_personales
		institucion_sede_planes = alumnos_plan_estudios.institucion_sede_plan
		planes_estudios         = institucion_sede_planes.plan_estudio
		matricula_planes 	    = alumnos_plan_estudios.matricula_plan
		planes_pago             = matricula_planes.planes_pago
		pagos_comprometidos 	= planes_pago.pagos_comprometidos( {fields: [:id, :plan_pago_id, :monto, :saldo]}.merge filtro_pagos_comprometidos )
		prorrogas 				= Prorroga.all pago_comprometido_id: pagos_comprometidos.map{|x| x.id}, :fecha.gte => Date.civil(@año.to_i, @mes.to_i, -1)
		
		# logger.info "Prorrogas: #{prorrogas.inspect}".bold.red

		@resumen = {}

		alumnos_plan_estudios.each do |ape|
			#alumno    = alumnos.select{|a| a.id == ape.alumno_id}.first
			#usuario   = usuarios.select{|u|  u.id == alumno.usuario_id}.first
			ins_se_pl = institucion_sede_planes.select{|i| i.id == ape.institucion_sede_plan_id}.first
			plan_est  = planes_estudios.select{|p| p.id == ins_se_pl.plan_estudio_id}.first
			mat_plan  = matricula_planes.select{|m| m.alumno_plan_estudio_id == ape.id}

			pl_pgs = []
			mat_plan.each do |mp|
				planes_pago.select{|pp| pp.matricula_plan_id == mp.id}.each do |pp|
					pl_pgs << pp
				end
			end
			total_comprometido = 0
			total_saldo        = 0
			cantidad_cuotas    = 0
			morosidad          = 0
			prorroga           = 0

			pl_pgs.each do |pp|
				pagos_comprometidos.select{|pc| pc.plan_pago_id == pp.id}.each do |pc|
					cantidad_cuotas    += 1
					total_comprometido += pc.monto
					total_saldo        += pc.saldo

					tmp = prorrogas.select{ |x| x.pago_comprometido_id.eql?(pc.id) }

					# logger.info "Prorrogas: #{prorrogas.inspect}\n busqueda: #{tmp.inspect}".bold.red
					if tmp.blank?
						morosidad += pc.saldo
					else
						prorroga += pc.saldo
					end
				end
			end
			#

			# ape.matricula_plan.planes_pago.each do |pp|
			# 	atrs = pp.atrasados
			# 	atrasadas += atrs.to_a unless atrs.blank?
			
			# end
			plan_est = PlanEstudio.new(id: 0, nombre: 'Sin definir') if plan_est.blank?

			if @resumen[plan_est.nombre].blank?
				@resumen[plan_est.nombre] = {
					carrera: "#{plan_est.nombre}",
					alumnos: 0,
					morosos: 0,
					comprometido: 0,
					cancelado: 0,
					por_cancelar: 0,
					morosidad: 0,
					prorroga: 0
				} 
			end

			@resumen[plan_est.nombre][:alumnos] += 1
			if total_saldo > 0
				@resumen[plan_est.nombre][:morosos] += 1
			end
			@resumen[plan_est.nombre][:comprometido] += total_comprometido
			@resumen[plan_est.nombre][:cancelado] += (total_comprometido-total_saldo)
			@resumen[plan_est.nombre][:por_cancelar] += total_saldo
			@resumen[plan_est.nombre][:morosidad] += morosidad
			@resumen[plan_est.nombre][:prorroga] += prorroga
		end
	end

	def carrera
		@institucion  = Institucion.get params[:institucion]
		@sede         = Sede.get params[:sede]
		@modalidad    = params[:modalidad]
		@año          = params[:anio]
		@mes          = params[:mes]
		@plan         = params[:plan]

		filtro_pagos_comprometidos = {
			:estado.not => [PagoComprometido::ANULADO, PagoComprometido::PAGADO],
			:saldo.not => 0,
			:fecha_vencimiento.gte => Date.civil(@año.to_i, @mes.to_i, 1),
			:fecha_vencimiento.lte => Date.civil(@año.to_i, @mes.to_i, -1)
		}

		filtro_institucion_sede_plan = {
			modalidad: params[:modalidad],
			institucion_sede: {
				sede_id: params[:sede].to_i,
				institucion_id: params[:institucion].to_i,
			},
			plan_estudio: {
				nombre: params[:plan]
			}
		}

		alumnos_plan_estudios = AlumnoPlanEstudio.all({
			institucion_sede_plan: filtro_institucion_sede_plan,
			matricula_plan: {
				planes_pago: {
					pagos_comprometidos: filtro_pagos_comprometidos,
				}
			}
		})
		
		alumnos                 = alumnos_plan_estudios.alumnos
		usuarios                = alumnos.datos_personales
		institucion_sede_planes = alumnos_plan_estudios.institucion_sede_plan
		planes_estudios         = institucion_sede_planes.plan_estudio
		matricula_planes 	    = alumnos_plan_estudios.matricula_plan
		planes_pago             = matricula_planes.planes_pago
		pagos_comprometidos 	= planes_pago.pagos_comprometidos( {fields: [:plan_pago_id, :monto, :saldo]}.merge filtro_pagos_comprometidos )

		@datos = []

		alumnos_plan_estudios.each do |ape|
			alumno    = alumnos.select{|a| a.id == ape.alumno_id}.first
			usuario   = usuarios.select{|u|  u.id == alumno.usuario_id}.first
			ins_se_pl = institucion_sede_planes.select{|i| i.id == ape.institucion_sede_plan_id}.first
			plan_est  = planes_estudios.select{|p| p.id == ins_se_pl.plan_estudio_id}.first
			mat_plan  = matricula_planes.select{|m| m.alumno_plan_estudio_id == ape.id}

			pl_pgs = []
			mat_plan.each do |mp|
				planes_pago.select{|pp| pp.matricula_plan_id == mp.id}.each do |pp|
					pl_pgs << pp
				end
			end
			total_comprometido = 0
			total_saldo        = 0
			cantidad_cuotas    = 0

			pl_pgs.each do |pp|
				pagos_comprometidos.select{|pc| pc.plan_pago_id == pp.id}.each do |pc|
					cantidad_cuotas    += 1
					total_comprometido += pc.monto
					total_saldo        += pc.saldo
				end
			end
			#

			# ape.matricula_plan.planes_pago.each do |pp|
			# 	atrs = pp.atrasados
			# 	atrasadas += atrs.to_a unless atrs.blank?
			
			# end

			@datos << {
				:rut                => usuario.rut,
				:nombres            => usuario.nombres,
				:apellidos          => usuario.apellidos,
				:email 				=> usuario.email,
				:telefono 			=> usuario.telefono_fijo_completo,
				:celular 			=> usuario.telefono_movil,
				:carrera            => "#{plan_est.nombre}",
				:anio_ingreso		=> ape.anio_ingreso,
				:nivel				=> pl_pgs.last.nivel,
				:estado				=> ape.estado_alumno(ape.estado),
				:total_comprometido => total_comprometido,
				:total_saldo        => total_saldo,
				:cantidad			=> cantidad_cuotas
			}
		end
	end
	def ingreso
		unless params[:busqueda].blank?
            redirect_to cobranzas_morosos_cobranza_externa_ingreso_path(params[:busqueda])
        end
        unless params[:rut].blank?
            @us_alumno = Usuario.first rut: params[:rut]

            if @us_alumno.blank?
                flash.now[:error] = "El alumno buscado no existe" 
            else
                store_location
                @periodos                = Periodo.lista

                if params[:matricula_id].blank?
                    matriculas          = MatriculaPlan.all alumno_plan_estudio: {
                                                    :alumno => {
                                                        :usuario_id => @us_alumno.id
                                                    }                
                                                }
                else
                    matriculas          = MatriculaPlan.all id: params[:matricula_id].to_i
                end

                @alumno_plan_estudio = matriculas.alumno_plan_estudio.last
                planes               = matriculas.planes_pagos
                pagos_comprometidos  = planes.pagos_comprometidos
                ejecutivos           = matriculas.ejecutivo_matriculas
                datos_personales     = ejecutivos.datos_personales

                
                @datos = []
                matriculas.each do |m|
                    tmp = []
                    planes.select{|p| p.matricula_plan_id == m.id}.each do |p|
                        tmp << {plan: p, pagos_comprometidos: pagos_comprometidos.select{|pc| pc.plan_pago_id == p.id}}
                    end
                    @datos << {
                        matricula: m,
                        periodo:   @periodos.select{|x| x.id == m.periodo_id}.first,
                        planes:    tmp,
                        ejecutivo: datos_personales.select{|d| d.id == ejecutivos.select{|e| e.id == m.ejecutivo_matriculas_id }.first.usuario_id}.first
                    }
                end
            end
        end
	end

	def guardar
		mat      = MatriculaPlan.get params['mat']
		ins_sede = mat.alumno_plan_estudio.institucion_sede_plan.institucion_sede_id
		rut      = mat.alumno_plan_estudio.alumno.datos_personales.rut

		cobranza = Cobranza.new fecha:                        Time.now, 
                                institucion_sede_id:          ins_sede,
                                ejecutivo_matriculas_id:      current_user_object.ejecutivo_matriculas.id,
                                pago_comprometido_id:         params['pago-comprometido-id'],
                                tipo: 						  params[:tipo]
                                
        cobranza.save   

        flash[:notice] = "La operación se realizó correctamente."

        redirect_back_or_default

        rescue Exception => e
            flash[:error] = "Ocurrió un error durante la operación, comunicarse con Sistemas."
            log_error e
            redirect_back_or_default
        
	end

	def eliminar
		
		cobranza = Cobranza.first pago_comprometido_id: params[:pago].to_i                      
        cobranza.destroy

        flash[:notice] = "La operación se realizó correctamente."

        redirect_back_or_default

        rescue Exception => e
            flash[:error] = "Ocurrió un error durante la operación, comunicarse con Sistemas."
            log_error e
            redirect_back_or_default
        
	end
#----------------------------------------------------------------------------#
#-------------------Cobranza Externa-----------------------------------------#
#----------------------------------------------------------------------------#
	def informes
		@sedes = Sede.all id: Sede::SEDES_VIGENTES,
						  fields: [:id, :nombre]
		@instituciones = Institucion.all fields: [:id, :nombre]

	end

	def informe_envio
		institucion_id   = params['institucion']
		sede_id          = params['sede']
		@modalidad       = params['modalidad']

		fechas  		= params['todos']
		@fecha_inicio   = fechas['fecha_inicio']
		@fecha_termino  = fechas['fecha_termino']

		cobranzas = Cobranza.all({
			:fecha.gte => @fecha_inicio,
			:fecha.lte => @fecha_termino,
			tipo: Cobranza::EXTERNA,
			pago_comprometido: {
				plan_pago: {
					matricula_plan: {
						alumno_plan_estudio: {
							institucion_sede_plan: {
								modalidad: @modalidad,
								institucion_sede:{
									institucion_id: institucion_id,
									sede_id: sede_id
								}
							}
						}
					}
				}
			}
		})

		@institucion = Institucion.first id: institucion_id,
										 fields: ['nombre']

		@sede 		 = Sede.first id: sede_id,
						   		  fields: ['nombre']

		@items = []

		cobranzas.each do |cobranza|
			pago 		  = cobranza.pago_comprometido
			pagare 		  = pago.pagare
			plan 		  = pago.plan_pago
			mat 		  = plan.matricula_plan
			alumno_plan   = mat.alumno_plan_estudio
			is_plan 	  = alumno_plan.institucion_sede_plan
			plan_est      = is_plan.plan_estudio
			alumno 		  = alumno_plan.alumno
			usuario 	  = alumno.datos_personales
			apoderado     = alumno.apoderado
			usu_apoderado = apoderado.datos_personales

			@items << {
				cobranza: 			   cobranza,
				pago_comprometido:     pago,
				pagare: 			   pagare,
				plan_pago: 		       plan,
				matricula_plan: 	   mat,
				alumno_plan_estudio:   alumno_plan,
				institucion_sede_plan: is_plan,
				plan_estudio:   	   plan_est,
				alumno: 			   alumno,
				usuario: 			   usuario,
				apoderado: 			   usu_apoderado
			}
		end
	end
	
	def informe_letras_situacion_pagadas
	    @sedes = Sede.all id: Sede::SEDES_VIGENTES,
			  fields: [:id, :nombre]
	    @instituciones = Institucion.all fields: [:id, :nombre]
    end

	def listado_cuotas_sitacion_pagadas
		institucion_id   = params['institucion']
		sede_id          = params['sede']
		@modalidad       = params['modalidad']

		fechas  		= params['todos']
		@fecha_inicio   = fechas['fecha_inicio']
		@fecha_termino  = fechas['fecha_termino']

		cobranzas = Cobranza.all({
			tipo: Cobranza::EXTERNA,
			pago_comprometido: {
				saldo: 0,
				:fecha_ultimo_abono.gte => @fecha_inicio,
				:fecha_ultimo_abono.lte => @fecha_termino,
				plan_pago: {
					matricula_plan: {
						alumno_plan_estudio: {
							institucion_sede_plan: {
								modalidad: @modalidad,
								institucion_sede:{
									institucion_id: institucion_id,
									sede_id: sede_id
								}
							}
						}
					}
				}
			}
		})
		
		@institucion = Institucion.first id: institucion_id,
										 fields: ['nombre']

		@sede 		 = Sede.first id: sede_id,
						   		  fields: ['nombre']

		@items = []

		cobranzas.each do |cobranza|
			pago 		  = cobranza.pago_comprometido
			pagare 		  = pago.pagare
			plan 		  = pago.plan_pago
			mat 		  = plan.matricula_plan
			alumno_plan   = mat.alumno_plan_estudio
			is_plan 	  = alumno_plan.institucion_sede_plan
			plan_est      = is_plan.plan_estudio
			alumno 		  = alumno_plan.alumno
			usuario 	  = alumno.datos_personales
			apoderado     = plan.apoderado
			usu_apoderado = apoderado.datos_personales
			abonos 		  = pago.abonos

			@items << {
				cobranza: 			   cobranza,
				pago_comprometido:     pago,
				pagare: 			   pagare,
				plan_pago: 		       plan,
				matricula_plan: 	   mat,
				alumno_plan_estudio:   alumno_plan,
				institucion_sede_plan: is_plan,
				plan_estudio:   	   plan_est,
				alumno: 			   alumno,
				usuario: 			   usuario,
				apoderado: 			   usu_apoderado,
				abonos:                abonos 
			}
		end
	end 
	
end