FROM golang:1.14.14-alpine3.13

VOLUME /data

RUN apk add --quiet --no-progress --no-cache bash make

ADD go.mod go.sum /data/
WORKDIR /data
RUN go mod download
