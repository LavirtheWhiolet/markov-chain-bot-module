
class MarkovChain
  
  # 
  # creates an empty MarkovChain.
  # 
  # +data+ is a map which will become owned by this MarkovChain.
  # 
  def initialize(data = {})
    @data = data
    @last_state = nil
  end
  
  # 
  # appends +states+ to the end of this MarkovChain.
  # 
  # +states+ are arbitrary objects.
  # 
  # It returns this (modified) MarkovChain.
  # 
  def append(states)
    for next_state in states
      state_occurences_map = (@data[@last_state] or Hash.new)
      state_occurences_map[next_state] ||= 0
      state_occurences_map[next_state] += 1
      @data[@last_state] = state_occurences_map
      @last_state = next_state
    end
    return self
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
  
  # 
  # This module is intended for inclusion into MarkovChain only.
  # 
  module Prediction
    
    include Enumerable
    
    def each
      #
      last_state = @last_state
      loop do
        #
        next_state = begin
          state_occurences_map = (@data[last_state] or Hash.new)
          occurences_sum = state_occurences_map.reduce(0) do |sum, entry|
            sum + entry[1]
          end
          choice = rand(occurences_sum + 1)
          chosen_state_and_occurences = state_occurences_map.find do |state, occurences|
            choice -= occurences
            choice <= 0 
          end
          chosen_state_and_occurences ||= [nil, nil]
          chosen_state_and_occurences[0]
        end
        #
        yield next_state
        #
        last_state = next_state
      end
    end
    
  end
  
end
