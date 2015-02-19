# encoding: utf-8
class Usuario
    include DataMapper::Resource
    include DataMapper::Timestamps
    include DataMapper::Historylog
    include DataMapper::Utils

    #ROL 10 ES EXCLUSIVO DEL VICERRECTOR (uno por sede) SINO PRODUCE CONFLICTO CON CERTIFICADOS 

    # TIPOS DE ALUMNO
    ESTUDIANTE              = 1
    APODERADO               = 2
    ADMINISTRATIVO          = 3
    DOCENTE                 = 4
    TIPOS                   = [:ESTUDIANTE, :APODERADO, :ADMINISTRATIVO, :DOCENTE]
    
    # ESTADOS CIVILES
    SOLTERO                 = 1
    CASADO                  = 2
    VIUDO                   = 3
    DIVORCIADO              = 4
    SEPARADO                = 5
    ESTADOS_CIVILES         = [:SOLTERO, :CASADO, :VIUDO, :DIVORCIADO, :SEPARADO]
    
    # SEXO
    MASCULINO               = 1
    FEMENINO                = 2
    SEXOS                   = [:MASCULINO, :FEMENINO]

    property    :id,                    Serial  

    property    :rut,                   String, :unique => true#, :required => true, :format => /\d{7,8}-(k|K|\d)$/, :length => 9..10

    property    :email,                 String, :format => :email_address#, :length => 32
    property    :password,              String, :required => true, :length => 225
    property    :primer_nombre,         String, length: 25#, :required => true, :length => 25
    property    :segundo_nombre,        String, :length => 25 #required [AV] (Creo que no es necesario...)
    property    :apellido_paterno,      String, length: 25#, :required => true, :length => 25
    property    :apellido_materno,      String, :length => 25 #required [AV] (Creo que no es necesario...)
    property    :fecha_nacimiento,      Date
    property    :estado_civil,          Integer
    property    :sexo,                  Integer
    property    :domicilio,             String, :required => true, :length => 255
    property    :villa_poblacion,       String, :length => 255
    property    :sector,                String, :length => 255

    property    :codigo_area_telefono,  String, :length => 3
    property    :telefono_fijo,         String, :length => 40
    property    :telefono_movil,        String, :length => 200
    property    :profesion,             String

    # PRE CAMBIOS IMPORTACIÓN [AV]
    # property    :codigo_area_telefono,  String, :required => true, :length => 2..2
    # property    :telefono_fijo,         String, :required => true, :length => 5..8
    # property    :telefono_movil,        String, :required => true, :length => 8..8
    # END

    property    :tipo,                  Integer, :required => true
    property    :siaa_id,               Integer
    property    :siaa_updated_at,       DateTime
    property    :siaa_trans_date,       DateTime



    timestamps  :at
    property    :deleted_at,            ParanoidDateTime

    has 1,      :alumno
    has 1,      :docente
    has 1,      :apoderado
    has 1,      :director_escuela
    has 1,      :ejecutivo_matriculas
    
    has n,      :coordinador_carreras,  "Coordinador"
    has n,      :egresados,             "Egresado"
    
    belongs_to  :region
    belongs_to  :comuna
    belongs_to  :pais
    
    belongs_to  :rol,               required: false
    belongs_to  :sede,              required: false

    # DEPLOY
    #belongs_to :institucion_sede #Sacar...
    def nombre
        "#{apellido_paterno.mb_chars.capitalize if apellido_paterno} #{apellido_materno.mb_chars.capitalize if apellido_materno} #{primer_nombre.mb_chars.capitalize if primer_nombre} #{segundo_nombre.mb_chars.capitalize if segundo_nombre}"
    end
    def nombre_1
        "#{primer_nombre.mb_chars.capitalize if primer_nombre} #{segundo_nombre.mb_chars.capitalize if segundo_nombre} #{apellido_paterno.mb_chars.capitalize if apellido_paterno} #{apellido_materno.mb_chars.capitalize if apellido_materno}" 
    end
    def nombre_2
        "#{primer_nombre.mb_chars.upcase if primer_nombre} #{segundo_nombre.mb_chars.upcase if segundo_nombre} #{apellido_paterno.mb_chars.upcase if apellido_paterno} #{apellido_materno.mb_chars.upcase if apellido_materno}"
    end
    def nombres
        "#{primer_nombre.mb_chars.capitalize if primer_nombre} #{segundo_nombre.mb_chars.capitalize if segundo_nombre}"
    end

    def apellidos
        "#{apellido_paterno.mb_chars.capitalize if apellido_paterno} #{apellido_materno.mb_chars.capitalize if apellido_materno}"
    end

    def nombre_corto
       "#{primer_nombre.mb_chars.capitalize if primer_nombre} #{apellido_paterno.mb_chars.capitalize if apellido_paterno}" 
    end

    def iniciales
        primer_nombre.downcase.first << apellido_paterno.downcase
    end
    
    def domicilio_completo
        "#{domicilio} #{', ' + villa_poblacion unless villa_poblacion.blank?}"
    end

    def telefono_fijo_completo
        "(#{codigo_area_telefono}) #{telefono_fijo}" unless telefono_fijo.blank?
    end

    def rut_humanizado
        rut.insert(-6, ".").insert(-10, ".")
    end

    def self.login(rut, password)
        user1 = Usuario.first :rut => rut
        user2 = Usuario.first :rut => rut.gsub("K", "k")
        
        if user1 && user1[:password] == Digest::MD5.hexdigest(password)
            return user1.attributes  
        elsif user2 && user2[:password] == Digest::MD5.hexdigest(password)
            return user2.attributes   
        else
            return false
        end

        #  user = Usuario.first :rut => rut
        
        # if user && user[:password] == Digest::MD5.hexdigest(password)
        #     user.attributes  
        # else
        #     false
        # end
    end

    # => Recibe un arreglo
    def self.constant_name(const , value)
       self.class_eval{ const_get(const) }[value - 1].to_s.capitalize
    end

    def self.docentes(attrs1, attrs2)
        self.all(:fields => attrs1,  :docente => Docente.all(:fields => attrs2))      
    end

end
