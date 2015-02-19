# encoding: utf-8
require 'csv'

class ConsultasSistemaAntiguo::Distancia

	URL = "/home/jony/Escritorio/"

	def self.toma_examenes sede
		# DataMapper::Logger.new(STDOUT, :debug)
		data = []

		carreras_distancia = ModelosAntiguos::Carrera.all(:fields => [:id_ca, :nombre_ca], :conditions => ["nombre_ca LIKE '%DISTANCIA%'"])
		matriculas = carreras_distancia.matriculas :ano_ma 	=> 2012, :sem_ma => 2

		alumnos = ModelosAntiguos::Persona.all(
			:fields => [:rut_pe, :digito_pe, :nombre_pe, :apellido_pe, :domicilio_pe, :sector_pe],
			:rut_pe => matriculas.map{ |a| a.rut_al }
		)

		asignaturas_impartidas = ModelosAntiguos::AsignaturaImpartida.all(:ano_ai => 2012, :sem_ai => 2, :id_ca => carreras_distancia.map{|c| c.id_ca}).asignaturas
		asignaturas_distancia = ModelosAntiguos::Asignatura.all(:fields => [:id_as, :nombre_as, :id_ca], :id_as => asignaturas_impartidas.map{|i| i.id_as})
		inscripciones_asignaturas = ModelosAntiguos::InscripcionAsignatura.all(
			:fields => [:rut_al, :id_ca, :id_as],
			:ano_in => 2012, :sem_in => 2,
			:rut_al => alumnos.map{ |a| a.rut_pe },
			:id_ca => carreras_distancia.map{ |q| q.id_ca },
			:id_as => asignaturas_distancia.map{|w| w.id_as}
		)
		notas = ModelosAntiguos::Nota.all(
			:fields => [:rut_al, :id_as, :nota_no, :id_tn, :id_ca, :nro_ce],
			:ano_no => 2012, :sem_no => 2,
			:rut_al => alumnos.map{ |a| a.rut_pe },
			:id_as 	=> asignaturas_distancia.map{ |a| a.id_as },
			:order => :nro_ce.asc
		)

		# tipos_notas = ConsultasSistemaAntiguo::TipoNota.all

		puts "... creando estructura de datos ...".bold.red
		alumnos.each do |alumno|
			_inscripciones = inscripciones_asignaturas.select{ |w| w.rut_al == alumno.rut_pe }
			_id_asignaturas = _inscripciones.map{ |w| w.id_as }
			_asignaturas = asignaturas_distancia.select{ |w| _id_asignaturas.include? w.id_as }

			_asignaturas.each do |asignatura|
				item = {}

				item[:alumno] = alumno
				item[:carrera] = carreras_distancia.select{ |w| w.id_ca == asignatura.id_ca }.first
				item[:asignatura] = asignatura
				item[:notas] = _notas = notas.select{ |w| w.rut_al == alumno.rut_pe and w.id_as == asignatura.id_as } 
				
				data << item
			end
		end

		puts "... generando CSV ...".bold.red
		index = 1
		CSV.open("#{URL}alumnos_distancia_2012_2_#{sede}.csv", "w") do |csv|
			data.each do |i|
				row 	= []
				row 	= [
					index.to_s,
					i[:alumno].apellido_pe.to_s.unpack("C*").pack("U*"),
					i[:alumno].nombre_pe.to_s.unpack("C*").pack("U*"),
					i[:carrera].nombre_ca.to_s.unpack("C*").pack("U*"),
					i[:asignatura].nombre_as.to_s.unpack("C*").pack("U*")
				]

				# Primera nota parcial
				nota 	= [""]
				_nota = [i[:notas].select{ |i| i.id_tn.to_i == ConsultasSistemaAntiguo::TipoNota::PRUEBA_PARCIAL }[0]]
				nota = _nota.map{ |w| w.nota_no.to_s.unpack("C*").pack("U*") if not w.nil? } if not _nota.empty?
				row.concat nota

				# Primera nota parcial
				nota 	= [""]
				_nota = [i[:notas].select{ |i| i.id_tn.to_i == ConsultasSistemaAntiguo::TipoNota::PRUEBA_PARCIAL }[1]]
				nota = _nota.map{ |w| w.nota_no.to_s.unpack("C*").pack("U*") if not w.nil? } if not _nota.empty?
				row.concat nota

				# Nota de presentacion
				nota 	= [""]
				_nota = i[:notas].select{ |i| i.id_tn.to_i == ConsultasSistemaAntiguo::TipoNota::NOTA_PRESENTACION }
				nota = _nota.map{ |w| w.nota_no.to_s.unpack("C*").pack("U*") if not w.nil? } if not _nota.empty?
				row.concat nota

				# Nota examen final
				nota 	= [""]
				_nota = i[:notas].select{ |i| i.id_tn.to_i == ConsultasSistemaAntiguo::TipoNota::EXAMEN_FINAL }
				nota = _nota.map{ |w| w.nota_no.to_s.unpack("C*").pack("U*") if not w.nil? } if not _nota.empty?
				row.concat nota

				# Nota examen repeticion
				nota 	= [""]
				_nota = i[:notas].select{ |i| i.id_tn.to_i == ConsultasSistemaAntiguo::TipoNota::EXAMEN_REPETICION }
				nota = _nota.map{ |w| w.nota_no.to_s.unpack("C*").pack("U*") if not w.nil? } if not _nota.empty?
				row.concat nota

				# Nota final
				nota 	= [""]
				_nota = i[:notas].select{ |i| i.id_tn.to_i == ConsultasSistemaAntiguo::TipoNota::NOTA_FINAL }
				nota = _nota.map{ |w| w.nota_no.to_s.unpack("C*").pack("U*") if not w.nil? } if not _nota.empty?
				row.concat nota

				csv << row
				index = index + 1
			end
		end

		#log_file = File.open("#{URL}/log.txt", "w") do |file|
		#	data.each do |i|
		#		file.puts "#{i[:alumno].apellido_pe.to_s.unpack('C*').pack('U*')} #{i[:alumno].nombre_pe.to_s.unpack('C*').pack('U*')}"
		#		file.puts "#{i[:carrera].nombre_ca.to_s.unpack('C*').pack('U*')}"
		#		file.puts "\t\t#{i[:asignatura].nombre_as.to_s.unpack('C*').pack('U*')}"
		#		i[:notas].each do |nota|
		#			file.puts "\t\t\t#{nota.nota_no.to_s.unpack('C*').pack('U*')}"
		#		end
		#	end
		#end
	end

	def self.alumnos_2012_2 sede
		# DataMapper::Logger.new(STDOUT, :debug)
		data = []

		carreras_distancia = ModelosAntiguos::Carrera.all(:fields => [:id_ca, :nombre_ca], :conditions => ["nombre_ca LIKE '%DISTANCIA%'"])
		matriculas = carreras_distancia.matriculas :ano_ma 	=> 2012, :sem_ma => 2

		alumnos = ModelosAntiguos::Persona.all(
			:fields => [:rut_pe, :digito_pe, :nombre_pe, :apellido_pe, :domicilio_pe, :sector_pe],
			:rut_pe => matriculas.map{ |a| a.rut_al }
		)

		puts "... creando estructura de datos ...".bold.red
		alumnos.each do |alumno|
			matricula = matriculas.select{ |matricula| alumno.rut_pe == matricula.rut_al }.first
			carrera = carreras_distancia.select{ |carrera| carrera.id_ca == matricula.id_ca }.first
			data << {
				:alumno 	=> alumno,
				:carrera 	=> carrera
			}
		end
		
		puts "... generando CSV ...".bold.red
		index = 1
		CSV.open("#{URL}alumnos_distancia_2012_2_#{sede}.csv", "w") do |csv|
			data.each do |item|
				csv << [
					index,
					item[:alumno].rut_pe.to_s.unpack("C*").pack("U*"),
					item[:alumno].nombre_pe.unpack("C*").pack("U*"),
					item[:alumno].apellido_pe.unpack("C*").pack("U*"),
					item[:carrera].nombre_ca.unpack("C*").pack("U*")
				]
				index = index + 1
			end
		end
	end
end