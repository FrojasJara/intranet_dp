# encoding: utf-8
require "date"

class DocumentoVenta
	include DataMapper::Resource
	include DataMapper::Timestamps
	include DataMapper::Historylog

	storage_names[:default] = 'documentos_ventas'

	# Tipos de documento emitidos
    BOLETA       = 1
    FACTURA      = 2
    TIPOS        = [:BOLETA, :FACTURA]
    
    # Estados de documento emitidos
    RETENIDA     = 1
    ENTREGADA    = 2
    ANULADA      = 3
    SIN_FABRICAR = 4
    
    ESTADOS      = [
		:RETENIDA,
		:ENTREGADA,
		:ANULADA
	]

    # Modalidades de documento emitidos (solo para documentos anonimos)
    PRESENCIAL   = 1
    DISTANCIA    = 2
    MODALIDADES  = [:PRESENCIAL, :DISTANCIA]

    property    :id, 	           Serial
    property    :estado,           Integer,    :required    => true, :default => DocumentoVenta::ENTREGADA
    property    :tipo,             Integer,    :required    => true
    property    :fecha_emision,    DateTime,   :default     => Time.now
    property    :numero,           Integer,    :required    => true, :min => 1
    property    :monto,            Integer,    :required    => true, :min => 0
    property    :fecha_anulacion,  DateTime

    property    :rut,               String
    property    :nombre_completo,   String,     :length => 155
    property    :carrera,           String,     :length => 155
    property    :direccion,         String,     :length => 255
    property    :giro,              String,     :length => 155
    property    :modalidad,         Integer,    :min => 1, :max => 2
    

    timestamps  :at
    property    :deleted_at,       ParanoidDateTime

	has n,      :abonos

	belongs_to 	:plan_pago, 			:required => false
	belongs_to 	:ejecutivo_matriculas
	belongs_to  :alumno_plan_estudio,   required: false
	belongs_to 	:institucion_sede
end