class Retail::ProductSpec < ::RetailScraperRecord
  self.table_name = 'retail_product_specs'

  # attr_accessible :retail_product_id, :value_type, :name, :value_1, :value_2, :locale
  attr_accessor :keyword # different from :name, as reference for LocaleWord

  UNWANTED_CHARS_REGEX = /([\s,.:;?#])$/
  REDUNDANT_PREFIXES_REGEX = /^(available|applicable|appropriate|choose)\b/i
  ELIMINATABLE_NAME_REGEX = /(.+)\b(color|width|sleeve\s+length|length|height|thickness|depth|material|fabrics?)\Z/i

  validates_presence_of :name, :value_1

  belongs_to :product, foreign_key: 'retail_product_id'

  before_create :set_defaults
  before_save :normalize_name!, :normalize_keyword!

  def to_s
    inspect
  end

  def inspect
    "Retail::ProductSpec(#{id}) of Product(#{retail_product_id}): #{keyword} / #{name} = #{value_1}, #{value_2}"
  end

  def name_as_key
    self.name.gsub(/(\W+)/, '_').downcase
  end

  def as_indexed_json(options = {})
    self.as_json(only: [:retail_product_id, :name, :value_1, :value_2, :locale] )
  end

  def json_for_export
    as_json(only: [:name, :value_1, :value_2, :locale] )
  end

  def normalize_name!
    if name
      self.name.gsub!(UNWANTED_CHARS_REGEX, '')
      self.name.gsub!(REDUNDANT_PREFIXES_REGEX, '')
      # self.name = $2 if self.name =~ ELIMINATABLE_NAME_REGEX
      self.name = name.downcase.singularize if name
    end
    name
  end

  def normalize_keyword!
    if keyword
      self.keyword.gsub!(UNWANTED_CHARS_REGEX, '')
    end
    keyword
  end

  # For comparison and sorting.
  def <=>(other)
    self.class.comparator_class(self).compare(self, other)
  end

  def ==(other)
    self.value_for_comparison == other.value_for_comparison
  end

  def value_for_comparison
    [name.try(:downcase), value_1.try(:strip), value_2.try(:strip)]
  end

  ##
  # Convert to data type defined by @value_type.  So could be types like Dimensions, Range, Array,
  #   Integer, Float, or String as default.
  def object_value
    case value_type
      when 'Dimensions'
        Dimensions.parse(value_1.to_s)
      when 'Range'
        eval("#{value_1}..#{value_2}")
      when 'Array'
        eval value_1
      when 'Integer'
        value_1.to_i
      when 'Float'
        value_1.to_f
      else
        value_1
    end
  end

  def json_for_export
    as_json(only: [:value_type, :name, :value_1, :value_2, :locale])
  end

  def self.comparator_class(spec)
    if spec.name =~ /\bsizes?$/i
      ::Retail::WordedSizeSpec
    else
      ::Retail::ProductSpec
    end
  end

  ##
  # Another level of comparison below comparison of value_for_comparison is by ID.
  def self.compare(spec_1, spec_2)
    comp = ( spec_1.value_for_comparison <=> spec_2.value_for_comparison )
    if comp == 0
      (spec_1.id && spec_2.id) ? (spec_1.id <=> spec_2.id) : comp
    else
      comp
    end
  end

  protected

  MAX_LIMIT_OF_VALUE = 120

  def set_defaults
    self.name = name[0,60].squeeze.strip if name
    if self.value_type.blank?
      self.value_type = 'String'
    end
    self.value_1 = value_1[0,MAX_LIMIT_OF_VALUE].strip if value_1
    self.value_2 = value_1[0,MAX_LIMIT_OF_VALUE].strip if value_2
  end
end
