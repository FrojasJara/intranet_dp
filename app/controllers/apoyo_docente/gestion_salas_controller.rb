# encoding: utf-8
class ApoyoDocente::GestionSalasController < ApplicationController

    before_filter :iniciar
    protect_from_forgery :except => [
                                        :registrar_nueva_sala 
                                    ]
    def ver_salas        
    	@items = Sala.all(:fields => [:nombre, :capacidad, :piso, :es_laboratorio, :sede_id])
    end

    def ingresar_sala
        
    end

    def registrar_nueva_sala
    	sala = params[:sala]
    	sala[:sede_id] = current_user[:sede_id] 
    	
    	_sala = Sala.new(sala)
    	_sala.save
    		flash[:notice] = "La sala ha sido creada exitosamente."
    		redirect_to apoyo_docente_ver_salas_path
    	rescue
    		flash[:error] = "Ocurrio un problema, no ha sido posible ingresar la sala."
    		redirect_to apoyo_docente_ver_salas_path
    end
    
end