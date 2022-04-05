#
# build the target application
#
FROM public.ecr.aws/docker/library/golang:1.18-alpine3.15 as builder
RUN apk update && apk upgrade

ENV GOPATH /build
WORKDIR $GOPATH
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go install github.com/rakyll/hey@latest

#
# build the target container
#
FROM public.ecr.aws/docker/library/alpine:3.15

# update the packages
RUN apk update && apk upgrade && apk add bash tzdata ca-certificates curl jq && rm -rf /var/cache/apk/*

# set the timezone appropriatly
ENV TZ=UTC
RUN cp /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Specify home 
ENV APP_HOME /virgo4-basic-loadtesting
WORKDIR $APP_HOME

# copy the scripts, etc
ADD . $APP_HOME

# Move in necessary assets
COPY --from=builder /build/bin/hey $APP_HOME/tools/bin/hey

# Move in other assets
COPY package/data/words /usr/share/dict/words
COPY package/data/container_bash_profile /root/.profile

#
# end of file
#
