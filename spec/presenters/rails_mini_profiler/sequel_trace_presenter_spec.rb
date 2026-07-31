# frozen_string_literal: true

require 'rails_helper'

module RailsMiniProfiler
  RSpec.describe SequelTracePresenter, type: :model do
    let(:view_context) { ProfiledRequestsController.new.view_context }
    let(:sql) { 'SELECT * FROM movies WHERE id = ?' }
    let(:payload) { { 'name' => 'Movie Load', 'sql' => sql, 'row_count' => 3 } }
    let(:sql_occurrences) { {} }
    let(:context) do
      { start: 0, finish: 0, total_duration: 0, total_allocations: 0, sql_occurrences: sql_occurrences }
    end
    let(:trace) { Trace.new(name: 'sql.active_record', payload: payload) }
    subject { described_class.new(trace, view_context, context: context) }

    describe 'content' do
      it 'shows the row count' do
        expect(subject.content).to include('3 rows')
      end

      context 'with a repeated query' do
        let(:sql_occurrences) { { sql => { count: 14, total_duration: 3800 } } }

        it 'flags a possible n+1' do
          expect(subject.content).to include('ran 14× in this request')
          expect(subject.content).to include('possible n+1')
        end
      end

      context 'with a single occurrence' do
        let(:sql_occurrences) { { sql => { count: 1, total_duration: 100 } } }

        it 'does not flag anything' do
          expect(subject.content).not_to include('n+1')
        end
      end
    end
  end
end
