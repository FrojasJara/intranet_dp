# encoding: utf-8
require 'json'
class Vicerrectoria::Ajax::PlanEstudiosController < ApplicationController
    
    def  buscar_carreras_sedes

        sede_id = params[:sede_id].to_i

        carreras = PlanEstudio.all(:fields => [:id, :nombre, :anio_inicio, :anio_fin], :institucion_sede_plan => {:institucion_sede => {:sede_id => sede_id }}, :estado => PlanEstudio::VIGENTE, :order => [:nombre.asc])
        tmp = []

        carreras.each do |i|
            tmp << {:plan_id => i.id, :nombre => "#{i.nombre} [#{i.anio_inicio} - #{i.anio_fin}]" }
        end

        render :json => {:carreras => tmp }
        
    end
end