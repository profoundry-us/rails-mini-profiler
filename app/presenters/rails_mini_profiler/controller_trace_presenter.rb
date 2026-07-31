# frozen_string_literal: true

module RailsMiniProfiler
  class ControllerTracePresenter < TracePresenter
    def controller
      payload['controller']
    end

    def action
      payload['action']
    end

    def view_runtime
      payload['view_runtime']
    end

    def db_runtime
      payload['db_runtime']
    end

    def status
      payload['status']
    end

    def format
      payload['format']
    end

    def request_params
      payload['params'] || {}
    end

    def label
      controller ? "#{controller}##{action}" : 'Action Controller'
    end

    def content
      content_tag('div') do
        content_tag('pre', class: 'trace-payload') do
          content_tag(:div, details_line, class: 'sequel-trace-query')
        end + params_content
      end
    end

    private

    def details_line
      parts = []
      parts << "Status: #{status}" if status
      parts << "Format: #{format}" if format
      parts << "View Time: #{view_runtime} ms" if view_runtime
      parts << "DB Time: #{db_runtime} ms" if db_runtime
      parts.join(', ')
    end

    def params_content
      return nil if request_params.empty?

      lines = request_params.map { |key, value| "#{key}: #{value.inspect}" }
      content_tag(:pre, "Params\n#{lines.join("\n")}", class: 'trace-query-stats')
    end
  end
end
