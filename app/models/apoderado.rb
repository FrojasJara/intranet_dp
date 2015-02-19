# encoding: utf-8
class Apoderado
	include DataMapper::Resource
	include DataMapper::Timestamps
	include DataMapper::Historylog

	LIQUIDACION_DE_SUELDO 		= 1
	BOLETA_DE_HONORARIOS		= 2
	NINGUNO						= 3
	DOCUMENTOS 					= [:LIQUIDACION_DE_SUELDO, :BOLETA_DE_HONORARIOS, :NINGUNO]

	property 	:id,						Serial
	property 	:documentos_presentados, 	Integer, 	:required => true
	property 	:es_alumno, 				Boolean, 	:required => true
    property    :siaa_id,               	Integer
    property    :siaa_updated_at,       	DateTime
    property	:siaa_id_sede_sync,			Integer

	timestamps 	:at
    property 	:deleted_at, 				ParanoidDateTime

	belongs_to 	:datos_personales, 'Usuario', :child_key => "usuario_id"
	has n, 		:alumnos
	has n,		:planes_pago, "PlanPago"

end