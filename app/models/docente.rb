# encoding: utf-8
class Docente
	include DataMapper::Resource
	include DataMapper::Timestamps
    include DataMapper::Historylog

	property    :id,		            Serial
    property    :curriculum,            Text
    property    :en_ejercicio,          Boolean
    property    :siaa_updated_at,       DateTime
    property    :siaa_id_sede_sync,     Integer
    

    timestamps  :at
    property    :deleted_at,    ParanoidDateTime

    has n,      :antecedentes, :order => [:create_at.asc]
    has n,      :secciones, "Seccion"
    has n,      :contratos
    has n,      :links_escuelas, "DocenteTrabaja"
    has n,      :comisiones_examinadoras, "DocenteExaminador"
    has n,      :docentes_trabajos_titulos , "DocenteTrabajoTitulo"
    has n,      :practicas_profesionales, "PracticaProfesional"
    belongs_to  :datos_personales, "Usuario", :child_key => "usuario_id"

    def asignaturas_dictadas docente_id, periodo_id; Docentes::Asignaturas.asignaturas_dictadas docente_id, periodo_id end

    def asignaturas_abiertas docente_id, periodo_id; Docentes::Asignaturas.asignaturas_abiertas docente_id, periodo_id end

    def asignaturas_abiertas_seleccion docente_id, periodo_id; Docentes::Asignaturas.asignaturas_abiertas_seleccion docente_id, periodo_id  end

    def self.mapear_iterador(consulta)
        iterador = consulta.map do |x| 
                            [{
                                :id_docente => x.id, :curriculum => x.curriculum, 
                                :usuario_id => x.usuario_id, :en_ejercicio => x.en_ejercicio ? 'Sí' : 'No'
                            }]
                        end
        iterador
    end

    def self.obtener_datos_docentes(docentes,attrs = [])
        attrs = %w[id rut primer_nombre segundo_nombre apellido_paterno apellido_materno] if attrs.size == 0
        datos = Usuario.all(:fields => attrs, 
                                    :docente => docentes).map do |x| 
                                                    [{
                                                        :id_usuario => x.id, :rut => x.rut, 
                                                        :primer_nombre => x.primer_nombre , :segundo_nombre => x.segundo_nombre,
                                                        :apellido_paterno => x.apellido_paterno, :apellido_materno => x.apellido_materno
                                                    }] 
                                                end
        datos
    end

end