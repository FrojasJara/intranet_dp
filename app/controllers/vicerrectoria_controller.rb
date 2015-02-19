class VicerrectoriaController < ApplicationController

    protect_from_forgery :except => [:abrir_asignaturas_semestre, :asignaturas_semestre, :buscar_alumnos, :generar_informe_alumnos, :ajax_buscar_carreras_sedes]
    before_filter :iniciar

    def asignaturas_semestre
        attrs = [:id, :nombre, :plan_estudio_id]
        @periodos  = Periodo::obtener_todos periodo_en_curso[:id]
        @planes_estudios = PlanEstudio::obtener_todos PlanEstudio::VIGENTE
        @items = []

        if params.has_key?("carreras") 
            periodo_id = params[:periodo][:periodo_id]
            @plan_estudio_id = params[:carreras][:carreras_id].to_i 

            @periodo = Periodo.get(:fields => [:id, :anio, :semestre])
            @items = Asignatura::obtener_todas_por_plan_estudio_y_periodo_map @plan_estudio_id , periodo_id, attrs 
        end   	
    end

	def abrir_asignaturas_semestre

        asignaturas = params[:asignaturas]
		
        if Asignatura::abrir_asignaturas_periodo asignaturas, periodo_en_curso[:id], current_user[:sede]
			flash[:notice] = "Las Asignaturas fueron creadas exitosamente, junto con sus respectivas secciones!"
			redirect_to asignaturas_semestre_path
		else
			flash[:error] = "Ha ocurrido un problema y la asignatura no puedo ser abierta, ni sus secciones creadas!"
			#render :action => :asignaturas_semestre
		end

	end
	
	
	def generar_carga_horaria
		
	end

    def ajax_buscar_carreras_sedes

        sede_id = params[:sede_id].to_i

        carreras = PlanEstudio.all(:fields => [:id, :nombre, :anio_inicio, :anio_fin], :institucion_sede_plan => {:institucion_sede => {:sede_id => sede_id }}, :estado => PlanEstudio::VIGENTE, :order => [:nombre.asc])
        tmp = []

        carreras.each do |i|
            tmp << {:plan_id => i.id, :nombre => "#{i.nombre} [#{i.anio_inicio} - #{i.anio_fin}]" }
        end

        render :json => {:carreras => tmp }
        
    end

    def generar_informe_alumnos

        @items = []

        if params.has_key?("filtro")
            filtros = params[:filtro]
            session[:filtro] = params[:filtro]
            @items =  Reportes::Vicerrectoria::obtener_alumnos_matriculados filtros
        end

        @items =  Reportes::Vicerrectoria::obtener_alumnos_matriculados session[:filtro]
        
        respond_to do |format|
            format.html
            respond_to_xls format , @items
            respond_to_pdf format

        end
    end

    #======================= Alumnos matriculados ========================#

    def alumnos_matriculados
        @periodos = Periodo.all order: [:anio.desc, :semestre.desc]

        @instituciones_sedes = InstitucionSede.all sede: {
                                    id: Sede::SEDES_VIGENTES
                                }

        unless params[:institucion_sede_id].blank?
            @institucion_sede = InstitucionSede.get params[:institucion_sede_id]
            periodo_consulta  = []
            @periodo          = Periodo.get params[:periodo_id]
            periodo_consulta    << @periodo.id

            @periodo_ant        = Periodo.get Periodo.periodo_anterior( @periodo.id )
            @periodo_anterior   = @periodo_ant.id
            periodo_consulta    << @periodo_anterior if !@periodo_anterior.blank?

            institucion_sede_planes = InstitucionSedePlan.all   fields: [:id],
                                                                :institucion_sede_id => params[:institucion_sede_id],
                                                                alumno_plan_estudio: {
                                                                    matricula_plan: {
                                                                            periodo_id: periodo_consulta
                                                                    }
                                                                }
                                                                

            alumnos_planes_estudios = AlumnoPlanEstudio.all fields: [:id, :institucion_sede_plan_id, :alumno_id, :anio_ingreso],
                                                               :institucion_sede_plan_id => institucion_sede_planes.map(&:id),
                                                               matricula_plan: {
                                                                    periodo_id: periodo_consulta
                                                               }
                                                                
            
            al_pl_es = { 
                        fields: [:id, :alumno_plan_estudio_id, :created_at],
                        :alumno_plan_estudio_id => alumnos_planes_estudios.map(&:id).uniq,
                        }
            
            matriculas = MatriculaPlan.all( {:periodo_id => @periodo.id,
                                        :estado.not => [MatriculaPlan::ANULADA]}.merge(al_pl_es) ) + 
                         MatriculaPlan.all( {:periodo_id => @periodo_anterior, 
                                        :estado.not => [MatriculaPlan::ANULADA],
                                        planes_pago: {
                                            :periodo_id => @periodo_anterior, 
                                            :tipo => MatriculaPlan::MATRICULAS_ANUALES_VALORES
                                        } }.merge(al_pl_es) ) +
                         MatriculaPlan.all( {:periodo_id => @periodo_anterior, 
                                        :estado.not => [MatriculaPlan::ANULADA],
                                        planes_pago: {
                                            :periodo_id => @periodo.id, 
                                            :tipo => MatriculaPlan::MATRICULAS_SEMESTRALES
                                        } }.merge(al_pl_es) )


            alumnos_planes_estudios    = AlumnoPlanEstudio.all fields: [:id, :institucion_sede_plan_id, :alumno_id, :anio_ingreso], 
                                                               id: matriculas.map(&:alumno_plan_estudio_id).uniq,
                                                               matricula_plan: {
                                                                 periodo_id: periodo_consulta
                                                               }

            alumnos                    = alumnos_planes_estudios.alumnos fields:[:id, :usuario_id], id: alumnos_planes_estudios.map(&:alumno_id).uniq
            usuarios                   = alumnos.datos_personales(fields: [:id, :rut, :primer_nombre, :segundo_nombre, :apellido_paterno, :apellido_materno])
            instituciones_sedes_planes = alumnos_planes_estudios.institucion_sede_plan
            planes_estudios            = instituciones_sedes_planes.plan_estudio(fields: [:id, :nombre])
            secciones_inscritas        = alumnos_planes_estudios.links_secciones_inscritas(fields: [:id, :alumno_plan_estudio_id], :seccion_dictada => { seccion: {:periodo => @periodo } } )
            planes_pagos               = matriculas.planes_pagos(fields: [:id, :nivel])

            @matriculas = []
            desertores      = 0
            retirados       = 0
            regulares       = 0 
            congelados      = 0
            s_inscripcion   = 0
            s_matricula     = 0
            egresados       = 0
            titulados       = 0
            total_alumnos   = alumnos_planes_estudios.size

            matriculas.each do |m|
                al_pl_es = alumnos_planes_estudios.select{|x| x.id == m.alumno_plan_estudio_id}.first
                desertores      = desertores    + 1 if [Alumno::DESERTOR,Alumno::POSTERGADO].include? al_pl_es.estado
                retirados       = retirados     + 1 if Alumno::RETIRADO == al_pl_es.estado
                regulares       = regulares     + 1 if Alumno::REGULAR == al_pl_es.estado 
                congelados      = congelados    + 1 if Alumno::CONGELADO == al_pl_es.estado
                s_inscripcion   = s_inscripcion + 1 if Alumno::SIN_INSCRIPCION == al_pl_es.estado
                s_matricula     = s_matricula   + 1 if Alumno::SIN_MATRICULA == al_pl_es.estado
                egresados       = egresados     + 1 if Alumno::EGRESADO == al_pl_es.estado 
                titulados       = titulados     + 1 if Alumno::TITULADO == al_pl_es.estado 
                al       = alumnos.select{|x| x.id == al_pl_es.alumno_id}.first
                us       = usuarios.select{|x| x.id == al.usuario_id}.first
                in_se_pl = instituciones_sedes_planes.select{|x| x.id == al_pl_es.institucion_sede_plan_id}.first
                pl_es    = planes_estudios.select{|x| x.id == in_se_pl.plan_estudio_id}.first
                sec_ins  = secciones_inscritas.select{|x| x.alumno_plan_estudio_id == al_pl_es.id}
                pl_pg    = (pp = planes_pagos.select{|x| x.matricula_plan_id == m.id}).blank? ? nil : pp.last

                @matriculas << {
                    matricula:              m,
                    alumno_plan_estudio:    al_pl_es,
                    alumno:                 al,
                    usuario:                us,
                    plan_estudio:           pl_es,
                    inscripciones:          sec_ins,
                    plan_pago:              pl_pg,
                }
            end

            @estadisticas = {
                desertores:     desertores,
                retirados:      retirados,
                regulares:      regulares,
                congelados:     congelados, 
                s_inscripcion:  s_inscripcion,
                s_matricula:    s_matricula,
                egresados:      egresados,
                titulados:      titulados,
                total:          total_alumnos       
            }

        end
        
    end

    private

    def respond_to_xls format, items
        objects = []
        items.each do |i|
            objects << Reportes::HashToObject.new(i) 
        end

        columnas = objects.first.instance_variables.map{|x| x.to_s.gsub('@', '').to_sym}
        titulos = objects.first.instance_variables.map{|x| x.to_s.gsub('@', '').capitalize}

        file = objects.to_xls(
            columns: columnas,
            headers: titulos
        )

        format.xls do
            send_data file,
            filename: "#{Time.now.strftime('%Y-%m-%d')}-alumnos.xls"
        end
    end


    def respond_to_pdf format
        format.pdf do
            @example_text = "informe"
            render :pdf => "alumnos",
                :template => 'vicerrectoria/generar_informe_alumnos.haml',
                #:layout => 'pdf',
                :footer => {
                    :center => "Center",
                    :left   => "Left",
                    :right  => "Right"
                }
            end
    end
end


