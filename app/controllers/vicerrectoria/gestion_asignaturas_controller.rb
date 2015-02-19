class Vicerrectoria::GestionAsignaturasController < ApplicationController
    
    protect_from_forgery :except => [
    									:abrir_asignaturas_semestre, 
    									:registrar_apertura_asignaturas_semestre,
    									:ver_secciones_asignatura,
    									:registrar_nueva_seccion
    								]

	def registrar_apertura_asignaturas_semestre

        asignaturas = params[:asignaturas]
        puts asignaturas.inspect
		
        if Asignatura::abrir_asignaturas_periodo asignaturas, periodo_en_curso[:id], current_user[:sede]
			flash[:notice] = "Las Asignaturas fueron creadas exitosamente, junto con sus respectivas secciones!"
			redirect_to asignaturas_semestre_path
		else
			flash[:error] = "Ha ocurrido un problema y la asignatura no puedo ser abierta, ni sus secciones creadas!"
			#render :action => :asignaturas_semestre
		end
	end
	
	# params plan_estudio_id
    def abrir_asignaturas_semestre
        @plan_estudios = PlanEstudio.all(:coordinadores => {:usuario_id =>current_user[:id]})

    end

    # => params plan_estudio_id
    def ver_asignaturas_plan_estudio
    	plan_estudio_id = params[:plan_estudio_id].to_i
        @plan_estudio = PlanEstudio.first(:fields => [:id, :nombre], :id => plan_estudio_id)

        @asignaturas = Asignatura.all(
                                        :fields => [:id, :nombre, :codigo,:semestre ], 
                                        :plan_estudio_id => plan_estudio_id
                                    )

    end

    def ver_secciones_asignatura
    	asignatura_id = params[:asignatura_id].to_i
		@asignatura = Asignatura.get(asignatura_id)
		@instituciones  = InstitucionSede.all(esta_abierta: 1)
        periodo = Periodo::en_curso
		
        @secciones_dictadas = SeccionDictada.all(
                                                    :fields => [:id, :seccion_id, :asignatura_id],
                                                    :asignatura_id => asignatura_id,
                                                    :periodo_id => periodo.id,
                                                    :seccion => {:numero.not => [Seccion::CONVALIDADA_HOMOLOGADA,Seccion::HISTORIAL_ACADEMICO]}
                                                )
        #@secciones = Seccion.all()
    end
    def registrar_nueva_seccion
    	seccion = params[:seccion]
        rut = params[:docente_id].split('| ')
        docente = Docente.first(:datos_personales => {:rut => rut[1]})
    	asignatura_id = params[:seccion][:asignatura_id].to_i
    	
    	Vicerrectoria::Seccion::guardar_nueva_seccion seccion, docente

        flash[:notice] = "La seccion fue abierta exitosamente!"
    	redirect_to ver_secciones_asignatura_path(asignatura_id)

        rescue Exception => e
            puts e.inspect.red
            flash[:error] = "Error desconocido"
            ver_secciones_asignatura_path(asignatura_id)
    end
end