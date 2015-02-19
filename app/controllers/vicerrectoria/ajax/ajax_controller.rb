# encoding: utf-8
class Vicerrectoria::Ajax::AjaxController < ApplicationController

    before_filter :iniciar
    
    protect_from_forgery :except => [
                                        :buscar_carreras,
                                        :buscar_asignaturas,
                                        :buscar_secciones,
                                        :buscar_secciones_por_periodo
                                    ]
    def buscar_carreras
        plan_estudios = PlanEstudio.all(
                                            :fields => [:id, :nombre, :siaa_id_ma], 
                                            :coordinadores => {:usuario_id =>current_user[:id]},
                                            :estado => PlanEstudio::VIGENTE,
                                            :order => :siaa_id_ma.asc
                                        )
        carreras = []
        plan_estudios.each do |i|
            carreras << {:plan_id => i.id, :nombre => i.nombre, :siaa_id_ma => i.siaa_id_ma}
        end
        render :json => {:carreras => carreras}
    end

    def buscar_asignaturas
        asignaturas = Asignatura.all(
                                        :fields => [:id, :nombre,:plan_estudio_id,:semestre], 
                                        :plan_estudio_id => params[:plan_estudio_id].to_i,
                                        :order => :semestre.asc
                                    )
        _asignaturas = []
        asignaturas.each do |i|
            _asignaturas << {:asignatura_id => i.id, :nombre => i.nombre, :semestre => i.semestre}
        end

        render :json => {:asignaturas => _asignaturas}
    end

    def buscar_secciones
        secciones = Seccion.all(
                                    :fields => [:id, :jornada, :numero], 
                                    :links_secciones_dictadas => {
                                                :asignatura_id => params[:asignatura_id].to_i
                                        },
                                    :institucion_sede_id => params[:institucion_sede_id].to_i,
                                    :numero.not => [Seccion::CONVALIDADA_HOMOLOGADA, Seccion::HISTORIAL_ACADEMICO],
                                    #TODO: REVISAR
                                    :periodo_id => periodo_en_curso[:id]
                                )
        _secciones = []
        secciones.each do |i|
            _secciones << {:seccion_id => i.id, :nombre => i.nombre}
        end

        render :json => {:secciones => _secciones}
    end

    def buscar_secciones_por_periodo
        periodo_id = params[:periodo_id].to_i
        asignatura_id = params[:asignatura_id].to_i
        secciones = Seccion.all(
                                    :fields => [:id, :jornada, :numero], 
                                    :links_secciones_dictadas => {
                                                :asignatura_id => asignatura_id
                                        },
                                    :numero.not => [Seccion::CONVALIDADA_HOMOLOGADA, Seccion::HISTORIAL_ACADEMICO],
                                    :institucion_sede => {:sede_id => current_user[:sede_id]},
                                    :periodo_id => periodo_id
                                )
        _secciones = []
        secciones.each do |i|
            _secciones << {:seccion_id => i.id, :nombre => i.nombre}
        end

        render :json => {:secciones => _secciones}
    end
end