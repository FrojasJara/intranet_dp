# encoding: utf-8
class Certificado
	include DataMapper::Resource
	include DataMapper::Timestamps
	include DataMapper::Historylog

	storage_names[:default] = 'certificados'

	URL_DOCUMENTOS = Rails.root.join("public", "documentos", "certificados")

	property 	:id,					Serial
	property 	:numero,				Integer
	property	:impreso,				Boolean
	property 	:entregado,				Boolean
	property 	:lugar,					String
	property 	:cursa,					String
	property 	:observacion,			String
	property 	:observacion2,			String
	property 	:linea1,				String
	property 	:linea2,				String

	timestamps 	:at

	belongs_to 	:ejecutivo_matriculas
	belongs_to  :abono, 		required: false
	belongs_to  :alumno_plan_estudio
	belongs_to  :tipo_abono
end