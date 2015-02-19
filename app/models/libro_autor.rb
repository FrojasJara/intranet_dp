# encoding: utf-8
class LibroAutor
	include DataMapper::Resource
	include DataMapper::Timestamps
	#include DataMapper::Historylog

	storage_names[:default] = 'autores_libros'

	property :id, 				Serial
	property :nombres, 			String, :length => 100 

	timestamps 	:at
	property    :deleted_at,    ParanoidDateTime

	# => relaciones
	belongs_to :pais, 		:required => false
	
	has n, :libro_titulos
end