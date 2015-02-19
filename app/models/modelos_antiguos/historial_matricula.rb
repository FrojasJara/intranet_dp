# coding: utf-8
class ModelosAntiguos::HistorialMatricula 

    include DataMapper::Resource

    def self.default_repository_name
        :db_antigua 
    end

    storage_names[:db_antigua] = 'historial_matriculas'


    property :oid,  Serial
    property :rut_al, Integer, :key => true
    property :id_jo, Integer
    property :id_ca, Integer, :key => true

    property :sem_hm, Integer, :key => true
    property :ano_hm, Integer, :key => true
    
    property :id_tp, Integer
    property :valor_mat_real_hm, Integer
    property :valor_mat_mod_hm, Integer
    property :valor_ara_real_hm, Integer
    property :valor_ara_mod_hm, Integer
    property :valor_reaju_hm, Integer
    property :valor_efe_hm, Integer
    property :valor_che_hm, Integer
    property :valor_tar_hm, Integer
    property :valor_pag_hm, Integer
    property :total_venta_hm, Integer

    property :pagare_ag, Integer
    property :boleta_pg, Integer

    property :fh_hm, String
    property :activo_hm, Boolean 

    belongs_to :alumno, "ModelosAntiguos::Persona", :parent_key => "rut_pe", :child_key => "rut_al"
    belongs_to :carrera, "ModelosAntiguos::Carrera", :parent_key => "id_ca", :child_key => "id_ca"    
    belongs_to :sede, "ModelosAntiguos::Sede", :parent_key => "id_se", :child_key => "id_se"


    def fecha
        self.fh_hm.nil? ? DateTime.now : self.fh_hm.split(".").first.to_datetime
    end

    def matricula
        return valor_mat_real_hm if valor_mat_mod_hm.blank?
        valor_mat_mod_hm < valor_mat_real_hm ? valor_mat_mod_hm : valor_mat_real_hm
    end

    def arancel
        val = valor_ara_real_hm.blank? ? 0 : valor_ara_real_hm
        val.nil? ? 0 : val
    end

    def descuento_arancel
        return valor_ara_real_hm if valor_ara_mod_hm.blank?
        val = valor_ara_mod_hm < valor_ara_real_hm ? (valor_ara_real_hm - valor_ara_mod_hm) : 0

        val.nil? ? 0 : val
    end

    def arancel_total
        begin
            return arancel - descuento_arancel
        rescue 
            return 0
        end
    end
end

