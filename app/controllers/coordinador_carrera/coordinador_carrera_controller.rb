# encoding: utf-8
class CoordinadorCarrera::CoordinadorCarreraController < ApplicationController
    before_filter :iniciar

    def inscripcion_asignaturas
        unless params[:busqueda].blank?
            usuario = Usuario.first rut: params[:busqueda]
            raise Excepciones::DatosNoExistentesError, "El Rut ingresado no existe" if usuario.blank?
            raise Excepciones::DatosNoExistentesError, "El Rut ingresado no tiene un alumno asociado" if usuario.alumno.blank?

            redirect_to alumno_generar_inscripcion_asignaturas_path(usuario.id)
        end

        rescue Excepciones::DatosNoExistentesError => e
            flash[:error] = e.message
    end

    def guarda_nivel_alumno #se llama en la inscripción de asignaturas
        msg = {status: 'error', message: ''}
        if current_role_can? :direccion_escuela
            pp = PlanPago.get params[:plan_pago_id]
            raise Excepciones::OperacionNoPermitidaError, 'No existe el plan de pago ingresado' if pp.blank?
            pp.update :nivel => params[:nivel]
            msg['status'] = 'ok'
        else
            raise Excepciones::OperacionNoPermitidaError, 'Usted no tiene los permisos para realizar esta operación'
        end

        render json: msg, layout: nil
        rescue DataMapper::SaveFailureError => e
            render json: {status: 'error', message: 'No se pudo modificar el nivel'}, layout: nil
        rescue Excepciones::OperacionNoPermitidaError => e
            render json: {status: 'error', message: e.message}, layout: nil
    end

	def modificar_planificacion
		
	end

    def secciones
        @instituciones_sedes = InstitucionSede.instituciones_en_sede @usuario.sede_id
        @periodos = Periodo.all order: [:anio.desc, :semestre.asc]
        
        unless params[:institucion_sede_id].blank?
            @data              = []
            secciones          = Seccion.all    institucion_sede_id: params[:institucion_sede_id],
                                                periodo_id: params[:periodo_id]

            @periodo           = Periodo.get params[:periodo_id]
            secciones_dictadas = secciones.links_secciones_dictadas
            asignaturas        = secciones_dictadas.asignatura
            planes_estudio     = asignaturas.plan_estudio

            secciones.each do |seccion|
                secciones_dictadas_para_hash = []
                las_secciones = secciones_dictadas.select{|sd| sd.seccion_id == seccion.id}
                las_secciones.each do |sd|
                    asignatura = asignaturas.select{|x| x.id == sd.asignatura_id}.first
                    secciones_dictadas_para_hash <<     {
                                                            :asignatura   => asignatura,
                                                            :plan_estudio => planes_estudio.select{|x| x.id == asignatura.plan_estudio_id}.first
                                                        }
                end

                @data <<    {
                                :seccion_id         => seccion.id,
                                :numero             => seccion.numero,
                                :estado             => seccion.estado,
                                :cupos              => seccion.cupos,
                                
                                :alumnos_inscritos  => seccion.alumnos_inscritos,
                                :periodo            => @periodo.nombre,
                                :secciones_dictadas => secciones_dictadas_para_hash
                            }
            end

        end
    end

    def secciones_ver
        @seccion = Seccion.get params[:id]

        inscripciones_planes = AlumnoPlanEstudio.all(
                :links_secciones_inscritas => {
                    :seccion_dictada => {
                        :seccion_id => @seccion.id
                    }
                }
        )

        institucion_sede_plan      = inscripciones_planes.first.institucion_sede_plan

        alumnos                    = inscripciones_planes.alumno
        usuarios_alumno            = alumnos.datos_personales
        planes_estudio             = @seccion.links_secciones_dictadas.asignaturas.plan_estudio

        @data = []
        inscripciones_planes.each do |item|
                alumno                = alumnos.select{ |a| a.id == item.alumno_id }.first
                usuario_alumno        = usuarios_alumno.select{ |a| a.id == alumno.usuario_id }.first
                plan_estudio          = planes_estudio.select{ |a| a.id == institucion_sede_plan.plan_estudio_id }.first


                @data << {
                        :usuario             => usuario_alumno,
                        :alumno              => alumno,
                        :alumno_plan_estudio => item,
                        :plan_estudio        => plan_estudio,
                }
        end

    end


    private
    def iniciar
        @usuario              = current_user_object
        @ejecutivo_matriculas = @usuario.ejecutivo_matriculas

        unless params[:rut].blank?
            @us_alumno = Usuario.first rut: params[:rut]
            @alumno    = @us_alumno.alumno if @us_alumno
        end
    end

end