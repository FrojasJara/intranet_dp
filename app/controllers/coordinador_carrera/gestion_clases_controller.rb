# encoding: utf-8
class CoordinadorCarrera::GestionClasesController < ApplicationController
    before_filter :iniciar

    protect_from_forgery :except => [
                                        :registrar_programacion_clases
                                    ]

	def programacion_clases

	end

	def registrar_programacion_clases
			
	end	


end