FROM ruby:3.0.1

RUN apt-get update -qq \
    && apt-get install -y nodejs libsodium-dev libpq-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
RUN mkdir /myapp

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update && apt-get install -y yarn

WORKDIR /myapp

COPY Gemfile /myapp/Gemfile
COPY Gemfile.lock /myapp/Gemfile.lock
COPY package.json /myapp/package.json
COPY yarn.lock /myapp/yarn.lock

RUN gem install bundler
RUN gem install devise
RUN gem install nokogiri --platform=ruby
RUN bundle install
RUN yarn install

COPY . /myapp
CMD ["rails", "server", "-b", "0.0.0.0", "-p", "3000"]