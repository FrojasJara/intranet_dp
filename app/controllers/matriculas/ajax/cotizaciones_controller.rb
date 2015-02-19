# encoding: utf-8
class Matriculas::Ajax::CotizacionesController  < ApplicationController
    before_filter :iniciar
    protect_from_forgery :except => [:buscar_carreras]
    
    def iniciar
        @usuario              = current_user_object
        @ejecutivo_matriculas = @usuario.ejecutivo_matriculas
    end

    def buscar_carreras
        carreras = PlanEstudio.all(
            fields: [:id,:nombre],
            unique: true,
            institucion_sede_plan: {
                institucion_sede: {
                    institucion_id: params[:institucion_id].to_i,
                    sede_id: @usuario.sede_id
                },
                cotizaciones: {
                    tipo: params[:tipo]
                },
                modalidad: params[:modalidad].to_i,
                periodo_id: params[:periodo_id].to_i
            },
            order: [:nombre.asc]
        )
        _carreras = []

        carreras.each do |carrera|
            puts carrera.nombre+" "+carrera.id.inspect.red
            if ! _carreras.detect{|c| c.nombre == carrera.nombre}
                _carreras << carrera
            end
        end

        render :json => {:carreras => _carreras}
    end
end