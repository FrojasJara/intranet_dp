class Administrador::SedesController < ApplicationController
    before_filter :store_location, :only => :index

    crud :sede, :use_class_name_as_title => true


end