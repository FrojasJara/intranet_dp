# encoding: utf-8
class Vicerrectoria::TrasladosController < ApplicationController

    # helper_method :current_url
    protect_from_forgery :except => [:update_estado_alumno_plan_estudio,:update_informacion_matriculados,:update_informacion_matriculados_sede_antigua]

    def traslados_sin_matricula
        @rut = params[:busqueda]
        @usuario = Usuario.first rut: params[:busqueda]

        if not @rut.nil?
            @estados = Alumno::ESTADOS_ACADEMICOS

            @alumno_plan_estudios = AlumnoPlanEstudio.all alumno: {
                                        datos_personales: {
                                            rut: @rut
                                        }
                                    }

            @items = []

            @alumno_plan_estudios.each do |aps|

                @items << {
                    alumno_plan_estudio:   aps,
                    alumno:                aps.alumno,
                    usuario:               aps.alumno.datos_personales,
                    institucion_sede_plan: aps.institucion_sede_plan,
                    plan_estudio:          aps.institucion_sede_plan.plan_estudio
                }

            end

            raise Excepciones::DatosNoExistentesError, "No existe ninguna matrícula registrada a un alumno con rut #{@rut}" if @alumno_plan_estudios.empty?
        end

    rescue Excepciones::DatosNoExistentesError => e
        flash.now[:error] = e.message
    end

    def update_estado_alumno_plan_estudio
        ids     = params[:id]
        estados = params[:estado]

        ids.each_with_index do |id,index|
            ape = AlumnoPlanEstudio.first id: id
            ape.update estado: estados[index]
        end

        flash[:notice] = "Estado actualizado exitósamente, el alumno ya puede ser matriculado en otra sede."
        redirect_to traslados_sin_matricula_path(busqueda: params[:rut])
        rescue Exception => e
        flash[:error] = "Error al actualizar los datos, comuniquese con el departamento de sistemas."
        redirect_to traslados_sin_matricula_path(busqueda: params[:rut])
    end

    def traslados_matriculados
        @rut = params[:busqueda]
        @usuario = Usuario.first rut: params[:busqueda]

        if not @rut.nil?
            @estados = Alumno::ESTADOS_ACADEMICOS

            @alumno_plan_estudios = AlumnoPlanEstudio.all alumno: {
                                        datos_personales: {
                                            rut: @rut
                                        }
                                    }

            @items = []

            @alumno_plan_estudios.each do |aps|

                @items << {
                    alumno_plan_estudio:   aps,
                    alumno:                aps.alumno,
                    usuario:               aps.alumno.datos_personales,
                    institucion_sede_plan: aps.institucion_sede_plan,
                    plan_estudio:          aps.institucion_sede_plan.plan_estudio
                }

            end

            raise Excepciones::DatosNoExistentesError, "No existe ningun plan de estudio asociado al alumno con rut #{@rut}" if @alumno_plan_estudios.empty?
        end

    rescue Excepciones::DatosNoExistentesError => e
        flash.now[:error] = e.message
    rescue Exception => e
        puts e.message
        puts e.backtrace
        flash[:error] = "Se ha producido un error inesperado, comuniquese con sistemas."
    end

    def traslados_matriculados_sede_antigua
        @rut = params[:busqueda]
        @usuario = Usuario.first rut: params[:busqueda]

        if not @rut.nil?
            @estados = Alumno::ESTADOS_ACADEMICOS
            @sedes = Sede.all id: Sede::SEDES_VIGENTES

            @alumno_plan_estudios = AlumnoPlanEstudio.all alumno: {
                                        datos_personales: {
                                            rut: @rut
                                        }
                                    }

            @items = []

            @alumno_plan_estudios.each do |aps|

                @items << {
                    alumno_plan_estudio:   aps,
                    alumno:                aps.alumno,
                    usuario:               aps.alumno.datos_personales,
                    institucion_sede_plan: aps.institucion_sede_plan,
                    plan_estudio:          aps.institucion_sede_plan.plan_estudio
                }

            end

            raise Excepciones::DatosNoExistentesError, "No existe ningun plan de estudio asociado al alumno con rut #{@rut}" if @alumno_plan_estudios.empty?
        end

    rescue Excepciones::DatosNoExistentesError => e
        flash.now[:error] = e.message
    rescue Exception => e
        puts e.message
        puts e.backtrace
        flash[:error] = "Se ha producido un error inesperado, comuniquese con sistemas."
    end

    def update_informacion_matriculados
        ape_ini = AlumnoPlanEstudio.first id: params[:ape_ini_id].to_i
        ape_fin = AlumnoPlanEstudio.first id: params[:ape_fin_id].to_i

        if ape_ini.institucion_sede_plan.institucion_sede.sede_id.to_i == ape_fin.institucion_sede_plan.institucion_sede.sede_id.to_i
            raise Excepciones::DatosInconsistentesError, "Ambos planes de estudio pertenecen a la misma sede."
        elsif ape_ini.institucion_sede_plan.plan_estudio_id.to_i != ape_fin.institucion_sede_plan.plan_estudio_id.to_i
            raise Excepciones::DatosInconsistentesError, "Ambos planes de estudio no pertenecen a la misma carrera."
        else
            traslado_informacion_acedemica ape_ini.id,ape_fin.id
            flash[:notice] = "El traslado de la información académica se realizó exitosamente."
            redirect_to traslados_matriculados_path(busqueda: params[:rut])
        end

    rescue Excepciones::DatosInconsistentesError => e
        flash[:error] = e.message
        redirect_to traslados_matriculados_path(busqueda: params[:rut])
    rescue Exception => e
        puts e.message
        puts e.backtrace
        flash[:error] = "No se ha podido trasladar la información, comuniquese con sistemas."
        redirect_to traslados_matriculados_path(busqueda: params[:rut])
    end

    def update_informacion_matriculados_sede_antigua
        ape_ini = AlumnoPlanEstudio.first id: params[:ape_ini_id].to_i

        if ape_ini.institucion_sede_plan.institucion_sede.sede_id.to_i == params[:sede_id].to_i
            raise Excepciones::DatosInconsistentesError, "El plan de estudio pertenece a la misma sede a la cual se quiere trasladar."
        elsif(ape_ini.estado != Alumno::TRASLADADO)
            raise Excepciones::DatosInconsistentesError, "El plan de estudio no ha sido habilitado para traslado."
        else
            instit_sede_plan = InstitucionSedePlan.first institucion_sede: {
                                                            institucion_id: ape_ini.institucion_sede_plan.institucion_sede.institucion_id.to_i,
                                                            sede_id: params[:sede_id].to_i
                                                         },
                                                         estado: InstitucionSedePlan::ABIERTA,
                                                         jornada: ape_ini.institucion_sede_plan.jornada,
                                                         modalidad: ape_ini.institucion_sede_plan.modalidad,
                                                         plan_estudio_id: ape_ini.institucion_sede_plan.plan_estudio_id,
                                                         periodo_id: ape_ini.institucion_sede_plan.periodo_id
            
            if instit_sede_plan.blank?
                raise Excepciones::DatosInconsistentesError, "No existe un plan de estudio con las mismas caracteristicas que el plan de origen en la sede a la cual se quiere trasladar el alumno."
            else
                AlumnoPlanEstudio.transaction do
                    ape_fin = AlumnoPlanEstudio.new anio_ingreso: ape_ini.anio_ingreso,
                                                    estado: Alumno::SIN_INSCRIPCION,
                                                    semestre: ape_ini.tipo_ingreso,
                                                    es_trabajador: ape_ini.es_trabajador,
                                                    aprobadas: ape_ini.aprobadas,
                                                    reprobadas: ape_ini.reprobadas,
                                                    abandonadas: ape_ini.abandonadas,
                                                    convalidadas: ape_ini.convalidadas,
                                                    homologadas: ape_ini.convalidadas,
                                                    alumno_id: ape_ini.alumno_id,
                                                    periodo_id: ape_ini.periodo_id,
                                                    institucion_sede_plan_id: instit_sede_plan.id
                    
                    ape_fin.save

                    traslado_informacion_acedemica ape_ini.id,ape_fin.id
                    traslado_informacion_administrativa ape_ini.id,ape_fin.id
                    flash[:notice] = "El traslado de la información académica se realizó exitosamente."
                    redirect_to traslados_matriculados_sede_antigua_path(busqueda: params[:rut])
                end
            end
        end

    rescue Excepciones::DatosInconsistentesError => e
        flash[:error] = e.message
        redirect_to traslados_matriculados_sede_antigua_path(busqueda: params[:rut])
    rescue Exception => e
        puts e.message
        puts e.backtrace
        flash[:error] = "No se ha podido trasladar la información, comuniquese con sistemas."
        redirect_to traslados_matriculados_sede_antigua_path(busqueda: params[:rut])
    end

    private

    def traslado_informacion_administrativa ape_ini_id,ape_fin_id
        ape_ini = AlumnoPlanEstudio.first id: ape_ini_id.to_i

        matricula = ape_ini.matricula_plan.last
        planes = matricula.planes_pago

        matricula.alumno_plan_estudio_id = ape_fin_id.to_i

        planes.each do |plan|
            pagare = Pagare.last plan_pago_id: plan.id,
                                 :estado.not => Pagare::ANULADO

            pagare.alumno_plan_estudio_id = ape_fin_id.to_i
            pagare.save

        end

        matricula.save
    end

    def traslado_informacion_acedemica ape_ini_id,ape_fin_id
        
        alumno_inscrito_secciones = AlumnoInscritoSeccion.all alumno_plan_estudio_id: ape_ini_id.to_i

        AlumnoInscritoSeccion.transaction do
            alumno_inscrito_secciones.each do |seccion_alumno|
                seccion_alumno.alumno_plan_estudio_id = ape_fin_id.to_i
                seccion_alumno.save
            end
        end
    end
end 