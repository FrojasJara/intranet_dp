require "time"
class Rectoria::InformesController < ApplicationController
    protect_from_forgery :except => [:resumen_global_matriculas]

    def resumen_global_matriculas

        if params.has_key?(:filtro)
            periodo_id = params[:filtro][:periodo_id].to_i
            periodo_ant = Periodo.get Periodo.periodo_anterior(periodo_id)

            periodo_consulta = []
            periodo_consulta << periodo_id
            periodo_consulta << periodo_ant.id

            @periodo = Periodo.first id: periodo_id

            @p_f_i = params[:filtro][:fecha_inicio]
            @p_f_t = params[:filtro][:fecha_termino]

            unless @p_f_i.blank?
                f_i = Time.parse(@p_f_i+' 00:00:00')
            end
            unless @p_f_t.blank?
                f_t = Time.parse(@p_f_t+' 23:59:59')
            end
            
            @mapeo = [] 

            instituciones = Institucion.all(:fields => [:id, :nombre])
            plan_estudios = PlanEstudio.all(:fields => [:id, :nombre, :revision])
            
            if f_i.blank? and f_t.blank? 
                matriculas_plan = MatriculaPlan.all(:fields => [:id, :periodo_id, :alumno_plan_estudio_id], 
                                                :estado.not => [MatriculaPlan::ANULADA],
                                                periodo_id: periodo_id) +
                                  MatriculaPlan.all(:fields => [:id, :periodo_id, :alumno_plan_estudio_id],
                                                :estado.not => [MatriculaPlan::ANULADA],
                                                planes_pago: {
                                                    :tipo => MatriculaPlan::MATRICULAS_ANUALES_VALORES
                                                },
                                                periodo_id: periodo_ant.id) +
                                  MatriculaPlan.all(:fields => [:id, :periodo_id, :alumno_plan_estudio_id],
                                                :estado.not => [MatriculaPlan::ANULADA],
                                                :periodo_id => periodo_ant.id, 
                                                planes_pago: {
                                                    :periodo_id => periodo_id, 
                                                    :tipo => MatriculaPlan::MATRICULAS_SEMESTRALES
                                                })
            elsif f_i.blank?
                matriculas_plan = MatriculaPlan.all(:fields => [:id, :periodo_id, :alumno_plan_estudio_id], 
                                                :created_at.lte => f_t,
                                                :estado.not => [MatriculaPlan::ANULADA],
                                                periodo_id: periodo_id) +
                                  MatriculaPlan.all(:fields => [:id, :periodo_id, :alumno_plan_estudio_id], 
                                                :created_at.lte => f_t,
                                                :estado.not => [MatriculaPlan::ANULADA],
                                                planes_pago: {
                                                    :tipo => MatriculaPlan::MATRICULAS_ANUALES_VALORES
                                                },
                                                periodo_id: periodo_ant.id) +
                                  MatriculaPlan.all(:fields => [:id, :periodo_id, :alumno_plan_estudio_id],
                                                :created_at.lte => f_t,
                                                :estado.not => [MatriculaPlan::ANULADA],
                                                :periodo_id => periodo_ant.id, 
                                                planes_pago: {
                                                    :periodo_id => periodo_id, 
                                                    :tipo => MatriculaPlan::MATRICULAS_SEMESTRALES
                                                })
            elsif f_t.blank?
                matriculas_plan = MatriculaPlan.all(:fields => [:id, :periodo_id, :alumno_plan_estudio_id], 
                                                :created_at.gte => f_i,
                                                :estado.not => [MatriculaPlan::ANULADA],
                                                periodo_id: periodo_id) +
                                  MatriculaPlan.all(:fields => [:id, :periodo_id, :alumno_plan_estudio_id], 
                                                :created_at.gte => f_i,
                                                :estado.not => [MatriculaPlan::ANULADA],
                                                planes_pago: {
                                                    :tipo => MatriculaPlan::MATRICULAS_ANUALES_VALORES
                                                },
                                                periodo_id: periodo_ant.id) +
                                  MatriculaPlan.all(:fields => [:id, :periodo_id, :alumno_plan_estudio_id],
                                                :created_at.gte => f_i,
                                                :estado.not => [MatriculaPlan::ANULADA],
                                                :periodo_id => periodo_ant.id, 
                                                planes_pago: {
                                                    :periodo_id => periodo_id, 
                                                    :tipo => MatriculaPlan::MATRICULAS_SEMESTRALES
                                                })
            else
                matriculas_plan = MatriculaPlan.all(:fields => [:id, :periodo_id, :alumno_plan_estudio_id], 
                                                :created_at => f_i..f_t,
                                                :estado.not => [MatriculaPlan::ANULADA],
                                                periodo_id: periodo_id) +
                                  MatriculaPlan.all(:fields => [:id, :periodo_id, :alumno_plan_estudio_id], 
                                                :created_at => f_i..f_t,
                                                :estado.not => [MatriculaPlan::ANULADA],
                                                planes_pago: {
                                                    :tipo => MatriculaPlan::MATRICULAS_ANUALES_VALORES
                                                },
                                                periodo_id: periodo_ant.id) +
                                  MatriculaPlan.all(:fields => [:id, :periodo_id, :alumno_plan_estudio_id],
                                                :created_at => f_i..f_t,
                                                :estado.not => [MatriculaPlan::ANULADA],
                                                :periodo_id => periodo_ant.id, 
                                                planes_pago: {
                                                    :periodo_id => periodo_id, 
                                                    :tipo => MatriculaPlan::MATRICULAS_SEMESTRALES
                                                })
            end

            institucion_sede_plan = InstitucionSedePlan.all(:fields => [:id, :institucion_sede_id], 
                                                            alumno_plan_estudio: {
                                                                matricula_plan: {
                                                                    id: matriculas_plan.map(&:id)
                                                                }
                                                            })
            
            institucion_sedes = InstitucionSede.all fields: [:id, :sede_id],
                                                    id: institucion_sede_plan.map(&:institucion_sede_id)

            sedes = Sede.all(:fields => [:nombre, :id],
                            id: Sede::SEDES_VIGENTES
                        )

            count1 = instituciones.size
            count2 = plan_estudios.size
            count3 = institucion_sedes.size
            count4 = institucion_sede_plan.size
            count5 = sedes.size
            count7 = matriculas_plan.size

            sedes.each do |s|
                @mapeo << {:sede_id => s.id, :nombre => s.nombre, :instituciones => []}
             end

            @mapeo.each do |m|
                institucion_sedes.each do |is|
                    inst = instituciones.find{|item| item.id == is.institucion_id} 
                    m[:instituciones] << {:institucion_id =>  is.institucion_id, :institucion_sede_id =>  is.id, :nombre => inst.nombre , :carreras_presenciales => [], :carreras_distancia => [] } if m[:sede_id] == is.sede_id

                end
            end

            @mapeo.each do |m|
                m[:instituciones].each do |ins|
                    institucion_sede_plan.each do |isp|
                        p_est =  plan_estudios.find{|item| item.id == isp.plan_estudio_id}
                        tmp = {:institucion_sede_plan_id => isp.id, :nombre => p_est.nombre, :revision => p_est.revision, :total_nuevos => 0, :total_antiguos => 0}
                        
                        if (isp.institucion_sede_id == ins[:institucion_sede_id]  && isp.modalidad == InstitucionSedePlan::PRESENCIAL)
                            ins[:carreras_presenciales] << tmp
                        elsif (isp.institucion_sede_id == ins[:institucion_sede_id]  && isp.modalidad != InstitucionSedePlan::PRESENCIAL)
                            ins[:carreras_distancia] << tmp
                        end
                    end
                end
            end

            @mapeo.each do |m|
                m[:instituciones].each do |ins|
                    ins[:carreras_presenciales] = ins[:carreras_presenciales].group_by{ |ic| ic[:nombre] }
                    ins[:carreras_distancia] = ins[:carreras_distancia].group_by{ |ic| ic[:nombre] }
                    
                    ins[:carreras_presenciales].each do |ca|
                        ca.last.each do |ca_individual|
                            ca_individual[:total_nuevos], ca_individual[:total_antiguos] =  obtener_totales_alumnos(matriculas_plan, ca_individual[:institucion_sede_plan_id],@periodo)
                        end
                    end

                    ins[:carreras_distancia].each do |ca|
                        ca.last.each do |ca_individual|
                            ca_individual[:total_nuevos], ca_individual[:total_antiguos] =  obtener_totales_alumnos(matriculas_plan, ca_individual[:institucion_sede_plan_id],@periodo)
                        end
                    end
                end
            end

        end
    end

    private

    # => Retorna el total de alumnos de una carrera
    def obtener_totales_alumnos(matriculas_plan, institucion_sede_plan_id,periodo)
        nuevos = 0 ; antiguos = 0

        matriculas_plan.each do |item|
            if  item.alumno_plan_estudio.institucion_sede_plan_id == institucion_sede_plan_id
                if item.alumno_plan_estudio.alumno.anio_ingreso.eql?(periodo.anio) && item.alumno_plan_estudio.institucion_sede_plan.periodo_id.eql?(periodo.id)
                    nuevos += 1
                else
                    antiguos += 1
                end
            end          
        end

        return nuevos, antiguos
    end

end