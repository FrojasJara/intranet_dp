class Administrador::RolesController < ApplicationController
    before_filter :store_location, :only => :index

    crud :rol, :use_class_name_as_title => true

end