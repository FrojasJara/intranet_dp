class VicerrectoriaController < ApplicationController

    protect_from_forgery :except => [:abrir_asignaturas_semestre, :asignaturas_semestre, :buscar_alumnos, :generar_informe_alumnos, :ajax_buscar_carreras_sedes]

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


