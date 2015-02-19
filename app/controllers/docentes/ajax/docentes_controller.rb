# encoding: utf-8
require 'json'

class Docentes::Ajax::DocentesController < ApplicationController

	layout nil

	def obtener_secciones_por_periodo
		docente_id = params[:docente_id].to_i
		periodo_id = params[:periodo_id].to_i
		asignaturas = Ajax::Docente.asignaturas docente_id, periodo_id
		render :json => asignaturas.to_json
	end
end