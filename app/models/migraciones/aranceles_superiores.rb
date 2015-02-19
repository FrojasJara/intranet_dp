# encoding: utf-8
class Migraciones::ArancelesSuperiores

	def self.ingresar_precios

		begin
		a = "" ; b = "" ; c = "" ; d = "" ; e = ""
			Sede.all.each do |sede|
				puts "SEDE #{sede.nombre}"
				PlanEstudio::MALLAS_HASH.each do |i|
					puts "CARRERA #{i[0]}"
					puts "PRECIO: #{PlanEstudio::PRECIOS_HASH[i[0].to_sym][:PRECIO_NORMAL]}"
					PrecioArancel.transaction do
						# => modalidad Precencial
						a = PrecioArancel.create(
												:mallas_hash => PlanEstudio::const_get(i[0]), 
											 	:sede_id => sede.id,
											 	:modalidad => InstitucionSedePlan::PRESENCIAL, 
											 	:precio => PlanEstudio::PRECIOS_HASH[i[0].to_sym][:PRECIO_NORMAL], 
											 	:contado => false, :anio => 2013, 
											 	:tipo_alumno => Alumno::SUPERIOR, 
											 	:tipo => MatriculaPlan::PROFESIONAL_DOS_SEMESTRES
											 	)

						b = PrecioArancel.create(
												:mallas_hash => PlanEstudio::const_get(i[0]), 
											 	:sede_id => sede.id,
											 	:modalidad => InstitucionSedePlan::PRESENCIAL, 
											 	:precio => PlanEstudio::PRECIOS_HASH[i[0].to_sym][:PRECIO_CONTADO],
											 	:contado => true, :anio => 2013, 
											 	:tipo_alumno => Alumno::SUPERIOR, 
											 	:tipo => MatriculaPlan::PROFESIONAL_DOS_SEMESTRES
											 	)

						c = PrecioMatricula.create(
												:mallas_hash => PlanEstudio::const_get(i[0]), 
												:sede_id => sede.id,
												:modalidad => InstitucionSedePlan::PRESENCIAL, 
												:precio => PlanEstudio::PRECIOS_HASH[i[0].to_sym][:PRECIO_MATRICULA], 
												:fecha_inicio => "2012-12-05", 
												:fecha_termino => "2013-12-05",  
												:tipo_alumno => Alumno::SUPERIOR
												)

						# => Modalidad Distancia
						if PlanEstudio::PRECIOS_HASH[i[0].to_sym].has_key?("PRECIO_MAT_DISTANCIA")
							d = PrecioArancel.create(
													:mallas_hash => PlanEstudio::const_get(i[0]), 
													:sede_id => sede.id, 
													:modalidad => InstitucionSedePlan::DISTANCIA, 
													:precio => PlanEstudio::PRECIOS_HASH[i[0].to_sym][:PRECIO_1R0], 
													:precio_5to => PlanEstudio::PRECIOS_HASH[i[0].to_sym][:PRECIO_5TO],
													:contado => false, :anio => 2013, 
													:tipo_alumno => Alumno::SUPERIOR, 
													:tipo => MatriculaPlan::PROFESIONAL_DOS_SEMESTRES
													)

							e = PrecioMatricula.create(
													:mallas_hash => PlanEstudio::const_get(i[0]), 
													:sede_id => sede.id, 
													:modalidad => InstitucionSedePlan::DISTANCIA,
													:precio => PlanEstudio::PRECIOS_HASH[i[0].to_sym][:PRECIO_MAT_DISTANCIA], 
													:fecha_inicio => "2012-12-05", :fecha_termino => "2013-12-05",  
													:tipo_alumno => Alumno::SUPERIOR
													)
						end
					end
				end
			end
		rescue DataMapper::SaveFailureError => e
			puts "========="
			puts e.resource.errors.inspect
		end
	end
end