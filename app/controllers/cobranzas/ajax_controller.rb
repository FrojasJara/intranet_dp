# encoding: utf-8
class Cobranzas::AjaxController < ApplicationController
    before_filter :iniciar
    protect_from_forgery :except => [:buscar_talonarios]
    
    def iniciar
        @usuario              = current_user_object
        @ejecutivo_matriculas = @usuario.ejecutivo_matriculas
    end

    def buscar_talonarios
        talonarios = RangoDocumento.all(
            fields: [:id,:inicio,:fin,:nombre,:ejecutivo_matriculas_id], 
            institucion_sede: {
                sede_id: @usuario.sede_id
            },
            ejecutivo_matriculas_id: params[:ejecutivo_matriculas_id].to_i,
            fecha_recepcion: nil
        )

        render :json => {:talonarios => talonarios}
    end

end