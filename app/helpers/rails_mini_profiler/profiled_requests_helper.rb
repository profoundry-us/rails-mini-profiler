# frozen_string_literal: true

module RailsMiniProfiler
  module ProfiledRequestsHelper
    include ApplicationHelper

    def formatted_duration(duration)
      duration = (duration.to_f / 100)
      duration < 1 ? duration : duration.round
    end

    def formatted_allocations(allocations)
      number_to_human(allocations, units: { unit: '', thousand: 'k', million: 'M', billion: 'B', trillion: 'T' })
    end

    TRACE_DISPLAY_NAMES = {
      'sql.active_record' => 'ActiveRecord Query',
      'instantiation.active_record' => 'ActiveRecord Instantiation',
      'render_template.action_view' => 'Render View',
      'render_partial.action_view' => 'Render Partial',
      'render_collection.action_view' => 'Render Collection',
      'render_layout.action_view' => 'Render Layout',
      'render.view_component' => 'View Component',
      'process_action.action_controller' => 'Controller',
      'cache_read.active_support' => 'Cache Read',
      'cache_read_multi.active_support' => 'Cache Read Multi',
      'cache_write.active_support' => 'Cache Write',
      'cache_write_multi.active_support' => 'Cache Write Multi',
      'cache_fetch_hit.active_support' => 'Cache Hit',
      'cache_generate.active_support' => 'Cache Generate',
      'cache_delete.active_support' => 'Cache Delete',
      'enqueue.active_job' => 'Enqueue Job',
      'enqueue_at.active_job' => 'Schedule Job'
    }.freeze

    def trace_display_name(name)
      TRACE_DISPLAY_NAMES.fetch(name.to_s, name.to_s)
    end
  end
end
