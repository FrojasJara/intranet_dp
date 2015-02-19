# encoding: utf-8
class MedioPago 
	include DataMapper::Resource
	include DataMapper::Timestamps
	include DataMapper::Historylog

	property 	:id,			Serial
	property 	:nombre,		String
	property 	:slug,			Slug

	timestamps 	:at
    property 	:deleted_at, 	ParanoidDateTime
    property    :siaa_id,       Integer

	has n, 		:abono

	def self.for_select
		validos.map{|x| [x.nombre, x.id]}
	end

	def self.validos
		MedioPago.all(fields: [:id, :nombre, :slug])#, :slug.not => 'pagare-slash-cheque')
	end
end