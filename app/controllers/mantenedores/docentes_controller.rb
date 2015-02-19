# encoding: utf-8
class Mantenedores::DocentesController < ApplicationController
    before_filter :store_location, :only => :index

    def index
    	#@items = Docente.all(:datos_personales => Usuario.all )
        
        @docentes = Docente.all(:fields => [:id, :usuario_id, :curriculum, :en_ejercicio])
        @items = []
        unless @docentes.blank?    
            iterador = Docente::mapear_iterador(@docentes)
            usuarios = Docente::obtener_datos_docentes(@docentes)

            usuarios.each do |p|
                iterador.each do |i|
                    @items << {
                        :id_usuario => p[0][:id_usuario], :rut => p[0][:rut], 
                        :primer_nombre => p[0][:primer_nombre], :segundo_nombre => p[0][:segundo_nombre], 
                        :apellido_paterno => p[0][:apellido_paterno], :apellido_materno => p[0][:apellido_materno], 
                        :id_docente => i[0][:id_docente], :curriculum => i[0][:curriculum], 
                        :en_ejercicio => i[0][:en_ejercicio] 
                        } if p[0][:id_usuario] == i[0][:usuario_id] 
                end
            end
        else
            @items = []
        end

    end

    def show
        @item = Docente.find_by_usuario_id(params[:id])
        @antecedentes = Antecedente.all(:docente_id => @item.id)
        @item = @item.datos_personales.attributes.merge(@item.attributes)
        

        
    end

    def new
        #@item = Docente.find_by_usuario_id(params[:id])
    	@item = Docente.new
        @datos_personales = Usuario.new
    end

    def edit
        @datos_personales = Usuario.get(params[:id])
        @item = Docente.find_by_usuario_id(params[:id])
        #@estudios = (not @item.estudios.blank? ) ? @item.estudios.first : Estudio.new(:docente_id => @item.id)  
    end

    def create
        
        rut = params[:docente][:usuario][:rut].gsub(".","")
        u  = Usuario.first(:rut => rut)
        if u.blank?
            Docente.transaction do
                @antecedentes = params[:antecedentes]
                
                @usuario = Usuario.new
                @usuario.rut = params[:docente][:usuario][:rut].gsub(".","")
                @usuario.password = Digest::MD5.hexdigest params[:docente][:usuario][:rut]
                @usuario.email   = params[:docente][:usuario][:email]

                @usuario.primer_nombre = params[:docente][:usuario][:primer_nombre] 
                @usuario.segundo_nombre =  params[:docente][:usuario][:segundo_nombre] 
                @usuario.apellido_paterno =  params[:docente][:usuario][:apellido_paterno] 
                @usuario.apellido_materno =  params[:docente][:usuario][:apellido_materno]
                @usuario.domicilio        =  params[:docente][:usuario][:domicilio]
                @usuario.villa_poblacion  =  params[:docente][:usuario][:villa_poblacion]
                @usuario.telefono_fijo    =  params[:docente][:usuario][:telefono_fijo]
                @usuario.profesion        =  params[:docente][:usuario][:profesion]
                @usuario.tipo = 2
                #puts "INSTITUCION SEDE #{current_user[:institucion_sede]}"
                @usuario.sede_id = params[:docente][:usuario][:sede_id].to_i
                @usuario.region_id = params[:docente][:usuario][:region_id].to_i
                @usuario.comuna_id =  params[:docente][:usuario][:comuna_id].to_i
                @usuario.pais_id = params[:docente][:usuario][:pais_id].to_i         
                @usuario.save
                @docente = Docente.new
                    @docente.en_ejercicio = params[:docente][:en_ejercicio] 
                    @docente.curriculum = params[:docente][:curriculum]
                    @docente.usuario_id = @usuario.id   
                @docente.save
                unless @antecedentes.blank?
                    @antecedentes.each do |a|
                        #puts "ANTECEDENTE #{a.inspect}"
                        antecedente                  = Antecedente.new
                        antecedente.tipo_antecedente = a[:tipo_antecedente].to_i
                        antecedente.lugar            = a[:institucion]
                        antecedente.descripcion      = a[:descripcion]
                        antecedente.desde            = a[:desde]
                        antecedente.hasta            = a[:hasta]
                        antecedente.detalle          = a[:cargo]
                        antecedente.docente_id       = @docente.id
                        
                        antecedente.save
                        #puts "ERORRO#{antecedente.errors.inspect}"
                    end
                end
            end
        
            flash[:notice] = "El docente ha sido ingresado exitosamente!"
            redirect_to mantenedores_docentes_path
        else
            flash[:error] = "El Rut ya existe como Usuario Registrado no puede ser ingresado nuevamente!"
            redirect_to mantenedores_docentes_path
        end
        rescue Exception => e
            flash[:error] = "Ha ocurrido un error, no se ha podido crear al docente!"
            redirect_to mantenedores_docentes_path
    end

    def update
        
        docente     = Docente.get(params[:id].to_i)
        usuario     = docente.datos_personales
        antecedente = params[:antecedentes]
        Usuario.transaction do            
            #usuario.rut = params[:docente][:usuario][:rut]
            # usuario.primer_nombre = params[:docente][:usuario][:primer_nombre]
            # usuario.segundo_nombre = params[:docente][:usuario][:segundo_nombre]
            # usuario.apellido_paterno = params[:docente][:usuario][:apellido_paterno]
            # usuario.apellido_materno = params[:docente][:usuario][:apellido_materno]
            # usuario.sede_id = params[:docente][:usuario][:sede_id].to_i
            unless antecedente.blank?
                antecedente.each do |i|
                    datos = i
                    antecedentes                    = Antecedente.new
                    antecedentes.lugar              = datos[:institucion]
                    antecedentes.tipo_antecedente   = datos[:tipo_antecedente].to_i
                    antecedentes.desde              = datos[:desde]
                    antecedentes.hasta              = datos[:hasta]
                    antecedentes.detalle            = datos[:cargo]
                    antecedentes.descripcion        = datos[:descripcion]
                    antecedentes.docente_id         = docente.id
                    antecedentes.save
                end
            end

            docente.en_ejercicio = params[:docente][:en_ejercicio]
            docente.curriculum   = params[:docente][:curriculum]

            usuario.update params[:docente][:usuario].merge({tipo: 4})
            logger.info "Errores: #{usuario.errors.inspect}".bold.red

            docente.save
        end

        flash[:notice] = "Los datos del Docente Han sido actualizados exitosamente!"
        redirect_to mantenedores_docentes_path

        rescue Exception => e
            log_error e
            flash[:error] = "Ha ocurrido un problema y los datos no se han podido actualizar#{e}"
            redirect_to mantenedores_docentes_path
    end

    def destroy
    	@item = Docente.get(params[:id])
    	
    	if @item.destroy
			redirect_to "/mantenedores/docentes"
    	end
    end

    def contrato
        @usuario = Usuario.get params[:docente_id]
        @docente = @usuario.docente        

        @contratos = @docente.contratos
    end

    def contrato_save
        docente = Docente.get params[:contrato][:docente_id]
        usuario = docente.datos_personales
        unless params[:contrato].blank?
            begin
                Contrato.create params[:contrato]
                flash[:notice] = "Contrato ingresado correctamente"
            rescue Exception => e
                flash[:error] = "Por favor complete toda la información"
            end
        end
        redirect_to mantenedores_docente_contrato_path(usuario.id)
    end

    def contrato_prestacion
        contratos 'prestacion'
        #render "mantenedores/docentes/documentos/prestacion", :layout => "pdf_sin_logo"        
    end
    def contrato_solicitud
        contratos 'solicitud'

        #render "mantenedores/docentes/documentos/prestacion", :layout => "pdf_sin_logo"        
    end

    private
    def contratos(tipo)
        @usuario = Usuario.get params[:docente_id]
        @docente = @usuario.docente
        @contrato = Contrato.get params[:id]
        @institucion_sede = @contrato.institucion_sede
        @institucion = @institucion_sede.institucion
        @sede = @institucion_sede.sede
        @vicerrector = Usuario.first sede: @institucion_sede.sede, rol_id: 10


        carpeta = "#{Contrato::URL_DOCUMENTOS}/#{@institucion_sede.id}/#{@usuario.rut}"
        fcertificado = "#{carpeta}/#{@contrato.id}_#{tipo}.pdf".delete(" ")

        FileUtils.mkdir_p carpeta

        str = render_to_string("mantenedores/docentes/documentos/#{tipo}", :layout => "pdf_sin_logo")

        pdf = WickedPdf.new.pdf_from_string(str, :disposition => 'inline')

        certificado = File.open(fcertificado, 'wb') do |file|
            file << pdf
        end
        
        redirect_to certificado.path.partition("public")[2]+"?date=#{Time.now.to_i}"
    end
end