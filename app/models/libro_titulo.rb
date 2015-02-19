# encoding: utf-8
class LibroTitulo
	include DataMapper::Resource
	include DataMapper::Timestamps
	#include DataMapper::Historylog
	storage_names[:default] = 'titulos_libros'


	property :id, 				Serial
	property :nombre, 			String ,	:length => 255

	property :codigo_dewey, 	String 
	property :anio, 			Integer
	property :numero_copias, 	Integer,	:default => 0


	timestamps 	:at
	property    :deleted_at,    ParanoidDateTime

	# => relaciones
	belongs_to :libro_autor, 		required: false
	belongs_to :libro_tematica,		required: false
	belongs_to :sede, 		required: false

	has n, :libro_copias

end