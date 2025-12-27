class RenameMonitorsToUptimeMonitors < ActiveRecord::Migration[8.1]
  def change
    rename_table :monitors, :uptime_monitors
  end
end
