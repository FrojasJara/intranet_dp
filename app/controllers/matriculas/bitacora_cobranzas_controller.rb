# encoding: utf-8
class Matriculas::BitacoraCobranzasController < ApplicationController
    helper_method [:current_url]
	before_filter :iniciar, :only => [:ver, :guardar, :eliminar]

	def ver
		unless params[:al_pl_es].blank?
            alias current_url matriculas_pagos_bitacora_cobranzas_path
            @alumno_plan_estudio_seleccionado = AlumnoPlanEstudio.first id: params[:al_pl_es].to_i
            @usuario_al     = @alumno_plan_estudio_seleccionado.alumno.datos_personales
            @otros_planes   = @usuario_al.alumno.alumno_plan_estudio
            @us_apoderado   = Usuario.get @usuario_al.alumno.apoderado.datos_personales.id

            
            @bitacoras = BitacoraCobranza.all(
            				fields: [:id,:fecha,:observacion,:tipo,:alumno_plan_estudio_id,:usuario_id,:periodo_id,:procedencia],
                            :alumno_plan_estudio_id => @alumno_plan_estudio_seleccionado.id,
                            :order => [:fecha.desc]
                        )
        end
        rescue Exception => e 
            puts log_error e
            flash[:error] = "Error al consultar"
        rescue Excepciones::DatosNoExistentesError => e
            flash[:error] = e.message
	end

	def guardar
		alumno_plan_estudio = params[:al_pl_es].to_i
		BitacoraCobranza.transaction do
                b = BitacoraCobranza.new params[:bitacora_cobranza]
                b.usuario_id                = @usuario.id
                b.periodo_id                = Periodo::en_curso.id
                b.alumno_plan_estudio_id    = alumno_plan_estudio
                b.save
        end
        flash[:notice] = "Acción guardada con éxito"
        redirect_to matriculas_pagos_bitacora_cobranzas_path(alumno_plan_estudio)
    rescue Exception => e 
        puts log_error e
        flash[:error] = "Error al Guardar la bitacora"
	end

	def eliminar
		alum_pl_es = params[:alumno_plan_estudio_id]
		BitacoraCobranza.transaction do
			b = BitacoraCobranza.get params[:bitacora_cobranzas_id]	
			if b.usuario.id == @usuario.id
				b.destroy
			end
		end
		flash[:notice] = "Bitácora de cobranzas eliminada correctamente"
		redirect_to matriculas_pagos_bitacora_cobranzas_path(alum_pl_es)
    	rescue Exception => e 
    		puts log_error e
    		flash[:error] = "Ocurrió un error al intentar eliminar la bitácora de cobranzas" 
    		redirect_to matriculas_pagos_bitacora_cobranzas_path(alum_pl_es)
	end

	private

	def iniciar
        @usuario              = current_user_object

        unless params[:rut].blank?
            @us_alumno = Usuario.first rut: params[:rut]
            @alumno    = @us_alumno.alumno if @us_alumno
        end
	end

end