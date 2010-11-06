/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package controller;

import java.io.IOException;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import manager.TwitterManager;
import service.FriendsService;
import twitter4j.Status;
import twitter4j.User;
import util.TwitterUtil;

/**
 *
 * @author wllyssys
 */
public class FriendsServlet extends HttpServlet {
   
    /** 
     * Processes requests for both HTTP <code>GET</code> and <code>POST</code> methods.
     * @param request servlet request
     * @param response servlet response
     * @throws ServletException if a servlet-specific error occurs
     * @throws IOException if an I/O error occurs
     */
    protected void processRequest(HttpServletRequest request, HttpServletResponse response)
    throws ServletException, IOException {
        response.setContentType("text/html;charset=UTF-8");
        FriendsService service = new FriendsService();
        //List<User> amigosList = service.getAmigos();
        //List<Status> timeline = service.getTimelineDeAmigos();
        TwitterManager manager = TwitterManager.getInstance();

        request.getSession().setAttribute("timeline", manager.getUserFriendsTimeline());
        request.getSession().setAttribute("amigosList", manager.getAllUserFriends());
        response.sendRedirect("index.jsp");
    }

    protected void parseLinks(List<Status> list) {
        for (Status status : list) {
            String string = status.getText();
            string = TwitterUtil.parseURLTextToHTMLLink(string);
            string = TwitterUtil.parseTwitterHashtagToHTMLLink(string);
            string = TwitterUtil.parseTwitterUserToHTMLLink(string);
        }
    }

    // <editor-fold defaultstate="collapsed" desc="HttpServlet methods. Click on the + sign on the left to edit the code.">
    /** 
     * Handles the HTTP <code>GET</code> method.
     * @param request servlet request
     * @param response servlet response
     * @throws ServletException if a servlet-specific error occurs
     * @throws IOException if an I/O error occurs
     */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
    throws ServletException, IOException {
        processRequest(request, response);
    } 

    /** 
     * Handles the HTTP <code>POST</code> method.
     * @param request servlet request
     * @param response servlet response
     * @throws ServletException if a servlet-specific error occurs
     * @throws IOException if an I/O error occurs
     */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
    throws ServletException, IOException {
        processRequest(request, response);
    }

    /** 
     * Returns a short description of the servlet.
     * @return a String containing servlet description
     */
    @Override
    public String getServletInfo() {
        return "Short description";
    }// </editor-fold>

}
