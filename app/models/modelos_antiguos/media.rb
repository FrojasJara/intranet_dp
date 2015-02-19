# coding: utf-8
class ModelosAntiguos::Media 
    include DataMapper::Resource

    def self.default_repository_name
        :db_antigua 
    end

    storage_names[:db_antigua] = 'medias'

    property :id_dn,            Serial
    property :nombre_dn,        String
    property :codigo_dn,        String
    property :domicilio_dn,     String
    property :sector_dn,       String

    def nombre
        self.nombre_dn.unpack("C*").pack("U*")
    end

end

