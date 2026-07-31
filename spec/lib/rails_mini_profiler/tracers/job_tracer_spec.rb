# frozen_string_literal: true

require 'rails_helper'
require 'ostruct'

module RailsMiniProfiler
  module Tracers
    RSpec.describe JobTracer do
      describe 'trace' do
        let(:job) { MovieSweepJob.new }
        let(:payload) { { job: job, adapter: OpenStruct.new } }
        let(:event) { OpenStruct.new(name: 'enqueue.active_job', payload: payload) }

        subject { JobTracer.new(event) }

        it('replaces the job instance with serializable attributes') do
          trace = subject.trace
          expect(trace.payload).to eq(job: 'MovieSweepJob', queue: 'default')
        end

        context('with a scheduled job') do
          let(:job) do
            MovieSweepJob.new.tap { |j| j.scheduled_at = Time.utc(2026, 7, 30, 12) }
          end

          it('includes the scheduled time') do
            expect(subject.trace.payload[:scheduled_at]).to eq(Time.utc(2026, 7, 30, 12).to_s)
          end
        end
      end
    end
  end
end
