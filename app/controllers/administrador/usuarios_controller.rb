class Administrador::UsuariosController < ApplicationController
    before_filter :store_location, :only => :index


    crud :usuario, :use_class_name_as_title => true


    def index
    	options = {order: [:tipo.desc, :rol_id.desc]}
    	case params[:filter]
    		when "administrativos"
    			options[:tipo] = Usuario::ADMINISTRATIVO
    		when "docentes"
    			options[:tipo] = Usuario::DOCENTE
    		else
    			options[:tipo.gt] = Usuario::APODERADO 
    	end
    	@items = Usuario.all(options).paginate(page: params[:page])
    end
end