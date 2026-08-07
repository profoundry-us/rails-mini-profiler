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

    def props
      payload['props'] || {}
    end

    def content
      return if identifier.blank? && props.empty?

      content_tag('div') do
        safe_join([source_content, props_content].compact)
      end
    end

    private

    def source_content
      return if identifier.blank?

      content_tag('pre', class: 'trace-payload') do
        content_tag(:div, identifier, class: 'trace-source-path')
      end
    end

    def props_content
      return if props.empty?

      lines = props.map { |key, value| "#{key}: #{value.is_a?(String) ? value.inspect : value}" }
      content_tag(:pre, "Props\n#{lines.join("\n")}", class: 'trace-query-stats')
    end
  end
end
