# etapa de build: compila o binário num ambiente com todas as deps
FROM golang:1.27-alpine AS builder

WORKDIR /app

# copia o go.mod primeiro pra baixar as dependências e aproveitar o cache de layers
COPY go.mod ./
RUN go mod download

# copia o resto e compila estático (sem depender de libc da imagem final)
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /http-server .

# etapa final: imagem mínima, só com o binário
FROM alpine:3.24

# roda sem root por boas práticas
RUN addgroup -S app && adduser -S app -G app
USER app

COPY --from=builder /http-server /http-server

EXPOSE 8080

CMD ["/http-server"]
