# encoding: utf-8
require 'csv'

class ConsultasSistemaAntiguo::Construccion

	URL = "/home/jony/Escritorio/"

	def self.matriculas_2012_tecnico_construccion
		# DataMapper::Logger.new(STDOUT, :debug)
		data = []
		tecnico_construccion_id = 18 

		matriculas = ModelosAntiguos::Matricula.all(:ano_ma => 2012, :sem_ma => [1, 2], :id_ca => tecnico_construccion_id, :order => [:sem_ma.asc])

		alumnos = ModelosAntiguos::Persona.all(
			:fields => [:rut_pe, :digito_pe, :nombre_pe, :apellido_pe],
			:rut_pe => matriculas.map{ |a| a.rut_al }
		)

		data = []
		alumnos.each do |alumno|
			matricula = matriculas.select{ |m| m.rut_al == alumno.rut_pe }.first
			data << {
				:alumno 	=> alumno,
				:matricula 	=> matricula
			}
		end

		CSV.open("#{URL}alumnos_construccion_2012.csv", "w") do |csv|
			data.each_with_index do |item, index|
				alumno = item[:alumno]
				matricula = item[:matricula]

				csv << [
					(index + 1).to_s,
					alumno.nombre_pe.to_s.unpack("C*").pack("U*"),
					alumno.apellido_pe.to_s.unpack("C*").pack("U*"),
					alumno.rut_pe.to_s.unpack("C*").pack("U*"),
					"#{matricula.ano_ma}-#{matricula.sem_ma}"
				]
			end
		end
	end
end