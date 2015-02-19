# encoding: utf-8
class CoordinadorCarrera::AjaxController < ApplicationController

    before_filter :iniciar
    
    protect_from_forgery :except => [
                                        :buscar_nivel
                                    ]

    def buscar_nivel

        carrera = PlanEstudio.first(id: params[:plan_estudio_id].to_i)
        nivel   = carrera.duracion

        render :json => {:nivel => nivel}
    end

    def eliminar_planificacion
    	id = params[:planificacion_id].to_i
    	puts id.inspect.red
    	planificacion = PlanificacionCalificacion.get(id)
    	CalificacionParcial.all(planificacion_calificacion_id: id).destroy
    	if planificacion.destroy
	    	response = {
							:status 		=> true, 
							:mensaje 		=> "Planificacion eliminada con exito", 
							:planificacion 	=> id
						}
					
				render :json => response
		else
			raise Excepciones::DatosNoExistentesError, "No es posible eliminar en estos momentos (2)"
		end
		rescue Excepciones::DatosNoExistentesError => e
			response = {
							:status=> false,
							:mensaje => "#{e.message}."
						}
			render :json  => response
		rescue Exception => e 
			response = {
							:status=> false,
							:mensaje => "#{e.inspect}."
						}
			render :json  => response
    end
end