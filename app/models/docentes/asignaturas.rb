# encoding: utf-8
class Docentes::Asignaturas

	def self.asignaturas_dictadas docente_id, periodo_id
		docente = Docente.get! docente_id
        data = []

        # "Secciones"
        secciones_dictadas = Seccion.all(
            :fields => [
                :id, :docente_id, :periodo_id, :numero,
                :alumnos_inscritos, :alumnos_aprobados, :alumnos_reprobados, :alumnos_convalidados,
                :alumnos_homologados, :promedio_aprobacion, :promedio_reprobacion,
                :desviacion_estandar, :institucion_sede_id
            ],
            :periodo_id     => periodo_id,
            :docente     	=> docente,
            :estado         => Seccion::CERRADA
        )

        raise Excepciones::DatosNoExistentesError, "El docente no posee asignaturas dictadas en el periodo consultado." if secciones_dictadas.empty? 

        # "SeccionDictada"
        links_asignaturas_dictadas = secciones_dictadas.links_secciones_dictadas :fields => [:id, :seccion_id, :asignatura_id]
        # "Asignatura"
        asignaturas_dictadas = links_asignaturas_dictadas.asignaturas :fields => [:id, :plan_estudio_id, :nombre]
        # "PlanEstudio"
        planes_dictados = asignaturas_dictadas.plan_estudio :fields => [:id, :nombre]

        secciones_dictadas.each do |seccion_dictada|
            item = {}

            item[:seccion] = seccion_dictada
            item[:institucion_sede] = seccion_dictada.institucion_sede.nombre

            # "SeccionDictada"
            links_asignatura_dictada = links_asignaturas_dictadas.select { |l| l.seccion_id == seccion_dictada.id }.map { |l| l.asignatura_id }

            # "Asignatura"
            asignaturas_dictada = asignaturas_dictadas.select { |a| links_asignatura_dictada.include? a.id }

            item[:asignaturas] = []
            asignaturas_dictada.each do |a|
                item2 = {}

                item2[:asignatura] = a
                # "PlanEstudio"
                item2[:plan_estudio] = planes_dictados.select { |p| p.id == a.plan_estudio_id }.first

                item[:asignaturas] << item2
            end

            data << item
        end
        data
	end

    def self.asignaturas_abiertas docente_id, periodo_id
        docente = Docente.get! docente_id
        data = []

        # "Seccion"
        secciones_abiertas = Seccion.all(
            :fields         => [
                :id, 
                :numero, 
                :alumnos_inscritos,
                :alumnos_aprobados,
                :alumnos_reprobados,
                :alumnos_homologados,
                :alumnos_convalidados,
                :institucion_sede_id
            ],
            :estado         => Seccion::ABIERTA,
            :docente        => docente,
            :periodo_id     => periodo_id
        )

        raise Excepciones::DatosNoExistentesError, "El docente no posee asignaturas abiertas en el periodo en curso." if secciones_abiertas.empty? 

        # "SeccionDictada"
        links_asignaturas_abiertas = secciones_abiertas.links_secciones_dictadas
        # "Asignatura"
        asignaturas_abiertas = links_asignaturas_abiertas.asignatura :fields => [:id, :nombre]
        # "Horario"
        horarios = secciones_abiertas.horarios
        # "BloqueHorario"
        bloques_horarios = horarios.bloque_horario :fields => [:id, :numero, :hora_inicio, :hora_termino]
        # "Sala"
        salas = horarios.sala :fields => [:id, :nombre]

        secciones_abiertas.each do |seccion|
            item = {}

            # "Seccion"
            item[:seccion] = seccion
            item[:institucion_sede] = seccion.institucion_sede.nombre

            # "Asignatura" y "PlanEstudio"
            links_asignaturas = links_asignaturas_abiertas.select { |link| seccion.id == link.seccion_id }
            id_links_asignatutas = links_asignaturas.map { |link| link.asignatura_id }
            item[:asignaturas] = asignaturas_abiertas.select{ |a| id_links_asignatutas.include? a.id }

            # "Horarios"
            horarios_seccion = horarios.select { |horario| seccion.id == horario.seccion_id }
            item[:horarios] = horarios_seccion.map do |horario|
                bloque = bloques_horarios.select { |bloque| bloque.id == horario.bloque_horario_id }.first
                sala = salas.select { |sala| sala.id == horario.sala_id }.first

                {
                    :horario    => horario,
                    :bloque     => bloque,
                    :sala       => sala
                }
            end

            data << item
        end

        data
    end

    def self.asignaturas_abiertas_seleccion docente_id, periodo_id
        docente = Docente.get! docente_id
        data = []

        # "Seccion"
        secciones_abiertas = docente.secciones :fields => [:id, :numero, :periodo_id, :docente_id], :estado => Seccion::ABIERTA, :periodo_id => periodo_id

         raise Excepciones::DatosNoExistentesError, "El docente no posee asignaturas abiertas en el periodo en curso." if secciones_abiertas.empty? 

        # "SeccionDictada"
        links_secciones_abiertas = secciones_abiertas.links_secciones_dictadas

        # "Asignatura"
        asignaturas_abiertas = links_secciones_abiertas.asignatura :fields => [:id, :nombre]

        links_secciones_abiertas.each do |link_seccion|
            seccion = secciones_abiertas.select { |seccion| seccion.id == link_seccion.seccion_id }.first
            asignatura = asignaturas_abiertas.select { |asignatura| asignatura.id == link_seccion.asignatura_id }.first

            data << {
                :seccion_id     => seccion.id,
                :asignatura     => seccion.sigla + " - " + asignatura.nombre
            }
        end
        
        data
    end
end