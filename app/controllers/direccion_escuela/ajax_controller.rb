# encoding: utf-8
class DireccionEscuela::AjaxController < ApplicationController

    before_filter :iniciar
    
    protect_from_forgery :except => [
                                        :buscar_docente_por_rut,
                                        :buscar_comunas,
                                        :ingresar_docente_nuevo,
                                        :ingresar_institucion_externa_nueva
                                    ]


	def buscar_docente_por_rut
		rut = params[:rut]
		usuario = Usuario.find_by_rut(rut)
		docente = usuario.docente
        
        raise Excepciones::DatosNoExistentesError, "El Rut ingresado no existe" if usuario.blank?
        raise Excepciones::DatosNoExistentesError, "El Rut ingresado no corresponde a un docente registrado" if usuario.docente.blank?
		
			response = {
								:status => true, 
								:mensaje => "Se encuentra en los registros", 
								:usuario => {
									:usuario_id => usuario.id, 
									:docente_id => docente.id, 
									:nombre => usuario.nombre, 
									:profesion => usuario.profesion , 
									:en_ejercicio => usuario.docente.en_ejercicio ? true : false}
								}
				
			render :json => response
		rescue
			response = {
							:status=> false,
							:mensaje => "No ha sido posible encontrar la información solicitada."
						}
			render :json  => response
	end

	def buscar_comunas
		region_id = params[:region_id].to_i
		comunas = Comuna.all( :fields => [:id, :nombre], :region_id => region_id)

        response = []
        comunas.each do |i|
        	response << {:comuna_id => i.id, :nombre => i.nombre }
        end
        render :json => {:comunas => response}
		
	end


	def ingresar_docente_nuevo
		docente = params[:docente]
		usuario = Usuario.find_by_rut(docente[:rut].gsub(".",""))

		raise Excepciones::DatosDuplicados, "El Rut ingresado ya existe!" unless usuario.blank?
		
		usuario = docente
		nuevo_usuario = Usuario.new(usuario)
			Usuario.transaction do 
				nuevo_usuario.rut = nuevo_usuario.rut.gsub(".", "")
				nuevo_usuario.password = Digest::MD5.hexdigest(nuevo_usuario.rut)
				nuevo_usuario.pais_id = 1
				nuevo_usuario.tipo = Usuario::DOCENTE
				nuevo_usuario.sede_id = current_user[:sede_id]
				nuevo_usuario.save

				nuevo_docente =  Docente.new
				nuevo_docente.en_ejercicio = true
				nuevo_docente.usuario_id = nuevo_usuario.id
				nuevo_docente.save
			end

		response = {
						:status => true, 
						:mensaje => "Se ha encontrado la siguiente información.", 
						:usuario => {
								:usuario_id => nuevo_usuario.id, 
								:nombre => nuevo_usuario.nombre, 
								:profesion => nuevo_usuario.profesion
							}
					}
			
		render :json => response

		puts = response
		rescue 
			response = {:status=> false, :mensaje => "No ha sido posible guardar la información."}
			render :json => response
	end

	def ingresar_institucion_externa_nueva
		institucion = params[:institucion]
			nueva_institucion = InstitucionExterna.new(institucion)
			nueva_institucion.save

		response = {
						:status => true,
						:mensaje => "Institución agregada exitosamente.",
						:institucion => nueva_institucion.to_json
					}
		render :json => response

		rescue Exception => e
			response = {:status => false, :mensaje => "No ha sido posible encontrar la información solicitada."}
			render :json => response
	end
end