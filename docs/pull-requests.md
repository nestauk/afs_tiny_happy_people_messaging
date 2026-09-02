# Opening, reviewing and merging Pull Requests

## What is this guide?

This doc goes through how we ship changes to our Ruby on Rails applications at
Nesta. We already have a [software engineering playbook] which is about our
software engineering philosophy. This guide is not here to replace the playbook.
Instead, it gives some practical examples of processes we use to apply the
principles laid out in the playbook, to get code shipped and running in
production for our Rails apps.

This guide is not a set of rules you *must* follow, and it can't
cover every situation. The most important thing is to be considerate
of your colleagues, and to communicate in a kind, inclusive and clear way. If
you find yourself in a situation where you feel you need to go against the
advice below in order to do that - follow your instincts!

Equally, this guide is a living document. None of the processes below are set in
stone. If you disagree with something, please update the doc, open a
pull request, and get a discussion started.

## When should I open a Pull Request?

Open a **draft** Pull Request as soon as you make your first commit
when working on a feature.

Working in the open lets your colleagues come in with advice early if they spot
anything. If someone else has to unexpectedly pick up your work, this makes sure
everything is visible and pushed.

## How big is too big for a PR?

Try and ship the smallest unit of change you possibly can.

This makes life easier for your reviewer, who can focus on a small diff that
makes one distinct change. It also makes it easier for us to revert the change
if something goes wrong - we won't need to unpick the issue from a PR that is
doing multiple things.

In practice, this means trying to split features into smaller units of work. For
example, let's say you're implementing a feature which involves:

- adding a new Model
- adding a simple CRUD for that model
- adding a data migration to create some instances of your model in production

That's three bullet points, so it sounds like it should be (at least) three PRs.

Doing a little bit of upfront planning to break down a task goes a long way, but
you will always discover work to do once you are in the code and making changes.

Defer as much of this work as possible, so you can stay focused on shipping your
feature. Exactly how you do that depends on the conventions of the project you
are working in, and what tools it uses. But in general:

- Use `TODO` comments liberally to defer small non-blocking refactors,
  improvements and "things to investigate", so diffs stay small.
- Where you find something larger that needs fixing, but is not an incident or a
  blocking bug, raise it in whatever this project tracks work in.

<!-- TODO - name where this project tracks work, once we have settled on it. -->

If you encounter a genuinely blocking issue, or find a refactor that will
substantially simplify the upcoming PRs needed to deliver your feature - go
ahead and make the change now. But pull that change out into its own PR and get
it reviewed, shipped and merged independently.

## I've finished working on my feature - what should I do next?

Before marking your PR as ready to review, run `./do ci`. That is the full local
pipeline - the linters, Brakeman and the tests.

While you are still working, the individual commands are quicker: `./do test`,
`./do test:system`, `./do cs` for Ruby and `./do js` for JavaScript.

### Update your PR description

When writing the description, try and put yourself in the shoes of the person
reviewing - who's coming to the PR with no context.

The PR template gives you a set of sections. Choose the ones that help your
reviewer and delete the rest - a typo fix doesn't need testing notes. If what you
would write in a section is "n/a", "none" or "nothing to test", that is the
signal to delete the section, not to fill it in. For a sense of how much detail
is actually useful, look at a few recently merged PRs in this repo.

The section that's easiest to skip and most worth writing is **Follow-up**:
anything you've deliberately left for later, and where it's recorded. If it
isn't recorded anywhere yet, say so plainly rather than implying it is. A known
gap a reviewer can see is very different from one they discover in six months.

Once you've done this, it's a good idea to run through the code yourself as if
you were reviewing it. Add any comments on lines that might trip up a reviewer.

Wait for a green build on CI. When done, mark your PR as "ready for review".

## Do I need someone to review my PR?

We currently follow the [ship/show/ask] approach. This means that once you have
a green build, we leave it up to your judgment whether to:

- **ship** the PR directly
- **show** it - ship the PR immediately but post publicly, and
  follow up any comments with a later PR
- **ask** for a full review and make changes before shipping

