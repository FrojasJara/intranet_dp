# encoding: utf-8
require 'csv'

class Dias
	attr_accessor :dias
	def initialize
		@dias = [    
			# Enero 2013
	    	{ :anio => 2013, :mes => 1, :dia => 5, :monto => nil },
	    	{ :anio => 2013, :mes => 1, :dia => 10, :monto => nil },
	    	{ :anio => 2013, :mes => 1, :dia => 15, :monto => nil },
	    	{ :anio => 2013, :mes => 1, :dia => 20, :monto => nil },
	    	{ :anio => 2013, :mes => 1, :dia => 25, :monto => nil },
	    	{ :anio => 2013, :mes => 1, :dia => 30, :monto => nil },

	    	# Febrero 2013
	    	{ :anio => 2013, :mes => 2, :dia => 5, :monto => nil },
	    	{ :anio => 2013, :mes => 2, :dia => 10, :monto => nil },
	    	{ :anio => 2013, :mes => 2, :dia => 15, :monto => nil },
	    	{ :anio => 2013, :mes => 2, :dia => 20, :monto => nil },
	    	{ :anio => 2013, :mes => 2, :dia => 25, :monto => nil },
	    	{ :anio => 2013, :mes => 2, :dia => 28, :monto => nil },

	    	# Marzo 2013
	    	{ :anio => 2013, :mes => 3, :dia => 5, :monto => nil },
	    	{ :anio => 2013, :mes => 3, :dia => 10, :monto => nil },
	    	{ :anio => 2013, :mes => 3, :dia => 15, :monto => nil },
	    	{ :anio => 2013, :mes => 3, :dia => 20, :monto => nil },
	    	{ :anio => 2013, :mes => 3, :dia => 25, :monto => nil },
	    	{ :anio => 2013, :mes => 3, :dia => 30, :monto => nil },

	    	# Abril 2013
	    	{ :anio => 2013, :mes => 4, :dia => 5, :monto => nil },
	    	{ :anio => 2013, :mes => 4, :dia => 10, :monto => nil },
	    	{ :anio => 2013, :mes => 4, :dia => 15, :monto => nil },
	    	{ :anio => 2013, :mes => 4, :dia => 20, :monto => nil },
	    	{ :anio => 2013, :mes => 4, :dia => 25, :monto => nil },
	    	{ :anio => 2013, :mes => 4, :dia => 30, :monto => nil },

	    	# Mayo 2013
	    	{ :anio => 2013, :mes => 5, :dia => 5, :monto => nil },
	    	{ :anio => 2013, :mes => 5, :dia => 10, :monto => nil },
	    	{ :anio => 2013, :mes => 5, :dia => 15, :monto => nil },
	    	{ :anio => 2013, :mes => 5, :dia => 20, :monto => nil },
	    	{ :anio => 2013, :mes => 5, :dia => 25, :monto => nil },
	    	{ :anio => 2013, :mes => 5, :dia => 30, :monto => nil },

	    	# junio 2013
	    	{ :anio => 2013, :mes => 6, :dia => 5, :monto => nil },
	    	{ :anio => 2013, :mes => 6, :dia => 10, :monto => nil },
	    	{ :anio => 2013, :mes => 6, :dia => 15, :monto => nil },
	    	{ :anio => 2013, :mes => 6, :dia => 20, :monto => nil },
	    	{ :anio => 2013, :mes => 6, :dia => 25, :monto => nil },
	    	{ :anio => 2013, :mes => 6, :dia => 30, :monto => nil },

	    	# Julio 2013
	    	{ :anio => 2013, :mes => 7, :dia => 5, :monto => nil },
	    	{ :anio => 2013, :mes => 7, :dia => 10, :monto => nil },
	    	{ :anio => 2013, :mes => 7, :dia => 15, :monto => nil },
	    	{ :anio => 2013, :mes => 7, :dia => 20, :monto => nil },
	    	{ :anio => 2013, :mes => 7, :dia => 25, :monto => nil },
	    	{ :anio => 2013, :mes => 7, :dia => 30, :monto => nil },

	    	# Agosto 2013
	    	{ :anio => 2013, :mes => 8, :dia => 5, :monto => nil },
	    	{ :anio => 2013, :mes => 8, :dia => 10, :monto => nil },
	    	{ :anio => 2013, :mes => 8, :dia => 15, :monto => nil },
	    	{ :anio => 2013, :mes => 8, :dia => 20, :monto => nil },
	    	{ :anio => 2013, :mes => 8, :dia => 25, :monto => nil },
	    	{ :anio => 2013, :mes => 8, :dia => 30, :monto => nil },

	    	# Septiembre 2013
	    	{ :anio => 2013, :mes => 9, :dia => 5, :monto => nil },
	    	{ :anio => 2013, :mes => 9, :dia => 10, :monto => nil },
	    	{ :anio => 2013, :mes => 9, :dia => 15, :monto => nil },
	    	{ :anio => 2013, :mes => 9, :dia => 20, :monto => nil },
	    	{ :anio => 2013, :mes => 9, :dia => 25, :monto => nil },
	    	{ :anio => 2013, :mes => 9, :dia => 30, :monto => nil },

	    	# Octubre 2013
	    	{ :anio => 2013, :mes => 10, :dia => 5, :monto => nil },
	    	{ :anio => 2013, :mes => 10, :dia => 10, :monto => nil },
	    	{ :anio => 2013, :mes => 10, :dia => 15, :monto => nil },
	    	{ :anio => 2013, :mes => 10, :dia => 20, :monto => nil },
	    	{ :anio => 2013, :mes => 10, :dia => 25, :monto => nil },
	    	{ :anio => 2013, :mes => 10, :dia => 30, :monto => nil },

	    	# Noviembre 2013
	    	{ :anio => 2013, :mes => 11, :dia => 5, :monto => nil },
	    	{ :anio => 2013, :mes => 11, :dia => 10, :monto => nil },
	    	{ :anio => 2013, :mes => 11, :dia => 15, :monto => nil },
	    	{ :anio => 2013, :mes => 11, :dia => 20, :monto => nil },
	    	{ :anio => 2013, :mes => 11, :dia => 25, :monto => nil },
	    	{ :anio => 2013, :mes => 11, :dia => 30, :monto => nil },

	    	# Diciembre 2013
	    	{ :anio => 2013, :mes => 12, :dia => 5, :monto => nil },
	    	{ :anio => 2013, :mes => 12, :dia => 10, :monto => nil },
	    	{ :anio => 2013, :mes => 12, :dia => 15, :monto => nil },
	    	{ :anio => 2013, :mes => 12, :dia => 20, :monto => nil },
	    	{ :anio => 2013, :mes => 12, :dia => 25, :monto => nil },
	    	{ :anio => 2013, :mes => 12, :dia => 30, :monto => nil },

	    	# Enero 2014
	    	{ :anio => 2014, :mes => 1, :dia => 5, :monto => nil },
	    	{ :anio => 2014, :mes => 1, :dia => 10, :monto => nil },
	    	{ :anio => 2014, :mes => 1, :dia => 15, :monto => nil },
	    	{ :anio => 2014, :mes => 1, :dia => 20, :monto => nil },
	    	{ :anio => 2014, :mes => 1, :dia => 25, :monto => nil },
	    	{ :anio => 2014, :mes => 1, :dia => 30, :monto => nil },

	    	# Febrero 2014
	    	{ :anio => 2014, :mes => 2, :dia => 5, :monto => nil },
	    	{ :anio => 2014, :mes => 2, :dia => 10, :monto => nil },
	    	{ :anio => 2014, :mes => 2, :dia => 15, :monto => nil },
	    	{ :anio => 2014, :mes => 2, :dia => 20, :monto => nil },
	    	{ :anio => 2014, :mes => 2, :dia => 25, :monto => nil },
	    	{ :anio => 2014, :mes => 2, :dia => 30, :monto => nil },

	    	# Marzo 2014
	    	{ :anio => 2014, :mes => 3, :dia => 5, :monto => nil },
	    	{ :anio => 2014, :mes => 3, :dia => 10, :monto => nil },
	    	{ :anio => 2014, :mes => 3, :dia => 15, :monto => nil },
	    	{ :anio => 2014, :mes => 3, :dia => 20, :monto => nil },
	    	{ :anio => 2014, :mes => 3, :dia => 25, :monto => nil },
	    	{ :anio => 2014, :mes => 3, :dia => 30, :monto => nil },
	    ]
	end
