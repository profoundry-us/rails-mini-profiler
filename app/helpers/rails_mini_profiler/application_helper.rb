# frozen_string_literal: true

module RailsMiniProfiler
  module ApplicationHelper
    def present(model, presenter_class = nil, **)
      klass = presenter_class || "#{model.class}Presenter".constantize
      presenter = klass.new(model, self, **)
      yield(presenter) if block_given?
      presenter
    end

    # Insert <wbr> line-break opportunities into long, unspaced identifiers (component/class names,
    # file paths) so they wrap at natural boundaries — `::` between namespaces, `/` and `_` in paths —
    # instead of overflowing their container. The text is HTML-escaped first, so this is injection-safe,
    # and <wbr> carries no text content, so copied/`innerText` values are unaffected.
    def break_opportunities(text)
      return if text.nil?

      ERB::Util.html_escape(text.to_s)
        .gsub(%r{::|[/_]}) { "#{Regexp.last_match(0)}<wbr>" }
        .html_safe
    end

    def icon(name, **kwargs)
      root = RailsMiniProfiler::Engine.root
      icon_path = File.read(root.join('app', 'assets', 'images', "#{name}.svg"))

      Nokogiri::HTML::DocumentFragment.parse(icon_path)
        .at_css('svg')
        .tap { _1['class'] = kwargs[:class] }
        .to_html
        .html_safe
    end
  end
end
