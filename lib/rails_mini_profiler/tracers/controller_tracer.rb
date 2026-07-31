# frozen_string_literal: true

module RailsMiniProfiler
  module Tracers
    class ControllerTracer < Tracer
      class << self
        def subscribes_to
          'process_action.action_controller'
        end

        def build_from(event)
          new(event).trace
        end

        def presents
          ControllerTracePresenter
        end
      end

      def trace
        payload = @event[:payload]
        @event[:payload] = {
          controller: payload[:controller],
          action: payload[:action],
          format: payload[:format].to_s.presence,
          method: payload[:method],
          status: payload[:status],
          params: serializable_params(payload[:params]),
          view_runtime: runtime(payload[:view_runtime]),
          db_runtime: runtime(payload[:db_runtime])
        }.compact
        super
      end

      private

      def runtime(value)
        value.round(2) if value.respond_to?(:round)
      end

      # The payload params are already filtered (config.filter_parameters), but can still contain
      # non-JSON-serializable values such as uploaded files — stringify anything that isn't a basic type,
      # and drop the routing keys that are shown separately.
      def serializable_params(params)
        return nil unless params.respond_to?(:except)

        params
          .except('controller', 'action')
          .deep_transform_values { |v| v.is_a?(String) || v.is_a?(Numeric) || v.in?([true, false, nil]) ? v : v.to_s }
          .presence
      end
    end
  end
end
