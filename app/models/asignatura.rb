# encoding: utf-8
class Asignatura 
    include DataMapper::Resource
    include DataMapper::Timestamps
    include DataMapper::Historylog

    # TIPOS DE ASIGNATURAS
    OBLIGATORIA = 1
    ELECTIVA    = 2
    CARACTERES  = [
        :OBLIGATORIA,
        :ELECTIVA
    ]

    REGULAR     = 1
    PRACTICA    = 2
    TERMINAL    = 3
    TIPOS       = [:REGULAR, :PRACTICA, :TERMINAL]

    property    :id,                           Serial
    property    :nombre,                       String,  :required => true, :length => 256
    property    :semestre,                     Integer, :required => true, :min => 1
    property    :tipo,                         Integer
    property    :codigo,                       String,  :default => 0
    property    :caracter,                     Integer, :default => self::OBLIGATORIA
    property    :horas_teoricas_semanales,     Integer, :min => 0, :default => 0
    property    :horas_ayudantias_semanales,   Integer, :min => 0, :default => 0
    property    :horas_practicas_semanales,    Integer, :min => 0, :default => 0
    property    :requisitos,                   Integer, :default => 0
    property    :siaa_id,                      Integer
    property    :siaa_updated_at,              DateTime
    property    :siaa_id_sede_sync,            Integer

    timestamps  :at
    property    :deleted_at,                    ParanoidDateTime

    has n,      :links_secciones_dictadas, "SeccionDictada"
    has n,      :secciones, "Seccion", :through => :links_secciones_dictadas, :via => :seccion
    belongs_to  :plan_estudio

    # Para el acceso a las asignaturas pre-requisitos
    has n,      :links_asignaturas_requisitos, "Requisito", :child_key => [:asignatura_dependiente_id]
    has n,      :links_asignaturas_dependientes, "Requisito", :child_key => [:asignatura_requisito_id]
    has n,      :asignaturas_requisitos, self, :through => :links_asignaturas_requisitos, :via => :asignatura_requisito
    has n,      :asignaturas_dependientes, self, :through => :links_asignaturas_dependientes, :via => :asignatura_dependiente

    # Para el acceso a los electivos
    has n,      :link_electivos_dictados, "ElectivoDictado"
    has n,      :electivos, "Electivo", :through => :link_electivos_dictados 


    #def codigo
    #    self[:codigo].blank? ? siaa_id : self[:codigo]
    #end

    def self.buscar_con_secciones_en_periodo(attrs, plan_id, periodo_id)
         all(:fields => attrs,:plan_estudio => {:id => plan_id}, :links_secciones_dictadas => {:seccion => {:periodo => {:id => periodo_id}}})        
    end

    def self.buscar_todas_attrs(attrs)
        all(:fields => attrs)
    end

    def es_electivo?
        self.caracter == Asignatura::ELECTIVA
    end

    def self.abrir_asignaturas_periodo asignaturas, periodo_id, institucion_sede_id 
        tmp = []
            asignaturas.each do |x|

                tmp << { :id_asignatura => x[:id_asignatura].to_i, :secciones_nuevas => x[:secciones_nuevas].to_i - x[:numero_secciones].to_i, :numero_secciones => x[:numero_secciones].to_i }  
            end

        tmp.each do |i|
            n = i[:secciones_nuevas]
            n.times do |t|
                Seccion.transaction do 
                    nueva_seccion = Seccion.create(
                                        :estado => Seccion::ABIERTA, 
                                        :cupos => 40, 
                                        :institucion_sede_id => institucion_sede_id , 
                                        :periodo_id => periodo_id , 
                                        :numero => i[:numero_secciones] + t + 1
                                    )

                    nueva_seccion_dictada = SeccionDictada.create(
                                                :asignatura_id => i[:id_asignatura], 
                                                :seccion_id => nueva_seccion.id
                                            ) 
                end
            end
        end

        return true

    end
    
    #TODO: mejorar metodo
    def self.obtener_todas_por_plan_estudio_y_periodo_map plan_estudio_id, periodo_id, attrs = nil 
        items = []
        
        if attrs.nil? 
            asignaturas = Asignatura.all :plan_estudio_id => plan_estudio_id  
        else 
            asignaturas = Asignatura.all :fields => attrs, :plan_estudio_id => plan_estudio_id
        end

        secciones = Seccion.all(:fields => [:id],  :periodo_id => periodo_id)

        secciones_dictadas = SeccionDictada.all( 
            :fields     => [:asignatura_id, :id], 
            :order      => [:id.asc], 
            :asignatura => asignaturas, 
            :seccion    => secciones, 
            :periodo_id => periodo_id,
            :seccion    => {
                :numero.not => [Seccion::CONVALIDADA_HOMOLOGADA,Seccion::HISTORIAL_ACADEMICO]
            } 
        )
        secciones_dictadas = secciones_dictadas.group_by { |s| s.asignatura_id }

        tmp = []
            secciones_dictadas.each do |i |
                tmp << {:asignatura_id => i[0].to_i, :numero_secciones => i[1].size }
            end
                    
        #TODO:cambiar el titulo profesional por el nombre cuando los datos esten 
        asignaturas = asignaturas.map{|x| {:id_asignatura => x.id,:semestre => x.semestre, :nombre_asignatura => x.nombre, :id_plan_estudio => x.plan_estudio_id}}
        
        asignaturas.each do |i|
            data = tmp.detect {|x| x[:asignatura_id] == i[:id_asignatura] } 
            numero_secciones = data.nil? ? 0 : data[:numero_secciones]
    
            items << {
                        :plan_estudio_id => plan_estudio_id, 
                        :id_asignatura => i[:id_asignatura], 
                        :nombre_asignatura => i[:nombre_asignatura],
                        :numero_secciones => numero_secciones,
                        :semestre => i[:semestre]
                    } 
        end

        items
    end

    def self.validar_asignatura_alumno alumno_id, institucion_origen, asignaturas_origen, asignaturas_destinos, tipo, alumno_plan_estudio_id, periodo_id

        Asignatura.transaction do 
            
            asignaturas_destinos.each do |i|
                asignatura_id = i["asignatura_id"].to_i
                nota_final  = i["nota"].to_f


                institucion_origen  = InstitucionExterna,new
                institucion_origen.nombre = institucion_origen["nombre"]
                institucion_origen.domicilio = institucion_origen["domicilio"]
                institucion_origen.alumno_plan_estudio_id = alumno_plan_estudio_id
                institucion_origen.save


                validacion = ConvalidacionHomologacion.new
                validacion.tipo = tipo
                validacion.periodo_id = periodo_id,
                validacion.carrera_convalidada = institucion_origen["carrera"]
                validacion.save

                seccion = Seccion.new
                seccion.periodo_id = periodo_id
                seccion.cupos = 1
                seccion.estado = 2
                seccion.save

                seccion_dictada = SeccionDictada.new
                seccion_dictada.asignatura_id = asignatura_id 
                seccion_dictada.seccion_id = seccion_id 
                seccion_dictada.save

                alumno_inscrito_seccion = AlumnoInscritoSeccion.new
                alumno_inscrito_seccion.seccion_dictada_id = seccion_dictada.id
                alumno_inscrito_seccion.alumno_plan_estudio_id = alumno_plan_estudio_id
                alumno_inscrito_seccion.nota_final = nota_final
                
                alumno_inscrito_seccion.save

                asignaturas_origen.each do |a|
                    id_asignatura = a["asignatura_id"].to_i
                    
                    if asignatura_id == id_asignatura 
                        nombre_asignatura = a["nombre"]
                        fecha_rendicion   = a["fecha"]
                        nota_aprobacion   = a["nota"]

                        asignatura_origen = AsignaturaInstitucionesExterna.new
                        asignatura_origen.nombre = nombre_asignatura
                        asignatura_origen.fecha  = fecha_rendicion
                        asignatura_origen.nota   =  nota_aprobacion
                        asignatura_origen.seccion_alumno_id = alumno_inscrito_seccion.id
                        asignatura_origen.save

                    end
                end
            end

        end
    end
end
