# Parts of the code

The frontend code can be found in `app/frontend`.

# Writing code
When writing code, make a plan by splitting the work into small chunks. Add the code one chunk at a time, preferably in a functional state, asking for confirmation for each change. Always write tests for new code where possible. Never write comments for code that used to exist: comments should be concise and explain the context or reason for the _current_ code.

# Testing
Always write tests to cover new code generated and check for missing tests when reviewing code

The test framework is Minitest (not RSpec), using FactoryBot for fixtures and Mocha for mocking.

Run tests with `bin/rails test <path>` (e.g. `bin/rails test test/models/`) or `bin/rails test:system` for system tests.

# Frontend
The frontend stack is Vite + Alpine.js + Tailwind CSS. Use Alpine.js for interactivity — do not introduce React or other component frameworks.

# Linting
- Ruby: `bundle exec rubocop  -A` to auto-fix where possible.

# Data & Models
To find model structure look in db/schema.rb. The file is big, you'll need to grep
When working with model attributes don't guess, grep the schema at db/schema.rb to confirm and use only valid attributes
