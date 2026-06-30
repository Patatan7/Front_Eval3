# ================================
# Stage 1: Builder (Maven + Java)
# ================================
FROM maven:3.9-eclipse-temurin-17-alpine AS builder

WORKDIR /app

ARG BACKEND_USERS_URL=http://localhost:8081
ARG BACKEND_PRODUCTS_URL=http://localhost:8082

COPY pom.xml .
COPY src ./src
COPY .env.example .env

# Sobreescribir las URLs en el .env con los build-args recibidos
RUN sed -i "s|BACKEND_USERS_URL=.*|BACKEND_USERS_URL=${BACKEND_USERS_URL}|" .env && \
    sed -i "s|BACKEND_PRODUCTS_URL=.*|BACKEND_PRODUCTS_URL=${BACKEND_PRODUCTS_URL}|" .env && \
    echo "URLs configuradas:" && cat .env && \
    mvn clean compile exec:java -q

# ================================
# Stage 2: Production (Nginx minimalista)
# ================================
FROM nginx:1.27-alpine AS production

# Nginx ya corre como su propio usuario interno (nginx) sin privilegios root
# para los procesos worker; solo el master arranca como root para bindear el puerto.

# Eliminar el sitio default y copiar los estáticos generados en el stage anterior
RUN rm -rf /usr/share/nginx/html/*
COPY --from=builder /app/output/ /usr/share/nginx/html/

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
