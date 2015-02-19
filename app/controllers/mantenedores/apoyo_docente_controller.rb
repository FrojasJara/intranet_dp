# encoding: utf-8
class Mantenedores::ApoyoDocenteController < ApplicationController


	def edit_programacion_clase
		puts params[:clase].inspect.red
		params[:clase].each do |c|
			id_clase = c[0].to_i
			c[1].each do |cl|
				clase = Clase.first(:id => id_clase)
				clase.estado = cl[:estado].to_i
				clase.numero = cl[:numero].to_i
				clase.fecha_planificada = cl[:fecha]
				clase.fecha_suspension = cl[:fecha_suspension] == nil ? nil : cl[:fecha_suspension]
				clase.save
			end
		end
		redirect_to apoyo_docente_ver_programacion_seccion_path
		flash[:notice] = "Edicion realizada con exito."
		rescue Exception => e
            puts e.resource.errors.inspect.red
            flash[:error] = "#{e}Ha ocurrido un error y no ha sido posible registrar el horario."
            redirect_to apoyo_docente_ver_programacion_seccion_path
	end
end