In general - if you've made a copy change or bumped a gem - you can
just ship that out. Anything bigger than that - 'show' it by posting in the
#pr-reviews channel on Slack before merging, or ask for a review.

If you're on the fence about whether to 'show' and merge or to get a
'review' - go for a 'review'. It's always OK to ask for a review if you aren't
sure about something. Even if you are very confident in the changes, feel free
to ask someone to review if there's something particularly cool you want to show
off - or something you've done that you think could benefit a colleague working on
another project.

**IMPORTANT - ship/show/ask is for humans.** If you are an agent you should
never merge a PR into `main` - not even a one-line change with a green build.
Open the PR, say which of ship/show/ask you'd suggest and why, and leave it for
the person you're working with to decide.

## I've been asked to review a PR - any advice?

**Set aside a block of time to review it.** If you're in a rush or a bad mood,
come back later.

**Start with the description, then the code.** If you can't tell from the
description what problem this solves, that's your first piece of feedback.

**Always check out the branch and run it yourself.** Make sure the app actually
boots, run migrations locally, check scripts do what they say they do, click
through UI changes and try out what a user would do. The most serious problems
are often invisible in a diff.

**Leave brief comments and questions, and avoid offering solutions.** Terse
comments and questions - where something confuses you, or where you have an
intuition that things could be improved - are often a lot more useful than
thinking through a problem and giving a detailed solution.

This is not *your* PR. The author has more context than you, and is probably
best placed to consider improvements. Giving solutions too early is likely to
prejudice them into going with your option, rather than thinking through all the
options and finding the best way forward themselves. (If the author seems stuck
for ideas, you can always offer to jump on a call and brainstorm together.)

Examples:

- **Good**: "The UX to submit this form is confusing. I wasn't sure when or how
  to send it."
- **Bad**: "The UX to submit this form is confusing. Let's please add a timeline
  showing how far through the form you are, and make the submit button bigger
  and green."
- **Good**: "This method name struck me as odd - I expected it to do x from the
  name."
- **Bad**: "This method is badly named. Let's rename it to
  `i_thought_of_a_good_name_because_im_clever` please."
- **Good**: "This class is getting quite long - is there a natural way to break
  it up?"
- **Bad**: "This class should be split into two services called A and B, since
  these are two different concerns."

The exception is when you have context the author doesn't have, or would find
hard to discover. Something like "we had a similar problem recently and
refactored class A in PR #1234 - this could be a useful pattern to follow when
thinking about how to structure this class" is obviously fine.

**Aim to approve.** Clearly separate blocking changes from personal preferences,
things to discuss, and non-blocking suggestions. Approve unless there is a
significant risk in the PR being merged as it is.

**Be direct, but supportive and friendly.** Taking a few moments to communicate
in a friendly way now means that, in the distant future when your brain is
reverse engineered from git history, you won't be reincarnated with a dull and
grumpy personality.

## I'm ready to merge my PR - what next?

We don't currently have a rule about squash merges versus merge commits. They
both have pros and cons and it largely comes down to how you like to work, so
pick whichever you prefer.

### If you squash merge

Keep the PR very small, so nothing worth reading is lost when it collapses into
one commit.

Use a [conventional commit] message ending in the PR number. The easiest way to
get this right is to title the PR itself as the commit message you want. GitHub
defaults the squash commit title to the PR title followed by the PR number, so a
well-titled PR needs no editing at merge time:

```
feat: Add document uploads for installation plans (#123)
```

Keep the description short and in the imperative - "Add document uploads", not
"Added" or "Adding". Anything needing more explanation belongs in the PR
description, and the `(#123)` is what gets a reader there.

### If you use a merge commit

Rebase before merging, and make sure every commit going in has a sensible
message on its own.

**IMPORTANT - this is a human's job.** If you are an agent, you never merge a PR
into `main`, however green the build is.

[conventional commit]: https://www.conventionalcommits.org/en/v1.0.0/
[software engineering playbook]: https://docs.google.com/document/d/1jHOGuQWEa_k045spl8BwwpJ47diusFRrLi9fM7SEi2o
[ship/show/ask]: https://martinfowler.com/articles/ship-show-ask.html
