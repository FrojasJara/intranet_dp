# encoding: utf-8
class Mantenedores::PlanEstudiosController < ApplicationController
    before_filter :store_location, :only => [:index, :modificar_escuela]
    
    crud :plan_estudio, :title_attribute => 'nombre'


    protect_from_forgery :except => [:modificar_carrera, :registrar_modificar_carrera]

    def modificar_carrera
    	@escuelas = Escuela.all(:fields => [:id, :nombre])
    	#@planes_estudios = PlanEstudio.all(:anio_inicio.gte => 2008)
        @planes_estudios = PlanEstudio.all(:fields => [:id, :nombre, :titulo_profesional, :estado, :escuela_id], :estado => PlanEstudio::VIGENTE, :institucion_sede_plan => {:institucion_sede => {:institucion_id =>  1}})
        #puts @planes_estudios.size
    end

    def registrar_modificar_carrera
    	planes_estudios = params[:plan_estudios]
    	Escuela::asignar_escuela_plan_estudio planes_estudios

    	flash[:notice] = "Los cambios se realizaron exitosamente."
    	redirect_to modificar_carrera_path
    	rescue 
    		flash[:error] = "Ha ocurrido un problema y el dato no se ha guardado!"
    		redirect_to modificar_carrera_path
    end

end