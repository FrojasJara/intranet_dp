class Mantenedores::DirectorEscuelaController < ApplicationController


    protect_from_forgery :except => [:modificar_escuela, :registrar_modificar_escuela]

    def modificar_escuela
    	@escuelas = Escuela.all(:fields => [:id, :nombre])
    	@planes_estudios = PlanEstudio.all(:anio_inicio.gte => 2008)
    end

    def registrar_modificar_escuela
    	planes_estudios = params[:plan_estudios]
    	Escuela::asignar_escuela_director_escuela directores

    	flash[:notice] = "Los cambios se realizaron exitosamente."
    	redirect_to modificar_escuela_path
    	rescue Exception => e
            puts e.message
            flash[:error] = "Ha ocurrido un error y la informacion no se ha actualizado!"
            redirect_to modificar_escuela_path
    end


end