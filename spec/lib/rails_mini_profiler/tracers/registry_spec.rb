# frozen_string_literal: true

require 'rails_helper'

module RailsMiniProfiler
  module Tracers
    RSpec.describe Registry do
      let(:configuration) { Configuration.new }

      subject { described_class.new(configuration) }

      let(:cache_events) do
        %w[
          cache_read.active_support
          cache_read_multi.active_support
          cache_write.active_support
          cache_write_multi.active_support
          cache_fetch_hit.active_support
          cache_generate.active_support
          cache_delete.active_support
        ]
      end

      describe 'tracers' do
        it('should return a name to tracer class mapping') do
          result = {
            'instantiation.active_record' => RailsMiniProfiler::Tracers::InstantiationTracer,
            'process_action.action_controller' => RailsMiniProfiler::Tracers::ControllerTracer,
            'render_partial.action_view' => RailsMiniProfiler::Tracers::ViewTracer,
            'render_collection.action_view' => RailsMiniProfiler::Tracers::ViewTracer,
            'render_layout.action_view' => RailsMiniProfiler::Tracers::ViewTracer,
            'render.view_component' => RailsMiniProfiler::Tracers::ViewComponentTracer,
            'rails_mini_profiler.total_time' => RailsMiniProfiler::Tracers::RmpTracer,
            'render_template.action_view' => RailsMiniProfiler::Tracers::ViewTracer,
            'sql.active_record' => RailsMiniProfiler::Tracers::SequelTracer,
            'enqueue.active_job' => RailsMiniProfiler::Tracers::JobTracer,
            'enqueue_at.active_job' => RailsMiniProfiler::Tracers::JobTracer
          }
          cache_events.each { |event| result[event] = RailsMiniProfiler::Tracers::CacheTracer }
          expect(subject.tracers).to eq(result)
        end
      end

      describe 'presenters' do
        it('should return a name to presenter class mapping') do
          result = {
            'instantiation.active_record' => RailsMiniProfiler::InstantiationTracePresenter,
            'process_action.action_controller' => RailsMiniProfiler::ControllerTracePresenter,
            'rails_mini_profiler.total_time' => RailsMiniProfiler::RmpTracePresenter,
            'render_partial.action_view' => RailsMiniProfiler::RenderPartialTracePresenter,
            'render_collection.action_view' => RailsMiniProfiler::RenderCollectionTracePresenter,
            'render_layout.action_view' => RailsMiniProfiler::RenderLayoutTracePresenter,
            'render_template.action_view' => RailsMiniProfiler::RenderTemplateTracePresenter,
            'render.view_component' => RailsMiniProfiler::ViewComponentTracePresenter,
            'sql.active_record' => RailsMiniProfiler::SequelTracePresenter,
            'enqueue.active_job' => RailsMiniProfiler::JobTracePresenter,
            'enqueue_at.active_job' => RailsMiniProfiler::JobTracePresenter
          }
          cache_events.each { |event| result[event] = RailsMiniProfiler::CacheTracePresenter }

          expect(subject.presenters).to eq(result)
        end
      end
    end
  end
end
