# encoding: utf-8
class Rol
    include DataMapper::Resource
    include DataMapper::Timestamp
    include DataMapper::Historylog

    storage_names[:default] = 'roles'

    property :id, 				            Serial

    property :nombre, 			            String

    property :por_defecto,                  Boolean, default: false

    property :alumno,                       Boolean

    property :academico,                    Boolean
    property :matriculas,                   Boolean
    property :cobranzas,                    Boolean
    property :docente,                      Boolean
    property :ac_mantenedores,              Boolean

    property :vicerrectoria_academica,      Boolean, default: false
    property :direccion_docencia,           Boolean, default: false
    property :direccion_escuela,            Boolean, default: false
    property :coordinador_carrera,          Boolean, default: false

    property :administrativo,               Boolean
    property :administrador, 	            Boolean
    property :mensajero,                    Boolean
    property :control_entrada,              Boolean

    property :apoyo_docente,                Boolean, default: false
    
    property :herramientas,                 Boolean, default: false
    property :biblioteca,                   Boolean, default: false
    property :asistente_social,                   Boolean, default: false

    timestamps :at
    
    property :deleted_at, 		            ParanoidDateTime

    has n,	 :usuarios

end