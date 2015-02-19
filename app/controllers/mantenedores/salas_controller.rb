# encoding: utf-8
class Mantenedores::SalasController < ApplicationController
    before_filter :store_location, :only => [:index]
    
    
    crud :sala, :title_attribute => 'nombre'

end