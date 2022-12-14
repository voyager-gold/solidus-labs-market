require 'csv'
require 'open-uri'

class Retail::Product < ::RetailScraperRecord

  self.table_name = 'retail_products'

  attr_accessor :temp_specs, :categories_object

  validates_presence_of :retail_site_id, :title

  INVALID_TITLE_REGEXP = /\A(301|302|404|500)\s+Moved\s+Permanently/i

  validates :title, format: { without: INVALID_TITLE_REGEXP }

  ################################
  # Scopes

  belongs_to :retail_site, class_name: 'Retail::Site', foreign_key: :retail_site_id
  belongs_to :retail_store, class_name: 'Retail::Store', foreign_key: :retail_store_id, optional: true
  belongs_to :page, class_name: 'Scraper::Page', foreign_key: :scraper_page_id, optional: true
  alias_method :scraper_page, :page

  has_many :product_specs, class_name: 'Retail::ProductSpec', foreign_key: :retail_product_id, dependent: :delete_all
  alias_method :specs, :product_specs
  has_many :product_photos, class_name: 'Retail::ProductPhoto', foreign_key: :retail_product_id, dependent: :destroy
  alias_method :photos, :product_photos

  has_many :migrations, class_name: 'Retail::ProductToSpreeProduct', foreign_key: :retail_product_id
  has_many :spree_products, class_name: 'Spree::Product', through: :migrations, foreign_key: :spree_product_id

  ##################################
  # Callbacks

  before_save :convert_attributes
  before_destroy :reset_assets!

  def store_id
    retail_store.try(:retail_site_store_ids)
  end

  def category_names
    (JSON.load(categories) || []).collect { |h| h['name'] }
  rescue JSON::ParserError
    []
  end

  def other_site_categories
    ::Retail::OtherSiteCategory.find_for_retail_product(self)
  end

  def leaf_other_site_category
    other_site_categories.last
  end

  ##
  # Deepest level of category, dependent on categories property specifying the category path.
  # @return <SiteCategory>
  def leaf_site_category
    categories.present? ? ::SiteCategory.find_by_full_path(retail_site.name, category_names) : []
  end
  alias_method :site_category, :leaf_site_category

  # Mixed spec name and values together, w/ spec.name as its own attribute name, e.g., "max_size": 10
  def specs_list
    # product_specs.collect{|spec| [spec.name, spec.value_1, spec.value_2].compact }.flatten.uniq Mixed spec name and values together
    product_specs.collect { |spec| { spec.name_as_key => spec.value_1} }
  end

  def as_json(options = {})
    h = super(options)
    # h['specs'] = product_specs.collect(&:as_json)
    # h['product_photos'] = product_photos.collect(&:as_json)
    h
  end

  ##
  # Grouped up list of values by common spec name.
  # @return <Hash of String => Set of values>
  def spec_name_to_values_group(which_product_specs = nil)
    h = {}
    (which_product_specs || self.product_specs).each do|spec|
      set = h[spec.name] || Set.new
      set << spec.object_value
      h[spec.name] = set
    end
    h
  end

  ###############################
  # Util methods

  ##
  # Destroys product_photos and product_specs
  def reset_assets!
    self.product_photos.each(&:destroy)
    self.product_specs.each(&:destroy)
  end

  ##
  # Delete duplicate specs.
  def clean_product_specs!
    existing_specs = Set.new
    product_specs.each do |spec|
      if existing_specs.include?(spec.value_for_comparison)
        puts "  - #{spec}"
        spec.destroy
      else
        existing_specs << spec
      end
    end
  end

  ##
  # Find or create this retail store
  def connect_to_retail_store!(retail_site_id, retail_site_store_id, other_attr = {})
    store = ::Retail::Store.find_or_create_by!(
        retail_site_id: retail_site_id, retail_site_store_id: retail_site_store_id) do|record|
      record.attributes = other_attr if other_attr.size > 0
    end
    self.retail_store ||= store
    self.save
  end

  ##
  # Matched or created ProductSpec would be yielded in block.
  # @specs <Array of Retail::ProductSpec or a Hash w/ spec name to value >
  # @return <Array of Retail::ProductSpec> updated list
  #
  def find_or_create_product_specs!(specs, &block)
    matching_specs = []
    group = self.product_specs.group_by(&:name)
    logger.info "  \\ given specs #{specs}"
    (specs || [] ).each do|obj|
      _name = nil
      _value = nil
      if obj.is_a?(::Retail::ProductSpec)
        _name = obj.name
        _value = obj.object_value
      elsif obj.is_a?(Hash)
        # model hash format like [{"name"=>"available sizes", "value_1"=>"S M"}, {"name"=>"available colors", "value_1"=>""}]
        obj_stringified = obj.stringify_keys
        sorted_keys = obj_stringified.keys.sort
        if sorted_keys == %w{name value_1}
          _name = obj_stringified['name']
          _value = obj_stringified['value_1']
        else # dynamic keys to values: 'material' => 'wool', 'color' => 'black'
          _name = obj_stringified.keys.first
          _value = obj_stringified[_name]
        end
      end
      next if _name.blank?
      # is new
      cur_set = group[_name] || []
      if (cur_spec = cur_set.find{|_spec| [_spec.value_1, _spec.value_2] == [_value, nil] } )
        matching_specs << cur_spec
      else
        cur_spec = Retail::ProductSpec.create(retail_product_id: id, name: _name, value_1: _value)
        matching_specs << cur_spec
      end
      yield cur_spec if block_given?
    end
    matching_specs
  end

  def fix_product_categories!
    self.update_attributes(categories: retail_site.scraper.find_categories_object(page.make_mechanize_page).to_json)
  end

  ##
  # @return <Spree::Product>
  def create_as_spree_product(force_recreate = false, other_attributes = {}, &block)
    product = force_recreate ? nil : ::Retail::ProductToSpreeProduct.where(retail_product_id: id).first.try(:spree_product)
    spree_user = retail_store ? retail_store.setup_spree_user_and_store! : nil
    unless product
      product = self.class.make_spree_product(self)
      product.attributes = other_attributes if other_attributes.size > 0
      product.user_id ||= spree_user.id
      product.save
      ::Retail::ProductToSpreeProduct.create(retail_product_id: id, spree_product_id: product.id)
      product.copy_images_from_retail_product!(self)
      product.create_categories_taxon!(self)
      product.copy_product_specs_from_retail_product!(self)
    end
    yield product if block_given?
    product
  end

  ##
  # @retail_product <Retail::Product> new but not saved
  def self.make_spree_product(retail_product)
    product = ::Spree::Product.new(
        name: retail_product.title.strip,
        description: retail_product.description,
        available_on: Time.now,
        shipping_category_id: ::Spree::ShippingCategory.default.try(:id),
        price: retail_product.price
      )
    product
  end

  protected

  def convert_attributes
    if categories_object.is_a?(Hash)
      self.categories = categories_object.to_json
    end
    self.description = description.encode_to_utf8 if description
  end

end
