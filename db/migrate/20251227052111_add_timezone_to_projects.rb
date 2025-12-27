class AddTimezoneToProjects < ActiveRecord::Migration[8.1]
  def change
    add_column :projects, :timezone, :string
  end
end
