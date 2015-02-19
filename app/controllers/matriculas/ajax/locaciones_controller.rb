# encoding: utf-8
require 'json'

class Matriculas::Ajax::LocacionesController < ApplicationController

	layout nil

	def obtener_comunas_por_region
		region_id = params[:id].to_i
		comunas = Region.obtener_comunas region_id
		render :json => comunas.to_json
	end
end