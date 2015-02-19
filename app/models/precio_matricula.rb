# encoding: utf-8
require "date"
class PrecioMatricula
	include DataMapper::Resource
	include DataMapper::Timestamps
	include DataMapper::Historylog

	storage_names[:default] = 'precios_matriculas'

	property 	:id,					Serial
	property 	:precio,				Integer, 	:required => true, :min => 0
	property 	:fecha_inicio, 			Date,		:required => true 
	property 	:fecha_termino, 		Date, 		:required => true
	property 	:tipo_alumno, 			Integer, 	:required => true
	property 	:mallas_hash,			Integer
	property 	:modalidad,				Integer

	timestamps 	:at
    property 	:deleted_at, 			ParanoidDateTime

	belongs_to :institucion_sede_plan, 	required: false
	belongs_to :sede, 					required: false
end