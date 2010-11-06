<%-- 
    Document   : listadeamigos
    Created on : 01/11/2010, 18:31:53
    Author     : Administrador
--%>

<%@tag description="put the tag description here" pageEncoding="UTF-8"%>

<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<%@attribute name="listadeamigos" required="true" type="java.util.List" %>
<c:if test="${listadeamigos ne null}">
    <c:forEach var="user" items="${listadeamigos}">
        <div id="${user.screenName}" class="seguido">
            <img src="${user.profileImageURL}" alt="${user.screenName}" width="48" height="48"/>
            <!--<a href="#">nome</a>-->
        </div>
    </c:forEach>
</c:if>