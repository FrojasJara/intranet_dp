# coding: utf-8
class ModelosAntiguos::Carrera 
    include DataMapper::Resource

    def self.default_repository_name
        :db_antigua 
    end
    
    storage_names[:db_antigua] = 'carreras'

    property :id_ca, Serial
    property :duracion_ca, Integer
    property :titulo_ca, String, :length => 150
    property :nombre_in_ca, String, :length => 60
    property :duracion_in_ca, Integer
    property :titulo_in_ca, String, :length => 60
    property :nombre_corto_ca, String, :length => 60
    property :nombre_ca, String, :length => 100
    property :sigla_ca, String, :length => 10
    property :pregrado, Boolean

    def nivel
        titulo = self.titulo_ca
        lvl = nil
        lvl = PlanEstudio::PROFESIONAL if (titulo.include?("INGENIER") or titulo.include?("CONTADOR"))
        lvl = PlanEstudio::DIPLOMADO if (titulo.include?("DIPLOMADO"))
        lvl = PlanEstudio::CEIA if (titulo.include?("CEIA"))

        #lvl = PlanEstudio::TECNICO if ti.include?("TECNICO") || ti.include?("GASTRONOMIA")

        

        lvl = PlanEstudio::TECNICO if lvl.nil?

        return lvl
    end

    has n, :matriculas, "ModelosAntiguos::Matricula", :parent_key => "id_ca", :child_key => "id_ca"
    has n, :mallas, "ModelosAntiguos::Malla", parent_key: :id_ca, child_key: :id_ca
    has n, :asignatura_impartida, "ModelosAntiguos::AsignaturaImpartida", parent_key: :id_as, child_key: :id_as
    #repository(:db_antigua) do
    
    #end 
end

