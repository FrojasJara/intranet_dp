# encoding: utf-8
class LibroTematica
	include DataMapper::Resource
	include DataMapper::Timestamps
	#include DataMapper::Historylog
	storage_names[:default] = 'tematicas_libros'


	property :id, 				Serial
	property :nombre, 			String, :length => 100 
	property :descripcion,		String, :length => 100


	timestamps 	:at
	property    :deleted_at,    ParanoidDateTime
	
	has n, :libro_titulo
end