# encoding: utf-8
class Utils
    TAB = "\t|\t".bold

    def self.menu
        puts "\e[H\e[2J"
        while 1
            puts "\n\n\n"
            puts "  ==== Utilidades varias ====".bold
            puts "1 - Mostrar información de un alumno"
            puts "2 - Cambiar estado academico"
            puts "3 - Anular matricula"
            puts "4 - Cambiar número de pagaré y limpiar contrato/pagare para regenerar"
            puts "0 - para salir"
            puts "Ingrese opcion:".yellow.bold
            opcion = gets
            opcion = opcion.to_i

            tipo_matricula              if opcion.eql? 1
            cambiar_estado_academico    if opcion.eql? 2
            anular_matricula            if opcion.eql? 3
            reemplazar_pagare           if opcion.eql? 4
            exit                        if opcion.eql? 0
        end
    end

    def self.tipo_matricula
        usuario = pide_alumno
        return nil if usuario.nil?
        datos_alumno usuario
    end



    def self.anular_matricula
        puts "Permite anular la ultima matricula y sus pagos segun el rut para un cambio de carrera, preguntara estado"
        usuario = pide_alumno
        return nil if usuario.nil?
        _cambia_estado usuario

        usuario.alumno.alumno_plan_estudio.last.matricula_plan.last.planes_pago.last.update fecha_anulacion: Time.now, estado: MatriculaPlan::ANULADA
        usuario.alumno.alumno_plan_estudio.last.matricula_plan.last.planes_pago.last.pagos_comprometidos.update estado: PagoComprometido::ANULADO
    end

    def self.cambiar_estado_academico
        usuario = pide_alumno
        return nil if usuario.nil?
        _cambia_estado usuario
    end

    def self.reemplazar_pagare
        puts "Ingrese 0 para volver al menú principal"
        puts "Ingrese número del pagaré:".bold
        numero = gets
        return nil if numero.to_i.eql?(0) or numero.to_i.blank?
        pagare = Pagare.last numero: numero.to_i
        if pagare.blank?
            puts "Pagaré no existe"
            return nil
        end
        puts "Nº Pagare: ".bold << pagare.numero.to_s << "\tMonto: ".bold << pagare.monto.to_s << "\tC. Arancel: ".bold << pagare.cuotas_arancel.to_s << "\tC. Matricula: ".bold << pagare.cuotas_matricula.to_s << "\tC. Normativa: ".bold << pagare.cuotas_normativa.to_s
        datos_alumno pagare.alumno_plan_estudio.alumno.datos_personales
        puts ""
        puts "Ingrese el nuevo número del pagaré: ".bold
        numero = gets
        pagare.update numero: numero.to_i, url: nil
        pagare.plan_pago.update url_contrato: nil

        puts "Pida al ejecutivo que genere el contrato y pagaré".yellow.bold
    end

    private
    def self.pide_alumno
        puts "Ingrese rut: ".bold
        rut = gets 
        rut = rut.gsub("\n", "")

        usuario = Usuario.first(:rut.like => "#{rut}%")

        if usuario.blank?
            puts "El usuario no existe".red.bold
            return nil
        end
        usuario
    end

    def self.datos_alumno usuario
        puts "Rut:".bold << " #{usuario.rut} " << "Nombre: ".bold << "#{usuario.nombre}"

        if usuario.alumno.blank?
            puts "No es alumno".red.bold
            return nil
        end
        if usuario.alumno.alumno_plan_estudio.blank?
            puts "No tiene plan de estudios".red.bold
        end
        matricula_plan = usuario.alumno.alumno_plan_estudio.last.matricula_plan.last
        if matricula_plan.blank?
            puts "No tiene matrícula".red.bold
            return nil
        end

        plan_pago = matricula_plan.planes_pago.last

        puts "Tipo matricula: ".bold << get_name(MatriculaPlan, :TIPOS, plan_pago.tipo) << "\tMatricula Plan id: ".bold << matricula_plan.id.to_s
        
        puts "\tEstado: ".bold << get_name(PlanPago, :ESTADOS, plan_pago.estado) << "\tPagares: ".bold << plan_pago.pagares.map{|x| {id: x.id, numero: x.numero}}.inspect
        puts "Plan pago id: ".bold << plan_pago.id.to_s
        puts "================ PAGOS COMPROMETIDOS ==========================================".bold
        puts "ID".bold + TAB + "MONTO".bold + TAB + "SALDO".bold + TAB + "ESTADO" .bold+ TAB + "FECHA PAGO".bold
        puts "===============================================================================".bold
        plan_pago.pagos_comprometidos.each do |pc|
            puts "#{pc.id}" << TAB << pc.monto.to_s << TAB << pc.saldo.to_s << TAB << get_name(PagoComprometido, :ESTADOS, pc.estado) << TAB << pc.fecha_vencimiento.to_s
        end
        puts "===============================================================================".bold
    end

    def self._cambia_estado usuario
        opciones = [nil, Alumno::SIN_MATRICULA, Alumno::RETIRADO, Alumno::ANULADO, Alumno::PROMOVIDO, Alumno::EGRESADO, Alumno::TITULADO]

        puts "El usuario es: #{usuario.rut} - #{usuario.nombre}"
        puts "Que estado desea:".bold.red
        puts "1 = SIN MATRICULA".bold
        puts "2 = RETIRADO (Cambio de carrera)".bold
        puts "3 = ANULADO".bold
        puts "4 = PROMOVIDO (PARA CEIA)".bold
        puts "5 = EGRESADO".bold
        puts "6 = TITULADO (Cuando pasa de Tecnico a IP)".bold
        puts "Ingrese su opcion...".yellow.bold
        opcion = gets
        unless opciones[opcion.to_i].blank?

            usuario.alumno.alumno_plan_estudio.last.update estado: opciones[opcion.to_i]

        end
    end

    def self.get_name cls, arr, val
        cls.const_get(arr).each do |i|
            return i.to_s.humanize.titleize if cls.const_get(i).to_s == val.to_s
        end
        return nil
    end
end