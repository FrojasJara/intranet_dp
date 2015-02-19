# encoding: utf-8
class FormaPlanPago
	include DataMapper::Resource
	include DataMapper::Timestamps
	include DataMapper::Historylog

	PLAN_SIN_INTERES 	= 1
	MATRICULA 			= 2
=begin
	ALUMNO_NUEVO 		= 1
	ALUMNO_SUPERIOR 	= 2
	ALUMNO_DISTANCIA 	= 3

	TIPOS = [:ALUMNO_NUEVO, :ALUMNO_SUPERIOR, :ALUMNO_DISTANCIA, :MATRICULA]
=end

	property 	:id,				Serial
	property 	:numero_cuotas, 	Integer,	:required => true, :min => 1
	property 	:interes,			Float,		:required => true, :min => 0.0
	property 	:nombre,			String, 	:required => true
	property 	:tipo,				Integer, 	:required => true

=begin
	def self.planes_alumno_nuevo
		all :tipo => FormaPlanPago::ALUMNO_NUEVO
	end

	def self.planes_alumno_superior
		all :tipo => FormaPlanPago::ALUMNO_SUPERIOR
	end

	def self.planes_alumno_distancia
		all :tipo => FormaPlanPago::ALUMNO_DISTANCIA
	end
=end
	def self.planes_matricula; all :tipo => FormaPlanPago::MATRICULA end

	def self.plan_sin_interes; all :tipo => FormaPlanPago::PLAN_SIN_INTERES end

	timestamps 	:at
    property 	:deleted_at, 		ParanoidDateTime
end