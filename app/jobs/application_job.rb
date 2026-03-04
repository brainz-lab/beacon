class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  # Use Solid Queue as the backend
  queue_as :default

  rescue_from(StandardError) do |exception|
    BrainzLab::Reflex.capture(exception, context: { job: self.class.name, arguments: arguments })
    BrainzLab::Recall.error("Job failed: #{self.class.name}", error: exception.message)
    BrainzLab::Signal.trigger("job.failure", severity: :high, details: { job: self.class.name, error: exception.message })
    raise exception
  end

  # Log job execution
  around_perform do |job, block|
    Rails.logger.info "[#{job.class.name}] Starting with args: #{job.arguments.inspect}"
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    block.call

    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time
    Rails.logger.info "[#{job.class.name}] Completed in #{elapsed.round(2)}s"
  rescue => e
    Rails.logger.error "[#{job.class.name}] Failed: #{e.message}"
    raise
  end
end
