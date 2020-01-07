FROM ruby:2.3-slim

ENV LANG en_US.UTF-8

RUN gem install bundler

RUN apt-get update && apt-get install -y \
     build-essential \
     locales nodejs \
     libpq-dev

RUN mkdir /bundle
ENV BUNDLE_PATH /bundle

WORKDIR /app

COPY run_rails.sh /
CMD ["/run_rails.sh"]

