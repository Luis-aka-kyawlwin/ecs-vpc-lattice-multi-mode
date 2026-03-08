FROM golang:1.17-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o counting-service .

FROM alpine:3.17

RUN apk --no-cache add ca-certificates curl openssl bind-tools

WORKDIR /root/
COPY --from=builder /app/counting-service .
COPY certs/ /certs/

EXPOSE 9003
ENV PORT=9003
ENV TLS_ENABLED=false
ENV TLS_CERT_FILE=/certs/tls.crt
ENV TLS_KEY_FILE=/certs/tls.key

CMD ["./counting-service"]
