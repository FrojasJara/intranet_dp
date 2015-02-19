# encoding: utf-8
class InstitucionSede
	include DataMapper::Resource
	include DataMapper::Timestamps
	include DataMapper::Historylog

	storage_names[:default] = 'institucion_sedes'

	property 	:id,				Serial
	property 	:esta_abierta, 		Boolean
	property    :siaa_id,           Integer
    property    :siaa_updated_at,   DateTime
    property 	:decreto,			String


	timestamps 	:at
   	property 	:deleted_at, 			ParanoidDateTime

	has n, 		:institucion_sede_plan
	has n, 		:contratos
	has n, 		:electivos
	has n, 		:pago_comprometido
	has n, 		:pagares
	has n, 		:documentos_venta, 		"DocumentoVenta"
	has n, 		:rango_documento

	belongs_to 	:institucion
	belongs_to 	:sede

	# DEPLOY
	#has n, 		:usuarios

	#TODAS	= -1 #Para informes globales

	def self.obtener_abiertas
		items = Array.new
		all(:esta_abierta => true).each do |item|
			items << {"id" => item.id, "nombre" => item.institucion.nombre + " - " + item.sede.nombre}
		end
		return items
	end

	def nombre
		return institucion.nombre + " - " + sede.nombre
	end

	def nombre_corto
		nombre.gsub("Instituto Profesional", "IP").gsub("Centro de Formación Técnica", "CFT").gsub("Casa matriz", "").gsub("Sede", "")
	end

	def self.instituciones_en_sede sede_id
		_sede = Sede.get sede_id
		_instituciones_sedes = all :sede => _sede,
								   :order => [:sede_id,:institucion_id]

		_instituciones = _instituciones_sedes.institucion

		data = _instituciones_sedes.map do |is|
			i = _instituciones.select{ |i| i.id == is.institucion_id }.first
			{
				:institucion_sede_id => is.id,
				:nombre              => "#{i.nombre} - #{_sede.ciudad}",
				:institucion_id      => is.institucion_id
			}
		end
		data
	end

	def self.nombre_sede sede_id
		sedes = Sede.all
		nombre=""
		sedes.each do |sede|
			if sede_id == sede.id
				nombre = sede.nombre
			end
		end

		nombre
	end

	def self.instituciones_en_sede_all sede_id
		_sede = Sede.get sede_id
		_instituciones_sedes = all order: [:sede_id,:institucion_id]
		_instituciones = _instituciones_sedes.institucion


		data = _instituciones_sedes.map do |is|
			i = _instituciones.select{ |i| i.id == is.institucion_id }.first
			{
				:institucion_sede_id => is.id,
				:nombre              => "#{i.nombre} - #{nombre_sede(is.sede_id)}",
				:institucion_id      => is.institucion_id
			}
		end

		data
	end

	def self.obtener_nombres_para_select
		institucion_sedes = []
		
		sedes = Sede.all(fields: [:id, :nombre])
		instituciones = Institucion.all(fields: [:id, :nombre])

		InstitucionSede.all(fields: [:id, :sede_id, :institucion_id], institucion_id: 1, esta_abierta: 1).each do |i|
			sede = sedes.select { |x| x.id == i.sede_id }.first
			institucion = instituciones.select {|x| x.id == i.institucion_id}.first
			institucion_sedes << [i.id, "#{sede[:nombre]} #{institucion[:nombre]}"]
		end

		institucion_sedes
	end
end
