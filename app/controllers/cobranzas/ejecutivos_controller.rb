# encoding: utf-8
class Cobranzas::EjecutivosController < ApplicationController
    before_filter :iniciar
    protect_from_forgery :except => [:guardar_ejecutivo]

    def iniciar
    	@usuario              = current_user_object
    	@ejecutivo_matriculas = @usuario.ejecutivo_matriculas
    end

    def ingreso_ejecutivo_matricula
    	
    end

    def guardar_ejecutivo
    	prms = params[:ejecutivo]
    	@b_usuario = Usuario.all(:rut => prms[:rut])
    	@b_ejecutivo = @b_usuario.ejecutivo_matriculas
    	raise Excepciones::DatosExistentesError, "El Rut ingresado ya esta registrado" if not @b_usuario.blank?
    	raise Excepciones::DatosExistentesError, "El Rut ingresado ya esta registrado como ejecutivo" if not @b_ejecutivo.blank?
    	# puts prms.inspect.yellow
    	if @b_usuario.blank?

    		# puts "rut "+prms[:rut].inspect.red
    		# puts "nombre " +prms[:primer_nombre].inspect.red
    		# puts "2do " +prms[:segundo_nombre].inspect.red
    		# puts "apellido" +prms[:apellido_paterno].inspect.red
    		# puts "2do " +prms[:apellido_materno].inspect.red
    		# puts "sede " +prms["sede_id"].to_i.inspect.red
    		# puts prms[:estado_civil].inspect.red
    		# puts prms[:domicilio].inspect.red
    		# puts prms[:villa_poblacion].inspect.red
    		# puts prms[:email].inspect.red
    		# puts prms[:telefono_fijo].inspect.red
    		# puts prms[:telefono_movil].inspect.red
    		# puts "pais" +prms[:pais_id].inspect.red
    		# puts prms[:region_id].inspect.red
    		# puts prms[:comuna_id].inspect.red
    		# puts prms[:tipo].inspect.red
    		# puts prms[:rol_id].inspect.red

    		Usuario.transaction do
		    	usuario = Usuario.new 
		    	usuario.rut = prms[:rut]
				usuario.password = Digest::MD5.hexdigest params[:ejecutivo][:rut]
				usuario.primer_nombre = prms[:primer_nombre]
				usuario.segundo_nombre = prms[:segundo_nombre]
		    	usuario.apellido_paterno = prms[:apellido_paterno]
		    	usuario.apellido_materno = prms[:apellido_materno]
		    	usuario.sede_id = prms[:sede_id]
		    	usuario.sexo = prms[:sexo]
		    	usuario.estado_civil = prms[:estado_civil]
		    	usuario.domicilio = prms[:domicilio]
		    	usuario.villa_poblacion = prms[:villa_poblacion]
		    	usuario.email = prms[:email]
		    	usuario.telefono_fijo = prms[:telefono_fijo]
		    	usuario.telefono_movil = prms[:telefono_movil]
		    	usuario.pais_id = prms[:pais_id]
		    	usuario.region_id = prms[:region_id]
		    	usuario.comuna_id = prms[:comuna_id]
		    	usuario.tipo = prms[:tipo]
				usuario.rol_id = prms[:rol_id]
		    	
		    	usuario.save
		    end
		    	# ejecutivo = EjecutivoMatriculas.new
		    	# ejecutivo.usuario_id = usuario.usuario.id

		end
		flash[:notice] = "El ejecutivo ha sido ingresado exitosamente!"
        redirect_back_or_default
        
        rescue Excepciones => e
        	flash[:error] = "El rut ingresado #{e}, ya existe... "
        	redirect_back_or_default
		rescue Exception => e
			puts e.resource.errors.inspect
            puts "No ha sido posible eliminar la inscripcion del alumno. #{e}" 
            redirect_back_or_default
    end

end