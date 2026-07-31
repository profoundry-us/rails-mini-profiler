# frozen_string_literal: true

require 'rails_helper'
require 'ostruct'

module RailsMiniProfiler
  RSpec.describe TraceTree do
    # Minimal stand-in for a trace/presenter: responds to start, finish, name, label, duration, allocations.
    def trace(**attrs)
      defaults = { name: 'event', label: 'label', start: 0, finish: 0, duration: 0, allocations: 0 }
      OpenStruct.new(defaults.merge(attrs))
    end

    describe '.build' do
      it 'nests traces by time-interval containment' do
        action = trace(name: 'process_action.action_controller', label: 'Action', start: 0, finish: 100)
        template = trace(name: 'render_template.action_view', label: 'index', start: 10, finish: 90)
        sql = trace(name: 'sql.active_record', label: 'User Load', start: 20, finish: 30)

        roots = described_class.build([sql, template, action])

        expect(roots.map { |n| n.trace.label }).to eq(['Action'])
        expect(roots.first.children.map { |n| n.trace.label }).to eq(%w[index])
        expect(roots.first.children.first.children.map { |n| n.trace.label }).to eq(['User Load'])
      end

      it 'treats events sharing an identical (coarse) interval as siblings, not a chain' do
        # start/finish are stored coarser than duration, so quick siblings collide on the same interval.
        template = trace(name: 'render_template.action_view', label: 'index', start: 10, finish: 20)
        a = trace(name: 'render_partial.action_view', label: '_a', start: 15, finish: 15)
        b = trace(name: 'render_partial.action_view', label: '_b', start: 15, finish: 15)

        roots = described_class.build([template, a, b])

        children = roots.first.children
        expect(children.map { |n| n.trace.label }).to contain_exactly('_a', '_b')
        expect(children.map(&:children)).to all(be_empty)
      end

      it 'promotes a trace to a root when its parent is absent (e.g. filtered out)' do
        template = trace(name: 'render_template.action_view', label: 'index', start: 10, finish: 90)
        sql = trace(name: 'sql.active_record', label: 'User Load', start: 20, finish: 30)

        roots = described_class.build([template, sql])

        expect(roots.map { |n| n.trace.label }).to eq(%w[index])
        expect(roots.first.children.map { |n| n.trace.label }).to eq(['User Load'])
      end

      it 'groups repeated same-signature siblings into a single group node' do
        parent = trace(name: 'render_template.action_view', label: 'index', start: 0, finish: 100)
        rows = Array.new(3) do |i|
          trace(name: 'render_partial.action_view', label: '_row', start: 10 + (i * 10), finish: 15 + (i * 10),
                duration: 5, allocations: 100)
        end

        roots = described_class.build([parent, *rows])

        children = roots.first.children
        expect(children.size).to eq(1)
        group = children.first
        expect(group).to be_group
        expect(group.count).to eq(3)
        expect(group.total_duration).to eq(15)
        expect(group.total_allocations).to eq(300)
      end

      it 'computes self duration as own duration minus instrumented children' do
        action = trace(name: 'process_action.action_controller', label: 'Action', start: 0, finish: 100,
                       duration: 100)
        sql = trace(name: 'sql.active_record', label: 'User Load', start: 20, finish: 30, duration: 10)
        template = trace(name: 'render_template.action_view', label: 'index', start: 40, finish: 70, duration: 30)

        roots = described_class.build([action, sql, template])

        expect(roots.first.self_duration).to eq(60)
      end

      it 'reports zero self duration for groups and clamps negative values' do
        parent = trace(name: 'render_template.action_view', label: 'index', start: 0, finish: 100, duration: 10)
        rows = Array.new(2) do |i|
          trace(name: 'render_partial.action_view', label: '_row', start: 10 + i, finish: 90 - i, duration: 20)
        end

        roots = described_class.build([parent, *rows])

        expect(roots.first.self_duration).to eq(0)
        expect(roots.first.children.first.self_duration).to eq(0)
      end

      it 'spans a group from its first member start to its last member finish' do
        parent = trace(name: 'render_template.action_view', label: 'index', start: 0, finish: 100)
        rows = Array.new(3) do |i|
          trace(name: 'render_partial.action_view', label: '_row', start: 10 + (i * 20), finish: 15 + (i * 20))
        end

        group = described_class.build([parent, *rows]).first.children.first
        expect(group.span_start).to eq(10)
        expect(group.span_finish).to eq(55)
      end

      it 'reports min, avg and max durations across a group' do
        parent = trace(name: 'render_template.action_view', label: 'index', start: 0, finish: 100)
        durations = [10, 20, 60]
        rows = durations.each_with_index.map do |duration, i|
          trace(name: 'render_partial.action_view', label: '_row', start: 10 + (i * 20), finish: 15 + (i * 20),
                duration: duration)
        end

        group = described_class.build([parent, *rows]).first.children.first
        expect(group.min_duration).to eq(10)
        expect(group.avg_duration).to eq(30)
        expect(group.max_duration).to eq(60)
      end

      it 'does not group when siblings are below the threshold' do
        parent = trace(name: 'render_template.action_view', label: 'index', start: 0, finish: 100)
        row = trace(name: 'render_partial.action_view', label: '_row', start: 10, finish: 20)

        roots = described_class.build([parent, row])

        expect(roots.first.children.first).not_to be_group
        expect(roots.first.children.first.count).to eq(1)
      end
    end
  end
end
