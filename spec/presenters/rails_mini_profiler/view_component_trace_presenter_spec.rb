# frozen_string_literal: true

require 'rails_helper'

module RailsMiniProfiler
  RSpec.describe ViewComponentTracePresenter, type: :model do
    let(:view_context) { ProfiledRequestsController.new.view_context }
    let(:context) { { start: 0, finish: 0, total_duration: 0, total_allocations: 0 } }
    subject { described_class.new(trace, view_context, context: context) }

    describe 'label' do
      context 'with a component name' do
        let(:trace) { Trace.new(payload: { 'name' => 'Common::CardComponent' }) }

        it 'is the component name' do
          expect(subject.label).to eq('Common::CardComponent')
        end
      end

      context 'with a dynamically-built component class' do
        let(:trace) { Trace.new(payload: { 'name' => 'BasicComponent__Build1' }) }

        it 'strips the __Build<n> suffix' do
          expect(subject.label).to eq('BasicComponent')
        end
      end

      context 'without a name' do
        let(:trace) { Trace.new(payload: {}) }

        it 'falls back to a generic label' do
          expect(subject.label).to eq('View Component')
        end
      end
    end

    describe 'type' do
      let(:trace) { Trace.new(payload: {}) }

      it 'is the view-component-trace css class' do
        expect(subject.type).to eq('view-component-trace')
      end
    end

    describe 'content' do
      let(:trace) do
        Trace.new(payload: { 'name' => 'BadgeComponent',
                             'identifier' => '/app/components/badge_component.rb',
                             'props' => { 'label' => 'recent', 'count' => 3 } })
      end

      it 'shows the captured props' do
        expect(subject.content).to include('label: &quot;recent&quot;')
        expect(subject.content).to include('count: 3')
        expect(subject.content).to include('/app/components/badge_component.rb')
      end
    end
  end
end
