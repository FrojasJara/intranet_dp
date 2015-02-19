# encoding: utf-8
class PlanEstudio
    include DataMapper::Resource
    include DataMapper::Timestamps
    include DataMapper::Historylog

    PROFESIONAL             = 1
    TECNICO                 = 2
    MENCION                 = 3
    DIPLOMADO               = 4
    SECUNDARIO              = 5
    PREUNIVERSITARIO        = 6
    
    NIVELES                 = [
            :PROFESIONAL, 
            :TECNICO,
            :MENCION,
            :DIPLOMADO,
            :SECUNDARIO,
            :PREUNIVERSITARIO
    ]

    # Estado del plan de estudio
    VIGENTE                         = 1
    NO_VIGENTE                      = 2
    ESTADO                          = [
            :VIGENTE,
            :NO_VIGENTE     
    ]
    
    EDUCACION_PARVULARIA                               = 1
    SERVICIO_SOCIAL                                    = 2
    PLAN_ESPECIAL_CONSTRUCCION_CIVIL                   = 3
    CONSTRUCCION_CIVIL                                 = 4
    CONTADOR_AUDITOR                                   = 5
    ADMINISTRACION_EMPRESAS                            = 6
    INGENIERIA_INFORMATICA                             = 7
    PREVENCION_RIESGOS                                 = 8
    GASTRONOMIA                                        = 9
    GASTRONOMIA_MENCION                                = 10 #INFO: [AV] incluir Cocina Internacional, Pasteleria y hay otra más...
    ENFERMERIA                                         = 11
    TOPOGRAFIA                                         = 12
    ELECTROMECANICA                                    = 13
    CFT_CONSTRUCCION                                   = 14
    CFT_GASTRONOMIA                                    = 15
    CFT_GASTRONOMIA_MENCION                            = 16
    CFT_ASISTENTE_DIFERENCIAL                          = 17
    CEIA_PRIMER_NIVEL                                  = 18
    CEIA_SEGUNDO_NIVEL                                 = 19
    PRE_UNIVERSITARIO                                  = 20
    NUTRICION_DIETETICA                                = 21
    PLAN_ESPECIAL_INGENIERIA_CONSTRUCCION_CIVIL        = 22
    INGENIERIA_EN_GEOMENSURA                           = 23
    TECNICO_JURIDICO                                   = 24
    INGENIERIA_ADMINISTRACION_PUBLICA                  = 25
    DIPLOMADO_ASISTENTE_DE_LA_EDUC_CON_ATENCION_EN_NEE = 26

    MALLAS_SELECT = [
        {id: EDUCACION_PARVULARIA, name: 'Educación Parvularia', institucion_id: Institucion::IP},
        {id: SERVICIO_SOCIAL, name: 'Servicio Social', institucion_id: Institucion::IP},
        {id: PLAN_ESPECIAL_CONSTRUCCION_CIVIL, name: 'P/E Construcción Civil', institucion_id: Institucion::IP},
        {id: CONSTRUCCION_CIVIL, name: 'Construcción Civil', institucion_id: Institucion::IP},
        {id: CONTADOR_AUDITOR, name: 'Contador Auditor', institucion_id: Institucion::IP},
        {id: ADMINISTRACION_EMPRESAS, name: 'Administración Empresas', institucion_id: Institucion::IP},
        {id: INGENIERIA_INFORMATICA, name: 'Ingeniería Informática', institucion_id: Institucion::IP},
        {id: PREVENCION_RIESGOS, name: 'Prevención de Riesgos', institucion_id: Institucion::IP},
        {id: GASTRONOMIA, name: 'Gastronomía', institucion_id: Institucion::IP},
        {id: GASTRONOMIA_MENCION, name: 'Gastronomía Mención', institucion_id: Institucion::IP},
        {id: ENFERMERIA, name: 'Enfermería', institucion_id: Institucion::IP},
        {id: TOPOGRAFIA, name: 'Topografía', institucion_id: Institucion::IP},
        {id: ELECTROMECANICA, name: 'Electromecánica', institucion_id: Institucion::IP},
        {id: CFT_CONSTRUCCION, name: 'CFT Construcción', institucion_id: Institucion::CFT},
        {id: CFT_GASTRONOMIA, name: 'CFT Gastronomía', institucion_id: Institucion::CFT},
        {id: CFT_GASTRONOMIA_MENCION, name: 'CFT Gastronomía Mención', institucion_id: Institucion::CFT},
        {id: CFT_ASISTENTE_DIFERENCIAL, name: 'CFT Asistente Diferencial', institucion_id: Institucion::CFT},
        {id: CEIA_PRIMER_NIVEL, name: 'CEIA Primer Nivel', institucion_id: Institucion::CEIA},
        {id: CEIA_SEGUNDO_NIVEL, name: 'CEIA Segundo Nivel', institucion_id: Institucion::CEIA},
        {id: PRE_UNIVERSITARIO, name: 'Preuniversitario', institucion_id: Institucion::PREU},
        {id: NUTRICION_DIETETICA, name: 'Nutrición y Dietética', institucion_id: Institucion::IP},
        {id: PLAN_ESPECIAL_INGENIERIA_CONSTRUCCION_CIVIL, name: 'Plan Especial Ingenieria en Construccion 2013', institucion_id: Institucion::IP},
        {id: INGENIERIA_EN_GEOMENSURA, name: 'Ingeniría en Geomensura', institucion_id: Institucion::IP},
        {id: TECNICO_JURIDICO, name: 'Tecnico Juridico', institucion_id: Institucion::IP},
        {id: INGENIERIA_ADMINISTRACION_PUBLICA, name: 'Administración Pública', institucion_id: Institucion::IP},
        {id: DIPLOMADO_ASISTENTE_DE_LA_EDUC_CON_ATENCION_EN_NEE, name: 'Diplomado Asistente de la Educ. con Atención en N.E.E', institucion_id: Institucion::OTEC}
    ]

