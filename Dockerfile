FROM ruby:2.6.5

LABEL maintainer="p-duong@ruby-dev.jp"

# Install necessary libs
RUN apt-get update -y && apt-get install -y \
  apt-transport-https
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update -y && apt-get install -y \
  nodejs \
  yarn \
  git-core \
  vim \
  nano \
  zlib1g-dev \
  build-essential \
  libssl-dev \
  libreadline-dev \
  libyaml-dev \
  libxml2-dev \
  libxslt1-dev \
  libcurl4-openssl-dev \
  software-properties-common \
  libffi-dev \
  default-mysql-client

# Install bundler version 2.0.2
RUN gem install bundler:2.0.2
RUN gem update --system

# Set up project folder
RUN mkdir /rails_skeleton
COPY Gemfile* /rails_skeleton/
WORKDIR /rails_skeleton

# Set up ENV
ENV LANG C.UTF-8
ENV BUNDLER_VERSION 2.0.2

# Set up Gems
RUN bundle install

# Copy project to Docker container
COPY . /rails_skeleton

# Startup command
ENTRYPOINT ["./docker/scripts/docker-entrypoint.sh"]
CMD ["sh", "-c", "bundle install && yarn install && bin/rails s -b 0.0.0.0"]
