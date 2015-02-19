# encoding: utf-8
class DirectorEscuela
	include DataMapper::Resource
	include DataMapper::Timestamps
    include DataMapper::Historylog

    property    :id,                Serial
    property    :en_ejercicio,      Boolean

    timestamps  :at
    property    :deleted_at,        ParanoidDateTime

    belongs_to  :usuario
    belongs_to :escuela
end