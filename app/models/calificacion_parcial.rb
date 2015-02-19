# encoding: utf-8
class CalificacionParcial
	include DataMapper::Resource
	include DataMapper::Timestamps
	include DataMapper::Historylog

	storage_names[:default] = 'calificaciones_paciales'

	CALIFICADA 		= 1
	AUSENTADA		= 2
	JUSTIFICADA 	= 3
	ESTADOS 		= [
		:CALIFICADA,
		:AUSENTADA,
		:JUSTIFICADA
	]

	NOTA_EXAMEN				= 3.0
	NOTA_EXAMEN_APROXIMADA 	= 2.95

	NOTA_EXIMIDO			= 5.5		
	NOTA_EXIMIDO_APROXIMADA = 5.45

	NOTA_MINIMA 			= 4.0
	NOTA_MINIMA_APROXIMADA 	= 3.95

	EXIGENCIA_MINIMA		= 0.6

	NO_CUMPLE_REQUISITOS = 0.0

	property 	:id,					Serial
	property 	:calificacion, 			Float
	property 	:estado, 				Integer, 	:default => CalificacionParcial::CALIFICADA

	property 	:siaa_id,				Integer
	property 	:siaa_updated_at,		DateTime
	property    :siaa_id_sede_sync, 	Integer

	timestamps 	:at

  	belongs_to :alumno_inscrito_seccion
  	belongs_to :planificacion_calificacion


  	def self.nota_alumno_planificada(alumno_inscrito_seccion_id, planificacion_calificacion_id)
  		nota = CalificacionParcial.first(
  						:fields =>[
  									:id, :calificacion, 
  									:alumno_inscrito_seccion_id, 
  									:planificacion_calificacion_id
  									],
  						:alumno_inscrito_seccion_id => alumno_inscrito_seccion_id,
  						:planificacion_calificacion_id =>planificacion_calificacion_id
  					) 
  		return nota.blank? ? nil : nota
  	end

  	


end