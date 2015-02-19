# encoding: utf-8
class Asistencia
	include DataMapper::Resource
	include DataMapper::Timestamps
	include DataMapper::Historylog

	storage_names[:default] = 'asistencias'

	ASISTIDA 		= 1
	AUSENTADA 		= 2
	JUSTIFICADA 	= 3
	ESTADOS 		= [
		:ASISTIDA,
		:AUSENTADA,
		:JUSTIFICADA
	]

	property 	:id,						Serial
	property 	:horas_asistidas, 			Integer, :required => true, :default => 0
	property 	:horas_ausentadas, 			Integer, :required => true, :default => 0
	property 	:horas_justificadas, 		Integer, :default => 0
    property    :estado,	               	Integer, :required => true

	timestamps 	:at

	belongs_to 	:clase
	belongs_to 	:alumno_inscrito_seccion


	def self.asistio_a_clase?(alumno_inscrito_seccion_id, clase_id)
		asistencia = Asistencia.all(:fields => [:id, :horas_asistidas, :horas_ausentadas],:alumno_inscrito_seccion_id => alumno_inscrito_seccion_id, :clase_id => clase_id).first
		rtrn = !asistencia.blank? ? {:id => asistencia.id, :asistio => true, :horas_asistidas => asistencia.horas_asistidas, :horas_ausentadas => asistencia.horas_ausentadas} : {:asistio => false, :horas_asistidas => 0, :horas_ausentadas => 0}
		return rtrn
	end


end