# ============================================================================
# cellar - Ruby gem to deal with cells of data in rows and columns
#
# Author: Steve Shreeve (steve.shreeve@gmail.com)
#   Date: October 8, 2024
#
# TODO:
# • Should we failover to empty strings like this: (value || "")
# ============================================================================

class Object
  def val?
    !nil?
  end unless defined? val?

  def blank?
    respond_to?(:empty?) or return !self
    empty? or respond_to?(:strip) && strip.empty?
  end unless defined? blank?

  def if_blank?(val)
    blank? ? val : self
  end unless defined? if_blank?
end

class Cellar
  VERSION="0.1.3"

  attr_reader   :fields
  attr_reader   :values
  attr_accessor :strict

  def initialize(obj=nil, header: true, strict: true)
    @fields = []
    @values = []
    @finder = {}
    @seeker = {}
    @index  = nil
    @widest = 0

    if obj.is_a?(Array)
      if obj.first.is_a?(Array)
        self.fields = obj.shift if header
        @rows = obj unless obj.empty?
      elsif !obj.empty?
        header ? (self.fields = obj) : (@rows = obj)
      end
    end

    @strict = strict.nil? ? !@fields.empty? : !!strict
  end

  def add_field(field)
    field = field.to_s
    index = @fields.size
    @fields << field
    finders = @finder.size
    @finder[field.downcase.gsub(/\W/,'_')] ||= index
    @finder.size == finders + 1 or warn "field clash for #{field.inspect}"
    @finder[field] ||= index
    @widest = field.length if field.length > @widest
    index
  end

  def index(field)
    case field
    when String, Symbol
      field = field.to_s
      index = @finder[field] || @finder[field.downcase.gsub(/\W/,'_')]
      raise "no field #{field.inspect}" if !index && @strict
      index
    when Integer
      raise "no field at index #{field}" if field >= @fields.size && @strict
      field < 0 ? field % @fields.size : field
    when Range
      from = field.begin
      till = field.end
      from = from.blank? ?  0 : index(from)
      till = till.blank? ? -1 : index(till)
      case from <=> till
      when  1 then field.exclude_end? ? [*(till+1)..from].reverse : [*till..from].reverse
      when  0 then from
      when -1 then field.exclude_end? ? from...till : from..till
      else "no fields match #{field.inspect}"
      end
    else
      raise "unable to index fields by #{field.class.inspect} [#{field.inspect}]"
    end
  end

  def clear
    @values = []
    self
  end

  def [](*fields)
    case fields.size
    when 0
      []
    when 1
      index = index(fields.first)
      value = @values[index] if index
    else
      fields.inject([]) do |values, field|
        index = index(field)
        value = case index
          when nil   then nil
          when Array then @values.values_at(*index)
          else            @values[index]
        end
        Array === value ? values.concat(value) : values.push(value)
      end
    end
  end

  def []=(*fields)
    values = Array(fields.pop).dup
    fields = fields.map {|field| Array(index(field) || add_field(field))}.flatten

    if fields.empty?
      @values.replace(values)
    elsif values.size > fields.size
      raise "unable to assign #{values.size} values to #{fields.size} fields for values=#{values.inspect}"
    else
      fields.each_with_index do |field, pos|
        @values[field] = values[pos]
      end
    end

    @values
  end

  def fields=(*list)
    @fields.clear
    @finder.clear
    @widest = 0

    list.flatten.each {|field| add_field(field)}
  end

  def values=(*list)
    @values = list.flatten
  end

  def field(pos)
    @fields[pos]
  end

  def method_missing(field, *args)
    field = field.to_s
    equal = field.chomp!("=")
    index = index(field)
    if equal
      index ||= add_field(field)
      value = @values[index] = args.first
    elsif index
      raise "variable lookup ignores arguments" unless args.empty?
      value = @values[index]
    else
      value = ""
    end
    value
  end

  # ==[ Row handling ]==

  def rows=(rows)
    rows or raise "no rows defined"
    @rows = rows
    row(0) # returns self
  end

  def row=(row)
    @rows or raise "no rows defined"
    row(row) # returns self
  end

  def cells
    [@fields.dup] + @rows
  end

  def rows
    @rows
  end

  def row(row=nil)
    @rows or raise "no rows defined"
    @values = row ? @rows[@row = row] : []
    self
  end

  def <<(data)
    @rows ||= []
    @row = row = @rows.size
    if self.class === data.class
      @rows << @values = []
      self[*data.fields] = data.values
    elsif data.is_a?(Array) && !data.first.is_a?(Array)
      @rows << data
    else
      raise "unable to << your object"
    end
    if @index
      block = @index if @index.is_a?(Proc)
      field = @index unless block
      index = index(field) or raise "unknown index #{field.inspect}" if field
      if key = block ? block.call(self) : @values[index]
        @seeker[key] and raise "duplicate index: #{key.inspect}"
        @seeker[key] = row
      end
    end
    self
  end

  def index!(field=nil, &block)
    @rows ||= []
    @index = field || block or raise "index needs a field or a block"
    index = index(field) or raise "unknown index #{field.inspect}" if field && @rows.size > 0
    @seeker.clear
    @rows.each_with_index do |values, row|
      if key = block ? yield(row(row)) : values[index]
        @seeker[key] and raise "duplicate index: #{key.inspect}"
        @seeker[key] = row
      end
    end
    self
  end

  def seek!(seek)
    @rows or raise "no rows defined"
    @seeker.empty? and raise "not indexed"

    if row = @seeker[seek]
      row(row)
    else
      @values = []
      @row = nil
    end
  end

  def each
    @rows or raise "no rows defined"
    @rows.each_with_index {|values, row| yield(row(row)) }
  end

  def map
    @rows or raise "no rows defined"
    @rows.map.with_index {|values, row| yield(row(row)) }
  end

  def from_array(list)
    clear
    @values = list.map {|v| v.to_s.strip if v }
    self
  end

  def from_hash(hash)
    clear
    hash.each {|k,v| self[k] = v.to_s if v }
    self
  end

  def to_hash!
    @fields.size.times.inject({}) do |h, i|
      v = @values[i]
      h[@fields[i].downcase.gsub(/\W/,'_')] = v if !v.blank?
      h
    end
  end
end
