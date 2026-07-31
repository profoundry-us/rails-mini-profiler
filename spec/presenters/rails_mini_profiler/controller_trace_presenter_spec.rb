# frozen_string_literal: true

require 'rails_helper'

module RailsMiniProfiler
  RSpec.describe ControllerTracePresenter, type: :model do
    let(:view_context) { ProfiledRequestsController.new.view_context }
    let(:context) { { start: 0, finish: 0, total_duration: 0, total_allocations: 0 } }
    let(:payload) do
      { 'controller' => 'MoviesController', 'action' => 'index', 'status' => 200,
        'params' => { 'page' => '2' }, 'view_runtime' => 10.5 }
    end
    let(:trace) { Trace.new(name: 'process_action.action_controller', payload: payload) }
    subject { described_class.new(trace, view_context, context: context) }

    describe 'label' do
      it 'names the controller and action' do
        expect(subject.label).to eq('MoviesController#index')
      end

      context 'without controller details (older traces)' do
        let(:payload) { { 'view_runtime' => 10.5 } }

        it 'falls back to the generic label' do
          expect(subject.label).to eq('Action Controller')
        end
      end
    end

    describe 'content' do
      it 'shows status and params' do
        expect(subject.content).to include('Status: 200')
        expect(subject.content).to include('page: &quot;2&quot;')
      end
    end
  end
end
