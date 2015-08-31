@persons = []

# get Persons data like it was received from a storage (chunk)
def _get_random_persons
  @persons += 10.times.map do |i|
    Struct.new(:gender, :age, :height, :index, :money).new(
        i%2,
        rand(100),
        rand(300),
        rand(1_000_000),
        (rand(1_000_000)/i.to_f).round(2)
    )
  end
end

# make indexes for each Person struct attribute
def _make_indexes
  %i(gender age height index money).each do |attr|
    index = {}
    @persons.each do |p|
      hash = _calc_hash(p.send(attr))
      index[hash] ||= []
      index[hash] += [p.object_id]
    end
    # index - an instance variable that stores Hash
    instance_variable_set "@#{attr}_index", index
  end
end

# that's it - in this example we're using Ruby hash function
def _calc_hash(value)
  value.hash
end

# common find method with little bit metaprogramming
def _find_by(attr, value)
  result = []
  attr_index = instance_variable_get "@#{attr.to_s}_index"
  # if filter's value either Range or Array - we'll make n-searches by index Hash
  if %w(Array Range).include? value.class.name
    value.to_a.each do |v|
      hash = _calc_hash(v)
      unless attr_index.has_key? hash
        result += []
        next
      end
      result += attr_index[hash]
    end
  else
    hash = _calc_hash(value)
    return [] unless attr_index.has_key? hash
    result += attr_index[hash]
  end
  # result contains an array of person.object_id
  result
end

# the main find method that supports a few filter conditions
def find_where(filters={})
  result = []
  filters.each do |attr, value|
    result << _find_by(attr, value)
  end
  # result is an array of arrays of person.object_id, we need to intersect them in order to find a Person that meets all filter conditions
  p result.inject(:&).map{|obj_id| ObjectSpace._id2ref(obj_id)}
end

# prepare data & indexes
_get_random_persons
_make_indexes

# call the main method
find_where gender: 1, age: (1..30)