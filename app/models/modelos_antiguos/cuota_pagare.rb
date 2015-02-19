# coding: utf-8
class ModelosAntiguos::CuotaPagare 

    include DataMapper::Resource

    def self.default_repository_name
        :db_antigua 
    end

    storage_names[:db_antigua] = 'cuotas_pagares'

    property :oid,          Integer, key: true
    property :pagare_ag,    Integer
    property :rut_al,       Integer
    property :nro_cuota_cp, Integer
    property :valor_cp,     Integer
    property :fh_venc_cp,   String
    property :nulo_cp,      Boolean
    property :fh_trans_cp,  String
    property :id_se,        Integer

end

