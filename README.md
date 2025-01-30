# Tiny Happy People text messaging service

Sends weekly texts with links to content from BBC's Tiny Happy People to parents.

Users can sign up, and then only interact with the service via text.
Admins maintain content via the admin dashboard.
Local authorities can view sign up and clickthrough data.

## Getting started

These instructions will get a copy of the project up and running on your local machine for
development and testing purposes.

### Prerequisites

Docker

### Local setup

1. Clone the repo

2. Navigate to the root directory of the project.

3. Install Ruby dependencies and start the local development server.
```shell
docker compose build
docker compose up
```

4. Run the database migrations and seed the database
```shell
docker compose exec app.local bash
rails db:schema:load
```

The local development server will now be accessible at http://localhost:3000.
[Blazer](https://github.com/ankane/blazer) dashboard can be found at http://localhost:3000/admin.

To view the admin dashboard, create an admin user in the database. Login is done via [magic Link](https://github.com/abevoelker/devise-passwordless).

Most features should work locally though for some you may need to add the appropriate credentials -
see the `.env.template` for an example. You may need to set up accounts for the relevant services -
or contact a maintainer for the keys.

### Running tests

- `docker compose exec app.local rails test` to run unit tests.
- `docker compose exec app.local rails test:system` to run system/end-to-end tests.

## Deployment

We use Heroku to host and deploy this app.

### Heroku Scheduler

The tasks to send messages to parents are set up using Heroku scheduler. See `scheduler.rake` for those tasks.

### Sending texts

We currently use [Twilio](https://www.twilio.com/en-us) to send the text messages, and [Sendgrid](https://sendgrid.com/en-us) to send login links to administrators.
