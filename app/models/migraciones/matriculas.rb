# encoding: utf-8
class Migraciones::Matriculas

	URL = Rails.root.to_s

	# def self.copiar_ejecutivo_en_matriculas_y_planes
	# 	matriculas = MatriculaPlan.all
	# 	ids = []
	# 	# DataMapper::Logger.new(STDOUT, :debug)
	# 	MatriculaPlan.transaction do
	# 		usuario_ejecutivo = Usuario.create(
	# 			:rut 				=> "0000000-0",
	# 			:password 			=> Digest::MD5.hexdigest("0000000-0"),
	# 			:primer_nombre 		=> "Ejectutivo de matrículas",
	# 			:segundo_nombre 	=> "No tiene",
	# 			:apellido_paterno 	=> "No tiene",
	# 			:apellido_materno 	=> "No tiene",
	# 			:domicilio 			=> "Maipu 301",
	# 			:tipo 				=> Usuario::ADMINISTRATIVO,
	# 			:region_id 			=> 1,
	# 			:pais_id 			=> 1,
	# 			:comuna_id 			=> 1,
	# 			:rol_id 			=> 5,
	# 			:sede_id 			=> 1,
	# 			:email 				=> "notiene@correo.cl"
	# 		)

	# 		ejecutivo = EjecutivoMatriculas.create :usuario_id =>  usuario_ejecutivo.id

	# 		File.open("#{URL}/matriculas_sin_ejecutivo.txt", "w") do |f|
	# 			matriculas.each do |matricula|
	# 				planes 				= matricula.planes_pago
	# 				pago_comprometido 	= planes.pagos_comprometidos(:ejecutivo_matriculas_id.not => nil).first
	# 				pagare 				= planes.pagares(:ejecutivo_matriculas_id.not => nil).first
	# 				documento 			= planes.documentos_venta(:ejecutivo_matriculas_id.not => nil).first

	# 				if not pagare.nil?
	# 					puts "... editando matricula #{matricula.id} y sus planes. Ejecutivo de matriculas #{pagare.ejecutivo_matriculas_id}".bold.blue
	# 					planes.update :ejecutivo_matriculas_id => pagare.ejecutivo_matriculas_id
	# 					matricula.update :ejecutivo_matriculas_id => pagare.ejecutivo_matriculas_id
	# 					pagos 	= planes.pagos_comprometidos(:ejecutivo_matriculas_id => nil)
	# 					abonos 	= pagos.abonos(:ejecutivo_matriculas_id => nil)
						
	# 					pagos.update :ejecutivo_matriculas_id => pagare.ejecutivo_matriculas_id
	# 					abonos.update :ejecutivo_matriculas_id => pagare.ejecutivo_matriculas_id
	# 					next
	# 				end

	# 				if not documento.nil?
	# 					puts "... editando matricula #{matricula.id} y sus planes. Ejecutivo de matriculas #{documento.ejecutivo_matriculas_id}".bold.blue
	# 					planes.update :ejecutivo_matriculas_id => documento.ejecutivo_matriculas_id
	# 					matricula.update :ejecutivo_matriculas_id => documento.ejecutivo_matriculas_id
	# 					pagos 	= planes.pagos_comprometidos(:ejecutivo_matriculas_id => nil)
	# 					abonos 	= pagos.abonos(:ejecutivo_matriculas_id => nil)

	# 					pagos.update :ejecutivo_matriculas_id => documento.ejecutivo_matriculas_id
	# 					abonos.update :ejecutivo_matriculas_id => documento.ejecutivo_matriculas_id
	# 					next
	# 				end

	# 				if not pago_comprometido.nil?
	# 					puts "... editando matricula #{matricula.id} y sus planes. Ejecutivo de matriculas #{pago_comprometido.ejecutivo_matriculas_id}".bold.blue
	# 					planes.update :ejecutivo_matriculas_id => pago_comprometido.ejecutivo_matriculas_id
	# 					matricula.update :ejecutivo_matriculas_id => pago_comprometido.ejecutivo_matriculas_id
	# 					pagos 	= planes.pagos_comprometidos(:ejecutivo_matriculas_id => nil)
	# 					abonos 	= pagos.abonos(:ejecutivo_matriculas_id => nil)

	# 					pagos.update :ejecutivo_matriculas_id => pago_comprometido.ejecutivo_matriculas_id
	# 					abonos.update :ejecutivo_matriculas_id => pago_comprometido.ejecutivo_matriculas_id
	# 					next
	# 				end

	# 				matricula.update :ejecutivo_matriculas => ejecutivo
	# 				planes.update :ejecutivo_matriculas => ejecutivo

	# 				ids << matricula.id
	# 				f.puts "... matricula #{matricula.id} no tiene planes ni pagares. Planes #{planes.map{ |p| p.id }.to_s}"
	# 				puts "... matricula #{matricula.id} no tiene planes ni pagares. Planes #{planes.map{ |p| p.id }.to_s}".bold.red
				
	# 			end
	# 			f.puts "-------------------------"
	# 			f.puts "Matriculas"
	# 			f.puts "#{ids.join(',').to_s}"
	# 		end
	# 	end
	# rescue DataMapper::SaveFailureError => e
	# 	puts e.resource.errors.inspect
	# end

	def self.definir_matriculas_y_planes_vigentes
		periodo_actual = Periodo.first :anio => 2013, :semestre => 1
		puts "... corrigiendo estado de matriculas actuales...".bold.blue
		periodo_actual.matriculas.update :estado => MatriculaPlan::VIGENTE
		puts "... corrigiendo estado de planes actuales...".bold.blue
		periodo_actual.planes_pago.update :estado => PlanPago::VIGENTE
		puts "... corrigiendo estado de alumno plan de estudio actuales".bold.blue
		periodo_actual.matriculas.alumno_plan_estudio.update :estado => Alumno::SIN_INSCRIPCION

		otros_periodos = Periodo.all :anio.not => 2013
		puts "... corrigiendo estado de matriculas expiradas...".bold.blue
		otros_periodos.matriculas.update :estado => MatriculaPlan::EXPIRADA
		puts "... corrigiendo estado de planes expirados...".bold.blue
		otros_periodos.planes_pago.update :estado => PlanPago::FINIQUITADO
	end

	def self.actualizar_estado_alumnos_superiores
		periodo_actual = Periodo.first( :anio => 2012, :semestre => 1 )
		puts "cambiando todos los usuarios a SIN_MATRICULA para periodo 2012".bold.blue
		periodo_actual.matriculas(:siaa_id.not => nil).alumno_plan_estudio.update :estado => Alumno::SIN_MATRICULA
		periodo_actual = Periodo.first( :anio => 2013, :semestre => 1 )
		puts "cambiando todos los usuarios a SIN_INSCRIPCION para periodo 2013".bold.blue
		periodo_actual.matriculas(:siaa_id.not => nil).alumno_plan_estudio.update :estado => Alumno::SIN_INSCRIPCION
	end
	
end