class AddUnsubscribeTokenToStatusSubscriptions < ActiveRecord::Migration[8.0]
  def change
    add_column :status_subscriptions, :unsubscribe_token, :string
    add_index :status_subscriptions, :unsubscribe_token, unique: true
  end
end
