# encoding: utf-8
class Matriculas::ExtensionController < ApplicationController
    before_filter :store_location, only: [:index]
    before_filter :buscar, except: [:index]
    helper_method :current_url, :url_postulante, :url_alumno

    def index
        unless (b = params[:busqueda]).blank?
            item = Usuario.first(rut: b)
            item = item.alumno unless item.nil?
            
            redirect_to matriculas_extender_listado_path(b) unless item.nil?

            flash.now[:error] = "El rut ingresado no es un alumno válido."
        end
    end

    def listado
        @estados_civiles      = Usuario::ESTADOS_CIVILES
        @sexos                = Usuario::SEXOS
        @regiones             = Region.all
        @procedencias         = Alumno::EST_EDUCACIONALES
        @paises               = Pais.all
        @documentos_apoderado = Apoderado::DOCUMENTOS
        @codigos_fijos        = Utils::CodigoTelefonico::FIJOS

        # Datos de los tipos de matrícula y descuetos
        @matriculas_profesionales   = MatriculaPlan::PROFESIONALES
        @matriculas_tecnicas        = MatriculaPlan::TECNICAS
        @matriculas_distancia       = MatriculaPlan::DISTANCIA

        @descuentos                              = Descuento.all(order: :nombre.asc).group_by { |e| e.tipo }
        @max_cantidad_cobro_asignaturas_regular  = Rails.configuration.max_cantidad_cobro_asignaturas_regular
        @max_cantidad_cobro_asignaturas_terminal = Rails.configuration.max_cantidad_cobro_asignaturas_terminal
        @cobro_asignaturas_regular_factor        = Rails.configuration.cobro_asignaturas_regular_factor
        @cobro_asignaturas_terminal_factor       = Rails.configuration.cobro_asignaturas_terminal_factor
        @max_cantidad_normativas                 = Rails.configuration.max_cantidad_normativas
        @cobro_normativas_factor                 = Rails.configuration.cobro_normativas_factor
        @distancia_cobro_semestre_factor         = Rails.configuration.cobro_semestre_distancia_factor

        alias url_alumno ajax_alumno_obtener_situacion_ip_path
        alias url_postulante ajax_postulante_obtener_ip_path

        # Datos de los medios de pagos
        @medios                        = Cotizacion::MEDIOS
        @medios_pagos                  = MedioPago.all
        @bancos                        = Banco.all
        @tarjetas_credito              = TarjetasCredito.all
        @formas_cuotas_alumno_superior = FormaPlanPago.plan_sin_interes
        @formas_cuotas_matriculas      = FormaPlanPago.planes_matricula
        @hoy                           = Date.today.to_s.gsub "-", "/"
        @documentos_alumno             = Alumno::DOCUMENTOS
        @documentos_apoderado          = Apoderado::DOCUMENTOS

        @documentos_venta = DocumentoVenta::TIPOS
    end

    private

    def buscar
        unless params[:rut].blank?
            @us_alumno            = Usuario.first rut: params[:rut]
            @matriculas           = MatriculaPlan.all alumno_plan_estudio: {  alumno: {datos_personales: @us_alumno} }
            
            @usuario              = current_user_object
            @ejecutivo_matriculas = @usuario.ejecutivo_matriculas
        end
    end
end