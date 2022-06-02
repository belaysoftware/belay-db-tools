FROM alpine:latest

RUN apk add s3cmd postgresql14-client --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/

ADD run.sh /run.sh

ENTRYPOINT [ "run.sh" ]`