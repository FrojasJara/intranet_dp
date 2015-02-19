# encoding: utf-8
require "date"

class Matriculas::InstitucionSedePlan

    def self.planes_alumno_nuevo periodo_id, sede_id
        data = {}

		instituciones 	= Institucion.all
		ip 				= instituciones.select{ |i| i.tipo == Institucion::IP }.first
		ceia 			= instituciones.select{ |i| i.tipo == Institucion::CEIA }.first
		preu 			= instituciones.select{ |i| i.tipo == Institucion::PREU }.first
		otec 			= instituciones.select{ |i| i.tipo == Institucion::OTEC }.first

		instituciones_sedes 	= InstitucionSede.all :sede_id => sede_id, :institucion => instituciones
		institucion_sede_ip 	= instituciones_sedes.select{ |i| i.institucion_id == ip.id }.first
		institucion_sede_ceia 	= instituciones_sedes.select{ |i| i.institucion_id == ceia.id }.first
		institucion_sede_preu 	= instituciones_sedes.select{ |i| i.institucion_id == preu.id }.first
		institucion_sede_otec 	= instituciones_sedes.select{ |i| i.institucion_id == otec.id }.first

		ultimos_planes 		= InstitucionSedePlan.all :periodo_id => periodo_id, :institucion_sede => instituciones_sedes, :estado => InstitucionSedePlan::ABIERTA
		aranceles 			= ultimos_planes.aranceles :tipo_alumno => Alumno::NUEVO, :tipo => MatriculaPlan::MATRICULAS_ALUMNO_NUEVO
		matriculas 			= ultimos_planes.matriculas :fecha_inicio.lte => Date.today, :fecha_termino.gt => Date.today, :tipo_alumno => Alumno::NUEVO

		planes = ultimos_planes.plan_estudio

		data[:planes_diurnos] = []
		ultimos_planes.select{ |link_plan| link_plan.modalidad == InstitucionSedePlan::PRESENCIAL and link_plan.jornada == InstitucionSedePlan::DIURNA }.each do |link_plan|
			plan = planes.select{ |plan| plan.id == link_plan.plan_estudio_id }.first

			# Solo las carreras para el IP, profesionale y tecnicas
			next if not plan.nivel == PlanEstudio::PROFESIONAL and not plan.nivel == PlanEstudio::TECNICO
			
			arancel = (a_s = aranceles.select{ |arancel| link_plan.id == arancel.institucion_sede_plan_id and arancel.contado == false }.first).nil? ? 0 : a_s.precio
            arancel_contado = (a_c = aranceles.select{ |arancel| link_plan.id == arancel.institucion_sede_plan_id and arancel.contado == true }.first).nil? ? 0 : a_c.precio
			matricula = (m_s = matriculas.select{ |matricula| link_plan.id == matricula.institucion_sede_plan_id }.first).nil? ? 0 : m_s.precio
            data[:planes_diurnos] << {
                    :institucion_sede_plan_id      => link_plan.id,
                    :nombre                        => "#{plan.nombre} - rev #{plan.revision}",
                    :arancel                       => arancel,
                    :arancel_contado               => arancel_contado,
                    :matricula                     => matricula,
                    :tipo_matricula                => (plan.nivel == PlanEstudio::PROFESIONAL) ? MatriculaPlan::PROFESIONAL_DOS_SEMESTRES : MatriculaPlan::TECNICA_DOS_SEMESTRES,
                    :institucion_sede_id           => institucion_sede_ip.id
            }

            #puts "Plan: #{plan.inspect}"
            #puts "data: #{((plan.nivel == PlanEstudio::PROFESIONAL) ? MatriculaPlan::PROFESIONAL_DOS_SEMESTRES : MatriculaPlan::TECNICA_DOS_SEMESTRES).inspect}"
        end

        data[:planes_vespertinos] = []
            ultimos_planes.select{ |link_plan| link_plan.modalidad == InstitucionSedePlan::PRESENCIAL and link_plan.jornada == InstitucionSedePlan::VESPERTINA }.each do |link_plan|
            plan = planes.select{ |plan| plan.id == link_plan.plan_estudio_id }.first

            # Solo las carreras para el IP, profesionale y tecnicas
			next if not plan.nivel == PlanEstudio::PROFESIONAL and not plan.nivel == PlanEstudio::TECNICO

			arancel = (a_s = aranceles.select{ |arancel| link_plan.id == arancel.institucion_sede_plan_id and arancel.contado == false }.first).nil? ? 0 : a_s.precio
            arancel_contado = (a_c = aranceles.select{ |arancel| link_plan.id == arancel.institucion_sede_plan_id and arancel.contado == true }.first).nil? ? 0 : a_c.precio                        
			matricula = (m_s = matriculas.select{ |matricula| link_plan.id == matricula.institucion_sede_plan_id }.first).nil? ? 0 : m_s.precio

            data[:planes_vespertinos] << {
                    :institucion_sede_plan_id      => link_plan.id,
                    :nombre                        => "#{plan.nombre} - rev #{plan.revision}",
                    :arancel                       => arancel,
                    :arancel_contado               => arancel_contado,
                    :matricula                     => matricula,
                    :tipo_matricula                => (plan.nivel == PlanEstudio::PROFESIONAL) ? MatriculaPlan::PROFESIONAL_DOS_SEMESTRES : MatriculaPlan::TECNICA_DOS_SEMESTRES,
                    :institucion_sede_id           => institucion_sede_ip.id
            }
        end

		data[:planes_distancia] = []
		ultimos_planes.select{ |link_plan| link_plan.modalidad == InstitucionSedePlan::DISTANCIA }.each do |link_plan|
			plan = planes.select{ |plan| plan.id == link_plan.plan_estudio_id }.first
			arancel = (a = aranceles.select{ |arancel| link_plan.id == arancel.institucion_sede_plan_id and arancel.contado == false }.first).blank? ? 0 : a.precio
			arancel_contado = aranceles.select{ |arancel| link_plan.id == arancel.institucion_sede_plan_id and arancel.contado == true }.first
			matricula = (ma = matriculas.select{ |matricula| link_plan.id == matricula.institucion_sede_plan_id }.first).blank? ? 0 : ma.precio

            data[:planes_distancia] << {
                :institucion_sede_plan_id       => link_plan.id,
                :nombre                         => "#{plan.nombre} - rev #{plan.revision}",
                :arancel                        => arancel,

                # Puede que los planes de distancia no tengan arancel pago contado
                :arancel_contado                => (not arancel_contado.nil?) ? arancel_contado.precio : nil,
                :matricula                      => matricula,
                :tipo_matricula                 => MatriculaPlan::DISTANCIA_1_A_4_NIVEL,
                :institucion_sede_id            => institucion_sede_ip.id
            }
        end
        
		data[:planes_ceia_diurno] = []
		ultimos_planes.select{ |link_plan| link_plan.modalidad == InstitucionSedePlan::PRESENCIAL and link_plan.jornada == InstitucionSedePlan::DIURNA }.each do |link_plan|
			plan = planes.select{ |plan| plan.id == link_plan.plan_estudio_id }.first
			
			# Solo aceptamos las carreras del CEIA
			next if not plan.nivel == PlanEstudio::SECUNDARIO

			arancel = (a = aranceles.select{ |arancel| link_plan.id == arancel.institucion_sede_plan_id and arancel.contado == false }.first).blank? ? 0 : a.precio
			arancel_contado = aranceles.select{ |arancel| link_plan.id == arancel.institucion_sede_plan_id and arancel.contado == true }.first
			matricula = (ma = matriculas.select{ |matricula| link_plan.id == matricula.institucion_sede_plan_id }.first).blank? ? 0 : ma.precio

			data[:planes_ceia_diurno] << {
				:institucion_sede_plan_id 	=> link_plan.id,
				:nombre 					=> "#{plan.nombre}",
				:arancel 					=> arancel,

				# Puede que los planes de distancia no tengan arancel pago contado
				:arancel_contado 			=> (not arancel_contado.nil?) ? arancel_contado.precio : nil,
				:matricula 					=> matricula,
				:tipo_matricula 			=> MatriculaPlan::CEIA_DOS_SEMESTRES,
				:institucion_sede_id 		=> institucion_sede_ceia.id

			}
		end

		data[:planes_ceia_vespertino] = []
		ultimos_planes.select{ |link_plan| link_plan.modalidad == InstitucionSedePlan::PRESENCIAL and link_plan.jornada == InstitucionSedePlan::VESPERTINA }.each do |link_plan|
			plan = planes.select{ |plan| plan.id == link_plan.plan_estudio_id }.first
			
			# Solo aceptamos las carreras del CEIA
			next if not plan.nivel == PlanEstudio::SECUNDARIO

			arancel = (a = aranceles.select{ |arancel| link_plan.id == arancel.institucion_sede_plan_id and arancel.contado == false }.first).blank? ? 0 : a.precio
			arancel_contado = aranceles.select{ |arancel| link_plan.id == arancel.institucion_sede_plan_id and arancel.contado == true }.first
			matricula = (ma = matriculas.select{ |matricula| link_plan.id == matricula.institucion_sede_plan_id }.first).blank? ? 0 : ma.precio

			data[:planes_ceia_vespertino] << {
				:institucion_sede_plan_id 	=> link_plan.id,
				:nombre 					=> "#{plan.nombre}",
				:arancel 					=> arancel,

				# Puede que los planes de distancia no tengan arancel pago contado
				:arancel_contado 			=> (not arancel_contado.nil?) ? arancel_contado.precio : nil,
				:matricula 					=> matricula,
				:tipo_matricula 			=> MatriculaPlan::CEIA_DOS_SEMESTRES,
				:institucion_sede_id 		=> institucion_sede_ceia.id

			}
		end

		data[:planes_preu_diurno] = []
		ultimos_planes.select{ |link_plan| link_plan.modalidad == InstitucionSedePlan::PRESENCIAL and link_plan.jornada == InstitucionSedePlan::DIURNA }.each do |link_plan|
			next if link_plan.blank?
			plan = planes.select{ |plan| plan.id == link_plan.plan_estudio_id }.first
			
			# Solo aceptamos las carreras del Preu
			next if plan.blank?
			next if not plan.nivel == PlanEstudio::PREUNIVERSITARIO
			arancel = (a = aranceles.select{ |arancel| link_plan.id == arancel.institucion_sede_plan_id and arancel.contado == false }.first).blank? ? 0 : a.precio
			arancel_contado = aranceles.select{ |arancel| link_plan.id == arancel.institucion_sede_plan_id and arancel.contado == true }.first
			matricula = (ma = matriculas.select{ |matricula| link_plan.id == matricula.institucion_sede_plan_id }.first).blank? ? 0 : ma.precio

			data[:planes_preu_diurno] << {
				:institucion_sede_plan_id 	=> link_plan.id,
				:nombre 					=> "#{plan.nombre}",
				:arancel 					=> arancel,

				# Puede que los planes de preu no tengan arancel pago contado
				:arancel_contado 			=> (not arancel_contado.nil?) ? arancel_contado.precio : nil,
				:matricula 					=> matricula,
				:tipo_matricula 			=> MatriculaPlan::PREU_DOS_SEMESTRES,
				:institucion_sede_id 		=> institucion_sede_preu.id

			}
		end

		data[:planes_preu_vespertino] = []
		ultimos_planes.select{ |link_plan| link_plan.modalidad == InstitucionSedePlan::PRESENCIAL and link_plan.jornada == InstitucionSedePlan::VESPERTINA }.each do |link_plan|
			next if link_plan.blank?
			plan = planes.select{ |plan| plan.id == link_plan.plan_estudio_id }.first
			
			# Solo aceptamos las carreras del PREU
			next if plan.blank?
			next if not plan.nivel == PlanEstudio::PREUNIVERSITARIO
			arancel = (a = aranceles.select{ |arancel| link_plan.id == arancel.institucion_sede_plan_id and arancel.contado == false }.first).blank? ? 0 : a.precio
			arancel_contado = aranceles.select{ |arancel| link_plan.id == arancel.institucion_sede_plan_id and arancel.contado == true }.first
			matricula = (ma = matriculas.select{ |matricula| link_plan.id == matricula.institucion_sede_plan_id }.first).blank? ? 0 : ma.precio

			data[:planes_preu_vespertino] << {
				:institucion_sede_plan_id 	=> link_plan.id,
				:nombre 					=> "#{plan.nombre}",
				:arancel 					=> arancel,

				# Puede que los planes de preu no tengan arancel pago contado
				:arancel_contado 			=> (not arancel_contado.nil?) ? arancel_contado.precio : nil,
				:matricula 					=> matricula,
				:tipo_matricula 			=> MatriculaPlan::PREU_DOS_SEMESTRES,
				:institucion_sede_id 		=> institucion_sede_preu.id

			}
		end

		data[:planes_otec_diurno] = []
		ultimos_planes.select{ |link_plan| link_plan.modalidad == InstitucionSedePlan::PRESENCIAL and link_plan.jornada == InstitucionSedePlan::DIURNA }.each do |link_plan|
			plan = planes.select{ |plan| plan.id == link_plan.plan_estudio_id }.first
			
			# Solo aceptamos las carreras del OTEC
			next if not plan.nivel == PlanEstudio::DIPLOMADO

			arancel1 = (a = aranceles.select{ |arancel| link_plan.id == arancel.institucion_sede_plan_id and arancel.contado == false and arancel.tipo == MatriculaPlan::OTEC_UN_SEMESTRE}.first).blank? ? 0 : a.precio
			arancel2 = (a = aranceles.select{ |arancel| link_plan.id == arancel.institucion_sede_plan_id and arancel.contado == false and arancel.tipo == MatriculaPlan::OTEC_UN_SEMESTRE_SENCE}.first).blank? ? 0 : a.precio
			arancel_contado1 = aranceles.select{ |arancel| link_plan.id == arancel.institucion_sede_plan_id and arancel.contado == true and arancel.tipo == MatriculaPlan::OTEC_UN_SEMESTRE}.first
			arancel_contado2 = aranceles.select{ |arancel| link_plan.id == arancel.institucion_sede_plan_id and arancel.contado == true and arancel.tipo == MatriculaPlan::OTEC_UN_SEMESTRE_SENCE}.first
			
			matricula = (ma = matriculas.select{ |matricula| link_plan.id == matricula.institucion_sede_plan_id }.first).blank? ? 0 : ma.precio

			data[:planes_otec_diurno] << {
				:institucion_sede_plan_id 	=> link_plan.id,
				:nombre 					=> "#{plan.nombre}",
				:arancel 					=> arancel1,

				# Puede que los planes de distancia no tengan arancel pago contado
				:arancel_contado 			=> (not arancel_contado1.nil?) ? arancel_contado1.precio : nil,
				:matricula 					=> matricula,
				:tipo_matricula 			=> MatriculaPlan::OTEC_UN_SEMESTRE,
				:institucion_sede_id 		=> institucion_sede_otec.id

			}

			unless arancel2 == 0
				data[:planes_otec_diurno] << {
					:institucion_sede_plan_id 	=> link_plan.id,
					:nombre 					=> "#{plan.nombre} (SENCE)",
					:arancel 					=> arancel2,

					# Puede que los planes de distancia no tengan arancel pago contado
					:arancel_contado 			=> (not arancel_contado2.nil?) ? arancel_contado2.precio : nil,
					:matricula 					=> matricula,
					:tipo_matricula 			=> MatriculaPlan::OTEC_UN_SEMESTRE_SENCE,
					:institucion_sede_id 		=> institucion_sede_otec.id

				}
			end
		end

		data[:planes_otec_vespertino] = []
		ultimos_planes.select{ |link_plan| link_plan.modalidad == InstitucionSedePlan::PRESENCIAL and link_plan.jornada == InstitucionSedePlan::VESPERTINA }.each do |link_plan|
			plan = planes.select{ |plan| plan.id == link_plan.plan_estudio_id }.first
			
			# Solo aceptamos las carreras del CEIA
			next if not plan.nivel == PlanEstudio::DIPLOMADO

			arancel1 = (a = aranceles.select{ |arancel| link_plan.id == arancel.institucion_sede_plan_id and arancel.contado == false and arancel.tipo == MatriculaPlan::OTEC_UN_SEMESTRE}.first).blank? ? 0 : a.precio
			arancel2 = (a = aranceles.select{ |arancel| link_plan.id == arancel.institucion_sede_plan_id and arancel.contado == false and arancel.tipo == MatriculaPlan::OTEC_UN_SEMESTRE_SENCE}.first).blank? ? 0 : a.precio
			arancel_contado1 = aranceles.select{ |arancel| link_plan.id == arancel.institucion_sede_plan_id and arancel.contado == true and arancel.tipo == MatriculaPlan::OTEC_UN_SEMESTRE}.first
			arancel_contado2 = aranceles.select{ |arancel| link_plan.id == arancel.institucion_sede_plan_id and arancel.contado == true and arancel.tipo == MatriculaPlan::OTEC_UN_SEMESTRE_SENCE}.first
			
			matricula = (ma = matriculas.select{ |matricula| link_plan.id == matricula.institucion_sede_plan_id }.first).blank? ? 0 : ma.precio

			data[:planes_otec_vespertino] << {
				:institucion_sede_plan_id 	=> link_plan.id,
				:nombre 					=> "#{plan.nombre}",
				:arancel 					=> arancel1,

				# Puede que los planes de distancia no tengan arancel pago contado
				:arancel_contado 			=> (not arancel_contado1.nil?) ? arancel_contado1.precio : nil,
				:matricula 					=> matricula,
				:tipo_matricula 			=> MatriculaPlan::OTEC_UN_SEMESTRE,
				:institucion_sede_id 		=> institucion_sede_otec.id

			}

			unless arancel2 == 0
				data[:planes_otec_vespertino] << {
					:institucion_sede_plan_id 	=> link_plan.id,
					:nombre 					=> "#{plan.nombre} (SENCE)",
					:arancel 					=> arancel2,

					# Puede que los planes de distancia no tengan arancel pago contado
					:arancel_contado 			=> (not arancel_contado2.nil?) ? arancel_contado2.precio : nil,
					:matricula 					=> matricula,
					:tipo_matricula 			=> MatriculaPlan::OTEC_UN_SEMESTRE_SENCE,
					:institucion_sede_id 		=> institucion_sede_otec.id

				}
			end
		end

        data
    end

    def self.planes_alumno_superior periodo_id, sede_id
        data = {}

		instituciones 	= Institucion.all
		ip 				= instituciones.select{ |i| i.tipo == Institucion::IP }.first
		ceia 			= instituciones.select{ |i| i.tipo == Institucion::CEIA }.first
		preu 			= instituciones.select{ |i| i.tipo == Institucion::PREU }.first

		instituciones_sedes 	= InstitucionSede.all :sede_id => sede_id, :institucion => instituciones
		institucion_sede_ip 	= instituciones_sedes.select{ |i| i.institucion_id == ip.id }.first
		institucion_sede_ceia 	= instituciones_sedes.select{ |i| i.institucion_id == ceia.id }.first
		institucion_sede_preu 	= instituciones_sedes.select{ |i| i.institucion_id == preu.id }.first

		ultimos_planes 		= InstitucionSedePlan.all :periodo_id => periodo_id, :institucion_sede => instituciones_sedes, :estado => InstitucionSedePlan::ABIERTA
		aranceles 			= ultimos_planes.aranceles :tipo_alumno => Alumno::SUPERIOR, :tipo => MatriculaPlan::MATRICULAS_ALUMNO_NUEVO
		matriculas 			= ultimos_planes.matriculas :fecha_inicio.lte => Date.today, :fecha_termino.gt => Date.today, :tipo_alumno => Alumno::SUPERIOR

		planes = ultimos_planes.plan_estudio

		data[:planes_diurnos] = []
		ultimos_planes.select{ |link_plan| link_plan.modalidad == InstitucionSedePlan::PRESENCIAL and link_plan.jornada == InstitucionSedePlan::DIURNA }.each do |link_plan|
			plan = planes.select{ |plan| plan.id == link_plan.plan_estudio_id }.first

			# Solo las carreras para el IP, profesionale y tecnicas
			next if not plan.nivel == PlanEstudio::PROFESIONAL and not plan.nivel == PlanEstudio::TECNICO
			
			arancel = (a_s = aranceles.select{ |arancel| link_plan.id == arancel.institucion_sede_plan_id and arancel.contado == false }.first).nil? ? 0 : a_s.precio
            arancel_contado = (a_c = aranceles.select{ |arancel| link_plan.id == arancel.institucion_sede_plan_id and arancel.contado == true }.first).nil? ? 0 : a_c.precio
			matricula = (m_s = matriculas.select{ |matricula| link_plan.id == matricula.institucion_sede_plan_id }.first).nil? ? 0 : m_s.precio
            
            data[:planes_diurnos] << {
                    :institucion_sede_plan_id      => link_plan.id,
                    :nombre                        => "#{plan.nombre} - rev #{plan.revision}",
                    :arancel                       => arancel,
                    :arancel_contado               => arancel_contado,
                    :matricula                     => matricula,
                    :tipo_matricula                => (plan.nivel == PlanEstudio::PROFESIONAL) ? MatriculaPlan::PROFESIONAL_DOS_SEMESTRES : MatriculaPlan::TECNICA_DOS_SEMESTRES,
                    :institucion_sede_id           => institucion_sede_ip.id
            }
        end

        data[:planes_vespertinos] = []
        ultimos_planes.select{ |link_plan| link_plan.modalidad == InstitucionSedePlan::PRESENCIAL and link_plan.jornada == InstitucionSedePlan::VESPERTINA }.each do |link_plan|
            plan = planes.select{ |plan| plan.id == link_plan.plan_estudio_id }.first

            # Solo las carreras para el IP, profesionale y tecnicas
			next if not plan.nivel == PlanEstudio::PROFESIONAL and not plan.nivel == PlanEstudio::TECNICO

			arancel = (a_s = aranceles.select{ |arancel| link_plan.id == arancel.institucion_sede_plan_id and arancel.contado == false }.first).nil? ? 0 : a_s.precio
            arancel_contado = (a_c = aranceles.select{ |arancel| link_plan.id == arancel.institucion_sede_plan_id and arancel.contado == true }.first).nil? ? 0 : a_c.precio                        
			matricula = (m_s = matriculas.select{ |matricula| link_plan.id == matricula.institucion_sede_plan_id }.first).nil? ? 0 : m_s.precio

            data[:planes_vespertinos] << {
                    :institucion_sede_plan_id      => link_plan.id,
                    :nombre                        => "#{plan.nombre} - rev #{plan.revision}",
                    :arancel                       => arancel,
                    :arancel_contado               => arancel_contado,
                    :matricula                     => matricula,
                    :tipo_matricula                => (plan.nivel == PlanEstudio::PROFESIONAL) ? MatriculaPlan::PROFESIONAL_DOS_SEMESTRES : MatriculaPlan::TECNICA_DOS_SEMESTRES,
                    :institucion_sede_id           => institucion_sede_ip.id
            }
        end

		data[:planes_distancia] = []
		ultimos_planes.select{ |link_plan| link_plan.modalidad == InstitucionSedePlan::DISTANCIA }.each do |link_plan|
			plan = planes.select{ |plan| plan.id == link_plan.plan_estudio_id }.first
			arancel = (a = aranceles.select{ |arancel| link_plan.id == arancel.institucion_sede_plan_id and arancel.contado == false }.first).blank? ? 0 : a.precio
			arancel_contado = aranceles.select{ |arancel| link_plan.id == arancel.institucion_sede_plan_id and arancel.contado == true }.first
			matricula = (ma = matriculas.select{ |matricula| link_plan.id == matricula.institucion_sede_plan_id }.first).blank? ? 0 : ma.precio

            data[:planes_distancia] << {
                :institucion_sede_plan_id       => link_plan.id,
                :nombre                         => "#{plan.nombre} - rev #{plan.revision}",
                :arancel                        => arancel,

                # Puede que los planes de distancia no tengan arancel pago contado
                :arancel_contado                => (not arancel_contado.nil?) ? arancel_contado.precio : nil,
                :matricula                      => matricula,
                :tipo_matricula                 => MatriculaPlan::DISTANCIA_1_A_4_NIVEL,
                :institucion_sede_id            => institucion_sede_ip.id
            }
        end
        
		data[:planes_ceia_diurno] = []
		ultimos_planes.select{ |link_plan| link_plan.modalidad == InstitucionSedePlan::PRESENCIAL and link_plan.jornada == InstitucionSedePlan::DIURNA }.each do |link_plan|
			plan = planes.select{ |plan| plan.id == link_plan.plan_estudio_id }.first
			
			# Solo aceptamos las carreras del CEIA
			next if not plan.nivel == PlanEstudio::SECUNDARIO

			arancel = (a = aranceles.select{ |arancel| link_plan.id == arancel.institucion_sede_plan_id and arancel.contado == false }.first).blank? ? 0 : a.precio
			arancel_contado = aranceles.select{ |arancel| link_plan.id == arancel.institucion_sede_plan_id and arancel.contado == true }.first
			matricula = (ma = matriculas.select{ |matricula| link_plan.id == matricula.institucion_sede_plan_id }.first).blank? ? 0 : ma.precio

			data[:planes_ceia_diurno] << {
				:institucion_sede_plan_id 	=> link_plan.id,
				:nombre 					=> "#{plan.nombre}",
				:arancel 					=> arancel,

				# Puede que los planes de distancia no tengan arancel pago contado
				:arancel_contado 			=> (not arancel_contado.nil?) ? arancel_contado.precio : nil,
				:matricula 					=> matricula,
				:tipo_matricula 			=> MatriculaPlan::CEIA_DOS_SEMESTRES,
				:institucion_sede_id 		=> institucion_sede_ceia.id

			}
		end

		data[:planes_ceia_vespertino] = []
		ultimos_planes.select{ |link_plan| link_plan.modalidad == InstitucionSedePlan::PRESENCIAL and link_plan.jornada == InstitucionSedePlan::VESPERTINA }.each do |link_plan|
			plan = planes.select{ |plan| plan.id == link_plan.plan_estudio_id }.first
			
			# Solo aceptamos las carreras del CEIA
			next if not plan.nivel == PlanEstudio::SECUNDARIO

			arancel = (a = aranceles.select{ |arancel| link_plan.id == arancel.institucion_sede_plan_id and arancel.contado == false }.first).blank? ? 0 : a.precio
			arancel_contado = aranceles.select{ |arancel| link_plan.id == arancel.institucion_sede_plan_id and arancel.contado == true }.first
			matricula = (ma = matriculas.select{ |matricula| link_plan.id == matricula.institucion_sede_plan_id }.first).blank? ? 0 : ma.precio

			data[:planes_ceia_vespertino] << {
				:institucion_sede_plan_id 	=> link_plan.id,
				:nombre 					=> "#{plan.nombre}",
				:arancel 					=> arancel,

				# Puede que los planes de distancia no tengan arancel pago contado
				:arancel_contado 			=> (not arancel_contado.nil?) ? arancel_contado.precio : nil,
				:matricula 					=> matricula,
				:tipo_matricula 			=> MatriculaPlan::CEIA_DOS_SEMESTRES,
				:institucion_sede_id 		=> institucion_sede_ceia.id

			}
		end

		data[:planes_preu_diurno] = []
		ultimos_planes.select{ |link_plan| link_plan.modalidad == InstitucionSedePlan::PRESENCIAL and link_plan.jornada == InstitucionSedePlan::DIURNA }.each do |link_plan|
			next if link_plan.blank?
			plan = planes.select{ |plan| plan.id == link_plan.plan_estudio_id }.first
			
			# Solo aceptamos las carreras del Preu
			next if plan.blank?
			next if not plan.nivel == PlanEstudio::PREUNIVERSITARIO
			arancel = (a = aranceles.select{ |arancel| link_plan.id == arancel.institucion_sede_plan_id and arancel.contado == false }.first).blank? ? 0 : a.precio
			arancel_contado = aranceles.select{ |arancel| link_plan.id == arancel.institucion_sede_plan_id and arancel.contado == true }.first
			matricula = (ma = matriculas.select{ |matricula| link_plan.id == matricula.institucion_sede_plan_id }.first).blank? ? 0 : ma.precio

			data[:planes_preu_diurno] << {
				:institucion_sede_plan_id 	=> link_plan.id,
				:nombre 					=> "#{plan.nombre}",
				:arancel 					=> arancel,

				# Puede que los planes de preu no tengan arancel pago contado
				:arancel_contado 			=> (not arancel_contado.nil?) ? arancel_contado.precio : nil,
				:matricula 					=> matricula,
				:tipo_matricula 			=> MatriculaPlan::PREU_DOS_SEMESTRES,
				:institucion_sede_id 		=> institucion_sede_preu.id

			}
		end

		data[:planes_preu_vespertino] = []
		ultimos_planes.select{ |link_plan| link_plan.modalidad == InstitucionSedePlan::PRESENCIAL and link_plan.jornada == InstitucionSedePlan::VESPERTINA }.each do |link_plan|
			next if link_plan.blank?
			plan = planes.select{ |plan| plan.id == link_plan.plan_estudio_id }.first
			
			# Solo aceptamos las carreras del PREU
			next if plan.blank?
			next if not plan.nivel == PlanEstudio::PREUNIVERSITARIO
			arancel = (a = aranceles.select{ |arancel| link_plan.id == arancel.institucion_sede_plan_id and arancel.contado == false }.first).blank? ? 0 : a.precio
			arancel_contado = aranceles.select{ |arancel| link_plan.id == arancel.institucion_sede_plan_id and arancel.contado == true }.first
			matricula = (ma = matriculas.select{ |matricula| link_plan.id == matricula.institucion_sede_plan_id }.first).blank? ? 0 : ma.precio

			data[:planes_preu_vespertino] << {
				:institucion_sede_plan_id 	=> link_plan.id,
				:nombre 					=> "#{plan.nombre}",
				:arancel 					=> arancel,

				# Puede que los planes de preu no tengan arancel pago contado
				:arancel_contado 			=> (not arancel_contado.nil?) ? arancel_contado.precio : nil,
				:matricula 					=> matricula,
				:tipo_matricula 			=> MatriculaPlan::PREU_DOS_SEMESTRES,
				:institucion_sede_id 		=> institucion_sede_preu.id

			}
		end

        data
    end
end