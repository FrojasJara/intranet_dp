class HistoryController < ApplicationController
	helper_method :differences

	def get_history

		@items = Historial.all historiable_id: params[:historiable_id], historiable_type: params[:historiable_type]
		
		begin
			@item_nombre = " de #{@items.first.historiable.nombre}"
		rescue
			@item_nombre = ""
		end
		


		render layout: false
	end

	private
	def differences item
		old = JSON.parse ( (v = item.original_state).nil? ? '{}' : v )
		cur = JSON.parse ( (v = item.current_state).nil? ? '{}' : v )

		cur.diff(old).except("created_at").except("updated_at").except("deleted_at")
	end

end