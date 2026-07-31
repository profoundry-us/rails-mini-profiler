# frozen_string_literal: true

module RailsMiniProfiler
  class RenderCollectionTracePresenter < RenderTracePresenter
    def count
      payload['count']
    end

    def cache_hits
      payload['cache_hits']
    end

    def label
      "#{super} ×#{count}"
    end

    def description
      text = "Rendered #{count} × #{relative_identifier.reverse.truncate(40).reverse}"
      cache_hits ? "#{text} (#{cache_hits} cache hits)" : text
    end
  end
end
