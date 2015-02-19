# encoding: utf-8
class HomeController < ApplicationController
	def index
		Rails.logger.info "Controller: #{@controller}"
	end

end