FROM openjdk:11
RUN echo "WAR NAME is: WAR_NAME"
VOLUME /tmp
RUN mkdir /app
COPY WAR_NAME.war /app/WAR_NAME.war
EXPOSE 8080
USER jboss
ENTRYPOINT ["java"]
CMD ["-jar", "/app/WAR_NAME.war", "--spring.config.location=/config/application.properties", "-Xmx2048m", "-Xms512m", "-Xss128m"]
