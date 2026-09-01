# AGENTS.md

Guidance for any coding agent working in this repository.

See [README.md](README.md) for the development principles and tech stack.

Parts of this file come from the [Rails template]. If you make updates that are
generally useful, and not specific to this repo, port them back to the AGENTS.md
in the template.

[Rails template]: https://github.com/nestauk/dt_rails_template/

## Running things

All dev tasks run through the `./do` script, which runs commands inside Docker.
Don't run `bundle`, `rails` or `npx` directly on the host.

- `./do test` - unit and integration tests (`./do test <path>` for one file)
- `./do test:system` - system (browser) tests
- `./do cs` - Rubocop (`./do cs:fix` to autofix)
- `./do js` - Biome (`./do js:fix` to autofix)
- `./do ci` - the full pipeline

Run `./do help` for the rest.

`./do` shells out to Docker, so it does not work from inside the container -
which is where `./do claude` runs. If you are already in there, run the commands
directly: `bundle exec rubocop`, `npx @biomejs/biome check`,
`bundle exec brakeman -q --no-pager`, `bin/rails test`, `bin/rails test:system`.

## Never do these

- **Never run raw SQL against a production database.**
- **Always ask before running any Rails command against production** - a console,
  a runner, a rake task, a migration. Treat every one of them as destructive
  until a human has said otherwise.
- **Never read secrets.** That means `.env`, Heroku config vars, Rails
  credentials, and anything else holding a key or a password. Don't print them,
  don't copy them into code, and don't put them in a commit, PR or issue.
- **Never copy production data out of production.** No user records in a PR
  description, an issue, a commit message, or a chat. Use seed data, or a
  sanitised dump.
- **Never rewrite shared history.** No force-push to `main`, and none to a branch
  someone else may have checked out.

## Writing code

When writing code, make a plan by splitting the work into small chunks. Add the
code one chunk at a time, preferably in a functional state, asking for
confirmation for each change.

### Comments

Do *not* write inline comments. The method name and body should be self
explanatory, and the tests are there for further documentation.

The only exceptions are:

- **TODO comments** - one line: what should change, and why it was left.
- **Genuinely surprising code** - where the reader needs to know something was
  deliberate rather than a mistake:

  ```ruby
  # method_a rather than the more natural method_b is intentional - method_b has
  # an edge case bug that would break this. See issue #1234.
  ```

Never write comments for code that used to exist: a comment explains the context
or reason for the *current* code.

## Testing

The framework is Minitest - not RSpec - with FactoryBot for fixtures, Mocha for
mocking, and Capybara for system tests.

Always write tests for new code, and check for missing tests when reviewing.

## Frontend

Vite + Alpine.js + Tailwind, with Turbo. Use Alpine for interactivity - don't
introduce React or another component framework. The frontend code is in
`app/frontend`.

## Data and models

Model structure lives in `db/schema.rb`. The file is big, so grep it rather than
opening it. When working with model attributes, don't guess - grep the schema to
confirm the attribute exists.

## Pull Requests

See [docs/pull-requests.md](docs/pull-requests.md) for the full process of
opening, reviewing and merging Pull Requests. The rules below are the short
version - read the full guide before opening a PR.

- Work on a branch. Never commit or push directly to `main`.
- Open a **draft** PR as soon as there is a first commit, so the work is visible
  early.
- Ship the smallest unit of change you can.
- Before marking a PR as ready for review, run `./do ci` locally and make sure it
  passes.
- Write the PR description for someone with no context. Use whichever sections
  of `.github/PULL_REQUEST_TEMPLATE.md` help your reviewer and delete the rest -
  never leave a section saying "n/a". Only tick a checklist item you actually
  did.
- Wait for a green build on CI before asking for a review or merging.
- **Never merge a PR into `main`.** If you are an agent, that decision is not
  yours to make - not even for a one-line change with a green build.
- We follow ship/show/ask, but that advice is written for humans. An agent
  opening a PR on someone's behalf should default to **ask**: leave the PR for a
  human to review, and let the person you are working with make the call.
