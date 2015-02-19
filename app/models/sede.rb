# encoding: utf-8
class Sede
	include DataMapper::Resource
	include DataMapper::Timestamps
	include DataMapper::Historylog

	property 	:id,			Serial
	property 	:nombre,		String
	property 	:direccion,		String, :length => 100
	property 	:telefono, 		String
	property 	:email,			String
	property 	:ciudad, 		String

	timestamps 	:at
    property 	:deleted_at, 	ParanoidDateTime

	has n, 		:institucion_sedes
    has n, 		:salas
    has n, 		:usuarios

    has n, 		:precio_arancel
    has n,		:precio_matricula

    has n,		:bloque_horarios

    CONCEPCION      = 1
	CHILLAN         = 2
	NUNOA           = 3
	BOSQUE          = 4
	VIÑA            = 5
	BARROS_ARANA    = 6
	VIÑA_NORTE      = 7
	MIRAFLORES      = 8
	
	SEDES  = [
		:CONCEPCION,
		:CHILLAN,
		:NUNOA,
		:BOSQUE,
		:VIÑA,
		:BARROS_ARANA,
		:VIÑA_NORTE,
		:MIRAFLORES,
	]

	SEDES_VIGENTES  = [
		CONCEPCION,
		CHILLAN,
		NUNOA,
		BOSQUE,
		VIÑA
	]
end