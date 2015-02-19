# coding: utf-8
class ModelosAntiguos::Persona 

    include DataMapper::Resource

    def self.default_repository_name
        :db_antigua 
    end

    storage_names[:db_antigua] = 'personas'

    property :rut_pe,               Serial
    property :digito_pe,            String, :length => 1
    property :nombre_pe,            String, :length => 60
    property :apellido_pe,          String, :length => 60
    property :fono_pe,              String, :length => 60
    property :email_pe,             String, :length => 60
    property :username_pe,          String, :length => 60
    property :password_pe,          String, :length => 60
    property :masculino_pe,         Boolean
    property :fh_nacimiento_pe,     String
    property :domicilio_pe,         String, :length => 60
    property :sector_pe,            String, :length => 60
    property :postal_pe,            Integer
    property :observacion_pe,       String, :length => 60
    property :foto_pe,              Boolean
    property :inf_mail_pe,          Boolean
    property :id_ec,                Integer
    property :id_ps,                Integer
    property :id_cm,                Integer
    property :id_dn,                Integer
    property :user_pe,              String, :length => 60
    property :ip_pe,                String, :length => 60
    property :fh_trans_pe,          String
    property :ano_matricula_pe,     Integer
    property :carrera_pe,           Integer
    property :estatura_pe,          Integer
    property :peso_pe,              Integer
    property :celular_pe,           String, :length => 60
    property :id_cl,                Integer
    property :l_media_pe,           Boolean
    property :c_nacimiento_pe,      Boolean
    property :i_social_pe,          Boolean
    property :copia_titulo_pe,      Boolean
    property :id_me,                Integer

    has n, :matriculas_alumno, "ModelosAntiguos::Matricula", :parent_key => "rut_pe", :child_key => "rut_al"

    def parsear_sexo
        if self.masculino_pe
            return Usuario::MASCULINO
        else
            return Usuario::FEMENINO
        end
    end

    def parsear_rut
        rut = self.rut_pe.to_s
        rut = rut + "-" + self.digito_pe
        rut.gsub(" ", "")
    end

    def parsear_nombres
        self.nombre_pe.unpack("C*").pack("U*").downcase.titleize.split
    end

    def parsear_apellidos
        self.apellido_pe.unpack("C*").pack("U*").downcase.titleize.split
    end

    def domicilio
        self.domicilio_pe.unpack("C*").pack("U*").titleize
    end

    def sector
        begin
            return self.sector_pe.nil? ? nil : self.sector_pe.unpack("C*").pack("U*").titleize 
        rescue
            return nil
        end
    end

    def fecha_transaccion
        self.fh_trans_pe.nil? ? DateTime.now : self.fh_trans_pe.split(".").first.to_datetime
    end
    def fecha_transaccion_str
        I18n.l(self.fecha_transaccion, format: :mini)
    end
    def obtener_tipo
        if self.matriculas.first.ano_ma == 2012
            return Alumno::NUEVO
        else
            return Alumno::SUPERIOR
        end
    end

    def obtener_anio_ingreso
        return self.matriculas.first.ano_ma
    end

    has n, :matriculas, "ModelosAntiguos::Matricula", :parent_key => "rut_pe", :child_key => "rut_al", :order => [:ano_ma.asc]
    has n, :apoderados, "ModelosAntiguos::Persona", :through => :matriculas, :via => :apoderado
    has n, :situaciones_alumno, "ModelosAntiguos::SituacionAlumno", :parent_key => "rut_pe", :child_key => "rut_al"
    belongs_to :comuna, "ModelosAntiguos::Comuna", :parent_key => "id_cm", :child_key => "id_cm"
    #has n, :profesor_asignatura, 'ModelosAntiguos::ProfesorAsignatura', parent_key: 'rut_pra', child_key: 'rut_pe'

    def self.planilla

        ModelosAntiguos::Planilla::IP_RUT_CHILLAN.each do |i| 
        #ModelosAntiguos::Matricula.all(:ano_ma => 2012, :sem_ma => 1).alumno.all.each do |a|
            a = ModelosAntiguos::Persona.get(i)
            agregar = true
           # matricula = a.matriculas(:ano_ma => 2012).last
            
            matricula = a.matriculas.last

            if matricula.nil?

                puts "#{a.rut_pe}\t#{a.nombre_pe}\t#{a.apellido_pe}\tBUSCAR CARRERA DESDE EXCEL"    

            else
                carrera = matricula.carrera 

                if carrera.nil?
                    puts "Para #{a.rut_pe} no hay carrera, matriculas: #{matriculas.inspect}"
                end
                #agregar = false if [100, 102].include?(carrera.id_ca)


                if agregar
                    data = {:rut => a.rut_pe , :carrera => carrera.nombre_ca, :carrera_id => carrera.id_ca , :nombre => a.nombre_pe, :apellido => a.apellido_pe }

                    #ModelosAntiguos::SituacionAlumno.all(:rut_al => a.rut_pe, :ano_sa => 2012, :id_ca => matricula.id_ca).each do |s|
                        #agregar = false if [3, 8, 15, 24, 26, 29, 32].include?(s.id_si)
                    #end


                    data[:carrera_min] = ModelosAntiguos::Planilla.busca(ModelosAntiguos::Planilla::IP_CHILLAN, carrera.nombre_ca, matricula.id_jo) 

                    puts "#{data[:rut]}\t#{data[:apellido]}\t#{data[:nombre]}\t#{data[:carrera_min]}\t#{data[:carrera]}\t#{data[:carrera_id]}\t#{matricula.id_jo}"    
                end
            end
            
        end
        # ORDENANDO
        
    end

    def self.migrar
        ModelosAntiguos::Matricula.all(:ano_ma => 2012).alumno.all.each do |item_alumno|
            nombres = item_alumno.parsear_nombres
            apellidos = item_alumno.parsear_apellidos
            rut = item_alumno.rut_pe.to_s + item_alumno.digito_pe

            # El usuario alumno -> Tabla 'Usuarios'
            usuario_alumno = Usuario.new(
                :rut                => rut,
                :password           => Digest::MD5.hexdigest(rut),
                :email              => item_alumno.email_pe,
                :primer_nombre      => nombres[0],
                :segundo_nombre     => nombres[1],
                :apellido_paterno   => apellidos[0],
                :apellido_materno   => apellidos[1],
                :fecha_nacimiento   => item_alumno.fh_nacimiento_pe,
                :sexo               => item_alumno.parsear_sexo,
                :domicilio          => item_alumno.domicilio_pe.titleize,
                :villa_poblacion    => item_alumno.sector_pe.titleize,
                :telefono_fijo      => item_alumno.fono_pe,
                :telefono_movil     => item_alumno.celular_pe,
                :tipo               => Usuario::ESTUDIANTE,
                :pais_id            => 1,
                :region_id          => 1,
                :comuna_id          => 1
            )
            if usuario_alumno.save
                puts "... USUARIO_ALUMNO guardado " + usuario_alumno.rut
            else
                # Si no se guarda, ha sido por que anteriormente el usuario
                # fue registrado como apoderado
                if not usuario_alumno.errors.on(:rut).nil?
                    puts "... USUARIO_ALUMNO ya guardado! " + usuario_alumno.rut
                    usuario_alumno = Usuario.first :rut => usuario_alumno.rut
                    usuario_alumno.tipo = Usuario::ESTUDIANTE
                    if usuario_alumno.save
                        puts "...... USUARIO_ALUMNO actualizado! " + usuario_alumno.rut
                    else
                        puts usuario_alumno.errors.inspect
                        raise RuntimeError, 'ERROR AL ALMACENAR EL USUARIO ALUMNO/APODERADO'
                    end
                else
                    puts usuario_alumno.errors.inspect
                    raise RuntimeError, 'ERROR AL ALMACENAR EL USUARIO ALUMNO'
                end                
            end

            # El alumno como tal -> Tabla 'Alumno'
            alumno = Alumno.new(
                :usuario_id     => usuario_alumno.id,
                :tipo           => item_alumno.obtener_tipo,
                :anio_ingreso   => item_alumno.obtener_anio_ingreso,
                :estado         => Alumno::REGULAR
            )
            if alumno.save
                puts "...... ALUMNO guardado " + usuario_alumno.rut               
            else
                puts alumno.errors.inspect
                raise RuntimeError, 'ERROR AL ALMACENAR EL ALUMNO'                
            end

            item_alumno.matriculas(:ano_ma => 2012).each do |item_matricula|
                # Solo se guarda si el alumno no es su propio apoderado
                if item_matricula.rut_al.to_s != item_matricula.rut_ap
                    item_apoderado = ModelosAntiguos::Persona.get(item_matricula.rut_ap.to_i)

                    # Solo si el apoderado existe
                    if not item_apoderado.nil?
                        nombres = item_apoderado.parsear_nombres
                        apellidos = item_apoderado.parsear_apellidos
                        rut = item_apoderado.rut_pe.to_s + item_apoderado.digito_pe
                        # El usuario apoderado -> Tabla 'Usuarios'
                        usuario_apoderado = Usuario.new(
                            :rut                => rut,
                            :password           => Digest::MD5.hexdigest(rut),
                            :email              => item_apoderado.email_pe,
                            :primer_nombre      => nombres[0],
                            :segundo_nombre     => nombres[1],
                            :apellido_paterno   => apellidos[0],
                            :apellido_materno   => apellidos[1],
                            :fecha_nacimiento   => item_apoderado.fh_nacimiento_pe,
                            :sexo               => item_apoderado.parsear_sexo,
                            :domicilio          => item_apoderado.domicilio_pe.titleize,
                            :villa_poblacion    => item_apoderado.sector_pe.titleize,
                            :telefono_fijo      => item_apoderado.fono_pe,
                            :telefono_movil     => item_apoderado.celular_pe,
                            :tipo               => Usuario::APODERADO,
                            :pais_id            => 1,
                            :region_id          => 1,
                            :comuna_id          => 1
                        )
                    else
                        usuario_apoderado = Usuario.new(
                            :rut                => item_matricula.rut_ap,
                            :tipo               => Usuario::APODERADO,
                            :pais_id            => 1,
                            :region_id          => 1,
                            :comuna_id          => 1
                        )                                
                    end  

                    # Guardar el usuario apoderado
                    if usuario_apoderado.save
                        puts "......... USUARIO_APODERADO guardado " + usuario_apoderado.rut
                        apoderado = Apoderado.new(
                            :usuario_id         => usuario_apoderado.id,
                            :alumno_id          => alumno.id,
                            :es_alumno          => false
                        )
                        if apoderado.save
                            puts "............ APODERADO guardado " + usuario_apoderado.rut
                        else
                            puts apoderado.errors.inspect
                            raise RuntimeError, 'ERROR AL ALMACENAR EL APODERADO' 
                        end
                    else                  
                        if not usuario_apoderado.errors.on(:rut).nil?
                            puts "......... USUARIO_APODERADO ya guardado! " + item_matricula.rut_ap.to_s
                        else
                            puts usuario_apoderado.errors.inspect
                            raise RuntimeError, 'ERROR AL ALMACENAR EL USUARIO APODERADO'
                        end 
                    end
                else
                    apoderado = Apoderado.new(
                        :usuario_id         => usuario_alumno.id,
                        :alumno_id          => alumno.id,
                        :es_alumno          => true
                    )
                    if apoderado.save
                        puts "............ APODERADO guardado ... es el mismo alumno !! " + usuario_alumno.rut
                    else
                        puts apoderado.errors.inspect
                        raise RuntimeError, 'ERROR AL ALMACENAR EL APODERADO' 
                    end
                end
            end
        end
        Process.exit
    end

    def self.lista_alumnos year
        data = []
        ModelosAntiguos::Matricula.all(:ano_ma => year).alumno.all.each do |alumno|
            #rut = ActionView::Helpers::NumberHelper::number_with_delimiter(alumno.rut_pe.to_s) + "-" + alumno.digito_pe
            rut = alumno.rut_pe.to_s + "-" + alumno.digito_pe
            nombres = nombre_con_inicial alumno.parsear_nombres
            apellidos = nombre_con_inicial alumno.parsear_apellidos

            if matricula = alumno.matriculas.last
                if ![110, 111].include?(matricula.id_ca)
                    tipo = matricula.sede.cft? ? 'CFT' : 'IP'
                    data << {:rut => rut, :nombre => "#{nombres} #{apellidos}".titleize, :tipo => tipo, :carrera => reemplazo_carreras(matricula.carrera.nombre_ca.titleize)}
                end
            end
        end

        data
    end

    def self.nombre_con_inicial nombre_arr
        str = nombre_arr[0]

        str << " #{nombre_arr[1][0]}." if nombre_arr.size > 1

        str
    end

    def self.reemplazo_carreras str

        [
            ["Ingenieria", "Ing."],
            [" De", " de"],
            [" En", " en"],
            [" A ", " a "],
            ["Administracion", "Adm."],
            [" de Nivel Superior", ""],
            ["enfermeria", "Enfermería"],
            ["Construccion", "Construcción"],
            ["(Ip)", ""],
            ["Educacion", "Educación"],
            ["Tecnico", "Técnico"],
            [" Y ", " y "],
            ["Prevencion", "Prevención"],
            ["Topografia", "Topografía"],
            ["Gastronomia", "Gastronomía"],
            ["Informatica", "Informática"],
            ["Ejecucion", "Ejecución"],
            ["Fisica", "Física"],
            [" E ", " e "],
            ["Plan Especial Ing. en Prevención de Riesgos", "Plan Esp. Ing. en Prevención de Riesgos"],
            ["Computacion", "Computación"],
            ["Auditoria", "Auditoría"]
        ].each do |i|
            str.gsub!(i[0], i[1])
        end

        str
    end

end

