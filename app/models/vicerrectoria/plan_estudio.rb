class Vicerrectoria::PlanEstudio
	def self.guardar_nuevo_plan_estudio plan_estudio
		PlanEstudio.transaction do
			nuevo_plan = PlanEstudio.new
			nuevo_plan.nombre 					= plan_estudio[:nombre]
			nuevo_plan.nivel					= plan_estudio[:nivel].to_i
			nuevo_plan.tiene_salida_intermedia  = plan_estudio[:tiene_salida_intermedia] == "on" ? true : false
			nuevo_plan.duracion					= plan_estudio[:duracion].to_i
			nuevo_plan.semestre_inicio			= plan_estudio[:semestre_inicio].to_i
			nuevo_plan.anio_inicio				= plan_estudio[:anio_inicio].to_i
			nuevo_plan.anio_fin					= plan_estudio[:anio_fin].to_i
			nuevo_plan.titulo_profesional		= plan_estudio[:titulo_profesional]
			nuevo_plan.titulo_tecnico			= plan_estudio[:titulo_tecnico]
			nuevo_plan.certificado				= plan_estudio[:certificado]
			nuevo_plan.licenciatura				= plan_estudio[:licenciatura]
			nuevo_plan.estado 					= plan_estudio[:estado].to_i
			nuevo_plan.revision					= plan_estudio[:revision]
		
			nuevo_plan.save
		end
		
	end

	def self.registrar_asignatura_plan_estudio asignatura
		Asignatura.transaction do
			nueva_asignatura =  Asignatura.new
			nueva_asignatura.nombre 		= asignatura[:nombre]
			nueva_asignatura.semestre 		= asignatura[:semestre].to_i
			nueva_asignatura.codigo			= asignatura[:codigo].to_i
			nueva_asignatura.plan_estudio_id 	= asignatura[:plan_estudio_id].to_i

			nueva_asignatura.save
		end
	end
end