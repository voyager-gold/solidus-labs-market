module Retail
  class StoreToSpreeUser < ::ApplicationRecord

    self.table_name = 'retail_stores_spree_users'

    belongs_to :retail_store, class_name: 'Retail::Store'
    belongs_to :spree_user, foreign_key: 'spree_user_id', class_name: 'Spree::User'
  end
end