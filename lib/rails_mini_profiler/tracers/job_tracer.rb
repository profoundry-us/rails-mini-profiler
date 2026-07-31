# frozen_string_literal: true

module RailsMiniProfiler
  module Tracers
    # Traces Active Job enqueues happening during a request (`SomethingJob.perform_later`).
    #
    # Only the enqueue is part of the request; the job itself runs elsewhere (another thread or process), so
    # `perform.active_job` is deliberately not subscribed — its traces could never attach to this request's
    # thread-local collection.
    class JobTracer < Tracer
      EVENTS = %w[
        enqueue.active_job
        enqueue_at.active_job
      ].freeze

      class << self
        def subscribes_to
          EVENTS
        end

        def presents
          EVENTS.index_with { JobTracePresenter }
        end
      end

      def trace
        job = @event[:payload][:job]
        # The payload carries the ActiveJob instance itself, which is not JSON-serializable — keep only
        # compact, meaningful attributes.
        @event[:payload] = {
          job: job&.class&.name,
          queue: job&.queue_name,
          scheduled_at: job&.scheduled_at&.to_s
        }.compact
        super
      end
    end
  end
end
