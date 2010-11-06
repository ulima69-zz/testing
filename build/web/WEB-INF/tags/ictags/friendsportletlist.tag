<%-- 
    Document   : userportletlist
    Created on : 30/10/2010, 21:09:41
    Author     : wllyssys
--%>


<%@tag description="Lista de portlets que renderiza usuários" pageEncoding="UTF-8"%>

<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<%@attribute name="listadeamigos" required="true" type="java.util.List" %>
<c:if test="${listadeamigos ne null}">
    <c:forEach var="user" items="${listadeamigos}">
        <div class="portlet">
            <div class="portlet-header"><a href="http://www.twitter.com/${user.screenName}">@${user.screenName}</a></div>
            <div class="portlet-content">
                <img src="${user.profileImageURL}" alt="@${user.screenName} logo" title="@${user.screenName}" height="48" width="48">
                <div class="info">
                    <span style="display: block;">Name: ${user.name}</span>
                    <span style="display: block;">Location: ${user.location}</span>
                    <span style="display: block; overflow: hidden; width: 250px;">Bio: ${user.description}</span>
                </div>
            </div>
        </div>
    </c:forEach>
</c:if>

