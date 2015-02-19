# encoding: utf-8
module ApplicationHelper
    # Arma un arreglo para options_for_select a partir de un arreglo de constantes (arr) definidas en una clase (cls)
    def for_select cls, arr, first=""
        fnl = first.blank? ? [] : [ [first, ""] ]
        cls.const_get(arr).each do |i|
            fnl << [i.to_s.humanize.titleize, cls.const_get(i)]
        end
        
	fnl
    end
    # Devuelve un hash con el nombre de un valor en particular
    # => Params
        # => cls : Clase
        # => arr : Arreglo de constantes
        # => val : Valor entero 
    def get_name cls, arr, val, default = nil
        cls.const_get(arr).each do |i|
            return i.to_s.humanize.upcase if cls.const_get(i).to_s == val.to_s
        end
        return default
    end

    def get_name_real cls, arr, val, default = nil
        cls.const_get(arr).each do |i|
            return i.to_s if cls.const_get(i).to_s == val.to_s
        end
        
        return default
    end

    def value obj, val
        return "" if obj.nil? || obj.send(val).nil?

        obj.send(val)
    end
    
    def get_name_matrix cls, arr, val
        data = []
        vl = val + 1000
        vl = vl.to_s
        k = 1
        while k < vl.length do
            cls.const_get(arr).each do |i|
                data << i.to_s.humanize.capitalize if vl[k] == '1' && ( 1000+ cls.const_get( i ) ).to_s[k] == '1'
            end
            k += 1
        end
        return data.join(", ")
    end
      
    def current_controller_is?(value, extra = true)
        controller_is?(value) && extra ? 'current' : nil
    end
      

      
    def current_action_is?(value)
        action_is?(value) ? 'current' : nil
    end
      
    def module_is?(value)
        return false if @module_name.nil?
        return @module_name.downcase == value.downcase
    end

    

    # => finderAttrAndModels 
    # => get_attr %w[childField1  childField2 ], %w[parentField1 parentField2 ],  'child_model', 'parent_model', :relation 

    def get_attr(child_attrs, parent_attrs, child_model, parent_model, relation )

        #@asignaturas = Asignatura.all(:fields => [:id, :nombre, :plan_estudio_id])
        child_model =  Kernel.const_get(child_model.classify) ;  parent_model =  Kernel.const_get(parent_model.classify)
        child_model = child_model.all(:fields => child_attrs )
        
        #.map{|x| [{:idPlan => x.id, :nombrePlan => x.nombre}] } 
        parent_model = parent_model.all(:fields => parent_attrs, relation => child_model).map do |x|
                            tmp1 = {}
                                parent_attrs.each do |i|
                                    i = i.to_s + parent_model.to_s 
                                    tmp1[i.to_sym] = x.send(i.chomp(parent_model.to_s))
                                end
                            tmp1
                        end

        tmp = []
        iterador = child_model.map do |x|
                    tmp1 = {}
                                child_attrs.each do |i|
                                    i = i.to_s + child_model.to_s 
                                    tmp1[i.to_sym] = x.send(i.chomp(child_model.to_s))
                                end
                            tmp1
                        end

        #{|x| [{:idAsignatura => x.id, :nombreAsignatura => x.nombre, :idPlan => x.plan_estudio_id}]}

        parent_model.each do |p|
            iterador.each do |i|
                tmp << {:idPlan => p[0][:idPlan],:nombrePlan => p[0][:nombrePlan], :idAsignatura => i[0][:idAsignatura], :nombreAsignatura => i[0][:nombreAsignatura]} if p[0][:idPlan] == i[0][:idPlan] 
            end
        end

           modelo =  Kernel.const_get(modelo.classify)
            rt =  modelo.first(:fields => atributo).nombre
            rt.to_s
    end


    def notificaciones
        str = ""
        # Mensaje informativo, color celeste
        if flash[:info]
            str << render( partial: "partials/notificaciones/info", locals: { mensaje: flash[:info] } )
        end

        # Mensaje de éxito, color verde
        if flash[:notice]
            str << render( partial: "partials/notificaciones/notice", locals: { mensaje: flash[:notice] } )
        end

        # Mensaje de error, color rojo
        if flash[:error]
            str << render( partial: "partials/notificaciones/error", locals: { mensaje: flash[:error] } )
        end

        raw str
    end

    def dinero numero
        number_to_currency numero, :delimiter => "."
    end

    def decimales numero
        number_to_currency numero, delimiter: '.', unit: ''
    end

    def interes numero
        "#{(numero * 100).round}%"
    end

    def fecha_humana fecha
        fecha.strftime("%d/%m/%Y a las %H:%M hrs.")
    rescue
        nil
    end

    def fecha_humana2 fecha
        fecha.strftime("%d/%m/%Y")
    rescue
        nil
    end

    def is_administrador?
        module_is?('administrador') or action_is?('administrador', 'home')
    end

    def is_mensajero?
        module_is?('mensajero') or action_is?('mensajero', 'home')
    end

    def is_administracion?
        module_is?('administracion') or action_is?('administracion', 'home')
    end

    def is_academico?
        module_is?('mantenedores') or controller_is?('docentes') or controller_is?('usuarios', 'mantenedores') or controller_is?('matriculas') or action_is?('academico', 'home')
    end

    def is_alumno?
        !is_administracion? && !is_mensajero? && !is_administrador? && !is_academico?
    end
  

    # => datatables
    # =>    String param1 : Nombre de la tabla.
    # =>    Hash   param2 : Opciones del datatable.
    # =>                    Default: {:msg_zero => "" }
    # => i.e.: datatable("tabla1", {:msg_zero => "No se encontraron elementos"})
    #TODO: aumentar el numero de opciones del datatable de jQuery
    
    def datatable model, options = {}
        options = (not options.blank?) ? options : {:msg_zero => "No se encontraron elementos"}

        options[:nosort] = false if options[:nosort].blank? # Ordenar automáticamente la tabla [AV]
        # => Falta agregar el resto de opciones

        str = ""
        str << render( partial: "partials/datatables/datatable", :locals => {:model => model , :opts => options})
        raw str
    end
    
    # => Estilos de datatable 

    def datatable_src
        str = ""
        str << stylesheet_link_tag("/assets/datatables.bootstrap.css")
        str << javascript_include_tag("/assets/jquery.dataTables.js")
        str << javascript_include_tag("/assets/datatables.bootstrap.js")

        return raw str
    end


    # => higthcharts
    def higthcharts_src
        str = ""
        str << javascript_include_tag("higthcharts/highcharts") 
        str << javascript_include_tag("higthcharts/highcharts-more") 
        str << javascript_include_tag("higthcharts/modules/exporting.js") 
        raw str
    end

      # => full_name_from_hash
    def full_name_from_hash(item)
        item = [item[:primer_nombre], item[:segundo_nombre], item[:apellido_paterno], item[:apellido_materno]]
        item.join(" ").titleize
    end

    def bv(boolean_value)
        boolean_value ? 'Si' : 'No'
    end

    def history item, label, cond = true
        label = item.send(label) unless label.class == String

        cond ? raw("<a href=\"#{historial_path(item.class.to_s, item.id)}\" data-toggle=\"modal\">#{label}</a>") : label

    end
    
    def distance_of_time_in_hours_and_minutes(from_time, to_time)
        from_time = Time.parse(from_time.to_s) if from_time.class == DateTime
        to_time = Time.parse(to_time.to_s) if to_time.class == DateTime
        dist = to_time - from_time

        minutes = (dist.abs / 60).round
        hours = minutes / 60
        minutes = minutes - (hours * 60)
        
        words = dist <= 0 ? '' : '-'

        words << "#{hours} #{hours > 1 ? 'horas' : 'hora' } " if hours > 0
        words << "#{minutes} #{minutes == 1 ? 'minuto' : 'minutos' }"
    end
    
    def minutos_a_tiempo_en_palabras minutes
        words = ''

        unless minutes.nil?
            hours = (minutes / 60).to_i
            minutes = (minutes - (hours * 60)).round if minutes > 60

            words << "#{hours} #{hours > 1 ? 'horas' : 'hora' } " if hours > 0
            words << "#{minutes} #{minutes == 1 ? 'minuto' : 'minutos' }"
        end
        
        words
    end

    def breadcrumb data_array = []
        str  = '<div class="sectionHeader">'
        str += '<ul class="breadcrumb">'

        data_array.each do |i|
            str += '<li>' 
            if i.is_a? Array
                str += '<a href="' + i[1] + '">' + i[0] + '</a>'
            else
                str += i
            end
            str += '<span class="divider">/</span>' unless i.eql?(data_array.last)
            str += '</li>'
        end

        str += '</ul></div>'
        
        raw str
    end

    def input_readonly value = nil, label = nil
        hsh = input_value value, label
        hsh[:input_html][:readonly] = true
        
        hsh
    end

    def input_value value = nil, label = nil
        hsh = { :input_html => {:value => value} }
        hsh[:label] = label unless label.nil?
        
        hsh
    end

    def jornada_en_palabras jornada
        return  case jornada
                when 1
                    "Diurna"
                when 2
                    "Vespertina"
                when 3
                    "Tarde"
                else
                    "Distancia"
                end
    end
end
