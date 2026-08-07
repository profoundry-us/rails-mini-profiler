# frozen_string_literal: true

module RailsMiniProfiler
  # Captures the arguments a ViewComponent was constructed with, so the trace popover can show *which*
  # component instance rendered (e.g. `icon: "cog", css: "size-5"`), not just its class.
  #
  # ViewComponent's own `render.view_component` notification carries only the class name and identifier, so
  # this module hooks ViewComponent::Base (via the engine's :view_component load hook):
  #
  # - A prepend on the class-side +new+ records a compact, JSON-safe snapshot of the constructor arguments
  #   on the instance. It must be `.new`, not `#initialize`: subclasses define their own initialize and call
  #   `super()` with no arguments, so a Base-level initialize never sees the real kwargs.
  # - A prepend on +render_in+ pushes that snapshot onto a thread-local stack around the render, which is
  #   exactly when ViewComponent's notification fires — ViewComponentTracer reads the top of the stack to
  #   enrich its trace. A stack (not a single slot) keeps nested component renders matched to the right event.
  #
  # Capture can be turned off with `config.view_component_props_enabled = false`.
  module ViewComponentProps
    THREAD_KEY = :rmp_view_component_props

    # Prepended to ViewComponent::Base's singleton class so every subclass's construction passes through it.
    module Construction
      def new(*args, **kwargs, &)
        instance = super
        if RailsMiniProfiler.configuration.view_component_props_enabled
          instance.instance_variable_set(:@__rmp_props, ViewComponentProps.serialize(args, kwargs))
        end
        instance
      end
    end

    class << self
      def install(component_class)
        component_class.singleton_class.prepend(Construction)
        component_class.prepend(self)
      end

      def current
        stack.last
      end

      def stack
        Thread.current[THREAD_KEY] ||= []
      end

      def serialize(args, kwargs)
        props = {}
        props['args'] = args.map { |value| safe_value(value) } if args.any?
        kwargs.each { |key, value| props[key.to_s] = safe_value(value) }
        props
      end

      # Keep basic types as-is; everything else becomes a truncated inspect so models, procs and the like
      # stay readable without storing huge or non-serializable objects.
      def safe_value(value)
        case value
        when String, Numeric, true, false, nil then value
        when Symbol then value.inspect
        else value.inspect.truncate(120)
        end
      end
    end

    def render_in(...)
      return super unless RailsMiniProfiler.configuration.view_component_props_enabled

      ViewComponentProps.stack.push(@__rmp_props || {})
      begin
        super
      ensure
        ViewComponentProps.stack.pop
      end
    end
  end
end
