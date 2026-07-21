FROM ruby:3.4.4-slim AS build
RUN apt-get update -qq && apt-get install --no-install-recommends -y build-essential libpq-dev nodejs && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN bundle config set without 'development test' && bundle install
COPY . .
RUN SECRET_KEY_BASE=dummy APP_HOST=example.invalid RAILS_ENV=production bundle exec rails assets:precompile

FROM ruby:3.4.4-slim
RUN apt-get update -qq && apt-get install --no-install-recommends -y libpq5 curl && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /app /app
RUN useradd --create-home --uid 10001 app && mkdir -p storage/media && chown -R app:app log tmp storage
USER app
ENV RAILS_ENV=production RAILS_LOG_TO_STDOUT=true RAILS_SERVE_STATIC_FILES=true
EXPOSE 3000
CMD ["./bin/start"]
