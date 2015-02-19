# encoding: utf-8
class Migraciones::Instituciones
	def self.preu_ceia_concepcion_2013_1
		Institucion.transaction do
			p2013_1 = Periodo.first :anio => 2013, :semestre => 1

			i_ceia = Institucion.first :tipo => Institucion::CEIA
			institucion_sede_ceia_conce = i_ceia.institucion_sede.create :sede_id => 1			
			ceia_1_nivel = PlanEstudio.first :nombre => "1º Nivel (1 y 2 medio)"
			ceia_2_nivel = PlanEstudio.first :nombre => "2º Nivel (3 y 4 medio)"

			ceia_conce_1_nivel_diurno = InstitucionSedePlan.create(
				:institucion_sede_id 	=> institucion_sede_ceia_conce.id, 
				:plan_estudio_id 		=> ceia_1_nivel.id, 
				:periodo_id 			=> p2013_1.id, 
				:modalidad 				=> InstitucionSedePlan::PRESENCIAL, 
				:jornada 				=> InstitucionSedePlan::DIURNA,
				:estado 				=> InstitucionSedePlan::ABIERTA
			)

			ceia_conce_2_nivel_diurno = InstitucionSedePlan.create(
				:institucion_sede_id 	=> institucion_sede_ceia_conce.id, 
				:plan_estudio_id 		=> ceia_2_nivel.id, 
				:periodo_id 			=> p2013_1.id, 
				:modalidad 				=> InstitucionSedePlan::PRESENCIAL, 
				:jornada 				=> InstitucionSedePlan::DIURNA,
				:estado 				=> InstitucionSedePlan::ABIERTA
			)

			ceia_conce_1_nivel_vesper = InstitucionSedePlan.create(
				:institucion_sede_id 	=> institucion_sede_ceia_conce.id, 
				:plan_estudio_id 		=> ceia_1_nivel.id, 
				:periodo_id 			=> p2013_1.id, 
				:modalidad 				=> InstitucionSedePlan::PRESENCIAL, 
				:jornada 				=> InstitucionSedePlan::VESPERTINA,
				:estado 				=> InstitucionSedePlan::ABIERTA
			)

			ceia_conce_2_nivel_vesper = InstitucionSedePlan.create(
				:institucion_sede_id 	=> institucion_sede_ceia_conce.id, 
				:plan_estudio_id 		=> ceia_2_nivel.id, 
				:periodo_id 			=> p2013_1.id, 
				:modalidad 				=> InstitucionSedePlan::PRESENCIAL, 
				:jornada 				=> InstitucionSedePlan::VESPERTINA,
				:estado 				=> InstitucionSedePlan::ABIERTA
			)

			i_preu = Institucion.create(
				:rut => '3.619.095-7', 
				:tipo => Institucion::PREU, 
				:razon_social => 'Preuniversitario Diego Portales Ltda.', 
				:nombre => "Preuniversitario"
			)
			institucion_sede_preu_conce = i_preu.institucion_sede.create :sede_id => 1
			preu_modulo_1 = PlanEstudio.first :nombre => "Lenguage - Matemáticas - Ciencias"
			preu_modulo_2 = PlanEstudio.first :nombre => "Lenguage - Matemáticas - Historia"

			preu_conce_modulo_1_diurno = InstitucionSedePlan.create(
				:institucion_sede_id 	=> institucion_sede_preu_conce.id, 
				:plan_estudio_id 		=> preu_modulo_1.id, 
				:periodo_id 			=> p2013_1.id, 
				:modalidad 				=> InstitucionSedePlan::PRESENCIAL, 
				:jornada 				=> InstitucionSedePlan::DIURNA,
				:estado 				=> InstitucionSedePlan::ABIERTA
			)

			preu_conce_modulo_2_diurno = InstitucionSedePlan.create(
				:institucion_sede_id 	=> institucion_sede_preu_conce.id, 
				:plan_estudio_id 		=> preu_modulo_2.id, 
				:periodo_id 			=> p2013_1.id, 
				:modalidad 				=> InstitucionSedePlan::PRESENCIAL, 
				:jornada 				=> InstitucionSedePlan::DIURNA,
				:estado 				=> InstitucionSedePlan::ABIERTA
			)

			preu_conce_modulo_1_vesper = InstitucionSedePlan.create(
				:institucion_sede_id 	=> institucion_sede_preu_conce.id, 
				:plan_estudio_id 		=> preu_modulo_1.id, 
				:periodo_id 			=> p2013_1.id, 
				:modalidad 				=> InstitucionSedePlan::PRESENCIAL, 
				:jornada 				=> InstitucionSedePlan::VESPERTINA,
				:estado 				=> InstitucionSedePlan::ABIERTA
			)

			preu_conce_modulo_2_vesper = InstitucionSedePlan.create(
				:institucion_sede_id 	=> institucion_sede_preu_conce.id, 
				:plan_estudio_id 		=> preu_modulo_2.id, 
				:periodo_id 			=> p2013_1.id, 
				:modalidad 				=> InstitucionSedePlan::PRESENCIAL, 
				:jornada 				=> InstitucionSedePlan::VESPERTINA,
				:estado 				=> InstitucionSedePlan::ABIERTA
			)
		end
		puts "... registros agregados con exito ...".bold.blue
	rescue Exception
		puts "... ha ocurrido un error ...".bold.red
	end
end