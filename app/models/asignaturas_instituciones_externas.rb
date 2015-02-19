# encoding: utf-8
class AsignaturasInstitucionesExternas
	include DataMapper::Resource
	include DataMapper::Timestamps
	include DataMapper::Historylog

	storage_names[:default] = 'asignaturas_instituciones_externas'

	property 	:id,					Serial
	property	:nombre,				String
	property	:nota_final,			Float

	timestamps 	:at
 	property 	:deleted_at, 	ParanoidDateTime

	belongs_to  :validacion, "ConvalidacionHomologacion", required: false
	belongs_to	:seccion_alumno, "AlumnoInscritoSeccion", child_key: :seccion_alumno_id, required: false
end