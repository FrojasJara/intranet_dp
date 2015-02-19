# encoding: utf-8

class ActionCorreoCotizacion < ActionMailer::Base

    #================================================================
    #Envío de Emails Cotización 
    #================================================================

    ActionCorreoCotizacion.smtp_settings = {
        address:              'smtp.gmail.com',
        port:                 587,
        domain:               'gmail.com',
        user_name:            'admisionvina@dportales.cl',
        password:             'vina2015',
        authentication:       'plain',
        enable_starttls_auto: true  
    }

    default from: "cobranzas@dportales.cl"

    def MailCotizacionConcepcion(cotizacion,usuario)
        ActionCorreoCotizacion.smtp_settings = {
            address:              'smtp.gmail.com',
            port:                 587,
            domain:               'gmail.com',
            user_name:            'admision.concepcion@dportales.cl',
            password:             'admision123',
            authentication:       'plain',
            enable_starttls_auto: true  
        }    

        @usuario   = usuario
        @user      = cotizacion
        
        unless validar_mail?(@user.email)
            raise Excepciones::DatosInconsistentesError, "El correo del usuario #{@user.rut} no es válido, no fue posible enviar correo a este usuario ni a los que le siguen." 
        end

        mail(to: @user.email, subject: 'Aprovecha descuentos y aranceles a tu alcance.',reply_to: @usuario.email)
       
    end

    def MailCotizacionChillan(cotizacion,usuario) 
        ActionCorreoCotizacion.smtp_settings = {
            address:              'smtp.gmail.com',
            port:                 587,
            domain:               'gmail.com',
            user_name:            'admision.chillan@dportales.cl',
            password:             '',
            authentication:       'plain',
            enable_starttls_auto: true  
        }

        @usuario   = usuario
        @user      = cotizacion
        
        unless validar_mail?(@user.email)
            raise Excepciones::DatosInconsistentesError, "El correo del usuario #{@user.rut} no es válido, no fue posible enviar correo a este usuario ni a los que le siguen." 
        end

        mail(to: @user.email, subject: 'Aprovecha descuentos y aranceles a tu alcance.',reply_to: @usuario.email)
       
    end

    def MailCotizacionBosque(cotizacion,usuario) 
        ActionCorreoCotizacion.smtp_settings = {
            address:              'smtp.gmail.com',
            port:                 587,
            domain:               'gmail.com',
            user_name:            'admision.elbosque@dportales.cl',
            password:             'ipdp2015',
            authentication:       'plain',
            enable_starttls_auto: true  
        }
        @usuario   = usuario
        @user      = cotizacion

        unless validar_mail?(@user.email)
            raise Excepciones::DatosInconsistentesError, "El correo del usuario #{@user.rut} no es válido, no fue posible enviar correo a este usuario ni a los que le siguen." 
        end

        mail(to: @user.email, subject: 'Aprovecha descuentos y aranceles a tu alcance.',reply_to: @usuario.email)
       
    end

    def MailCotizacionNunoa(cotizacion,usuario) 
        ActionCorreoCotizacion.smtp_settings = {
            address:              'smtp.gmail.com',
            port:                 587,
            domain:               'gmail.com',
            user_name:            'admision.santiago@dportales.cl',
            password:             '---',
            authentication:       'plain',
            enable_starttls_auto: true  
        }
        @usuario   = usuario
        @user      = cotizacion

        unless validar_mail?(@user.email)
            raise Excepciones::DatosInconsistentesError, "El correo del usuario #{@user.rut} no es válido, no fue posible enviar correo a este usuario ni a los que le siguen." 
        end

        mail(to: @user.email, subject: 'Aprovecha descuentos y aranceles a tu alcance.',reply_to: @usuario.email)
       
    end

    def MailCotizacionVina(cotizacion,usuario) 
        ActionCorreoCotizacion.smtp_settings = {
            address:              'smtp.gmail.com',
            port:                 587,
            domain:               'gmail.com',
            user_name:            'admision.vina@dportales.cl',
            password:             'admision2014',
            authentication:       'plain',
            enable_starttls_auto: true  
        }
        @usuario   = usuario
        @user      = cotizacion

        unless validar_mail?(@user.email)
            raise Excepciones::DatosInconsistentesError, "El correo del usuario #{@user.rut} no es válido, no fue posible enviar correo a este usuario ni a los que le siguen." 
        end

        mail(to: @user.email, subject: 'Aprovecha descuentos y aranceles a tu alcance.',reply_to: @usuario.email)
       
    end

    def validar_mail?(email)
        email_regex = /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i

        (email =~ email_regex)
    end
    
end