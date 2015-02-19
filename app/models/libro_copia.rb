# encoding: utf-8
class LibroCopia
	include DataMapper::Resource
	include DataMapper::Timestamps
	#include DataMapper::Historylog

	storage_names[:default] = 'copias_libros'

	property :id, 			Serial
	property :folio, 		String

	property :numero, 		Integer

	
	timestamps 	:at
	property    :deleted_at,    ParanoidDateTime

	# => relaciones
	belongs_to :libro_titulo, 	required: false

end