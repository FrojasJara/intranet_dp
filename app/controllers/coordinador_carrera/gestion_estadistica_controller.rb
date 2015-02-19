# encoding: utf-8
class CoordinadorCarrera::GestionEstadisticaController < ApplicationController
		before_filter :iniciar

    def estadistica_nota_seccion
			seccion_id = params[:seccion_id].to_i
			@seccion = Seccion.find_by_id(seccion_id)
			@asignatura = @seccion.asignatura_base
			@jornada = @seccion.jornada

		@planificaciones = PlanificacionCalificacion.all(seccion_id: @seccion.id)
    end

    def estadistica_notas_finales
    	seccion_id = params[:seccion_id].to_i
		@seccion = Seccion.get(seccion_id)
		@asignatura = @seccion.asignatura_base
		@jornada = @seccion.jornada
    end

    def asistencia_parcial_seccion
    	secciones_inscritas = []
        @contenedor         = []      
        seccion_id          = params[:seccion_id].to_i
        raise Excepciones::DatosNoExistentesError, "Error al consultar vuelva a intentarlo" if seccion_id.blank?
        seccion             = Seccion.find_by_id(seccion_id)
        seccion_dictada     = SeccionDictada.find_by_seccion_id(seccion.id)
        asignatura          = seccion_dictada.asignatura
        secciones_inscritas =   AlumnoInscritoSeccion.all(
                                            :fields => [
                                                :id, 
                                                :seccion_dictada_id, 
                                                :alumno_plan_estudio_id,
                                                :estado
                                            ],
                                            :seccion_dictada => 
                                                    {
                                                        :seccion_id => seccion.id
                                                    }
                                )
        secciones_inscritas.each do |i|
            item = {
                :asistencia     => i.porcentaje_horas_asistidas,
                :inasistencia   => i.porcentaje_horas_ausentadas,
                :alumno         => i.alumno_plan_estudio.alumno.datos_personales.nombre,
                :rut_alumno     => i.alumno_plan_estudio.alumno.datos_personales.rut

            }
            @contenedor << item
        end
        @asignatura = {
            :nombre             => asignatura.nombre,
            :carrera            => asignatura.plan_estudio.nombre,
            :codigo             => asignatura.codigo,
            :semestre           => asignatura.semestre,
            :cantidad_alumnos   => secciones_inscritas.size,
            :jornada            => seccion.jornada
        }
    	rescue Excepciones::DatosNoExistentesError => e 
			flash[:error] = e.message
			redirect_to coordinador_carrera_secciones_path
		rescue Exception => e 
			flash[:error] = "Error desconocido #{e}"
			redirect_to coordinador_carrera_secciones_path

    end

    def estadistica_por_nivel

        @sedes          = current_role_can?(:direccion_escuela) ? Sede.all(id: Sede::SEDES_VIGENTES) : Sede.all(:id => current_user[:sede_id])
        @jornadas       = Seccion::JORNADAS_PARA_FILTRO
        @periodos       = Periodo.all(:order => [:anio.desc, :semestre.desc])

        if params.has_key?("filtro")
            sede    = params[:filtro][:sede_id].to_i
            carrera = params[:filtro][:plan_estudio_id].to_i
            jornada = params[:filtro][:jornada].to_i
            periodo = params[:filtro][:periodo_id].to_i
            nivel   = params[:filtro][:nivel].to_i

            periodo_g   = Periodo.first id: periodo
            carrera_g   = PlanEstudio.first id: carrera
            sede_g      = Sede.first id: sede
            secciones = Seccion.all(
                            :fields => [:id],
                            :institucion_sede => {:sede => {:id => sede} },
                            :links_secciones_dictadas => {
                                :asignatura => {
                                    :semestre => nivel, 
                                    :plan_estudio => {
                                        :id => carrera
                                    }
                                }
                            },
                            :periodo_id => periodo,
                            :jornada => jornada
                        ).map(&:id)
            puts secciones.inspect.red 
            @data = []
            tipo_nota, nota_tipo = "final", :nota_final
        
            # AlumnoInscritoSeccion
            inscripciones = AlumnoInscritoSeccion.all( 
                                :fields => [:id, nota_tipo,:estado],
                                nota_tipo.not => CalificacionParcial::NO_CUMPLE_REQUISITOS,
                                :seccion_dictada => {
                                    :seccion_id => secciones
                                    }
                            )
            inscripciones_ncr = AlumnoInscritoSeccion.all( 
                                    :fields => [:id, nota_tipo,:estado],
                                    nota_tipo => CalificacionParcial::NO_CUMPLE_REQUISITOS,
                                    :seccion_dictada => {
                                        :seccion_id => secciones
                                        }
                                )
            if !inscripciones.blank?
                # AlumnoInscritoSeccion
                inscripciones_seccion = inscripciones + inscripciones_ncr
                alumnos_aprobados = inscripciones_seccion.select{ |i| [AlumnoInscritoSeccion::APROBADA,AlumnoInscritoSeccion::CONVALIDADA,AlumnoInscritoSeccion::HOMOLOGADA].include? i.estado }
                alumnos_reprobados = inscripciones_seccion.select{ |i| [AlumnoInscritoSeccion::REPROBADA, AlumnoInscritoSeccion::REPROBADA_POR_INASISTENCIA, AlumnoInscritoSeccion::REPROBADA_NCR].include? i.estado }
                
                aprobados = alumnos_aprobados.count
                reprobados = alumnos_reprobados.count
                alumnos_ncr = inscripciones_ncr.count

                # la maxima y la minima
                maxima = inscripciones.max(nota_tipo)
                minima = inscripciones.min(nota_tipo)
                #calculamos promedio y la mediana
                m_pos = inscripciones.size / 2
                mediana = inscripciones.size % 2 == 1 ? inscripciones[m_pos].nota_final : inscripciones[m_pos-1].nota_final
                promedio = inscripciones.collect(&nota_tipo).sum.to_f/inscripciones.length if inscripciones.length > 0

                #calculamos la moda / 
                f={}    
                fmax=0 
                m=nil
                f1 = 0
                f2 = 0
                f3 = 0
                f4 = 0
                f6 = 0
                f5 = 0

                inscripciones.each do |v|
                    f[v.nota_final] ||= 0
                    f[v.nota_final] += 1
                    fmax,m = f[v.nota_final], v.nota_final if f[v.nota_final] > fmax
                    
                    f1 = f1+1 if v.nota_final <= 2
                    f2 = f2+1 if v.nota_final <= 3 && v.nota_final > 2
                    f3 = f3+1 if v.nota_final <= 4 && v.nota_final > 3
                    f4 = f4+1 if v.nota_final <= 5 && v.nota_final > 4
                    f5 = f5+1 if v.nota_final <= 6 && v.nota_final > 5
                    f6 = f6+1 if v.nota_final <= 7 && v.nota_final > 6

                end
                @data << {
                    :periodo    => periodo_g,   
                    :carrera    => carrera_g,   
                    :sede       => sede_g,     
                    :jornada    => jornada,   
                    :nivel      => nivel,
                    :maxima     => maxima, 
                    :minima     => minima, 
                    :mediana    => mediana,
                    :promedio   => promedio,
                    :moda       => m,
                    :f1         => f1,
                    :f2         => f2,
                    :f3         => f3,
                    :f4         => f4,
                    :f5         => f5,
                    :f6         => f6,
                    :tipo       => tipo_nota,
                    :alumnos_ncr=> alumnos_ncr,
                    :aprobados  => aprobados,
                    :reprobados => reprobados
                }
            elsif 
                @data << {
                    :periodo    => periodo_g,   
                    :carrera    => carrera_g,   
                    :sede       => sede_g,     
                    :jornada    => jornada, 
                    :nivel      => nivel,
                    :maxima     => 0, 
                    :minima     => 0, 
                    :mediana    => 0,
                    :promedio   => 0,
                    :moda       => 0,
                    :f1         => 0,
                    :f2         => 0,
                    :f3         => 0,
                    :f4         => 0,
                    :f5         => 0,
                    :f6         => 0,
                    :tipo       => 0,
                    :alumnos_ncr=> 0,
                    :aprobados  => 0,
                    :reprobados => 0
                }
            end
        end
        return @data
    rescue Exception => e 
        puts e.inspect.red
        flash[:error] = "Error desconocido "
        redirect_to coordinador_carrera_estadistica_por_nivel_path
    end #fin funcion

end #fin controlador
