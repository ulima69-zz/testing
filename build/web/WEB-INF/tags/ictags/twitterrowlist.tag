<%-- 
    Document   : twitterrowlist
    Created on : 01/11/2010, 10:21:50
    Author     : wllyssys
--%>

<%@tag description="Twitts do usuário" pageEncoding="UTF-8"%>

<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<%@attribute name="timeline" required="true" type="java.util.List" %>

<c:if test="${timeline ne null}" >
    <c:forEach var="status" items="${timeline}" >
        <div class="twitterrow ${status.user.screenName} rounded-corners">
            <div class="userinfo">
                <a href="http://www.twitter.com/${status.user.screenName}">@${status.user.screenName}</a>
                <img src="${status.user.profileImageURL}" />
            </div>
            <div class="usertweet">${status.text}</div>
        </div>
    </c:forEach>
</c:if>

