
# A map which key of is always mapped with some function.
class KeyMappingMap
  
  # 
  # +backend+ is a map which will be used to store the data. Its key will
  # always be results of +map_key+.
  # 
  # +map_key+ is passed with a key for this KeyMappingMap and returns
  # a key for +backend+.
  # 
  # Example:
  #   
  #   m = KeyMappingMap.new(Hash.new) { |key| f(key) }
  #   m[16] = 32
  #   puts m[16]
  #     # is equivalent to
  #   m = Hash.new
  #   m[f(16)] = 32
  #   puts m[f(16)]
  # 
  def initialize(backend, &map_key)
    @backend = backend
    @map_key = map_key
  end
  
  def [](key)
    @backend[@map_key.(key)]
  end
  
  def []=(key, value)
    @backend[@map_key.(key)] = value
  end
  
end
