# frozen_string_literal: true

require 'rails_helper'

module RailsMiniProfiler
  module Tracers
    RSpec.describe Tracer do
      describe 'trace' do
        subject do
          ActiveSupport::Notifications.subscribe('wait') do |*args|
            @event = ActiveSupport::Notifications::Event.new(*args)
          end

          ActiveSupport::Notifications.instrument('wait') do
            sleep 0.001
          end

          Tracer.new(@event)
        end

        it('stores duration in hundredths of a millisecond') do
          expect(subject.trace.duration).to be_within(5).of(@event.duration * 100)
        end

        it('stores start and finish in hundredths of a millisecond') do
          expect(subject.trace.start).to be_within(5).of(@event.time.to_f * Tracer::TIMESTAMP_MULTIPLIER)
          expect(subject.trace.finish).to be_within(5).of(@event.end.to_f * Tracer::TIMESTAMP_MULTIPLIER)
        end

        it('stores timestamps and duration in the same unit') do
          trace = subject.trace
          expect(trace.finish - trace.start).to be_within(10).of(trace.duration)
        end

        it('captures a backtrace by default') do
          allow(Rails.backtrace_cleaner).to receive(:clean).and_return(['app/foo.rb:1'])
          expect(subject.trace.backtrace).to eq(['app/foo.rb:1'])
        end

        context('when backtraces are disabled') do
          before { RailsMiniProfiler.configuration.backtraces_enabled = false }
          after { RailsMiniProfiler.configuration.backtraces_enabled = true }

          it('skips backtrace capture entirely and returns an empty array') do
            expect(Rails.backtrace_cleaner).not_to receive(:clean)
            expect(subject.trace.backtrace).to eq([])
          end
        end
      end
    end
  end
end
