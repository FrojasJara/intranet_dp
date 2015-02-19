# encoding: utf-8
class UsuariosController < ApplicationController

	layout 'login', :action => [:login, :index]

	crud :usuario, :title_attribute => 'rut'


  # METODOS DE CONEXIÓN
  def login
	if current_user.nil? && params[:usuario]
		rut = params[:usuario][:rut].gsub(".", "")
		pass = params[:usuario][:password]
		
		data = Usuario.login rut,pass
	  
		if data
			session[:user] = data

			periodo_en_curso = Periodo.en_curso
			periodo_proximo = Periodo.proximo

			session[:periodo_en_curso] = {
				:id         => periodo_en_curso.id,
				:anio       => periodo_en_curso.anio,
				:semestre   => periodo_en_curso.semestre,
				:nombre     => periodo_en_curso.nombre
			}

			if not periodo_proximo.nil?
				session[:periodo_proximo] = {
					:id         => periodo_proximo.id,
					:anio       => periodo_proximo.anio,
					:semestre   => periodo_proximo.semestre,
					:nombre     => periodo_proximo.nombre
				}
			end

			session[:role] = (current_user_object.rol.nil? ? Rol.first(por_defecto: true) : current_user_object.rol).attributes
			redirect_to :controller => 'home', :action => 'index'
		else
			flash[:info] = "Por favor verifique sus datos. Su contrasena debe ser su rut sin puntos ejemplo: 12345678-K."
			must_login
		end
	elsif current_user
		flash[:info] = "Usted ya esta logueado en el sistema."
		redirect_to :controller => 'home', :action => 'index'
	end
  end

    def cambiar_clave
        password_actual = params[:password_actual]
        nuevo_password = params[:nuevo_password]
        confirmacion_nuevo_password = params[:confirmacion_nuevo_password]

        usuario = session[:user]
        if not Digest::MD5.hexdigest(password_actual) == usuario[:password]
            raise Excepciones::OperacionNoPermitidaError, "Su contraseña actual no coincide con la que ha entregado."
        end

        if not nuevo_password == confirmacion_nuevo_password
            raise Excepciones::OperacionNoPermitidaError, "Su nueva contrasena y la confirmación no coiciden."
        end

        _usuario = Usuario.get usuario[:id]
        _usuario.update :password => Digest::MD5.hexdigest(nuevo_password)

        redirect_to "/usuarios/logout"

    rescue Excepciones::OperacionNoPermitidaError => e
        flash[:error] = e.message
        redirect_to request.referer
    rescue DataMapper::SaveFailureError => e
        flash[:error] = "Ha ocurrido un error al tratar de cambiar la contrasena. Por favor, verifique los campos ingresados."
        redirect_to request.referer
    rescue Exception => e
        flash[:error] = Excepciones::ERROR_DESCONOCIDO
        redirect_to request.referer
    end

  def logout      
	  reset_session unless current_user.nil?
	  redirect_to root_path
  end





end