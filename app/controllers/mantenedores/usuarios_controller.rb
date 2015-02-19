# encoding: utf-8
class Mantenedores::UsuariosController < ApplicationController
    before_filter :store_location, :only => [:index]
    crud :usuario, :title_attribute => 'rut'

    def index
        # => Alumnos
        items = Usuario.all

        @items = [] 
        # => Crea Hash personalizado con informacion relevante de los alumnos
        items.each do |i|
            tmp = {:rut => i.rut, :primer_nombre => i.primer_nombre , :apellido_materno => i.apellido_materno ,:apellido_paterno => i.apellido_paterno, :region => i.region.nombre.html_safe, :comuna => i.pais.nombre.html_safe, :pais => i.pais.nombre.html_safe, :sexo => i.get_sexo(i.sexo)}
            @items << tmp
        end

    end

    def before_action
        @item.password = Digest::MD5.hexdigest(@item.rut) if @item.password.nil?

        true
    end

    
end
