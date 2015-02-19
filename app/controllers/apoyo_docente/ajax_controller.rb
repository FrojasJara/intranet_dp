# encoding: utf-8
class ApoyoDocente::AjaxController < ApplicationController

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
        									:institucion_sede_plan => {
        																:institucion_sede => {:sede_id => params[:sede_id].to_i }
        																},
        									:estado => PlanEstudio::VIGENTE,
                                            :coordinadores => {:usuario_id =>current_user[:id]},
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
                                    :institucion_sede => {:sede_id => current_user[:sede_id]},
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
        sede_id = params[:sede_id].to_i
        secciones = Seccion.all(
                                    :fields => [:id, :jornada, :numero], 
                                    :links_secciones_dictadas => {
                                                :asignatura_id => asignatura_id
                                        },
                                    :numero.not => [Seccion::CONVALIDADA_HOMOLOGADA, Seccion::HISTORIAL_ACADEMICO],
                                    :institucion_sede => {:sede_id => sede_id},
                                    :periodo_id => periodo_id
                                )
        _secciones = []
        secciones.each do |i|
            _secciones << {:seccion_id => i.id, :nombre => i.nombre}
        end

        render :json => {:secciones => _secciones}
    end
    def buscar_bloques
        bloques = BloqueHorario.all(
                                    :fields => [:id, :hora_inicio, :hora_termino], 
                                    :sede_id => params[:sede],
                                    :periodo_id => params[:periodo]
                                )
        _bloques = []
        bloques.each do |i|
            _bloques << {:bloque_id => i.id, :h_inicio => i.hora_inicio, :h_termino => i.hora_termino}
        end

        render :json => {:bloques => _bloques}
    end
    def buscar_salas
        salas = Sala.all(
                                    :fields => [:id, :nombre, :capacidad], 
                                    :sede_id => params[:sede]
                                )
        _salas = []
        salas.each do |i|
            _salas << {:sala_id => i.id, :nombre => i.nombre, :capacidad => i.capacidad}
        end

        render :json => {:salas => _salas}
    end
    def typeaheadresp_carreras
        query = params[:query]
        carrera = PlanEstudio.all(:nombre.like => "%#{query}%",:estado => 1)
        array = []
        carrera .each do |c|
            array << "#{c.nombre} #{c.revision} | #{c.id}"
        end
        render :json => array
    end

end