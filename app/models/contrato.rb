# encoding: utf-8
class Contrato
	include DataMapper::Resource
	include DataMapper::Timestamps
	include DataMapper::Historylog

    URL_DOCUMENTOS = Rails.root.join("public", "documentos", "contratos")

	property 	:id,			  Serial
    property 	:anio, 		      Integer
    property 	:periodos,		  Integer
    property 	:fecha_inicio, 	  Date
    property 	:fecha_termino,	  Date
    property    :valor_hora,      Integer
    property    :empresa_trabaja, String

    timestamps 	:at
    property 	:deleted_at, 	  ParanoidDateTime

    belongs_to 	:docente
    belongs_to 	:institucion_sede
end