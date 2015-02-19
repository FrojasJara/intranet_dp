# encoding: utf-8
class DirectorEscuelaController < ApplicationController

    before_filter :seccion_config, only: [
        :acta_notas, :listado_alumnos, :libro_calificaciones, :libro_asistencia
    ]
    protect_from_forgery :except => [:asignaturas_escuela]

	def asignaturas_escuela
		attrs = [:id, :nombre, :plan_estudio_id, :semestre]
        @periodos  = Periodo::obtener_todos periodo_en_curso[:id]
        @planes_estudios =  PlanEstudio.all(:coordinadores => {:usuario_id =>current_user[:id]})
        @items = []
        
        if params.has_key?("plan_estudios")
            @plan_estudio_id = params[:plan_estudios][:plan_estudio_id].to_i 
            @periodo_id = params[:plan_estudios][:periodo_id].to_i
                    
            @items = Asignatura::obtener_todas_por_plan_estudio_y_periodo_map @plan_estudio_id , @periodo_id, attrs 

        end
	end

    # Muestra el acta de notas solamente con la sección [AV]
    def acta_notas
    end

    def listado_alumnos
        render 'docentes/obtener_listado_alumnos'
    end

    def libro_calificaciones
        @libro = @seccion.preparar_libro_calificaciones unless @seccion.blank?

        render 'docentes/obtener_libro_calificaciones'
    end

    def libro_asistencia
        @libro = @seccion.libro_asistencia unless @seccion.blank?

        render 'docentes/obtener_libro_asistencia'
    end

    private
    def seccion_config
        @alumnos = []

        @seccion_id = (not params[:seccion_id].nil?) ? params[:seccion_id].to_i : nil
        
        @plan_estudio = PlanEstudio.first fields: [:nombre], id: params[:plan_estudio_id] if params[:plan_estudio_id] && !params[:plan_estudio_id].blank?

        unless @seccion_id.blank?
            @seccion = Seccion.get @seccion_id
            @asignaturas_seccion = @seccion.asignaturas_seccion

            @periodo_seleccionado = @seccion.periodo
            @docente = @seccion.docente

            @usuario = @docente.datos_personales unless @docente.blank?

            @alumnos = @seccion.alumnos params[:plan_estudio_id]
            @asignatura = Asignatura.get params[:asignatura_id]
        end

        flash.now[:info] = "La sección consultada no registra alumnos" if @alumnos.empty? 
            
    end

end