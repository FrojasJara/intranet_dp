# encoding: utf-8

class Matriculas::CobranzasController < ApplicationController
	before_filter :iniciar
	protect_from_forgery :except => [:listado,:listado_mails_matricula,:mails,:envio_mails_matricula]

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

	#---------------------------------------------------------------------------#
	#-------------------Envio Cartas Cobranza-----------------------------------#
	#---------------------------------------------------------------------------#
	def listados
		# index mails cobranza

	    @instituciones = Institucion.all fields: [:id, :nombre]

	    periodos = Periodo.all fields: [:id, :anio, :semestre],
							   :estado.not => Periodo::PROXIMO

		@periodos = periodos.to_a.sort!{|a,b| a.nombre <=> b.nombre}
		@periodos = @periodos.reverse
		
		# @años = Periodo.all fields: [:anio],
		# 					unique: true,
		# 					order: :anio.desc,
		# 				    :estado.not => Periodo::PROXIMO
		# @meses = []
		# (0..11).each {|m| @meses << %w(Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre) [m]}
		
		# @dias = []

		# 31.times do |d| 
		# 	@dias << (d+1)
		# end
	end 

	def listado
		# listado mails cobranza
		
		@institucion_id  = params[:institucion]
		periodo_id 	     = params[:periodo]
		@carrera_nombre  = params[:carrera]
		@modalidad  	 = params[:modalidad]
		@sede_id 		 = @usuario.sede_id

		@periodo = Periodo.first id: periodo_id,
								 fields: [:id,:semestre,:anio]

		filtro_alumno_plan_estudios = AlumnoPlanEstudio.all(
			institucion_sede_plan: {
				plan_estudio: {
					nombre: @carrera_nombre.to_s
				},
				modalidad: @modalidad.to_i,
				institucion_sede: {
					institucion_id: @institucion_id.to_i,
					sede_id: @sede_id.to_i
				}
			}
		)

		matriculas = MatriculaPlan.all(
			periodo_id: periodo_id.to_i,
			planes_pago: {
				pagos_comprometidos: {
					:saldo.gt => 0,
					:fecha_vencimiento.lt => (Date.today - 3.day),
					:estado.not => PagoComprometido::ANULADO
				}
			},
			alumno_plan_estudio: filtro_alumno_plan_estudios
		)

		@matriculas = []

		matriculas.each do |matricula|
			suma = 0
			matricula.planes_pago.each do |plan|
                plan.pagos_comprometidos.each do |pago|
                    if pago.saldo > 0 && pago.estado != PagoComprometido::ANULADO
                    	if pago.tiene_prorroga?(pago.id)
	                        unless pago.fecha_vencimiento_con_prorroga.blank?
	                            if pago.fecha_vencimiento_con_prorroga < (Date.today)
	                                suma += 1
	                            end
	                        end
	                    else
	                    	unless pago.fecha_vencimiento.blank?
	                            if pago.fecha_vencimiento < (Date.today - 3.day)
	                                suma += 1
	                            end
	                        end
	                    end
                    end
                end
            end

            if suma > 0
            	@matriculas << matricula
            end
		end

		@matriculas
	end 

	def mails_matricula
		# index mails matricula

	    @instituciones = Institucion.all fields: [:id, :nombre]

	    periodos = Periodo.all fields: [:id, :anio, :semestre],
							   :estado.not => Periodo::PROXIMO

		@periodos = periodos.to_a.sort!{|a,b| a.nombre <=> b.nombre}
		@periodos = @periodos.reverse
		
	end

	def listado_mails_matricula
		# listado mails matricula

		@institucion_id  = params[:institucion]
		periodo_id 	     = params[:periodo]
		@carrera_nombre  = params[:carrera]
		@modalidad  	 = params[:modalidad]
		@sede_id 		 = @usuario.sede_id

  		@periodo = Periodo.first id: periodo_id,
								 fields: [:id,:semestre,:anio]

		filtro_alumno_plan_estudios = AlumnoPlanEstudio.all(
			institucion_sede_plan: {
				plan_estudio: {
					nombre: @carrera_nombre.to_s
				},
				modalidad: @modalidad.to_i,
				institucion_sede: {
					institucion_id: @institucion_id.to_i,
					sede_id: @sede_id.to_i
				}
			}
		)

		@matriculas = MatriculaPlan.all(
			periodo_id: periodo_id.to_i,
			:estado.not => [MatriculaPlan::ANULADA],
			alumno_plan_estudio: filtro_alumno_plan_estudios
		)

		@matriculas
	end

	def mails
		# envío mails cobranza

  	    matriculas = MatriculaPlan.all id: params[:matriculas]
  	    modalidad  	 = params[:modalidad]

  	    @matriculas = []

		matriculas.each do |matricula|
			cuotas = 0
			fechas = []
	    	saldos = []

			matricula.planes_pago.each do |plan|
				plan.pagos_comprometidos.each do |pago|
					if pago.saldo > 0 && pago.estado != PagoComprometido::ANULADO
						if pago.tiene_prorroga?(pago.id)
							unless pago.fecha_vencimiento_con_prorroga.blank?
								if pago.fecha_vencimiento_con_prorroga < (Date.today)
									cuotas += 1
									fechas << pago.fecha_vencimiento
		                            saldos << pago.saldo
								end
							end
						else
							unless pago.fecha_vencimiento.blank?
								if pago.fecha_vencimiento < (Date.today - 3.day)
									cuotas += 1
									fechas << pago.fecha_vencimiento
		                            saldos << pago.saldo
								end
							end
						end
					end
				end
			end

			if cuotas > 0
				unless @matriculas.detect{|m| m.id == matricula.id}
					@matriculas << matricula
					observacion = 'Envío de mail de cobranza '

					if modalidad.to_i == InstitucionSedePlan::PRESENCIAL
						if cuotas == 1 
							ActionCorreo.MailCobranzaPresencial1(matricula,fechas,saldos,@usuario).deliver
							observacion += 'presencial 1 cuota'
						elsif cuotas == 2
							ActionCorreo.MailCobranzaPresencial2(matricula,fechas,saldos,@usuario).deliver
							observacion += 'presencial 2 cuotas'
						elsif cuotas == 3 
							ActionCorreo.MailCobranzaPresencial3(matricula,fechas,saldos,@usuario).deliver
							observacion += 'presencial 3 cuotas'
						elsif cuotas > 3 
							ActionCorreo.MailCobranzaPresencial4(matricula,fechas,saldos,@usuario).deliver
							observacion += 'presencial mas de 3 cuotas'
						end
					elsif modalidad.to_i == InstitucionSedePlan::DISTANCIA
						if cuotas == 1 
							ActionCorreo.MailCobranzaDistancia1(matricula,fechas,saldos,@usuario).deliver
							observacion += 'distancia 1 cuota'
						elsif cuotas == 2
							ActionCorreo.MailCobranzaDistancia2(matricula,fechas,saldos,@usuario).deliver
							observacion += 'distancia 2 cuotas'
						elsif cuotas > 2 
							ActionCorreo.MailCobranzaDistancia3(matricula,fechas,saldos,@usuario).deliver
							observacion += 'distancia 3 o mas cuotas'
						end
					end

					bitacora = BitacoraCobranza.new observacion: observacion,
                                   fecha: Date.today,
                                   tipo: BitacoraCobranza::SOLO_EMAIL,
                                   usuario_id: @ejecutivo_matriculas.usuario_id,
                                   alumno_plan_estudio_id: matricula.alumno_plan_estudio_id,
                                   periodo_id: matricula.planes_pago.last.periodo_id,
                                   procedencia: BitacoraCobranza::ADMINISTRATIVA

        			bitacora.save 
				end
			end
		end

		flash[:notice] = "Se han realizado los envíos correctamente."
        redirect_to matriculas_cobranzas_envio_mails_listados_path

	    rescue Exception => e
	        flash[:error] = "#{e}"
	        puts e.message
			puts e.backtrace
	        redirect_to matriculas_cobranzas_envio_mails_listados_path

	end  

	def envio_mails_matricula
		# envío mails matricula

  	    matriculas = MatriculaPlan.all id: params[:matriculas]
  	    modalidad  	 = params[:modalidad]

  	    matriculas.each do |matricula|
			if modalidad.to_i == InstitucionSedePlan::DISTANCIA
				ActionCorreo.MailMatriculas(matricula,@usuario).deliver
			end
		end

		flash[:notice] = "Se han realizado los envíos correctamente."
        redirect_to matriculas_cobranzas_envio_mails_mails_matricula_path

	    rescue Exception => e
	        flash[:error] = "#{e}"
	        puts e.message
			puts e.backtrace
	        redirect_to matriculas_cobranzas_envio_mails_mails_matricula_path

	end  
end