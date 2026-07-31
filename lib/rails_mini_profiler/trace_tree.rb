# frozen_string_literal: true

module RailsMiniProfiler
  # Builds a hierarchical view of traces out of the flat event list.
  #
  # Rails Mini Profiler records individual ActiveSupport::Notifications events, each with a start and finish
  # timestamp but no explicit parent. We reconstruct the call tree purely from time-interval containment:
  # an event B is nested under event A when A starts no later than B and finishes no earlier than B. Repeated
  # sibling events that share a signature (same event name + label — e.g. the same partial rendered many times)
  # are collapsed into a single group node so the tree stays readable.
  #
  # The input is any list of objects responding to +start+, +finish+, +name+ and +label+ (trace presenters do).
  #
  # @api private
  class TraceTree
    # A node in the tree. Wraps a single trace, or — when +members+ is set — represents a group of sibling
    # traces that share a signature.
    class Node
      attr_reader :trace, :members
      attr_accessor :children

      def initialize(trace:, children: [], members: nil)
        @trace = trace
        @children = children
        @members = members
      end

      def group?
        !@members.nil?
      end

      # Number of underlying traces this node represents (>1 only for groups).
      def count
        group? ? @members.size : 1
      end

      # Total self-duration (raw, hundredths of a millisecond) across the traces this node represents.
      def total_duration
        traces.sum { |t| raw(t, :duration) }
      end

      # Total allocations across the traces this node represents.
      def total_allocations
        traces.sum { |t| raw(t, :allocations) }
      end

      # The traces represented by this node (the members for a group, otherwise just the one trace).
      def traces
        group? ? @members.map(&:trace) : [@trace]
      end

      # Time spent in this node itself, outside any instrumented child event — i.e. work no tracer captured
      # (the controller's own code, framework internals, and so on). Zero for groups: a group's rendered
      # children are its own members, which sum to its total by definition.
      def self_duration
        return 0 if group?

        [raw(@trace, :duration) - children.sum(&:total_duration), 0].max
      end

      # Earliest start and latest finish across the traces this node represents. For a single trace these are
      # just its own timestamps; for a group they describe the window its scattered members span.
      def span_start
        traces.map { |t| raw(t, :start) }.min
      end

      def span_finish
        traces.map { |t| raw(t, :finish) }.max
      end

      private

      # Read a raw numeric attribute. Trace presenters format their +duration+/+allocations+ for display, so
      # reach through to the underlying model for the raw value; plain objects are read directly.
      def raw(trace, attribute)
        source = trace.respond_to?(:model) ? trace.model : trace
        source.public_send(attribute).to_i
      end
    end

    def self.build(traces, group_threshold: 2)
      new(traces, group_threshold: group_threshold).build
    end

    def initialize(traces, group_threshold: 2)
      @traces = traces
      @group_threshold = group_threshold
    end

    # @return [Array<Node>] the root nodes of the tree
    def build
      group(nest(@traces))
    end

    private

    # Nest traces by interval containment using a stack. Traces whose parent is absent (filtered out, or a
    # genuine root) become top-level nodes.
    def nest(traces)
      sorted = traces.sort_by { |t| [t.start.to_i, -t.finish.to_i] }
      roots = []
      stack = []
      sorted.each do |trace|
        node = Node.new(trace: trace)
        stack.pop while stack.any? && !contains?(stack.last.trace, trace)
        (stack.last&.children || roots) << node
        stack.push(node)
      end
      roots
    end

    # True when +parent+'s interval strictly encloses +child+'s. Rails Mini Profiler stores start/finish at a
    # coarser resolution than duration, so many quick sibling events share an identical [start, finish]. Requiring
    # a strict enclosure (not an identical interval) keeps those as siblings — attached to their nearest genuinely
    # larger ancestor — instead of chaining them into each other.
    def contains?(parent, child)
      parent.start.to_i <= child.start.to_i &&
        child.finish.to_i <= parent.finish.to_i &&
        (parent.start.to_i < child.start.to_i || child.finish.to_i < parent.finish.to_i)
    end

    # Collapse same-signature siblings into group nodes, depth-first. Children are grouped before their parents
    # so a group's members keep their (already grouped) subtrees.
    def group(nodes)
      nodes.each { |node| node.children = group(node.children) }
      collapse_repeated_siblings(nodes)
    end

    # Replace runs of same-signature siblings (>= threshold) with a single group node, keeping the position of
    # the first occurrence. Siblings below the threshold pass through unchanged.
    def collapse_repeated_siblings(nodes)
      buckets = nodes.group_by { |node| signature(node.trace) }
      emitted = {}
      nodes.each_with_object([]) do |node, result|
        signature = signature(node.trace)
        members = buckets[signature]
        if members.size < @group_threshold
          result << node
        elsif !emitted[signature]
          emitted[signature] = true
          result << Node.new(trace: node.trace, members: members)
        end
      end
    end

    def signature(trace)
      [trace.name, trace.label]
    end
  end
end
