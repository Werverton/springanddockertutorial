# syntax=docker/dockerfile:1
#vai usar essa imagem
FROM eclipse-temurin:17-jdk-jammy AS base
#torna o /app o diretório onde todos os outros comandos serão executados
WORKDIR /app
#copia o mvn e o pom para dentro do /app
COPY .mvn/ .mvn
COPY mvnw pom.xml ./
#roda o maven para instalar as dependências
RUN ./mvnw dependency:resolve
#neste ponto já temos a imagem com OpenJDK 17 e as dependências instaladas

#agora copiar todo o nosso código para dentro da imagem
COPY src ./src

FROM base as test
RUN ["./mvnw", "test"]

FROM base as development
#aqui O cmd é usado definir um comando que vai ser executado quando a imagem for carregada.
CMD ["./mvnw", "spring-boot:run", "-Dspring-boot.run.profiles=mysql", "-Dspring-boot.run.jvmArguments='-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:8000'"]

FROM base as build
RUN ./mvnw package

FROM eclipse-temurin:17-jre-jammy as production
EXPOSE 8080
COPY --from=build /app/target/spring-petclinic-*.jar /spring-petclinic.jar
CMD ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "/spring-petclinic.jar"]
