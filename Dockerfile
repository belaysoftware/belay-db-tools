FROM alpine:latest

RUN apk add s3cmd postgresql14-client mysql-client --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/

WORKDIR /root
ADD run.sh .s3cfg /root/

ENTRYPOINT [ "/root/run.sh" ]`