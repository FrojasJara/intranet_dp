# encoding: utf-8
require 'csv'

class Migraciones::Usuarios

	URL = Rails.root.to_s

	def self.verificar_usuarios_invalidos
		usuarios = Usuario.all

		File.open("#{URL}/usuarios_invalidos.txt", "w") do |f|
			usuarios.each_with_index do |usuario, index|
				if not usuario.valid?
					puts "... (#{index}) analizando usuario #{usuario.rut} INVALIDDO".bold.red
					f.puts "ID: #{usuario.id} | Rut: #{usuario.rut}"
					f.puts "Errores: #{usuario.errors.inspect}"
					f.puts "---------------------------------------------------------"
				else
					puts "... (#{index}) analizando usuario #{usuario.rut}".bold.blue
				end
			end
		end
	end

	def self.alumnos_inconsistentes
		usuarios = Usuario.all :tipo => Usuario::ESTUDIANTE
		puts "... #{usuarios.size} usuarios alumno en total ..."
		sin_alumno = []
		sin_alumno_plan_estudio = []
		sin_nada = []

		File.open("#{URL}/alumnos_inconsistentes.txt", "w") do |f|
			usuarios.each_with_index do |usuario, index|
				alumno = usuario.alumno
				if not alumno.nil?
					if not alumno.alumno_plan_estudio.empty?
						puts "... (#{index}) #{usuario.id} | #{usuario.rut} : Con instancia alumno_plan_estudio".blue.bold
					else
						sin_alumno_plan_estudio << usuario.id
						puts "... (#{index}) #{usuario.id} | #{usuario.rut} : Sin instancia alumno_plan_estudio".red.bold
						f.puts "... (#{index}) #{usuario.id} | #{usuario.rut} : Sin instancia alumno_plan_estudio"
						f.puts "---------------------------------------------------------"
					end
				else
					sin_alumno << usuario.id
					puts "... (#{index}) #{usuario.id} | #{usuario.rut} : Sin instancia alumno".red.bold
					f.puts "... (#{index}) #{usuario.id} | #{usuario.rut} : Sin instancia alumno"
					
					#if not usuario.docente.nil? or not usuario.apoderado.nil?
					#	puts "... (#{index}) #{usuario.id} | #{usuario.rut} : Con instancia docente o apoderado".blue.bold
					#else
					#	sin_nada << usuario.id
					#	puts "... (#{index}) #{usuario.id} | #{usuario.rut} : Sin instancia docente ni apoderado".red.bold
					#	f.puts "... (#{index}) #{usuario.id} | #{usuario.rut} : Sin instancia docente ni apoderado"
					#end
					#f.puts "---------------------------------------------------------"
				end
			end
			f.puts "SIN ALUMNO:"
			f.puts "#{sin_alumno.join(',')}"
			f.puts "-------------------------------------------------------------------------"
			f.puts "SIN ALUMNO PLAN ESTUDIO:"
			f.puts "#{sin_alumno_plan_estudio.join(',')}"
			#f.puts "-------------------------------------------------------------------------"
			#f.puts "SIN NADA:"
			#f.puts "#{sin_nada.join(',')}"
		end
	end
end