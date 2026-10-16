# SMS delivery, failure handling and retries

How an outbound SMS is sent, how failures come back from AWS, and how failed messages are retried.

Twilio was the initial SMS client/service (from the 1st England pilot, 08.24-05.25). The app then moved
to AWS End User Messaging in June 2026 (first message sent 29.06.26). Both services are currently
active (as at 16.10.26) because users from the 1st pilot (England) and the 2nd pilot (wales-eng and
wales-cr) are still receiving messages. Which SMS client is used is defined under `User.sms_provider`
(user sms_provider counts as at 16.10.26 twilio: 1960, aws: 523).

## SMS sending code flow

SendBulkMessageJob (recurring) -> SendMessageJob -> Sms::Client -> Sms::AwsAdapter#deliver ->
MessagesController#aws_status

_Diagrammed SMS send flow_
![SMS deliver flow: stage 1 branches on whether AWS accepts the message, stage 2 reports delivery later through SNS](images/sms-deliver-flow.svg)

A message succeeds or fails at two separate stages: first whether AWS accepts it, then whether AWS
manages to deliver it to the phone.

### Stage 1 - AWS accepting the message

`Sms::AwsAdapter#deliver` calls the AWS `#send_text_message` endpoint:

- **Succeeds**
  - AWS returns a response object with the `message_id`. We save this as `message_sid` on the message
    (named due to the original Twilio only implementation) and set the status to `sent`. This only
    marks that the message has been accepted by AWS, not that delivery has succeeded.

- **Fails**
  - It throws an `Aws::PinpointSMSVoiceV2::Errors::ServiceError`, which is caught. Details are
    reported to Appsignal (tags `message_id`, `user_id`, `aws_event_type`, `aws_status_description`)
    and the message status is set to `failed`.
  - No AWS event exists or is sent to SNS for these, because AWS never accepted the message.

### Stage 2 - AWS delivering the message

Only happens for messages accepted in stage 1. AWS publishes an event for the delivery outcome via two
'Configuration Sets', one sending to the AWS SNS pubsub service and one to AWS CloudWatch.

- Events are broadcast to the `cbeebies-sms-delivery-status` SNS topic, which is configured to call
  our `messages/aws_status` callback endpoint:
  AWS event destination -> SNS topic -> `POST /messages/aws_status` -> `UpdateMessageStatusJob`

