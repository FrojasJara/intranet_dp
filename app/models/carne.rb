# encoding: utf-8
require 'barby'
require 'barby/barcode/ean_13'
require 'barby/outputter/png_outputter'
include MiniMagick
require "prawn/measurement_extensions"

class Carne
    CARNE_PATH = "#{Rails.root.to_s}/public/carne"
    def self.generar
        files = []

        ModelosAntiguos::Persona::lista_alumnos(2012).each do |i|

            generate i[:nombre], i[:rut], i[:carrera], 'Viña del Mar', i[:tipo]

            files << [i[:rut], i[:tipo]]
        end

        pdfsave files
    end

    private
    def self.generate nombre, rut, carrera, sede, tipo
        
        puts "Generando el carné para: #{rut} #{nombre}"
        img = Image.open("#{CARNE_PATH}/CarneBiblioteca#{tipo}-01.png")
        # Nombre
        drawtext img, "text 520,259 '#{nombre}'"
        # Rut
        drawtext img, "text 520,203 '#{rut}'"
        # Carrera
        drawtext img, "text 520,368 '#{carrera}'"
        # Sede
        drawtext img, "text 520,312 '#{sede}'"

        zrut = zeros_rut rut

        barcode = Barby::EAN13.new(zrut)
        save_img "#{CARNE_PATH}/barcodes/#{zrut}.png", barcode.to_png(:xdim => 4, :height => 190)

        result = img.composite(Image.open("#{CARNE_PATH}/barcodes/#{zrut}.png")) do |c|
            c.gravity "Southeast"
            c.geometry '+140+20'
        end
        
        result.write("#{CARNE_PATH}/carnes/#{zrut}.png")

    end

    def self.pdfsave files

        Prawn::Document.generate "#{Rails.root.to_s}/public/carne/credenciales-vina.pdf" do |pdf|
            c = 0
            y_pos = 0
            diff = 0

            files.each do |i|
                c += 1
                
                segundo = [2, 4, 6, 8].include?(c)

                y_pos = pdf.cursor unless segundo

                puts "Agregando al pdf a: #{i[0]} cursor: #{y_pos}"
                str_file = "#{Rails.root.to_s}/public/carne/carnes/#{zeros_rut(i[0])}.png"

                if segundo
                    pdf.image(str_file, 
                      :width => 9.cm, 
                      :height => "5.9".to_f.cm,
                      :at => [(pdf.bounds.width - 9.cm), y_pos])
                    pdf.text " "
                    diff = pdf.cursor - y_pos
                else
                    pdf.image(str_file, 
                          :width => 9.cm, 
                          :height => "5.9".to_f.cm)
                end
                c = 0 if c == 8
=begin

                if c == 8
                    4.times do 
                        y_pos = pdf.cursor

                        pdf.image("#{Rails.root.to_s}/public/carne/CarneBibliotecaCFT-02.png", 
                          :width => 9.cm, 
                          :height => "5.9".to_f.cm)

                        pdf.image("#{Rails.root.to_s}/public/carne/CarneBibliotecaCFT-02.png", 
                          :width => 9.cm, 
                          :height => "5.9".to_f.cm,
                          :at => [(pdf.bounds.width - 9.cm), y_pos])
                        pdf.text " "
                        puts "INSERTANDO PARTES DE 2 ATRAS en #{y_pos}"
                        #y_pos = y_pos + diff + "5.9".to_f.cm
                    end
                    c = 0
                end
=end
            end
        end
    end

    def self.generar_contra
        Prawn::Document.generate "#{Rails.root.to_s}/public/carne/credenciales-reves.pdf" do |pdf|
            c = 0
            y_pos = 0
            diff = 0

            (0..7).each do |i|
                c += 1
                
                segundo = [2, 4, 6, 8].include?(c)

                y_pos = pdf.cursor unless segundo

                str_file = "#{Rails.root.to_s}/public/carne/CarneBibliotecaCFT-02.png"

                if segundo
                    pdf.image(str_file, 
                      :width => 9.cm, 
                      :height => "5.9".to_f.cm,
                      :at => [(pdf.bounds.width - 9.cm), y_pos])
                    pdf.text " " if not c == 8
                    diff = pdf.cursor - y_pos
                else
                    pdf.image(str_file, 
                          :width => 9.cm, 
                          :height => "5.9".to_f.cm)
                end
                c = 0 if c == 8
            end
        end
    end

    def self.drawtext img, text
        img.combine_options do |c|
            c.gravity 'Northwest'
            c.pointsize '38'
            c.font "#{CARNE_PATH}/foliobq.otf"
            c.draw text
            c.fill("#333333")
        end
    end

    def self.save_img name, contents
        file = File.new(name, "w")
        file.write(contents)
        file.close
    end

    def self.zeros_rut rut
        sprintf('%012d', rut.gsub(".", "").gsub("-", "").to_i)
    end
end