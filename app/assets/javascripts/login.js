//= require jquery
//= require jquery_ujs
//= require ./libjquery/jquery.Rut.min

$(document).ready(function() {
	/*	Rut	*/
	$("input[name*='rut']").Rut();
	$("input[name*='rut']").change(function(){
		$(this).val( $(this).val().replace("k", "K") );
	});
})