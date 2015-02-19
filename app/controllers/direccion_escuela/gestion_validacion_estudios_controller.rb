# encoding: utf-8
class DireccionEscuela::GestionValidacionEstudiosController < ApplicationController
    protect_from_forgery :except => [
                                        :convalidacion_estudios,
                                        :homologacion_estudios,
                                        :registrar_convalidacion,
                                        :registrar_homologacion
                                    ]

	def convalidacion_estudios
		unless params[:busqueda].blank?
            @usuario = Usuario.first rut: params[:busqueda]
            raise Excepciones::DatosNoExistentesError, "El Rut ingresado no existe" if @usuario.blank?
            raise Excepciones::DatosNoExistentesError, "El Rut ingresado no tiene un alumno asociado" if @usuario.alumno.blank?
        	
        	@alumno = @usuario.alumno 
        	@alumno_plan_estudios = AlumnoPlanEstudio.all(
                                                        :fields => [:id, :alumno_id, :estado, :institucion_sede_plan_id ],
                                                        :estado => [Alumno::REGULAR, Alumno::SIN_INSCRIPCION, Alumno::SIN_MATRICULA],
                                                        :alumno_id => @alumno.id
                                                        )

        end

        unless params[:alumno_plan_estudio_id].blank?
            @aprobadas = []
            @periodos = Periodo.all(:order => [:anio.desc, :semestre.desc],:semestre => 1)
        	@alumno_plan_estudio_seleccionado = AlumnoPlanEstudio.first id: params[:alumno_plan_estudio_id].to_i
        	@plan_estudio = @alumno_plan_estudio_seleccionado.plan_estudio
        	@asignaturas = Asignatura.all(
        									:fields => [:nombre, :semestre, :plan_estudio_id, :id],
        									:plan_estudio_id => @plan_estudio.id,
        									:order => [:semestre.asc]
        								)
            #cursadas = Alumnos::Asignatura::informe_curricular @alumno_plan_estudio_seleccionado.id   	
        	
            #cursadas.each do |item|
                #estado = get_name AlumnoInscritoSeccion, "ESTADOS", item[:inscripciones].last[:estado].estado
               # item[:inscripciones].each do |inscripcion|
                #    if inscripcion[:estado].estado == 2 or inscripcion[:estado].estado == 4 or inscripcion[:estado].estado == 5
               #         @aprobadas << item[:asignatura]


            #end
            @alumno = @alumno_plan_estudio_seleccionado.alumno
        	
        	@alumno_plan_estudios = @alumno.alumno_plan_estudio

        	@usuario = @alumno.datos_personales
        	#raise Excepciones::DatosNoExistentesError, "No se han encontrado asignaturas para este plan de estudio." if @asignaturas.blank?
        end
        rescue Excepciones::DatosNoExistentesError => e
            flash[:error] = e.message 
	end


    def homologacion_estudios
        unless params[:busqueda].blank?
            @usuario = Usuario.first rut: params[:busqueda]
            raise Excepciones::DatosNoExistentesError, "El Rut ingresado no existe" if @usuario.blank?
            raise Excepciones::DatosNoExistentesError, "El Rut ingresado no tiene un alumno asociado" if @usuario.alumno.blank?
            
            @alumno = @usuario.alumno 
            @alumno_plan_estudios = AlumnoPlanEstudio.all(
                                                        :fields => [:id, :alumno_id, :estado, :institucion_sede_plan_id ],
                                                        :estado => [Alumno::REGULAR, Alumno::SIN_INSCRIPCION, Alumno::SIN_MATRICULA],
                                                        :alumno_id => @alumno.id
                                                        )

        end

        unless params[:alumno_plan_estudio_id].blank?
            @aprobadas = []
            @alumno_plan_estudio_seleccionado = AlumnoPlanEstudio.first id: params[:alumno_plan_estudio_id].to_i
            @plan_estudio = @alumno_plan_estudio_seleccionado.plan_estudio
            @asignaturas = Asignatura.all(
                                            :fields => [:nombre, :semestre, :plan_estudio_id, :id],
                                            :plan_estudio_id => @plan_estudio.id,
                                            :order => [:semestre.asc]
                                        )
            @alumno = @alumno_plan_estudio_seleccionado.alumno
            
            @alumno_plan_estudios = @alumno.alumno_plan_estudio

            @usuario = @alumno.datos_personales
            #raise Excepciones::DatosNoExistentesError, "No se han encontrado asignaturas para este plan de estudio." if @asignaturas.blank?
        end
        rescue Excepciones::DatosNoExistentesError => e
            flash[:error] = e.message 
    end

    def registrar_convalidacion
        
        datos_homologacion = params[:asignatura_convalidada][:convalidacion]
        institucion_externa = params[:carrera_convalidada][:institucion_externa_id].to_i
        institucion_sede = params[:asignatura_convalidada][:institucion_sede].to_i
        numero_documento = params[:carrera_convalidada][:numero_documento].to_i
        carrera_origen = params[:carrera_convalidada][:carrera_nombre]
        plan_estudio = params[:asignatura_convalidada][:alumno_plan_estudio].to_i
        semestre_cursa = params[:asignatura_convalidada][:semestre_cursa].to_i
        tipo = params[:asignatura_convalidada][:tipo].to_i

        ConvalidacionHomologacion.transaction do

            datos_homologacion.each do |i|
                puts i.inspect
                datos = i[1]
                rut = datos[:Docente].split('| ')
                docente = Docente.first(:datos_personales => {:rut => rut[1]})
                periodo = Periodo.first id: datos[:periodo].to_i
                

                validacion = ConvalidacionHomologacion.new
                validacion.tipo = tipo
                validacion.anio_cursa = datos[:anio].to_i
                validacion.semestre_cursa = datos[:semestre].to_i
                validacion.carrera_convalidada = carrera_origen
                validacion.nro_documento = numero_documento
                validacion.periodo_id = periodo.id
                validacion.responsable_id = docente.datos_personales.id
                validacion.alumno_plan_estudio_id = plan_estudio
                validacion.institucion_externa_id = institucion_externa
                puts validacion.inspect
                validacion.save


                seccion = Seccion.new
                seccion.periodo_id = periodo.id
                seccion.cupos = 1
                seccion.estado = 2
                seccion.numero = Seccion::CONVALIDADA_HOMOLOGADA
                seccion.jornada = Seccion::CONVALIDACION
                seccion.docente_id = docente.id
                seccion.institucion_sede_id = institucion_sede
                puts seccion.inspect
                seccion.save

                seccion_dictada = SeccionDictada.new
                seccion_dictada.asignatura_id = datos[:asignatura_origen_id].to_i 
                seccion_dictada.seccion_id = seccion.id 
                seccion_dictada.periodo_id = periodo.id
                puts seccion_dictada.inspect
                seccion_dictada.save

                alumno_inscrito_seccion = AlumnoInscritoSeccion.new
                alumno_inscrito_seccion.seccion_dictada_id = seccion_dictada.id
                alumno_inscrito_seccion.alumno_plan_estudio_id = plan_estudio
                alumno_inscrito_seccion.nota_final = datos[:nota_externa].to_f
                alumno_inscrito_seccion.estado = 4
                alumno_inscrito_seccion.convalidacion_homologacion_id = validacion.id
                alumno_inscrito_seccion.inspect
                alumno_inscrito_seccion.save

                asignatura = AsignaturasInstitucionesExternas.new
                asignatura.nombre = datos[:asignatura_externa]
                asignatura.nota_final = datos[:nota_externa].to_f
                asignatura.seccion_alumno_id = alumno_inscrito_seccion.id
                asignatura.validacion_id = validacion.id
                puts asignatura.inspect
                asignatura.save

            end
        end
        flash[:notice] = "La Convalidacion de Asignatura ha sido Guardada exitosamente."
        redirect_to  direccion_escuela_convalidacion_estudios_path  
        
        rescue Exception => e
            puts e.message
            flash[:error] = "No ha sido posible guardar la Convalidacion Verifique que ingreso todos los datos correctamente.#{e.inspect}"
            redirect_to  direccion_escuela_convalidacion_estudios_path
        
    end

    def registrar_homologacion
        
        datos_homologacion = params[:asignatura_convalidada][:convalidacion]
        institucion_sede = params[:asignatura_convalidada][:institucion_sede].to_i
        numero_documento = params[:carrera_convalidada][:numero_documento].to_i
        carrera_origen = params[:carrera_convalidada][:carrera_nombre]
        plan_estudio = params[:asignatura_convalidada][:alumno_plan_estudio].to_i
        semestre_cursa = params[:asignatura_convalidada][:semestre_cursa].to_i
        tipo = params[:asignatura_convalidada][:tipo].to_i

        ConvalidacionHomologacion.transaction do

            datos_homologacion.each do |i|
                datos = i[1]
                rut = datos[:Docente].split('| ')
                docente = Docente.first(:datos_personales => {:rut => rut[1]})
                periodo = Periodo.first id: datos[:periodo].to_i

                validacion = ConvalidacionHomologacion.new
                validacion.tipo = tipo
                validacion.anio_cursa = datos[:anio].to_i
                validacion.semestre_cursa = datos[:semestre].to_i
                validacion.carrera_convalidada = carrera_origen
                validacion.nro_documento = numero_documento
                validacion.periodo_id = periodo.id
                validacion.responsable_id = docente.datos_personales.id
                validacion.alumno_plan_estudio_id = plan_estudio
                validacion.institucion_externa_id = 4
                puts validacion.inspect
                validacion.save


                seccion = Seccion.new
                seccion.periodo_id = periodo.id
                seccion.cupos = 1
                seccion.estado = 2
                seccion.numero = Seccion::CONVALIDADA_HOMOLOGADA
                seccion.jornada = Seccion::HOMOLOGACION
                seccion.docente_id = docente.id
                seccion.institucion_sede_id = institucion_sede
                puts seccion.inspect
                seccion.save

                seccion_dictada = SeccionDictada.new
                seccion_dictada.asignatura_id = datos[:asignatura_origen_id].to_i 
                seccion_dictada.seccion_id = seccion.id 
                seccion_dictada.periodo_id = periodo.id
                puts seccion_dictada.inspect
                seccion_dictada.save

                alumno_inscrito_seccion = AlumnoInscritoSeccion.new
                alumno_inscrito_seccion.seccion_dictada_id = seccion_dictada.id
                alumno_inscrito_seccion.alumno_plan_estudio_id = plan_estudio
                alumno_inscrito_seccion.nota_final = datos[:nota_externa].to_f
                alumno_inscrito_seccion.estado = 5
                alumno_inscrito_seccion.convalidacion_homologacion_id = validacion.id
                alumno_inscrito_seccion.inspect
                alumno_inscrito_seccion.save

                asignatura = AsignaturasInstitucionesExternas.new
                asignatura.nombre = datos[:asignatura_externa]
                asignatura.nota_final = datos[:nota_externa].to_f
                asignatura.seccion_alumno_id = alumno_inscrito_seccion.id
                asignatura.validacion_id = validacion.id
                puts asignatura.inspect
                asignatura.save

            end
        end
        flash[:notice] = "La Homologacion de Asignatura ha sido Guardada exitosamente."
        redirect_to  direccion_escuela_convalidacion_estudios_path  
        
        rescue Exception => e
            puts e.message
            flash[:error] = "No ha sido posible guardar la Homologacion Verifique que ingreso todos los datos correctamente."
            redirect_to  direccion_escuela_convalidacion_estudios_path
        
    end

end