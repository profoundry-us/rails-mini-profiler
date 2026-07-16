# frozen_string_literal: true

module RailsMiniProfiler
  module Tracers
    # Traces ViewComponent renders (the `render.view_component` notification).
    #
    # ViewComponent instrumentation is off by default in the host app, so this tracer only produces traces
    # once the host enables it:
    #
    #   config.view_component.instrumentation_enabled = true
    #   # ViewComponent 3.x also emits the modern event name only when:
    #   config.view_component.use_deprecated_instrumentation_name = false
    #
    # Rails Mini Profiler can't turn this on for the host app; without it the subscription is simply idle.
    class ViewComponentTracer < Tracer
      class << self
        def subscribes_to
          'render.view_component'
        end

        def presents
          ViewComponentTracePresenter
        end
      end

      def trace
        @event[:payload].slice!(:name, :identifier)
        super
      end
    end
  end
end
