# Tiny Happy People text messaging service

Texts video content from BBC's Tiny Happy People to parents

## Getting started

These instructions will get a copy of the project up and running on your local machine for
development and testing purposes.

### Prerequisites

Ruby (see .ruby-version) and PostgreSQL.

### Local setup

1. Clone the repo
2. Navigate to the root directory of the project.
3. `bundle install` to install Ruby dependencies.
4. `rails db:create db:schema:load` to set up the database.
5. `bin/dev` to start a local development server.

Most features should work locally though for some you may need to add the appropriate credentials - see the `.env.test` for an example. You may need to set up accounts for the relevant services or contact a maintainer for the keys.

### Running tests

- `rails test` to run unit tests.
- `rails test:system` to run system/end-to-end tests.

## Deployment

We currently use Heroku to host and deploy this app.

### Heroku Scheduler

The tasks to send messages to parents are set up using Heroku scheduler. See `scheduler.rake` for those tasks.
