module MatriculasHelper
    def estado_cuota_class pago_comprometido
        estado = get_name PagoComprometido, "ESTADOS", pago_comprometido.estado
        atrasada = pago_comprometido.atrasada? ? "atrasada" : nil
        

        return estado, atrasada
    end
end