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

  def add_leaves(leaf_hash)
    parent_quire = leaf_hash['parent_quire'].to_i
    position = leaf_hash['position']
    fol_num = leaf_hash['fol_num']
    single = leaf_hash['single']
    add_leaf(parent_quire, position, fol_num, single)
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

# TODO auto detect how many quires in the input csv
# right now we are manually creating quires and shoveling
# data in. if we create quires based on how many variations
# of 'parent_quire' there are in the spreadsheet. then,
# we separate the csv data based on their 'parent_quire'
# number, and shovel the data into the quires that we have created.

quire_array = []
row_hashes.each do |hash|
  parent_quire = hash['parent_quire'].to_i
  quire_array[parent_quire] = [] if quire_array[parent_quire].nil?
  quire_array[parent_quire] << hash
end

# TODO this piece of code should create new quire objects and
# shovel in the correct data to the correct quire
quires = []
quire_array.each do |quire_leaves|
  next if quire_leaves.nil?
  quire_leaves.each { |leaf_hash| quires << leaf_hash }
end

puts quires
