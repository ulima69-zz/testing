package org.apache.jsp;

import javax.servlet.*;
import javax.servlet.http.*;
import javax.servlet.jsp.*;

public final class seguidos_jsp extends org.apache.jasper.runtime.HttpJspBase
    implements org.apache.jasper.runtime.JspSourceDependent {

  private static final JspFactory _jspxFactory = JspFactory.getDefaultFactory();

  private static java.util.Vector _jspx_dependants;

  static {
    _jspx_dependants = new java.util.Vector(1);
    _jspx_dependants.add("/WEB-INF/tags/ictags/friendsportletlist.tag");
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
      out.write("\n");
      out.write("<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\"\n");
      out.write("    \"http://www.w3.org/TR/html4/loose.dtd\">\n");
      out.write("\n");
      out.write("<html>\n");
      out.write("    <head>\n");
      out.write("        <meta charset=\"UTF-8\" />\n");
      out.write("        <title>jQuery UI Sortable - Portlets</title>\n");
      out.write("        <link type=\"text/css\" href=\"css/themes/base/jquery.ui.all.css\" rel=\"stylesheet\" />\n");
      out.write("        <script type=\"text/javascript\" src=\"js/jquery-1.4.2.js\"></script>\n");
      out.write("        <script type=\"text/javascript\" src=\"js/jquery.ui.core.js\"></script>\n");
      out.write("        <script type=\"text/javascript\" src=\"js/jquery.ui.widget.js\"></script>\n");
      out.write("        <script type=\"text/javascript\" src=\"js/jquery.ui.mouse.js\"></script>\n");
      out.write("        <script type=\"text/javascript\" src=\"js/jquery.ui.sortable.js\"></script>\n");
      out.write("        <link type=\"text/css\" href=\"css/themes/demos.css\" rel=\"stylesheet\" />\n");
      out.write("        <link type=\"text/css\" href=\"css/util/util.css\" rel=\"stylesheet\" />\n");
      out.write("        <style type=\"text/css\">\n");
      out.write("            .column { width: 170px; float: left; padding-bottom: 100px; }\n");
      out.write("            .portlet { margin: 0 1em 1em 0; width: 300px; padding-bottom: 4px;}\n");
      out.write("            .portlet-header { margin: 0.3em; padding-bottom: 4px; padding-left: 0.2em; }\n");
      out.write("            .portlet-header .ui-icon { float: right; }\n");
      out.write("            .portlet-content { padding: 0.4em; }\n");
      out.write("            .ui-sortable-placeholder { border: 1px dotted black; visibility: visible !important; height: 50px !important; }\n");
      out.write("            .ui-sortable-placeholder * { visibility: hidden; }\n");
      out.write("\n");
      out.write("            #wrapperpainel {width: 700px; height: 600px; margin: 0 auto; background-color: #f92; padding: 10px;}\n");
      out.write("\n");
      out.write("            #seguidosativos, #seguidosinativos {width:320px; height:580px; overflow: auto; background-color: #3cf; padding: 10px;}\n");
      out.write("            #seguidosinativos {float: left;}\n");
      out.write("            #seguidosativos {float: right;}\n");
      out.write("\n");
      out.write("            #seguidosinativos div.column div.portlet div.portlet-content img,\n");
      out.write("            #seguidosinativos div.column div.portlet div.portlet-content div.info { float: left;}\n");
      out.write("            #seguidosativos div.column div.portlet div.portlet-content img,\n");
      out.write("            #seguidosativos div.column div.portlet div.portlet-content div.info { float: left;}\n");
      out.write("\n");
      out.write("            #seguidosativos div.column div.portlet div.portlet-header a,\n");
      out.write("            #seguidosinativos div.column div.portlet div.portlet-header a {text-decoration: none;}\n");
      out.write("\n");
      out.write("            #seguidosativos div.column div.portlet div.portlet-content div.info,\n");
      out.write("            #seguidosinativos div.column div.portlet div.portlet-content div.info { margin-left: 4px;}\n");
      out.write("\n");
      out.write("            div.info {float: right;}\n");
      out.write("        </style>\n");
      out.write("        <script type=\"text/javascript\">\n");
      out.write("            $(function() {\n");
      out.write("                $(\".column\").sortable({\n");
      out.write("                    connectWith: '.column'\n");
      out.write("                });\n");
      out.write("\n");
      out.write("                $(\".portlet\").addClass(\"ui-widget ui-widget-content ui-helper-clearfix ui-corner-all\")\n");
      out.write("                .find(\".portlet-header\")\n");
      out.write("                .addClass(\"ui-widget-header ui-corner-all\")\n");
      out.write("                .prepend('<span class=\"ui-icon ui-icon-minusthick\"></span>')\n");
      out.write("                .end()\n");
      out.write("                .find(\".portlet-content\");\n");
      out.write("\n");
      out.write("                $(\".portlet-header .ui-icon\").click(function() {\n");
      out.write("                    $(this).toggleClass(\"ui-icon-minusthick\").toggleClass(\"ui-icon-plusthick\");\n");
      out.write("                    $(this).parents(\".portlet:first\").find(\".portlet-content\").toggle();\n");
      out.write("                });\n");
      out.write("\n");
      out.write("                $(\".column\").disableSelection();\n");
      out.write("            });\n");
      out.write("\n");
      out.write("            //tratando o formulário\n");
      out.write("            $('#seguidosform').submit(function(){\n");
      out.write("                var inativos = \"\";\n");
      out.write("                inativos = $('#seguidosinativos div.column div.portlet div.portlet-header a').text();\n");
      out.write("                $('input[name=seguidosinativos]').val(inativos);\n");
      out.write("                var ativos = \"\";\n");
      out.write("                ativos = $('#seguidosativos div.column div.portlet div.portlet-header a').text();\n");
      out.write("                $('input[name=seguidosativos]').val(ativos);\n");
      out.write("                return true;\n");
      out.write("            });\n");
      out.write("        </script>\n");
      out.write("    </head>\n");
      out.write("    <body>\n");
      out.write("        <div id=\"wrapperpainel\" class=\"rounded-corners\">\n");
      out.write("            <form id=\"seguidosform\" action=\"TesteServlet\" method=\"POST\" >\n");
      out.write("\n");
      out.write("                <div id=\"seguidosinativos\" class=\"rounded-corners\">\n");
      out.write("                    <div class=\"column\">\n");
      out.write("                        \n");
      out.write("                    </div>\n");
      out.write("\n");
      out.write("                </div>\n");
      out.write("\n");
      out.write("                <div id=\"seguidosativos\" class=\"rounded-corners\">\n");
      out.write("                    <div class=\"column\">\n");
      out.write("                        ");
      if (_jspx_meth_ic_friendsportletlist_0(_jspx_page_context))
        return;
      out.write("\n");
      out.write("                    </div>\n");
      out.write("                </div>\n");
      out.write("\n");
      out.write("                    <input type=\"hidden\" name=\"seguidosativos\" value=\"tatarara\" />\n");
      out.write("                    <input type=\"hidden\" name=\"seguidosinativos\" value=\"tarara2\" />\n");
      out.write("                    <input type=\"submit\" name=\"submitlist\" />\n");
      out.write("\n");
      out.write("            </form>\n");
      out.write("                    \n");
      out.write("        </div><!-- End wrapperpainel -->\n");
      out.write("    </body>\n");
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

  private boolean _jspx_meth_ic_friendsportletlist_0(PageContext _jspx_page_context)
          throws Throwable {
    PageContext pageContext = _jspx_page_context;
    JspWriter out = _jspx_page_context.getOut();
    //  ic:friendsportletlist
    org.apache.jsp.tag.web.ictags.friendsportletlist_tag _jspx_th_ic_friendsportletlist_0 = new org.apache.jsp.tag.web.ictags.friendsportletlist_tag();
    if (_jspx_resourceInjector != null) {
      _jspx_resourceInjector.inject(_jspx_th_ic_friendsportletlist_0      );
    }
    _jspx_th_ic_friendsportletlist_0.setJspContext(_jspx_page_context);
    _jspx_th_ic_friendsportletlist_0.setListadeamigos((java.util.List) org.apache.jasper.runtime.PageContextImpl.evaluateExpression("${amigosList}", java.util.List.class, (PageContext)_jspx_page_context, null));
    _jspx_th_ic_friendsportletlist_0.doTag();
    return false;
  }
}
