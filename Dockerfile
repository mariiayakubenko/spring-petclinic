FROM openjdk:8-jdk-alpine
COPY /target/*SNAPSHOT.jar /spring_petclinic.jar
CMD ["java", "-jar", "/spring_petclinic.jar", "--server.port=8080"]
