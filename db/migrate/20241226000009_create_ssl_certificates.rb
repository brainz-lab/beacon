class CreateSSLCertificates < ActiveRecord::Migration[8.0]
  def change
    create_table :ssl_certificates, id: :uuid do |t|
      t.references :monitor, type: :uuid, null: false, foreign_key: true

      t.string :domain, null: false
      t.string :issuer
      t.string :subject
      t.string :serial_number

      t.datetime :issued_at
      t.datetime :expires_at

      t.boolean :valid, default: true
      t.string :validation_error

      t.string :fingerprint_sha256
      t.string :public_key_algorithm
      t.integer :public_key_bits

      t.datetime :last_checked_at

      t.timestamps

      t.index [:monitor_id, :expires_at]
      t.index :expires_at
      t.index :domain
    end
  end
end
