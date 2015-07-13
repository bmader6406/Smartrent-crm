class AddSmartRentFieldsToProperties < ActiveRecord::Migration
  def change
    add_column :properties, :county, :string
    add_column :properties, :description, :text
    add_column :properties, :short_description, :text
    add_column :properties, :latitude, :float
    add_column :properties, :longitude, :float
    add_column :properties, :studio_price, :float
    add_column :properties, :special_promotion, :boolean, :default => false
    add_attachment :properties, :image
    add_column :properties, :studio, :boolean, :default => false
    add_column :properties, :origin_id, :integer
    add_column :properties, :bozzuto_url, :string
    add_column :properties, :promotion_title, :string
    add_column :properties, :promotion_subtitle, :string
    add_column :properties, :promotion_url, :string
    add_column :properties, :promotion_expiration_date, :date
    add_column :properties, :is_smartrent, :boolean, :default => false
    #add_column :properties, :price, :float, :defualt => 0.0
  end
end
