# encoding: utf-8
module DocentesHelper
	def opciones usuario_id, seccion_id, no_mostrar = nil
		raw render(partial: "docentes/docentes/partials/opciones", locals: { usuario_id: usuario_id, seccion_id: seccion_id, no_mostrar: no_mostrar })
	end
end