# frozen_string_literal: true

module RailsMiniProfiler
  module Tracers
    # Traces Rails.cache operations (ActiveSupport::Cache instrumentation).
    #
    # Every store instruments these events out of the box, so fragment caching, low-level Rails.cache calls,
    # and cache-backed gems all show up — cache stampedes and n+1 cache reads group naturally in the trace
    # tree like repeated partials do.
    class CacheTracer < Tracer
      EVENTS = %w[
        cache_read.active_support
        cache_read_multi.active_support
        cache_write.active_support
        cache_write_multi.active_support
        cache_fetch_hit.active_support
        cache_generate.active_support
        cache_delete.active_support
      ].freeze

      class << self
        def subscribes_to
          EVENTS
        end

        def presents
          EVENTS.index_with { CacheTracePresenter }
        end
      end

      def trace
        payload = @event[:payload]
        # Keys can be arrays/symbols and multi-operations carry hashes of key => value; keep a compact,
        # JSON-safe representation and drop everything else (values can be arbitrary objects).
        key = payload[:key]
        @event[:payload] = {
          key: key.is_a?(Hash) ? key.keys.map(&:to_s).join(', ') : key.to_s,
          hit: payload[:hit],
          super_operation: payload[:super_operation],
          store: payload[:store]
        }.compact
        super
      end
    end
  end
end
