Repository: tirupdev/gt1  (snapshot on 2025-06-30 04:34:12 )

.
├── pom.xml
├── .github/
│   └── workflows/
│       └── build.yml
└── src/
    └── main/
        ├── java/
        │   └── com/
        │       └── example/
        │           ├── SimpleBean.java
        │           └── HelloServlet.java
        └── webapp/
            └── index.jsp

======================================================================
File: pom.xml
======================================================================
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
                             http://maven.apache.org/xsd/maven-4.0.0.xsd">

  <modelVersion>4.0.0</modelVersion>

  <groupId>com.example</groupId>
  <artifactId>simple-war</artifactId>
  <version>1.0.0</version>
  <packaging>war</packaging>

  <properties>
    <maven.compiler.source>11</maven.compiler.source>
    <maven.compiler.target>11</maven.compiler.target>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
  </properties>

  <dependencies>
    <dependency>
      <groupId>javax.servlet</groupId>
      <artifactId>javax.servlet-api</artifactId>
      <version>4.0.1</version>
      <scope>provided</scope>
    </dependency>
    <dependency>
      <groupId>javax.servlet.jsp</groupId>
      <artifactId>javax.servlet.jsp-api</artifactId>
      <version>2.3.3</version>
      <scope>provided</scope>
    </dependency>
  </dependencies>

  <build>
    <plugins>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-war-plugin</artifactId>
        <version>3.3.2</version>
      </plugin>
    </plugins>
  </build>
</project>


======================================================================
File: .github/workflows/build.yml
======================================================================
name: Build WAR Package and Deploy to Tomcat

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v3
        with:
          java-version: '17'
          distribution: 'temurin'
          cache: 'maven'

      - name: Build with Maven
        run: mvn -B clean package --file pom.xml

      - name: Deploy to EC2 Tomcat # set your credentials in secrets
        env:
          TOMCAT_URL: ${{ secrets.TOMCAT_URL }}   # e.g. http://18.60.47.20:8080 tomcat url
          TOMCAT_USER: ${{ secrets.TOMCAT_USER }} # e.g. tirup tomcat username
          TOMCAT_PASSWORD: ${{ secrets.TOMCAT_PASSWORD }} # e.g. ullitirup@123 tomcat password
        run: |
          # Install curl if not present
          sudo apt-get update && sudo apt-get install -y curl
          # Get the built WAR file
          WAR_FILE=$(ls target/*.war)
          # Deploy using Tomcat Manager
          curl -v --fail --upload-file "$WAR_FILE"                     
          "$TOMCAT_URL/manager/text/deploy?path=/myapp&update=true"                    
           --user "$TOMCAT_USER:$TOMCAT_PASSWORD"


======================================================================
File: src/main/java/com/example/SimpleBean.java
======================================================================
package com.example;

public class SimpleBean {
    private String message = "Hello from Bean!";

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }
}


======================================================================
File: src/main/java/com/example/HelloServlet.java
======================================================================
package com.example;

import java.io.IOException;
import java.io.PrintWriter;
import javax.servlet.*;
import javax.servlet.http.*;

public class HelloServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("text/html");
        try (PrintWriter out = response.getWriter()) {
            out.println("<html><body>");
            out.println("<h1>Hello from Servlet!</h1>");
            out.println("<p>Current time: " + new java.util.Date() + "</p>");
            out.println("</body></html>");
        }
    }
}


======================================================================
File: src/main/webapp/index.jsp
======================================================================
<%@ page import="com.example.SimpleBean" %>
<!DOCTYPE html>
<html>
<head>
    <title>Simple WAR Project</title>
</head>
<body>
    <h1>Welcome to our Simple App</h1>

    <%
        SimpleBean bean = new SimpleBean();
    %>

    <p><%= bean.getMessage() %></p>

    <a href="HelloServlet">Call Servlet</a>

    <p>Server: <%= application.getServerInfo() %></p>
</body>
</html>

