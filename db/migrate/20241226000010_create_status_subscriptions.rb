class CreateStatusSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :status_subscriptions, id: :uuid do |t|
      t.references :status_page, type: :uuid, null: false, foreign_key: true

      t.string :email
      t.string :phone                        # For SMS
      t.string :webhook_url                  # For webhook notifications

      t.string :channel, null: false         # email, sms, webhook
      t.boolean :confirmed, default: false
      t.string :confirmation_token
      t.datetime :confirmed_at

      # Preferences
      t.boolean :notify_incidents, default: true
      t.boolean :notify_maintenance, default: true
      t.string :severity_filter, array: true, default: ["minor", "major", "critical"]

      t.timestamps

      t.index [:status_page_id, :email]
      t.index [:status_page_id, :channel]
      t.index :confirmation_token, unique: true
    end
  end
end
