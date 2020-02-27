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
  attr_reader :leaves, :n

  def initialize(quire_number)
    @leaves = []
    @n = quire_number
  end

  def add_leaf(parent_quire, position, folio_number, single = nil)
    @leaves << Leaf.new(parent_quire, position, folio_number, single)
  end

  def add_leaves(quire_hashes)
    quire_hashes.each do |row|
      parent_quire = row['parent_quire']
      position = row['position']
      fol_num = row['fol_num']
      single = row['single']
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

# TODO auto detect how many quires in the input csv
# right now we are manually creating quires and shoveling
# data in. if we create quires based on how many variations
# of 'parent_quire' there are in the spreadsheet. then,
# we separate the csv data based on their 'parent_quire'
# number, and shovel the data into the quires that we have created.

# get all parent_quire values into a list
parent_quires = []
row_hashes.each do |hash|
  parent_quires << hash['parent_quire']
  parent_quires.uniq!
end

quire_list = []
parent_quires.each do |parent_quire_number|
  quire_list << Quire.new(parent_quire_number)
end

# if the n value for a row in the hash is == 1, shovel those quires into quire 1

quire_list[0].add_leaves(row_hashes)
quire_list[0].set_conjoins
quire_list[0].leaves.each do |leaf|
  puts sprintf('%2d  %2s', leaf.position, leaf.conjoin)
end

my_manuscript = Manuscript.new
my_manuscript.quires << quire_list[0]

puts my_manuscript.to_xml

