# encoding: utf-8
class ConvalidacionHomologacion
	include DataMapper::Resource
	include DataMapper::Timestamps
	include DataMapper::Historylog
	include DataMapper::Utils

	storage_names[:default] = 'convalidaciones_homologaciones'

	# Tipos
	CONVALIDACION	= 1
	HOMOLOGACION	= 2
	TIPOS = [:CONVALIDACION, :HOMOLOGACION]

	property 	:id,					Serial
	property 	:tipo, 					Integer, :required => true
	property	:anio_cursa,			Integer
	property	:semestre_cursa,		Integer
	property 	:carrera_convalidada,	String, length: 200
	property	:nro_documento,			Integer

	property	:siaa_rut_al,			Integer
	property 	:siaa_id_ca,			Integer
	property 	:siaa_id_as,			Integer
	property	:siaa_id_se,			Integer
	property 	:siaa_updated_at, 		DateTime
	property    :siaa_id_sede_sync,     Integer

	timestamps 	:at
 	property 	:deleted_at, 			ParanoidDateTime

	belongs_to	:periodo, 				required: false
	belongs_to  :responsable, "Usuario",child_key: :responsable_id, required: false
	belongs_to	:alumno_plan_estudio, 	required: false
	belongs_to  :institucion_externa,	required: false

end

