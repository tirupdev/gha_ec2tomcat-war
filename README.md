https://github.com/tirupdev/gha_ec2tomcat-war

.
├── pom.xml   # define wa/jar, 
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
            └── index.jsp  # output page

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

# purely on tomcat hos, user, password only

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

  - name: Deploy to Tomcat
    env:
      TOMCAT_URL: ${{ secrets.TOMCAT_URL }}
      TOMCAT_USER: ${{ secrets.TOMCAT_USER }}
      TOMCAT_PASSWORD: ${{ secrets.TOMCAT_PASSWORD }}
    run: |
      # Install curl if not present
      sudo apt-get update && sudo apt-get install -y curl
      
      # Define the context path
      CONTEXT_PATH="/myapp"

      # Undeploy the existing application
      echo "Undeploying existing application..."
      curl -v --fail "$TOMCAT_URL/manager/text/undeploy?path=$CONTEXT_PATH" \
        --user "$TOMCAT_USER:$TOMCAT_PASSWORD" || echo "No previous deployment to remove."

      # Deploy the new WAR file
      WAR_FILE=$(ls target/*.war)
      echo "Deploying new WAR file..."
      curl -v --fail --upload-file "$WAR_FILE" \
        "$TOMCAT_URL/manager/text/deploy?path=$CONTEXT_PATH&update=true" \
        --user "$TOMCAT_USER:$TOMCAT_PASSWORD"


======================================================================
File: .github/workflows/build.yml
======================================================================
## purely using ec2_user(ubuntu), ec2_host(ec2 pip), ec2 pem file(pem key)

name: Build and Deploy to EC2 Tomcat

on:
  push:
    branches: [ main ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
      # Checkout the code
      - name: Checkout code
        uses: actions/checkout@v4

      # Set up Java environment
      - name: Set up JDK 17
        uses: actions/setup-java@v3
        with:
          java-version: '17'
          distribution: 'temurin'

      # Build the WAR file
      - name: Build with Maven
        run: mvn clean package

      # Deploy the WAR file to EC2 Tomcat
      - name: Deploy to EC2 Tomcat
        env:
          EC2_USER: ${{ secrets.EC2_USER }}
          EC2_HOST: ${{ secrets.EC2_HOST }}
          PEM_KEY: ${{ secrets.PEM_KEY }}
        run: |
          # Save PEM key to a file
          echo "${{ secrets.PEM_KEY }}" > ec2-key.pem
          chmod 600 ec2-key.pem

          # Ensure the .ssh directory exists
          mkdir -p ~/.ssh

          # Add EC2 host to known_hosts
          ssh-keyscan -H $EC2_HOST >> ~/.ssh/known_hosts

          # Upload the WAR file
          scp -i ec2-key.pem target/*.war $EC2_USER@$EC2_HOST:/tmp/

          # SSH into EC2 to deploy the WAR
          ssh -i ec2-key.pem $EC2_USER@$EC2_HOST << 'EOF'
            sudo mv /tmp/*.war /opt/tomcat/webapps/
            sudo systemctl restart tomcat
          EOF

          # Clean up the PEM key
          rm -f ec2-key.pem


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


