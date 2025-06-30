<%@ page import="com.example.SimpleBean" %>
<html>
<head>
    <title>Simple WAR Project</title>
</head>
<body>
    <h1>Welcome to our Simple App</h1>
    
    <% SimpleBean bean = new SimpleBean(); %>
    <p><%= bean.getMessage() %></p>
    
    <p><a href="hello">Call Servlet! Ulli Tirupataiah,sister Teja & Siva</a></p>
    
    <p>Server: <%= application.getServerInfo() %></p>
</body>
</html>