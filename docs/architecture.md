# Architecture

How the app is put together and how its main flows work, as diagrams. Class,
method and column names match the code, so you can search for anything you see
here. If you change the schema, one of these flows or
[config/recurring.yml](../config/recurring.yml), update this file in the same PR.

- [System context](#system-context)
- [Weekly message pipeline](#weekly-message-pipeline)
- [Incoming SMS and auto-responses](#incoming-sms-and-auto-responses)
- [A parent's journey](#a-parents-journey)
- [Survey flow](#survey-flow)
- [Scheduled jobs](#scheduled-jobs)
- [Database](#database)

## System context

The app runs on Heroku as a `web` dyno (Puma) and a `worker` dyno (Solid Queue),
both using one Postgres database. Solid Queue keeps its jobs in that same
database. All SMS goes out from background jobs. Delivery receipts and replies
come back to the web dyno as webhooks (dashed lines): AWS sends them through SNS
to `/messages/aws_*`, and Twilio posts to `/messages/twilio_*`.

```mermaid
flowchart LR
  Browser(["Parent's browser"])
  Team(["Team and admins"])
  Parent(["Parent's phone"])

  Web["Heroku web dyno<br/>Rails + Puma"]
  Worker["Heroku worker dyno<br/>Solid Queue"]
  PG[("Heroku Postgres<br/>app data, jobs, analytics")]

  AwsSms["AWS Pinpoint SMS + SNS"]
  Twilio["Twilio"]
  Geo["Geokit geocoder"]
  BBC["BBC Tiny Happy People"]
  SES["AWS SES email"]
  AppSignal["AppSignal"]

  Browser -->|"sign up"| Web
  Parent -->|"taps /m/:token or survey link"| Web
  Team -->|"/admin, Blazer, Skadi, /jobs"| Web
  Web --> PG
  Worker --> PG
  Web -->|"postcode lookup"| Geo
  Web -->|"records clicked_at, then redirects"| BBC
  Worker -->|"send SMS"| AwsSms
  Worker -->|"send SMS"| Twilio
  Worker -->|"link check"| BBC
  Worker -->|"emails"| SES
  SES -->|"login links, reply alerts"| Team
  Worker -->|"errors, check-ins"| AppSignal
  AwsSms <-->|"SMS"| Parent
  Twilio <-->|"SMS"| Parent
  AwsSms -.->|"webhooks"| Web
  Twilio -.->|"webhooks"| Web
```

- Every `users` row has an `sms_provider` (`aws` by default, or `twilio`).
  `Sms::Client` uses it to pick an adapter. Nothing is sent unless
  `SMS_ENABLED` is `"true"`.
- Content links in an SMS point at the app (`/m/:token`), not straight at the
  BBC. `MessagesController#next` sets the message's `clicked_at`, then
  redirects to the BBC page. Only `bbc.co.uk` links are allowed. Survey links
  in an SMS also open in the app.
- Webhooks are checked before they're used: the SNS message signature for AWS,
  and `X-Twilio-Signature` for Twilio.
- The `/admin` area, Blazer, Skadi and Mission Control (`/jobs`) are only for
  signed-in admins (Devise).

## Weekly message pipeline

Each parent gets one piece of content a week, on the day and at the time of day
they chose. [config/recurring.yml](../config/recurring.yml) runs
`SendBulkMessageJob` four times a day: once for each time preference
(`morning`, `afternoon`, `evening`, `no_preference`). Each run only picks up
parents whose `day_preference` matches today.

```mermaid
sequenceDiagram
    autonumber
    participant SQ as Solid Queue<br/>(recurring.yml)
    participant Bulk as SendBulkMessageJob
    participant Send as SendMessageJob
    participant User as User
    participant Client as Sms::Client
    participant Provider as AWS Pinpoint SMS<br/>or Twilio
    participant Webhook as MessagesController
    participant Status as UpdateMessageStatusJob

    SQ->>Bulk: perform("weekly_message", "morning")
    Bulk->>User: not_finished.contactable<br/>.with_preference_for_day(today)<br/>.wants_morning_message
    Bulk->>Send: enqueue_in_batches<br/>(15 jobs per second)

    Send->>User: had_content_this_week? / finished_programme?
    alt already sent this week, or programme finished
        Send-->>Send: return without sending
    end
    Send->>User: next_content
    Note over Send,User: The override content if set, otherwise the next<br/>unseen content in the group. The first message<br/>is picked by the child's age in months.
    Send->>Send: transaction: user.last_content_id = content<br/>and Message.save (body, link, token)

    Send->>Client: send_message
    alt SMS_ENABLED is not "true"
        Client-->>Send: do nothing
    end
    Client->>Provider: deliver via the adapter for user.sms_provider
    Provider-->>Client: message id
    Client->>Client: message.update(status, message_sid)

    opt Wales cohort
        Send->>Send: Survey.trigger_for(user, message_count)<br/>enqueues SendSurveyJob
    end
    opt finished_programme? now true
        Send->>User: finished_content_at = now
        Send->>Send: OffboardingMessageJob in 1 week<br/>(only if programme_length is set)
    end

    Provider->>Webhook: POST /messages/aws_status (via SNS)<br/>or /messages/twilio_status
    Webhook->>Webhook: verify SNS or Twilio signature
    opt delivery failed
        Webhook->>Status: perform_later(message_sid, "failed")
        Status->>Status: message.update(status: "failed")
    end
```

What else to know:

- **Rate limit.** `Sms::Client::BATCH_SIZE` is 15. `EnqueuesJobsInBatches`
  delays each batch of 15 jobs by one more second, to stay under the AWS limit
  of 20 SMS a second.
- **Reruns are safe.** `SendMessageJob` skips anyone who got content in the
  last 6 days, so if `SendBulkMessageJob` fails and runs again, nobody gets two
  messages.
- **Retries.** `RetryFailedMessagesJob` runs every hour. It resends messages
  marked `failed` in the last hour, for parents who are still contactable and
  not anonymised.
- **Link clicks.** `{{link}}` in content becomes `/m/:token`. When a parent
  taps it, `MessagesController#next` sets `clicked_at` and redirects to the
  BBC page. Only `bbc.co.uk` links are allowed.
- **Other one-off messages** (welcome, waitlist, nudge, feedback, bilingual,
  survey, restart, offboarding, broadcasts) skip `SendBulkMessageJob` and
  `SendMessageJob`. They build a `Message` and call `Sms::Client`, usually
  through `SendCustomMessageJob`.

## Incoming SMS and auto-responses

When a parent texts back, the provider calls a webhook and the reply is saved
as a `Message` with `status: "received"`. Saving it triggers the auto-response
check and, at most once a day, an email to the team.

```mermaid
sequenceDiagram
    autonumber
    actor Parent
    participant Provider as AWS (via SNS)<br/>or Twilio
    participant Webhook as MessagesController
    participant Msg as Message
    participant Matcher as ResponseMatcherJob<br/>→ AutoResponseMatch
    participant AR as AutoResponse
    participant User as User
    participant Custom as SendCustomMessageJob
    participant Notify as SendAdminNotificationJob

    Parent->>Provider: SMS reply
    Provider->>Webhook: POST /messages/aws_incoming<br/>or /messages/twilio_incoming
    Webhook->>Webhook: verify SNS or Twilio signature
    opt SNS subscription confirmation
        Webhook-->>Provider: 200, log the SubscribeURL
    end
    Webhook->>Msg: create(user found by phone_number,<br/>body, status: "received")
    Note over Webhook,Msg: If no user has that number, the Message<br/>fails validation and nothing else happens.

    Msg->>Matcher: after_create: perform_later
    opt no AdminNotification for today yet
        Msg->>Msg: AdminNotification.create!(sent_on: today)<br/>(unique index stops duplicates)
        Msg->>Notify: perform_later
        Notify->>Notify: email info@cbeebies-text.uk
    end

    Matcher->>AR: where(trigger_phrase: body.downcase.strip)
    alt one or more matches
        loop each match, until one's conditions pass
            Matcher->>User: do user_conditions all match?
            opt conditions pass
                Matcher->>User: update(update_user fields)<br/>e.g. contactable: false
                Matcher->>Custom: reply with response text, if any
            end
        end
    else no match and it's Saturday or Sunday
        Matcher->>Custom: reply with out-of-hours message
    else no match on a weekday
        Matcher-->>Matcher: no reply (the team follows up)
    end
    Custom->>Provider: Sms::Client.send_message
```

What else to know:

- **Auto-responses are data.** Admins edit them at `/admin/auto_responses`.
  `trigger_phrase` has to match the whole message, ignoring case and spaces at
  either end. `user_conditions` and `update_user` are JSON objects of `User`
  columns. `AutoResponse` checks the column names when it's saved.
- **Opting out and back in** works this way. An auto-response sets
  `contactable` to `false` or `true`. No other code in the app handles
  keywords like STOP, though the SMS providers may also act on them.

## A parent's journey

A parent's state isn't one column. It comes from `contactable`, `restart_at`,
`finished_content_at` and `anonymised_at` on `users`, plus how many content
messages they've had. This diagram shows how they change.

```mermaid
stateDiagram-v2
    direction TB

    [*] --> SigningUp
    SigningUp: Signing up (Registration.submit)
    note right of SigningUp
        Rejected if SIGN_UP_OPEN is "false", if the
        signup cap (3,000 since 13 May 2026) is reached,
        or if the child's age or (for Wales) postcode fails
        validation. Then update_local_authority geocodes
        the postcode.
    end note

    SigningUp --> Waitlisted: child under 6 months
    SigningUp --> Personalising: otherwise

    Waitlisted: Waitlisted
    note right of Waitlisted
        contactable = false
        restart_at = birthday + 6 months
        SendWaitlistMessageJob
        Once restart_at passes, RestartMessagesJob
        (daily 11:00) sends a link that lasts 2 days.
    end note
    Waitlisted --> Personalising: restart link from RestartMessagesJob

    Personalising: Personalising
    note right of Personalising
        Name, day and time of day, language,
        then how they heard about the service.
        Sets contactable = true.
        Ends with SendWelcomeMessageJob.
    end note
    Personalising --> Active: about_service step saved

    state Active {
        direction TB
        [*] --> Weekly
        Weekly: Weekly content (SendMessageJob)
        Weekly --> Weekly: one message a week
        Weekly --> Extras
        Extras: Other messages, from message counts
        Extras --> Weekly
    }
    note right of Active
        Other messages:
        nudge after 3 unclicked links (once, Tuesdays)
        feedback at 2 and 18 messages (Wednesdays)
        bilingual text at 6+ messages (Wales, once, Thursdays)
        survey at send_after_message_count (Wales)
        offboarding warning 4 messages before the end (Wales, Fridays)
    end note

    Active --> OptedOut: auto-response sets contactable false
    OptedOut --> Active: auto-response sets contactable true
    OptedOut: Opted out

    Active --> Finished: finished_programme?
    note right of Finished
        Wales: 52 messages (programme_length).
        first_uk: the group runs out of content.
        finished_content_at is set. Wales parents
        get the offboarding survey a week later.
    end note

    Waitlisted --> Anonymised
    Active --> Anonymised
    OptedOut --> Anonymised
    Finished --> Anonymised
    Anonymised: Anonymised
    note left of Anonymised
        AnonymiseUsersJob (daily 03:00),
        3 years after sign-up. Clears names and
        phone number, and blanks sent message bodies.
    end note
    Anonymised --> [*]
```

What else to know:

- **Cohorts.** `cohort` is `first_uk` or `wales`. Only Wales parents have a
  fixed `programme_length` (52), surveys, the bilingual text and offboarding.
  First UK parents keep getting content until their group runs out.
- **Links expire.** The sign-up `profile_token` lasts 15 minutes and the
  `restart_token` lasts 2 days. If a parent opens an expired link,
  `User.report_expired_token` reports it to AppSignal.
- **Admins can skip content.** Setting `next_content_override` on a user (from
  the admin user page) makes it their next message. Once it's sent,
  `last_content_id` points at it and normal ordering continues.

## Survey flow

Surveys are mainly for the Wales cohort. A `survey_sends` row records that a
parent was sent a survey. Its `completed_at` is set when they submit. Survey
links use the parent's `survey_token`, a short code stored on `users`, so they
don't expire.

```mermaid
sequenceDiagram
  autonumber
  participant Trig as Trigger
  participant Job as SendSurveyJob
  participant SS as SurveySend
  participant Custom as SendCustomMessageJob
  actor Parent
  participant Ctrl as SurveysController
  participant Rem as SendSurveyReminderJob

  alt after the Nth content message (Wales)
    Trig->>Job: Survey.trigger_for(user, message_count)<br/>for surveys with send_after_message_count = N
    Job->>SS: skip if already sent
    Job->>Custom: "messages.survey" text with the survey link
    Job->>SS: create(sent_at: now)
  else broadcast with a survey
    Trig->>SS: SendBroadcastJob creates it with the message
    Trig->>Custom: broadcast body with the survey link
  else sign-up thank-you page (Wales)
    Trig->>SS: find_or_create for "Pre-programme survey"<br/>(the page links to it)
  else a week after the programme ends
    Trig->>Custom: OffboardingMessageJob sends the "Offboarding" survey link
    Note over Trig,SS: No SurveySend is created for this one
  end

  Custom-->>Parent: SMS with /surveys/:id/edit?token=...

  Parent->>Ctrl: GET edit
  Ctrl->>Ctrl: find user by survey_token
  alt survey is full (max_responses reached) and they haven't completed it
    Ctrl-->>Parent: redirect to thank_you (closed)
  else
    Ctrl-->>Parent: questions in the parent's language
    Parent->>Ctrl: PATCH update (nested answers)
    Ctrl->>SS: completed_at = now
    Ctrl-->>Parent: thank_you
  end

  loop daily at 08:00, "Pre-programme survey" only
    Rem->>SS: sent 1 to 2 days ago and not completed?
    Rem->>Custom: reminder, unless already sent today or 2 sends already
    Rem->>SS: create(sent_at: now)
  end
```

## Scheduled jobs

Everything in [config/recurring.yml](../config/recurring.yml). The weekly
message runs happen every day, but each one only messages parents whose
`day_preference` is today. Most of the other jobs pick their parents with a
`User` scope, then enqueue one job per parent through `SendBulkMessageJob`.

| Time  | Every day                                                  | One day a week                                    |
| ----- | ---------------------------------------------------------- | ------------------------------------------------- |
| :00   | Retry failed messages (every hour)                         |                                                   |
| 01:00 | Check BBC links                                            |                                                   |
| 02:00 | Clear finished jobs                                        |                                                   |
| 03:00 | Anonymise users who signed up 3 years ago                  |                                                   |
| 07:00 | Weekly message: morning                                    | Wed: feedback request. Thu: bilingual text (Wales) |
| 07:01 | Weekly message: no preference                              |                                                   |
| 08:00 | Survey reminders                                           |                                                   |
| 11:00 | Weekly message: afternoon. Restarts from the waitlist      | Tue: nudge. Fri: offboarding warning (Wales)      |
| 18:00 | Weekly message: evening                                    |                                                   |

- **Time zone.** Solid Queue reads these times in the server's time zone. On
  Heroku that's UTC unless the `TZ` config var is set, so in summer 07:00 would
  be 08:00 UK time. `config.time_zone` isn't set either, so `Time.zone.today`
  (used to choose the day's parents) is also UTC.
- **11:00 is the busiest slot.** The afternoon message, restarts, Tuesday
  nudges and Friday offboarding warnings all start then. They share the
  worker's 3 threads and the 15-a-second SMS batching.
- **Jobs that aren't scheduled** run when something happens. Welcome and
  waitlist messages run on sign-up. Surveys run after a set number of messages.
  The offboarding survey runs a week after the last message. Broadcasts run when
  an admin sends one. Auto-replies, admin emails and status updates run when a
  webhook arrives.

## Database

Every table in [db/schema.rb](../db/schema.rb), grouped by what it's for.
Timestamps (`created_at`, `updated_at`) are left out to keep the boxes short.
Solid lines are foreign key constraints in the database. Dashed lines are Rails
associations with no constraint. Array columns are shown as `string_array` and
`integer_array`.

### Messaging

Parents sign up as `users` and are put in a `group`. Each group has a sequence
of `contents` keyed by the child's age in months. Every SMS is a `message`,
either from the content programme or from an admin's `broadcast`.

```mermaid
erDiagram
  groups ||--o{ users : "has"
  groups ||..o{ contents : "has"
  local_authorities |o--o{ users : "has"
  contents |o--o{ users : "last_content"
  contents |o--o{ users : "next_content_override"
  users ||--o{ messages : "receives"
  contents |o--o{ messages : "sent as"
  broadcasts |o--o{ messages : "sent as"
  admins ||--o{ broadcasts : "sends"
  users |o--o{ interests : "has"

  users {
    bigint id PK
    bigint group_id FK
    bigint local_authority_id FK
    bigint last_content_id FK
    bigint next_content_override_id FK
    string first_name
    string phone_number
    string postcode
    string language
    string sms_provider
    string child_name
    date child_birthday
    integer cohort
    integer day_preference
    string hour_preference
    integer programme_length
    jsonb referral_sources
    string survey_token
    boolean contactable
    boolean asked_for_feedback
    boolean can_be_contacted_for_research
    boolean can_be_quoted_for_research
    datetime terms_agreed_at
    datetime consent_given_at
    datetime nudged_at
    datetime restart_at
    datetime finished_content_at
    datetime sent_bilingual_text_at
    datetime anonymised_at
  }
  groups {
    bigint id PK
    string name
    string language
  }
  contents {
    bigint id PK
    bigint group_id FK
    integer age_in_months
    integer position
    text body
    string link
    datetime archived_at
  }
  messages {
    bigint id PK
    bigint user_id FK
    bigint content_id FK
    bigint broadcast_id FK
    text body
    string link
    string token
    string status
    string message_sid
    datetime sent_at
    datetime clicked_at
    datetime marked_as_seen_at
  }
  broadcasts {
    bigint id PK
    bigint admin_id FK
    bigint survey_id FK
    text body_en
    text body_cy
    integer_array recipient_ids
    datetime sent_at
  }
  admins {
    bigint id PK
    string email
    string encrypted_password
    string role
    string reset_password_token
    datetime reset_password_sent_at
    datetime remember_created_at
  }
  local_authorities {
    bigint id PK
    string name
    string country
  }
  interests {
    bigint id PK
    bigint user_id FK
    string title
  }
```

Tables with no links: `auto_responses` (trigger_phrase, response,
user_conditions, update_user), `admin_notifications` (sent_on),
`research_study_users` (last_four_digits_phone_number, postcode),
`user_referrers` (gclid and UTM fields).

### Surveys

A `survey` is split into ordered `survey_sections` of `questions`, with English
and Welsh (`_cy`) text.

```mermaid
erDiagram
  surveys ||--o{ survey_sections : "has"
  survey_sections ||--o{ questions : "has"
  questions ||--o{ answers : "has"
  users ||--o{ answers : "gives"
  surveys ||--o{ survey_sends : "sent as"
  users ||--o{ survey_sends : "receives"
  surveys |o--o{ broadcasts : "linked from"

  surveys {
    bigint id PK
    string title_en
    string title_cy
    text intro_en
    text intro_cy
    text thank_you_title_en
    text thank_you_title_cy
    text thank_you_body_en
    text thank_you_body_cy
    integer max_responses
    integer send_after_message_count
  }
  survey_sections {
    bigint id PK
    bigint survey_id FK
    integer position
    string title_en
    string title_cy
  }
  questions {
    bigint id PK
    bigint survey_section_id FK
    integer position
    string question_type
    string text_en
    string text_cy
    string hint_en
    string hint_cy
    string_array options_en
    string_array options_cy
    string language
    boolean show_word_count_nudge
  }
  answers {
    bigint id PK
    bigint question_id FK
    bigint user_id FK
    text response
  }
  survey_sends {
    bigint id PK
    bigint survey_id FK
    bigint user_id FK
    datetime sent_at
    datetime completed_at
  }
  users {
    bigint id PK
  }
  broadcasts {
    bigint id PK
    bigint survey_id FK
  }
```

### Analytics

Ahoy tracks website visits and events. Skadi tracks page views, events and daily
demographic counts. Blazer stores saved SQL queries, dashboards and checks.

```mermaid
erDiagram
  users |o..o{ ahoy_visits : "makes"
  ahoy_visits ||..o{ ahoy_events : "has"
  users |o..o{ ahoy_events : "triggers"
  users |o..o{ skadi_visits : "makes"
  skadi_visits |o--o{ skadi_views : "has"
  skadi_visits |o--o{ skadi_events : "has"
  skadi_views |o--o{ skadi_events : "has"
  blazer_queries |o..o{ blazer_checks : "checked by"
  blazer_queries |o..o{ blazer_dashboard_queries : "placed in"
  blazer_dashboards |o..o{ blazer_dashboard_queries : "contains"
  blazer_queries |o..o{ blazer_audits : "audited in"

  users {
    bigint id PK
  }
  ahoy_visits {
    bigint id PK
    bigint user_id
    string visit_token
    string visitor_token
    text landing_page
    text referrer
    string referring_domain
    string browser
    string os
    string device_type
    text user_agent
    string utm_source
    string utm_medium
    string utm_campaign
    datetime started_at
  }
  ahoy_events {
    bigint id PK
    bigint visit_id
    bigint user_id
    string name
    jsonb properties
    datetime time
  }
  skadi_visits {
    bigint id PK
    bigint user_id
    uuid visit_token
    uuid tracking_token
    text landing_page
    text referrer
    boolean cookies_enabled
    boolean verified
    text utm_source
    text utm_medium
    text utm_campaign
  }
  skadi_views {
    bigint id PK
    bigint visit_id FK
    uuid view_token
    string controller
    string action
    string verb
    text path
    jsonb query_params
    text exit_page
    boolean verified
    string version
  }
  skadi_events {
    bigint id PK
    bigint visit_id FK
    bigint view_id FK
    string name
    jsonb properties
  }
  blazer_queries {
    bigint id PK
    bigint creator_id
    string name
    text description
    text statement
    string data_source
    string status
  }
  blazer_dashboards {
    bigint id PK
    bigint creator_id
    string name
  }
  blazer_dashboard_queries {
    bigint id PK
    bigint dashboard_id
    bigint query_id
    integer position
  }
  blazer_checks {
    bigint id PK
    bigint query_id
    bigint creator_id
    string check_type
    string state
    string schedule
    text emails
    text slack_channels
    text message
    datetime last_run_at
  }
  blazer_audits {
    bigint id PK
    bigint query_id
    bigint user_id
    text statement
    string data_source
  }
```

Tables with no links: `skadi_dashboards` (name, description, configuration),
`skadi_demographics` (name, value, uri, count, recorded_on).

### Rails and jobs

Tables owned by Rails and gems. Active Storage holds uploads, Action Text holds
the rich-text survey intros, and Solid Queue runs background jobs. Each job has
at most one row in each execution table, depending on its state. Polymorphic
links (`record_type` + `record_id`) can point at any table, so only the known
one, survey intros, is drawn.

```mermaid
erDiagram
  active_storage_blobs ||--o{ active_storage_attachments : "attached as"
  active_storage_blobs ||--o{ active_storage_variant_records : "has"
  surveys ||..o{ action_text_rich_texts : "intro_en, intro_cy"
  solid_queue_jobs ||--o| solid_queue_ready_executions : ""
  solid_queue_jobs ||--o| solid_queue_scheduled_executions : ""
  solid_queue_jobs ||--o| solid_queue_claimed_executions : ""
  solid_queue_jobs ||--o| solid_queue_blocked_executions : ""
  solid_queue_jobs ||--o| solid_queue_failed_executions : ""
  solid_queue_jobs ||--o| solid_queue_recurring_executions : ""
  solid_queue_processes |o..o{ solid_queue_claimed_executions : "claims"
  solid_queue_recurring_tasks |o..o{ solid_queue_recurring_executions : "task_key"

  active_storage_blobs {
    bigint id PK
    string key
    string filename
    string content_type
    bigint byte_size
    string checksum
    string service_name
    text metadata
  }
  active_storage_attachments {
    bigint id PK
    bigint blob_id FK
    string name
    string record_type
    bigint record_id
  }
  active_storage_variant_records {
    bigint id PK
    bigint blob_id FK
    string variation_digest
  }
  action_text_rich_texts {
    bigint id PK
    string name
    string record_type
    bigint record_id
    text body
  }
  surveys {
    bigint id PK
  }
  solid_queue_jobs {
    bigint id PK
    string active_job_id
    string class_name
    text arguments
    string queue_name
    integer priority
    string concurrency_key
    datetime scheduled_at
    datetime finished_at
  }
  solid_queue_ready_executions {
    bigint job_id FK
    string queue_name
    integer priority
  }
  solid_queue_scheduled_executions {
    bigint job_id FK
    string queue_name
    integer priority
    datetime scheduled_at
  }
  solid_queue_claimed_executions {
    bigint job_id FK
    bigint process_id
  }
  solid_queue_blocked_executions {
    bigint job_id FK
    string queue_name
    integer priority
    string concurrency_key
    datetime expires_at
  }
  solid_queue_failed_executions {
    bigint job_id FK
    text error
  }
  solid_queue_recurring_executions {
    bigint job_id FK
    string task_key
    datetime run_at
  }
  solid_queue_processes {
    bigint id PK
    string kind
    string name
    string hostname
    integer pid
    bigint supervisor_id
    datetime last_heartbeat_at
  }
  solid_queue_recurring_tasks {
    bigint id PK
    string key
    string schedule
    string class_name
    string command
    text arguments
    string queue_name
    boolean static
  }
```

Tables with no links: `solid_queue_pauses` (queue_name),
`solid_queue_semaphores` (key, value, expires_at).
