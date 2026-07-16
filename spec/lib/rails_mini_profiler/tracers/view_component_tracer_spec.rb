# frozen_string_literal: true

require 'rails_helper'
require 'ostruct'

module RailsMiniProfiler
  module Tracers
    RSpec.describe ViewComponentTracer do
      describe 'trace' do
        let(:payload) do
          { name: 'Common::CardComponent', identifier: '/app/components/common/card_component.rb', ignore: 100 }
        end
        let(:event) { OpenStruct.new(payload: payload) }

        subject { ViewComponentTracer.new(event) }

        it('keeps only the name and identifier payload fields') do
          trace = subject.trace
          expected = { name: 'Common::CardComponent', identifier: '/app/components/common/card_component.rb' }
          expect(trace.payload).to eq(expected)
        end

        it('subscribes to the modern render.view_component event') do
          expect(described_class.subscribes_to).to eq('render.view_component')
        end
      end
    end
  end
end
