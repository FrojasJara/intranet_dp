# encoding: utf-8
class PrecioArancel
        include DataMapper::Resource
        include DataMapper::Timestamps
        include DataMapper::Historylog

    storage_names[:default] = 'precios_aranceles'

	property 	:id,			Serial
	property 	:precio,		Integer, :required => true, :min => 1
	property 	:anio,			Integer, :required => true 
	property 	:tipo, 			Integer, :default => MatriculaPlan::PROFESIONAL_DOS_SEMESTRES
	property 	:tipo_alumno, 	Integer, :required => true
	property 	:contado, 		Boolean, :default => false
	property 	:mallas_hash,	Integer
	property 	:modalidad,		Integer
	property	:precio_5to,	Integer


	timestamps 	:at
    property 	:deleted_at, 	ParanoidDateTime
	
	belongs_to 	:institucion_sede_plan, required: false
	belongs_to  :sede, 			required: false

	#tipo_alumno	=> Corresponde al tipo que se encuentra en Alumno

    # NUEVO           = 1
    # SUPERIOR        = 2
    # TIPOS           = [
    #       :NUEVO,
    #       :SUPERIOR
    # ]

 	#tipo 	=> Corresponde al tipo que se encuentra en MatriculaPlan

    # TIPOS DE MATRICULA
	# Profesionales
	# PROFESIONAL_UN_SEMESTRE 					= 1 # => NO lleva arancel
	# PROFESIONAL_DOS_SEMESTRES 					= 2 # => Si lleva arancel Contado y Normal
	# TERMINAL									= 3 # => NO lleva Arancel
	# SALIDA_INTERMEDIA							= 4 # => Lleva Arancel de salida Intermedia similares Practica de Tecnicos, normal y contado

	# # Tecnicas
	# PRACTICA_TRABAJO_DE_TITULO 					= 5 # => LLeva Arancel Normal y Contado
	# TECNICA_UN_SEMESTRE 						= 6 # => No LLeva Arancel
	# TECNICA_DOS_SEMESTRES 						= 7 # => Lleva Arancel Normal y Contado

	# # Distancia (Todas son arancel con contado => false)
	# DISTANCIA_1_A_4_NIVEL 						= 8 # => LLeva Arancel Normal
	# DISTANCIA_5_A_8_NIVEL						= 9	# => LLeva Arancel Normal
	# DISTANCIA_SALIDA_INTERMEDIA_EXENTA 			= 10
	# DISTANCIA_SALIDA_INTERMEDIA_SEMI_EXENTA 	= 11
	# DISTANCIA_SALIDA_INTERMEDIA_COMPLETA 		= 12 
	# DISTANCIA_TERMINAL_EXENTA 					= 13
	# DISTANCIA_TERMINAL_SEMI_EXENTA 				= 14
	# DISTANCIA_TERMINAL_COMPLETA 				= 15

	# # Preu y CEIA
	# CEIA_DOS_SEMESTRES							= 16 # => Arancel NORMAL 
	# PREU_DOS_SEMESTRES							= 17 # => Arancel

	# # Continuidad y otros
	# CONTINUIDA_EXENTA 							= 18


	# TIPOS 	= [
	# 	# Profesionales
	# 	:PROFESIONAL_UN_SEMESTRE, 
	# 	:PROFESIONAL_DOS_SEMESTRES,
	# 	:TERMINAL, 
	# 	:SALIDA_INTERMEDIA, 

	# 	# Tecnicas
	# 	:PRACTICA_TRABAJO_DE_TITULO, 
	# 	:TECNICA_UN_SEMESTRE,
	# 	:TECNICA_DOS_SEMESTRES,

	# 	# Distancia
	# 	:DISTANCIA_1_A_4_NIVEL,
	# 	:DISTANCIA_5_A_8_NIVEL,
	# 	:DISTANCIA_SALIDA_INTERMEDIA_EXENTA,
	# 	:DISTANCIA_SALIDA_INTERMEDIA_SEMI_EXENTA,
	# 	:DISTANCIA_SALIDA_INTERMEDIA_COMPLETA,
	# 	:DISTANCIA_TERMINAL_EXENTA,
	# 	:DISTANCIA_TERMINAL_SEMI_EXENTA,
	# 	:DISTANCIA_TERMINAL_COMPLETA, 

	# 	# Preu y CEIA
	# 	:CEIA_DOS_SEMESTRES,
	# 	:PREU_DOS_SEMESTRES,

	# 	# Sin pagos hacer la continuidad
	# 	:CONTINUIDA_EXENTA
	# ]

end