=begin
    # Matriculas Profesionales
    PROFESIONAL_UN_SEMESTRE = 1 
    PROFESIONAL_DOS_SEMESTRES = 2
    TERMINAL = 3
    SALIDA_INTERMEDIA = 4
    # Matriculas Tecnicas
    PRACTICA_TRABAJO_DE_TITULO = 5
    TECNICA_UN_SEMESTRE = 6
    TECNICA_DOS_SEMESTRES = 7
    # Matriculas Distancia
    DISTANCIA_1_A_4_NIVEL = 8
    DISTANCIA_5_A_8_NIVEL = 9
    DISTANCIA_SALIDA_INTERMEDIA_EXENTA = 10
    DISTANCIA_SALIDA_INTERMEDIA_SEMI_EXENTA = 11
    DISTANCIA_SALIDA_INTERMEDIA_COMPLETA = 12 
    DISTANCIA_TERMINAL_EXENTA = 13
    DISTANCIA_TERMINAL_SEMI_EXENTA = 14
    DISTANCIA_TERMINAL_COMPLETA = 15
    # Matriculas Preu y CEIA
    CEIA_DOS_SEMESTRES = 16
    PREU_DOS_SEMESTRES = 17
    # Continuidad y otros
    CONTINUIDA_EXENTA = 18
    OTEC_UN_SEMESTRE = 19
