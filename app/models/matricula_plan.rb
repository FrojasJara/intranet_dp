# encoding: utf-8
require "date"

class MatriculaPlan
	include DataMapper::Resource
	include DataMapper::Timestamps
	include DataMapper::Historylog

	storage_names[:default] = 'matriculas_planes'
	
	VIGENTE 	= 1
	ANULADA 	= 2
	EXPIRADA	= 3
	ESTADOS 	= [
		:VIGENTE, 
		:ANULADA, 
		:EXPIRADA
	]

	# TIPOS DE MATRICULA
	
	# Profesionales
	PROFESIONAL_UN_SEMESTRE 					= 1 # => NO lleva arancel
	PROFESIONAL_DOS_SEMESTRES 					= 2 # => Si lleva arancel Contado y Normal
	TERMINAL									= 3 # => NO lleva Arancel
	SALIDA_INTERMEDIA							= 4 # => Lleva Arancel de salida Intermedia similares Practica de Tecnicos, normal y contado

	# Tecnicas
	PRACTICA_TRABAJO_DE_TITULO 					= 5 # => LLeva Arancel Normal y Contado
	TECNICA_UN_SEMESTRE 						= 6 # => No LLeva Arancel
	TECNICA_DOS_SEMESTRES 						= 7 # => Lleva Arancel Normal y Contado

	# Distancia (Todas son arancel con contado => false)
	DISTANCIA_1_A_4_NIVEL 						= 8 # => LLeva Arancel Normal
	DISTANCIA_5_A_8_NIVEL						= 9	# => LLeva Arancel Normal
	DISTANCIA_SALIDA_INTERMEDIA_EXENTA 			= 10
	DISTANCIA_SALIDA_INTERMEDIA_SEMI_EXENTA 	= 11
	DISTANCIA_SALIDA_INTERMEDIA_COMPLETA 		= 12 
	DISTANCIA_TERMINAL_EXENTA 					= 13
	DISTANCIA_TERMINAL_SEMI_EXENTA 				= 14
	DISTANCIA_TERMINAL_COMPLETA 				= 15

	# Preu y CEIA
	CEIA_DOS_SEMESTRES							= 16 # => Arancel NORMAL 
	PREU_DOS_SEMESTRES							= 17 # => Arancel

	# Continuidad y otros
	CONTINUIDA_EXENTA 							= 18

	OTEC_UN_SEMESTRE							= 19 # => Arancel
	OTEC_UN_SEMESTRE_SENCE						= 20 # => Arancel


	TIPOS 	= [
		# Profesionales
		:PROFESIONAL_UN_SEMESTRE, 
		:PROFESIONAL_DOS_SEMESTRES,
		:TERMINAL, 
		:SALIDA_INTERMEDIA, 

		# Tecnicas
		:PRACTICA_TRABAJO_DE_TITULO, 
		:TECNICA_UN_SEMESTRE,
		:TECNICA_DOS_SEMESTRES,

		# Distancia
		:DISTANCIA_1_A_4_NIVEL,
		:DISTANCIA_5_A_8_NIVEL,
		:DISTANCIA_SALIDA_INTERMEDIA_EXENTA,
		:DISTANCIA_SALIDA_INTERMEDIA_SEMI_EXENTA,
		:DISTANCIA_SALIDA_INTERMEDIA_COMPLETA,
		:DISTANCIA_TERMINAL_EXENTA,
		:DISTANCIA_TERMINAL_SEMI_EXENTA,
		:DISTANCIA_TERMINAL_COMPLETA, 

		# Preu CEIA y OTEC
		:CEIA_DOS_SEMESTRES, 
		:PREU_DOS_SEMESTRES, 
		:OTEC_UN_SEMESTRE,
		:OTEC_UN_SEMESTRE_SENCE,

		# Sin pagos hacer la continuidad
		:CONTINUIDA_EXENTA 
	]

	# No referenciadas como simbolos, para obtener valor numerico directo

	MATRICULAS_SEMESTRALES = [
		PROFESIONAL_UN_SEMESTRE,
		TERMINAL,
		SALIDA_INTERMEDIA,
		PRACTICA_TRABAJO_DE_TITULO,
		TECNICA_UN_SEMESTRE,
		DISTANCIA_SALIDA_INTERMEDIA_EXENTA,
		DISTANCIA_SALIDA_INTERMEDIA_SEMI_EXENTA,
		DISTANCIA_SALIDA_INTERMEDIA_COMPLETA,
		DISTANCIA_TERMINAL_EXENTA,
		DISTANCIA_TERMINAL_SEMI_EXENTA,
		DISTANCIA_TERMINAL_COMPLETA,
		OTEC_UN_SEMESTRE,
		OTEC_UN_SEMESTRE_SENCE,
		CONTINUIDA_EXENTA
	]

	MATRICULAS_ANUALES_VALORES = [
		PROFESIONAL_DOS_SEMESTRES,
		TECNICA_DOS_SEMESTRES,
		DISTANCIA_1_A_4_NIVEL,
		DISTANCIA_5_A_8_NIVEL,
		CEIA_DOS_SEMESTRES,
		PREU_DOS_SEMESTRES
	]

	MATRICULAS_AFECTAS_PAGO_CONTADO = [
		PROFESIONAL_DOS_SEMESTRES,
		SALIDA_INTERMEDIA,
		TECNICA_DOS_SEMESTRES,
		PRACTICA_TRABAJO_DE_TITULO,
		CEIA_DOS_SEMESTRES,
		OTEC_UN_SEMESTRE,
		OTEC_UN_SEMESTRE_SENCE
	]

	MATRICULAS_AFECTAS_COBROS_ESPECIALES = [
		PROFESIONAL_UN_SEMESTRE,
		TERMINAL,
		TECNICA_UN_SEMESTRE
	]

	EXENTAS_MATRICULA = [
		DISTANCIA_SALIDA_INTERMEDIA_EXENTA,
		DISTANCIA_TERMINAL_EXENTA,
		CONTINUIDA_EXENTA
	]

	EXENTAS_ARANCEL = [
		DISTANCIA_SALIDA_INTERMEDIA_EXENTA,
		DISTANCIA_SALIDA_INTERMEDIA_SEMI_EXENTA,
		DISTANCIA_TERMINAL_EXENTA,
		DISTANCIA_TERMINAL_SEMI_EXENTA,
		CONTINUIDA_EXENTA
	]

	MATRICULAS_ALUMNO_NUEVO = [
		PROFESIONAL_DOS_SEMESTRES,
		TECNICA_DOS_SEMESTRES,
		DISTANCIA_1_A_4_NIVEL,
		CEIA_DOS_SEMESTRES,
		PREU_DOS_SEMESTRES,
		OTEC_UN_SEMESTRE,
		OTEC_UN_SEMESTRE_SENCE
	]

	MATRICULAS_ALUMNO_SUPERIOR_IP = [
		:PROFESIONAL_UN_SEMESTRE,
		:PROFESIONAL_DOS_SEMESTRES,
		:TERMINAL, 
		:SALIDA_INTERMEDIA,
		:TECNICA_UN_SEMESTRE,
		:TECNICA_DOS_SEMESTRES,
		:PRACTICA_TRABAJO_DE_TITULO
	]

	PROFESIONALES = [
		:PROFESIONAL_UN_SEMESTRE, 
		:PROFESIONAL_DOS_SEMESTRES,
		:TERMINAL, 
		:SALIDA_INTERMEDIA,
		:CONTINUIDA_EXENTA
	]

	TECNICAS = [
		:TECNICA_UN_SEMESTRE,
		:TECNICA_DOS_SEMESTRES,
		:PRACTICA_TRABAJO_DE_TITULO,
		:CONTINUIDA_EXENTA
	]

	DISTANCIA = [
		:DISTANCIA_1_A_4_NIVEL,
		:DISTANCIA_5_A_8_NIVEL,
		:DISTANCIA_SALIDA_INTERMEDIA_EXENTA,
		:DISTANCIA_SALIDA_INTERMEDIA_SEMI_EXENTA,
		:DISTANCIA_SALIDA_INTERMEDIA_COMPLETA,
		:DISTANCIA_TERMINAL_EXENTA,
		:DISTANCIA_TERMINAL_SEMI_EXENTA,
		:DISTANCIA_TERMINAL_COMPLETA
	]

	EXTENSION_PROFESIONALES = [
		:PROFESIONAL_UN_SEMESTRE, 
		:TERMINAL, 
		:SALIDA_INTERMEDIA
	]

	EXTENSION_TECNICAS = [
		:TECNICA_UN_SEMESTRE,
		:PRACTICA_TRABAJO_DE_TITULO
	]

	property 	:id,                  			Serial
	property 	:estado, 						Integer, 	:default => MatriculaPlan::VIGENTE
	property 	:medio, 						Integer
	property 	:fecha_anulacion, 				DateTime
	

	property 	:siaa_id,						Integer
    property    :siaa_updated_at,              	DateTime
    property    :siaa_id_sede_sync,            	Integer

	timestamps 	:at
    property 	:deleted_at, 					ParanoidDateTime

	
	belongs_to 	:periodo, 						:required => false # Cambiar a true luego	
	belongs_to 	:alumno_plan_estudio, 			:required => false # Remover luego
	belongs_to  :ejecutivo_matriculas, 			:required => false
	has n, 		:planes_pago, 					"PlanPago"

	validates_with_method :es_matricula_valida?

	def es_matricula_valida?
		if estado == MatriculaPlan::VIGENTE
			matricula_vigente = MatriculaPlan.first :periodo_id => periodo_id, :alumno_plan_estudio_id => alumno_plan_estudio_id, :estado => MatriculaPlan::VIGENTE, :id.not => id
			if matricula_vigente.nil?
				true
			else
				return [false, "El alumno ya registra matrícula vigente para el periodo en cuestión"]
			end
		else
			return true
		end
	end

	def anular
		MatriculaPlan.transaction do
			pagos_comprometidos = planes_pago.pagos_comprometidos
			pagares 	= planes_pago.pagares
			abonos 		= pagos_comprometidos.abonos
			documentos 	= planes_pago.documentos_venta

			ahora = Time.now

			update :estado => MatriculaPlan::ANULADA
			planes_pago.update :estado => PlanPago::ANULADO
			documentos.update :estado => DocumentoVenta::ANULADA, :fecha_anulacion => ahora
			pagares.update :estado => Pagare::ANULADO, :fecha_anulacion => ahora
			pagos_comprometidos.update :estado => PagoComprometido::ANULADO, :fecha_anulacion => ahora
			abonos.update :estado => PagoComprometido::ANULADO
		end
	end

	def ejecutivo_matriculas_puede_editar? e_matriculas_id
		estado == MatriculaPlan::VIGENTE and created_at.to_date == Date.today and ejecutivo_matriculas_id == e_matriculas_id
	end

	def self.editar(
			matricula_id, 			matricula_plan, 		inscripcion, 
			usuario_alumno, 		alumno, 				documentos_alumno,
			apoderado_es_el_alumno, usuario_apoderado_id, 	usuario_apoderado,
			apoderado,				e_matriculas_id, 		sede_id,
			nivel
		)

		matricula = MatriculaPlan.get! matricula_id
		plan = matricula.planes_pago.first :estado => PlanPago::VIGENTE

		raise Excepciones::OperacionNoPermitidaError, "No esta autorizado para editar la matrícula" if not matricula.ejecutivo_matriculas_puede_editar? e_matriculas_id
		
		_inscripcion = AlumnoPlanEstudio.get! inscripcion.delete("id")
		
		MatriculaPlan.transaction do		
			# Actualizar el alumno
			_usuario_alumno = Usuario.get! usuario_alumno.delete("id")
			usuario_alumno["password"] = Digest::MD5.hexdigest(usuario_alumno["rut"])
			_usuario_alumno.update usuario_alumno

			_alumno = _usuario_alumno.alumno
			documentos = documentos_alumno
			_alumno.tiene_certificado_nacimiento = documentos.include? Alumno::CERTIFICADO_NACIMIENTO.to_s
			_alumno.tiene_licencia_e_media = documentos.include? Alumno::LICENCIA_E_MEDIA.to_s
			_alumno.tiene_certificado_titulo = documentos.include? Alumno::CERTIFICADO_TITULO.to_s
			_apoderado_antiguo = _alumno.apoderado

			_usuario_apoderado = Usuario.new usuario_apoderado
			_apoderado = Apoderado.new apoderado

			# El mismo alumno es el apoderado
			if apoderado_es_el_alumno
				_apoderado.datos_personales = _usuario_alumno
				_apoderado.es_alumno = true

			# El alumno y el apoderado son personas distintas
			else
				# El apoderado no existe
				if apoderado[:usuario_id].nil?
					# Guardar el "Usuario" apoderado
					_usuario_apoderado.tipo = Usuario::APODERADO
					_usuario_apoderado.sede_id = sede_id
					_usuario_apoderado.password = Digest::MD5.hexdigest(usuario_apoderado[:rut])
					_usuario_apoderado.save	

				# El apoderado ya existe
				else
					_usuario_apoderado = Usuario.get apoderado[:usuario_id]
					_usuario_apoderado.update usuario_apoderado
				end

				_apoderado.datos_personales = _usuario_apoderado
				_apoderado.es_alumno = false				
			end

			# Actualizar el "Apoderado",
			_apoderado.save

			# Actualizar el alumno
			_alumno.apoderado = _apoderado
			_alumno.save

			# Actualizar "AlumnoPlanEstudio"
			_inscripcion.update inscripcion

			# Actualizar la matricula
			matricula.update matricula_plan

			# Actualizar el plan de pago
			plan.apoderado = _apoderado
			plan.url_contrato = nil

			# Solo se actualiza el nivel cuando corresponde
			plan.nivel = nivel if not nivel.nil?
			
			plan.save

			# !! Importante
			# El ejecutiv debe hacer el proceso de anulación/sustición por si mismo

			# Actualizar el pagare.
			# plan.pagares.first(:estado => Pagare::VIGENTE).update :url => nil

			# El alumno tenia un apoderado que no era el mismo
			if not usuario_apoderado_id.nil?
				_apoderado_antiguo.destroy!
				_usuario_apoderado_antiguo = Usuario.get! usuario_apoderado_id

				# Borro el usuario apoderado si no esta asociado con nada mas
				_usuario_apoderado_antiguo.destroy! if _usuario_apoderado_antiguo.alumno.nil? and Apoderado.count(:usuario_id => usuario_apoderado_id, :id.not => _apoderado_antiguo.id) == 0
			end
		end

		plan
	end

	def self.matricular_alumno_superior_ip(
										sede_id,
										institucion_sede_id,
										usuario_alumno, 
										usuario_apoderado, 
										apoderado, 
										apoderado_es_el_alumno,
										periodo,
										matricula,
										plan_pago,
										pagares,
										pagos_comprometidos,
										documento_venta
									)
		_matricula = MatriculaPlan.new matricula
		MatriculaPlan.transaction do

			# Estás dos lineas las comenté en un merge, quizás se tengan que borrar

			_usuario_alumno = Usuario.get usuario_alumno.delete("id")
			_alumno = _usuario_alumno.alumno

			_usuario_apoderado = Usuario.new usuario_apoderado
			_apoderado = Apoderado.new apoderado

			# El mismo alumno es el apoderado
			if apoderado_es_el_alumno
				_apoderado.datos_personales = _usuario_alumno
				_apoderado.es_alumno = true

			# El alumno y el apoderado son personas distintas
			else
				# El apoderado no existe
				if apoderado[:usuario_id].nil?
					# Guardar el "Usuario" apoderado
					_usuario_apoderado.tipo = Usuario::APODERADO
					_usuario_apoderado.sede_id = sede_id
					_usuario_apoderado.password = Digest::MD5.hexdigest(usuario_apoderado[:rut])
					_usuario_apoderado.save	

				# El apoderado ya existe
				else
					_usuario_apoderado = Usuario.get apoderado[:usuario_id]
					_usuario_apoderado.update usuario_apoderado
				end

				_apoderado.datos_personales = _usuario_apoderado
				_apoderado.es_alumno = false				
			end
			# Guardar el "Apoderado"
			_apoderado.save

			# Actualizar el "Alumno"
			_alumno.update :apoderado => _apoderado

			# Actualizo los datos de contacto del alumno
			_usuario_alumno.update usuario_alumno

			# Guardar la matricula
			_matricula.periodo_id = periodo[:id]
			_matricula.save
			inscripcion_plan = _matricula.alumno_plan_estudio


			# Guardar el plan de pago
			# Guardar la informacion del plan de pago
			_plan_pago = _matricula.planes_pago.new plan_pago
			_plan_pago.apoderado = _apoderado
			_plan_pago.periodo_id = periodo[:id]
			_plan_pago.save			

			# Solo si existen pagares
			if not pagares.nil?
				# Unificamos los pagares
				_pagares_unificados = pagares.group_by{ |pagare| pagare["numero"].strip }.map{ |numero_pagare, pagares_duplicados| pagares_duplicados.inject(:merge) }

				# Guardar los pagares
				_pagares = []
				_pagares_unificados.each do |pagare| 
					_pagare = _plan_pago.pagares.new pagare
					cuotas_pagare = pagos_comprometidos.select{ |pago| pago["numero_pagare"].to_i == _pagare.numero }

					_pagare.alumno_plan_estudio = inscripcion_plan
					_pagare.institucion_sede_id = institucion_sede_id
					_pagare.fecha_inicio = cuotas_pagare.min_by{ |pago| Date.parse pago["fecha_vencimiento"] }["fecha_vencimiento"]
					_pagare.fecha_termino = cuotas_pagare.max_by{ |pago| Date.parse pago["fecha_vencimiento"] }["fecha_vencimiento"]
					_pagare.monto = cuotas_pagare.map{ |pago| pago["monto"].to_i }.inject(:+)

					_pagare.save
					_pagares << _pagare
				end
			end

			# Guardar los pagos comprometidos, solo si se ha generado alguno (Alumno que tiene beneficio del 100%)
			if not pagos_comprometidos.nil?
				# Guardar el documento de venta, solo si se ha generado algún pago al contado
				pagos_contado = pagos_comprometidos.select{ |pago| pago["estado"].to_i == PagoComprometido::PAGADO or pago["tipo_cuota"].to_i == PagoComprometido::CHEQUE }
				if not pagos_contado.empty?
					_documento_venta = _plan_pago.documentos_venta.new documento_venta 		
					_documento_venta.alumno_plan_estudio = inscripcion_plan
					_documento_venta.institucion_sede_id = institucion_sede_id
					_documento_venta.fecha_emision = Time.now
					_documento_venta.save		
				end			

				pagos_comprometidos.each do |pago_comprometido|
					_abono = pago_comprometido.delete "abono"
					numero_pagare = pago_comprometido.delete "numero_pagare"
					_pago_comprometido = _plan_pago.pagos_comprometidos.new pago_comprometido

					# Pertenece a un pagare ??
					_pago_comprometido.pagare = _pagares.select{ |pagare| pagare.numero == numero_pagare.to_i }.first if _pago_comprometido.tipo_cuota == PagoComprometido::PAGARE
					_pago_comprometido.institucion_sede_id = institucion_sede_id
					_pago_comprometido.save

					# Tiene abono inicial ??
					if not _abono.nil?
						abono = _pago_comprometido.abonos.new _abono
						abono.documento_venta = _documento_venta
						abono.alumno_plan_estudio = inscripcion_plan
						abono.tipo_abono_id = _pago_comprometido.centro_costo
						abono.fecha = Time.now
						abono.save
					end
				end
			end
			inscripcion_plan.update estado: Alumno::SIN_INSCRIPCION,
									semestre: (_plan_pago.nivel - 1)
		end
		_matricula
	end

	def self.matricular_alumno_extension(
										sede_id,
										institucion_sede_id,
										usuario_alumno, 
										usuario_apoderado, 
										apoderado, 
										apoderado_es_el_alumno,
										periodo,
										matricula,
										plan_pago,
										pagares,
										pagos_comprometidos,
										documento_venta
									)
		_plan_pago = PlanPago.new plan_pago
		_matricula = ""

		PlanPago.transaction do

			# Estás dos lineas las comenté en un merge, quizás se tengan que borrar

			_usuario_alumno = Usuario.get usuario_alumno.delete("id")

			puts "_usuario_alumno: #{_usuario_alumno.inspect}".bold.blue
			puts "atributos _usuario_alumno: #{_usuario_alumno.attributes.inspect}".bold.blue
			puts "_usuario_alumno.valid?: #{_usuario_alumno.valid?}".bold.blue

			_alumno = _usuario_alumno.alumno

			_usuario_apoderado = Usuario.new usuario_apoderado
			_apoderado = Apoderado.new apoderado

			# El mismo alumno es el apoderado
			if apoderado_es_el_alumno
				_apoderado.datos_personales = _usuario_alumno
				_apoderado.es_alumno = true

			# El alumno y el apoderado son personas distintas
			else
				# El apoderado no existe
				if apoderado[:usuario_id].nil?
					# Guardar el "Usuario" apoderado
					_usuario_apoderado.tipo = Usuario::APODERADO
					_usuario_apoderado.sede_id = sede_id
					_usuario_apoderado.password = Digest::MD5.hexdigest(usuario_apoderado[:rut])
					_usuario_apoderado.save	

				# El apoderado ya existe
				else
					_usuario_apoderado = Usuario.get apoderado[:usuario_id]
					_usuario_apoderado.update usuario_apoderado
				end

				_apoderado.datos_personales = _usuario_apoderado
				_apoderado.es_alumno = false				
			end
			# Guardar el "Apoderado"
			_apoderado.save

			# Actualizar el "Alumno"
			_alumno.update :apoderado => _apoderado

			# Actualizo los datos de contacto del alumno
			_usuario_alumno.update usuario_alumno
			
			# Guardar el plan de pago
			# Guardar la informacion del plan de pago

			_matricula = MatriculaPlan.last alumno_plan_estudio_id: matricula[:alumno_plan_estudio_id]
			inscripcion_plan = _matricula.alumno_plan_estudio
			plan_anterior = PlanPago.last fields: [:id],
										  matricula_plan_id: _matricula.id
			pagare_anterior = Pagare.last fields: [:id],
										  plan_pago_id: plan_anterior.id

			_plan_pago.apoderado = _apoderado
			_plan_pago.periodo_id = periodo[:id]
			_plan_pago.matricula_plan = _matricula

			# Solo si existen pagares
			if not pagares.nil?
				# Unificamos los pagares
				_pagares_unificados = pagares.group_by{ |pagare| pagare["numero"].strip }.map{ |numero_pagare, pagares_duplicados| pagares_duplicados.inject(:merge) }

				# Guardar los pagares
				_pagares = []
				_pagares_unificados.each do |pagare| 
					_pagare = _plan_pago.pagares.new pagare
					cuotas_pagare = pagos_comprometidos.select{ |pago| pago["numero_pagare"].to_i == _pagare.numero }

					_pagare.alumno_plan_estudio = inscripcion_plan
					_pagare.institucion_sede_id = institucion_sede_id
					_pagare.fecha_inicio = cuotas_pagare.min_by{ |pago| Date.parse pago["fecha_vencimiento"] }["fecha_vencimiento"]
					_pagare.fecha_termino = cuotas_pagare.max_by{ |pago| Date.parse pago["fecha_vencimiento"] }["fecha_vencimiento"]
					_pagare.monto = cuotas_pagare.map{ |pago| pago["monto"].to_i }.inject(:+)
					_pagare.es_extension = true
					_pagare.pagare_id = pagare_anterior.id if not pagare_anterior.blank?

					_pagare.save
					_pagares << _pagare
				end
			end

			# Guardar los pagos comprometidos, solo si se ha generado alguno (Alumno que tiene beneficio del 100%)
			if not pagos_comprometidos.nil?
				# Guardar el documento de venta, solo si se ha generado algún pago al contado
				pagos_contado = pagos_comprometidos.select{ |pago| pago["estado"].to_i == PagoComprometido::PAGADO or pago["tipo_cuota"].to_i == PagoComprometido::CHEQUE }
				if not pagos_contado.empty?
					_documento_venta = _plan_pago.documentos_venta.new documento_venta 		
					_documento_venta.alumno_plan_estudio = inscripcion_plan
					_documento_venta.institucion_sede_id = institucion_sede_id
					_documento_venta.fecha_emision = Time.now
					_documento_venta.save		
				end			

				pagos_comprometidos.each do |pago_comprometido|
					_abono = pago_comprometido.delete "abono"
					numero_pagare = pago_comprometido.delete "numero_pagare"
					_pago_comprometido = _plan_pago.pagos_comprometidos.new pago_comprometido

					# Pertenece a un pagare ??
					_pago_comprometido.pagare = _pagares.select{ |pagare| pagare.numero == numero_pagare.to_i }.first if _pago_comprometido.tipo_cuota == PagoComprometido::PAGARE
					_pago_comprometido.institucion_sede_id = institucion_sede_id
					_pago_comprometido.save

					# Tiene abono inicial ??
					if not _abono.nil?
						abono = _pago_comprometido.abonos.new _abono
						abono.documento_venta = _documento_venta
						abono.alumno_plan_estudio = inscripcion_plan
						abono.tipo_abono_id = _pago_comprometido.centro_costo
						abono.fecha = Time.now
						abono.save
					end
				end
			end
			inscripcion_plan.update estado: Alumno::SIN_INSCRIPCION,
									semestre: (_plan_pago.nivel - 1)
		end
		_matricula
	end

	def self.matricular_alumno_nuevo_ip(
											sede_id, 
											institucion_sede_id,
											usuario_alumno,
											usuario_postulante_id,
											alumno,
											documentos_alumno,
											usuario_apoderado, 
											apoderado, 
											apoderado_es_el_alumno,
											periodo,
											inscripcion_plan,
											matricula_plan,
											plan_pago,
											pagares,
											pagos_comprometidos,
											documento_venta
										)
		_matricula = MatriculaPlan.new matricula_plan
		MatriculaPlan.transaction do	
			_usuario_alumno = Usuario.new usuario_alumno
			_usuario_alumno.tipo = Usuario::ESTUDIANTE
			_usuario_alumno.password = Digest::MD5.hexdigest(usuario_alumno[:rut])
			_usuario_alumno.sede_id = sede_id

			_usuario_apoderado = Usuario.new usuario_apoderado
			_apoderado = Apoderado.new apoderado
			_alumno = Alumno.new alumno
			_inscripcion_plan = AlumnoPlanEstudio.new inscripcion_plan
			alumno_id = _inscripcion_plan[:alumno_id]

			# Es un persona existente que estudia una carrera
			if not usuario_postulante_id.nil?
				_usuario_alumno = Usuario.get usuario_postulante_id
				# Es alumno
				if not alumno_id.nil?
					_alumno = Alumno.get alumno_id
				end				
				# Actualizamos los datos de contacto
				_usuario_alumno.update usuario_alumno

			# Es un alumno completamente nuevo
			else
				_usuario_alumno.save
			end	

			# El mismo alumno es el apoderado
			if apoderado_es_el_alumno
				_apoderado.datos_personales = _usuario_alumno
				_apoderado.es_alumno = true

			# El alumno y el apoderado son personas distintas
			else
				# El apoderado no existe
				if apoderado[:usuario_id].nil?
					# Guardar el "Usuario" apoderado
					_usuario_apoderado.tipo = Usuario::APODERADO
					_usuario_apoderado.sede_id = sede_id
					_usuario_apoderado.password = Digest::MD5.hexdigest(usuario_apoderado[:rut])
					_usuario_apoderado.save	

				# El apoderado ya existe
				else
					_usuario_apoderado = Usuario.get apoderado[:usuario_id]
					_usuario_apoderado.update usuario_apoderado
				end

				_apoderado.datos_personales = _usuario_apoderado
				_apoderado.es_alumno = false				
			end
			# Guardar el "Apoderado"
			_apoderado.save

			# Es un alumno que estudia una nueva carrera
			if not alumno_id.nil?
				documentos = documentos_alumno
				_alumno.apoderado = _apoderado
				_alumno.datos_personales = _usuario_alumno
				_alumno.establecimiento_educacional = alumno[:establecimiento_educacional]

				_alumno.tiene_certificado_nacimiento = documentos.include? Alumno::CERTIFICADO_NACIMIENTO.to_s
				_alumno.tiene_licencia_e_media = documentos.include? Alumno::LICENCIA_E_MEDIA.to_s
				_alumno.tiene_certificado_titulo = documentos.include? Alumno::CERTIFICADO_TITULO.to_s
				_alumno.ingresos = (_alumno.ingresos+1)

				_alumno.save
			# El alumno es completamente nuevo
			else
				# Guardar el "Alumno"
				documentos = documentos_alumno
				_alumno.apoderado = _apoderado
				_alumno.datos_personales = _usuario_alumno
				_alumno.anio_ingreso = periodo[:anio]

				_alumno.tiene_certificado_nacimiento = documentos.include? Alumno::CERTIFICADO_NACIMIENTO.to_s
				_alumno.tiene_licencia_e_media = documentos.include? Alumno::LICENCIA_E_MEDIA.to_s
				_alumno.tiene_certificado_titulo = documentos.include? Alumno::CERTIFICADO_TITULO.to_s
				
				_alumno.save
				_inscripcion_plan.alumno = _alumno
			end

			# Guardar la inscripcion en la carrera "AlumnoPlanEstudio"			
			_inscripcion_plan.anio_ingreso = periodo[:anio]
			_inscripcion_plan.periodo_id = periodo[:id]
			_inscripcion_plan.save	

			# Guardar la matricula
			_matricula.periodo_id = periodo[:id]
			_matricula.alumno_plan_estudio = _inscripcion_plan
			_matricula.save

			# Guardar la informacion del plan de pago
			_plan_pago = _matricula.planes_pago.new plan_pago
			_plan_pago.apoderado = _apoderado
			_plan_pago.periodo_id = periodo[:id]
			# Atributo para la inscripcion de asignaturas
			_plan_pago.nivel = 1
			_plan_pago.save

			# Solo si existen pagares
			if not pagares.nil?
				# Unificamos los pagares
				_pagares_unificados = pagares.group_by{ |pagare| pagare["numero"].strip }.map{ |numero_pagare, pagares_duplicados| pagares_duplicados.inject(:merge) }

				# Guardar los pagares
				_pagares = []
				_pagares_unificados.each do |pagare| 
					_pagare = _plan_pago.pagares.new pagare
					cuotas_pagare = pagos_comprometidos.select{ |pago| pago["numero_pagare"].to_i == _pagare.numero }

					_pagare.alumno_plan_estudio = _inscripcion_plan
					_pagare.institucion_sede_id = institucion_sede_id
					_pagare.fecha_inicio 		= cuotas_pagare.min_by{ |pago| Date.parse pago["fecha_vencimiento"] }["fecha_vencimiento"]
					_pagare.fecha_termino 		= cuotas_pagare.max_by{ |pago| Date.parse pago["fecha_vencimiento"] }["fecha_vencimiento"]
					_pagare.monto 				= cuotas_pagare.map{ |pago| pago["monto"].to_i }.inject(:+)

					_pagare.save
					_pagares << _pagare
				end
			end

			# Guardar los pagos comprometidos, si hay
			if not pagos_comprometidos.nil?
				# Guardar el documento de venta, solo si se ha generado algún pago al contado
				pagos_contado = pagos_comprometidos.select{ |pago| pago["estado"].to_i == PagoComprometido::PAGADO or pago["tipo_cuota"].to_i == PagoComprometido::CHEQUE }
				if not pagos_contado.empty?
					_documento_venta = _plan_pago.documentos_venta.new documento_venta 		
					_documento_venta.alumno_plan_estudio = _inscripcion_plan
					_documento_venta.institucion_sede_id = institucion_sede_id
					_documento_venta.fecha_emision = Time.now
					_documento_venta.save		
				end
				
				pagos_comprometidos.each do |pago_comprometido|
					_abono = pago_comprometido.delete "abono"
					numero_pagare = pago_comprometido.delete "numero_pagare"
					_pago_comprometido = _plan_pago.pagos_comprometidos.new pago_comprometido

					# Pertenece a un pagare ??
					_pago_comprometido.pagare = _pagares.select{ |pagare| pagare.numero == numero_pagare.to_i }.first if _pago_comprometido.tipo_cuota == PagoComprometido::PAGARE
					_pago_comprometido.institucion_sede_id = institucion_sede_id
					_pago_comprometido.save

					# Tiene abono inicial ??
					if not _abono.nil?
						abono = _pago_comprometido.abonos.new _abono
						abono.documento_venta = _documento_venta
						abono.alumno_plan_estudio = _inscripcion_plan
						abono.tipo_abono_id = _pago_comprometido.centro_costo
						abono.fecha = Time.now
						abono.save
					end
				end
			end
		end
		_matricula
	end

	def self.matricular_alumno_convalidado(
											sede_id, 
											institucion_sede_id,
											usuario_alumno,
											usuario_postulante_id,
											alumno,
											documentos_alumno,
											usuario_apoderado, 
											apoderado, 
											apoderado_es_el_alumno,
											periodo,
											inscripcion_plan,
											matricula_plan,
											plan_pago,
											pagares,
											pagos_comprometidos,
											documento_venta,
											estado_plan_anterior
										)

		_matricula = MatriculaPlan.new matricula_plan
		MatriculaPlan.transaction do	
			_usuario_alumno = Usuario.new usuario_alumno
			_usuario_alumno.tipo = Usuario::ESTUDIANTE
			_usuario_alumno.password = Digest::MD5.hexdigest(usuario_alumno[:rut])
			_usuario_alumno.sede_id = sede_id

			_usuario_apoderado = Usuario.new usuario_apoderado
			_apoderado = Apoderado.new apoderado
			_alumno = Alumno.new alumno
			_inscripcion_plan = AlumnoPlanEstudio.new inscripcion_plan
			alumno_id = _inscripcion_plan[:alumno_id]

			# Es un persona existente que estudia una carrera
			if not usuario_postulante_id.nil?
				_usuario_alumno = Usuario.get usuario_postulante_id
				# Es alumno
				if not alumno_id.nil?
					_alumno = Alumno.get alumno_id
				end				
				# Actualizamos los datos de contacto
				_usuario_alumno.update usuario_alumno
				_usuario_alumno.sede_id = sede_id
				_usuario_alumno.save

			# Es un alumno completamente nuevo
			else
				_usuario_alumno.save
			end	

			# El mismo alumno es el apoderado
			if apoderado_es_el_alumno
				_apoderado.datos_personales = _usuario_alumno
				_apoderado.es_alumno = true

			# El alumno y el apoderado son personas distintas
			else
				# El apoderado no existe
				if apoderado[:usuario_id].nil?
					# Guardar el "Usuario" apoderado
					_usuario_apoderado.tipo = Usuario::APODERADO
					_usuario_apoderado.sede_id = sede_id
					_usuario_apoderado.password = Digest::MD5.hexdigest(usuario_apoderado[:rut])
					_usuario_apoderado.save	

				# El apoderado ya existe
				else
					_usuario_apoderado = Usuario.get apoderado[:usuario_id]
					_usuario_apoderado.update usuario_apoderado
				end

				_apoderado.datos_personales = _usuario_apoderado
				_apoderado.es_alumno = false				
			end
			# Guardar el "Apoderado"
			_apoderado.save

			# Es un alumno que estudia una nueva carrera
			if not alumno_id.nil?
				documentos = documentos_alumno
				_alumno.apoderado = _apoderado
				_alumno.datos_personales = _usuario_alumno
				_alumno.establecimiento_educacional = alumno[:establecimiento_educacional]
				_alumno.tipo_establecimiento_educacional = alumno[:tipo_establecimiento_educacional]

				_alumno.tiene_certificado_nacimiento = documentos.include? Alumno::CERTIFICADO_NACIMIENTO.to_s
				_alumno.tiene_licencia_e_media = documentos.include? Alumno::LICENCIA_E_MEDIA.to_s
				_alumno.tiene_certificado_titulo = documentos.include? Alumno::CERTIFICADO_TITULO.to_s
				_alumno.ingresos = (_alumno.ingresos+1)

				_alumno.save

			# El alumno es completamente nuevo
			else
				# Guardar el "Alumno"
				documentos = documentos_alumno
				_alumno.apoderado = _apoderado
				_alumno.datos_personales = _usuario_alumno
				_alumno.anio_ingreso = periodo[:anio]

				_alumno.tiene_certificado_nacimiento = documentos.include? Alumno::CERTIFICADO_NACIMIENTO.to_s
				_alumno.tiene_licencia_e_media = documentos.include? Alumno::LICENCIA_E_MEDIA.to_s
				_alumno.tiene_certificado_titulo = documentos.include? Alumno::CERTIFICADO_TITULO.to_s
				_alumno.save

				_inscripcion_plan.alumno = _alumno
			end

			# Guardar la inscripcion en la carrera "AlumnoPlanEstudio"			
			_inscripcion_plan.anio_ingreso = periodo[:anio]
			_inscripcion_plan.periodo_id   = periodo[:id]
			_inscripcion_plan.semestre     = (plan_pago[:nivel].to_i - 1)

			if estado_plan_anterior.to_i == Alumno::TRASLADADO
				_inscripcion_plan.tipo_ingreso = Alumno::TRASLADO
			else
				_inscripcion_plan.tipo_ingreso = Alumno::CONVALIDACION
			end

			_inscripcion_plan.save	

			# Guardar la matricula
			_matricula.periodo_id = periodo[:id]
			_matricula.alumno_plan_estudio = _inscripcion_plan
			_matricula.save

			# Guardar la informacion del plan de pago
			_plan_pago = _matricula.planes_pago.new plan_pago
			_plan_pago.apoderado = _apoderado
			_plan_pago.periodo_id = periodo[:id]
			# Atributo para la inscripcion de asignaturas
			_plan_pago.save

			# Solo si existen pagares
			if not pagares.nil?
				# Unificamos los pagares
				_pagares_unificados = pagares.group_by{ |pagare| pagare["numero"].strip }.map{ |numero_pagare, pagares_duplicados| pagares_duplicados.inject(:merge) }

				# Guardar los pagares
				_pagares = []
				_pagares_unificados.each do |pagare| 
					_pagare = _plan_pago.pagares.new pagare
					cuotas_pagare = pagos_comprometidos.select{ |pago| pago["numero_pagare"].to_i == _pagare.numero }

					_pagare.alumno_plan_estudio = _inscripcion_plan
					_pagare.institucion_sede_id = institucion_sede_id
					_pagare.fecha_inicio 		= cuotas_pagare.min_by{ |pago| Date.parse pago["fecha_vencimiento"] }["fecha_vencimiento"]
					_pagare.fecha_termino 		= cuotas_pagare.max_by{ |pago| Date.parse pago["fecha_vencimiento"] }["fecha_vencimiento"]
					_pagare.monto 				= cuotas_pagare.map{ |pago| pago["monto"].to_i }.inject(:+)

					_pagare.save
					_pagares << _pagare
				end
			end

			# Guardar los pagos comprometidos, si hay
			if not pagos_comprometidos.nil?
				# Guardar el documento de venta, solo si se ha generado algún pago al contado
				pagos_contado = pagos_comprometidos.select{ |pago| pago["estado"].to_i == PagoComprometido::PAGADO or pago["tipo_cuota"].to_i == PagoComprometido::CHEQUE }
				if not pagos_contado.empty?
					_documento_venta = _plan_pago.documentos_venta.new documento_venta 		
					_documento_venta.alumno_plan_estudio = _inscripcion_plan
					_documento_venta.institucion_sede_id = institucion_sede_id
					_documento_venta.fecha_emision = Time.now
					_documento_venta.save		
				end
				
				pagos_comprometidos.each do |pago_comprometido|
					_abono = pago_comprometido.delete "abono"
					numero_pagare = pago_comprometido.delete "numero_pagare"
					_pago_comprometido = _plan_pago.pagos_comprometidos.new pago_comprometido

					# Pertenece a un pagare ??
					_pago_comprometido.pagare = _pagares.select{ |pagare| pagare.numero == numero_pagare.to_i }.first if _pago_comprometido.tipo_cuota == PagoComprometido::PAGARE
					_pago_comprometido.institucion_sede_id = institucion_sede_id
					_pago_comprometido.save

					# Tiene abono inicial ??
					if not _abono.nil?
						abono = _pago_comprometido.abonos.new _abono
						abono.documento_venta = _documento_venta
						abono.alumno_plan_estudio = _inscripcion_plan
						abono.tipo_abono_id = _pago_comprometido.centro_costo
						abono.fecha = Time.now
						abono.save
					end
				end
			end
		end
		_matricula
	end

	def self.buscar_por_rut q; Matriculas::MatriculaPlan.buscar_por_rut q end

	def resumen_planes; Matriculas::MatriculaPlan.resumen_planes self.id end

	def self.detalle_cajas_diarias ejecutivo_matricula_id, fecha, institucion_sede_id, modalidad
		Matriculas::Pagos.detalle_cajas_diarias ejecutivo_matricula_id, fecha, institucion_sede_id, modalidad
	end
end
