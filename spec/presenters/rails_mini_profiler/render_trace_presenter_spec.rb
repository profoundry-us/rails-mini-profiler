# frozen_string_literal: true

require 'rails_helper'

module RailsMiniProfiler
  RSpec.describe RenderTracePresenter, type: :model do
    let(:view_context) { ProfiledRequestsController.new.view_context }
    let(:context) { { start: 0, finish: 0, total_duration: 0, total_allocations: 0 } }
    let(:identifier) { Rails.root.join('app/views/movies/index.html.erb').to_s }
    let(:trace) { Trace.new(payload: { 'identifier' => identifier }) }
    subject { described_class.new(trace, view_context, context: context) }

    describe 'label' do
      it 'is the path relative to the app root, order preserved' do
        expect(subject.label).to eq('app/views/movies/index.html.erb')
      end

      context 'with a long path' do
        let(:identifier) { Rails.root.join('app/views/some/deeply/nested/namespace/_partial.html.erb').to_s }

        it 'keeps the tail of the path' do
          expect(subject.label).to end_with('namespace/_partial.html.erb')
          expect(subject.label.length).to be <= 40
        end
      end

      context 'with an engine path' do
        let(:identifier) { RailsMiniProfiler::Engine.root.join('app/views/shared/_head.erb').to_s }

        it 'is relative to the engine root' do
          expect(subject.label).to eq('app/views/shared/_head.erb')
        end
      end
    end

    describe 'content' do
      it 'includes the full identifier path' do
        expect(subject.content).to include(identifier)
        expect(subject.content).to include('trace-source-path')
      end
    end
  end
end
