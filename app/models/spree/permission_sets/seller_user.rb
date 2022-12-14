##
# class SellerUser < DefaultCustomer
module Spree
  module PermissionSets
    class SellerUser < DefaultCustomer
      def activate!
        super

        # from Spree::PermissionSets::ProductManagement
        ::Spree::ProductUserRelation::MANAGEABLE_CLASSES.each do|klass|
          can :manage, klass, user_id: user.id if klass.new.respond_to?(:user_id)
          can [:new, :create], klass
        end
        ::Spree::StoreUserRelation::MANAGEABLE_CLASSES.each do|klass|
          can :manage, klass, user_id: user.id if klass.new.respond_to?(:user_id)
          can [:new, :create], klass
        end

        # These don't have ref to product
        can :manage, Spree::Price
        can :manage, Spree::Image

        # somehow the looped 'can :manage' calls don't work
        can :manage, Spree::Product, user_id: user.id
        can [:new, :create], Spree::Product
        # can :manage, Spree::OptionValue, user_id: user.id
        can [:new, :create], ::Spree::OptionValue
        can :manage, Spree::StockItem

        # Cannot's
        cannot :manage, Spree::StockLocation
        cannot :erase, Spree::Product

        # exceptions that don't have actual model class as reference
        cannot :admin, :reports
      end

    end
  end
end
