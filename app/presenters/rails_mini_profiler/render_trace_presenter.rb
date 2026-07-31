# frozen_string_literal: true

module RailsMiniProfiler
  # Shared behavior for view-render traces (templates, partials, collections, layouts): a compact label built
  # from the template path, and popover content showing the full identifier.
  class RenderTracePresenter < TracePresenter
    def identifier
      payload['identifier'].to_s
    end

    # The identifier relative to the app (or engine) root — e.g. "app/views/movies/index.html.erb".
    def relative_identifier
      path = identifier
      [Rails.root.to_s, RailsMiniProfiler::Engine.root.to_s].each do |root|
        return path.delete_prefix("#{root}/") if path.start_with?("#{root}/")
      end
      path
    end

    # Keep the tail of the path — the file name is the informative part.
    def label
      relative_identifier.reverse.truncate(40).reverse
    end

    def description
      "Render #{label}"
    end

    def content
      content_tag('div') do
        content_tag('pre', class: 'trace-payload') do
          content_tag(:div, identifier, class: 'trace-source-path')
        end
      end
    end
  end
end
