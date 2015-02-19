# encoding: utf-8
PEQUENOS = %w(cero un dos tres cuatro cinco seis siete ocho nueve diez
		   once doce trece catorce quince dieciséis diecisiete dieciocho diecinueve)
 
DECENAS = %w(wrong wrong veinte treinta cuarenta cincuenta sesenta setenta ochenta noventa)

CIEN = "ciento"
UN_MILLON = "un millón"
CIENTOS = [nil, nil] + %w(dosci tresci cuatroci quini seisci seteci ochoci noveci).map{ |p| "#{p}entos" }
 
GRANDES = [nil, "mil"] + %w( m b tr cuatr quint sixt sept oct non dec).map{ |p| "#{p}illones" }
 
class Fixnum
  	def wordify
	  	if self < 0
			"menos #{wordify -self}".strip

		elsif self == 0
			return
	 
	  	elsif self < 20
			PEQUENOS[self]
	 
	  	elsif self < 100
			div, mod = self.divmod(10)
			if mod > 0
				"#{DECENAS[div]} y #{mod.wordify}".strip
			else
				"#{DECENAS[div]}".strip
			end

		elsif self == 100
			"cien".strip

		elsif self < 200
			div, mod = self.divmod(100)
			"#{CIEN} #{mod.wordify}".strip
	 
	  	elsif self < 1000
			div, mod = self.divmod(100)
			"#{CIENTOS[div]} #{mod.wordify}".strip
		
		elsif self < 2000
			div, mod = self.divmod(1000) 
			"mil #{mod.wordify}"

		elsif self >= 1000000 and self < 2000000
			div, mod = self.divmod(1000000)
			"#{UN_MILLON} #{mod.wordify}".strip	

	  	else
			# separate into 3-digit chunks
			chunks = []
			div = self
			while div != 0
		  		div, mod = div.divmod(1000)
		  		chunks << mod # will store PEQUENOSest to largest
			end
	 
			if chunks.length > GRANDES.length
		  		raise ArgumentError, "Integer value too large."
			end
	 
			chunks.map{ |c| c.wordify }.
				zip(GRANDES). # zip pairs up corresponding elements from the two arrays
				find_all { |c| c[0] != 'zero' }.
				map{ |c| c.join ' '}. # join ["forty", "thousand"]
				reverse.
				join(' '). # join chunks
				strip
  		end
  	end
end