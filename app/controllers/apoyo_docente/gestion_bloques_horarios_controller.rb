# encoding: utf-8
class ApoyoDocente::GestionBloquesHorariosController < ApplicationController


    before_filter :iniciar
    protect_from_forgery :except => [
                                        :nuevo_bloque_horario,
                                        :registrar_nuevo_bloque_horario
                                    ]
    def ver_bloques_horarios
        @bloques_horarios  = BloqueHorario.all(:periodo_id => periodo_en_curso[:id], :sede_id => current_user[:sede_id])
    	
    end

    def nuevo_bloque_horario
    	
    end
    
    def registrar_nuevo_bloque_horario
    	sede_id = current_user[:sede_id].to_i
        periodo_id = Periodo::en_curso.id
        bloque_horario = params[:bloque]
            
            BloqueHorario.transaction do
                nuevo_bloque = BloqueHorario.new
                nuevo_bloque.numero = bloque_horario[:numero].to_i
                nuevo_bloque.hora_inicio = bloque_horario[:hora_inicio]
                nuevo_bloque.hora_termino = bloque_horario[:hora_termino]
                nuevo_bloque.sede_id = sede_id
                nuevo_bloque.periodo_id = periodo_id
                nuevo_bloque.save
            end

        flash[:notice] = "El bloque de Horario ha sido ingresado exitosamente."
        redirect_to apoyo_docente_ver_bloques_horarios_path

        rescue Exception => e
            flash[:error] = "Ha ocurrido un error y no ha sido prosible registrar el bloque horario."
            redirect_to apoyo_docente_ver_bloques_horarios_path
    end
end