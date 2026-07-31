# frozen_string_literal: true

# Trace and profiled-request timestamps used to be stored at 10ms resolution (monotonic seconds * 100), while
# durations are stored in hundredths of a millisecond (milliseconds * 100). Timestamps are now recorded in
# hundredths of a millisecond too, so existing rows are scaled by 1000 to keep old and new data in the same
# unit. Timestamps come from the monotonic clock, so only differences within a request are meaningful — the
# scaling preserves exactly those.
class ScaleRmpTimestampsToMatchDuration < ActiveRecord::Migration[7.2]
  def up
    execute <<~SQL
      UPDATE rmp_profiled_requests SET start = start * 1000, finish = finish * 1000
    SQL
    execute <<~SQL
      UPDATE rmp_traces SET start = start * 1000, finish = finish * 1000
    SQL
  end

  def down
    execute <<~SQL
      UPDATE rmp_profiled_requests SET start = start / 1000, finish = finish / 1000
    SQL
    execute <<~SQL
      UPDATE rmp_traces SET start = start / 1000, finish = finish / 1000
    SQL
  end
end
