# encoding: utf-8
class Mensajero::ContactosController < ApplicationController

    def index
        @items = Usuario.all :tipo => [Usuario::ADMINISTRATIVO, Usuario::DOCENTE]
    end

end