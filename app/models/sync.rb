# encoding: utf-8
class Sync  
    SEDE_CONCEPCION         = 1
    SEDE_NUNOA              = 2
    SEDE_ELBOSQUE           = 3
    SEDE_VINA               = 4
    SEDE_CHILLAN            = 5
    
    SEDE_SYNC               = SEDE_CONCEPCION

    DEFAULT_SEDE_CONCEPCION = 1 
    DEFAULT_SEDE_NUNOA      = 5
    DEFAULT_SEDE_ELBOSQUE   = 7
    DEFAULT_SEDE_VINA       = 8
    DEFAULT_SEDE_CHILLAN    = 3

    DEFAULT_SEDES = {
        SEDE_CONCEPCION => DEFAULT_SEDE_CONCEPCION,
        SEDE_NUNOA      => DEFAULT_SEDE_NUNOA,
        SEDE_ELBOSQUE   => DEFAULT_SEDE_ELBOSQUE,
        SEDE_VINA       => DEFAULT_SEDE_VINA,
        SEDE_CHILLAN    => DEFAULT_SEDE_CHILLAN
    }


    SEDE_CONCEPCION_ID = 1
    SEDE_CHILLAN_ID    = 2
    SEDE_NUNOA_ID      = 3
    SEDE_BOSQUE_ID     = 4
    SEDE_VINA_ID       = 5
    SEDE_BARROS_ID     = 6
    SEDE_VINA_NORTE_ID = 7
    SEDE_MIRAFLORES_ID = 8
 
    SEDE_ID = {
        SEDE_CONCEPCION_ID => SEDE_CONCEPCION,
        SEDE_CHILLAN_ID    => SEDE_CHILLAN,
        SEDE_NUNOA_ID      => SEDE_NUNOA,
        SEDE_BOSQUE_ID     => SEDE_ELBOSQUE,
        SEDE_VINA_ID       => SEDE_VINA      
    }
    
    PERIODO_ANIO_ACTUAL     = 2013
    PERIODO_SEMESTRE_ACTUAL = 1

    DISTANCIA_ID_CA = [64, 61, 63, 46, 79, 84, 80]

    JORNADA_SWITCH = {
        InstitucionSedePlan::DIURNA     => 1, 
        InstitucionSedePlan::VESPERTINA => 3, 
        InstitucionSedePlan::TARDE      => 2, 
        nil                             => nil

    }
    PE_SWITCH = {
        SEDE_CONCEPCION     => :siaa_id_ca_concepcion,
        SEDE_CHILLAN        => :siaa_id_ca_chillan,
        SEDE_NUNOA          => :siaa_id_ca_nunoa,
        SEDE_ELBOSQUE       => :siaa_id_ca_bosque,
        SEDE_VINA           => :siaa_id_ca_vina
    }

    NOTAS_FINALES_SWITCH    = { 
        PlanificacionCalificacion::EXAMEN_DE_REPETICION => :nota_examen_repeticion, 
        PlanificacionCalificacion::NOTA_FINAL           => :nota_final, 
        PlanificacionCalificacion::NOTA_DE_PRESENTACION => :nota_presentacion, 
        PlanificacionCalificacion::EXAMEN_FINAL         => :nota_examen
    } 


    
    def self.sincronizar            
        #import_mallas
        import_asignaturas
        import_usuarios
        calcular_semestre_alumnos
        #actualizar_rol_docente
        actualizar_tipo_administrativo
        importar_homologacion_convalidacion
    end

    def self.corregir_morosos
        #DataMapper::Logger.new(STDOUT, :debug)
        PagoComprometido.transaction do 
            PagoComprometido.all(:estado.not => [PagoComprometido::ANULADO, PagoComprometido::PAGADO]).abonos( :estado.not => PagoComprometido::ANULADO, saldo: 0).each do |abono|
              
                puts "Hay abono 0: #{abono.inspect}".red
                ( pc = abono.pago_comprometido).update :estado => PagoComprometido::PAGADO
                puts "Cuota pagada: #{pc.inspect}".bold

                if ![PagoComprometido::ANULADO, PagoComprometido::PAGADO].include?( pc.estado ) && (pc.fecha_ultimo_abono.blank? ? pc.fecha_vencimiento : pc.fecha_ultimo_abono) < Date.today
                    puts "Dejando cuota como atrasada: #{pc.inspect}".yellow
                    pc.update :estado => PagoComprometido::ATRASADO
                end
          
                
            end
        end


        rescue Exception => e
            log_error e
    end

    def self.import_mallas #importa mallas -> revisiones de PlanEstudio
        puts "--- IMPORTANDO MALLAS ---"
        ModelosAntiguos::Malla.all.each do |malla|
            carrera = malla.carrera
            # , siaa_id_sede_sync: SEDE_SYNC 
            
            if (plan = PlanEstudio.first(siaa_id_ma: malla.id_ma, siaa_id_sede_sync: SEDE_SYNC)).blank? && !carrera.blank? # No existe plan y carrera existe
                
                pe_data = { nombre:                     t_str(carrera.nombre_ca),
                            nivel:                      carrera.nivel,
                            tiene_salida_intermedia:    !carrera.duracion_in_ca.eql?(0),
                            duracion:                   carrera.duracion_ca,
                            titulo_profesional:         t_str(carrera.titulo_ca),
                            titulo_tecnico:             t_str(carrera.titulo_in_ca),
                            revision:                   t_str(malla.nombre_ma),
                            semestre_inicio:            malla.sem_ini_ma,
                            anio_inicio:                malla.ano_ini_ma,
                            semestre_fin:               malla.sem_fin_ma,
                            anio_fin:                   malla.ano_fin_ma,
                            siaa_id_ma:                 malla.id_ma,
                            siaa_id_ca:                 malla.id_ca,
                            siaa_updated_at:            DateTime.now
                        }
                plan = PlanEstudio.new pe_data

                if plan.save
                    puts "-- PlanEstudio CREADO: #{plan.nombre}"



                else
                    puts "PROBLEMA AL CREAR PLAN DE ESTUDIO: #{plan.errors.inspect}"
                    rails RuntimeError, "Error al crear"
                end
            else
                if carrera.blank?
                    puts "-< Carrera no existe para Malla: #{malla.id_ma}"
                else
                    puts "-- PLAN EXISTENTE: #{plan.nombre}"
                end
            end
            
        end
    end

    def self.import_asignaturas
        datos = ModelosAntiguos::ConjuntoMalla.all
        puts "-- IMPORTANDO ASIGNATURAS ---".red

        c = 0
        datos.each do |conj_malla|
            c += 1
            puts "======================================================== [#{c}/#{datos.length}]".bold

            asignatura = ModelosAntiguos::Asignatura.first  id_ca: conj_malla.id_ca,
                                                            id_as: conj_malla.id_as,
                                                            id_se: conj_malla.id_se

            unless asignatura.nil?
                begin
                    # siaa_id_sede_sync: SEDE_SYNC
                    #tmp_carrera = ModelosAntiguos::Carrera.first id_ca: conj_malla.id_ca

                    plan_est = PlanEstudio.first_or_create({siaa_id_ma: conj_malla.id_ma, PE_SWITCH[SEDE_SYNC] => conj_malla.id_ca},
                                                           {nombre: 'MALLA INEXISTENTE',
                                                            siaa_updated_at: DateTime.now
                                                           }
                    )
                    #plan_est = PlanEstudio.first siaa_id_ma: conj_malla.id_ma.to_i, PE_SWITCH[SEDE_SYNC] => conj_malla.id_ca.to_i


                    asig = Asignatura.first_or_create({siaa_id: asignatura.id_as, siaa_id_sede_sync: SEDE_SYNC},
                                                      {nombre: t_str(asignatura.nombre_as),
                                                       semestre: conj_malla.blank? ? nil : conj_malla.id_ni,
                                                       codigo: asignatura.id_as,
                                                       plan_estudio: plan_est,
                                                       siaa_id: asignatura.id_as,
                                                       siaa_updated_at: DateTime.now
                                                      })


                    ModelosAntiguos::Prerequisito.all(id_as: asignatura.id_as).each do |prereq|
                        req_conj_malla = ModelosAntiguos::ConjuntoMalla.first(id_ma: conj_malla.id_ma, id_as: prereq.id_as_pr)

                        unless prereq.asignatura_requisito.nil?

               as_d = {nombre: t_str(prereq.asignatura_requisito.nombre),
                                                                   semestre: (req_conj_malla.blank? ? nil : req_conj_malla.id_ni),
                                                                   plan_estudio: plan_est,
                                                                   codigo: prereq.id_as,
                                                                   siaa_id: prereq.id_as,
                                                                   siaa_updated_at: DateTime.now
                                                                  }

                puts "Asignatura a crear en el caso que no exista : #{as_d}".bold
                            asig_req = Asignatura.first_or_create({siaa_id: prereq.id_as_pr, siaa_id_sede_sync: SEDE_SYNC}, as_d)

                            if (req = Requisito.first(siaa_id: prereq.oid.to_i, siaa_id_sede_sync: SEDE_SYNC)).blank? && !asig_req.blank? # no existe, hay que crearlo
                                req = Requisito.new asignatura_dependiente: asig,
                                                    asignatura_requisito: asig_req,
                                                    siaa_id: prereq.oid,
                                                    siaa_updated_at: DateTime.now,
                                                    siaa_id_sede_sync: SEDE_SYNC
                                if req.save
                                    puts "---- Requisito creado: #{asig.nombre} requisito: #{req.asignatura_requisito.nombre}".green
                                else
                                    raise RuntimeError, "Error al crear requisito: #{req.errors.inspect}"
                                end
                            else
                                if req.blank?
                                    puts = "----- Asignatura prerequisito: #{prereq.id_as_pr} no existe, para asig: #{asig.nombre}".red
                                else
                                    puts "--- Requisito existe: asignatura: #{req.asignatura_dependiente.nombre} requisito: #{req.asignatura_requisito.nombre}".yellow
                                end
                            end
                        end
                    end

                        # ModelosAntiguos::AsignaturaImpartida.all(id_as: conj_malla.id_as, id_ca: conj_malla.id_ca).each do |asig_imp|

                        #     periodo             = Periodo.first_or_create(  { anio: asig_imp.ano_ai, semestre: asig_imp.sem_ai },
                        #                                                     { estado: Periodo::CERRADO, siaa_updated_at: DateTime.now})
                        #     institucion_sede    = InstitucionSede.first     siaa_id: asig_imp.id_se


                        #     if (seccion = Seccion.first(siaa_id_ca: asig_imp.id_ca, siaa_id_as: asig_imp.id_as, numero: asig_imp.seccion_ai,
                        #                                 periodo: periodo, institucion_sede: institucion_sede)).blank? # No existe, se crea

                        #             seccion = Seccion.new   estado:             Seccion::CERRADA,
                        #                                     cupos:              asig_imp.cupos_ai,
                        #                                     numero:             asig_imp.seccion_ai,
                        #                                     #jornada:    #TODO: Falta definir [AV]
                        #                                     #inscritos:  #TODO: Falta calculo de inscritos [AV]
                        #                                     institucion_sede:   institucion_sede,
                        #                                     periodo:            periodo,
                        #                                     siaa_id_ca:         asig_imp.id_ca,
                        #                                     siaa_id_as:         asig_imp.id_as,
                        #                                     siaa_updated_at:    DateTime.now


                        #             if seccion.save
                        #                 puts "--> Seccion guardada: #{seccion.sigla} - asignatura: #{asig_imp.id_as}".bold.green
                        #             else
                        #                 raise RuntimeError, "-> Error al guardar: #{seccion.errors.inspect}".red
                        #             end
                        #     else
                        #         puts "-- La seccion ya existe:  #{seccion.sigla} - asignatura: #{asig_imp.id_as}".yellow
                        #     end
                        #     if (seccion_dictada = SeccionDictada.first(siaa_id_ca: asig_imp.id_ca, asignatura: asig, seccion: seccion)).blank?
                        #         seccion_dictada = SeccionDictada.new    asignatura:     asig,
                        #                                                 seccion:        seccion,
                        #                                                 siaa_id_ca:     asig_imp.id_ca,
                        #                                                 siaa_updated_at:DateTime.now

                        #         if seccion_dictada.save
                        #             puts "-----> SeccionDictada guardado, asignatura: #{seccion_dictada.asignatura.nombre}".blue
                        #         else
                        #             raise RuntimeError, "-> Error al guardar seccion_dictada: #{seccion_dictada.errors.inspect}".red
                        #         end
                        #     else
                        #         puts "-- La seccion dictada ya existe: #{seccion_dictada.asignatura.nombre}".magenta
                        #     end
                        # end

                rescue DataMapper::SaveFailureError => e
                    log_error e
                end
            end
        end

        puts "-- FIN IMPORTAR ASIGNATURAS --".red
    end

    def self.importar_salas

        
        ModelosAntiguos::Bloque.all.each do |bloque_siaa|

            if (bloque = BloqueHorario.first siaa_id: bloque_siaa.oid, siaa_id_sede_sync: SEDE_SYNC  ).blank?
                bloque = BloqueHorario.create   siaa_id:            bloque_siaa.oid,
                                                numero:             bloque_siaa.id_bl,
                                                nombre:             bloque_siaa.nombre_bl,
                                                hora_inicio:        bloque_siaa.hora_ini_bl,
                                                hora_termino:       bloque_siaa.hora_fin_bl,
                                                periodo:            Periodo.first(anio: bloque_siaa.ano_bl, semestre: bloque_siaa.sem_bl),
                                                siaa_updated_at:    DateTime.now,
                                                siaa_id_sede_sync: SEDE_SYNC

                puts "Bloque creado, numero: #{bloque.numero} nombre: #{bloque.nombre}".bold
            end

        end

        ModelosAntiguos::Sala.all.each do |sala_siaa|
            if (sala = Sala.first siaa_id: sala_siaa.id_sl, siaa_id_sede_sync: SEDE_SYNC  ).blank?
                insed = InstitucionSede.first(siaa_id: sala_siaa.id_se)
                puts "InstitucionSede: #{insed.nombre}"
                sala = Sala.create  nombre:             clean_str(sala_siaa.nombre_sl),
                                    piso:               sala_siaa.piso_sl,
                                    capacidad:          sala_siaa.capacidad_sl,
                                    sede:               insed.sede,
                                    siaa_id:            sala_siaa.id_sl,
                                    siaa_updated_at:    DateTime.now,
                                    siaa_id_sede_sync: SEDE_SYNC  
                puts "Sala #{sala.nombre} creada #{sala.siaa_id}".bold
            end
        end

        rescue DataMapper::SaveFailureError => e
            log_error e
    end

    def self.asignatura_ordenar_malla
        Asignatura.all( siaa_id_sede_sync: SEDE_SYNC  ).each do |asignatura|
            con_malla = ModelosAntiguos::ConjuntoMalla.first(id_as: asignatura.siaa_id)
            if not con_malla.nil?
                asignatura.update semestre: con_malla.id_ni if asignatura.semestre != con_malla.id_ni
            end
        end
    end

    def self.importar_academico
        #DataMapper::Logger.new(STDOUT, :debug)
        # Pre importación:
        #   CalificacionParcial.all.destroy!
        #   AlumnoInscritoSeccion.all.destroy!
        #   SeccionDictada.all.destroy!
        #   PlanificacionCalificacion.all.destroy!
        #   Seccion.all.destroy!
        #   r = Asignatura.all.links_asignaturas_requisitos.map(&:id)
        #   ar = Asignatura.all.links_asignaturas_requisitos.asignatura_requisito.map &:id
        #   Requisito.all(id: r).destroy!
        #   Asignatura.all(id: ar).destroy!
        #   Asignatura.all.destroy!
        # ---> Resetear AUTO INCREMENT en las tablas
        limit = 1
        offset = 0
        
        max = Alumno.count(:siaa_id.not => nil)
        puts " > Total: #{max}"#.blue
        
        begin
            while offset < (max + limit)
                Usuario.transaction do
                
                    begin
                        puts "-- Vuelta con offset: #{offset}".red
                        # Busca alumnos que no hayan entrado el 2013 (o sea, solo antiguos)
                        periodo_actual = Periodo.first(anio: PERIODO_ANIO_ACTUAL, semestre: PERIODO_SEMESTRE_ACTUAL)
                        #:alumno_plan_estudio => {:anio_ingreso.not => 2013}
                        Alumno.all(:siaa_id_sede_sync => SEDE_SYNC, :siaa_id.not => nil, :limit => limit, :offset => offset).each_with_index do |alumno, index|
                            puts "\tItem: #{index} =====================================".yellow.bold
                            usuario = alumno.datos_personales
                            puts "\t\tAlumno: #{alumno.inspect}".yellow
                            puts "\t\tUsuario: #{usuario.inspect}".bold
                            
                            alumno.alumno_plan_estudio.each_with_index do |al_pl_es, i_ape|
                                t        = "\t\t\t"
                                isp      = al_pl_es.institucion_sede_plan
                                inst_sed = isp.institucion_sede
                                pl_es    = isp.plan_estudio
                                puts "#{t}Estudia: #{pl_es.nombre}"
                                puts "#{t}Alumno Plan Estudio: #{al_pl_es.inspect}".bold
                                
                                t = "\t\t\t\t"
                                al_pl_es.matricula_plan.each do |mp|
                                    puts "#{t}==== MATRICULA PLAN ==============".bold
                                    periodo = mp.periodo
                                    puts "#{t} Periodo: #{periodo.nombre} Matricula Plan: #{mp.inspect} "

                                    t = "\t\t\t\t\t"
                                    puts "#{t}==== NOTAS =================".bold
                                    id_ca = al_pl_es.siaa_id
                                    
                                    if id_ca.blank?
                                        mat_ant = ModelosAntiguos::Matricula.first( oid: mp.siaa_id )
                                        next if mat_ant.blank?
                                        id_ca = mat_ant.id_ca
                                    end
                                
                                    ModelosAntiguos::Nota.all(rut_al: usuario.siaa_id, id_ca: id_ca, ano_no: periodo.anio).each do |nota|
                                        puts "#{t} Nota: #{nota.inspect}"
                                        
                                        asig_ant = ModelosAntiguos::Asignatura.first( id_as: nota.id_as )
                                        puts "#{t} Asignatura ant: #{asig_ant.inspect}"
                                        
                                        unless asig_ant.blank?
                                            

                                            id_ma = ModelosAntiguos::Malla.buscar_siaa_id_ma pl_es

                                            conj_malla = ModelosAntiguos::ConjuntoMalla.first id_as: nota.id_as, id_se: nota.id_se, id_ca: nota.id_ca, id_ma: id_ma

                                            if conj_malla.blank?
                                                conj_malla = ModelosAntiguos::ConjuntoMalla.first id_as: nota.id_as, id_se: nota.id_se, id_ca: nota.id_ca   
                                            end

                                            
                                            asig = Asignatura.first_or_create({siaa_id: asig_ant.id_as, siaa_id_sede_sync: SEDE_SYNC},
                                                                              {nombre: t_str(asig_ant.nombre_as),
                                                                               semestre: conj_malla.blank? ? 1 : conj_malla.id_ni,
                                                                               codigo: asig_ant.id_as,
                                                                               plan_estudio: al_pl_es.plan_estudio,
                                                                               siaa_id: asig_ant.id_as,
                                                                               siaa_updated_at: DateTime.now
                                                                              })
                                            #TODO: Falta importar PREREQUISITO, probablemente sea mejor al final

                                            # ModelosAntiguos::Prerequisito.all(id_as: asig_ant.id_as, id_ca: nota.id_ca).each do |prereq|
                                            #     req_conj_malla = ModelosAntiguos::ConjuntoMalla.first(id_ma: conj_malla.id_ma, id_as: prereq.id_as_pr)

                                            #     unless prereq.asignatura_requisito.nil?

                                            #             as_d = {
                                            #                         nombre: t_str(prereq.asignatura_requisito.nombre),
                                            #                         semestre: (req_conj_malla.blank? ? nil : req_conj_malla.id_ni),
                                            #                         plan_estudio: al_pl_es.plan_estudio,
                                            #                         codigo: prereq.id_as,
                                            #                         siaa_id: prereq.id_as,
                                            #                         siaa_updated_at: DateTime.now
                                            #                     }

                                            #             puts "#{t}\tAsignatura a crear en el caso que no exista : #{as_d}".blue.bold
                                            #             asig_req = Asignatura.first_or_create({siaa_id: prereq.id_as_pr, siaa_id_sede_sync: SEDE_SYNC}, as_d)
                                            #             unless asig_req.blank?
                                            #                 req = Requisito.first_or_create({
                                            #                                                     siaa_id: prereq.oid.to_i, siaa_id_sede_sync: SEDE_SYNC
                                            #                                                 }, {
                                            #                                                     asignatura_dependiente: asig,
                                            #                                                     asignatura_requisito: asig_req,
                                            #                                                     siaa_id: prereq.oid,
                                            #                                                     siaa_updated_at: DateTime.now,
                                            #                                                     siaa_id_sede_sync: SEDE_SYNC
                                            #                                                 })
                                            #             end

                                            #     end
                                            # end
                                        end
                                        unless asig.blank?
                                            per_insc = Periodo.first anio: nota.ano_no, semestre: nota.sem_no
                                            per_insc = Periodo.first(anio: 2010, semestre: 1) if per_insc.blank?
                                            
                                            seccion = Seccion.first_or_create({
                                                                                #siaa_id_ca:         id_ca,
                                                                                siaa_id_as:         nota.id_as,
                                                                                siaa_id_sede_sync:  SEDE_SYNC,
                                                                                numero:             nota.seccion_no,
                                                                                periodo:            per_insc,
                                                                                institucion_sede:   inst_sed
                                                                            },{
                                                                                estado:             (per_insc == periodo_actual ? Seccion::ABIERTA : Seccion::CERRADA),
                                                                                siaa_updated_at:    DateTime.now
                                                                            })

                                            puts "#{t} Seccion: #{seccion.inspect} ¿creada? #{seccion.new?}".blue

                                            seccion_dictada = SeccionDictada.first_or_create({
                                                                                                    siaa_id_ca: id_ca,
                                                                                                    siaa_id_sede_sync: SEDE_SYNC,
                                                                                                    seccion: seccion,
                                                                                                    asignatura: asig
                                                                                                },{
                                                                                                    siaa_updated_at: DateTime.now
                                                                                                })
                                            puts "#{t} Seccion inscrita: #{seccion_dictada.inspect}".blue.bold

                                            alumno_inscrito_seccion = AlumnoInscritoSeccion.first_or_create({
                                                                                                                siaa_id:                id_ca,
                                                                                                                siaa_id_sede_sync:      SEDE_SYNC,
                                                                                                                seccion_dictada:        seccion_dictada,
                                                                                                                alumno_plan_estudio:    al_pl_es
                                                                                                            },{
                                                                                                                estado: AlumnoInscritoSeccion::INSCRITA,
                                                                                                                siaa_updated_at: DateTime.now
                                                                                                            })

                                            
                                            
                                            cal_ev = ModelosAntiguos::CalendarioEvaluacion.all( id_ca: id_ca, 
                                                                                                id_as: nota.id_as, 
                                                                                                sem_ce: nota.sem_no, 
                                                                                                ano_ce: nota.ano_no,
                                                                                                seccion_ce: nota.seccion_no,
                                                                                                id_tn: [PlanificacionCalificacion::PRUEBA_PARCIAL, PlanificacionCalificacion::PRUEBA_GLOBAL],
                                                                                                order: :nro_ce.desc)

                                            cal_ev.each do |ce|
                                            

                                                if (plan_calif = PlanificacionCalificacion.first(siaa_id: ce.oid, siaa_id_sede_sync:  SEDE_SYNC)).blank?
                                                    ponderacion = ce.ponderacion_ce

                                                    if ponderacion > 1.0 && ponderacion < 2.0
                                                        ponderacion = ponderacion-1.0
                                                    end

                                                    if ponderacion >= 100 && ponderacion <= 1000
                                                        ponderacion = ponderacion / 1000
                                                    end

                                                    if ponderacion > 1000
                                                        ponderacion = ponderacion / 10000
                                                    end

                                                    if ponderacion > 1 and ponderacion < 100
                                                        ponderacion = ponderacion/100
                                                    end

                                                    plan_calif = PlanificacionCalificacion.create(  ponderacion:            (ce.id_te == PlanificacionCalificacion::SUMATIVA ? ponderacion : 0),
                                                                                                    fecha_comprometida:     ce.fh_ce,
                                                                                                    nombre:                 ce.id_tn,
                                                                                                    seccion_id:             seccion.id,
                                                                                                    tipo:                   ce.id_te,
                                                                                                    numero:                 ce.nro_ce,
                                                                                                    siaa_id:                ce.oid,
                                                                                                    siaa_updated_at:        DateTime.now,
                                                                                                    siaa_id_sede_sync:      SEDE_SYNC)
                                                                
                                                    
                                                    puts "#{t}>> Calificacion creada de #{al_pl_es.alumno.datos_personales.nombre}: #{plan_calif.inspect}".green.bold
                                                end # if (plan_calif...)

                                                if plan_calif.numero == nota.nro_ce
                                                    calif_par = CalificacionParcial.first_or_create({
                                                                                            siaa_id:                    nota.oid,
                                                                                            siaa_id_sede_sync:          SEDE_SYNC,
                                                                                            alumno_inscrito_seccion:    alumno_inscrito_seccion,
                                                                                            planificacion_calificacion: plan_calif
                                                                                        },{
                                                                                            calificacion:               nota.nota_no,
                                                                                            estado:                     CalificacionParcial::CALIFICADA
                                                                                        })
                                                    puts "#{t}Calificacion Parcial creada: #{calif_par.inspect}"
                                                end # if plan_calif.numero == nota.nro_ce

                                                if [PlanificacionCalificacion::EXAMEN_DE_REPETICION, PlanificacionCalificacion::NOTA_FINAL, PlanificacionCalificacion::NOTA_DE_PRESENTACION, PlanificacionCalificacion::EXAMEN_FINAL].include? nota.id_tn
                                                    if( (alumno_inscrito_seccion.send(NOTAS_FINALES_SWITCH[nota.id_tn]) != nota.nota_no) or (nota.id_tn == PlanificacionCalificacion::NOTA_FINAL && alumno_inscrito_seccion.estado.nil?) )
                                                        ins_upd = {NOTAS_FINALES_SWITCH[nota.id_tn] => nota.nota_no}

                                                        if nota.id_tn == PlanificacionCalificacion::NOTA_FINAL && !nota.nota_no.nil?
                                                            ins_upd[:estado] = (nota.nota_no >= 4 ? AlumnoInscritoSeccion::APROBADA : AlumnoInscritoSeccion::REPROBADA)
                                                        end
                                                        alumno_inscrito_seccion.update! ins_upd
                                                        puts "#{t}>>> Alumno: #{usuario.nombre} de seccion: #{alumno_inscrito_seccion.seccion_dictada.seccion.sigla} - #{alumno_inscrito_seccion.seccion_dictada.asignatura.nombre} con #{NOTAS_FINALES_SWITCH[nota.id_tn].to_s} : #{nota.nota_no} - Estado: #{alumno_inscrito_seccion.estado}".red.bold


                                                    end
                                                end # if [PlanificacionCalificacion::...]

                        
                                            end # cal_env.each
                                        end # unless asig.blank?
                                        puts "#{t}==== !NOTAS ================".bold

                                        t = "\t\t\t\t"
                                        
                                        puts "#{t}==== !MATRICULA PLAN =============".bold
                                    end # ModelosAntiguos::Nota.all
                                end # al_pl_es.matricula_plan.each
                            end # alumno.alumno_plan_estudio.each_with_index
                            
                            
                            
                            
                            puts "=============================================================".blue.bold
                        end # Alumno.all

                        rescue DataMapper::SaveFailureError => e
                            log_error e
                        rescue Exception => e
                            log_error e
                    end #begin
                    puts "limit: #{limit} offset: #{offset}"
                    
                end # Usuario.transaction do
                offset += limit
            end # while
        rescue NameError => e
            log_error e
        rescue RuntimeError => e
            log_error e
        rescue DataMapper::SaveFailureError => e
            log_error e
        rescue Exception => e
            log_error e
        end
        
    end
    def self.import_usuarios #TODO: Está a medias [AV]
        #DataMapper::Logger.new(STDOUT, :debug)
        limit = 50
        offset = 0
        
        max = ModelosAntiguos::Persona.count
        puts " > Total: #{max}"#.blue
        
        #Cobranza.all.destroy!
        
        file_text = ""
        
        while offset < (max + limit)
            file_text << "-- Vuelta con offset: #{offset}"
            puts "-- Vuelta con offset: #{offset}".red
            begin
                Usuario.transaction do
                   
                    periodo_actual = Periodo.first(anio: PERIODO_ANIO_ACTUAL, semestre: PERIODO_SEMESTRE_ACTUAL)
                    
                    puts "--- IMPORTANDO ALUMNOS ---"

                    default_sede = DEFAULT_SEDES[SEDE_SYNC]
                    sede = Sede.get SEDE_ID[SEDE_SYNC]

                    tipos_pagos_para_plan = (ModelosAntiguos::TipoPago.all(:alias_tp.like => 'MATRICULA')+ModelosAntiguos::TipoPago.all(:alias_tp.like => 'ARANCEL%')+ModelosAntiguos::TipoPago.all(:alias_tp.like => 'NORMATIVA')).map{|x| x.id_tp}

                    personas_array = ModelosAntiguos::Persona.all(order: :fh_trans_pe.desc, limit: limit, offset: offset)#, limit: 9999, offset: 2154)#, offset: 1600)
                    file_text << "Cantidad de personas (buenas o malas): #{personas_array.size}\n".red.bold
                    personas_validas = []
                    #personas_array = ModelosAntiguos::Matricula.all(ano_ma: 2012).alumnos
                    #personas_array = ModelosAntiguos::Matricula.all(rut_al: 17815935).alumnos

                    

                    # VUELTA PARA USUARIOS
                    puts "VUELTA DE USUARIOS".red
                    c = 0
                    personas_array.each do |persona|
                        puts "====================================================== [#{c+1} / #{personas_array.length}]".red
                        c += 1
                        debo_eliminar = true
                        rut = persona.parsear_rut
                        rut = rut + "0" if rut.last == "-"

                        # Elimino información antigua del alumno antes de insertar todo lo nuevo...
                        us = Usuario.first(:rut => rut)
                        al = us.alumno unless us.blank?
                        #apo = al.apoderado unless al.blank?
                        ape = al.alumno_plan_estudio(:siaa_updated_at.not => nil) unless al.blank?
                        if ape.blank?
                            debo_eliminar = false
                            file_text << "\n=============================\n".yellow.bold
                            file_text << "!!! --- No elimino los datos del usuario: #{us.inspect} ya que es un registro nuevo\n".red
                            file_text << "\n=============================\n".yellow.bold
                        end
                        ais = ape.links_secciones_inscritas unless ape.blank?
                        acp = ais.calificaciones_parciales unless ais.blank?
                        matr = ape.matricula_plan unless ape.blank?
                        p_p = matr.planes_pagos unless matr.blank?
                        bcob= p_p.bitacora_cobranzas unless p_p.blank?
                        pagare = p_p.pagares unless p_p.blank?
                        p_c = p_p.pagos_comprometidos unless p_p.blank?
                        cob = p_c.cobranzas unless p_c.blank?
                        p_r = p_c.prorrogas unless p_c.blank?
                        abonos = p_c.abonos unless p_c.blank?
                        
                        d_v = []
                        d_v += p_p.documentos_ventas unless p_p.blank?
                        d_v += ape.documentos_venta unless ape.blank?

                        unless abonos.blank?
                            abonos.each do |abono|
                                d_v +=  [abono.documento_venta]
                            end
                        end

                        abonos = []
                        abonos.each{ |x| abonos += x }
                        d_v.each{|dv| dv.abonos.each {|x| abonos += [x]} }

                        # file_text << "\n=============================\n".bold
                        # file_text << "Eliminando datos de usuario: #{us.inspect}"
                        debo_eliminar = false unless ape.blank?
                        if debo_eliminar
                            unless abonos.blank?
                                # file_text << "Eliminando #{abonos.inspect}\n"
                                abonos.each do |x| 
                                    x.certificado.destroy! unless x.certificado.blank?
                                    x.destroy!
                                end
                            end

                            unless d_v.blank?
                                # file_text << "Eliminando #{d_v.inspect}\n"
                                d_v.each{ |x| x.destroy! }
                            end
                            unless cob.blank?
                                # file_text << "Eliminando #{cob.inspect}\n"
                                cob.destroy! 
                            end
                            unless bcob.blank?
                                bcob.destroy!
                            end
                            unless p_r.blank?
                                p_r.destroy!
                            end
                            unless p_c.blank?
                                # file_text << "Eliminando #{p_c.inspect}\n"
                                p_c.destroy! 
                            end

                            unless pagare.blank?
                                # file_text << "Eliminando #{pagare.inspect}\n"
                                pagare.destroy! 
                            end
                            unless p_p.blank?
                                # file_text << "Eliminando #{p_p.inspect}\n"
                                p_p.destroy!    
                            end
                            unless matr.blank?
                                # file_text << "Eliminando #{matr.inspect}\n"
                                matr.destroy!   
                            end
                            unless acp.blank?
                                # file_text << "Eliminando #{acp.inspect}\n"
                                acp.destroy!    
                            end
                            unless ais.blank?
                                # file_text << "Eliminando #{ais.inspect}\n"
                                ais.destroy!    
                            end
                            unless ape.blank?
                                # file_text << "Eliminando #{ape.inspect}\n"
                                ape.destroy!    
                            end
                        end
                        
                        # file_text << "\n=============================\n".red.bold
                        #apo.destroy! unless apo.blank?
                        #al.destroy! unless al.blank?

                        if persona.parsear_rut.blank? || persona.parsear_nombres.blank? || persona.parsear_apellidos.blank?
                            puts "Rut parseado: #{persona.parsear_rut}"
                            puts "La persona no es válida #{persona.inspect}".red.bold
                            next 
                        end

                        
                        ma = persona.matriculas.first

                        institucion_sede = (ma.blank? || (def_is = InstitucionSede.first(siaa_id: ma.id_se)).blank?) ? InstitucionSede.get(default_sede) : def_is
                        institucion_sede = InstitucionSede.get(default_sede) if institucion_sede.blank?


                        if persona.matriculas_alumno.size.eql? 0
                            puts "---- Persona #{rut} no tiene matrículas, así que no lo guardo".red
                            next 
                        end

                        personas_validas << persona

                        #===================== USUARIO =======================
                        if (usuario = Usuario.first(rut: rut)).blank? #no existe, crea un nuevo registro

                            usuario = Usuario.new self.usuario_hash(persona, sede) 

                            if usuario.save
                                puts "------ Usuario creado: #{rut} : #{c}".green
                            else
                                puts "------ Error al crear usuario: #{rut} \nValidaciones: #{usuario.errors.inspect}".red
                                puts "---------- Datos originales: #{persona.inspect}".red
                                raise RuntimeError, "Hubo un error al crear el usuario".red
                            end # usuario.save
                        else # es un registro existente
                            unless usuario.siaa_id.blank? # Actualizo solo si se sincronizó
                                usuario.update self.usuario_hash(persona, sede)
                                puts "------ Actualizando usuario: #{rut} : #{c}".yellow
                            end
                            # institucion_sede    = (ma = persona.matriculas.last).blank? ? default_sede : InstitucionSede.first(siaa_id: ma.id_se)
                            # # verifico si el usuario fue modificado
                            # if str_date(usuario.siaa_trans_date) != persona.fecha_transaccion_str # cambió, así que actualizo
                            #     puts "------ Actualizando usuario: #{rut} : #{c}".yellow
                            #     usuario.update self.usuario_hash(persona, sede)
                            # else
                            #     puts "------ Usuario: #{rut} no ha cambiado : #{c}".magenta
                            # end
                        end # usuario.blank?
                        #================== FIN USUARIO =======================
                    end # personas_array.each

                    puts "VUELTA DE ALUMNOS Y APODERADOS".red

                    file_text << "Cantidad de alumnos a importar: #{personas_validas.size}\n".blue.bold

                    c = 0
                    personas_validas.each do |persona|
                        puts "====================================================== [#{c+1} / #{personas_validas.length}]".bold
                        c += 1
                        # Obtengo apoderados del alumno
                        apoderados = ModelosAntiguos::Persona.all rut_pe: persona.matriculas_alumno.map{|x| x.rut_ap}
                        puts "Persona actual: #{persona.parsear_rut}".bold
                        puts "Apoderados del alumno: #{apoderados.inspect}".yellow

                        # Matrículas
                        matriculas = persona.matriculas_alumno
                        historial_matriculas = ModelosAntiguos::HistorialMatricula.all rut_al: persona.rut_pe, order: [:ano_hm.asc, :sem_hm.asc]
                        #matriculas.uniq{|x| x.ano_ma}.sort_by{|x| x.ano_ma}.each do |matricula| # Recorro matrículas y voy creando apoderado
                        
                        for i in 0..(historial_matriculas.size-1)
                            puts "||||||||||||||||||| HM: #{i}/#{historial_matriculas.size-1}".blue.bold
                            hm = historial_matriculas[i]
                            hm_siguiente = historial_matriculas.size < i ? historial_matriculas[i] : nil
                            
                            ma = matricula = ModelosAntiguos::Matricula.first rut_al: hm.rut_al, sem_ma: hm.sem_hm, ano_ma: hm.ano_hm

                            if ma.blank?
                                file_text << "\n=====================\n"
                                file_text << "El alumno: #{hm.rut_al} no tiene matricula pero si historial.. ?".red
                                file_text << "\n=====================\n"
                                next
                            end

                            # ============= Busco el plan de estudios
                            busqueda = {}
                            busqueda[:siaa_id_ca_concepcion] = ma.id_ca if SEDE_SYNC == SEDE_CONCEPCION
                            busqueda[:siaa_id_ca_chillan]    = ma.id_ca if SEDE_SYNC == SEDE_CHILLAN
                            busqueda[:siaa_id_ca_bosque]     = ma.id_ca if SEDE_SYNC == SEDE_ELBOSQUE
                            busqueda[:siaa_id_ca_nunoa]      = ma.id_ca if SEDE_SYNC == SEDE_NUNOA
                            busqueda[:siaa_id_ca_vina]       = ma.id_ca if SEDE_SYNC == SEDE_VINA

                            
                            primera_matricula   = matriculas.first(id_ca: ma.id_ca, order: [:ano_ma.asc, :sem_ma.asc])

                            institucion_sede = (primera_matricula.blank? || (def_is = InstitucionSede.first(siaa_id: primera_matricula.id_se)).blank?) ? InstitucionSede.get(default_sede) : def_is
                            institucion_sede = InstitucionSede.get(default_sede) if institucion_sede.blank?

                            malla = ModelosAntiguos::Malla.first    :ano_ini_ma.gte => primera_matricula.ano_ma,   :sem_ini_ma.gte => primera_matricula.sem_ma,
                                                                    :ano_fin_ma.lte => primera_matricula.ano_ma,   :sem_fin_ma.lte => primera_matricula.sem_ma,
                                                                    :id_ca => primera_matricula.id_ca,             :id_se => primera_matricula.id_se

                            busqueda[:siaa_id_ma] = malla.id_ma unless malla.blank?

                            plan_estudio = PlanEstudio.first busqueda


                            puts "---===+******* PLAN ESTUDIO: #{plan_estudio.inspect}".blue.bold
                            if plan_estudio.blank?
                                file_text << "\n=============================\n"
                                file_text << "Plan Estudio para id_ca: #{primera_matricula.id_ca} y id_ma: #{malla.id_ma unless malla.blank?} no existe\n".red.bold
                                file_text << "Persona: #{persona.inspect}\n"
                                next
                            end # pe.blank?

                            # ============== Creo al apoderado
                            if (apoderado = Apoderado.first(siaa_id: ma.rut_ap)).blank? # Apoderado no existe
                                per_ap = ModelosAntiguos::Persona.first rut_pe: ma.rut_ap
                                if per_ap.blank?
                                    file_text << "\n==========================\n"
                                    file_text << "Matricula sin apoderado: #{ma.inspect}\n".red.bold 
                                    file_text << "Se matricula con el mismo alumno como apoderado: #{persona.inspect}\n".blue.bold

                                    per_ap = ModelosAntiguos::Persona.first rut_pe: ma.rut_al                            
                                end
                                apod = Usuario.first_or_create( {rut: per_ap.parsear_rut}, self.usuario_hash(per_ap, sede, Usuario::APODERADO) )

                                apoderado = Apoderado.new   es_alumno:          (ma.rut_al == per_ap.rut_pe),
                                                            documentos_presentados: Apoderado::NINGUNO,
                                                            siaa_id:            ma.rut_ap,
                                                            siaa_updated_at:    DateTime.now,
                                                            datos_personales:   apod, 
                                                            siaa_id_sede_sync:  SEDE_SYNC  
                                if apoderado.save
                                    puts "--- Apoderado creado: #{ma.rut_ap} : #{c}".green
                                else
                                    raise RuntimeError, "Error al crear el apoderado: #{apoderado.errors.inspect}".red
                                end # if apoderado.save
                            end # if check apoderado

                            usuario = Usuario.first(siaa_id: ma.rut_al)
                            next if usuario.nil?  # Mato el recorrido, sería raro que no exista un usuario del alumno

                            # El usuario es un alumno
                            if (alumno = Alumno.first(siaa_id: ma.rut_al) ).blank? #no existe, se crea
                                alumno = Alumno.new     anio_ingreso:       (ma_in = matriculas.first(id_ca: ma.id_ca).ano_ma) > 9999 ? ma_in/10 : (ma_in < 1000 ? ma_in.to_s+"0" : ma_in),
                                                        datos_personales:   usuario,
                                                        apoderado:          apoderado,
                                                        #modalidad:          -1,
                                                        #estado_academico:   -1,
                                                        #estado_financiero:  -1,
                                                        establecimiento_educacional: -1,
                                                        # tipo_ingreso:       -1,
                                                        tiene_certificado_nacimiento: false,
                                                        tiene_certificado_titulo: false,
                                                        tiene_licencia_e_media: false,
                                                        siaa_id:            ma.rut_al,
                                                        siaa_updated_at:    DateTime.now,
                                                        siaa_id_sede_sync:  SEDE_SYNC
                                
                                if alumno.save
                                    puts "--- Alumno creado: #{ma.rut_al} : #{c}".magenta
                                else
                                    raise RuntimeError, "Error al crear alumno: #{ma.rut_al} errores: #{alumno.errors.inspect}"
                                end # if alumno.save
                            end # if alumno no existe


                            periodo_isp         = Periodo.first_or_create(  {anio: primera_matricula.ano_ma, semestre: primera_matricula.sem_ma}, 
                                                                            {estado: Periodo::CERRADO, siaa_updated_at: DateTime.now} )
                            periodo_matricula   = Periodo.first_or_create(  {anio: matricula.ano_ma, semestre: matricula.sem_ma}, 
                                                                            {estado: Periodo::CERRADO, siaa_updated_at: DateTime.now} )
                            # Asocio al alumno a algún plan
                            institucion_sede_plan = InstitucionSedePlan.first_or_create({   institucion_sede_id:    institucion_sede.id, 
                                                                                            plan_estudio_id:        plan_estudio.id,
                                                                                            periodo_id:             periodo_isp.id,
                                                                                            modalidad:              DISTANCIA_ID_CA.include?(primera_matricula.id_ca) ? InstitucionSedePlan::DISTANCIA : InstitucionSedePlan::PRESENCIAL,
                                                                                            jornada:                JORNADA_SWITCH[ma.id_jo],
                                                                                            siaa_id_sede_sync:      SEDE_SYNC},
                                                                                        {
                                                                                            estado:                 (periodo_isp.anio > 2008 ? InstitucionSedePlan::ABIERTA : InstitucionSedePlan::CERRADA),
                                                                                            siaa_id:                primera_matricula.id_ca,
                                                                                            siaa_updated_at:        DateTime.now
                                                                                        })                                                                              
                                    
                            institucion_sede_plan.update institucion_sede_id: institucion_sede.id if institucion_sede_plan.institucion_sede.nil?



                            if (al_pl_es = AlumnoPlanEstudio.first( institucion_sede_plan: institucion_sede_plan,
                                                                    alumno: alumno,
                                                                    periodo: periodo_isp)).blank? # no existe, lo creo

                                al_pl_es = AlumnoPlanEstudio.new    anio_ingreso: primera_matricula.ano_ma,
                                                                    institucion_sede_plan: institucion_sede_plan,
                                                                    alumno: alumno,
                                                                    periodo: periodo_isp,
                                                                    siaa_updated_at: DateTime.now,
                                                                    siaa_id_sede_sync:  SEDE_SYNC,
                                                                    es_trabajador:      (ma.rut_al == ma.rut_ap)
                                if al_pl_es.save
                                    puts "---- AlumnoPlanEstudio: #{al_pl_es.alumno.datos_personales.nombre} - #{institucion_sede_plan.periodo.nombre} - #{al_pl_es.institucion_sede_plan.plan_estudio.nombre}".green
                                else
                                    puts "institucion_sede: #{institucion_sede.inspect}".magenta
                                    puts "institucion_sede_plan: #{institucion_sede_plan.inspect}".yellow
                                    puts "plan_estudio: #{plan_estudio.inspect}".red
                                    puts "periodo: #{periodo_isp.inspect}".magenta
                                    raise RuntimeError, "Error al crear alumno plan estudio: #{al_pl_es.errors.inspect}".red
                                end
                            end

                            #tipo_matricula = matriculas.select{|x| x.ano_ma === matricula.ano_ma}.size > 1 ? MatriculaPlan::PROFESIONAL_DOS_SEMESTRES : MatriculaPlan::PROFESIONAL_UN_SEMESTRE

                            semestres = 0
                            if hm_siguiente.nil?
                                # cuento directo cuantas matrículas hay
                                semestres = matriculas.select{|x| x.ano_ma >= hm.ano_hm and x.sem_ma >= hm.sem_hm}.size
                            else # veo directamente el siguiente
                                if hm.sem_hm == hm_siguiente.sem_hm && hm.ano_hm == (hm_siguiente.ano_hm - 1) # Es el siguiente año
                                    semestres = 2
                                else 
                                    if matriculas.select{|x| x.sem_ma == (hm.sem_hm.eql?(1) ? 2 : 1) and x.ano_ma == (hm.sem_hm.eql?(1) ? hm.ano_hm : (hm.ano_hm+1))}.size > 0
                                        semestres = 2   
                                    else
                                        semestres = 1
                                    end
                                end
                            end # hm_siguiente.nil?
                            tipo_matricula = PlanEstudio.buscar_nivel_malla plan_estudio.id, semestres

                            if institucion_sede_plan.modalidad.eql? InstitucionSedePlan::DISTANCIA
                                tipo_matricula = MatriculaPlan::DISTANCIA_1_A_4_NIVEL
                            end

                            tipo_matricula = MatriculaPlan::SALIDA_INTERMEDIA unless ModelosAntiguos::SalidaIntermedia.all( rut_al: persona.rut_pe, ano_si: matricula.ano_ma, sem_si: matricula.sem_ma ).blank?
                            tipo_matricula = MatriculaPlan::DISTANCIA_SALIDA_INTERMEDIA_COMPLETA if institucion_sede_plan.modalidad.eql?(InstitucionSedePlan::DISTANCIA) and tipo_matricula.eql?(MatriculaPlan::SALIDA_INTERMEDIA)
                            

                            puts "!!!!____----- Matrículas ya registradas del periodo: #{MatriculaPlan.all(periodo_id: periodo_matricula.id, alumno_plan_estudio_id: al_pl_es.id).inspect}".red.bold

                            ejecutivo_matricula = ejecutivo(matricula.rut_em, sede)

                            if MatriculaPlan.first(siaa_id: matricula.oid).blank?
                                mat_plan = MatriculaPlan.create     siaa_id:                    matricula.oid,
                                                                    periodo_id:                 periodo_matricula.id,
                                                                    alumno_plan_estudio_id:     al_pl_es.id,
                                                                    siaa_updated_at:            DateTime.now,
                                                                    siaa_id_sede_sync:          SEDE_SYNC,
                                                                    created_at:                 matricula.fecha_matricula,
                                                                    ejecutivo_matriculas_id:    ejecutivo_matricula.id
                                                                #apoderado_id:           apoderado.id,
                                                                #tipo:                   tipo_matricula, # Se cambió a PlanPago
                                                                #matricula:              hist_mat.nil? ? 0 : hist_mat.matricula,
                                                                #arancel:                hist_mat.nil? ? 0 : hist_mat.arancel
                                puts "\n=======> Creado Matricula Plan id: #{mat_plan.id} oid: #{mat_plan.siaa_id} periodo: #{periodo_matricula.anio}-#{periodo_matricula.semestre}\n".bold

                                hist_mat = ModelosAntiguos::HistorialMatricula.first rut_al: matricula.rut_al, id_ca: matricula.id_ca, ano_hm: matricula.ano_ma, sem_hm: matricula.sem_ma

                                plan_pago = PlanPago.create estado:                     PlanPago::VIGENTE,
                                                            tipo:                       tipo_matricula,
                                                            #normativa: X #TODO: Fal    ta...
                                                            matricula:                  hist_mat.nil? ? 0 : hist_mat.matricula,
                                                            arancel:                    hist_mat.nil? ? 0 : hist_mat.arancel,
                                                            descuento_aplicado:         hist_mat.nil? ? 0 : hist_mat.descuento_arancel,
                                                            arancel_total:              hist_mat.nil? ? 0 : hist_mat.arancel_total,
                                                            matricula_plan:             mat_plan,
                                                            ejecutivo_matriculas_id:    ejecutivo_matricula.id,
                                                            apoderado_id:               apoderado.id,
                                                            periodo_id:                 periodo_matricula.id,
                                                            descuento_id:               ModelosAntiguos::Beneficio.buscar_descuento(rut_al: matricula.rut_al, sem_be: matricula.sem_ma, ano_be: matricula.ano_ma),
                                                            siaa_rut_al:                matricula.rut_al,
                                                            siaa_ano_ma:                matricula.ano_ma,
                                                            siaa_sem_ma:                matricula.sem_ma,
                                                            siaa_updated_at:            DateTime.now,
                                                            created_at:                 hm.fecha

                                bitacoras = ModelosAntiguos::BitacoraCobranza.all(rut_al: matricula.rut_al, id_ca: matricula.id_ca, ano_bc: matricula.ano_ma)
                                
                                bitacoras.each do |bitacora|
                                    BitacoraCobranza.first_or_create({ siaa_id: bitacora.id_bc },
                                                                     { 
                                                                        :ejecutivo_matriculas_id => ejecutivo(bitacora.rut_em, institucion_sede.sede.id).id,
                                                                        :plan_pago_id            => plan_pago.id,
                                                                        :fecha                   => bitacora.fh_bc,
                                                                        :observacion             => bitacora.detalle,
                                                                        :created_at              => bitacora.fecha
                                                                     })
                                end

                                planes = ModelosAntiguos::Plan.all rut_al: matricula.rut_al, ano_pl: matricula.ano_ma, sem_pl: matricula.sem_ma # Importo cuotas de pagaré
                                


                                cuotas_arancel = cuotas_matricula = cuotas_normativa = 0

                                planes.each do |plan|
                                    tipo_pago = ModelosAntiguos::TipoPago.first id_tp: plan.id_tp
                                    next if tipo_pago.blank?
                                    cuotas_matricula += 1   if tipo_pago.alias_tp.include? "MATRICULA"
                                    cuotas_arancel += 1     if tipo_pago.alias_tp.include? "ARANCEL"
                                    cuotas_normativa += 1   if tipo_pago.alias_tp.include? "NORMATIVA"
                                end
                                unless planes.blank?
                                    pagare = Pagare.create  :estado                  => Pagare::VIGENTE,
                                                            :numero                  => hm.pagare_ag.blank? ? 1 : hm.pagare_ag,
                                                            :monto                   => hm.valor_pag_hm.blank? ? 0 : hm.valor_pag_hm,
                                                            :cuotas_arancel          => cuotas_arancel,
                                                            :cuotas_matricula        => cuotas_matricula,
                                                            :cuotas_normativa        => cuotas_normativa,
                                                            :fecha_inicio            => planes.first.fh_venc_pl,
                                                            :fecha_termino           => planes.last.fh_venc_pl,
                                                            :plan_pago_id            => plan_pago.id,
                                                            :ejecutivo_matriculas_id => ejecutivo_matricula.id,
                                                            :alumno_plan_estudio_id  => al_pl_es.id,
                                                            :institucion_sede_id     => institucion_sede.id
                                end

                                planes.each do |plan|
                                    pagos = ModelosAntiguos::Pago.all rut_al: plan.rut_al, letra_pl: plan.letra_pl, order: [:fh_pg.asc]

                                    estado = PagoComprometido::COMPROMETIDO

                                    if pagos.size > 0
                                        estado = pagos.last.saldo_pg.eql?(0) ? PagoComprometido::PAGADO : PagoComprometido::COMPROMETIDO_CON_ABONOS 
                                    end

                                    unless estado.eql? PagoComprometido::PAGADO
                                        if pagos.size.eql?(0) && plan.fh_venc_pl < Date.today
                                            estado = PagoComprometido::ATRASADO
                                        end
                                        if pagos.size > 0 && plan.fh_venc_pl > pagos.last.fecha && !pagos.last.saldo_pg.eql?(0)
                                            estado = PagoComprometido::ATRASADO
                                        end
                                    end
                                

                                    pago_comprometido = PagoComprometido.create :numero_cuota            => plan.secuencia_letra_pl,
                                                                                :tipo_cuota              => PagoComprometido::PAGARE,
                                                                                :estado                  => estado,
                                                                                :fecha_vencimiento       => plan.fh_venc_pl,
                                                                                :fecha_ultimo_abono      => pagos.blank? ? nil : pagos.last.fh_pg,
                                                                                :fecha_pago_realizado    => estado.eql?(PagoComprometido::PAGADO) ? pagos.last.fh_pg : nil,
                                                                                :monto                   => plan.valor_pl,
                                                                                :saldo                   => (p_tmp = (pagos.blank? ? plan.valor_pl : pagos.last.saldo_pg)) < 0 ? 0 : p_tmp,
                                                                                :centro_costo            => plan.centro_costos,
                                                                                :institucion_sede_id     => institucion_sede.id,
                                                                                :plan_pago_id            => plan_pago.id,
                                                                                :ejecutivo_matriculas_id => ejecutivo_matricula.id,
                                                                                :pagare_id               => pagare.id,
                                                                                :siaa_id                 => plan.letra_pl,
                                                                                :siaa_id_sede_sync       => SEDE_SYNC

                                    ant_prorrogas = ModelosAntiguos::Prorroga.all(letra_pl: plan.letra_pl, rut_al: plan.rut_al)

                                    ant_prorrogas.each do |ant_prorroga|
                                        prorroga = Prorroga.first_or_create({ siaa_id: ant_prorroga.id_pr },
                                                                            { 
                                                                                :fecha                   => ant_prorroga.fh_prorroga_pr, 
                                                                                :created_at              => ant_prorroga.fecha_emision,
                                                                                :pago_comprometido_id    => pago_comprometido.id,
                                                                                :ejecutivo_matriculas_id => ejecutivo_matricula.id
                                                                            })
                                        puts "Prorroga: #{prorroga.id} - #{prorroga.fecha} creada".bold
                                    end

                                    pagos.each do |pago|
                                        intereses = ModelosAntiguos::Interes.all rut_al: pago.rut_al, letra_pl: pago.letra_pl
                                        interes = intereses.select{|x| x.fecha == pago.fecha}

                                        documento_venta = DocumentoVenta.first  :tipo                   => DocumentoVenta::BOLETA,
                                                                                :numero                 => pago.boleta_pg,
                                                                                :alumno_plan_estudio_id => al_pl_es.id,
                                                                                :institucion_sede_id    => institucion_sede.id

                                        if documento_venta.blank?
                                            documento_venta = DocumentoVenta.create :estado                  => DocumentoVenta::ENTREGADA,
                                                                                    :tipo                    => DocumentoVenta::BOLETA,
                                                                                    :fecha_emision           => pago.fecha,
                                                                                    :numero                  => pago.boleta_pg,
                                                                                    :monto                   => 0,
                                                                                    :plan_pago_id            => plan_pago.id,
                                                                                    :ejecutivo_matriculas_id => ejecutivo_matricula.id,
                                                                                    :alumno_plan_estudio_id  => al_pl_es.id,
                                                                                    :institucion_sede_id     => institucion_sede.id
                                        end

                                        documento_venta.update :monto => (documento_venta.monto + pago.valor_pg)

                                        Abono.create    :monto                   => pago.valor_pg,
                                                        :interes                 => interes.blank? ? 0 : interes.first.valor_acumulado_in,
                                                        :saldo                   => (pago.saldo_pg < 0 ? 0 : pago.saldo_pg),
                                                        :fecha                   => pago.fecha,
                                                        :estado                  => PagoComprometido::PAGADO,
                                                        :numero_documento        => pago.numero_documento,
                                                        :fecha_documento         => pago.fecha,
                                                        :medio_pago_id           => pago.medio_pago,
                                                        :banco_id                => pago.banco,
                                                        :tarjetas_credito        => pago.tarjeta_credito,
                                                        :pago_comprometido_id    => pago_comprometido.id,
                                                        :alumno_plan_estudio_id  => al_pl_es.id,
                                                        :ejecutivo_matriculas_id => ejecutivo_matricula.id,
                                                        :documento_venta_id      => documento_venta.id
                                    end # pagos.each
                                    cobranzas = ModelosAntiguos::Cobranza.all rut_al: plan.rut_al, letra_pl: plan.letra_pl, order: :id_cz.asc#, limit: limite, offset: offset

                                    cobranzas.each do |cobranza|
                                        puts "**** A IMPORTAR COBRANZA: #{cobranza.inspect}".yellow
                                        tipo_cobranza = cobranza.id_cb.nil? ? nil : CobranzaTipo.first_or_create({siaa_id: cobranza.id_cb},
                                                                                                                 {nombre: cobranza.tipo_cobranza.nombre_cb
                                                                                                                })
                                        cobranza_tipo_plaza_letra = cobranza.id_pz.nil? ? nil : CobranzaTipoPlazaLetra.first_or_create({siaa_id: cobranza.id_pz},
                                                                                                                                       {nombre: cobranza.tipo_plaza_letra.nombre_pz})
                                   
                                        pl_pg = cobranza.letra_pl.blank? ? nil : PagoComprometido.first(siaa_id: cobranza.letra_pl, siaa_id_sede_sync: SEDE_SYNC)
                                        pl_pg = pl_pg.plan_pago unless pl_pg.blank?

                                        next if pl_pg.blank?
                                        ejectv= cobranza.rut_em.blank? ? nil : ejecutivo(cobranza.rut_em, sede)
                                        inSed = InstitucionSede.first(siaa_id: cobranza.id_se)

                                        if ( cobr = Cobranza.first(siaa_id: cobranza.id_cz, siaa_id_sede_sync: SEDE_SYNC) ).blank?
                                            cobr = Cobranza.create  siaa_id: cobranza.id_cz, siaa_id_sede_sync: SEDE_SYNC,
                                                                    fecha: cobranza.fecha_cobranza, observacion: cobranza.observacion_cz,
                                                                    fecha_agendada: cobranza.fecha_nueva,
                                                                    pago_comprometido: pago_comprometido,
                                                                    ejecutivo_matriculas: ejectv,
                                                                    institucion_sede: inSed,
                                                                    cobranza_tipo: tipo_cobranza,
                                                                    cobranza_tipo_plaza_letra: cobranza_tipo_plaza_letra

                                            puts "++++++++++++ CREANDO COBRANZA: #{cobr.inspect}".bold
                                        end # if cobranza.first blank?
                                    end # cobranzas.each
                                end # planes.each

                                
                            end # MatriculaPlan.blank?
                            
                        end # for historial_matriculas
                        # next # ------------------- MATO LO SIGUIENTE, CODIGO VIEJO

                        # #================= ALUMNO ===========================
                        # if !(ma = persona.matriculas_alumno.last).blank? and !(apod = Usuario.first(siaa_id: ma.rut_ap)).blank?
                        #     #=============== APODERADO ==========================
                        #     if (apoderado = Apoderado.first(siaa_id: ma.rut_ap, siaa_id_sede_sync: SEDE_SYNC  )).blank? # Apoderado no existe
                        #         apoderado = Apoderado.new   es_alumno:          (ma.rut_al == ma.rut_ap),
                        #                                     documentos_presentados: Apoderado::NINGUNO,
                        #                                     siaa_id:            ma.rut_ap,
                        #                                     siaa_updated_at:    DateTime.now,
                        #                                     datos_personales:   apod, 
                        #                                     siaa_id_sede_sync:  SEDE_SYNC  
                        #         if apoderado.save
                        #             puts "--- Apoderado creado: #{ma.rut_ap} : #{c}".green
                        #         else
                        #             raise RuntimeError, "Error al crear el apoderado: #{apoderado.errors.inspect}".red

                        #         end # if apoderado.save
                        #     end # if check apoderado
                            
                        #     usuario = Usuario.first(siaa_id: ma.rut_al)
                    
                        #     next if usuario.nil? 
                            

                        #     # El usuario es un alumno
                        #     if (alumno = Alumno.first(siaa_id: ma.rut_al, siaa_id_sede_sync: SEDE_SYNC  )).blank? #no existe, se crea
                        #         alumno = Alumno.new     anio_ingreso:       (ma_in = persona.matriculas(id_ca: ma.id_ca).first.ano_ma) > 9999 ? ma_in/10 : (ma_in < 1000 ? ma_in.to_s+"0" : ma_in),
                        #                                 datos_personales:   usuario,
                        #                                 apoderado:          apoderado,
                        #                                 #modalidad:          -1,
                        #                                 #estado_academico:   -1,
                        #                                 #estado_financiero:  -1,
                        #                                 establecimiento_educacional: -1,
                        #                                 # tipo_ingreso:       -1,
                        #                                 tiene_certificado_nacimiento: false,
                        #                                 tiene_certificado_titulo: false,
                        #                                 tiene_licencia_e_media: false,
                        #                                 siaa_id:            ma.rut_al,
                        #                                 siaa_updated_at:    DateTime.now,
                        #                                 siaa_id_sede_sync:  SEDE_SYNC
                                
                        #         if alumno.save
                        #             puts "--- Alumno creado: #{ma.rut_al} : #{c}".magenta
                        #         else
                        #             raise RuntimeError, "Error al crear alumno: #{ma.rut_al} errores: #{alumno.errors.inspect}"
                        #         end # if alumno.save
                        #     end # if alumno no existe

                        #     # IMPORTANDO ALUMNO_PLAN_ESTUDIO


                        #     carreras_estudia = persona.matriculas(fields: [:id_ca, :ano_ma], :unique => true).map {|x| x.id_ca}.uniq

                        #     carreras_estudia.each do |id_ca|
                        #         puts ">> Analizando carrera: #{id_ca}".yellow

                        #         institucion_sede = (def_is = InstitucionSede.first(siaa_id: ma.id_se)).blank? ? InstitucionSede.get(default_sede) : def_is
                        

                        #         puts ">> Buscando rut_al #{alumno.siaa_id} id_se: #{ma.id_se}".blue.bold

                        #         ia_siaa = ModelosAntiguos::InscripcionAsignatura.first( id_ca: id_ca, 
                        #                                                                 rut_al: alumno.siaa_id)
                        #         if not ia_siaa.nil?
                        #             puts ">> IA_SIAA: #{ia_siaa.inspect}".red
                        #             #siaa_id_sede_sync:  SEDE_SYNC
                        #             plan_estudio = Asignatura.first(siaa_id: ia_siaa.id_as, siaa_id_sede_sync:  SEDE_SYNC).plan_estudio

                                    
                        #             primera_matricula   = persona.matriculas.first(id_ca: id_ca, order: [:ano_ma.desc, :sem_ma.desc])

                        #             puts "+++ Si no existe periodo creando: #{{anio: ma.ano_ma, semestre: ma.sem_ma}}".bold
                        #             periodo             = Periodo.first_or_create(  {anio: ma.ano_ma, semestre: ma.sem_ma}, 
                        #                                                             {estado: Periodo::CERRADO, siaa_updated_at: DateTime.now}
                        #                                                         )
                                    

                        #             periodo_isp         = Periodo.first_or_create( {anio: primera_matricula.ano_ma, semestre: primera_matricula.sem_ma}, 
                        #                                                            {estado: Periodo::CERRADO, siaa_updated_at: DateTime.now} )
                                                                                 

                        #             puts "---> InstitucionSede: #{institucion_sede.inspect}".red
                        #             puts "---> PlanEstudio: #{plan_estudio.inspect}".magenta
                        #             puts "---> Periodo: #{periodo.inspect}".yellow

                        #             institucion_sede_plan = InstitucionSedePlan.first_or_create({   institucion_sede_id:    institucion_sede.id, 
                        #                                                                             plan_estudio_id:        plan_estudio.id,
                        #                                                                             periodo_id:             periodo_isp.id,
                        #                                                                             modalidad:              InstitucionSedePlan::PRESENCIAL,
                        #                                                                             jornada:                JORNADA_SWITCH[ma.id_jo],
                        #                                                                             siaa_id_sede_sync:      SEDE_SYNC},
                        #                                                                         {
                        #                                                                             estado:                 (periodo_isp.anio > 2008 ? InstitucionSedePlan::ABIERTA : InstitucionSedePlan::CERRADA),
                        #                                                                             siaa_id:                id_ca,
                        #                                                                             siaa_updated_at:        DateTime.now
                        #                                                                         })                                                                              
                                    
                        #             institucion_sede_plan.update institucion_sede_id: institucion_sede.id if institucion_sede_plan.institucion_sede.nil?



                        #             if (al_pl_es = AlumnoPlanEstudio.first( institucion_sede_plan: institucion_sede_plan,
                        #                                                     alumno: alumno,
                        #                                                     periodo: periodo_isp,
                        #                                                     siaa_id_sede_sync:  SEDE_SYNC)).blank? # no existe, lo creo

                        #                 al_pl_es = AlumnoPlanEstudio.new    anio_ingreso: primera_matricula.ano_ma,
                        #                                                     institucion_sede_plan: institucion_sede_plan,
                        #                                                     alumno: alumno,
                        #                                                     periodo: periodo_isp,
                        #                                                     siaa_updated_at: DateTime.now,
                        #                                                     siaa_id_sede_sync:  SEDE_SYNC,
                        #                                                     es_trabajador:      (ma.rut_al == ma.rut_ap)
                        #                 if al_pl_es.save
                        #                     puts "---- AlumnoPlanEstudio: #{al_pl_es.alumno.datos_personales.nombre} - #{institucion_sede_plan.periodo.nombre} - #{al_pl_es.institucion_sede_plan.plan_estudio.nombre}".green
                        #                 else
                        #                     puts "institucion_sede: #{institucion_sede.inspect}".magenta
                        #                     puts "institucion_sede_plan: #{institucion_sede_plan.inspect}".yellow
                        #                     puts "plan_estudio: #{plan_estudio.inspect}".red
                        #                     puts "periodo: #{periodo_isp.inspect}".magenta
                        #                     raise RuntimeError, "Error al crear alumno plan estudio: #{al_pl_es.errors.inspect}".red
                        #                 end
                        #             end

                        #             if al_pl_es
                        #                 ModelosAntiguos::InscripcionAsignatura.all(rut_al: alumno.siaa_id).each do |insc_asig|

                        #                     if (inscrito = AlumnoInscritoSeccion.first(siaa_id: insc_asig.oid, siaa_id_sede_sync:  SEDE_SYNC)).blank? # Creo
                        #                         per_insc = Periodo.first_or_create( {anio: insc_asig.ano_in,    semestre: insc_asig.sem_in },
                        #                                                             {estado: Periodo::CERRADO,  siaa_updated_at: DateTime.now})


                        #                         inst_sed = InstitucionSede.first siaa_id: insc_asig.id_se
                                                
                        #                         #TODO: Revisar seleccion de secciones, no estoy seguro que esté bien 
                        #                         if (seccion = Seccion.first(institucion_sede: inst_sed,
                        #                                                     periodo: per_insc,
                        #                                                     numero: insc_asig.seccion_in,
                        #                                                     siaa_id_as: insc_asig.id_as,
                        #                                                     siaa_id_sede_sync:  SEDE_SYNC)).blank?

                        #                             asig_imp = ModelosAntiguos::AsignaturaImpartida.first   id_ca: insc_asig.id_ca,
                        #                                                                                     id_as: insc_asig.id_as,
                        #                                                                                     seccion_ai: insc_asig.seccion_in,
                        #                                                                                     id_se: insc_asig.id_se,
                        #                                                                                     sem_ai: insc_asig.sem_in,
                        #                                                                                     ano_ai: insc_asig.ano_in



                        #                             seccion = Seccion.create    estado:             (per_insc == periodo_actual ? Seccion::ABIERTA : Seccion::CERRADA),
                        #                                                         cupos:              asig_imp.blank? ? 0 : asig_imp.cupos_ai,
                        #                                                         numero:             asig_imp.blank? ? 0 : asig_imp.seccion_ai,
                        #                                                         institucion_sede:   inst_sed, 
                        #                                                         periodo:            per_insc, 
                        #                                                         siaa_id_ca:         insc_asig.id_ca,
                        #                                                         siaa_id_as:         insc_asig.id_as,
                        #                                                         siaa_updated_at:    DateTime.now,
                        #                                                         siaa_id_sede_sync:  SEDE_SYNC

                        #                             puts "+++ Seccion creada: #{seccion.to_yaml}".bold
                        #                         end

                        #                         conj_malla = ModelosAntiguos::ConjuntoMalla.first(id_ma: al_pl_es.plan_estudio.siaa_id_ma, id_as: insc_asig.id_as)
                        #                         asignat = Asignatura.first_or_create({  siaa_id: insc_asig.id_as, siaa_id_sede_sync:  SEDE_SYNC},
                        #                                                              {  nombre:             "Asignatura #{insc_asig.id_as} no existente",
                        #                                                                 plan_estudio:       al_pl_es.institucion_sede_plan.plan_estudio,
                        #                                                                 semestre:           conj_malla.nil? ? nil : conj_malla.id_ni,
                        #                                                                 siaa_updated_at:    DateTime.now
                        #                                                              })

                        #                         puts "***> Asignatura: #{asignat.inspect}".red
                        #                         puts "***> Insc_asig: #{insc_asig.inspect}".blue.bold
                        #                         puts "***> Seccion: #{seccion.inspect}".yellow
                                                
                        #                         seccion_dictada = SeccionDictada.first_or_create({  asignatura_id:      asignat.id,
                        #                                                                             siaa_id_ca:         insc_asig.id_ca,
                        #                                                                             seccion_id:         seccion.id,
                        #                                                                             siaa_id_sede_sync:  SEDE_SYNC},  
                        #                                                                             {siaa_updated_at:   DateTime.now})
                                                                                                
                                                
                        #                         inscrito = AlumnoInscritoSeccion.new    seccion_dictada_id:     seccion_dictada.id, 
                        #                                                                 alumno_plan_estudio_id: al_pl_es.id,
                        #                                                                 estado:                 AlumnoInscritoSeccion::INSCRITA,
                        #                                                                 siaa_id:                insc_asig.oid,
                        #                                                                 siaa_updated_at:        DateTime.now,
                        #                                                                 siaa_id_sede_sync:      SEDE_SYNC
                        #                         if inscrito.save
                        #                             puts ">>> Alumno: #{al_pl_es.alumno.datos_personales.nombre} inscrito en seccion: #{inscrito.seccion_dictada.seccion.sigla} - #{inscrito.seccion_dictada.asignatura.nombre}".magenta
                        #                         else
                        #                             puts ">>> Periodo: #{periodo.inspect}".magenta
                        #                             puts ">>> Seccion: #{seccion.inspect}".yellow
                        #                             puts ">>> Asignatura: #{asignat.inspect}".red
                        #                             puts ">>> SeccionDictada: #{seccion_dictada.inspect}".magenta
                        #                             puts ">>> AlumnoInscritoSeccion: #{inscrito.inspect}".yellow
                        #                             raise RuntimeError, "Error al inscribir alumno en asignatura: #{inscrito.errors.inspect}".red
                        #                         end

                        #                     end


                        #                     #puts "--- IMPORTAR PLANIFICACION DE NOTAS para #{al_pl_es.alumno.datos_personales.nombre} ---".red

                        #                     #begin
                        #                         seccion = inscrito.seccion_dictada.seccion
                        #                         cal_ev = ModelosAntiguos::CalendarioEvaluacion.all(id_ca: id_ca, 
                        #                                     id_as: insc_asig.id_as, 
                        #                                     sem_ce: insc_asig.sem_in, 
                        #                                     ano_ce: insc_asig.ano_in,
                        #                                     seccion_ce: insc_asig.seccion_in,
                        #                                     id_tn: [PlanificacionCalificacion::PRUEBA_PARCIAL, PlanificacionCalificacion::PRUEBA_GLOBAL],
                        #                                     order: :nro_ce.desc)

                        #                         cal_ev.each do |ce|
                                                

                        #                             if (plan_calif = PlanificacionCalificacion.first(siaa_id: ce.oid, siaa_id_sede_sync:  SEDE_SYNC)).blank?
                        #                                 ponderacion = ce.ponderacion_ce

                        #                                 if ponderacion > 1.0 && ponderacion < 2.0
                        #                                     ponderacion = ponderacion-1.0
                        #                                 end

                        #                                 if ponderacion >= 100 && ponderacion <= 1000
                        #                                     ponderacion = ponderacion / 1000
                        #                                 end

                        #                                 if ponderacion > 1000
                        #                                     ponderacion = ponderacion / 10000
                        #                                 end

                        #                                 if ponderacion > 1 and ponderacion < 100
                        #                                     ponderacion = ponderacion/100
                        #                                 end


                                                        



                        #                                 plan_calif = PlanificacionCalificacion.create(  ponderacion:            (ce.id_te == PlanificacionCalificacion::SUMATIVA ? ponderacion : 0),
                        #                                                                                 fecha_comprometida:     ce.fh_ce,
                        #                                                                                 nombre:                 ce.id_tn,
                        #                                                                                 seccion_id:             seccion.id,
                        #                                                                                 tipo:                   ce.id_te,
                        #                                                                                 numero:                 ce.nro_ce,
                        #                                                                                 siaa_id:                ce.oid,
                        #                                                                                 siaa_updated_at:        DateTime.now,
                        #                                                                                 siaa_id_sede_sync:      SEDE_SYNC)
                                                                    
                                                        
                        #                                 puts ">> Calificacion creada de #{al_pl_es.alumno.datos_personales.nombre}: #{plan_calif.to_yaml}".green.bold
                        #                             end

                                                
                        #                             ModelosAntiguos::Nota.all(  id_ca:          insc_asig.id_ca,
                        #                                                         id_as:          insc_asig.id_as,
                        #                                                         seccion_no:     insc_asig.id_se,
                        #                                                         nro_ce:         plan_calif.numero,
                        #                                                         id_se:          insc_asig.id_se,
                        #                                                         sem_no:         insc_asig.sem_in,
                        #                                                         ano_no:         insc_asig.ano_in,
                        #                                                         id_tn:          plan_calif.nombre.to_i,
                        #                                                         rut_al:         alumno.siaa_id
                        #                                                      ).each do |nota|

                        #                                 if (calif_parcial = CalificacionParcial.first(siaa_id: nota.oid, siaa_id_sede_sync:  SEDE_SYNC)).blank?

                        #                                     calif_parcial = CalificacionParcial.create  calificacion:                   nota.nota_no,
                        #                                                                                 alumno_inscrito_seccion_id:     inscrito.id,
                        #                                                                                 planificacion_calificacion_id:  plan_calif.id,
                        #                                                                                 siaa_id:                        nota.oid,
                        #                                                                                 siaa_updated_at:                DateTime.now,
                        #                                                                                 siaa_id_sede_sync:              SEDE_SYNC

                                                            
                        #                                     puts ">>> Calificacion parcial creada: #{calif_parcial.to_yaml}".blue.bold
                        #                                 end

                        #                             end
                        #                         end

                        #                         # Para asociar promedios, notas 
                        #                         ModelosAntiguos::Nota.all(  id_ca:          insc_asig.id_ca,
                        #                                                     id_as:          insc_asig.id_as,
                        #                                                     seccion_no:     insc_asig.seccion_in,
                        #                                                     id_se:          insc_asig.id_se,
                        #                                                     sem_no:         insc_asig.sem_in,
                        #                                                     ano_no:         insc_asig.ano_in,
                        #                                                     id_tn:          [PlanificacionCalificacion::EXAMEN_DE_REPETICION, PlanificacionCalificacion::NOTA_FINAL, PlanificacionCalificacion::NOTA_DE_PRESENTACION, PlanificacionCalificacion::EXAMEN_FINAL],
                        #                                                     rut_al:         alumno.siaa_id
                        #                                                 ).each do |nota|
                                                    

                        #                             if( (inscrito.send(NOTAS_FINALES_SWITCH[nota.id_tn]) != nota.nota_no) or (nota.id_tn == PlanificacionCalificacion::NOTA_FINAL && inscrito.estado.nil?) )
                        #                                 ins_upd = {NOTAS_FINALES_SWITCH[nota.id_tn] => nota.nota_no}

                        #                                 if nota.id_tn == PlanificacionCalificacion::NOTA_FINAL && !nota.nota_no.nil?
                        #                                     ins_upd[:estado] = (nota.nota_no >= 4 ? AlumnoInscritoSeccion::APROBADA : AlumnoInscritoSeccion::REPROBADA)
                        #                                 end
                        #                                 inscrito.update! ins_upd
                        #                                 puts ">>> Alumno: #{al_pl_es.alumno.datos_personales.nombre} de seccion: #{inscrito.seccion_dictada.seccion.sigla} - #{inscrito.seccion_dictada.asignatura.nombre} con #{NOTAS_FINALES_SWITCH[nota.id_tn].to_s} : #{nota.nota_no} - Estado: #{inscrito.estado}".red.bold


                        #                             end
                        #                         end
                                                

                        #                     #rescue DataMapper::SaveFailureError => e
                        #                     #    log_error e
                        #                     #end



                        #                 end
                        #             end

                        #         end # if not ia_siaa.nil?

                        #     end # carreras_estudia.each
                        # else
                        #     puts "--- El apoderado o matricula no existe, asi que continuo nomas : #{persona.rut_pe} , #{c}".red
                        # end # if existe apoderado y matrícula
                    end
                    aFile = File.new(Rails.root.to_s + "/sync_errores.txt", "w")
                    aFile.write(file_text + "\n")
                    aFile.close
                    #raise RuntimeError, "No guardo...".red
                end # termino transacción

                rescue NameError => e
                    log_error e
                rescue RuntimeError => e
                    log_error e
                rescue DataMapper::SaveFailureError => e
                    log_error e
                rescue Exception => e
                log_error e
            end

            puts "limit: #{limit} offset: #{offset}"
            offset += limit
        end
            
    end

    def self.import_usuarios_pendientes #TODO: Está a medias [AV]
        #DataMapper::Logger.new(STDOUT, :debug)
        limit = 50
        offset = 0
        
        max = ModelosAntiguos::Persona.count
        puts " > Total: #{max}"#.blue
        
        #Cobranza.all.destroy!
        
        file_text = ""
        
    
        file_text << "-- Vuelta con offset: #{offset}"
        puts "-- Vuelta con offset: #{offset}".red

        ruts = [16994950,17396428,   18388042,16761095,13510400,16329740,16988246]

        tipo_pagos_matricula = ModelosAntiguos::TipoPago.all( alias_tp: 'MATRICULA' ).map{|x| x.id_tp}
        tipo_pagos_arancel   = ModelosAntiguos::TipoPago.all( alias_tp: 'ARANCEL' ).map{|x| x.id_tp}
        tipo_pagos_normativa = ModelosAntiguos::TipoPago.all( alias_tp: 'NORMATIVA' ).map{|x| x.id_tp}

        begin
            Usuario.transaction do
               
                periodo_actual = Periodo.first(anio: PERIODO_ANIO_ACTUAL, semestre: PERIODO_SEMESTRE_ACTUAL)
                
                puts "--- IMPORTANDO ALUMNOS ---"

                default_sede = DEFAULT_SEDES[SEDE_SYNC]
                sede = Sede.get SEDE_ID[SEDE_SYNC]

                tipos_pagos_para_plan = (ModelosAntiguos::TipoPago.all(:alias_tp.like => 'MATRICULA')+ModelosAntiguos::TipoPago.all(:alias_tp.like => 'ARANCEL%')+ModelosAntiguos::TipoPago.all(:alias_tp.like => 'NORMATIVA')).map{|x| x.id_tp}

                personas_array = ModelosAntiguos::Persona.all(rut_pe: ruts)#, limit: 9999, offset: 2154)#, offset: 1600)

                puts "Personas: #{personas_array.inspect}".yellow.bold

                file_text << "Cantidad de personas (buenas o malas): #{personas_array.size}\n".red.bold
                personas_validas = []
                #personas_array = ModelosAntiguos::Matricula.all(ano_ma: 2012).alumnos
                #personas_array = ModelosAntiguos::Matricula.all(rut_al: 17815935).alumnos

                

                # VUELTA PARA USUARIOS
                puts "VUELTA DE USUARIOS".red
                c = 0
                personas_array.each do |persona|
                    puts "====================================================== [#{c+1} / #{personas_array.length}]".red
                    c += 1
                    debo_eliminar = true
                    rut = persona.parsear_rut
                    rut = rut + "0" if rut.last == "-"

                    # Elimino información antigua del alumno antes de insertar todo lo nuevo...
                    us = Usuario.first(:rut => rut)
                    al = us.alumno unless us.blank?
                    #apo = al.apoderado unless al.blank?
                    ape = al.alumno_plan_estudio(:siaa_updated_at.not => nil) unless al.blank?
                    if ape.blank?
                        debo_eliminar = false
                        file_text << "\n=============================\n".yellow.bold
                        file_text << "!!! --- No elimino los datos del usuario: #{us.inspect} ya que es un registro nuevo\n".red
                        file_text << "\n=============================\n".yellow.bold
                    end
                    ais = ape.links_secciones_inscritas unless ape.blank?
                    acp = ais.calificaciones_parciales unless ais.blank?
                    matr = ape.matricula_plan unless ape.blank?
                    p_p = matr.planes_pagos unless matr.blank?
                    bcob= p_p.bitacora_cobranzas unless p_p.blank?
                    pagare = p_p.pagares unless p_p.blank?
                    p_c = p_p.pagos_comprometidos unless p_p.blank?
                    cob = p_c.cobranzas unless p_c.blank?
                    p_r = p_c.prorrogas unless p_c.blank?
                    abonos = p_c.abonos unless p_c.blank?
                    
                    d_v = []
                    d_v += p_p.documentos_ventas unless p_p.blank?
                    d_v += ape.documentos_venta unless ape.blank?

                    unless abonos.blank?
                        abonos.each do |abono|
                            d_v +=  [abono.documento_venta]
                        end
                    end

                    abonos = []
                    abonos.each{ |x| abonos += x }
                    d_v.each{|dv| dv.abonos.each {|x| abonos += [x]} }

                    # file_text << "\n=============================\n".bold
                    # file_text << "Eliminando datos de usuario: #{us.inspect}"
                    debo_eliminar = false unless ape.blank?
                    if debo_eliminar
                        unless abonos.blank?
                            # file_text << "Eliminando #{abonos.inspect}\n"
                            abonos.each do |x| 
                                x.certificado.destroy! unless x.certificado.blank?
                                x.destroy!
                            end
                        end

                        unless d_v.blank?
                            # file_text << "Eliminando #{d_v.inspect}\n"
                            d_v.each{ |x| x.destroy! }
                        end
                        unless cob.blank?
                            # file_text << "Eliminando #{cob.inspect}\n"
                            cob.destroy! 
                        end
                        unless bcob.blank?
                            bcob.destroy!
                        end
                        unless p_r.blank?
                            p_r.destroy!
                        end
                        unless p_c.blank?
                            # file_text << "Eliminando #{p_c.inspect}\n"
                            p_c.destroy! 
                        end

                        unless pagare.blank?
                            # file_text << "Eliminando #{pagare.inspect}\n"
                            pagare.destroy! 
                        end
                        unless p_p.blank?
                            # file_text << "Eliminando #{p_p.inspect}\n"
                            p_p.destroy!    
                        end
                        unless matr.blank?
                            # file_text << "Eliminando #{matr.inspect}\n"
                            matr.destroy!   
                        end
                        unless acp.blank?
                            # file_text << "Eliminando #{acp.inspect}\n"
                            acp.destroy!    
                        end
                        unless ais.blank?
                            # file_text << "Eliminando #{ais.inspect}\n"
                            ais.destroy!    
                        end
                        unless ape.blank?
                            # file_text << "Eliminando #{ape.inspect}\n"
                            ape.destroy!    
                        end
                    end
                    
                    # file_text << "\n=============================\n".red.bold
                    #apo.destroy! unless apo.blank?
                    #al.destroy! unless al.blank?

                    if persona.parsear_rut.blank? || persona.parsear_nombres.blank? || persona.parsear_apellidos.blank?
                        puts "Rut parseado: #{persona.parsear_rut}"
                        puts "La persona no es válida #{persona.inspect}".red.bold
                        next 
                    end

                    
                    ma = persona.matriculas.first

                    institucion_sede = (ma.blank? || (def_is = InstitucionSede.first(siaa_id: ma.id_se)).blank?) ? InstitucionSede.get(default_sede) : def_is
                    institucion_sede = InstitucionSede.get(default_sede) if institucion_sede.blank?


                    if persona.matriculas_alumno.size.eql? 0
                        puts "---- Persona #{rut} no tiene matrículas, así que no lo guardo".red
                        next 
                    end

                    personas_validas << persona

                    #===================== USUARIO =======================
                    if (usuario = Usuario.first(rut: rut)).blank? #no existe, crea un nuevo registro

                        usuario = Usuario.new self.usuario_hash(persona, sede) 

                        if usuario.save
                            puts "------ Usuario creado: #{rut} : #{c}".green
                        else
                            puts "------ Error al crear usuario: #{rut} \nValidaciones: #{usuario.errors.inspect}".red
                            puts "---------- Datos originales: #{persona.inspect}".red
                            raise RuntimeError, "Hubo un error al crear el usuario".red
                        end # usuario.save
                    else # es un registro existente
                        unless usuario.siaa_id.blank? # Actualizo solo si se sincronizó
                            usuario.update self.usuario_hash(persona, sede)
                            puts "------ Actualizando usuario: #{rut} : #{c}".yellow
                        end
                        # institucion_sede    = (ma = persona.matriculas.last).blank? ? default_sede : InstitucionSede.first(siaa_id: ma.id_se)
                        # # verifico si el usuario fue modificado
                        # if str_date(usuario.siaa_trans_date) != persona.fecha_transaccion_str # cambió, así que actualizo
                        #     puts "------ Actualizando usuario: #{rut} : #{c}".yellow
                        #     usuario.update self.usuario_hash(persona, sede)
                        # else
                        #     puts "------ Usuario: #{rut} no ha cambiado : #{c}".magenta
                        # end
                    end # usuario.blank?
                    #================== FIN USUARIO =======================
                end # personas_array.each

                puts "VUELTA DE ALUMNOS Y APODERADOS".red

                file_text << "Cantidad de alumnos a importar: #{personas_validas.size}\n".blue.bold

                c = 0
                personas_validas.each do |persona|
                    puts "====================================================== [#{c+1} / #{personas_validas.length}]".bold
                    c += 1
                    # Obtengo apoderados del alumno
                    apoderados = ModelosAntiguos::Persona.all rut_pe: persona.matriculas_alumno.map{|x| x.rut_ap}
                    puts "Persona actual: #{persona.parsear_rut}".bold
                    puts "Apoderados del alumno: #{apoderados.inspect}".yellow

                    # Matrículas
                    matriculas = persona.matriculas_alumno
                    historial_matriculas = ModelosAntiguos::Matricula.all rut_al: persona.rut_pe, order: [:ano_ma.asc, :sem_ma.asc]
                    #matriculas.uniq{|x| x.ano_ma}.sort_by{|x| x.ano_ma}.each do |matricula| # Recorro matrículas y voy creando apoderado
                    
                    for i in 0..(historial_matriculas.size-1)
                        puts "||||||||||||||||||| HM: #{i}/#{historial_matriculas.size-1}".blue.bold
                        hm = historial_matriculas[i]
                        hm_siguiente = historial_matriculas.size < i ? historial_matriculas[i] : nil
                        
                        ma = matricula = hm #ModelosAntiguos::Matricula.first rut_al: hm.rut_al, sem_ma: hm.sem_, ano_ma: hm.ano_hm

                        if ma.blank?
                            file_text << "\n=====================\n"
                            file_text << "El alumno: #{hm.rut_al} no tiene matricula pero si historial.. ?".red
                            file_text << "\n=====================\n"
                            next
                        end

                        # ============= Busco el plan de estudios
                        busqueda = {}
                        busqueda[:siaa_id_ca_concepcion] = ma.id_ca if SEDE_SYNC == SEDE_CONCEPCION
                        busqueda[:siaa_id_ca_chillan]    = ma.id_ca if SEDE_SYNC == SEDE_CHILLAN
                        busqueda[:siaa_id_ca_bosque]     = ma.id_ca if SEDE_SYNC == SEDE_ELBOSQUE
                        busqueda[:siaa_id_ca_nunoa]      = ma.id_ca if SEDE_SYNC == SEDE_NUNOA
                        busqueda[:siaa_id_ca_vina]       = ma.id_ca if SEDE_SYNC == SEDE_VINA

                        
                        primera_matricula   = matriculas.first(id_ca: ma.id_ca, order: [:ano_ma.asc, :sem_ma.asc])

                        institucion_sede = (primera_matricula.blank? || (def_is = InstitucionSede.first(siaa_id: primera_matricula.id_se)).blank?) ? InstitucionSede.get(default_sede) : def_is
                        institucion_sede = InstitucionSede.get(default_sede) if institucion_sede.blank?

                        malla = ModelosAntiguos::Malla.first    :ano_ini_ma.gte => primera_matricula.ano_ma,   :sem_ini_ma.gte => primera_matricula.sem_ma,
                                                                :ano_fin_ma.lte => primera_matricula.ano_ma,   :sem_fin_ma.lte => primera_matricula.sem_ma,
                                                                :id_ca => primera_matricula.id_ca,             :id_se => primera_matricula.id_se

                        busqueda[:siaa_id_ma] = malla.id_ma unless malla.blank?

                        plan_estudio = PlanEstudio.first busqueda


                        puts "---===+******* PLAN ESTUDIO: #{plan_estudio.inspect}".blue.bold
                        if plan_estudio.blank?
                            file_text << "\n=============================\n"
                            file_text << "Plan Estudio para id_ca: #{primera_matricula.id_ca} y id_ma: #{malla.id_ma unless malla.blank?} no existe\n".red.bold
                            file_text << "Persona: #{persona.inspect}\n"
                            next
                        end # pe.blank?

                        # ============== Creo al apoderado
                        if (apoderado = Apoderado.first(siaa_id: ma.rut_ap)).blank? # Apoderado no existe
                            per_ap = ModelosAntiguos::Persona.first rut_pe: ma.rut_ap
                            if per_ap.blank?
                                file_text << "\n==========================\n"
                                file_text << "Matricula sin apoderado: #{ma.inspect}\n".red.bold 
                                file_text << "Se matricula con el mismo alumno como apoderado: #{persona.inspect}\n".blue.bold

                                per_ap = ModelosAntiguos::Persona.first rut_pe: ma.rut_al                            
                            end
                            apod = Usuario.first_or_create( {rut: per_ap.parsear_rut}, self.usuario_hash(per_ap, sede, Usuario::APODERADO) )

                            apoderado = Apoderado.new   es_alumno:          (ma.rut_al == per_ap.rut_pe),
                                                        documentos_presentados: Apoderado::NINGUNO,
                                                        siaa_id:            ma.rut_ap,
                                                        siaa_updated_at:    DateTime.now,
                                                        datos_personales:   apod, 
                                                        siaa_id_sede_sync:  SEDE_SYNC  
                            if apoderado.save
                                puts "--- Apoderado creado: #{ma.rut_ap} : #{c}".green
                            else
                                raise RuntimeError, "Error al crear el apoderado: #{apoderado.errors.inspect}".red
                            end # if apoderado.save
                        end # if check apoderado

                        usuario = Usuario.first(siaa_id: ma.rut_al)
                        next if usuario.nil?  # Mato el recorrido, sería raro que no exista un usuario del alumno

                        # El usuario es un alumno
                        if (alumno = Alumno.first(siaa_id: ma.rut_al) ).blank? #no existe, se crea
                            alumno = Alumno.new     anio_ingreso:       (ma_in = matriculas.first(id_ca: ma.id_ca).ano_ma) > 9999 ? ma_in/10 : (ma_in < 1000 ? ma_in.to_s+"0" : ma_in),
                                                    datos_personales:   usuario,
                                                    apoderado:          apoderado,
                                                    #modalidad:          -1,
                                                    #estado_academico:   -1,
                                                    #estado_financiero:  -1,
                                                    establecimiento_educacional: -1,
                                                    # tipo_ingreso:       -1,
                                                    tiene_certificado_nacimiento: false,
                                                    tiene_certificado_titulo: false,
                                                    tiene_licencia_e_media: false,
                                                    siaa_id:            ma.rut_al,
                                                    siaa_updated_at:    DateTime.now,
                                                    siaa_id_sede_sync:  SEDE_SYNC
                            
                            if alumno.save
                                puts "--- Alumno creado: #{ma.rut_al} : #{c}".magenta
                            else
                                raise RuntimeError, "Error al crear alumno: #{ma.rut_al} errores: #{alumno.errors.inspect}"
                            end # if alumno.save
                        end # if alumno no existe


                        periodo_isp         = Periodo.first_or_create(  {anio: primera_matricula.ano_ma, semestre: primera_matricula.sem_ma}, 
                                                                        {estado: Periodo::CERRADO, siaa_updated_at: DateTime.now} )
                        periodo_matricula   = Periodo.first_or_create(  {anio: matricula.ano_ma, semestre: matricula.sem_ma}, 
                                                                        {estado: Periodo::CERRADO, siaa_updated_at: DateTime.now} )
                        # Asocio al alumno a algún plan
                        institucion_sede_plan = InstitucionSedePlan.first_or_create({   institucion_sede_id:    institucion_sede.id, 
                                                                                        plan_estudio_id:        plan_estudio.id,
                                                                                        periodo_id:             periodo_isp.id,
                                                                                        modalidad:              DISTANCIA_ID_CA.include?(primera_matricula.id_ca) ? InstitucionSedePlan::DISTANCIA : InstitucionSedePlan::PRESENCIAL,
                                                                                        jornada:                JORNADA_SWITCH[ma.id_jo],
                                                                                        siaa_id_sede_sync:      SEDE_SYNC},
                                                                                    {
                                                                                        estado:                 (periodo_isp.anio > 2008 ? InstitucionSedePlan::ABIERTA : InstitucionSedePlan::CERRADA),
                                                                                        siaa_id:                primera_matricula.id_ca,
                                                                                        siaa_updated_at:        DateTime.now
                                                                                    })                                                                              
                                
                        institucion_sede_plan.update institucion_sede_id: institucion_sede.id if institucion_sede_plan.institucion_sede.nil?



                        if (al_pl_es = AlumnoPlanEstudio.first( institucion_sede_plan: institucion_sede_plan,
                                                                alumno: alumno,
                                                                periodo: periodo_isp)).blank? # no existe, lo creo

                            al_pl_es = AlumnoPlanEstudio.new    anio_ingreso: primera_matricula.ano_ma,
                                                                institucion_sede_plan: institucion_sede_plan,
                                                                alumno: alumno,
                                                                periodo: periodo_isp,
                                                                siaa_updated_at: DateTime.now,
                                                                siaa_id_sede_sync:  SEDE_SYNC,
                                                                es_trabajador:      (ma.rut_al == ma.rut_ap)
                            if al_pl_es.save
                                puts "---- AlumnoPlanEstudio: #{al_pl_es.alumno.datos_personales.nombre} - #{institucion_sede_plan.periodo.nombre} - #{al_pl_es.institucion_sede_plan.plan_estudio.nombre}".green
                            else
                                puts "institucion_sede: #{institucion_sede.inspect}".magenta
                                puts "institucion_sede_plan: #{institucion_sede_plan.inspect}".yellow
                                puts "plan_estudio: #{plan_estudio.inspect}".red
                                puts "periodo: #{periodo_isp.inspect}".magenta
                                raise RuntimeError, "Error al crear alumno plan estudio: #{al_pl_es.errors.inspect}".red
                            end
                        end

                        #tipo_matricula = matriculas.select{|x| x.ano_ma === matricula.ano_ma}.size > 1 ? MatriculaPlan::PROFESIONAL_DOS_SEMESTRES : MatriculaPlan::PROFESIONAL_UN_SEMESTRE

                        semestres = 0
                        if hm_siguiente.nil?
                            # cuento directo cuantas matrículas hay
                            semestres = matriculas.select{|x| x.ano_ma >= hm.ano_ma and x.sem_ma >= hm.sem_ma}.size
                        else # veo directamente el siguiente
                            if hm.sem_hm == hm_siguiente.sem_hm && hm.ano_hm == (hm_siguiente.ano_hm - 1) # Es el siguiente año
                                semestres = 2
                            else 
                                if matriculas.select{|x| x.sem_ma == (hm.sem_hm.eql?(1) ? 2 : 1) and x.ano_ma == (hm.sem_hm.eql?(1) ? hm.ano_hm : (hm.ano_hm+1))}.size > 0
                                    semestres = 2   
                                else
                                    semestres = 1
                                end
                            end
                        end # hm_siguiente.nil?
                        tipo_matricula = PlanEstudio.buscar_nivel_malla plan_estudio.id, semestres

                        if institucion_sede_plan.modalidad.eql? InstitucionSedePlan::DISTANCIA
                            tipo_matricula = MatriculaPlan::DISTANCIA_1_A_4_NIVEL
                        end

                        tipo_matricula = MatriculaPlan::SALIDA_INTERMEDIA unless ModelosAntiguos::SalidaIntermedia.all( rut_al: persona.rut_pe, ano_si: matricula.ano_ma, sem_si: matricula.sem_ma ).blank?
                        tipo_matricula = MatriculaPlan::DISTANCIA_SALIDA_INTERMEDIA_COMPLETA if institucion_sede_plan.modalidad.eql?(InstitucionSedePlan::DISTANCIA) and tipo_matricula.eql?(MatriculaPlan::SALIDA_INTERMEDIA)
                        

                        puts "!!!!____----- Matrículas ya registradas del periodo: #{MatriculaPlan.all(periodo_id: periodo_matricula.id, alumno_plan_estudio_id: al_pl_es.id).inspect}".red.bold

                        ejecutivo_matricula = ejecutivo(matricula.rut_em, sede)

                        if MatriculaPlan.first(siaa_id: matricula.oid).blank?
                            mat_planes = ModelosAntiguos::Plan.all rut_al: matricula.rut_al, ano_pl: matricula.ano_ma, sem_pl: matricula.sem_ma
                            next if mat_planes.blank?


                            mat_plan = MatriculaPlan.create     siaa_id:                    matricula.oid,
                                                                periodo_id:                 periodo_matricula.id,
                                                                alumno_plan_estudio_id:     al_pl_es.id,
                                                                siaa_updated_at:            DateTime.now,
                                                                siaa_id_sede_sync:          SEDE_SYNC,
                                                                created_at:                 matricula.fecha_matricula,
                                                                ejecutivo_matriculas_id:    ejecutivo_matricula.id
                                                            #apoderado_id:           apoderado.id,
                                                            #tipo:                   tipo_matricula, # Se cambió a PlanPago
                                                            #matricula:              hist_mat.nil? ? 0 : hist_mat.matricula,
                                                            #arancel:                hist_mat.nil? ? 0 : hist_mat.arancel
                            puts "\n=======> Creado Matricula Plan id: #{mat_plan.id} oid: #{mat_plan.siaa_id} periodo: #{periodo_matricula.anio}-#{periodo_matricula.semestre}\n".bold
                            puts "\n=====> Matricula: #{matricula.inspect}".red

                            hist_mat = ModelosAntiguos::HistorialMatricula.first rut_al: matricula.rut_al, id_ca: matricula.id_ca, ano_hm: matricula.ano_ma, sem_hm: matricula.sem_ma


                                                        


                            plan_pago = PlanPago.create estado:                     PlanPago::VIGENTE,
                                                        tipo:                       tipo_matricula,
                                                        #normativa: X #TODO: Fal    ta...
                                                        matricula:                  hist_mat.nil? ? mat_planes.select{|x| tipo_pagos_matricula.include?(x.id_tp)}.sum(&:valor_pl) : hist_mat.matricula,
                                                        arancel:                    hist_mat.nil? ? mat_planes.select{|x| tipo_pagos_arancel.include?(x.id_tp)}.sum(&:valor_pl) : hist_mat.valor_ara_real_hm,
                                                        descuento_aplicado:         hist_mat.nil? ? 0 : hist_mat.descuento_arancel,
                                                        arancel_total:              hist_mat.nil? ? mat_planes.select{|x| tipo_pagos_arancel.include?(x.id_tp)}.sum(&:valor_pl) : hist_mat.arancel_total,
                                                        matricula_plan:             mat_plan,
                                                        ejecutivo_matriculas_id:    ejecutivo_matricula.id,
                                                        apoderado_id:               apoderado.id,
                                                        periodo_id:                 periodo_matricula.id,
                                                        descuento_id:               ModelosAntiguos::Beneficio.buscar_descuento(rut_al: matricula.rut_al, sem_be: matricula.sem_ma, ano_be: matricula.ano_ma),
                                                        siaa_rut_al:                matricula.rut_al,
                                                        siaa_ano_ma:                matricula.ano_ma,
                                                        siaa_sem_ma:                matricula.sem_ma,
                                                        siaa_updated_at:            DateTime.now,
                                                        created_at:                 hm.fh_ma

                            bitacoras = ModelosAntiguos::BitacoraCobranza.all(rut_al: matricula.rut_al, id_ca: matricula.id_ca, ano_bc: matricula.ano_ma)
                            
                            bitacoras.each do |bitacora|
                                BitacoraCobranza.first_or_create({ siaa_id: bitacora.id_bc },
                                                                 { 
                                                                    :ejecutivo_matriculas_id => ejecutivo(bitacora.rut_em, institucion_sede.sede.id).id,
                                                                    :plan_pago_id            => plan_pago.id,
                                                                    :fecha                   => bitacora.fh_bc,
                                                                    :observacion             => bitacora.detalle,
                                                                    :created_at              => bitacora.fecha
                                                                 })
                            end

                            planes = ModelosAntiguos::Plan.all rut_al: matricula.rut_al, ano_pl: matricula.ano_ma, sem_pl: matricula.sem_ma # Importo cuotas de pagaré
                            


                            cuotas_arancel = cuotas_matricula = cuotas_normativa = 0

                            planes.each do |plan|
                                tipo_pago = ModelosAntiguos::TipoPago.first id_tp: plan.id_tp
                                next if tipo_pago.blank?
                                cuotas_matricula += 1   if tipo_pago.alias_tp.include? "MATRICULA"
                                cuotas_arancel += 1     if tipo_pago.alias_tp.include? "ARANCEL"
                                cuotas_normativa += 1   if tipo_pago.alias_tp.include? "NORMATIVA"
                            end
                            unless planes.blank?
                                next if hist_mat.blank?
                                pagare = Pagare.create  :estado                  => Pagare::VIGENTE,
                                                        :numero                  => hist_mat.pagare_ag.blank? ? 1 : hist_mat.pagare_ag,
                                                        :monto                   => hist_mat.valor_pag_hm.blank? ? 0 : hist_mat.valor_pag_hm,
                                                        :cuotas_arancel          => cuotas_arancel,
                                                        :cuotas_matricula        => cuotas_matricula,
                                                        :cuotas_normativa        => cuotas_normativa,
                                                        :fecha_inicio            => planes.first.fh_venc_pl,
                                                        :fecha_termino           => planes.last.fh_venc_pl,
                                                        :plan_pago_id            => plan_pago.id,
                                                        :ejecutivo_matriculas_id => ejecutivo_matricula.id,
                                                        :alumno_plan_estudio_id  => al_pl_es.id,
                                                        :institucion_sede_id     => institucion_sede.id
                            end

                            planes.each do |plan|
                                pagos = ModelosAntiguos::Pago.all rut_al: plan.rut_al, letra_pl: plan.letra_pl, order: [:fh_pg.asc]

                                estado = PagoComprometido::COMPROMETIDO

                                if pagos.size > 0
                                    estado = pagos.last.saldo_pg.eql?(0) ? PagoComprometido::PAGADO : PagoComprometido::COMPROMETIDO_CON_ABONOS 
                                end

                                unless estado.eql? PagoComprometido::PAGADO
                                    if pagos.size.eql?(0) && plan.fh_venc_pl < Date.today
                                        estado = PagoComprometido::ATRASADO
                                    end
                                    if pagos.size > 0 && plan.fh_venc_pl > pagos.last.fecha && !pagos.last.saldo_pg.eql?(0)
                                        estado = PagoComprometido::ATRASADO
                                    end
                                end
                            

                                pago_comprometido = PagoComprometido.create :numero_cuota            => plan.secuencia_letra_pl,
                                                                            :tipo_cuota              => PagoComprometido::PAGARE,
                                                                            :estado                  => estado,
                                                                            :fecha_vencimiento       => plan.fh_venc_pl,
                                                                            :fecha_ultimo_abono      => pagos.blank? ? nil : pagos.last.fh_pg,
                                                                            :fecha_pago_realizado    => estado.eql?(PagoComprometido::PAGADO) ? pagos.last.fh_pg : nil,
                                                                            :monto                   => plan.valor_pl,
                                                                            :saldo                   => (p_tmp = (pagos.blank? ? plan.valor_pl : pagos.last.saldo_pg)) < 0 ? 0 : p_tmp,
                                                                            :centro_costo            => plan.centro_costos,
                                                                            :institucion_sede_id     => institucion_sede.id,
                                                                            :plan_pago_id            => plan_pago.id,
                                                                            :ejecutivo_matriculas_id => ejecutivo_matricula.id,
                                                                            :pagare_id               => pagare.blank? ? nil : pagare.id,
                                                                            :siaa_id                 => plan.letra_pl,
                                                                            :siaa_id_sede_sync       => SEDE_SYNC

                                ant_prorrogas = ModelosAntiguos::Prorroga.all(letra_pl: plan.letra_pl, rut_al: plan.rut_al)

                                ant_prorrogas.each do |ant_prorroga|
                                    prorroga = Prorroga.first_or_create({ siaa_id: ant_prorroga.id_pr },
                                                                        { 
                                                                            :fecha                   => ant_prorroga.fh_prorroga_pr, 
                                                                            :created_at              => ant_prorroga.fecha_emision,
                                                                            :pago_comprometido_id    => pago_comprometido.id,
                                                                            :ejecutivo_matriculas_id => ejecutivo_matricula.id
                                                                        })
                                    puts "Prorroga: #{prorroga.id} - #{prorroga.fecha} creada".bold
                                end

                                pagos.each do |pago|
                                    intereses = ModelosAntiguos::Interes.all rut_al: pago.rut_al, letra_pl: pago.letra_pl
                                    interes = intereses.select{|x| x.fecha == pago.fecha}

                                    documento_venta = DocumentoVenta.first  :tipo                   => DocumentoVenta::BOLETA,
                                                                            :numero                 => pago.boleta_pg,
                                                                            :alumno_plan_estudio_id => al_pl_es.id,
                                                                            :institucion_sede_id    => institucion_sede.id

                                    if documento_venta.blank?
                                        documento_venta = DocumentoVenta.create :estado                  => DocumentoVenta::ENTREGADA,
                                                                                :tipo                    => DocumentoVenta::BOLETA,
                                                                                :fecha_emision           => pago.fecha,
                                                                                :numero                  => pago.boleta_pg,
                                                                                :monto                   => 0,
                                                                                :plan_pago_id            => plan_pago.id,
                                                                                :ejecutivo_matriculas_id => ejecutivo_matricula.id,
                                                                                :alumno_plan_estudio_id  => al_pl_es.id,
                                                                                :institucion_sede_id     => institucion_sede.id
                                    end

                                    documento_venta.update :monto => (documento_venta.monto + pago.valor_pg)

                                    Abono.create    :monto                   => pago.valor_pg,
                                                    :interes                 => interes.blank? ? 0 : interes.first.valor_acumulado_in,
                                                    :saldo                   => (pago.saldo_pg < 0 ? 0 : pago.saldo_pg),
                                                    :fecha                   => pago.fecha,
                                                    :estado                  => PagoComprometido::PAGADO,
                                                    :numero_documento        => pago.numero_documento,
                                                    :fecha_documento         => pago.fecha,
                                                    :medio_pago_id           => pago.medio_pago,
                                                    :banco_id                => pago.banco,
                                                    :tarjetas_credito        => pago.tarjeta_credito,
                                                    :pago_comprometido_id    => pago_comprometido.id,
                                                    :alumno_plan_estudio_id  => al_pl_es.id,
                                                    :ejecutivo_matriculas_id => ejecutivo_matricula.id,
                                                    :documento_venta_id      => documento_venta.id
                                end # pagos.each
                                cobranzas = ModelosAntiguos::Cobranza.all rut_al: plan.rut_al, letra_pl: plan.letra_pl, order: :id_cz.asc#, limit: limite, offset: offset

                                cobranzas.each do |cobranza|
                                    puts "**** A IMPORTAR COBRANZA: #{cobranza.inspect}".yellow
                                    tipo_cobranza = cobranza.id_cb.nil? ? nil : CobranzaTipo.first_or_create({siaa_id: cobranza.id_cb},
                                                                                                             {nombre: cobranza.tipo_cobranza.nombre_cb
                                                                                                            })
                                    cobranza_tipo_plaza_letra = cobranza.id_pz.nil? ? nil : CobranzaTipoPlazaLetra.first_or_create({siaa_id: cobranza.id_pz},
                                                                                                                                   {nombre: cobranza.tipo_plaza_letra.nombre_pz})
                               
                                    pl_pg = cobranza.letra_pl.blank? ? nil : PagoComprometido.first(siaa_id: cobranza.letra_pl, siaa_id_sede_sync: SEDE_SYNC)
                                    pl_pg = pl_pg.plan_pago unless pl_pg.blank?

                                    next if pl_pg.blank?
                                    ejectv= cobranza.rut_em.blank? ? nil : ejecutivo(cobranza.rut_em, sede)
                                    inSed = InstitucionSede.first(siaa_id: cobranza.id_se)

                                    if ( cobr = Cobranza.first(siaa_id: cobranza.id_cz, siaa_id_sede_sync: SEDE_SYNC) ).blank?
                                        cobr = Cobranza.create  siaa_id: cobranza.id_cz, siaa_id_sede_sync: SEDE_SYNC,
                                                                fecha: cobranza.fecha_cobranza, observacion: cobranza.observacion_cz,
                                                                fecha_agendada: cobranza.fecha_nueva,
                                                                pago_comprometido: pago_comprometido,
                                                                ejecutivo_matriculas: ejectv,
                                                                institucion_sede: inSed,
                                                                cobranza_tipo: tipo_cobranza,
                                                                cobranza_tipo_plaza_letra: cobranza_tipo_plaza_letra

                                        puts "++++++++++++ CREANDO COBRANZA: #{cobr.inspect}".bold
                                    end # if cobranza.first blank?
                                end # cobranzas.each
                            end # planes.each

                            
                        end # MatriculaPlan.blank?
                        
                    end # for historial_matriculas
                    
                end
                aFile = File.new(Rails.root.to_s + "/sync_errores.txt", "w")
                aFile.write(file_text + "\n")
                aFile.close
                #raise RuntimeError, "No guardo...".red
            end # termino transacción

            rescue NameError => e
                log_error e
            rescue RuntimeError => e
                log_error e
            rescue DataMapper::SaveFailureError => e
                log_error e
            rescue Exception => e
            log_error e
        end

        puts "limit: #{limit} offset: #{offset}"
        offset += limit
    
            
    end

    def self.calcular_semestre_alumnos
        #DataMapper::Logger.new(STDOUT, :debug)

        sin_plan_estudio = Usuario.all( :siaa_id.not => nil, alumno: nil, rol: nil) + Usuario.all( :siaa_id.not => nil, alumno: {alumno_plan_estudio: nil} )
        
        sin_plan_estudio.each do |usuario|
            Usuario.transaction do 
                begin
                    if usuario.ejecutivo_matriculas.blank? && usuario.docente.blank?
                        if usuario.alumno.blank?
                            puts "Tratando de destruir: #{usuario.inspect}".red
                            unless usuario.apoderado.blank?
                                puts "Es un apoderado, paso..."
                                next
                            end
                            puts "Lo destruyo".yellow
                            usuario.destroy!
                        else
                            if usuario.alumno.alumno_plan_estudio.blank?
                                puts "Alumno a eliminar: #{usuario.inspect}"
                                apo_id = usuario.alumno.apoderado_id
                                
                                apo = Apoderado.get(apo_id)
                                unless apo.blank?
                                    apo_user_id = apo.usuario_id
                                    if apo.alumnos.alumno_plan_estudio.blank?
                                        puts "Es un apoderado con alumnos, borro alumnos y apoderado con su usuario".yellow

                                        apo.alumnos(alumno_plan_estudio: nil).destroy!
                                        next unless apo.alumnos.blank?
                                        #apo.destroy!
                                        us_apod = Usuario.get(apo_user_id)
                                        if us_apod.docente.blank? && us_apod.ejecutivo_matriculas.blank?
                                            next unless us_apod.apoderado.alumnos.alumno_plan_estudio.blank?
                                            next unless us_apod.alumno.blank?
                                            next unless us_apod.apoderado.planes_pago.blank?
                                            us_apod.apoderado.destroy! #unless us_apod.apoderado.blank?
                                            us_apod.destroy!
                                        else
                                            puts "Es docente, no lo borro".bold
                                        end
                                    end
                                    if usuario.apoderado.blank?
                                        puts "No tiene apoderado, destruyo".yellow
                                        usuario.alumno.destroy! unless usuario.alumno.blank?   
                                        usuario.destroy!
                                    else
                                        puts "Es un apoderado, no lo toco".bold
                                    end
                                else
                                    if usuario.docente.blank? && usuario.ejecutivo_matriculas.blank?
                                        usuario.alumno.destroy!
                                        usuario.destroy!
                                    end
                                end
                            end
                        end

                        puts "===========================\r".green.bold
                    end
                rescue Exception => e
                    puts "Se cayo"
                end
            end
            
        end
    

        limit = 50
        offset = 0
        
        max = Alumno.count
        puts " > Total: #{max}"#.blue
        
        while offset < (max + limit)
        
            Alumno.all(:siaa_id.not => nil, limit: limit, offset: offset).each do |alumno|
                begin
                    puts "Alumno: #{alumno.datos_personales.nombre}".yellow

                    alumno.planes_estudiados[:planes_estudiados].each do |plan|
                            puts "Plan Estudio: #{plan[:alumno_plan_estudio_id]}".bold
                            al_ins_sec = AlumnoInscritoSeccion.all alumno_plan_estudio_id: plan[:alumno_plan_estudio_id]
                            al_pl_est  = al_ins_sec.alumno_plan_estudio.first

                            semestre   = al_ins_sec.seccion_dictadas.seccion.asignaturas.max(:semestre)
                            puts "Semestre actual: #{semestre}".blue
                            
                            #alumno.update       semestre: semestre      if alumno.semestre    != semestre
                            al_pl_est.update    semestre: semestre      if al_pl_est.semestre != semestre

                    end
                rescue NoMethodError => e
                    puts "Error 1 #{e.inspect}"
                rescue
                    puts "Error 2"
                end
            end

            offset += limit

        end
        rescue NameError => e
            log_error e
        rescue RuntimeError => e
            log_error e
        rescue DataMapper::SaveFailureError => e
            log_error e
        rescue Exception => e
            log_error e
    end

    def self.anular_cuotas_antiguas

        ModelosAntiguos::Plan.all( nula_letra_pl: true, order: [:fh_trans_pl.desc] ).each do |p|
            puts p.inspect.bold
            PagoComprometido.transaction do
                pc = PagoComprometido.first( siaa_id: p.letra_pl, siaa_id_sede_sync: SEDE_SYNC )
                if !pc.blank?
                    puts "Tiene pago comprometido, actualizo estado: #{pc.inspect}".yellow.bold
                    pc.update fecha_anulacion: p.fh_trans_pl, estado: PagoComprometido::ANULADO
                end
            end
        end
    end

    def self.importar_profesores
        limit = 10000
        offset = 20000 
        datos = Seccion.all(siaa_id_sede_sync:  SEDE_SYNC, limit: limit, offset: offset)

        count = 0
        datos.each do |seccion|
            count += 1
            puts "===================================================================== [#{count} / #{datos.length}]".blue.bold
            sede = seccion.institucion_sede
            periodo = seccion.periodo
            horario = ModelosAntiguos::Horario.first    id_se: sede.siaa_id,        id_ca: seccion.siaa_id_ca, 
                                                        id_as: seccion.siaa_id_as,  seccion_ho: seccion.numero, 
                                                        ano_ho: periodo.anio,       sem_ho: periodo.semestre,
                                                        :rut_pe.gt => 0
          

            if !horario.blank? && !(profesor = horario.profesor).blank?
                

                if (usuario = Usuario.first siaa_id: profesor.rut_pe).blank?
                    usuario = Usuario.create usuario_hash(horario.profesor, sede, Usuario::DOCENTE)
                    puts "+++ Usuario para el profesor #{profesor.rut_pe} no existe, lo creo".bold
                end

                if (usuario.tipo < Usuario::DOCENTE)
                    usuario.update rol_id: 2, tipo: Usuario::DOCENTE
                end

                if (docente = Docente.first datos_personales: usuario, siaa_id_sede_sync:  SEDE_SYNC).blank?
                    docente = Docente.create    en_ejercicio:       (horario.ano_ho == 2012), 
                                                datos_personales:   usuario,
                                                siaa_updated_at:    DateTime.now,
                                                siaa_id_sede_sync:  SEDE_SYNC
                    puts "+++++ Docente para el usuario #{profesor.rut_pe} creado #{docente.id}".bold
                end
                docente.update en_ejercicio: true if horario.ano_ho == 2012 && !docente.en_ejercicio

                if seccion.docente.blank?
                    seccion.update docente: docente 
                    puts "**** Seccion: #{seccion.id} docente #{horario.rut_pe} actualizado".yellow
                else
                    puts "==== Seccion (#{seccion.id}) id_ca: #{horario.id_ca} id_as: #{horario.id_as} seccion: #{horario.seccion_ho} ya tenia docente: #{horario.rut_pe}".red
                end

            end
        end

        # count = 0
        # ModelosAntiguos::ProfesorAsignatura.all(order: [:ano_pra.desc, :sem_pra.desc]).each do |prof_asig|
        #     count += 1
        #     if (profesor = prof_asig.profesor).blank?
        #         puts "!!! La asignatura #{prof_asig.asignatura.nombre} no tiene profesor".red
        #     else
        #         institucion_sede = InstitucionSede.first(siaa_id: prof_asig.id_se)
        #         periodo          = Periodo.first(anio: prof_asig.ano_pra, semestre: prof_asig.sem_pra)

        #         if (usuario = Usuario.first siaa_id: profesor.rut_pe).blank?
        #             usuario = Usuario.create usuario_hash(profesor, institucion_sede, Usuario::DOCENTE)
        #             puts "+++ Usuario para el profesor #{profesor.rut_pe} no existe, lo creo".blue.bold
        #         end

        #         if (docente = Docente.first datos_personales: usuario).blank?
        #             docente = Docente.create    en_ejercicio:       (prof_asig.ano_pra == 2012), 
        #                                         datos_personales:   usuario,
        #                                         siaa_updated_at:    DateTime.now
        #             puts "+++++ Docente para el usuario #{profesor.rut_pe} creado #{docente.id}".bold
        #         end

        #         seccion = Seccion.first     institucion_sede:   institucion_sede, 
        #                                     periodo:            periodo, 
        #                                     numero:             prof_asig.seccion_pra,
        #                                     siaa_id_ca:         prof_asig.id_ca,
        #                                     siaa_id_as:         prof_asig.id_as

        #         if seccion.blank? 
        #             puts "!!! seccion de asignatura: #{prof_asig.id_as} no existe".red
        #         else
        #             if seccion.docente.blank?
        #                 seccion.update docente: docente 
        #                 puts "**** Seccion: #{seccion.id} docente #{prof_asig.rut_pra} actualizado".yellow
        #             else
        #                 puts "==== Seccion (#{seccion.id}) id_ca: #{prof_asig.id_ca} id_as: #{prof_asig.id_as} seccion: #{prof_asig.seccion_pra} ya tenia docente: #{prof_asig.rut_pra}".yellow
        #             end
        #         end
        #     end

        #     puts "Registro #{count}".blue
        # end
    end

    def self.actualizar_rol_docente
        ModelosAntiguos::ProfesorAsignatura.all(order: [:ano_pra.desc, :sem_pra.desc]).each do |prof_asig|
            if (profesor = prof_asig.profesor)
                if (usuario = Usuario.first siaa_id: profesor.rut_pe)
                    if usuario.update rol_id: 2, tipo: Usuario::DOCENTE
                        puts "Docente: #{usuario.rut} actualizado" 
                    end
                end
            end
        end
    end

    def self.actualizar_tipo_administrativo
        ModelosAntiguos::Derecho.all.each do |derecho|
            if !(usuario = Usuario.first siaa_id: derecho.rut_us).blank? && usuario.tipo < Usuario::ADMINISTRATIVO
                unless usuario.tipo.eql?(Usuario::DOCENTE)
                    usuario.update tipo: Usuario::ADMINISTRATIVO 
                    puts "Cambiando a administrativo #{usuario.nombre}".bold
                end
            end
        end
    end

    def self.importar_homologacion_convalidacion
        #DataMapper::Logger.new(STDOUT, :debug)

        siaa_id_ca_val = {
            SEDE_CONCEPCION => :siaa_id_ca_concepcion,
            SEDE_VINA       => :siaa_id_ca_vina,
            SEDE_NUNOA      => :siaa_id_ca_nunoa,
            SEDE_ELBOSQUE   => :siaa_id_ca_bosque,
            SEDE_CHILLAN    => :siaa_id_ca_chillan
        }[SEDE_SYNC]
        default_sede = DEFAULT_SEDES[SEDE_SYNC]

        datos = ModelosAntiguos::Convalidacion.all(order: :oid.desc)
        c = 0
        datos.each do |conv|
            c += 1
            puts "============================================= [#{c}/#{datos.length}]".blue.bold
            Alumno.transaction do
                periodo = Periodo.first_or_create({ anio:       conv.ano_co, semestre:      conv.sem_co }, {estado: Periodo::CERRADO})
                usuario = Usuario.first(siaa_id: conv.rut_al)

                if !usuario.blank? && !(alumno = usuario.alumno).blank?
                    puts "Alumno: #{usuario.nombre} rut: #{usuario.rut}".yellow

                    puts "#{alumno.alumno_plan_estudio.institucion_sede_plan.plan_estudio.length} Planes estudio: #{alumno.alumno_plan_estudio.institucion_sede_plan.plan_estudio.inspect}"

                    if alumno.alumno_plan_estudio.institucion_sede_plan.plan_estudio.length.eql?(0)
                        puts "No hay planes de estudio disponibles...."
                        next 
                    end

                    al_pl_est = alumno.alumno_plan_estudio.institucion_sede_plan

                    pl_est  = al_pl_est.plan_estudio.length.eql?(1) ? al_pl_est.plan_estudio.first : al_pl_est.plan_estudio.first( "#{siaa_id_ca_val}" => conv.id_ca) #, siaa_id_sede_sync:  SEDE_SYNC
                    puts "Plan estudio: #{pl_est.inspect} Carrera a convalidar: #{conv.id_ca}".red

                    next if pl_est.blank?


                    in_s_pl = alumno.alumno_plan_estudio.institucion_sede_plan.first plan_estudio: pl_est#, siaa_id_sede_sync:  SEDE_SYNC

                    # ins_sed = InstitucionSede.first siaa_id:    conv.id_se
                    # ins_sed = InstitucionSede.get(default_sede) if ins_sed.blank?
                    ins_sed = in_s_pl.institucion_sede

                    puts "Institucion Sede: #{ins_sed.nombre}"


                    
                    #InstitucionSedePlan.first siaa_id: conv.id_ca, institucion_sede: ins_sed 

                    al_pl_es = alumno.alumno_plan_estudio.first institucion_sede_plan: in_s_pl#, siaa_id_sede_sync:  SEDE_SYNC

                    next if al_pl_es.nil?

                    puts "Ins Sede Plan #{in_s_pl.id} nombre: #{in_s_pl.plan_estudio.nombre} "
                    
                    

                    puts "Alumno plan estudio: #{al_pl_es.inspect}"

                    if (seccion = al_pl_es.secciones_cursadas.seccion.first(  siaa_id_ca: conv.id_ca, siaa_id_as:    conv.id_as, 
                                                                    institucion_sede: ins_sed, periodo: periodo,
                                                                    numero: Seccion::CONVALIDADA_HOMOLOGADA, siaa_id_sede_sync:  SEDE_SYNC )).blank?
                        seccion = Seccion.create    estado: Seccion::CERRADA, cupos: 40, numero: Seccion::CONVALIDADA_HOMOLOGADA, 
                                                    siaa_id_ca: conv.id_ca, siaa_id_as: conv.id_as, 
                                                    institucion_sede: ins_sed, periodo: periodo,
                                                    siaa_updated_at: DateTime.now,
                                                    siaa_id_sede_sync:  SEDE_SYNC
                    end
                    
                    asig_ant = ModelosAntiguos::Asignatura.first id_as: conv.id_as, id_ca: conv.id_ca
                    de_con = ModelosAntiguos::DetalleConvalidacion.first    rut_al: conv.rut_al, id_se: conv.id_se,
                                                                            id_ca: conv.id_ca, id_as: conv.id_as,
                                                                            sem_dc: conv.sem_co, ano_dc: conv.ano_co

                    malla = ModelosAntiguos::Malla.first id_ca: conv.id_ca, :ano_ini_ma.lte => conv.ano_co, :ano_fin_ma.gte => conv.ano_co
                    malla = ModelosAntiguos::Malla.first id_ca: conv.id_ca if malla.blank?

                    conj_malla = ModelosAntiguos::ConjuntoMalla.first( id_as: conv.id_as, id_ca: conv.id_ca, id_ma: malla.id_ma )
                    conj_malla = ModelosAntiguos::ConjuntoMalla.first( id_as: conv.id_as, id_ca: conv.id_ca) if conj_malla.blank?



                    _data = { siaa_id: conv.id_as, plan_estudio: pl_est }#,  siaa_id_sede_sync:  SEDE_SYNC }

                    if (asignatura = Asignatura.first _data).blank?

                        asignatura = Asignatura.create _data.merge({ codigo: asig_ant.id_as, nombre: t_str(asig_ant.nombre_as), semestre: conj_malla.id_ni })
                    end

                    next if asignatura.blank?

                    if (seccion_dictada = seccion.links_secciones_dictadas.last(siaa_id_sede_sync:  SEDE_SYNC)).blank?
                        
                        seccion_dictada = SeccionDictada.create asignatura: asignatura, seccion: seccion, siaa_id_ca: conv.id_ca, siaa_id_sede_sync:  SEDE_SYNC
                    end

                    puts "Seccion dictada: #{seccion_dictada.inspect}".blue
                    if (al_ins_sec = AlumnoInscritoSeccion.first    seccion_dictada_id: seccion_dictada.id, alumno_plan_estudio_id: al_pl_es.id, siaa_id_sede_sync:  SEDE_SYNC ).blank?
                        al_ins_sec = AlumnoInscritoSeccion.new   seccion_dictada_id: seccion_dictada.id, alumno_plan_estudio_id: al_pl_es.id,
                                                                siaa_updated_at: DateTime.now, siaa_id_sede_sync:  SEDE_SYNC
                        puts al_ins_sec.errors.inspect.yellow
                        al_ins_sec.save                                                           
                    end
                    

                    unless [AlumnoInscritoSeccion::CONVALIDADA, AlumnoInscritoSeccion::HOMOLOGADA].include? al_ins_sec.estado

                        media = ModelosAntiguos::Media.first id_dn: conv.id_dn

                        inst_ext = InstitucionExterna.first_or_create(  {siaa_id: conv.id_dn},
                                                                        {nombre: clean_str(media.nombre),
                                                                         codigo: media.codigo_dn,
                                                                         domicilio: clean_str(media.domicilio_dn),
                                                                         sector: clean_str(media.sector_dn),
                                                                         siaa_updated_at: DateTime.now})

                        conv_hom = ConvalidacionHomologacion.first_or_create( { siaa_rut_al: conv.rut_al, siaa_id_ca: conv.id_ca,
                                                                                siaa_id_as: conv.id_as, 
                                                                                periodo_id: Periodo.first(anio: conv.ano_co, semestre: conv.sem_co).id, 
                                                                                siaa_id_se: conv.id_se, siaa_id_sede_sync:  SEDE_SYNC,
                                                                                alumno_plan_estudio_id: al_pl_es.id},
                                                                             {  carrera_convalidada: t_str(conv.carrera_co2),
                                                                                semestre_cursa: (de_con.sem_cursa unless de_con.blank?),
                                                                                anio_cursa: (de_con.ano_cursa unless de_con.blank?),
                                                                                nro_documento: conv.nro_docto_co,
                                                                                tipo: conv.tipo,
                                                                                institucion_externa_id: inst_ext.id
                                                                             })

                        al_ins_sec.update   estado:                     (conv.id_tv == 1 ? AlumnoInscritoSeccion::CONVALIDADA : AlumnoInscritoSeccion::HOMOLOGADA), 
                                            convalidacion_homologacion: conv_hom, 
                                            nota_final:                 (de_con.nota_dc unless de_con.blank?)
                    end
                    
                    puts "Secciones convalidada: #{al_ins_sec.seccion_dictada.asignatura.nombre}".red
                
                end
            end # Alumno.transaction
        end

        rescue DataMapper::SaveFailureError => e

            log_error e
        rescue Exception => e
            log_error e
    end


    def self.importar_matriculas_y_pagos
        limite = 1000
        offset = 0

        datos = ModelosAntiguos::HistorialMatricula.all(order: :ano_hm.desc, limit: limite, offset: offset)
        #datos = ModelosAntiguos::Matricula.all(rut_al: 17815935)

        datos.each do |hist_mat|
            mat_ant = ModelosAntiguos::Matricula.first rut_al: hist_mat.rut_al, ano_ma: hist_mat.ano_hm, sem_ma: hist_mat.sem_hm
            next if mat_ant.nil?||mat_ant.rut_al.nil?
            hist_mat = ModelosAntiguos::HistorialMatricula.first rut_al: mat_ant.rut_al, sem_hm: mat_ant.sem_ma, ano_hm: mat_ant.ano_ma, id_ca: mat_ant.id_ca

            puts "hist_mat: #{hist_mat.inspect} rut_al: #{mat_ant.rut_al} sem: #{mat_ant.sem_ma} ano: #{mat_ant.ano_ma} id_ca: #{mat_ant.id_ca}".blue.bold
            periodo = Periodo.first anio: mat_ant.ano_ma, semestre: mat_ant.sem_ma

            if (mat_plan = MatriculaPlan.first siaa_id: mat_ant.oid).blank? # No existe, creo
                usuario = Usuario.first siaa_id: mat_ant.rut_al

                if usuario.blank?
                    puts "***** NO EXISTE USUARIO: #{mat_ant.rut_al}".red
                else
                    if (alumno = usuario.alumno).blank?
                        puts "***** NO EXISTE ALUMNO #{mat_ant.rut_al}".red
                    else
                        ap_usr = Usuario.first( siaa_id: mat_ant.rut_ap )
                        apoderado = ap_usr.nil? ? nil : ap_usr.apoderado
                        
                        if apoderado.blank?
                            puts "***** NO EXISTE APODERADO PARA ALUMNO: #{mat_ant.rut_al} rut ap: #{mat_ant.rut_ap}".red
                            next 
                        end

                        planes_estudios = PlanEstudio.all(fields: [:id], siaa_id_ca: mat_ant.id_ca ).map {|x| x.id}

                        ins_se_planes = InstitucionSedePlan.all(fields: [:id], plan_estudio_id: planes_estudios ).map {|x| x.id }

                        al_pl_est = AlumnoPlanEstudio.first( alumno: alumno, institucion_sede_plan_id: ins_se_planes )

                        if al_pl_est.blank?
                            al_pl_est = AlumnoPlanEstudio.last( alumno: alumno )
                        end

                        if al_pl_est.blank?
                            puts "NO EXISTE PLAN ESTUDIO periodo: #{periodo.inspect} \n alumno: #{alumno.inspect}".red
                            # puts "MATRICULA: #{mat_ant.inspect}".blue.bold
                            # puts "ALUMNO: al: #{usuario.inspect} alumno: #{alumno.inspect}".yellow
                            next
                        end

                        mat_plan = MatriculaPlan.create siaa_id:                mat_ant.oid,
                                                        #tipo:                   MatriculaPlan::PROFESIONAL_UN_SEMESTRE,
                                                        periodo_id:             periodo.id,
                                                        # apoderado_id:           apoderado.id,
                                                        alumno_plan_estudio_id: al_pl_est.id,
                                                        siaa_updated_at:        DateTime.now,
                                                        siaa_id_sede_sync:      SEDE_SYNC,
                                                        created_at:             mat_ant.fecha_matricula,
                                                        matricula:              hist_mat.nil? ? 0 : hist_mat.matricula,
                                                        arancel:                hist_mat.nil? ? 0 : hist_mat.arancel
                        puts "=======> Matricula Plan id: #{mat_plan.id} oid: #{mat_plan.siaa_id} periodo: #{periodo.anio}-#{periodo.semestre}".bold

                        
                    end
                end
            end

            # ======= IMPORTO PLANES DE PAGOS
            unless mat_plan.blank?
                puts "+++++ IMPORTANDO PLAN PAGO PARA #{mat_ant.rut_al} semestre: #{mat_ant.ano_ma}-#{mat_ant.sem_ma}".yellow

                plan_pagos = ModelosAntiguos::Plan.all  rut_al: mat_ant.rut_al, 
                                                        ano_pl: mat_ant.ano_ma, 
                                                        sem_pl: mat_ant.sem_ma, 
                                                        order: :nro_cuota_cp.desc
                puts "===== CANTIDAD DE PAGOS COMPROMETIDOS #{plan_pagos.length}".blue

                if plan_pagos.length > 0 # Existe un plan de pagos, así que creo el registro y sus pagos comprometidos
                    perso_em = ModelosAntiguos::Persona.first username_pe: plan_pagos.first.user_pl
                    usr_eje = Usuario.first siaa_id: perso_em.rut_pe unless perso_em.nil?
                    ejecutivo = usr_eje.nil? ? nil : EjecutivoMatriculas.first_or_create({datos_personales: usr_eje})

                    next if ejecutivo.nil?

                    institucion_sede = InstitucionSede.first(siaa_id: plan_pagos.first.id_se)

                    total_pagos = 0
                    plan_pagos.each do |plan|
                        total_pagos += plan.valor_pl if !plan.blank? && !plan.valor_pl.blank?
                    end

                    # Falta revisar esto... no está importando las cuotas
                    puts "********* BUSCANDO CUOTAS PAGARE: #{plan_pagos.first.pagare_ag}".magenta.bold

                    pagare = nil


                    
                    plan_pago = PlanPago.first_or_create({  siaa_rut_al:    mat_ant.rut_al, 
                                                            siaa_ano_ma:    mat_ant.ano_ma, 
                                                            siaa_sem_ma:    mat_ant.sem_ma,
                                                         },
                                                         {  
                                                            monto_documentado: total_pagos,
                                                            #institucion_sede: institucion_sede,
                                                            siaa_updated_at: DateTime.now,
                                                            matricula_plan_id: mat_plan.id,
                                                            created_at: plan_pagos.first.fecha
                                                        })

                    if (pagare = Pagare.first( numero: plan_pagos.first.pagare_ag ) ).nil?
                        cuotas_pagares = ModelosAntiguos::Plan.all pagare_ag: plan_pagos.first.pagare_ag, rut_al: mat_ant.rut_al, order: :nro_cuota_cp.desc

                        pagare = Pagare.create  numero: plan_pagos.first.pagare_ag,
                                                estado: Pagare::CANCELADO_POR_PAGO,
                                                monto: cuotas_pagares.map(&:valor_pl).inject(:+),
                                                cuotas_arancel: cuotas_pagares.length,
                                                fecha_inicio: cuotas_pagares.first.fh_venc_pl,
                                                fecha_termino: cuotas_pagares.last.fh_venc_pl, 
                                                institucion_sede: institucion_sede,
                                                ejecutivo_matriculas: ejecutivo,
                                                alumno_plan_estudio: mat_plan.alumno_plan_estudio,
                                                plan_pago: plan_pago
                    end

                    plan_pagos.each do |plan|
                        if (pago_comprometido = PagoComprometido.first(siaa_id: plan.letra_pl, siaa_id_sede_sync:  SEDE_SYNC)).blank?

                            pago_comprometido = PagoComprometido.create siaa_id: plan.letra_pl, 
                                                                        numero_cuota: plan.nro_cuota_cp,
                                                                        fecha_vencimiento: plan.fh_venc_pl,
                                                                        monto: plan.valor_pl,
                                                                        siaa_id_plan: plan.letra_pl,
                                                                        tipo_cuota: plan.tipo_cuota,
                                                                        institucion_sede_id: institucion_sede.id,
                                                                        plan_pago_id: plan_pago.id,
                                                                        siaa_id_sede_sync:  SEDE_SYNC,
                                                                        centro_costo: plan.centro_costos,
                                                                        ejecutivo_matriculas: ejecutivo
                            puts "No existe pago oid: #{plan.letra_pl} creado\n#{pago_comprometido.to_yaml}".bold


                        end


                    end

                end
            end
        end

        puts "======================== IMPORTACION DE COBRANZAS: TODAS! ==============================".red

        cobranzas = ModelosAntiguos::Cobranza.all order: :id_cz.desc, limit: limite, offset: offset

        puts "===== CANTIDAD DE COBRANZAS A IMPORTAR #{cobranzas.length}".blue


        cobranzas.each do |cobranza|
            puts "**** A IMPORTAR COBRANZA: #{cobranza.inspect}".yellow
            tipo_cobranza = cobranza.id_cb.nil? ? nil : CobranzaTipo.first_or_create({siaa_id: cobranza.id_cb},
                                                                                     {nombre: cobranza.tipo_cobranza.nombre_cb
                                                                                    })
            cobranza_tipo_plaza_letra = cobranza.id_pz.nil? ? nil : CobranzaTipoPlazaLetra.first_or_create({siaa_id: cobranza.id_pz},
                                                                                                           {nombre: cobranza.tipo_plaza_letra.nombre_pz})
       
            pl_pg = cobranza.letra_pl.blank? ? nil : PagoComprometido.first(siaa_id: cobranza.letra_pl, siaa_id_sede_sync: SEDE_SYNC)
            pl_pg = pl_pg.plan_pago unless pl_pg.blank?

            next if pl_pg.blank?
            alum  = cobranza.rut_al.blank? ? nil : Usuario.first(siaa_id: cobranza.rut_al)
            ejectv= cobranza.rut_em.blank? ? nil : Usuario.first(siaa_id: cobranza.rut_em)
            inSed = InstitucionSede.first(siaa_id: cobranza.id_se)

            if ( cobr = Cobranza.first(siaa_id: cobranza.id_cz, siaa_id_sede_sync: SEDE_SYNC) ).blank?
                cobr = Cobranza.create  siaa_id: cobranza.id_cz, siaa_id_sede_sync: SEDE_SYNC,
                                        fecha: cobranza.fecha_cobranza, observacion: cobranza.observacion_cz,
                                        fecha_agendada: cobranza.fecha_nueva, 
                                        situacion_administrativa: cobranza.situacion_adm_cz,
                                        situacion_academica: cobranza.situacion_aca_cz,
                                        plan_pago: pl_pg,
                                        usuario: alum, ejecutivo: ejectv,
                                        institucion_sede: inSed,
                                        cobranza_tipo: tipo_cobranza,
                                        cobranza_tipo_plaza_letra: cobranza_tipo_plaza_letra

                puts "++++++++++++ CREANDO COBRANZA: #{cobr.inspect}".bold
            end
        end

        puts "======================== IMPORTACION DE PAGOS: TODOS! ==============================".red

        pagos = ModelosAntiguos::Pago.all order: :id_pg.desc, limit: limite, offset: offset

        pagos.each do |pago|
            if (abono = Abono.first(siaa_id: pago.id_pg, siaa_id_sede_sync:  SEDE_SYNC)).blank?
                perso_em = ModelosAntiguos::Persona.first username_pe: pago.user_pg
                usr_eje = Usuario.first siaa_id: perso_em.rut_pe unless perso_em.nil?
                ejecutivo = usr_eje.nil? ? nil : EjecutivoMatriculas.first_or_create({datos_personales: usr_eje})

                next if ejecutivo.nil?

                usr_alm        = Usuario.first(siaa_id: pago.rut_al)
                next if usr_alm.blank? ||usr_alm.alumno.blank?
                #alumno         = usr_alm.alumno
                # apoderado      = alumno.apoderado.nil? ? alumno : alumno.apoderado
                abono_tipo     = TipoAbono.first_or_create({   siaa_id: pago.id_tp                  },
                                                           {   nombre: pago.tipo_pago.nombre_tp,
                                                                alias: pago.tipo_pago.alias_tp      })

                # tipo_documento = (!pago.serie_ch.blank? ? PagoComprometido::CHEQUE : (pago.id_fp.eql?(5) ? PagoComprometido::PAGARE : nil))
                # numero_documento = tipo_documento.eql?(PagoComprometido::CHEQUE) ? pago.serie_ch : (tipo_documento.eql?(PagoComprometido::PAGARE) ? pago.letra_pl : nil)
                medio_pago = pago.id_fp.blank? ? nil : MedioPago.first( siaa_id: pago.id_fp )
                banco = pago.id_ba.blank? ? nil : Banco.first( siaa_id: pago.id_ba )
                tarjeta = pago.id_tt.blank? ? nil : TarjetasCredito.first( siaa_id: pago.id_tt )
                pago_comprometido = pago.letra_pl.blank? ? nil : PagoComprometido.first(siaa_id: pago.letra_pl)
                alm_pl_est = pago_comprometido.nil? ? nil : pago_comprometido.plan_pago.matricula_plan.alumno_plan_estudio.id

                documento_venta = DocumentoVenta.create estado: pago.estado, 
                                                        tipo: DocumentoVenta::BOLETA, 
                                                        fecha_emision: pago.fecha_emision, 
                                                        numero: pago.boleta_pg,
                                                        monto: pago.valor_pg,
                                                        plan_pago: pago_comprometido.nil? ? nil : pago_comprometido.plan_pago,
                                                        alumno_plan_estudio_id: alm_pl_est,
                                                        ejecutivo_matriculas: ejecutivo

                puts "DocumentoVenta: #{documento_venta.inspect}".red.bold

                abono = Abono.create    siaa_id: pago.id_pg, 
                                        siaa_id_sede_sync: SEDE_SYNC,
                                        monto: pago.valor_pg,
                                        interes: 0,#Falta ver donde capturar esto
                                        saldo: pago.saldo_pg,
                                        fecha: pago.fecha,
                                        estado: PagoComprometido::PAGADO,
                                        numero_documento: pago.boleta_pg,
                                        fecha_documento: pago.fecha_emision,
                                        medio_pago: medio_pago,
                                        banco: banco,
                                        tarjetas_credito: tarjeta,
                                        pago_comprometido_id: pago_comprometido.nil? ? nil : pago_comprometido.id,
                                        documento_venta_id: documento_venta.id,
                                        tipo_abono_id: abono_tipo.id,
                                        alumno_plan_estudio_id: alm_pl_est,
                                        ejecutivo_matriculas_id: ejecutivo.id






                  # siaa_id: pago.id_pg,
                  #                       siaa_id_sede_sync: SEDE_SYNC,
                  #                       monto: pago.valor_pg,
                  #                       saldo: pago.saldo_pg,
                  #                       #tipo_documento_venta: PagoComprometido::BOLETA,
                  #                       #numero_documento_venta: pago.boleta_pg,
                  #                       #anula_documento_venta: pago.nula_boleta_pg,
                  #                       fabricado_documento_venta: pago.compra_fabricada_pg,
                  #                       entregado_documento_venta: pago.compra_entregada_pg,
                  #                       pago_comprometido_id: pago_comprometido.blank? ? nil : pago_comprometido.id,
                  #                       apoderado_id: apoderado.id,
                  #                       institucion_sede_id: (iss = InstitucionSede.first(siaa_id: pago.id_se)).nil? ? nil : iss.id,
                  #                       fecha_pago: pago.fh_pg,
                  #                       alumno_plan_estudio_id: alm_pl_est.nil? ? nil : alm_pl_est.id,
                  #                       estado: PagoComprometido::PAGADO,
                  #                       tipo_documento: tipo_documento,
                  #                       forma_pago: pago.id_fp,
                  #                       abono_tipo: abono_tipo,
                  #                       numero_documento: numero_documento,
                  #                       medio_pago: medio_pago,
                  #                       banco: banco,
                  #                       tarjetas_credito: tarjeta,
                  #                       created_at: pago.fecha,
                  #                       ejecutivo_matriculas: ejecutivo
                puts "++++++++++++ CREANDO ABONO: #{abono.inspect}".bold
            end
        end

        rescue DataMapper::SaveFailureError => e
            log_error e
        rescue Exception => e
            log_error e
    end

    def self.actualizar_estado_alumno
        periodo_actual = Periodo.first :anio => PERIODO_ANIO_ACTUAL, :semestre => PERIODO_SEMESTRE_ACTUAL

        alumnos = Alumno.all

        alumnos.each do |al|  
            pes = al.alumno_plan_estudio

            pes.each do |pe|
                secciones         = pe.links_secciones_inscritas
                aprobadas         = secciones.all(:estado => AlumnoInscritoSeccion::APROBADA).length
                reprobadas        = secciones.all(:estado => AlumnoInscritoSeccion::REPROBADA).length
                homologadas       = secciones.all(:estado => AlumnoInscritoSeccion::HOMOLOGADA).length
                convalidadas      = secciones.all(:estado => AlumnoInscritoSeccion::CONVALIDADA).length
                abandonadas       = secciones.all(:estado => AlumnoInscritoSeccion::ABANDONADA)
                

                 puts "Alumno: #{al.datos_personales.nombre} Plan estudio: #{pe.plan_estudio.nombre}"

                actualizacion = {
                    :aprobadas    => aprobadas,
                    :reprobadas   => reprobadas,
                    :homologadas  => homologadas,
                    :convalidadas => convalidadas,
                    :estado       => Alumno::PENDIENTE
                }

                actualizacion[:estado] = Alumno::REGULAR if secciones.seccion_dictada.seccion.all periodo_id: periodo_actual.id
                actualizacion[:estado] = Alumno::REGULAR_CON_ABANDONO  if abandonadas.seccion_dictada.seccion.all(periodo_id: periodo_actual.id).length > 0
            
                pe.update actualizacion
               
                puts "Secciones: #{secciones.length} aprobadas: #{aprobadas} reprobadas: #{reprobadas} homologadas: #{homologadas} convalidadas: #{convalidadas}".bold
                puts "Estado: #{ApplicationController.helpers.get_name Alumno, :ESTADOS_ACADEMICOS, actualizacion[:estado]}".yellow
                puts "Datos a actualizar: #{actualizacion.inspect}".red
                puts "====".yellow
            end
        end
    end

