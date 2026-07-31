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

    def content
      return if identifier.blank?

      content_tag('div') do
        content_tag('pre', class: 'trace-payload') do
          content_tag(:div, identifier, class: 'trace-source-path')
        end
      end
    end
  end
end
