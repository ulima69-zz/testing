<%-- 
    Document   : seguidos
    Created on : 29/10/2010, 16:07:55
    Author     : Administrador
--%>

<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="ic" tagdir="/WEB-INF/tags/ictags/" %>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
    "http://www.w3.org/TR/html4/loose.dtd">

<html>
    <head>
        <meta charset="UTF-8" />
        <title>jQuery UI Sortable - Portlets</title>
        <link type="text/css" href="css/themes/base/jquery.ui.all.css" rel="stylesheet" />
        <script type="text/javascript" src="js/jquery-1.4.2.js"></script>
        <script type="text/javascript" src="js/jquery.ui.core.js"></script>
        <script type="text/javascript" src="js/jquery.ui.widget.js"></script>
        <script type="text/javascript" src="js/jquery.ui.mouse.js"></script>
        <script type="text/javascript" src="js/jquery.ui.sortable.js"></script>
        <link type="text/css" href="css/themes/demos.css" rel="stylesheet" />
        <link type="text/css" href="css/util/util.css" rel="stylesheet" />
        <style type="text/css">
            .column { width: 170px; float: left; padding-bottom: 100px; }
            .portlet { margin: 0 1em 1em 0; width: 300px; padding-bottom: 4px;}
            .portlet-header { margin: 0.3em; padding-bottom: 4px; padding-left: 0.2em; }
            .portlet-header .ui-icon { float: right; }
            .portlet-content { padding: 0.4em; }
            .ui-sortable-placeholder { border: 1px dotted black; visibility: visible !important; height: 50px !important; }
            .ui-sortable-placeholder * { visibility: hidden; }

            #wrapperpainel {width: 700px; height: 600px; margin: 0 auto; background-color: #f92; padding: 10px;}

            #seguidosativos, #seguidosinativos {width:320px; height:580px; overflow: auto; background-color: #3cf; padding: 10px;}
            #seguidosinativos {float: left;}
            #seguidosativos {float: right;}

            #seguidosinativos div.column div.portlet div.portlet-content img,
            #seguidosinativos div.column div.portlet div.portlet-content div.info { float: left;}
            #seguidosativos div.column div.portlet div.portlet-content img,
            #seguidosativos div.column div.portlet div.portlet-content div.info { float: left;}

            #seguidosativos div.column div.portlet div.portlet-header a,
            #seguidosinativos div.column div.portlet div.portlet-header a {text-decoration: none;}

            #seguidosativos div.column div.portlet div.portlet-content div.info,
            #seguidosinativos div.column div.portlet div.portlet-content div.info { margin-left: 4px;}

            div.info {float: right;}
        </style>
        <script type="text/javascript">
            $(function() {
                $(".column").sortable({
                    connectWith: '.column'
                });

                $(".portlet").addClass("ui-widget ui-widget-content ui-helper-clearfix ui-corner-all")
                .find(".portlet-header")
                .addClass("ui-widget-header ui-corner-all")
                .prepend('<span class="ui-icon ui-icon-minusthick"></span>')
                .end()
                .find(".portlet-content");

                $(".portlet-header .ui-icon").click(function() {
                    $(this).toggleClass("ui-icon-minusthick").toggleClass("ui-icon-plusthick");
                    $(this).parents(".portlet:first").find(".portlet-content").toggle();
                });

                $(".column").disableSelection();
            });

            $(document).ready(function(){
                $('#seguidosform').submit(function(){
                    var inativos = $('#seguidosinativos div.column div.portlet div.portlet-header a').text();
                    var ativos = $('#seguidosativos div.column div.portlet div.portlet-header a').text();
                    $('input[name=seguidosinativos]').val(inativos);
                    $('input[name=seguidosativos]').val(ativos);
                    return true;
                });
            });
        </script>
    </head>
    <body>
        <div id="wrapperpainel" class="rounded-corners">
            <form id="seguidosform" action="TesteServlet" method="POST" >

                <div id="seguidosinativos" class="rounded-corners">
                    <div class="column">
                        <ic:friendsportletlist listadeamigos="${amigosList}" />
                    </div>

                </div>

                <div id="seguidosativos" class="rounded-corners">
                    <div class="column">
                    </div>
                </div>

                    <input type="hidden" name="seguidosativos" value="foovalue" />
                    <input type="hidden" name="seguidosinativos" value="foovalue" />
                    <input type="submit"  />

            </form>
                    
        </div><!-- End wrapperpainel -->
    </body>
</html>
