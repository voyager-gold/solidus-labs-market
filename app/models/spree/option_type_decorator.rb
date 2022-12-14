module Spree
  OptionType.class_eval do
    validate :check_name

    VALID_OPTION_NAME_REGEX = /^((max|maximum|minmum|min|average|avg|estimate|est|US|UK|original|market|man'?s?|men'?s?|woman'?s?|women'?s?|kids?|adults?|new|supported|product|item)\s+)?([a-z]{2,}\s+)?(types?|category|name|colou?rs?|sizes?|number|no|sku|brand|width|length|height|diameter|radius|thickness|area|waist|bust|collar|weight|depth|models?|material|fabric|quality|quantity|count|pieces?|style|group|range|age|gender|level|class|capacity|time|date|life|season|quantity|version|edition|mode|port|payment|pattern|price|cost|charge|fee|rate|frequency|response|speed|bandwidth|volume|shape|method|current|voltage|percentage|ratio|frequency|condition|code|sleeve|sensitivity|grade|rating|platform|protocol|operating\s+system|format|angle|interface|standard)$/i

    DEFAULT_CACHE_KEY = 'DEFAULT_OPTION_TYPES'
    DEFAULT_OPTION_NAMES = ['color', 'clothing color', 'size', 'clothing size', 'shoe size']
    CATEGORY_NAMES_TO_OPTION_TYPE_NAMES_MAP = {
      /shoes?\s*\z/i => ['color', 'clothing color', 'shoe size'],
      /clothing|clothes/i => ['color', 'clothing color', 'size', 'clothing size']
    }

    after_save :clear_cache

    ##
    # @specific_user <Spree::User> If specified, would be option_values only accessible_by that.
    def as_json_with_option_values(specific_user = nil)
      json = as_json(except: [:created_at, :updated_at])
      list = specific_user ? option_values.accessible_by(::Spree::Ability.new(specific_user))
        : option_values.for_public
      json[:option_values] = list.collect{|v| v.as_json(except:[:created_at, :updated_at] ) }
      json
    end

    def self.valid_option_name?(name = '')
      !name.to_sanitized_keyword_name.match(VALID_OPTION_NAME_REGEX).nil?
    end

    ##
    # Iterates over list of category names, and find matches and their paired option type names
    # @category_names <Array of String>
    def self.default_option_types(category_names = [])
      option_names = Set.new
      category_names.each do|category_name|
        CATEGORY_NAMES_TO_OPTION_TYPE_NAMES_MAP.each_pair do|k, v|
          option_names += v if k =~ category_name
        end
      end
      self.where(name: option_names.to_a )
    end

    protected

    def check_name
      unless self.class.valid_option_name?(name)
        self.errors.add(:name)
      end
    end

    def clear_cache
      Rails.cache.delete(DEFAULT_CACHE_KEY)
    end
  end
end