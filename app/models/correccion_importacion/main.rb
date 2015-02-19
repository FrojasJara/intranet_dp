# encoding: utf-8
require 'csv'

class CorreccionImportacion::Main

	URL = "/home/jony/Escritorio/"

	def self.carreras_mal_copiadas
		planes_sin_codigo = []
		planes_sin_malla = []
		planes_sin_asignaturas = []

		PlanEstudio.all.each do |plan|
			codigo = plan.siaa_id_ma
			nombre_malla = PlanEstudio::MALLAS_HASH.select{ |malla, ids| ids.include? plan.id }.keys[0]
			asignaturas = plan.asignaturas

			if nombre_malla.blank?
				planes_sin_malla << plan
				next
			end

			if plan.siaa_id_ma.blank?
				planes_sin_codigo << plan
				next
			end

			if asignaturas.empty?
				planes_sin_asignaturas << plan
				next
			end

			asigaturas_ids = asignaturas.map{ |a| a.plan_estudio_id }.uniq
			
			puts "CODIGO: #{codigo}, ID: #{plan.id} | #{plan.nombre}"
			puts "PLANES DE LAS ASIGNATURAS: #{asigaturas_ids.inspect}"
			puts "FAMILIA: #{nombre_malla}".bold.blue
			puts "---------------------------------------".bold.red
		end

		puts "\n\nPLANES SIN MALLA (#{planes_sin_malla.size}): ".bold.green
		planes_sin_malla.each { |plan| puts "#{plan.nombre} - #{plan.revision}" }

		puts "\n\nPLANES SIN CODIGO (#{planes_sin_codigo.size}): ".bold.green
		planes_sin_codigo.each { |plan| puts "#{plan.nombre} - #{plan.revision}" }

		puts "\n\nPLANES SIN ASIGNATURAS (#{planes_sin_asignaturas.size}): ".bold.green
		planes_sin_asignaturas.each { |plan| puts "#{plan.nombre} - #{plan.revision}" }		
	end

	def self.unificar_jornadas input
		ruts = []
		File.foreach(input) do |row| 
			partes = row.split
			ruts << {
				:rut 	=> partes[0].delete("\n"),
				:orden 	=> partes[1].delete("\n")
			}
		end

		#DataMapper::Logger.new(STDOUT, :debug)
		Usuario.all(:rut => ruts.map{|i| i[:rut]}).each do |usuario|
			puts "... Analizando a #{usuario.rut} | #{usuario.nombre} ...".bold
			inscripciones_planes = usuario.alumno.alumno_plan_estudio
			if inscripciones_planes.size == 2
				planes_estudio = inscripciones_planes.institucion_sede_plan.plan_estudio
				if planes_estudio.size == 1

					case ruts.select{|i| i[:rut] == usuario.rut}.first[:orden]
					when "<"
						plan_erroneo = inscripciones_planes[1]
						plan_correcto = inscripciones_planes[0]
					when ">"
						plan_erroneo = inscripciones_planes[0]
						plan_correcto = inscripciones_planes[1]
					end					

					puts "IN #{plan_correcto.id} | OUT #{plan_erroneo.id}"

					#next

					AlumnoPlanEstudio.transaction do
						alumnos_trabajadores = plan_erroneo.alumno_trabajador
						puts "alumno_trabajador: #{alumnos_trabajadores.map{|i| i.id}.inspect}"
						alumnos_trabajadores.update! :alumno_plan_estudio => plan_correcto

						matriculas = plan_erroneo.matricula_plan
						puts "matriculas: #{matriculas.map{|i| i.id}.inspect}"
						matriculas.update! :alumno_plan_estudio => plan_correcto

						secciones = plan_erroneo.links_secciones_inscritas
						puts "secciones: #{secciones.map{|i| i.id}.inspect}"
						secciones.update! :alumno_plan_estudio => plan_correcto

						pagares = plan_erroneo.pagares
						puts "pagares: #{pagares.map{|i| i.id}.inspect}"
						pagares.update! :alumno_plan_estudio => plan_correcto

						documentos = plan_erroneo.documentos_venta
						puts "documentos: #{documentos.map{|i| i.id}.inspect}"
						documentos.update! :alumno_plan_estudio => plan_correcto

						abonos = plan_erroneo.abono
						puts "abonos: #{abonos.map{|i| i.id}.inspect}"
						abonos.update! :alumno_plan_estudio => plan_correcto

						plan_erroneo.destroy!
					end
					
					puts "... Carrera correcta: #{plan_correcto.id} ...".bold
				else
					puts "... No presenta situacion ...".bold
				end
			else
				puts "... No presenta situacion ...".bold
			end
			puts "-------------------------------------------------------------".bold
		end
	rescue DataMapper::SaveFailureError => e
		puts e.resource.errors.inspect.bold.red
	rescue DataObjects::IntegrityError => e
		puts e.backtrace
		puts e.inspect
		puts e.message.bold.red
	rescue Exception => e
		puts e.message.bold.red
	end

	def self.alumnos_jornada_duplicada
		#DataMapper::Logger.new(STDOUT, :debug)
        instituciones = Institucion.all
        sedes = Sede.all
                
        inscripciones_planes = AlumnoPlanEstudio.all(
            :institucion_sede_plan => {
                    :modalidad              => InstitucionSedePlan::PRESENCIAL
            },
            :estado                         => [Alumno::SIN_INSCRIPCION, Alumno::REGULAR, Alumno::SIN_MATRICULA]
        )

        alumnos = inscripciones_planes.alumno
        
        usuarios_alumno = alumnos.datos_personales
        instituciones_sedes_planes = inscripciones_planes.institucion_sede_plan
        instituciones_sedes = instituciones_sedes_planes.institucion_sede
        planes_estudio = instituciones_sedes_planes.plan_estudio

        data = []
        
        #puts "inscripciones: #{inscripciones_planes.size}"
        #puts "alumnos: #{alumnos.size}"
        #puts "usuarios_alumno: #{usuarios_alumno.size}"
        #puts "instituciones_sedes_planes: #{instituciones_sedes_planes.size}"
        #puts "instituciones_sedes: #{instituciones_sedes.size}"
        #puts "planes_estudio: #{planes_estudio.size}"
        #puts "--------------------------------------------------"

        #return
        #puts "planes_estudio: #{planes_estudio.map{|a| a.id}.inspect}"
        puts "... obteniendo informacion ..."
        usuarios_alumno.each do |usuario_alumno|
            alumno = alumnos.select{ |a| a.usuario_id == usuario_alumno.id }.first
            inscripciones = inscripciones_planes.select{ |a| a.alumno_id == alumno.id }
            
            next if not inscripciones.size == 2 

            instituciones_sede_planes_ids = inscripciones.map{ |a| a.institucion_sede_plan_id }
		    carreras_impartidas = instituciones_sedes_planes.select{ |a| instituciones_sede_planes_ids.include? a.id }
		    
		    next if not carreras_impartidas.size == 2

		    planes_estudio_ids = carreras_impartidas.map{ |a| a.plan_estudio_id }
            planes = planes_estudio.select{ |a| planes_estudio_ids.include? a.id }
            
            next if not planes.size == 1

            plan_estudio = planes[0]

            institucion_sede = instituciones_sedes.select{ |a| a.id == carreras_impartidas[0].institucion_sede_id }.first
            institucion = instituciones.select{ |a| a.id == institucion_sede.institucion_id }.first
            sede = sedes.select{ |a| a.id == institucion_sede.sede_id }.first

            data << {
                :usuario                => usuario_alumno,
                :alumno                 => alumno,
                :alumno_plan_estudio    => inscripciones[0],
                :institucion_sede_plan  => carreras_impartidas[0],
                :plan_estudio           => plan_estudio,
                :institucion            => institucion,
                :sede                   => sede
            }
        end

        puts "... creando archivos ..."
        index = 1
        CSV.open("#{URL}alumnos_jornada_duplicada.csv", "w") do |csv|
	        begin
	            data.each do |i|
	                row     = []
	                row     = [
	                    index.to_s,
	                    i[:usuario].rut,
	                    i[:usuario].nombre,
	                    i[:plan_estudio].nombre,
	                    i[:alumno_plan_estudio].anio_ingreso,
	                    i[:institucion].nombre,
	                    i[:sede].nombre
	                ]
	                csv << row
	                index = index + 1
	            end
	        rescue Exception => e
	                puts e.message.bold.red
	                puts data[index].inspect
	        end
        end

        puts "... #{data.size} alumnos obtenidos ..."
	end

	def self.alumnos_inscripciones_asignaturas_erroneas
		#DataMapper::Logger.new(STDOUT, :debug)
        instituciones = Institucion.all
        sedes = Sede.all
                
        inscripciones_planes = AlumnoPlanEstudio.all(
            :institucion_sede_plan => {
                    :institucion_sede => {
                    	:sede_id 	=> 1 # Solo Sede Concepcion
                    }
            },
            :estado                         => [Alumno::SIN_INSCRIPCION, Alumno::REGULAR, Alumno::SIN_MATRICULA]
        )

        alumnos = inscripciones_planes.alumno
        
        usuarios_alumno = alumnos.datos_personales
        instituciones_sedes_planes = inscripciones_planes.institucion_sede_plan
        instituciones_sedes = instituciones_sedes_planes.institucion_sede
        planes_estudio = instituciones_sedes_planes.plan_estudio

        data = []
        
        puts "... obteniendo informacion ..."
        usuarios_alumno.each do |usuario_alumno|
            alumno = alumnos.select{ |a| a.usuario_id == usuario_alumno.id }.first
            inscripciones = inscripciones_planes.select{ |a| a.alumno_id == alumno.id }
            
            next if not inscripciones.size == 1 
            inscripcion = inscripciones[0]

		    carrera_impartida = instituciones_sedes_planes.select{ |a| a.id == inscripcion.institucion_sede_plan_id }.first
		    plan_estudio = planes_estudio.select{ |a| a.id == carrera_impartida.plan_estudio_id }.first
            institucion_sede = instituciones_sedes.select{ |a| a.id == carrera_impartida.institucion_sede_id }.first
            institucion = instituciones.select{ |a| a.id == institucion_sede.institucion_id }.first
            sede = sedes.select{ |a| a.id == institucion_sede.sede_id }.first

            asignaturas_cursadas = inscripcion.links_secciones_inscritas.seccion_dictada.asignatura

            next if asignaturas_cursadas.empty?

            planes_estudio_ids = asignaturas_cursadas.map{ |a| a.plan_estudio_id }.uniq

            next if not planes_estudio_ids.size == 1
            next if plan_estudio.id == planes_estudio_ids[0]

            data << {
                :usuario                => usuario_alumno,
                :alumno                 => alumno,
                :alumno_plan_estudio    => inscripcion,
                :institucion_sede_plan  => carrera_impartida,
                :plan_estudio           => plan_estudio,
                :institucion            => institucion,
                :sede                   => sede
            }
        end

        puts "... creando archivos ..."
        index = 1
        CSV.open("#{URL}alumnos_inscripciones_asignaturas_erroneas.csv", "w") do |csv|
	        begin
	            data.each do |i|
	                row     = []
	                row     = [
	                    index.to_s,
	                    i[:usuario].rut,
	                    i[:usuario].nombre,
	                    i[:plan_estudio].nombre,
	                    i[:alumno_plan_estudio].anio_ingreso,
	                    i[:institucion].nombre,
	                    i[:sede].nombre
	                ]
	                csv << row
	                index = index + 1
	            end
	        rescue Exception => e
	                puts e.message.bold.red
	                puts data[index].inspect
	        end
        end

        puts "... #{data.size} alumnos obtenidos ..."
	end

	def self.unificar_aignaturas_erroneas input
		ruts = []
		File.foreach(input){ |row| ruts << row.delete("\n") }

		Usuario.all(:rut => ruts).each do |usuario|
			inscripciones_planes = usuario.alumno.alumno_plan_estudio
			next if not inscripciones_planes.size == 1 
			
			planes_estudio = inscripciones_planes.institucion_sede_plan.plan_estudio
			next if not planes_estudio.size == 1

			plan_estudio = planes_estudio[0]
			inscripcion_plan = inscripciones_planes[0]
					
			asignaturas = inscripcion_plan.links_secciones_inscritas.seccion_dictada.asignatura
			planes_estudio_ids = asignaturas.map{ |a| a.plan_estudio_id }.uniq

			next if not planes_estudio_ids.size == 1
         	next if plan_estudio.id == planes_estudio_ids[0]

         	institucion_sede_plan = inscripcion_plan.institucion_sede_plan
         	nuevo_plan_estudio_id = planes_estudio_ids[0]

         	nuevo_plan_estudio = PlanEstudio.get nuevo_plan_estudio_id
         	es_plan_distancia = (nuevo_plan_estudio.nombre.include?("Distancia") or nuevo_plan_estudio.nombre.include?("distancia"))

         	institucion_sede_plan_nuevo = nil

         	if es_plan_distancia
         		_institucion_sede_plan_nuevo = {
					:institucion_sede_id 	=> institucion_sede_plan.institucion_sede_id,
					:estado 				=> InstitucionSedePlan::ABIERTA,
					:jornada 				=> nil,
					:modalidad 				=> InstitucionSedePlan::DISTANCIA,
					:periodo_id 			=> institucion_sede_plan.periodo_id,
					:plan_estudio_id 		=> nuevo_plan_estudio_id
         		}
         	else
         		_institucion_sede_plan_nuevo = {
					:institucion_sede_id 	=> institucion_sede_plan.institucion_sede_id,
					:estado 				=> InstitucionSedePlan::ABIERTA,
					:jornada 				=> institucion_sede_plan.jornada,
					:modalidad 				=> institucion_sede_plan.modalidad,
					:periodo_id 			=> institucion_sede_plan.periodo_id,
					:plan_estudio_id 		=> nuevo_plan_estudio_id
				}
         	end

			AlumnoPlanEstudio.transaction do
				institucion_sede_plan_nuevo = InstitucionSedePlan.first_or_create _institucion_sede_plan_nuevo
				inscripcion_plan.update :institucion_sede_plan => institucion_sede_plan_nuevo
			end

			puts "... Aanalizado #{usuario.rut} | #{usuario.nombre} ...".bold
			puts "Carrera anterior: #{plan_estudio.id} | Carrera nueva: #{nuevo_plan_estudio_id}"
			puts "InstitucionSedePlan anterior: #{institucion_sede_plan.id} | InstitucionSedePlan nueva: #{institucion_sede_plan_nuevo.id}"
			puts "DISTANCIA".bold.blue if es_plan_distancia
			puts "-------------------------------------------------------------".bold.red
		end
	rescue DataMapper::SaveFailureError => e
		puts e.resource.errors.inspect.bold.red
	rescue DataObjects::IntegrityError => e
		puts e.backtrace
		puts e.inspect
		puts e.message.bold.red
	rescue Exception => e
		puts e.backtrace
		puts e.inspect
		puts e.message.bold.red
	end

	def self.alumnos_inscripciones_asignaturas_erroneas_multiples
		#DataMapper::Logger.new(STDOUT, :debug)
        instituciones = Institucion.all
        sedes = Sede.all
                
        inscripciones_planes = AlumnoPlanEstudio.all(
            :institucion_sede_plan => {
                    :institucion_sede => {
                    	:sede_id 	=> 1 # Solo Sede Concepcion
                    }
            },
            :estado                         => [Alumno::SIN_INSCRIPCION, Alumno::REGULAR, Alumno::SIN_MATRICULA]
        )

        alumnos = inscripciones_planes.alumno
        
        usuarios_alumno = alumnos.datos_personales
        instituciones_sedes_planes = inscripciones_planes.institucion_sede_plan
        instituciones_sedes = instituciones_sedes_planes.institucion_sede
        planes_estudio = instituciones_sedes_planes.plan_estudio

        data = []
        
        puts "... obteniendo informacion ..."
        usuarios_alumno.each do |usuario_alumno|
            alumno = alumnos.select{ |a| a.usuario_id == usuario_alumno.id }.first
            inscripciones = inscripciones_planes.select{ |a| a.alumno_id == alumno.id }
            
            next if not inscripciones.size == 1 
            inscripcion = inscripciones[0]

		    carrera_impartida = instituciones_sedes_planes.select{ |a| a.id == inscripcion.institucion_sede_plan_id }.first
		    plan_estudio = planes_estudio.select{ |a| a.id == carrera_impartida.plan_estudio_id }.first
            institucion_sede = instituciones_sedes.select{ |a| a.id == carrera_impartida.institucion_sede_id }.first
            institucion = instituciones.select{ |a| a.id == institucion_sede.institucion_id }.first
            sede = sedes.select{ |a| a.id == institucion_sede.sede_id }.first

            asignaturas_cursadas = inscripcion.links_secciones_inscritas.seccion_dictada.asignatura

            next if asignaturas_cursadas.empty?

            planes_estudio_ids = asignaturas_cursadas.map{ |a| a.plan_estudio_id }.uniq

            # !! INCRIPCIONES QUE APUNTAN A MUCHOS ...
            next if not planes_estudio_ids.size > 1
            next if not planes_estudio_ids.include? plan_estudio.id

            data << {
                :usuario                => usuario_alumno,
                :alumno                 => alumno,
                :alumno_plan_estudio    => inscripcion,
                :institucion_sede_plan  => carrera_impartida,
                :plan_estudio           => plan_estudio,
                :institucion            => institucion,
                :sede                   => sede
            }
        end

        puts "... creando archivos ..."
        index = 1
        CSV.open("#{URL}alumnos_inscripciones_asignaturas_erroneas_multiples.csv", "w") do |csv|
	        begin
	            data.each do |i|
	                row     = []
	                row     = [
	                    index.to_s,
	                    i[:usuario].rut,
	                    i[:usuario].nombre,
	                    i[:plan_estudio].nombre,
	                    i[:alumno_plan_estudio].anio_ingreso,
	                    i[:institucion].nombre,
	                    i[:sede].nombre
	                ]
	                csv << row
	                index = index + 1
	            end
	        rescue Exception => e
	                puts e.message.bold.red
	                puts data[index].inspect
	        end
        end

        puts "... #{data.size} alumnos obtenidos ..."
	end
end