# encoding: utf-8
class Egresado	
	include DataMapper::Resource
    include DataMapper::Timestamps
    include DataMapper::Historylog

    CONTRATADO      = 1
    HONORARIO       = 2
    INDEPENDIENTE   = 3
    ESTUDIANTE     	= 4
    CESANTE			= 5
    OCUPACION     	= [
        :CONTRATADO, 
        :HONORARIO, 
        :INDEPENDIENTE, 
        :ESTUDIANTE,
        :CESANTE
    ]

    property    :id,            Serial
    property    :ocupacion,   	Integer,			:required => true
    property	:renta,			Integer,			:required => true, :min => 0
    property	:lugar,			String,				:length	=> 200
    property	:funcion,		String,				:length => 300

    property    :deleted_at,    ParanoidDateTime
    timestamps  :at

    belongs_to  :alumno_plan_estudio
    belongs_to	:periodo
    belongs_to  :usuario

end