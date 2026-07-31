# frozen_string_literal: true

module RailsMiniProfiler
  module Tracers
    class Tracer
      TIMESTAMP_MULTIPLIER = 100_000

      class << self
        def subscribes_to
          []
        end

        def presents
          TracePresenter
        end

        def build_from(event)
          new(event).trace
        end
      end

      def initialize(event)
        @event = event_data(event)
      end

      def trace
        Trace.new(**@event)
      end

      private

      def event_data(event)
        # Everything is stored in hundredths of a millisecond, as integers — easier to store and process than
        # floats. `event.time`/`event.end` are monotonic clock floats in seconds, so they are scaled by
        # TIMESTAMP_MULTIPLIER (100,000); `event.duration` is float milliseconds, so it is scaled by 100. Using
        # the same unit for timestamps and durations matters: the trace tree reconstructs nesting from interval
        # containment, and coarser timestamps make quick sibling events indistinguishable.
        #
        # See https://github.com/rails/rails/commit/81d0dc90becfe0b8e7f7f26beb66c25d84b8ec7f
        start_time = (event.time.to_f * TIMESTAMP_MULTIPLIER).to_i
        finish_time = (event.end.to_f * TIMESTAMP_MULTIPLIER).to_i
        {
          name: event.name,
          start: start_time,
          finish: finish_time,
          duration: (event.duration.to_f * 100).to_i,
          allocations: event.allocations,
          backtrace: capture_backtrace,
          payload: event.payload
        }
      end

      # Capturing a backtrace for every trace is expensive (Kernel#caller plus the backtrace cleaner's
      # silencers) and dominates on high-volume pages, skewing the very timings we report. Skip it entirely
      # when disabled — returning an empty array keeps the trace detail view (which does `backtrace.empty?`)
      # happy while avoiding the `caller` call altogether.
      def capture_backtrace
        return [] unless RailsMiniProfiler.configuration.backtraces_enabled

        Rails.backtrace_cleaner.clean(caller)
      end
    end
  end
end
