# encoding: utf-8
class Cobranzas::RangosDocumentosController < ApplicationController
	before_filter :iniciar
    protect_from_forgery :except => [:agregar]

	def iniciar
        @usuario              = current_user_object
        @ejecutivo_matriculas = @usuario.ejecutivo_matriculas
    end
    def talonarios
    	@ejecutivos_matriculas = EjecutivoMatriculas.all({
    		fields: [:id],
            estado: RangoDocumento::HABILITADO,
    		datos_personales: {
    			sede_id: @usuario.sede_id
    		}
    	})
    end
    def agregar
        institucion_sede = InstitucionSede.first(
                            institucion_id: params[:institucion_id],
                            sede_id: @usuario.sede_id
        )

        nombre = ""

        RangoDocumento::CENTRO_COSTOS.each_with_index do |item,index|
            if((index+1) == params[:centro_costos].to_i)
                nombre = item
            end
        end

        talonario = RangoDocumento.new inicio: params[:inicio],
                                       fin: params[:fin],
                                       tipo: params[:tipo],
                                       ejecutivo_matriculas_id: params[:ejecutivo_id],
                                       centro_costos: params[:centro_costos],
                                       nombre: "#{nombre} #{params[:numero]}",
                                       institucion_sede_id: institucion_sede.id

        talonario.save   

        flash[:notice] = "La operación se realizó correctamente."
        redirect_to cobranzas_rangos_documentos_talonarios_path

        rescue Exception => e
            flash[:error] = "Ocurrió un error durante la operación, comunicarse con Sistemas."
            log_error e
            redirect_to cobranzas_rangos_documentos_talonarios_path
    end
    
    def recepcion
        talonario = RangoDocumento.get params[:talonario_id].to_i

        talonario.fecha_recepcion = Time.now
        talonario.save   

        flash[:notice] = "La operación se realizó correctamente."
        redirect_to cobranzas_rangos_documentos_talonarios_path

        rescue Exception => e
            flash[:error] = "Ocurrió un error durante la operación, comunicarse con Sistemas."
            log_error e
            redirect_to cobranzas_rangos_documentos_talonarios_path
    end
end