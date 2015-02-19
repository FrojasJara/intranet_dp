# encoding: utf-8
class Mantenedores::AsignaturasController < ApplicationController
    before_filter :store_location, :only => [:index]
    crud :asignatura, :title_attribute => 'nombre'
    
end