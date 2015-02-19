module Administrador::DedosHelper
	def calculo_horas data
		if data.length % 2 == 0
			result = (data.map {|d| d.diferencia.blank? ? 0 : d.diferencia }).sum
		else
			result = ( Time.parse(data.last.fecha.to_s) - Time.parse(data.first.fecha.to_s) )/60
		end

		return result
	end
end