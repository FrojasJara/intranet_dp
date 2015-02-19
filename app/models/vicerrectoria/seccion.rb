class Vicerrectoria::Seccion

	def self.guardar_nueva_seccion seccion, docente
        Seccion.transaction do 
            
            nueva_seccion = Seccion.new
            nueva_seccion_dictada = SeccionDictada.new

            nueva_seccion.institucion_sede_id = seccion[:institucion_sede_id].to_i
            nueva_seccion.cupos         = seccion[:cupos].to_i
            nueva_seccion.numero        = seccion[:numero].to_i
            nueva_seccion.estado        = Seccion::ABIERTA
            nueva_seccion.jornada       = seccion[:jornada].to_i == nil ? 0  : seccion[:jornada].to_i
            nueva_seccion.periodo_id    = seccion[:periodo_id].to_i
            nueva_seccion.docente_id    = docente == nil ? nil : docente.id
            nueva_seccion.save

            nueva_seccion_dictada.asignatura_id = seccion[:asignatura_id].to_i
            nueva_seccion_dictada.seccion_id  = nueva_seccion.id
            nueva_seccion_dictada.periodo_id =  nueva_seccion.periodo_id
            nueva_seccion_dictada.save

            puts nueva_seccion.inspect.red
            puts nueva_seccion_dictada.inspect.red
        end
  end

end