class BibliotecaController < ApplicationController
	before_filter :iniciar
    protect_from_forgery :except => [:lista_libros_sedes]

    def lista_libros_sedes
    	# @items = LibroTitulo.all(:sede_id => 1)
    end

    def vista_ejecutivos
    	
    end

    private
    
	def iniciar
		@usuario = current_user_object
		@ejecutivo_matriculas = @usuario.ejecutivo_matriculas
	end
end