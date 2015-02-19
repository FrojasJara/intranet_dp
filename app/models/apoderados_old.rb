# encoding: utf-8
class ApoderadoOld
    include DataMapper::Resource
    include DataMapper::Timestamps
    #include DataMapper::Historylog

    storage_names[:default] = 'apoderados_old'

    property    :rut_ap,              String, key: true 
    property    :apellido_ap,         String, length: 25
    property    :nombre_ap,           String, length: 25    
    property    :apellido_al,         String, length: 25
   	property    :nombre_al,           String, length: 25
   	property    :rut_al,              String

    timestamps :at
end
