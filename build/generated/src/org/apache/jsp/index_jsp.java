package org.apache.jsp;

import javax.servlet.*;
import javax.servlet.http.*;
import javax.servlet.jsp.*;

public final class index_jsp extends org.apache.jasper.runtime.HttpJspBase
    implements org.apache.jasper.runtime.JspSourceDependent {

  private static final JspFactory _jspxFactory = JspFactory.getDefaultFactory();

  private static java.util.Vector _jspx_dependants;

  static {
    _jspx_dependants = new java.util.Vector(2);
    _jspx_dependants.add("/WEB-INF/tags/ictags/twitterrowlist.tag");
    _jspx_dependants.add("/WEB-INF/tags/ictags/friendslist.tag");
  }

  private org.apache.jasper.runtime.ResourceInjector _jspx_resourceInjector;

  public Object getDependants() {
    return _jspx_dependants;
  }

  public void _jspService(HttpServletRequest request, HttpServletResponse response)
        throws java.io.IOException, ServletException {

    PageContext pageContext = null;
    HttpSession session = null;
    ServletContext application = null;
    ServletConfig config = null;
    JspWriter out = null;
    Object page = this;
    JspWriter _jspx_out = null;
    PageContext _jspx_page_context = null;


    try {
      response.setContentType("text/html;charset=UTF-8");
      pageContext = _jspxFactory.getPageContext(this, request, response,
      			null, true, 8192, true);
      _jspx_page_context = pageContext;
      application = pageContext.getServletContext();
      config = pageContext.getServletConfig();
      session = pageContext.getSession();
      out = pageContext.getOut();
      _jspx_out = out;
      _jspx_resourceInjector = (org.apache.jasper.runtime.ResourceInjector) application.getAttribute("com.sun.appserv.jsp.resource.injector");

      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">\n");
      out.write("<html>\n");
      out.write("  <head>\n");
      out.write("    <title></title>\n");
      out.write("    <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\n");
      out.write("    <script type=\"text/javascript\"  src=\"js/jquery-1.4.2.js\"></script>\n");
      out.write("    <script type=\"text/javascript\"  src=\"js/jquery.limit-1.2.js\"></script>\n");
      out.write("    <script type=\"text/javascript\"  src=\"js/jquery.regex.js\"></script>\n");
      out.write("    <script type=\"text/javascript\"  src=\"js/jquery.qtip-1.0.js\"></script>\n");
      out.write("    <link href='http://fonts.googleapis.com/css?family=Droid+Sans:bold' rel='stylesheet' type='text/css'>\n");
      out.write("    <style type=\"text/css\">\n");
      out.write("        body {\n");
      out.write("            font-family: 'Droid Sans',   sans-serif;\n");
      out.write("            font-size: 12px;\n");
      out.write("            line-height: 14px;\n");
      out.write("            font-weight: bold;\n");
      out.write("            word-spacing: 2px;\n");
      out.write("            margin: 0; padding: 0; height: 100%;}\n");
      out.write("        #wrapper{margin: 0 auto; width: 960px; height: 100%; min-height: 100%}\n");
      out.write("\n");
      out.write("        #head {\n");
      out.write("            height: 50px;\n");
      out.write("            background: url('image/gline.png') repeat-x;\n");
      out.write("            margin-bottom: 10px;\n");
      out.write("        }\n");
      out.write("\n");
      out.write("        #content {\n");
      out.write("            background: #ff6633;\n");
      out.write("            height: 510px;\n");
      out.write("            margin-bottom: 10px;\n");
      out.write("            padding: 10px;\n");
      out.write("        }\n");
      out.write("\n");
      out.write("        #footer {\n");
      out.write("            background: url('image/gline.png') repeat-x;\n");
      out.write("            height: 100px;\n");
      out.write("\n");
      out.write("        }\n");
      out.write("\n");
      out.write("        #meustweets {\n");
      out.write("            background: url('image/fundo.png') repeat-x;\n");
      out.write("            width: 700px;\n");
      out.write("            height: 510px;\n");
      out.write("            float: left;\n");
      out.write("        }\n");
      out.write("\n");
      out.write("        #tweetswrapper {\n");
      out.write("            margin: 10px;\n");
      out.write("            height: 490px;\n");
      out.write("            overflow: auto;\n");
      out.write("        }\n");
      out.write("\n");
      out.write("        #tweetswrapper div.twitterrow {\n");
      out.write("            background:url(\"image/bg_pattern_gray.png\") repeat scroll left top transparent;\n");
      out.write("            margin: 4px;\n");
      out.write("            height: 100px;\n");
      out.write("            border: 1px solid #36f;\n");
      out.write("            padding: 4px;\n");
      out.write("        }\n");
      out.write("\n");
      out.write("        #tweetswrapper div.twitterrow:hover {border: 1px solid #f63;}\n");
      out.write("\n");
      out.write("        #tweetswrapper div.twitterrow div.userinfo { \n");
      out.write("            height: 90px;\n");
      out.write("            margin: 5px;\n");
      out.write("            float: left;\n");
      out.write("            border-right: 2px dotted #3cf;\n");
      out.write("            width: 25%;\n");
      out.write("        }\n");
      out.write("        #tweetswrapper div.twitterrow div.userinfo img {margin: 10px 0 0 50px;}\n");
      out.write("        #tweetswrapper div.twitterrow div.userinfo a {display: block;}\n");
      out.write("        #tweetswrapper div.twitterrow div.usertweet {\n");
      out.write("            float: right;\n");
      out.write("            width: 70%;\n");
      out.write("            height: 90px;\n");
      out.write("            padding-top: 8px;\n");
      out.write("            padding-right: 4px;\n");
      out.write("        }\n");
      out.write("\n");
      out.write("        #meusseguidos {\n");
      out.write("            background: url('image/fundo.png') repeat-x;\n");
      out.write("            width: 140px;\n");
      out.write("            height: 510px;\n");
      out.write("            float: right;\n");
      out.write("        }\n");
      out.write("\n");
      out.write("        #meusseguidosfotos {\n");
      out.write("            width: 100px;\n");
      out.write("            height: 490px;\n");
      out.write("            margin-top: 10px;\n");
      out.write("            margin-right: 10px;\n");
      out.write("            float: right;\n");
      out.write("            overflow: auto;}\n");
      out.write("\n");
      out.write("        #meusseguidosfotos div.seguido img {\n");
      out.write("            margin: 4px 20px 0 4px;\n");
      out.write("            border: 1px solid #36f;\n");
      out.write("        }\n");
      out.write("\n");
      out.write("        #meusseguidosfotos div.seguido img:hover {\n");
      out.write("            border: 1px solid #f63;\n");
      out.write("        }\n");
      out.write("\n");
      out.write("        #botaorefresh {\n");
      out.write("            background: url('image/gline.png') repeat-x;\n");
      out.write("            width: 160px;\n");
      out.write("            height: 50px;\n");
      out.write("            margin-top: 250px;\n");
      out.write("        }\n");
      out.write("\n");
      out.write("        #botaorefresh span {color: #A65C0E; }\n");
      out.write("\n");
      out.write("        #footer #tweetmessage #message textarea {\n");
      out.write("            width: 672px;\n");
      out.write("            height: 50px;\n");
      out.write("            margin-left: 14px; margin-top: 12px;}\n");
      out.write("\n");
      out.write("        #footer #tweetmessage #tweetbutton {\n");
      out.write("            background: url('image/tweet.png') #ffb260 no-repeat;\n");
      out.write("            margin-top: 25px;\n");
      out.write("            margin-right: 14px;\n");
      out.write("            width: 160px;\n");
      out.write("            height: 50px;\n");
      out.write("            float: right;\n");
      out.write("\n");
      out.write("        }\n");
      out.write("\n");
      out.write("        #message {float: left;}\n");
      out.write("\n");
      out.write("        .rounded-corners {\n");
      out.write("            -moz-border-radius: 10px;\n");
      out.write("            -webkit-border-radius: 10px;\n");
      out.write("            -khtml-border-radius: 10px;\n");
      out.write("            border-radius: 10px;\n");
      out.write("        }\n");
      out.write("\n");
      out.write("        .transparent {\n");
      out.write("            filter:alpha(opacity=50);\n");
      out.write("            -moz-opacity:0.5;\n");
      out.write("            -khtml-opacity: 0.5;\n");
      out.write("            opacity: 0.5;\n");
      out.write("        }\n");
      out.write("    </style>\n");
      out.write("\n");
      out.write("    <script type=\"text/javascript\">\n");
      out.write("        //enable chcracter count in textarea\n");
      out.write("        $(document).ready(function(){\n");
      out.write("            $('#tweetertextarea').limit('140','#left');\n");
      out.write("        });\n");
      out.write("\n");
      out.write("        $(document).ready(function(){\n");
      out.write("            $('.seguido').click(function(){\n");
      out.write("                var idclase = $(this).attr('id');\n");
      out.write("                $(\".\"+idclase).toggle();\n");
      out.write("                $(this).toggleClass('transparent');\n");
      out.write("            });\n");
      out.write("        });\n");
      out.write("\n");
      out.write("        //replacing url\n");
      out.write("        $(document).ready(function(){\n");
      out.write("            $(\"div.usertweet:regex('(?<![a-zA-Z0-9_\\\"'<>])@([a-z0-9_]{1,20})\\\\b')\").css(\"color\", \"red\");\n");
      out.write("\n");
      out.write("        });\n");
      out.write("\n");
      out.write("\n");
      out.write("        //setting tooltip\n");
      out.write("            $(document).ready(function(){\n");
      out.write("                $('#meusseguidosfotos div.seguido img').qtip({\n");
      out.write("                    content: '<span style=\\\"display:block;\\\">Fulano de Tal</span><span style=\\\"display:block;\\\">@FulanodeTal</span>',\n");
      out.write("                    position: {\n");
      out.write("                        corner: {\n");
      out.write("                            target: 'topRight',\n");
      out.write("                            tooltip: 'bottomLeft'\n");
      out.write("                        }\n");
      out.write("                    },\n");
      out.write("                    style: {\n");
      out.write("                        name: 'cream',\n");
      out.write("                        border: {\n");
      out.write("                            width: 2,\n");
      out.write("                            radius: 4\n");
      out.write("                        },\n");
      out.write("                        tip: 'bottomLeft'\n");
      out.write("                    }\n");
      out.write("                });\n");
      out.write("            });\n");
      out.write("        \n");
      out.write("    </script>\n");
      out.write("  </head>\n");
      out.write("  <body>\n");
      out.write("      <div id=\"wrapper\">\n");
      out.write("\n");
      out.write("          <div id=\"head\" class=\"rounded-corners\"></div>\n");
      out.write("\n");
      out.write("          <div id=\"content\" class=\"rounded-corners\">\n");
      out.write("              <div id=\"meustweets\" class=\"rounded-corners\">\n");
      out.write("                  <div id=\"tweetswrapper\">\n");
      out.write("                      ");
      if (_jspx_meth_ic_twitterrowlist_0(_jspx_page_context))
        return;
      out.write("\n");
      out.write("                  </div>\n");
      out.write("              </div>\n");
      out.write("              <div id=\"meusseguidos\" class=\"rounded-corners\">\n");
      out.write("                  <div id=\"meusseguidosfotos\">\n");
      out.write("                      ");
      if (_jspx_meth_ic_friendslist_0(_jspx_page_context))
        return;
      out.write("\n");
      out.write("                  </div>\n");
      out.write("              </div>\n");
      out.write("          </div>\n");
      out.write("\n");
      out.write("          <div id=\"footer\" class=\"rounded-corners\">\n");
      out.write("              <div id=\"tweetmessage\">\n");
      out.write("                  <form action=\"\"  name=\"messageform\" method=\"POST\">\n");
      out.write("                      <div id=\"message\">\n");
      out.write("                          <textarea cols=\"\" rows=\"\"  id=\"tweetertextarea\" name=\"message\"></textarea>\n");
      out.write("                          <div style=\"margin-left: 16px; margin-top: 4px;\">Ainda restam <span id=\"left\"> </span> caracteres.</div>\n");
      out.write("                      </div>\n");
      out.write("                      <div id=\"tweetbutton\" class=\"rounded-corners\"></div>\n");
      out.write("                  </form>\n");
      out.write("              </div>\n");
      out.write("          </div>\n");
      out.write("      </div>\n");
      out.write("  </body>\n");
      out.write("</html>\n");
    } catch (Throwable t) {
      if (!(t instanceof SkipPageException)){
        out = _jspx_out;
        if (out != null && out.getBufferSize() != 0)
          out.clearBuffer();
        if (_jspx_page_context != null) _jspx_page_context.handlePageException(t);
      }
    } finally {
      _jspxFactory.releasePageContext(_jspx_page_context);
    }
  }

  private boolean _jspx_meth_ic_twitterrowlist_0(PageContext _jspx_page_context)
          throws Throwable {
    PageContext pageContext = _jspx_page_context;
    JspWriter out = _jspx_page_context.getOut();
    //  ic:twitterrowlist
    org.apache.jsp.tag.web.ictags.twitterrowlist_tag _jspx_th_ic_twitterrowlist_0 = new org.apache.jsp.tag.web.ictags.twitterrowlist_tag();
    if (_jspx_resourceInjector != null) {
      _jspx_resourceInjector.inject(_jspx_th_ic_twitterrowlist_0      );
    }
    _jspx_th_ic_twitterrowlist_0.setJspContext(_jspx_page_context);
    _jspx_th_ic_twitterrowlist_0.setTimeline((java.util.List) org.apache.jasper.runtime.PageContextImpl.evaluateExpression("${timeline}", java.util.List.class, (PageContext)_jspx_page_context, null));
    _jspx_th_ic_twitterrowlist_0.doTag();
    return false;
  }

  private boolean _jspx_meth_ic_friendslist_0(PageContext _jspx_page_context)
          throws Throwable {
    PageContext pageContext = _jspx_page_context;
    JspWriter out = _jspx_page_context.getOut();
    //  ic:friendslist
    org.apache.jsp.tag.web.ictags.friendslist_tag _jspx_th_ic_friendslist_0 = new org.apache.jsp.tag.web.ictags.friendslist_tag();
    if (_jspx_resourceInjector != null) {
      _jspx_resourceInjector.inject(_jspx_th_ic_friendslist_0      );
    }
    _jspx_th_ic_friendslist_0.setJspContext(_jspx_page_context);
    _jspx_th_ic_friendslist_0.setListadeamigos((java.util.List) org.apache.jasper.runtime.PageContextImpl.evaluateExpression("${amigosList}", java.util.List.class, (PageContext)_jspx_page_context, null));
    _jspx_th_ic_friendslist_0.doTag();
    return false;
  }
}