end

class ConsultasTransitorias::PagosComprometidos

    URL = "/home/jony/Escritorio/salidas/"

    def self.comprometidos nombre_sede, sede_id
    	#_dias = Dias.new
    	#puts _dias.inspect
    	#puts _dias.dias.map{ |x| x[:anio] }.inspect
    	#return

        p_2013_1 = Periodo.first :anio => 2013, :semestre => 1
        instituciones = Institucion.all
        sedes = Sede.all
                
        inscripciones_planes = AlumnoPlanEstudio.all(
            :matricula_plan => {
                :planes_pago => {
                        :periodo_id => [2, 3] # 2012-2, 2013-1
                },
            },
            :institucion_sede_plan => {
	            :institucion_sede    => {
	            	:sede_id => sede_id
	            }
            },
            :estado                         => [Alumno::SIN_INSCRIPCION, Alumno::REGULAR]
        )

        instituciones_sedes_planes = inscripciones_planes.institucion_sede_plan
        planes_estudio = instituciones_sedes_planes.plan_estudio

        pagares = inscripciones_planes.pagares
        pagos_comprometidos = pagares.cuotas :estado.not => [PagoComprometido::PAGADO, PagoComprometido::ANULADO]
        pg_por_mes = pagos_comprometidos.group_by{ |n| n.fecha_vencimiento.month }

	    data = []

        planes_estudio.each do |plan_estudio|
        	#dias = []
        	isp = instituciones_sedes_planes.select{ |x| plan_estudio.id == x.plan_estudio_id }.map{ |x| x.id }
        	ape = inscripciones_planes.select{ |x| isp.include? x.institucion_sede_plan_id }.map{ |x| x.id }
        	pgr = pagares.select{ |x| ape.include? x.alumno_plan_estudio_id }.map{ |x| x.id }
        	pagos = pagos_comprometidos.select{ |x| pgr.include? x.pagare_id }

        	_dias = Dias.new
        	_dias.dias.each do |d|
        		_pagos = pagos.select do |x|  
        			fecha_vencimiento = x.fecha_vencimiento
        			fecha_vencimiento.year == d[:anio] and fecha_vencimiento.month == d[:mes] and fecha_vencimiento.day == d[:dia]
        		end

        		d[:monto] = _pagos.map{ |x| x.monto }.inject(:+)
        		d[:monto] = 0 if d[:monto].nil?
        		#dias << _dias
        	end        	

        	data << {
        		:plan_estudio 	=> plan_estudio,
        		:dias 			=> _dias.dias
        	}
        end

        index = 1
        CSV.open("#{URL}comprometidos_#{nombre_sede}.csv", "w") do |csv|
            begin
                data.each do |i|
                    row     = []

                    row     = [
                        index.to_s,
                        i[:plan_estudio].nombre, 						
                    ].concat(i[:dias].map{ |x| x[:monto] })

                    csv << row
                    index = index + 1
                end
            rescue Exception => e
                puts e.message.bold.red
                puts data[index].inspect
            end
        end
    end
end