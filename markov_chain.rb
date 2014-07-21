
class MarkovChain
  
  def initialize(data = {})
    @data = data
    @last_state = nil
  end
  
  def append(states)
    for next_state in states
      state_occurences_map = (@data[@last_state] or Hash.new)
      state_occurences_map[next_state] ||= 0
      state_occurences_map[next_state] += 1
      @data[@last_state] = state_occurences_map
    end
  end
  
  #
  # returns Enumerable of predicted states.
  # 
  def predict()
    self.extend(Prediction)
  end
  
  # 
  # +data+ passed to #initialize().
  # 
  def data
    @data
  end
  
  private
  
  module Prediction
    
    include Enumerable
    
    def each
      #
      last_state = @last_state
      loop do
        #
        next_state = begin
          state_occurences_map = (@data[last_state] or Hash.new)
          occurences_sum = state_occurences_map.reduce(0) { |sum, entry| sum + entry[1] }
          choice = rand(occurences_sum + 1)
          state_occurences_map.each_pair do |state, occurences|
            choice -= occurences
            if choice <= 0 then
              break(state)
            end
          end
        end
        #
        yield next_state
      end
    end
    
  end
  
end