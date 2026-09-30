module EnqueuesJobsInBatches
  extend ActiveSupport::Concern

  private

  # Stagger enqueued jobs so message-sending jobs execute in batches spread a
  # second apart, keeping SMS sends under our AWS Pinpoint account's rate limit.
  def enqueue_in_batches(jobs)
    return if jobs.empty?

    jobs.each_slice(Sms::Client::BATCH_SIZE).with_index do |batch, index|
      next if index.zero? # first batch sends immediately, same as before batching existed

      batch.each { |job| job.set(wait: index.seconds) }
    end

    ActiveJob.perform_all_later(jobs)
  end
end
