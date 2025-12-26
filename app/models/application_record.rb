class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Use UUIDs by default
  self.implicit_order_column = "created_at"
end
