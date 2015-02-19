# encoding: utf-8
class Administrador::DedosController < ApplicationController

    def index

        if !params[:filtro].blank? 
           if params[:filtro][:fecha_inicio].blank? && params[:filtro][:fecha_termino].blank? 
                flash.now[:error]             = "Recuerde seleccionar una fecha de inicio y término"
            else
                session[:ficha_fecha_inicio]  = params[:filtro][:fecha_inicio]
                session[:ficha_fecha_termino] = params[:filtro][:fecha_termino]
                
                @f_i                          = session[:ficha_fecha_inicio]
                @f_t                          = session[:ficha_fecha_termino]

                f_i                           = Time.parse(@f_i)
                f_t                           = Time.parse(@f_t+' 23:59:59')
                cond                          = {:fecha.gte => f_i, :fecha.lte => f_t}
                @items                        = Dedo.all(cond)
                
                @personas                     = []
                personas_data                 = DataMapper.repository.adapter.select("SELECT rut, SUM(diferencia) AS tiempo FROM dedos WHERE fecha >= '#{f_i}' AND fecha <= '#{f_t}' GROUP BY rut")

                DedoPersonas::PERSONAS.each do |persona|
                    @personas << {rut: persona[1], nombre: DedoPersonas.nombre(persona), tiempo: (dato = personas_data.find {|i| i.rut.to_i == persona[1]}).blank? ? nil : dato.tiempo}
                end
                
                
=begin                
                last = nil

                @items.each do |i|
                    if( last.nil? ? true : (last.rut != i.rut ? true : (i.fecha - last.fecha > 5.minutes)) )
                        
                        encontrados = @data.select {|f| f[:rut] == i.rut && i.fecha.to_s.split('T')[0] == f[:fecha].to_s.split('T')[0] }
                        
                        anterior = encontrados.blank? ? nil : encontrados.last[:fecha]
                      
                        @data << {id: i.id, rut: i.rut, nombre: i.nombre, fecha: i.fecha, anterior: anterior}
                        

                    end
                    last = i
                end
=end                
            end
        end    
        
        
    end

    def ficha
        
    end
    
    def upload
        
    end
    
    def upload_process
        if not params['upload']['file'].blank?
            Dedo::process params['upload']['file'].tempfile.path
            flash[:notice] = 'Archivo subido correctamente'
        else
            flash[:error]  = 'No olvide seleccionar un archivo'
        end
        
        redirect_to administrador_dedos_path
    end

end