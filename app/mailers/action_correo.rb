# encoding: utf-8

class ActionCorreo < ActionMailer::Base

    #================================================================
    #Envío de Emails cobranzas 
    #================================================================

    ActionCorreo.smtp_settings = {
        address:              'smtp.gmail.com',
        port:                 587,
        domain:               'gmail.com',
        user_name:            'cobranzas@dportales.cl',
        password:             'cobranzadp',
        authentication:       'plain',
        enable_starttls_auto: true  
    }

    default from: "cobranzas@dportales.cl"

	def MailCobranzaDistancia1(matricula,fechas,saldos,usuario)
        @usuario   = usuario
		@matricula = matricula
		@fecha     = fechas.first
        @fecha_fin = (Date.today + 3.day)
        @saldo     = saldos.first
		@user      = matricula.alumno_plan_estudio.alumno.datos_personales

        unless validar_mail?(@user.email)
            raise Excepciones::DatosInconsistentesError, "El correo del usuario #{@user.rut} no es válido, no fue posible enviar correo a este usuario ni a los que le siguen." 
        end

        mail(to: @user.email, subject: 'Vencimiento mensualidad',reply_to: @usuario.email)
       
    end

    def MailCobranzaDistancia2(matricula,fechas,saldos,usuario)
    	@usuario   = usuario
		@matricula = matricula
		@fechas    = fechas
        @fecha_fin = (Date.today + 3.day)
        @saldos    = saldos
		@user      = matricula.alumno_plan_estudio.alumno.datos_personales

        unless validar_mail?(@user.email)
            raise Excepciones::DatosInconsistentesError, "El correo del usuario #{@user.rut} no es válido, no fue posible enviar correo a este usuario ni a los que le siguen." 
        end

        mail(to: @user.email, subject: 'Vencimiento mensualidades',reply_to: @usuario.email)
       
    end

    def MailCobranzaDistancia3(matricula,fechas,saldos,usuario)
    	@usuario   = usuario
		@matricula = matricula
		@fechas    = fechas
        @fecha_fin = (Date.today + 3.day)
        @saldos    = saldos
		@user      = matricula.alumno_plan_estudio.alumno.datos_personales

        unless validar_mail?(@user.email)
            raise Excepciones::DatosInconsistentesError, "El correo del usuario #{@user.rut} no es válido, no fue posible enviar correo a este usuario ni a los que le siguen." 
        end

        mail(to: @user.email, subject: 'Vencimiento mensualidades',reply_to: @usuario.email)
       
    end

    def MailCobranzaPresencial1(matricula,fechas,saldos,usuario)
        @usuario   = usuario
        @matricula = matricula
        @fecha     = fechas.first
        @fecha_fin = (Date.today + 3.day)
        @saldo     = saldos.first
        @user      = matricula.alumno_plan_estudio.alumno.datos_personales

        unless validar_mail?(@user.email)
            raise Excepciones::DatosInconsistentesError, "El correo del usuario #{@user.rut} no es válido, no fue posible enviar correo a este usuario ni a los que le siguen." 
        end

        mail(to: @user.email, subject: 'Vencimiento mensualidad',reply_to: @usuario.email)

    end

    def MailCobranzaPresencial2(matricula,fechas,saldos,usuario)
        @usuario   = usuario
        @matricula = matricula
        @fechas    = fechas
        @fecha_fin = (Date.today + 3.day)
        @saldos    = saldos
        @user      = matricula.alumno_plan_estudio.alumno.datos_personales

        unless validar_mail?(@user.email)
            raise Excepciones::DatosInconsistentesError, "El correo del usuario #{@user.rut} no es válido, no fue posible enviar correo a este usuario ni a los que le siguen." 
        end

        mail(to: @user.email, subject: 'Vencimiento mensualidades',reply_to: @usuario.email)
       
    end

    def MailCobranzaPresencial3(matricula,fechas,saldos,usuario)
        @usuario   = usuario
        @matricula = matricula
        @fechas    = fechas
        @fecha_fin = (Date.today + 3.day)
        @saldos    = saldos
        @user      = matricula.alumno_plan_estudio.alumno.datos_personales

        unless validar_mail?(@user.email)
            raise Excepciones::DatosInconsistentesError, "El correo del usuario #{@user.rut} no es válido, no fue posible enviar correo a este usuario ni a los que le siguen." 
        end

        mail(to: @user.email, subject: 'Vencimiento mensualidades',reply_to: @usuario.email)
       
    end

    def MailCobranzaPresencial4(matricula,fechas,saldos,usuario)
        @usuario   = usuario
        @matricula = matricula
        @fechas    = fechas
        @fecha_fin = (Date.today + 3.day)
        @saldos    = saldos
        @user      = matricula.alumno_plan_estudio.alumno.datos_personales

        unless validar_mail?(@user.email)
            raise Excepciones::DatosInconsistentesError, "El correo del usuario #{@user.rut} no es válido, no fue posible enviar correo a este usuario ni a los que le siguen." 
        end

        mail(to: @user.email, subject: 'Vencimiento mensualidades',reply_to: @usuario.email)
       
    end

    def MailMatriculas(matricula,usuario)
        @usuario   = usuario
        @matricula = matricula
        @user      = matricula.alumno_plan_estudio.alumno.datos_personales

        unless validar_mail?(@user.email)
            raise Excepciones::DatosInconsistentesError, "El correo del usuario #{@user.rut} no es válido, no fue posible enviar correo a este usuario ni a los que le siguen." 
        end

        mail(to: @user.email, subject: 'Información Proceso de Matriculas',reply_to: @usuario.email)
       
    end

    def validar_mail?(email)
        email_regex = /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i

        (email =~ email_regex)
    end
end
