class ChangePlatformProjectIdNullable < ActiveRecord::Migration[8.1]
  def change
    change_column_null :projects, :platform_project_id, true
  end
end
