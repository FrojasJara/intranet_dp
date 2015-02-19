# encoding: utf-8
require 'dm-rails/middleware/identity_map'
require 'dm-serializer'

class ApplicationController < ActionController::Base
    #use Rails::DataMapper::Middleware::IdentityMap
    protect_from_forgery
      
    before_filter :init 
    before_filter :must_login

    helper_method [:controller_is?, :action_is?, :module_is?, :current_user, :historial, :current_period, :current_year, :current_semester, :current_user_object]
    helper_method [:current_user_is_alumno, :current_user_is_apoderado, :current_user_is_usuario]
    helper_method [:current_role, :current_role_can?]

    helper_method [:periodo_proximo, :periodo_en_curso, :periodo_matriculable, :es_periodo_transicion?, :es_academico?]

    protected
    def init
    
        my_class_name = self.class.name
        if my_class_name.index("::").nil? then
            @module_name = nil
        else
            @module_name = my_class_name.split("::").first
        end
        @controller = controller_name
        @action = action_name
    end

  
    def controller_is?(value, module_name = nil)
        status = @controller.downcase == value.downcase
    
        if status
            status = module_name.downcase == @module_name.downcase unless @module_name.nil? || module_name.nil?
        end
    
        status
    end
  
    def action_is?(value, controller_name = true)
        @action.downcase == value.downcase && ( ( controller_name && !(controller_name.class == String) ) ? true : controller_is?(controller_name) )
    end
  
    def module_is?(value)
        return false if @module_name.nil?
        return @module_name.downcase == value.downcase
    end
  
    def current_user
        session.has_key?(:user) && session[:user] ? session[:user] : nil
    end

    def current_user_object
        current_user.nil? ? nil : Usuario.get(current_user[:id])
    end

    def current_user_is_alumno
        current_user_object.nil? ? false : current_user_object.tipo == Usuario::ESTUDIANTE
    end


    def current_user_is_apoderado
        current_user_object.nil? ? false : current_user_object.tipo == Usuario::APODERADO
    end

    def current_user_is_usuario
        current_user_object.nil? ? false : current_user_object.tipo > 2
    end

    # Para la gestion de periodo

    def periodo_en_curso
        session[:periodo_en_curso]
    end

    def periodo_proximo
        session[:periodo_proximo]
    end

    def periodo_matriculable
        if not session[:periodo_proximo].nil?
            return session[:periodo_proximo]
        else
            return session[:periodo_en_curso]
        end
    end

# HELPERS PARA ROLES Y PERMISOS
    def current_role
        session.has_key?(:role) ? session[:role] : nil
    end

    def current_role_can?(prop)
        return false if current_role.nil?
        current_role.has_key?(prop) ? current_role[prop] : false
    end
# END ROLES Y PERMISOS  

    def must_login
        redirect_to :action => 'login', :controller => 'usuarios' if !(controller_is?('usuarios') && action_is?('login')) && current_user.nil?
    end


    def historial comentario, item, opts = {}
        Historial.do comentario, item, { :usuario => current_user }.merge( opts )
    end

    def store_location
        logger.info "> Store Location: #{request.path}"
        session[:return_to] = request.path
    end


    def redirect_back_or_default default = '/'
        default = '/' if default.nil?
        logger.info "> Return to: #{session[:return_to]}"
        redirect_to(session[:return_to] || default) 
        session[:return_to] = nil
    end

    def save_tmp data = {}
        session[:tmp] = data
    end

    def get_tmp simbolo
        session[:tmp][simbolo]
    end

    def check_tmp? simbolo, data    
        value = session[:tmp].fetch simbolo.to_sym
        return false if value.nil?

        data.each do |d|
            return false if not value.include? Integer(d)
        end

        return true

        rescue
            return false
    end

    def clean_tmp
        session.delete :tmp
    end
    
    def log_error e
        logger.info "========================================".red
        logger.info e.inspect
        logger.info e.resource.errors.inspect.blue.bold if e.is_a? DataMapper::SaveFailureError
        logger.info "========================================".red
        e.backtrace.map{ |x| x.match(/^(.+?):(\d+)(|:in `(.+)')$/); [$1,$2,$4] }.each do |i|
            logger.info i[0].magenta + ":" + i[1].red + "\t" + i[2].yellow
        end

        if Rails.env.production?
            str = "========================================\n"
            str << e.inspect + "\n"
            str << e.resource.errors.inspect + "\n" if e.is_a? DataMapper::SaveFailureError
            str << "========================================\n"
            e.backtrace.map{ |x| x.match(/^(.+?):(\d+)(|:in `(.+)')$/); [$1,$2,$4] }.each do |i|
                str << i[0] + ":" + i[1] + "\t" + i[2] + "\n"
            end
            str << "========================================\n"
            str << "Dump de variables locales:\n"
            local_variables.each do |i|
                str << "#{i} => #{eval(i.to_s)}\n"
            end
        
            ActionMailer::Base.mail(:from => 'intranet@dportales.cl', :to => 'frojas@dportales.cl,dmunoz@dportales.cl,mvera@dportales.cl', :subject => "Backtrace en producción", :body => "Error en producción:\n#{str}").deliver
        end
    end

    def iniciar
        @usuario              = current_user_object
        @ejecutivo_matriculas = @usuario.ejecutivo_matriculas

        unless params[:rut].blank?
            @us_alumno = Usuario.first rut: params[:rut]
            @alumno    = @us_alumno.alumno if @us_alumno
        end
    end

    def es_periodo_transicion?
        Rails.configuration.es_periodo_transicion
    end

    def es_academico?
        roles = session[:role]
        roles[:academico] and roles[:direccion_docencia] and roles[:direccion_escuela]
    end
end