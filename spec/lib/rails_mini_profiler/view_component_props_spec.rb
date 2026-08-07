# frozen_string_literal: true

require 'rails_helper'

module RailsMiniProfiler
  RSpec.describe ViewComponentProps do
    describe '.serialize' do
      it 'keeps basic keyword values as-is' do
        props = described_class.serialize([], { label: 'recent', count: 3, active: true, css: nil })
        expect(props).to eq('label' => 'recent', 'count' => 3, 'active' => true, 'css' => nil)
      end

      it 'inspects symbols and truncates complex objects' do
        big = Struct.new(:description).new('x' * 500)
        props = described_class.serialize([], { variant: :primary, movie: big })
        expect(props['variant']).to eq(':primary')
        expect(props['movie'].length).to be <= 120
      end

      it 'captures positional arguments' do
        props = described_class.serialize(['hello'], {})
        expect(props).to eq('args' => ['hello'])
      end
    end

    describe 'stack' do
      after { Thread.current[described_class::THREAD_KEY] = nil }

      it 'exposes the innermost render props via current' do
        described_class.stack.push({ 'icon' => 'cog' })
        described_class.stack.push({ 'icon' => 'check' })
        expect(described_class.current).to eq('icon' => 'check')
        described_class.stack.pop
        expect(described_class.current).to eq('icon' => 'cog')
      end
    end
  end
end
