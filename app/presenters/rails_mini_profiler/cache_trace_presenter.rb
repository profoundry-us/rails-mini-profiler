# frozen_string_literal: true

module RailsMiniProfiler
  class CacheTracePresenter < TracePresenter
    OPERATIONS = {
      'cache_read.active_support' => 'Cache Read',
      'cache_read_multi.active_support' => 'Cache Read Multi',
      'cache_write.active_support' => 'Cache Write',
      'cache_write_multi.active_support' => 'Cache Write Multi',
      'cache_fetch_hit.active_support' => 'Cache Hit',
      'cache_generate.active_support' => 'Cache Generate',
      'cache_delete.active_support' => 'Cache Delete'
    }.freeze

    def key
      payload['key']
    end

    def hit
      payload['hit']
    end

    # Operation only — keeping the key out of the label lets repeated cache operations (n+1 reads of
    # different keys) group together in the trace tree.
    def label
      OPERATIONS.fetch(model.name, 'Cache')
    end

    def description
      "#{label}: #{key}"
    end

    def content
      details = [key]
      details << "hit: #{hit}" unless hit.nil?
      content_tag('div') do
        content_tag('pre', class: 'trace-payload') do
          content_tag(:div, details.join(' — '), class: 'trace-source-path')
        end
      end
    end
  end
end
