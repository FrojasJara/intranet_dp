# encoding: utf-8
class PlanificacionCalificacion
	include DataMapper::Resource
	include DataMapper::Timestamps
	include DataMapper::Historylog

	storage_names[:default] = 'planificacion_calificaciones'

	PRUEBA_PARCIAL 			= 1
	PRUEBA_GLOBAL 			= 2
	EXAMEN_DE_REPETICION 	= 4
	NOTA_FINAL 				= 99
	NOTA_DE_PRESENTACION 	= 98
	EXAMEN_FINAL 			= 3
	NOTA_EXAMEN_DE_TITULO 	= 101
	NOTA_TRABAJO_DE_TITULO 	= 100

	NOMBRE_NOTAS = [ # id_tn TIPO DE NOTA
		:PRUEBA_PARCIAL, 
		:PRUEBA_GLOBAL, 
		:EXAMEN_DE_REPETICION, 
		:NOTA_FINAL, 
		:NOTA_DE_PRESENTACION,
		:EXAMEN_FINAL,
		:NOTA_EXAMEN_DE_TITULO,
		:NOTA_TRABAJO_DE_TITULO
	]

	SUMATIVA 	= 1
	FORMATIVA 	= 2
	DIAGNOSTICO = 3

	TIPO_NOTAS = [ # id_te: TIPO EVALUACION
		:SUMATIVA,
		:FORMATIVA,
		:DIAGNOSTICO
	]

	COMPROMETIDA 	= 1
	APLICADA 		= 2
	ESTADOS 		= [
		:COMPROMETIDA,
		:APLICADA
	]

	property 	:id,					Serial
	property 	:ponderacion, 			Float, 		:required => true, :min => 0, :max => 100
	property 	:fecha_comprometida, 	Date
	property 	:nombre, 				String # id_tn
	property 	:tipo,					Integer, 	:default => self::PRUEBA_PARCIAL #id_te
	property 	:numero,				Integer
	property 	:estado, 				Integer,	:default => PlanificacionCalificacion::COMPROMETIDA

	property 	:siaa_id,				Integer # CalendarioEvaluaciones OID
	property 	:siaa_updated_at,		DateTime
	property    :siaa_id_sede_sync, 	Integer

	timestamps 	:at

    has n, :calificaciones_parciales, "CalificacionParcial"
    belongs_to :seccion

  def estadisticas_evaluacion
  	data = []
  	 notas = CalificacionParcial.all(planificacion_calificacion_id: id,
  	 					 			:calificacion.not => CalificacionParcial::NO_CUMPLE_REQUISITOS,
  	 					 			:order => [:calificacion.desc]
  	 					 )
    if !notas.blank?
    	 maxima = notas.max(:calificacion)
    	 minima = notas.min(:calificacion)
       #calculamos promedio y la mediana
    	 m_pos = notas.size / 2
    	 mediana = notas.size % 2 == 1 ? notas[m_pos].calificacion : notas[m_pos-1].calificacion
    	 promedio = notas.collect(&:calificacion).sum.to_f/notas.length if notas.length > 0
    	 #calculamos la moda / 
    	 f={}    
     	 fmax=0 
       m=nil
       f1 = 0
       f2 = 0
       f3 = 0
       f4 = 0
       f6 = 0
       f5 = 0

       notas.each do |v|
       	f[v.calificacion] ||= 0
       	f[v.calificacion] += 1
       	fmax,m = f[v.calificacion], v.calificacion if f[v.calificacion] > fmax
       	
       	f1 = f1+1 if v.calificacion <= 2
       	f2 = f2+1 if v.calificacion <= 3 && v.calificacion > 2
       	f3 = f3+1 if v.calificacion <= 4 && v.calificacion > 3
       	f4 = f4+1 if v.calificacion <= 5 && v.calificacion > 4
       	f5 = f5+1 if v.calificacion <= 6 && v.calificacion > 5
       	f6 = f6+1 if v.calificacion <= 7 && v.calificacion > 6

     	 end
    	data << {
        :maxima 	=> maxima, 
        :minima 	=> minima, 
        :mediana 	=> mediana,
        :promedio 	=> promedio,
        :moda 		=> m,
        :f1 		=> f1,
        :f2			=> f2,
        :f3 		=> f3,
        :f4			=> f4,
        :f5 		=> f5,
        :f6			=> f6
      }
       return data
    elsif
      data << {
        :maxima   => 0, 
        :minima   => 0, 
        :mediana  => 0,
        :promedio => 0,
        :moda     => 0,
        :f1     => 0,
        :f2     => 0,
        :f3     => 0,
        :f4     => 0,
        :f5     => 0,
        :f6     => 0
      }
       return data
    end
      

  end
  def nombre_nota
    NOMBRE_NOTAS.each do |i|
        return i.to_s.humanize.titleize if PlanificacionCalificacion::const_get(i).to_s == nombre.to_s
    end

    nombre
  end

  def ponderacion_entera
  	"#{(ponderacion * 100).to_i}"
  end

  def ponderacion_porcentual
  	"#{ponderacion_entera}%"
  end

  def tipo_nota
    TIPO_NOTAS.each do |i|
          return i.to_s.humanize.titleize if PlanificacionCalificacion::const_get(i).to_s == tipo.to_s
      end

      tipo
  end





end