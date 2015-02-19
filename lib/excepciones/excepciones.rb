# encoding: utf-8
module Excepciones

	ERROR_DESCONOCIDO = "Ha ocurrido un error inesperado. Por favor, intente el procedimiento más tarde."

	# Una operacion que no puede llevarse a cabo debido a la reglas de negocios
	class OperacionNoPermitidaError < StandardError; end

	# Una operacion que no puede llevarse a cabo debido a inconsistencias en la informacion por la importacion
	class DatosInconsistentesError < StandardError; end

	# Un alumno que por diversos motivos no puede ser matriculado
	class AlumnoNoMatriculable < StandardError; end

	class DemasiadosDatosError < StandardError; end

	# No existe información para una consulta o reporte
	class DatosNoExistentesError < StandardError; end

	# El modelo a eliminar/modificar tiene hijos por lo que no es posible su modificación
	class ModificacionConflictiva < StandardError; end
	
	class DatosDuplicados < StandardError; end
end