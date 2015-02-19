# encoding: utf-8
class Mantenedores::SeccionesController < ApplicationController

	crud :seccion, :title_attribute => 'id'
    protect_from_forgery :except => [
                                     :abrir_secciones, 
                                     :agregar_alumnos, 
                                     :asignaturas_secciones,
                                     :update,
                                     :fusion_seccion
                                    ]
    def asignaturas_secciones
        @periodos  = Periodo::obtener_todos periodo_en_curso[:id]
        @planes_estudios = PlanEstudio::obtener_todos PlanEstudio::VIGENTE
        @items = []
        if params.has_key?("carreras") 
            attrs = [:id, :nombre, :plan_estudio_id]
            
            periodo_id = params[:periodo][:periodo_id]
            @plan_estudio_id = params[:carreras][:carreras_id].to_i 

            @periodo = Periodo.get(periodo_id)
            @items = Asignatura::obtener_todas_por_plan_estudio_y_periodo_map @plan_estudio_id , periodo_id, attrs 
        end 
    end

    def abrir_secciones
        
        @asignatura  = Asignatura.first(:id => params[:id])
        @items = @asignatura.links_secciones_dictadas.seccion.sort{|s,t| s[:created_at] <=> t[:created_at]}.reverse!

        if params.has_key?("seccion")
            cupos = params[:seccion][:cupos].to_i ; docente = params[:seccion][:docente_id].to_i 
            estado = params[:seccion][:estado].to_i ; numero = params[:seccion][:numero].to_i
            periodo  = current_period.id
            institucion_sede_id = current_user_object.sede.id

            seccion = Seccion.new(:cupos => cupos, :docente_id => docente, :estado => estado,:periodo_id => periodo,:institucion_sede_id => institucion_sede_id , :numero => numero )

            if seccion.save
                seccion_dictada = SeccionDictada.new(:seccion_id => seccion.id,:asignatura_id =>  @asignatura.id )
                if seccion_dictada.save
                    flash[:notice] = "La Seccion ha sido abierta exitosamente"
                    #redirect_to lista_asignaturas_secciones_path
                else
                    seccion.destroy
                    flash[:error] = "No se logro guardar la seccion "
                    #render :action => "abrir_secciones"
                end    
            else
                flash[:error] = "Ocurrio un problema al abrir la seccion!!"
            end
            render :action => "abrir_secciones"
        end

    end

    def secciones_por_asignatura
        @items = Seccion.all(:asignatura_id => params[:id])   

    end

    def inscribir_alumnos_seccion
        @seccion = Seccion.first(:id => params[:id])

        logger.info(@seccion.inspect)
        @alumnos = Usuario.all(:tipo => Usuario::ESTUDIANTE ) 
        
        @items = []
        @alumnos.each do |i|
           # @items << "#{i.rut }::#{i.primer_nombre + " " + i.segundo_nombre + " " + i.apellido_paterno + " " + i.apellido_materno }"
            @items << "#{i.rut }"
        end
       # puts params[:alumnos][:id].inspect

        if params.has_key?("alumnos")
            if params[:alumnos][:id].length > 0
                params[:alumnos][:id].each do |i|
                    id = AlumnoPlanEstudio.first(:alumno_id => i)
                    puts id.inspect
                    tmp = AlumnoInscritoSeccion.new(:alumno_plan_estudio_id => AlumnoPlanEstudio.last(:alumno_id => i).id, :seccion_id => params[:id])
                    if tmp.save
                        flash[:notice] = "Alumnos han sido inscritos exitosamente"
                    else
                        flash[:error] = "Alumnos han sido inscritos exitosamente"
                    end
                end
            end
        end  

    end


    def detalle_asignatura_secciones
        idAsignatura = params[:asignatura_id]
        periodo = params[:periodo_id]
        @asignatura = Asignatura.first(:fields => [:id, :nombre, :plan_estudio_id, :created_at], :conditions => {:id => idAsignatura} )#.map{|x| [x.id,x.nombre,x.plan_estudio_id]}
        @items = @asignatura.links_secciones_dictadas.seccion(
                                                                :order => [:created_at.desc],
                                                                :periodo_id => periodo,
                                                                :numero.not => [    
                                                                            Seccion::CONVALIDADA_HOMOLOGADA,
                                                                            Seccion::HISTORIAL_ACADEMICO
                                                                        ]
                                                            )
    end


    def edit
        @jornadas  = Seccion::JORNADAS
        @estados = Seccion::ESTADOS
        @item = Seccion.get(params[:id].to_i)
        docente = Docente.all()
        
    end

    def typeaheadresp
        query = params[:query]
        persona = Docente.all(:datos_personales => { :apellido_paterno.like => "%#{query}%"}) | Docente.all(:datos_personales => { :apellido_materno.like => "%#{query}%"}) | Docente.all(:datos_personales => { :rut.like => "%#{query}%"})
        array = []
        persona .each do |p|
            array << "#{p.datos_personales.apellido_paterno} #{p.datos_personales.apellido_materno} #{p.datos_personales.primer_nombre} | #{p.datos_personales.rut}"
        end
        render :json => array
    end

    def update
        @item = Seccion.get(params[:id].to_i)
        rut = params[:docente_id].split('| ')
        docente = Docente.first(:datos_personales => {:rut => rut[1]})
        Seccion.transaction do
            @item.cupos = params[:cupos].to_i
            @item.numero = params[:numero].to_i
            @item.estado = params[:estado].to_i
            @item.jornada = params[:jornada].to_i
            @item.docente_id = docente == nil ? nil : docente.id
            @item.save
        end
        flash[:notice] = "La seccion fue actualizada exitosamente!"
        redirect_to asignaturas_escuela_path
        
        rescue Exception => e
            flash[:error] = "Ha ocurrido un error, no se ha podido actualizar la seccion!"
            redirect_to asignaturas_escuela_path        
    end

    def fusion_seccion
        if current_role_can?(:direccion_escuela)
            @sedes = Sede.all(id: Sede::SEDES_VIGENTES)
        else
            @sedes = Sede.all(:id => current_user[:sede_id])
        end
        @items = Seccion.first(:id => params[:id_seccion].to_i)
        @fusiones = @items.secciones_hijas
        if params.has_key?("filtro")
            seccion_hija = Seccion.first(id: params[:filtro][:seccion_id].to_i)
            raise Excepciones::OperacionNoPermitidaError, "La seccion seleccionada como maestra ya es hija de otra seccion y no puede ser fusionada" if not @items.fusion_id.blank?
            raise Excepciones::OperacionNoPermitidaError, "No se puede fucionar la seccion con si misma" if seccion_hija.id == @items.id
            Seccion.transaction do
                seccion_hija.fusion_id = @items.id
                seccion_hija.save
            end
            flash[:notice] = "La seccion fue fusionada exitosamente!"
            redirect_to fusion_seccion_path
        end
        rescue Excepciones::OperacionNoPermitidaError => e
            flash[:error] = e.message
            redirect_to fusion_seccion_path
        rescue DataMapper::SaveFailureError => e
            flash[:error] = "Ha ocurrido un error, no se ha podido fusionar la seccion!"
            redirect_to fusion_seccion_path
        rescue Exception => e
            puts e.inspect.red
            flash[:error] = Excepciones::ERROR_DESCONOCIDO
            redirect_to fusion_seccion_path
    end

end