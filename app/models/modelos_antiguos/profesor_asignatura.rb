# coding: utf-8
class ModelosAntiguos::ProfesorAsignatura 
    include DataMapper::Resource

    def self.default_repository_name
        :db_antigua 
    end
    
    storage_names[:db_antigua] = 'profesores_asignaturas'

    property :id_pra,               Serial
    property :id_ca,                Integer
    property :id_as,                Integer
    property :seccion_pra,          Integer
    property :rut_pra,              Integer
    property :sem_pra,              Integer
    property :ano_pra,              Integer
    property :horas_pra,            Integer
    property :valor_horas_pra,      Integer
    property :id_se,                Integer
    property :id_tc,                Integer

    belongs_to :profesor, 'ModelosAntiguos::Persona', parent_key: 'rut_pe', child_key: 'rut_pra', required: false
    belongs_to :asignatura, 'ModelosAntiguos::Asignatura', parent_key: 'id_as', child_key: 'id_as', required: false
end

