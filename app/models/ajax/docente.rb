# encoding: utf-8
class Ajax::Docente

    def self.asignaturas docente_id, periodo_id
        data = []

        # "Seccion"
        secciones_dictadas = Seccion.all(
            :fields => [:id, :docente_id, :periodo_id, :numero],
            :docente_id => docente_id,
            :periodo_id => periodo_id
        )

        # "SeccionDictada"
        links_asignaturas_dictadas = secciones_dictadas.links_secciones_dictadas

        # "Asignatura"
        asignaturas_dictadas = links_asignaturas_dictadas.asignaturas(
            :fields => [:id, :nombre]
        )

        links_asignaturas_dictadas.each do |link_asignatura|
            # "Seccion"
            seccion = secciones_dictadas.select { |seccion| seccion.id == link_asignatura.seccion_id }.first
            # "Asignatura"
            asignatura = asignaturas_dictadas.select { |asignatura| asignatura.id == link_asignatura.asignatura_id }.first            

            data << {
                :seccion    => seccion.sigla + " - " + asignatura.nombre,
                :id         => seccion.id
            }
        end  

        data
    end

end