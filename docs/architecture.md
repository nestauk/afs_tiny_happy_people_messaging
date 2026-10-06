# Architecture

How the main flows in the app work, as diagrams. For the database tables, the
scheduled jobs calendar, the system context and the survey flow, open
[architecture.html](architecture.html) in a browser.

Class and method names match the code, so you can search for anything you see
here. If you change one of these flows, update the diagram in the same PR.

- [Weekly message pipeline](#weekly-message-pipeline)
- [Incoming SMS and auto-responses](#incoming-sms-and-auto-responses)
- [A parent's journey](#a-parents-journey)

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
