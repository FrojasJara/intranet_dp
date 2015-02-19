# encoding: utf-8
class Usuarios::UsuariosController < ApplicationController

    def panel_configuracion_perfiles
        @controladores = buscar_controlladores
        
        @esquemas = leer_esquemas
    end

    def crear_ejecutivo_matriculas
        
    end

    def crear_director_escuela
        
    end


    
    private

    def buscar_controlladores
=begin
        Rails.application.eager_load!
        controladores = []
        tmp = ApplicationController.subclasses
        
        tmp.each do |i|
            controlador = {:nombre => i.name.gsub('Controller', ''), :metodos => i.action_methods.to_a, :procedimientos => i::PROCEDIMIENTOS }
            controladores << controlador 
        end 
        controladores
=end
    end

    def leer_esquemas

        require 'yaml'
        esquemas = YAML::load(File.read(File.join(Rails.root, "config/esquemas_perfiles.yml")))
        esquemas
    end

end