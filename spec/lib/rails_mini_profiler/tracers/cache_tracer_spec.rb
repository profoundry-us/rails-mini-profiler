# frozen_string_literal: true

require 'rails_helper'
require 'ostruct'

module RailsMiniProfiler
  module Tracers
    RSpec.describe CacheTracer do
      describe 'trace' do
        let(:payload) { { key: 'movies/count', store: 'ActiveSupport::Cache::MemoryStore', hit: true, ignore: 1 } }
        let(:event) { OpenStruct.new(name: 'cache_read.active_support', payload: payload) }

        subject { CacheTracer.new(event) }

        it('keeps a compact, serializable payload') do
          trace = subject.trace
          expected = { key: 'movies/count', hit: true, store: 'ActiveSupport::Cache::MemoryStore' }
          expect(trace.payload).to eq(expected)
        end

        context('with a non-string key') do
          let(:payload) { { key: [:movies, 5] } }

          it('stringifies the key') do
            expect(subject.trace.payload[:key]).to eq('[:movies, 5]')
          end
        end

        context('with a multi-operation hash key') do
          let(:payload) { { key: { 'a' => 1, 'b' => 2 } } }

          it('lists the keys') do
            expect(subject.trace.payload[:key]).to eq('a, b')
          end
        end

        it('subscribes to all cache events') do
          expect(described_class.subscribes_to).to all(match(/\Acache_.*\.active_support\z/))
        end
      end
    end
  end
end
