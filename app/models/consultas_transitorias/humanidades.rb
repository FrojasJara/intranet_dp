# encoding: utf-8
require 'csv'

class ConsultasTransitorias::Humanidades

        URL = "/home/jony/Escritorio/"

        def self.parvularia_social_matriculados_inscritos_2013_1
                DataMapper::Logger.new(STDOUT, :debug)
                p_2013_1 = Periodo.first :anio => 2013, :semestre => 1
                instituciones = Institucion.all
                sedes = Sede.all
                carreras_humanidades = []
                #puts PlanEstudio::MALLAS_HASH_PRESENCIALES[PlanEstudio::EDUCACION_PARVULARIA].inspect
                carreras_humanidades.concat(PlanEstudio::MALLAS_HASH_PRESENCIALES[PlanEstudio::EDUCACION_PARVULARIA]).concat(PlanEstudio::MALLAS_HASH_PRESENCIALES[PlanEstudio::SERVICIO_SOCIAL])

                puts carreras_humanidades.inspect
                
                inscripciones_planes = AlumnoPlanEstudio.all(
                        :matricula_plan => {
                                :planes_pago => {
                                        :periodo => p_2013_1
                                },
                                :periodo => { :anio => [2012, 2013] }
                        },
                        :institucion_sede_plan => {
                                :institucion_sede_id    => 1, # solo IP Concepcion
                                :plan_estudio_id        => carreras_humanidades,
                                :modalidad              => InstitucionSedePlan::PRESENCIAL
                        },
                        :estado                         => [Alumno::SIN_INSCRIPCION, Alumno::REGULAR]
                )

                alumnos = inscripciones_planes.alumno
                usuarios_alumno = alumnos.datos_personales
                instituciones_sedes_planes = inscripciones_planes.institucion_sede_plan
                instituciones_sedes = instituciones_sedes_planes.institucion_sede
                planes_estudio = instituciones_sedes_planes.plan_estudio

                data = []
                inscripciones_planes.each do |item|
                        alumno = alumnos.select{ |a| a.id == item.alumno_id }.first
                        usuario_alumno = usuarios_alumno.select{ |a| a.id == alumno.usuario_id }.first
                        institucion_sede_plan = instituciones_sedes_planes.select{ |a| a.id == item.institucion_sede_plan_id }.first
                        plan_estudio = planes_estudio.select{ |a| a.id == institucion_sede_plan.plan_estudio_id }.first
                        institucion_sede = instituciones_sedes.select{ |a| a.id == institucion_sede_plan.institucion_sede_id }.first
                        institucion = instituciones.select{ |a| a.id == institucion_sede.institucion_id }.first
                        sede = sedes.select{ |a| a.id == institucion_sede.sede_id }.first


                        data << {
                                :usuario                                => usuario_alumno,
                                :alumno                                 => alumno,
                                :alumno_plan_estudio    => item,
                                :institucion_sede_plan  => institucion_sede_plan,
                                :plan_estudio                   => plan_estudio,
                                :institucion                    => institucion,
                                :sede                                   => sede
                        }
                end

                index = 1
                CSV.open("#{URL}alumnos_parvularia_social_2013_matriculas_e_inscritos.csv", "w") do |csv|
                        begin
                                data.each do |i|
                                        row     = []
                                        row     = [
                                                index.to_s,
                                                i[:usuario].rut,
                                                i[:usuario].nombre,
                                                i[:usuario].domicilio,
                                                i[:usuario].villa_poblacion,
                                                i[:usuario].telefono_fijo_completo,
                                                i[:usuario].email,
                                                i[:usuario].comuna.nombre,
                                                i[:usuario].region.nombre,
                                                i[:plan_estudio].nombre,
                                                i[:alumno_plan_estudio].anio_ingreso,
                                                ( i[:alumno_plan_estudio].estado == Alumno::REGULAR ) ? "REGULAR" : "SIN INSCRIPCION",
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
        end
end