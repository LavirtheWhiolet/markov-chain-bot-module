
# 
# A map which automatically marshals all keys and values passed to it.
# 
class AutoMarshallingMap
	
	# 
	# +backend+ is a Map from String to (String or nil). It will be used as
	# a backend storage for the new AutoMarshallingMap.
	# 
	def initialize(backend)
		@backend = backend
	end
	
	def [](key)
		value_string = @backend[Marshal.dump(key)]
		return nil if value_string.nil?
		return Marshal.load value_string
	end
	
	def []=(key, value)
		@backend[Marshal.dump(key)] = Marshal.dump(value)
		return value
	end
	
	# +backend+ argument passed to #new().
	attr_reader :backend
	
end
