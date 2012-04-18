$(function() {
    var html = $('html');
    var w = $(window);

    if (!Modernizr.input.placeholder) {
        html.addClass('no-placeholder');
    }

    $("#presentation").slides({
        generateNextPrev: true,
        pagination: true,
        generatePagination: true
    });

});

