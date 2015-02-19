# encoding: utf-8
require 'json'

class Matriculas::Ajax::DocumentosVentaController < ApplicationController

	layout nil

	def verificar_validez
		institucion_sede_plan 		= InstitucionSedePlan.get! params[:institucion_sede_plan_id]
		ejecutivo 					= EjecutivoMatriculas.get! params[:ejecutivo_matriculas_id]

		institucion_sede 			= institucion_sede_plan.institucion_sede
		institucion 				= institucion_sede.institucion
		sede 						= institucion_sede.sede

		numero 						= params[:numero_documento].to_i
		tipo 						= params[:tipo_documento].to_i

		boleta 						= DocumentoVenta.first numero: numero,
														   estado: DocumentoVenta::ENTREGADA,
														   institucion_sede: {
														   		institucion_id: institucion.id.to_i,
														   },
														   tipo: tipo

        unless boleta.nil?
			raise DataMapper::ObjectNotFoundError.new("El documento consultado ya ha sido utilizado por la institución.")
		end

		# Debemos determinar el centro de costos del talonario ... [ip, cft, distancia, etc]
		if institucion_sede_plan.modalidad == InstitucionSedePlan::DISTANCIA
			centro_costos = RangoDocumento::TALONARIOS_DISTANCIA

			# El talonario es comun a varios ejecutivos
			talonario = RangoDocumento.first(
				:fecha_recepcion 	=> nil, 
				:tipo 				=> tipo, 
				:inicio.lte 		=> numero, 
				:fin.gte 			=> numero,
				:centro_costos 		=> centro_costos
			)
		else
			centro_costos = RangoDocumento::TALONARIOS_PRESENCIALES

			# El talonario es del ejecutivo
			talonario = ejecutivo.rangos_documentos.first(
				:fecha_recepcion 	 => nil, 
				:tipo 				 => tipo, 
				:inicio.lte 		 => numero, 
				:fin.gte 			 => numero,
				:centro_costos 		 => centro_costos,
				:institucion_sede 	 => {
					institucion_id: 	institucion_sede_plan.institucion_sede.institucion_id
				}
			)
		end

		if talonario.nil?
			raise DataMapper::ObjectNotFoundError.new("El documento consultado no está asociado a ninguno de sus talonarios vigentes.")
		end

		render :json => {
			:exito 		=> true,
			:mensaje	=> "Esta usando el talonario #{talonario.nombre.upcase}."
		}

	rescue DataMapper::ObjectNotFoundError => e
		render :json => {
			:exito 		=> false,
			:mensaje 	=> e.message
		}
	rescue Excepciones::OperacionNoPermitidaError => e
		render :json => {
			:exito 		=> false,
			:mensaje 	=> e.message
		}
	end

	def verificar_validez_certificados
		alumno_plan_estudio 		= AlumnoPlanEstudio.get! params[:alumno_plan_estudio_id].to_i
		institucion_sede_plan 		= InstitucionSedePlan.get! alumno_plan_estudio.institucion_sede_plan_id.to_i

		ejecutivo 					= EjecutivoMatriculas.get! params[:ejecutivo_matriculas_id].to_i

		institucion_sede 			= institucion_sede_plan.institucion_sede
		institucion 				= institucion_sede.institucion
		sede 						= institucion_sede.sede

		numero 						= params[:numero_documento].to_i
		tipo 						= params[:tipo_documento].to_i

		boleta 						= DocumentoVenta.first numero: numero,
														   estado: DocumentoVenta::ENTREGADA,
														   institucion_sede: {
														   		institucion_id: institucion.id.to_i,
														   },
														   tipo: tipo

        unless boleta.nil?
			raise DataMapper::ObjectNotFoundError.new("El documento consultado ya ha sido utilizado por la institución.")
		end

		# Debemos determinar el centro de costos del talonario ... [ip, cft, distancia, etc]
		if institucion_sede_plan.modalidad == InstitucionSedePlan::DISTANCIA
			centro_costos = RangoDocumento::TALONARIOS_DISTANCIA

			# El talonario es comun a varios ejecutivos
			talonario = RangoDocumento.first(
				:fecha_recepcion 	=> nil, 
				:tipo 				=> tipo, 
				:inicio.lte 		=> numero, 
				:fin.gte 			=> numero,
				:centro_costos 		=> centro_costos
			)
		else
			centro_costos = RangoDocumento::TALONARIOS_PRESENCIALES

			# El talonario es del ejecutivo
			talonario = ejecutivo.rangos_documentos.first(
				:fecha_recepcion 	 => nil, 
				:tipo 				 => tipo, 
				:inicio.lte 		 => numero, 
				:fin.gte 			 => numero,
				:centro_costos 		 => centro_costos,
				:institucion_sede 	 => {
					institucion_id: 	institucion_sede_plan.institucion_sede.institucion_id
				}
			)
		end

		if talonario.nil?
			raise DataMapper::ObjectNotFoundError.new("El documento consultado no está asociado a ninguno de sus talonarios vigentes.")
		end

		render :json => {
			:exito 		=> true,
			:mensaje	=> "Esta usando el talonario #{talonario.nombre.upcase}."
		}

	rescue DataMapper::ObjectNotFoundError => e
		render :json => {
			:exito 		=> false,
			:mensaje 	=> e.message
		}
	rescue Excepciones::OperacionNoPermitidaError => e
		render :json => {
			:exito 		=> false,
			:mensaje 	=> e.message
		}
	end

	def verificar_validez_documento_anonimo
		institucion_sede 			= InstitucionSede.first institucion_id: params[:institucion_id],
															sede_id: 		params[:sede_id]

		ejecutivo 					= EjecutivoMatriculas.get! params[:ejecutivo_matriculas_id]

		institucion 				= institucion_sede.institucion
		sede 						= institucion_sede.sede

		numero 						= params[:numero_documento].to_i
		tipo 						= params[:tipo_documento].to_i
		modalidad 					= params[:modalidad].to_i

		boleta 						= DocumentoVenta.first numero: numero,
														   estado: DocumentoVenta::ENTREGADA,
														   institucion_sede: {
														   		institucion_id: institucion.id.to_i,
														   },
														   tipo: tipo

        unless boleta.nil?
			raise DataMapper::ObjectNotFoundError.new("El documento consultado ya ha sido utilizado por la institución.")
		end

		# Debemos determinar el centro de costos del talonario ... [ip, cft, distancia, etc]
		if modalidad == InstitucionSedePlan::DISTANCIA
			centro_costos = RangoDocumento::TALONARIOS_DISTANCIA

			# El talonario es comun a varios ejecutivos
			talonario = RangoDocumento.first(
				:fecha_recepcion 	=> nil, 
				:tipo 				=> tipo, 
				:inicio.lte 		=> numero, 
				:fin.gte 			=> numero,
				:centro_costos 		=> centro_costos
			)
		else
			centro_costos = RangoDocumento::TALONARIOS_PRESENCIALES

			# El talonario es del ejecutivo
			talonario = ejecutivo.rangos_documentos.first(
				:fecha_recepcion 	 => nil, 
				:tipo 				 => tipo, 
				:inicio.lte 		 => numero, 
				:fin.gte 			 => numero,
				:centro_costos 		 => centro_costos,
				:institucion_sede 	 => {
					institucion_id: 	institucion_sede.institucion_id
				}
			)
		end

		if talonario.nil?
			raise DataMapper::ObjectNotFoundError.new("El documento consultado no está asociado a ninguno de sus talonarios vigentes.")
		end

		render :json => {
			:exito 		=> true,
			:mensaje	=> "Esta usando el talonario #{talonario.nombre.upcase}."
		}

	rescue DataMapper::ObjectNotFoundError => e
		render :json => {
			:exito 		=> false,
			:mensaje 	=> e.message
		}
	rescue Excepciones::OperacionNoPermitidaError => e
		render :json => {
			:exito 		=> false,
			:mensaje 	=> e.message
		}
	end
end