- **The event** is JSON in the SNS envelope's `Message` field (`sns_event` in the
  controller). The fields we use:
  - `eventType` - e.g. `TEXT_DELIVERED`, `TEXT_UNREACHABLE`. Matched against
    `AWS_FAILED_EVENT_TYPES` to decide whether it is a failure, & logged to Appsignal.
  - `messageStatus` (e.g. `UNREACHABLE`) / `messageStatusDescription` (e.g. "Phone is
    currently unreachable/unavailable"). Description logged to Appsignal.
  - FYI `eventType` and `messageStatus` are two names for the same outcome: `eventType` is
    `messageStatus` with a `TEXT_` prefix (`TEXT_UNREACHABLE` / `UNREACHABLE`,
    `TEXT_TTL_EXPIRED` / `TTL_EXPIRED`, `TEXT_UNKNOWN` / `UNKNOWN`). App matches on `eventType`,
    the CloudWatch queries happen to filter on `messageStatus`.
  - `messageId` - what we store on `User` as `message_sid`, used to find the message to update its
    status. It's set once when `send_text_message` accepts the message and is the same on every event
    for that send. Note that a retry is a new send attempt, so it gets a new `messageId`.

- **The SNS subscription** is handled in `MessagesController` (skips admin auth & CSRF for
  `aws_status`):
  - `verify_sns_request` runs first, checking the SNS signature (`Aws::SNS::MessageVerifier`).
    A bad signature or unparseable body is reported to Appsignal and answered with `403`.
  - `handle_sns_subscription` checks the envelope `Type`, if it's `SubscriptionConfirmation` it just
    logs a warning with the topic and `SubscribeURL`, then returns `200`. (The subscription isn't
    confirmed in code, needs manual visit that URL (see logs) once for SNS to start delivering events.)
    Any other type is ignored.

- **Delivery succeeds** (`TEXT_DELIVERED`)
  - The event is ignored. The message stays `sent`, so the app can't currently tell a delivered
    message from one still in flight.

- **Delivery fails** (an `eventType` in `AWS_FAILED_EVENT_TYPES`, e.g. `TEXT_UNREACHABLE`)
  - Error details are logged to Appsignal (tags `aws_event_type`, `aws_message_id`,
    `aws_status_description`) and `UpdateMessageStatusJob` sets the message status to `failed`.

- **Every other event type** is ignored.

### Outcomes

| Stage | Outcome | `message.status` | Where it is visible |
|---|---|---|---|
| 1 AWS acceptance | Success | `sent` | `message_sid` saved |
| 1 AWS acceptance | `ServiceError` | `failed` | Appsignal |
| 2 AWS Delivery | `TEXT_DELIVERED` | stays `sent` | CloudWatch only |
| 2 AWS Delivery | Failed event type | `failed` | Appsignal, CloudWatch |

## Config

- `Sms::Client::BATCH_SIZE` - 7, 1 batch per second. AWS limits to 10 sends per second.
  - To investigate: can jobs bunch in the queues, so more than 7 are claimed and executed within
    1 second? Likewise the AWS throttle settings.
- `time_to_live` - not passed in `send_text_message`, so AWS uses its default of 72 hours.
  A TTL failure would therefore never be retried, because it wouldn't meet the
  `created_at < 1.hour.ago` condition.

## Retry logic

- An hourly `RetryFailedMessagesJob` re-sends messages where status is `failed` &&
  `created_at < 1.hour.ago`.
- The retry cap is implicit, from those conditions (not any explicit attempt counter for example).
- A retry reuses the same `Message` row and goes through stage 1 again:
  - If the AWS `send_text_message` call succeeds then message status returns to `sent` and `message_sid`
    is overwritten with the new AWS send attempt `message_id`.
    - then to stage 2. Note that if a delivery failure then reports to `aws_status` message's state
      will get set to `failed` but created_at never changes so it will not get picked up by next
      hourly retry job.
  - If the AWS `send_text_message` call fails with a `ServiceError`, the status remains as `failed`
    and `message_sid` is unchanged. The `created_at` would not change and thus the message would not
    get picked up on the next hourly retry job run.
- Because `RetryFailedMessages` job runs hourly, with a message filter of `created_at` < 1.hour.ago,
  failed messages are only retried once (unless created exactly on the hour, then two runs may catch it).

### Retry 'exceptions'

- **>= 2 error reports** (a hypothetical) If an `aws_status` failure call were received after the message
  was already set to `failed` and an hour had elapsed between its creation, a retry job would have been
  done on it and its `message_sid` would have changed, ∴ the later `aws_status` call would not find the
  message from the `messageId`, aka our `message_sid`, that it were carrying.
  (Carriers' event reporting to to AWS can take up to 72hours)
- **Timing misses:**
  - ✅ created_at 07:00:06 & failed (on send or aws_status callback) - retried 08:00 (~60 min wait). 
  - ✅ created_at 07:44 & failed (on send or aws_status callback) - retried 08:00 (16 min).
  - ❌ created_at 07:59:58, failure reported on callback at 08:00:05 - misses the retry run ∴ gets 0 retries.
- **Slow failures**
  - `TTL_EXPIRED` and late `UNKNOWN` arrive after the 72 hour TTL - never retried, status remains
    as `sent`.

## Failure data

### Failure Stats

All final events, 90 days to 14.10.26 (CloudWatch `cbeebies-sms-logs`, `ByAllStatus-90d`):

| Status | Events | Share |
|---|---|---|
| `DELIVERED` | 4,907 | 95.0% |
| `UNREACHABLE` | 173 | 3.3% |
| `TTL_EXPIRED` | 66 | 1.3% |
| `UNKNOWN` | 19 | 0.4% |
| **Total** | **5,165** | **100%** (258 failures, 5.0%) |

Of the failures:

| Status | Events | `messageStatusDescription` |
|---|---|---|
| `UNREACHABLE` | 173 (67%) | "Phone is currently unreachable/unavailable" |
| `TTL_EXPIRED` | 66 (26%) | "The delivery TTL has expired" |
| `UNKNOWN` | 19 (7%) | "Unknown error attempting to reach phone" |
| **Total** | **258** | across 77 numbers |

- 17 of those numbers have 3+ failures and account for 183 of the 258 events (71%).
- 9 numbers had more than one status type. 45 numbers failed once and 15 twice.
- **Failures are concentrated.** 17 numbers with 3+ events account for 183 of 258 events (71%). The
  top 3 numbers account for 74 and the top 10 for 151 (59%). The highest number alone has 26 events.
- **`UNREACHABLE` is concentrated, `TTL_EXPIRED` is spread.** 11 numbers with 3+ `UNREACHABLE` events
  account for 150 of 173. `TTL_EXPIRED` is spread over 44 numbers, 34 of them once only (max 9).
- Pausing/killing the 11 repeat `UNREACHABLE` numbers would remove up to 150 of the 258 failure
  events (58%).

### Future extrapolation

Future example of 50k users with 70% completing 52 weeks of messages:
- 1.82m SMS send attempts
- 1.23m are DELIVERED
- 91k are of some FAILURE type
  - 58% of those 91k failures, 52.8k, could be eliminated by:
    - detecting persistant UNREACHABLES and stopping service delivery to them

## Reference docs
- See repo issue [#520](https://github.com/nestauk/afs_tiny_happy_people_messaging/issues/520) for enhancement work on these mechanisms.
- [AWS event format](https://docs.aws.amazon.com/sms-voice/latest/userguide/configuration-sets-event-format.html)
- [SendTextMessage](https://docs.aws.amazon.com/pinpoint/latest/apireference_smsvoicev2/API_SendTextMessage.html)
