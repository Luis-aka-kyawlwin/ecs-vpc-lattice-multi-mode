FROM golang:1.17-alpine AS builder

RUN go install github.com/GeertJohan/go.rice/rice@latest

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN rice embed-go
RUN CGO_ENABLED=0 GOOS=linux go build -o dashboard-service .

FROM alpine:3.17

RUN apk --no-cache add ca-certificates curl openssl bind-tools

WORKDIR /root/
COPY --from=builder /app/dashboard-service .

EXPOSE 9002
ENV PORT=9002
ENV COUNTING_SERVICE_URL=http://localhost:9003

CMD ["./dashboard-service"]