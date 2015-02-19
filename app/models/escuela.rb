# encoding: utf-8
class Escuela
	include DataMapper::Resource
	include DataMapper::Timestamps
	include DataMapper::Historylog

	property 	:id,			Serial
	property 	:nombre, 		String

	has n, :carreras_dictadas, "PlanEstudio"
	has n, :director_escuelas
    has n, :plan_estudio
    
    has n, :coordinadores, "Coordinador"

	timestamps 	:at
    property 	:deleted_at, 	ParanoidDateTime



    def self.asignar_escuela_plan_estudio planes_estudios
    	PlanEstudio.transaction do 
    		planes_estudios.each do |i|
    			
    			plan_estudio_id = i[:plan_estudio_id].to_i
    			escuela_id = i[:escuela_id].to_i
    			estado = i[:vigencia].to_i
    			plan_estudio = PlanEstudio.get(plan_estudio_id)

    			plan_estudio.escuela_id = escuela_id
                plan_estudio.estado = estado
    			plan_estudio.save

    		end
    	end
    end

    def self.obtener_todas attrs
        all(:fields => attrs)
    end

end