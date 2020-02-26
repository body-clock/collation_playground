require 'csv'

class Quire
  attr_reader :leaves

  def initialize
    @leaves = []
  end

  def add_leaf(position, folio_number, single = nil)
    @leaves << Leaf.new(position, folio_number, single)
  end

  def add_leaves(quire_hashes)
    quire_hashes.each do |row|
      position = row['position']
      fol_num = row['fol_num']
      single = row['single']
      add_leaf(position, fol_num, single)
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
  attr_accessor :position, :folio_number, :single, :conjoin

  def initialize(position, folio_number, single)
    @position = position
    @folio_number = folio_number
    @single = single
  end
end

my_quire = Quire.new
row_hashes = []
CSV.foreach '/Users/patrick/work/collation_playground/quire_data.csv', headers: true do |row|
  row_hashes << row.to_h
end
my_quire.add_leaves(row_hashes)
my_quire.set_conjoins
my_quire.leaves.each do |leaf|
  puts sprintf('%2d  %2s', leaf.position, leaf.conjoin)
end