# frozen_string_literal: true

module RailsMiniProfiler
  class JobTracePresenter < TracePresenter
    def job
      payload['job']
    end

    def queue
      payload['queue']
    end

    def scheduled_at
      payload['scheduled_at']
    end

    def label
      "Enqueue #{job}"
    end

    def description
      text = "Enqueued #{job} on queue #{queue}"
      scheduled_at ? "#{text} for #{scheduled_at}" : text
    end
  end
end