=end

    PRECIOS_HASH = {
        :EDUCACION_PARVULARIA                               => {:PRECIO_MATRICULA => 120000,:PRECIO_NORMAL => 850000, :PRECIO_CONTADO => 640000, :tipo => "profesional"}, 
        :SERVICIO_SOCIAL                                    => {:PRECIO_MATRICULA => 120000,:PRECIO_NORMAL => 800000, :PRECIO_CONTADO => 600000,:tipo => "profesional", :PRECIO_MAT_DISTANCIA => 40000, :PRECIO_1RO => 740000, :PRECIO_5TO => 740000},
        :PLAN_ESPECIAL_CONSTRUCCION_CIVIL                   => {:PRECIO_MATRICULA => 120000,:PRECIO_NORMAL => 850000, :PRECIO_CONTADO => 640000, :tipo => "profesional"},
        :CONSTRUCCION_CIVIL                                 => {:PRECIO_MATRICULA => 120000,:PRECIO_NORMAL => 850000, :PRECIO_CONTADO => 640000, :tipo => "profesional"},
        :CONTADOR_AUDITOR                                   => {:PRECIO_MATRICULA => 85000,:PRECIO_NORMAL => 750000, :PRECIO_CONTADO => 565000, :tipo => "salida_intermedia",:PRECIO_MAT_DISTANCIA => 40000, :PRECIO_1RO => 520000, :PRECIO_5TO => 740000, :PRECIO_NORMAL_PRAC_SALIDA => 500000,  :PRECIO_PRAC_CONTADO_SALIDA => 400000},
        :ADMINISTRACION_EMPRESAS                            => {:PRECIO_MATRICULA => 85000,:PRECIO_NORMAL => 750000, :PRECIO_CONTADO => 565000, :tipo => "salida_intermedia", :PRECIO_MAT_DISTANCIA => 40000, :PRECIO_1RO => 520000, :PRECIO_5TO => 740000, :PRECIO_NORMAL_PRAC_SALIDA => 500000,  :PRECIO_PRAC_CONTADO_SALIDA => 400000},
        :INGENIERIA_INFORMATICA                             => {:PRECIO_MATRICULA => 85000,:PRECIO_NORMAL => 750000, :PRECIO_CONTADO => 565000, :tipo => "salida_intermedia", :PRECIO_NORMAL_PRAC_SALIDA => 500000,  :PRECIO_PRAC_CONTADO_SALIDA => 400000},
        :PREVENCION_RIESGOS                                 => {:PRECIO_MATRICULA => 85000,:PRECIO_NORMAL => 750000, :PRECIO_CONTADO => 565000, :tipo => "salida_intermedia", :PRECIO_MAT_DISTANCIA => 40000, :PRECIO_1RO => 520000, :PRECIO_5TO => 740000, :PRECIO_NORMAL_PRAC_SALIDA => 500000,  :PRECIO_PRAC_CONTADO_SALIDA => 400000},
        :GASTRONOMIA                                        => {:PRECIO_MATRICULA => 85000,:PRECIO_NORMAL => 880000, :PRECIO_CONTADO => 680000, :tipo => "tecnico", :PRECIO_NORMAL_PRAC_TECNICO => 500000,  :PRECIO_CONTADO_PRAC_TECNICO => 400000},
        :GASTRONOMIA_MENCION                                => {:PRECIO_MATRICULA => 90000,:PRECIO_NORMAL => 940000, :PRECIO_CONTADO => 715000, :tipo => "tecnico", :PRECIO_NORMAL_PRAC_TECNICO => 540000,  :PRECIO_CONTADO_PRAC_TECNICO => 432000},
        :ENFERMERIA                                         => {:PRECIO_MATRICULA => 85000,:PRECIO_NORMAL => 880000, :PRECIO_CONTADO => 680000, :tipo => "tecnico", :PRECIO_NORMAL_PRAC_TECNICO => 500000,  :PRECIO_CONTADO_PRAC_TECNICO => 400000},
        :TOPOGRAFIA                                         => {:PRECIO_MATRICULA => 85000,:PRECIO_NORMAL => 750000, :PRECIO_CONTADO => 565000, :tipo => "tecnico", :PRECIO_NORMAL_PRAC_TECNICO => 500000,  :PRECIO_CONTADO_PRAC_TECNICO => 400000},
        :ELECTROMECANICA                                    => {:PRECIO_MATRICULA => 85000,:PRECIO_NORMAL => 1, :PRECIO_CONTADO => 1, :tipo => "tecnico", :PRECIO_NORMAL_PRAC_TECNICO => 500000,  :PRECIO_CONTADO_PRAC_TECNICO => 400000},
        :CFT_CONSTRUCCION                                   => {:PRECIO_MATRICULA => 85000,:PRECIO_NORMAL => 750000, :PRECIO_CONTADO => 565000, :tipo => "cft", :PRECIO_NORMAL_PRAC_CFT => 500000,  :PRECIO_CONTADO_PRAC_CFT => 400000},
        :CFT_GASTRONOMIA                                    => {:PRECIO_MATRICULA => 85000,:PRECIO_NORMAL => 880000, :PRECIO_CONTADO => 680000, :tipo => "cft", :PRECIO_NORMAL_PRAC_CFT => 500000,  :PRECIO_CONTADO_PRAC_CFT => 400000},
        :CFT_GASTRONOMIA_MENCION                            => {:PRECIO_MATRICULA => 85000,:PRECIO_NORMAL => 880000, :PRECIO_CONTADO => 680000, :tipo => "cft", :PRECIO_NORMAL_PRAC_CFT => 500000,  :PRECIO_CONTADO_PRAC_CFT => 400000},
        :CFT_ASISTENTE_DIFERENCIAL                          => {:PRECIO_MATRICULA => 85000,:PRECIO_NORMAL => 1, :PRECIO_CONTADO => 1, :tipo => "cft", :PRECIO_NORMAL_PRAC_CFT => 500000,  :PRECIO_CONTADO_PRAC_CFT => 400000},
        :NUTRICION_DIETETICA                                => {:PRECIO_MATRICULA => 120000,:PRECIO_NORMAL => 800000, :PRECIO_CONTADO => 600000, :tipo => "profesional"},
        :PLAN_ESPECIAL_INGENIERIA_CONSTRUCCION_CIVIL        => {:PRECIO_MATRICULA => 100000,:PRECIO_NORMAL => 1000000, :PRECIO_CONTADO => 1000000, :tipo => "profesional"},
        :INGENIERIA_EN_GEOMENSURA                           => {:PRECIO_MATRICULA => 125000,:PRECIO_NORMAL => 1000000, :PRECIO_CONTADO => 750000, :tipo => "profesional"},
        :TECNICO_JURIDICO                                   => {:PRECIO_MATRICULA => 45000,:PRECIO_NORMAL => 580000, :PRECIO_CONTADO => 580000, :tipo => "profesional"},
        :INGENIERIA_ADMINISTRACION_PUBLICA                  => {:PRECIO_MATRICULA => 45000,:PRECIO_NORMAL => 580000, :PRECIO_CONTADO => 580000, :tipo => "profesional"}
    }

    MALLAS_HASH = {
        :EDUCACION_PARVULARIA                           => [15,16,90,106,144,160,164,183,200,203,205,229,230,231,275,387,391], 
        :SERVICIO_SOCIAL                                => [72,73,103,154,174,194,263,265,273,288,298,308,310,327,358,359,364,233,248,362,404],
        :PLAN_ESPECIAL_CONSTRUCCION_CIVIL               => [2,123,142,162,170,280,281,345,347],
        :CONSTRUCCION_CIVIL                             => [69,70,71,104,150,181, 189,446,219],
        :CONTADOR_AUDITOR                               => [5,41,77,78,105,117,135,143,152,163,172,182,191,213,249,253,283,290,293,301,304,314,316,320,321,326,343,344,385,213,215,217,350,351,394,398,367],
        :ADMINISTRACION_EMPRESAS                        => [3,10,12,13,35,76,89,96,101,102,121,128,130,131,141,155,157,159,161,175,177,179,180,195,197,199,201,212,250,252,254,255,257,261,267,268,270,272,302,305,311,312,313,319,323,363,365,371,386,407,416,417,216,218,349,396,399],
        :INGENIERIA_INFORMATICA                         => [1,4,68,108,119,146,153,166,173,185,193,223,224,225,226,227,228,251,282,284,287,296,299,306,315,317,341,357,368,410,447],
        :PREVENCION_RIESGOS                             => [8,24,29,36,58,74,110,124,127,148,156,168,176,187,196,235,236,237,238,239,240,241,242,256,258,259,266,289,292,294,295,297,300,303,307,309,318,322,355,360,361,388,402,403,411,432,234,247,335,346,348,352,353,354,356,395,397,401,403,405,406],                
        :GASTRONOMIA                                    => [21,26,33,57,81,98,118,243,244,286,291,325,332,333,336,370,381,383,384,418,419,420,421,429,430],
        :GASTRONOMIA_MENCION                            => [97,214,245,246,262,392,393,435,460],
        :ENFERMERIA                                     => [413,414],
        :TOPOGRAFIA                                     => [14,25,27,75,126,222,400],
        :ELECTROMECANICA                                => [20,65,116,277,324,339,342],
        :CFT_CONSTRUCCION                               => [17,66,101,111,279,285,340,380,415],
        :CFT_GASTRONOMIA                                => [],
        :CFT_GASTRONOMIA_MENCION                        => [],
        :CFT_ASISTENTE_DIFERENCIAL                      => [19,114,274,337],
        :CEIA_PRIMER_NIVEL                              => [448],
        :CEIA_SEGUNDO_NIVEL                             => [449],
        :NUTRICION_DIETETICA                            => [330,444],
        :PLAN_ESPECIAL_INGENIERIA_CONSTRUCCION_CIVIL    => [463,232],
        :INGENIERIA_EN_GEOMENSURA                       => [466],
        :TECNICO_JURIDICO                               => [374,412],
        :INGENIERIA_ADMINISTRACION_PUBLICA              => [464,467]
    }  

    MALLAS_N_HASH = {
        EDUCACION_PARVULARIA                            => MALLAS_HASH[:EDUCACION_PARVULARIA],
        SERVICIO_SOCIAL                                 => MALLAS_HASH[:SERVICIO_SOCIAL],
        PLAN_ESPECIAL_CONSTRUCCION_CIVIL                => MALLAS_HASH[:PLAN_ESPECIAL_CONSTRUCCION_CIVIL],
        CONSTRUCCION_CIVIL                              => MALLAS_HASH[:CONSTRUCCION_CIVIL],
        CONTADOR_AUDITOR                                => MALLAS_HASH[:CONTADOR_AUDITOR],
        ADMINISTRACION_EMPRESAS                         => MALLAS_HASH[:ADMINISTRACION_EMPRESAS],
        INGENIERIA_INFORMATICA                          => MALLAS_HASH[:INGENIERIA_INFORMATICA],
        PREVENCION_RIESGOS                              => MALLAS_HASH[:PREVENCION_RIESGOS],
        GASTRONOMIA                                     => MALLAS_HASH[:GASTRONOMIA],
        GASTRONOMIA_MENCION                             => MALLAS_HASH[:GASTRONOMIA_MENCION],
        ENFERMERIA                                      => MALLAS_HASH[:ENFERMERIA],
        TOPOGRAFIA                                      => MALLAS_HASH[:TOPOGRAFIA],
        ELECTROMECANICA                                 => MALLAS_HASH[:ELECTROMECANICA],
        CFT_CONSTRUCCION                                => MALLAS_HASH[:CFT_CONSTRUCCION],
        CFT_GASTRONOMIA                                 => MALLAS_HASH[:CFT_GASTRONOMIA],
        CFT_GASTRONOMIA_MENCION                         => MALLAS_HASH[:CFT_GASTRONOMIA_MENCION],
        CFT_ASISTENTE_DIFERENCIAL                       => MALLAS_HASH[:CFT_ASISTENTE_DIFERENCIAL],
        CEIA_PRIMER_NIVEL                               => MALLAS_HASH[:CEIA_PRIMER_NIVEL],
        CEIA_SEGUNDO_NIVEL                              => MALLAS_HASH[:CEIA_SEGUNDO_NIVEL],
        NUTRICION_DIETETICA                             => MALLAS_HASH[:NUTRICION_DIETETICA],
        PLAN_ESPECIAL_INGENIERIA_CONSTRUCCION_CIVIL     => MALLAS_HASH[:PLAN_ESPECIAL_INGENIERIA_CONSTRUCCION_CIVIL],
        INGENIERIA_EN_GEOMENSURA                        => MALLAS_HASH[:INGENIERIA_EN_GEOMENSURA],
        TECNICO_JURIDICO                                => MALLAS_HASH[:TECNICO_JURIDICO],
        INGENIERIA_ADMINISTRACION_PUBLICA               => MALLAS_HASH[:INGENIERIA_ADMINISTRACION_PUBLICA]
    }  

    MALLAS_HASH_PRESENCIALES = {
        EDUCACION_PARVULARIA               => [15,16,90,106,144,160,164,183,200,203,205,229,230,231,275,387,391],
        SERVICIO_SOCIAL                    => [73,103,154,174,194,263,265,273,288,298,308,310,327,358,359,364]
    } 

    MALLAS_PROFESIONALES = [:EDUCACION_PARVULARIA, :SERVICIO_SOCIAL, :PLAN_ESPECIAL_CONSTRUCCION_CIVIL, 
                                                    :CONSTRUCCION_CIVIL, :CONTADOR_AUDITOR, :ADMINISTRACION_EMPRESAS, :INGENIERIA_INFORMATICA,
                                                    :PREVENCION_RIESGOS, :NUTRICION_DIETETICA, :PLAN_ESPECIAL_INGENIERIA_CONSTRUCCION_CIVIL,
                                                    :INGENIERIA_EN_GEOMENSURA, :TECNICO_JURIDICO]
    
    MALLAS_TECNICAS = [:GASTRONOMIA, :CFT_GASTRONOMIA, :ENFERMERIA, :TOPOGRAFIA, :ELECTROMECANICA, :CFT_CONSTRUCCION, :CFT_ASISTENTE_DIFERENCIAL,
                                                    :INGENIERIA_EN_GEOMENSURA]
    
    MALLAS_MENCIONES = [:GASTRONOMIA_MENCION, :CFT_GASTRONOMIA_MENCION]
   
    # Ejemplos: Para obtener los id de plan_estudio de Educación Parvularia:
    # => PlanEstudio::MALLAS_HASH[PlanEstudio::EDUCACION_PARVULARIA]
    # Si quiero saber a que pertenece mi plan de estudio
    # => 
    
    property        :id,                                    Serial
    property        :nombre,                                String,         :length => 256
    property        :nivel,                                 Integer
    property        :tiene_salida_intermedia,               Boolean,        :default => false
    property        :duracion,                              Integer
    property        :titulo_profesional,                    String,         :length => 256
    property        :titulo_tecnico,                        String,         :length => 256
    property        :certificado,                           String,         :length => 256
    property        :licenciatura,                          String,         :length => 256
    property        :revision,                              String,         length: 256
    property        :semestre_inicio,                       Integer
    property        :anio_inicio,                           Integer
    property        :semestre_fin,                          Integer
    property        :anio_fin,                              Integer
    property        :certificado,                           String
    property        :url_malla,                             String,        :length => 256
    
    # [JM] Para el CEIA y PREU
    property        :certificado,                           String,         :length => 256
    property        :estado,                                Integer,        :default => PlanEstudio::VIGENTE
    property        :maximo_asignaturas,                    Integer
    property        :resolucion_salida_intermedia,          String,         :length => 256

    property        :siaa_id_ma,                            Integer
    property        :siaa_id_ca,                            Integer
    property        :siaa_id_ca_concepcion,                 Integer
    property        :siaa_id_ca_chillan,                    Integer
    property        :siaa_id_ca_nunoa,                      Integer
    property        :siaa_id_ca_bosque,                     Integer
    property        :siaa_id_ca_vina,                       Integer
    property        :siaa_updated_at,                       DateTime
    property        :siaa_id_sede_sync,                     Integer
    
    timestamps      :at
    property        :deleted_at,                            ParanoidDateTime
    
    belongs_to      :planes_requisitos, "PlanEstudio", :child_key   => "plan_requisito_id", :required => false
    belongs_to      :escuela, required: false # [AV] Quitar post-sync
    belongs_to      :carrera, required: false
    
    has n,          :institucion_sede_plan
    has n,          :asignaturas
    has n,          :planes_dependientes, "PlanEstudio", :child_key => "plan_requisito_id"
    has n,          :coordinadores, "Coordinador"
    
    def self.obtener_todos estado = nil, attrs = {}
        attrs[:fields] = %w[id titulo_profesional] 
                
        if estado.nil?
                planes_estudios = PlanEstudio.all(:fields => attrs[:fields], :order => [:titulo_profesional.asc])
        else 
                planes_estudios = PlanEstudio.all(:fields => attrs[:fields], :estado => estado, :order => [:titulo_profesional.asc])
        end 
        planes_estudios
                                        
    end

    def nombre_completo
        "#{nombre} [#{anio_inicio} #{anio_fin}] #{revision}"
    end

    def self.buscar_malla plan_estudio_id
        MALLAS_HASH.each do |key, value|
                return self.const_get(key) if value.include?(plan_estudio_id)
        end

        return nil
    end

    def self.buscar_nivel_malla plan_estudio_id, semestres
        carrera = nil
        
        MALLAS_HASH.each do |key, value|
            carrera = key if value.include?(plan_estudio_id)
        end
        
        if MALLAS_PROFESIONALES.include?( carrera )||MALLAS_MENCIONES.include?( carrera )
            return semestres == 1 ? MatriculaPlan::PROFESIONAL_UN_SEMESTRE : MatriculaPlan::PROFESIONAL_DOS_SEMESTRES
        end
        
        if MALLAS_TECNICAS.include? carrera
            return semestres == 1 ? MatriculaPlan::TECNICA_UN_SEMESTRE : MatriculaPlan::TECNICA_DOS_SEMESTRES
        end 
    end

    def self.nombre_item_malla malla_id
        p = (PlanEstudio::MALLAS_SELECT).select{|x|x[:id] == malla_id.to_i}.first
        p.blank? ? 'Sin registro' : p[:name]
    end
end