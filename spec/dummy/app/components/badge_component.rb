# frozen_string_literal: true

# A small demo component so requests exercise the view_component tracer and props capture.
class BadgeComponent < ViewComponent::Base
  def initialize(label:, css: nil)
    super()
    @label = label
    @css = css
  end

  def call
    content_tag(:span, @label, class: ['badge', @css].compact.join(' '))
  end
end
