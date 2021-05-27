FROM ruby:2.6.3

WORKDIR /app
RUN gem install bundler -v 2.2.4
COPY Gemfile* /app
RUN bundle install --path vendor/bundle

COPY . /app

ENTRYPOINT ["bundle", "exec"]