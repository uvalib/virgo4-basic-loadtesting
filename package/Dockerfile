#
# build the target application
#
#FROM golang:1.12 as builder
#WORKDIR /build
#RUN go get -u github.com/rakyll/hey

#
# build the target container
#
FROM alpine:3.10

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
#COPY --from=builder /build/bin/virgo4-pool-solr-ws $APP_HOME/bin/virgo4-pool-solr-ws

# Move in other assets
COPY package/data/words /usr/share/dict/words
COPY package/data/container_bash_profile /root/.profile

#
# end of file
#
