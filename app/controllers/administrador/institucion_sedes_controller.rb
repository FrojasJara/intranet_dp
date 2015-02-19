class Administrador::InstitucionSedesController < ApplicationController
    before_filter :store_location, :only => :index

    crud :institucion_sede, :use_class_name_as_title => true

end