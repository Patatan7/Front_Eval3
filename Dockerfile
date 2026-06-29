# ================================
# Stage 1: Builder (Maven + Java)
# Genera los archivos estáticos (index.html, styles.css, script.js)
# ================================
FROM maven:3.9-eclipse-temurin-17-alpine AS builder

WORKDIR /app

# Variables de entorno usadas por StaticPageGenerator.java al generar script.js
# Se sobreescriben en build-time con --build-arg para apuntar al ALB real
ARG BACKEND_USERS_URL=http://localhost:8081
ARG BACKEND_PRODUCTS_URL=http://localhost:8082
ENV BACKEND_USERS_URL=${BACKEND_USERS_URL}
ENV BACKEND_PRODUCTS_URL=${BACKEND_PRODUCTS_URL}

COPY pom.xml .
COPY src ./src

# Compila y ejecuta el generador -> crea /app/output/{index.html, styles.css, script.js}
RUN mvn clean compile exec:java -q

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
