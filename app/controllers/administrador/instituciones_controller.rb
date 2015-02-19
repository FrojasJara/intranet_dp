class Administrador::InstitucionesController < ApplicationController
    before_filter :store_location, :only => :index

    crud :institucion, :use_class_name_as_title => true

end