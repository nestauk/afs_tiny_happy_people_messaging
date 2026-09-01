<!--
Write this for someone coming to the PR with no context, and make it as easy as
possible for a reviewer to approve. That means:
- one focussed change per PR - keep the diff as small as possible
- clear, short description of **why** we're making this change
- you've personally run the code (in the console for backend changes, or by clicking
  through any UI changes)
- green build on CI

See docs/pull-requests.md for the full guide.

The sections below are designed for features. Pick the ones that help your
reviewer and delete the rest - a PR that only needs an Overview should only have
an Overview. If what you would write in a section is "n/a", "none" or "nothing
to test", delete the section instead of writing that.
-->

<!--
A very high level headline of the change, and why it's being made (2-3 sentences).

Example (made up, to show the level of detail):
Introduces a `Document` model. This models heat pump installation plan pdf docs
uploaded by users (the frontend doc uploader will follow soon).
-->

### Details

<!--
A little more detail of the what and why if necessary. If you've made a frontend
change, a picture is worth a thousand words. Before and after screenshots, or a video
clicking through your new flow is ideal here. Avoid in-depth technical implementation
details unless there's something a reviewer would otherwise trip over.

If this change builds on an earlier PR, link it here.
-->

### Testing notes

<!--
Anything your reviewer will need to know to test this.

Example (made up, to show the level of detail):
You need to be logged in as a logistics user to get to this page. Run
`User.create!(role: :logistics, password: 'test123')` to create one. You will also
need to turn on the `new_logistics_thing_ive_done` feature flag at /flags.
Once logged in, navigate to 'orders' in the top nav to start the new flow.
-->

### Asks - Anything you'd like feedback on

<!--
Any asks of your reviewer, or notes on things you are unsure of - "I thought about
implementing x like this, but ended up going with this approach. I'm still on the
fence about this approach".
-->

### Follow-up

<!--
What's coming next or needs to be followed up on.
Anything you've deliberately left for later, and where it's recorded - an issue
number, TODO, or the next PR. If it isn't recorded anywhere yet, say so plainly rather
than implying it is.
-->

---

Before marking as ready for review - only tick what you actually did, and delete
any line that cannot apply to this change:

- [ ] `./do ci` passes locally
- [ ] I've read through the diff myself and left comments on anything that might trip up a reviewer
