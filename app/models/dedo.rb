# encoding: utf-8
class Dedo
    include DataMapper::Resource
    include DataMapper::Timestamps

    property    :id,            Serial
    property    :rut,           String
    property    :nombre,        String
    property    :fecha,         DateTime
    property    :diferencia,    Integer

    timestamps  :at

    def self.process file
        begin
            dia_actual = ""
            datos_dia = []
            
            CSV.foreach(file, col_sep: "\t", return_headers: false) do |i|
                dia_actual_i = i[6].split(' ').first
                
                if dia_actual_i != dia_actual # Es para realizar verificación solo en el día actual [AV]
                    datos_dia = [] 
                    dia_actual = dia_actual_i
                end

                unless Dedo.get(i[0].to_i)
                    persona = DedoPersonas::busca(i[2].to_i)
                    
                    if not persona.blank?
                        
                        datos = {
                            id:         i[0].to_i,
                            rut:        i[2].to_i,
                            nombre:     persona,
                            fecha:      Time.parse(i[6])
                        }
                        
                        encontrados = datos_dia.select {|f| f[:rut] == datos[:rut] && datos[:fecha].to_s.split(' ').first == f[:fecha].to_s.split(' ').first }
                        
                        if encontrados.blank?
                            Dedo.create datos
                            datos_dia << datos
                        elsif (encontrados.last[:fecha] + 5.minutes) < datos[:fecha]
                            
                            datos[:diferencia] = ((datos[:fecha] - encontrados.last[:fecha]).abs / 60).round if encontrados.last[:diferencia].nil?
                            
                            Dedo.create datos
                            datos_dia << datos
                        end
                        
                    end
                end
            end
        rescue DataMapper::SaveFailureError => e
            puts e.resource.errors.inspect.red
            e.backtrace.map{ |x| x.match(/^(.+?):(\d+)(|:in `(.+)')$/); [$1,$2,$4] }.each do |i|
                puts i[0].magenta + "\t" + i[1].red + "\t" + i[2].yellow
            end
        end
    end
end