# Make sure RUBY_VERSION matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.2.2

FROM ruby:$RUBY_VERSION

# Setup default directory
RUN mkdir /var/source
WORKDIR /var/source

# Install rails and dependencies
RUN gem install rails bundler

# Install the Heroku CLI
RUN curl https://cli-assets.heroku.com/install-ubuntu.sh | sh

# Install node 22
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash
RUN apt-get install -y nodejs

# Install playwright driver
RUN npx playwright install chromium --with-deps

COPY docker/rails_entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
