$(document).ready(function() {

    $('#email').focus(function(){
        var widget=$(this);
        console.log(widget);
        var tip=$('<div>this is here</div>');  
        attrs={
            // top :widget.offset().top,
            // left:widget.offset().left + widget.outerWidth() + 10, 
            top:0, 
            left:0, 
            position:'absolute', 
            display:'block', 
            'min-height': widget.outerHeight()+'px'
        }
        tip.css(attrs);
        tip.insertAfter(widget);       
    })
})