# ==================== UTILIDADES ===================
    def self.str_date date
        I18n.l(date, format: :mini)
    end


    def self.parse_date date_str
        (date_str.blank? || date_str.length > 10) ? nil : Date.strptime(date_str, "%Y-%m-%d")
    end

    def self.t_str to_titleize
        to_titleize.nil? ? nil : clean_str(to_titleize).titleize.gsub(" De ", " de ").gsub(" En ", " en ").gsub(" Ii", " II").gsub(" Iii", " III").gsub(" Iv", " IV").gsub(" A ", " a ").gsub(" La ", " la ").gsub(" Y ", " y ")
    end


    def self.clean_str str
        string = str.nil? ? nil : str.unpack("C*").pack("U*")

        return string unless string.is_a? String

        # Try it as UTF-8 directly
        cleaned = string.dup.force_encoding('UTF-8')
        if cleaned.valid_encoding?
            cleaned
        else
            # Some of it might be old Windows code page
            string.encode(Encoding::UTF_8, Encoding::Windows_1250)
        end
        rescue EncodingError
          # Force it to UTF-8, throwing out invalid bits
          string.encode!('UTF-8', invalid: :replace, undef: :replace)
    end

    def self.clean_email str
        str = clean_str str
        return nil if str.blank?

        reg = /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i
        #return nil unless reg.match(str)

        str = str.gsub(" ", "").gsub("ñ", "n").gsub(/[^a-zA-Z0-9@._-]/, '').gsub("@.", "@")
        str = str[1 .. str.length] if str[0] == "."

        return str if str.match(reg)

        str.split("-").each do |em|
            return em if em.match(reg)
        end

        str.split("|").each do |em|
            return em if em.match(reg)
        end

        str.split(" ").each do |em|
            return em if em.match(reg)
        end

        str.split(",").each do |em|
            return em if em.match(reg)
        end

        return nil
    end

    def self.ejecutivo rut_em, sede_id
        puts "Ejecutivo: rut_em: #{rut_em} sede: #{sede_id}".bold
        persona = ModelosAntiguos::Persona.first rut_pe: rut_em
        persona = ModelosAntiguos::Persona.first(rut_pe: 14266362) if persona.blank?

        sede = sede_id.is_a?(Fixnum) ? Sede.get(sede_id) : sede_id

        usuario = Usuario.first_or_create(  { :rut.like => "#{persona.rut_pe}-%" },
                                            usuario_hash(persona, sede, Usuario::ADMINISTRATIVO) )

        EjecutivoMatriculas.first_or_create({usuario_id: usuario.id })
    end

    def self.usuario_hash persona, sede, tipo = Usuario::ESTUDIANTE
        rut         = persona.parsear_rut
        rut = rut + "0" if rut.last == "-"
        nombres     = persona.parsear_nombres
        apellidos   = persona.parsear_apellidos

        # if institucion_sede.is_a?(Fixnum)
        #     institucion_sede = InstitucionSede.get(institucion_sede) 
        # end
        # if institucion_sede.blank?
        #     institucion_sede = InstitucionSede.get(DEFAULT_SEDES[SEDE_SYNC]) 
        # end

        comuna = ModelosAntiguos::Comuna.get(persona.id_cm)
        comuna = comuna.blank? ? nil : comuna.buscar

        {
            rut:                rut,
            password:           Digest::MD5.hexdigest(rut),
            email:              ((email = clean_email(persona.email_pe)).blank? || !(email.include?("@") && email.include?(".")) ) ? 'notiene@email.cl' : email,
            primer_nombre:      nombres[0],
            segundo_nombre:     nombres[1],
            apellido_paterno:   apellidos[0],
            apellido_materno:   apellidos[1],
            fecha_nacimiento:   parse_date(persona.fh_nacimiento_pe),
            sexo:               persona.parsear_sexo,
            domicilio:          (dom = t_str(persona.domicilio)).blank? ? 'No registrado' : dom,
            villa_poblacion:    t_str(persona.sector),
            telefono_fijo:      clean_str(persona.fono_pe),
            telefono_movil:     clean_str(persona.celular_pe),
            tipo:               tipo,
            pais_id:            1,
            region_id:          (comuna.blank? ? 1 : comuna.region_id),
            comuna_id:          (comuna.blank? ? 1 : comuna.id),
            siaa_id:            persona.rut_pe,
            siaa_updated_at:    DateTime.now,
            siaa_trans_date:    persona.fecha_transaccion,
            sede:               sede
            #codigo_area_telefono:41
        }

    end

    def self.log_error e
        puts "========================================".red
        puts e.inspect
        puts e.resource.errors.inspect.blue.bold if e.is_a? DataMapper::SaveFailureError
        puts "========================================".red
        e.backtrace.map{ |x| x.match(/^(.+?):(\d+)(|:in `(.+)')$/); [$1,$2,$4] }.each do |i|
            puts i[0].magenta + ":" + i[1].red + "\t" + i[2].yellow
        end
        Process.exit!(true)
    end

    def self.generar_seed
        filename = Rails.root.to_s + "/db/seeds/mallas.csv"
        puts "GENERAR SEED".blue

        fl = true

        CSV.foreach(filename, :col_sep => ";") do |l|

            carrera,responsable,concepcion,chillan,nunoa,bosque,vina = l

            if fl
                fl = false
            else
                
                pe = PlanEstudio.first( siaa_id_ca: vina.to_i, siaa_id_sede_sync: SEDE_VINA )

                unless pe.nil?
                    puts "PlanEstudio.create nombre: '#{pe.nombre}', nivel: #{pe.nivel}, tiene_salida_intermedia: #{pe.tiene_salida_intermedia}, duracion: #{pe.duracion}, titulo_profesional: '#{pe.titulo_profesional}', titulo_tecnico: '#{pe.titulo_tecnico}', licenciatura: #{pe.licenciatura.nil? ? 'nil' : pe.lincenciatura }, alumno_nuevo_paga_matricula: #{pe.alumno_nuevo_paga_matricula.nil? ? 'nil' : pe.alumno_nuevo_paga_matricula}, revision: '#{pe.revision}', semestre_inicio: #{pe.semestre_inicio}, anio_inicio: #{pe.anio_inicio}, semestre_fin: #{pe.semestre_fin}, anio_fin: #{pe.anio_fin}, estado: #{pe.estado.nil? ? 'nil' : pe.estado}, siaa_id_ma: #{pe.siaa_id_ma}, siaa_id_ca_concepcion: #{concepcion}, siaa_id_ca_chillan: #{chillan}, siaa_id_ca_nunoa: #{nunoa}, siaa_id_ca_bosque: #{bosque}, siaa_id_ca_vina: #{vina}, plan_requisito_id: #{pe.plan_requisito_id.nil? ? 'nil' : pe.plan_requisito_id}, escuela_id: #{(pe.escuela_id.nil?||pe.escuela_id.eql?(0)) ? 'nil' : pe.escuela_id}"
                else
                    puts "#NO EXISTE CARRERA: #{carrera} en esta sede"
                end
            end

        end
    end

    def self.generar_seed_final
        filename = Rails.root.to_s + "/db/seeds/mallas_siaa.csv"
        #puts "GENERAR SEED FINAL".blue.bold

        sedes = {
            1 => :siaa_id_ca_concepcion,
            2 => :siaa_id_ca_chillan,
            3 => :siaa_id_ca_nunoa,
            4 => :siaa_id_ca_bosque,
            5 => :siaa_id_ca_vina,
            6 => :siaa_id_ca_concepcion,
            7 => :siaa_id_ca_vina,
            8 => :siaa_id_ca_nunoa
        }

        datos = []

        fl = true

        CSV.foreach(filename, :col_sep => ";") do |l|
            id_ma,nombre_ma,sem_ini_ma,ano_ini_ma,sem_fin_ma,ano_fin_ma,id_se,id_ca = l
            #puts "id_ma: #{id_ma} id_ca: #{id_ca} id_se: #{id_se}"
            next if (id_ma.blank?||id_ca.blank? && id_se.blank?)

            id_ma = id_ma.to_i
            id_ca = id_ca.to_i
            id_se = id_se.to_i

            ins_sed = InstitucionSede.first siaa_id: id_se

            if fl
                fl = false
            else

                unless ins_sed.nil? 
                    base = PlanEstudio.first sedes[ins_sed.sede.id] => id_ca
                    
                    #puts "Base: #{base.id}".bold
                    next if base.nil?     

                    if (datos.find_all{|x| (x[:siaa_id_ca_concepcion] == base.siaa_id_ca_concepcion ||
                        x[:siaa_id_ca_chillan] == base.siaa_id_ca_chillan ||
                        x[:siaa_id_ca_nunoa] == base.siaa_id_ca_nunoa ||
                        x[:siaa_id_ca_bosque] == base.siaa_id_ca_bosque ||
                        x[:siaa_id_ca_vina] == base.siaa_id_ca_vina) && x[:siaa_id_ma] == id_ma}).length == 0
                        
                        #puts "creando row".bold
                        
                        datos << genera_row_seed( id_ma,nombre_ma,sem_ini_ma,ano_ini_ma,sem_fin_ma,ano_fin_ma,id_se,id_ca, base, ins_sed, sedes )
                        #puts "datos puestos".red

                    else

                        #puts "buscando indice".bold
                        #puts "#{sedes[ins_sed.sede.id]} = #{id_ca} id_ma: #{id_ma} ins_sed: #{ins_sed.id}".yellow
                        #puts "sede: #{ins_sed.sede.id}".red
                        idx = datos.find_index{|x| x[sedes[ins_sed.sede.id]] == id_ca && x[:siaa_id_ma] == id_ma }
                        
                        if idx.nil?
                            datos << genera_row_seed( id_ma,nombre_ma,sem_ini_ma,ano_ini_ma,sem_fin_ma,ano_fin_ma,id_se,id_ca, base, ins_sed, sedes )
                        else

                            #puts "idx: #{idx}"

                            #puts "linea: #{l.inspect}"
                            row = datos[idx]
                            #puts "row a modificar: #{row.inspect}"
                            row[sedes[ins_sed.sede.id]] = id_ca
                            
                            datos[idx] = row
                            #puts "asociando datos".red
                        end
                    end
                end
            end
        end
        datos.each do |i|
            puts "PlanEstudio.create nombre: '#{i[:nombre]}', " <<
            "nivel: #{i[:nivel].blank? ? 'nil' : i[:nivel] }, " <<
            "tiene_salida_intermedia: #{i[:tiene_salida_intermedia].blank? ? 'nil' : i[:tiene_salida_intermedia]}, " <<
            "duracion: #{i[:duracion].blank? ? 'nil' : i[:duracion]}, " <<
            "titulo_profesional: '#{i[:titulo_profesional]}', " <<
            "titulo_tecnico: '#{i[:titulo_tecnico]}', " <<
            "licenciatura: '#{i[:licenciatura]}', " <<
            "alumno_nuevo_paga_matricula: #{i[:alumno_nuevo_paga_matricula].blank? ? 'nil' : i[:alumno_nuevo_paga_matricula]}, " <<
            "revision: '#{i[:revision]}', " <<
            "semestre_inicio: #{i[:semestre_inicio].blank? ? 'nil' : i[:semestre_inicio]}, " <<
            "anio_inicio: #{i[:anio_inicio].blank? ? 'nil' : i[:anio_inicio]}, " <<
            "semestre_fin: #{i[:semestre_fin].blank? ? 'nil' : i[:semestre_fin]}, " <<
            "anio_fin: #{i[:anio_fin].blank? ? 'nil' : i[:anio_fin]}, " <<
            "estado: #{i[:estado].blank? ? 'nil' : i[:estado]}, " <<
            "siaa_id_ma: #{i[:siaa_id_ma].blank? ? 'nil' : i[:siaa_id_ma]}, " <<
            "siaa_id_ca_concepcion: #{i[:siaa_id_ca_concepcion].blank? ? 'nil' : i[:siaa_id_ca_concepcion]}, " <<
            "siaa_id_ca_chillan: #{i[:siaa_id_ca_chillan].blank? ? 'nil' : i[:siaa_id_ca_chillan]}, " <<
            "siaa_id_ca_nunoa: #{i[:siaa_id_ca_nunoa].blank? ? 'nil' : i[:siaa_id_ca_nunoa]}, " <<
            "siaa_id_ca_bosque: #{i[:siaa_id_ca_bosque].blank? ? 'nil' : i[:siaa_id_ca_bosque]}, " <<
            "siaa_id_ca_vina: #{i[:siaa_id_ca_vina].blank? ? 'nil' : i[:siaa_id_ca_vina]}, " <<
            "plan_requisito_id: #{i[:plan_requisito_id].blank? ? 'nil' : i[:plan_requisito_id]}, " <<
            "escuela_id: #{i[:escuela_id].blank? ? 'nil' : i[:escuela_id]}"
        end
    end

    def self.genera_row_seed id_ma,nombre_ma,sem_ini_ma,ano_ini_ma,sem_fin_ma,ano_fin_ma,id_se,id_ca, base, ins_sed, sedes
        row = {
            nombre: base.nombre,
            nivel: base.nivel,
            tiene_salida_intermedia: base.tiene_salida_intermedia,
            duracion: base.duracion,
            titulo_profesional: base.titulo_profesional,
            titulo_tecnico: base.titulo_tecnico,
            licenciatura: base.licenciatura,
            alumno_nuevo_paga_matricula: base.alumno_nuevo_paga_matricula,
            revision: nombre_ma,
            semestre_inicio: sem_ini_ma,
            anio_inicio: ano_ini_ma,
            semestre_fin: sem_fin_ma,
            anio_fin: ano_fin_ma,
            estado: base.estado,
            siaa_id_ma: id_ma,
            siaa_id_ca_concepcion: base.siaa_id_ca_concepcion,
            siaa_id_ca_chillan: base.siaa_id_ca_chillan,
            siaa_id_ca_nunoa: base.siaa_id_ca_nunoa,
            siaa_id_ca_bosque: base.siaa_id_ca_bosque,
            siaa_id_ca_vina: base.siaa_id_ca_vina,
            plan_requisito_id: base.plan_requisito_id,
            escuela_id: base.escuela_id
        }

        #row[sedes[ins_sed.sede.id]] = id_ca
       
        return row 
    end
end
