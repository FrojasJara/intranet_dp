# encoding: utf-8
class Matriculas::DocumentoVentaController < ApplicationController
    before_filter :iniciar, :only => [:buscar]

    def index
        unless params[:documento_venta].blank?
            b = DocumentoVenta.first(numero: params[:documento_venta], tipo: params[:tipo])
            
            if b.blank?
                flash[:error] = "El documento de venta ingresado no existe"
            else
                redirect_to matriculas_documento_venta_show_path(b.numero)
                return nil
            end
        end
    end

    
    def show
        @items = DocumentoVenta.all numero: params[:numero].to_i

        if @items.blank?
            flash[:error] = "El documento de venta ingresado no existe"
            redirect_to matriculas_documento_venta_path
        end
    end

    def edit
        @item = DocumentoVenta.get params[:id]
    end

    def update
        item = DocumentoVenta.get params[:id]
        dv = params[:documento_venta]
        
        DocumentoVenta.transaction do
            begin
                
                
                unless dv[:fecha_emision_original].eql?(dv[:fecha_emision]) # En el caso de que solo cambie la fecha de emisión, no necesito modificar otras cosas
                    item.fecha_emision = dv[:fecha_emision]     
                    item.save
                    flash[:notice] = "Se cambió la fecha al documento de venta"
                end


                unless dv[:numero_original].eql?(dv[:numero]) # Cambia documento, así que debo clonar y anular lo antiguo
                    nuevo_documento_venta = DocumentoVenta.create( item.attributes.merge(:id => nil, :numero => dv[:numero]) )


                    item.abonos.each do |i|
                        Abono.create( i.attributes.merge(:id => nil, :documento_venta_id => nuevo_documento_venta.id) )
                        i.update :estado => PagoComprometido::ANULADO
                    end
                    
                    item.update :estado => DocumentoVenta::ANULADA
                    flash[:notice] = "Documento de venta anulado y sustituido correctamente"
                end                
            rescue
                flash[:error] = "Ocurrió un error al modificar el documento de venta"
            end
        end

        redirect_to matriculas_documento_venta_show_path(item.id)
    end
    
	private
    
	def iniciar
		@usuario = current_user_object
		@ejecutivo_matriculas = @usuario.ejecutivo_matriculas
	end
end