# frozen_string_literal: true

# A no-op job so requests exercise Active Job enqueue instrumentation.
class MovieSweepJob < ApplicationJob
  queue_as :default

  def perform; end
end
