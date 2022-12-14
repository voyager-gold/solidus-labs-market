module Spree
  User.class_eval do
    USERNAME_REGEXP = /\A[a-z][a-z0-9_\-]*\z/i

    validates_format_of :username, with: USERNAME_REGEXP, allow_blank: true

    has_one :store, class_name: 'Spree::Store', foreign_key: 'user_id', dependent: :destroy

    before_save :set_defaults
    after_create :create_store!
    after_save :generate_address!

    alias_attribute :npb_count, :non_paying_buyer_count

    handle_asynchronously :send_confirmation_instructions, queue: 'user'

    #######################################

    def self.find_for_database_authentication(warden_conditions)
      conditions = warden_conditions.dup
      if login = conditions.delete(:login)
        where(conditions.to_h).where(['lower(username) = :value OR lower(email) = :value', { :value => login.downcase }]).first
      elsif conditions.has_key?(:username) || conditions.has_key?(:email)
        where(conditions.to_h).first
      end
    end

    def self.fetch_admin
      admin_role = ::Spree::Role.admin_role || ::Spree::Role.create(name: 'admin')
      admin_user = admin_role.users.first
      unless admin_user
        admin_user = ::Spree::User.find_or_create_by!(email: 'admin@shoppn.com') do|user|
            user.attributes = { login: 'admin@shoppn.com', country:'United States',
              country_code: 'US', zipcode: '19019', timezone: '-04:00',
              spree_api_key: '' }
            user.password = 'test1234'
          end
      end
      unless admin_user.role_users.where(role_id: admin_role.id).first
        admin_user.role_users.create(role_id: admin_role.id)
      end
      admin_user
    end

    ######################################
    # Action methods

    # Find or create one
    def fetch_store
      @store ||= self.store || create_store!
    end

    def create_store!
      ::Spree::Store.find_or_create_by(user_id: id) do|store|
        store.name = display_name || username || "Store #{id}"
        store.url = APP_HOST # ::SolidusMarket::Application.routes.url_helpers.seller_path(id: id)
        store.mail_from_address = email
        store.code = "sellers/#{id}"
      end
    end

    ##
    # Based on GeoIp with saved current_sign_in_ip.
    def generate_address!
      if !@current_sign_in_ip_updated && acceptable_ip?(current_sign_in_ip) && acceptable_ip?(current_sign_in_ip_was)
        @current_sign_in_ip_updated = true # prevent looping after calls
        h = GeoIp.geolocation(current_sign_in_ip, :timezone => true)
        self.update_attributes(country: h[:country_name], country_code: h[:country_code],
          zipcode: h[:zip_code], timezone: h[:timezone] ) if h.size > 0
      else
        nil
      end
    rescue Timeout::Error, JSON::ParserError
      ::Spree::User.logger.warn 'Problem with request to GeoIp API'
    rescue ArgumentError => e
      ::Spree::User.logger.warn "Problem in fetching location of #{current_sign_in_ip}: #{e}"
    end

    ###################################
    # Attributes

    ##
    # Ensures always have some value.  Precedence of attributes to check: display_name, username
    def try_display_name
      [display_name, username].find(&:present?)
    end

    FIRSTNAME_LASTNAME_REGEXP = /(.+)\s+(\S+)\Z/i

    def firstname
      n = try_display_name
      n.index(' ').nil? ? n : n.match(FIRSTNAME_LASTNAME_REGEXP)[1]
    end

    def lastname
      n = try_display_name
      n.index(' ').nil? ? '' : n.match(FIRSTNAME_LASTNAME_REGEXP)[2]
    end

    def acceptable_ip?(ip)
      ip.present? && ip != '127.0.0.1'
    end

    def send_confirmation_notification?
      !Rails.env.test?
    end

    protected

    def set_defaults
      self.login = username if username.present?
    end
  end

end