# frozen_string_literal: true

module RailsMiniProfiler
  class ViewComponentTracePresenter < TracePresenter
    def label
      component_name.sub(/__Build\d+\z/, '')
    end

    def component_name
      payload['name'] || 'View Component'
    end

    def identifier
      payload['identifier']
    end

    def description
      "Rendered #{label}"
    end
  end
end
