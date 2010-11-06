<%-- 
    Document   : index
    Created on : 28/10/2010, 16:06:04
    Author     : Administrador
--%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="ic" tagdir="/WEB-INF/tags/ictags/" %>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
  <head>
    <title></title>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <script type="text/javascript"  src="js/jquery-1.4.2.js"></script>
    <script type="text/javascript"  src="js/jquery.limit-1.2.js"></script>
    <script type="text/javascript"  src="js/jquery.regex.js"></script>
    <script type="text/javascript"  src="js/jquery.qtip-1.0.js"></script>
    <link href='http://fonts.googleapis.com/css?family=Droid+Sans:bold' rel='stylesheet' type='text/css'>
    <style type="text/css">
        body {
            font-family: 'Droid Sans',   sans-serif;
            font-size: 12px;
            line-height: 14px;
            font-weight: bold;
            word-spacing: 2px;
            margin: 0; padding: 0; height: 100%;}
        #wrapper{margin: 0 auto; width: 960px; height: 100%; min-height: 100%}

        #head {
            height: 50px;
            background: url('image/gline.png') repeat-x;
            margin-bottom: 10px;
        }

        #content {
            background: #ff6633;
            height: 510px;
            margin-bottom: 10px;
            padding: 10px;
        }

        #footer {
            background: url('image/gline.png') repeat-x;
            height: 100px;

        }

        #meustweets {
            background: url('image/fundo.png') repeat-x;
            width: 700px;
            height: 510px;
            float: left;
        }

        #tweetswrapper {
            margin: 10px;
            height: 490px;
            overflow: auto;
        }

        #tweetswrapper div.twitterrow {
            background:url("image/bg_pattern_gray.png") repeat scroll left top transparent;
            margin: 4px;
            height: 100px;
            border: 1px solid #36f;
            padding: 4px;
        }

        #tweetswrapper div.twitterrow:hover {border: 1px solid #f63;}

        #tweetswrapper div.twitterrow div.userinfo { 
            height: 90px;
            margin: 5px;
            float: left;
            border-right: 2px dotted #3cf;
            width: 25%;
        }
        #tweetswrapper div.twitterrow div.userinfo img {margin: 10px 0 0 50px;}
        #tweetswrapper div.twitterrow div.userinfo a {display: block;}
        #tweetswrapper div.twitterrow div.usertweet {
            float: right;
            width: 70%;
            height: 90px;
            padding-top: 8px;
            padding-right: 4px;
        }

        #meusseguidos {
            background: url('image/fundo.png') repeat-x;
            width: 140px;
            height: 510px;
            float: right;
        }

        #meusseguidosfotos {
            width: 100px;
            height: 490px;
            margin-top: 10px;
            margin-right: 10px;
            float: right;
            overflow: auto;}

        #meusseguidosfotos div.seguido img {
            margin: 4px 20px 0 4px;
            border: 1px solid #36f;
        }

        #meusseguidosfotos div.seguido img:hover {
            border: 1px solid #f63;
        }

        #botaorefresh {
            background: url('image/gline.png') repeat-x;
            width: 160px;
            height: 50px;
            margin-top: 250px;
        }

        #botaorefresh span {color: #A65C0E; }

        #footer #tweetmessage #message textarea {
            width: 672px;
            height: 50px;
            margin-left: 14px; margin-top: 12px;}

        #footer #tweetmessage #tweetbutton {
            background: url('image/tweet.png') #ffb260 no-repeat;
            margin-top: 25px;
            margin-right: 14px;
            width: 160px;
            height: 50px;
            float: right;

        }

        #message {float: left;}

        .rounded-corners {
            -moz-border-radius: 10px;
            -webkit-border-radius: 10px;
            -khtml-border-radius: 10px;
            border-radius: 10px;
        }

        .transparent {
            filter:alpha(opacity=50);
            -moz-opacity:0.5;
            -khtml-opacity: 0.5;
            opacity: 0.5;
        }
    </style>

    <script type="text/javascript">
        //enable chcracter count in textarea
        $(document).ready(function(){
            $('#tweetertextarea').limit('140','#left');
        });

        $(document).ready(function(){
            $('.seguido').click(function(){
                var idclase = $(this).attr('id');
                $("."+idclase).toggle();
                $(this).toggleClass('transparent');
            });
        });

        //replacing url
        $(document).ready(function(){
            $("div.usertweet:regex('(?<![a-zA-Z0-9_\"'<>])@([a-z0-9_]{1,20})\\b')").css("color", "red");

        });


        //setting tooltip
        $(document).ready(function(){
            $('#meusseguidosfotos div.seguido img').qtip({
                content: $(this).parent().attr('id'),
                position: {
                    corner: {
                        target: 'topRight',
                        tooltip: 'bottomLeft'
                    }
                },
                style: {
                    name: 'cream',
                    border: {
                        width: 2,
                        radius: 4
                    },
                    tip: 'bottomLeft'
                }
            });
        });
        
    </script>
  </head>
  <body>
      <div id="wrapper">

          <div id="head" class="rounded-corners"></div>

          <div id="content" class="rounded-corners">
              <div id="meustweets" class="rounded-corners">
                  <div id="tweetswrapper">
                      <ic:twitterrowlist timeline="${timeline}" />
                  </div>
              </div>
              <div id="meusseguidos" class="rounded-corners">
                  <div id="meusseguidosfotos">
                      <ic:friendslist listadeamigos="${amigosList}" />
                  </div>
              </div>
          </div>

          <div id="footer" class="rounded-corners">
              <div id="tweetmessage">
                  <form action=""  name="messageform" method="POST">
                      <div id="message">
                          <textarea cols="" rows=""  id="tweetertextarea" name="message"></textarea>
                          <div style="margin-left: 16px; margin-top: 4px;">Ainda restam <span id="left"> </span> caracteres.</div>
                      </div>
                      <div id="tweetbutton" class="rounded-corners"></div>
                  </form>
              </div>
          </div>
      </div>
  </body>
</html>
