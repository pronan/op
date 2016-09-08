webpackJsonp([3],{

/***/ 20:
/***/ function(module, exports) {

	function main() {
	    $("form").submit(function(e) {
	        var fm = $(this);
	        var event = window.event || e;
	        if (event.preventDefault){
	            event.preventDefault();
	        } else if(FormData===undefined){
	            console.log('no FormData');
	            return; 
	        }else{
	            event.returnValue = false;
	            console.log('have return value but no preventDefault');
	        }
	        $.ajax({
	            type: "POST",
	            dataType: "json",
	            url: window.location.href,
	            data: new FormData(fm[0]),
	            cache: false,
	            contentType: false,
	            processData: false,
	            success: function(res) {
	                if (res.valid == true) {
	                    window.location.replace(res.url);
	                } else {
	                    var errors = res.errors;
	                    $.each(errors, function(field, value) {
	                        var e = $('#id_'+field);
	                        $('<div>'+value[0]+'</div>').insertAfter(e);
	                    });
	                }
	            },
	            error: function(xhr, textStatus, errorThrown) {
	                console.log(xhr, textStatus, errorThrown);
	            },
	        })
	    });
	}

	module.exports = main

/***/ }

});