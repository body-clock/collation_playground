require 'csv'
require 'nokogiri'
require 'set'

class Manuscript
  attr_accessor :quires

  def initialize
    @quires = []
  end

  def to_xml
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.manuscript {
        xml.quires {
          @quires.each { |quire|
            xml.quire('n': quire.n)
          }
        }
        @quires.each { |quire|
          quire.leaves.each { |leaf|
            xml.leaf('n': leaf.position,
                     'parent_quire':leaf.parent_quire,
                     'conjoin': leaf.conjoin)
          }
        }
      }
    end
    builder.to_xml
  end
end

class Quire
  attr_reader :leaves

  def initialize
    @leaves = []
  end

  def add_leaf(parent_quire, position, folio_number, single = nil)
    @leaves << Leaf.new(parent_quire, position, folio_number, single)
  end

  def add_leaves(array_of_leaf_hashes)
    array_of_leaf_hashes.each do |leaf_hash|
      parent_quire = leaf_hash['parent_quire'].to_i
      position = leaf_hash['position']
      fol_num = leaf_hash['fol_num']
      single = leaf_hash['single']
      add_leaf(parent_quire, position, fol_num, single)
    end
  end

  def size
    @leaves.size
  end

  def set_conjoins
    conjoined_leafs = @leaves.reject { |leaf| leaf.single }
    while conjoined_leafs.count > 0
      pair = [conjoined_leafs.shift, conjoined_leafs.pop]
      pair.first.conjoin = pair.last.position
      pair.last.conjoin = pair.first.position
    end
  end
end

class Leaf
  attr_accessor :parent_quire, :position, :folio_number, :single, :conjoin

  def initialize(parent_quire, position, folio_number, single)
    @parent_quire = parent_quire
    @position = position
    @folio_number = folio_number
    @single = single
  end
end

row_hashes = []
CSV.foreach '/Users/patrick/work/collation_playground/quire_data.csv', headers: true do |row|
  row_hashes << row.to_h
end

# formatted_csv_data is the raw csv information in a nested structure
# that imitates the construction of a book

# quires is a similar structure, but makes use of the Quire and
# Leaf object to arrange and modify our leaf information (ie conjoin)

# formatted_csv_data is an array where each element is another array
# of hashes. each hash contains the information from a row in
# the csv

formatted_csv_data = []
row_hashes.each do |hash|
  # convert the 'parent_quire' value from the csv to int and assign to
  # variable called parent_quire '1'
  parent_quire = hash['parent_quire'].to_i
  # create empty array at index [parent_quire] 'quire_array[1]'
  # if there isn't already a value there
  formatted_csv_data[parent_quire] = [] if formatted_csv_data[parent_quire].nil?
  # shovel in the leaf hash (csv row) information at the index of
  # the parent quire
  formatted_csv_data[parent_quire] << hash
end

# quires is an array where each element is a quire object. inside each quire
# object is an array called @leaves. each element in this array is a page object.
quires = []
formatted_csv_data.each do |quire_leaves|
  next if quire_leaves.nil?
  quire = Quire.new
  quire.add_leaves quire_leaves
  quires << quire
end

quires.each do |quire|
  quire.set_conjoins
end