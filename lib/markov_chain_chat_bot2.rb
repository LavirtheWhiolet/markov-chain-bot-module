# encoding: UTF-8
require 'markov_chain'
require 'strscan'
require 'key_mapping_map'

# Optimization: See this constant's usage in MarkovChainChatBot2.
I = Struct.new :v

# Optimization: See this constant's usage in MarkovChainChatBot2.
W = Struct.new :v

# Optimization: See this constant's usage in MarkovChainChatBot2.
M = Struct.new :v

# 
# A chat bot utilizing MarkovChain.
# 
class MarkovChainChatBot2
  
  private_class_method :new
  
  #
  # +data+ is a map. It may be empty, in this case a brand new
  # MarkovChainChatBot2 is created. +data+ becomes owned by the returned
  # MarkovChainChatBot2.
  # 
  # +answer_limit+ is maximum size of the result of #answer().
  # 
  def self.from(data, answer_limit = 1000)
    new(data, answer_limit)
  end
  
  def initialize(data, answer_limit)  # :nodoc:
    @answer_limit = answer_limit
    @data = data
    # Split data into separate maps.
    @next_word_id_storage = data
    @word_to_id = KeyMappingMap.new(data, &WordToIDKey)
    @id_to_word = KeyMappingMap.new(data, &IDToWordKey)
    @markov_chain = MarkovChain.from(KeyMappingMap.new(data, &MarkovChainDataKey))
  end
  
  # +data+ passed to MarkovChainChatBot2.from().
  def data
    @data
  end
  
  # 
  # +message+ is String.
  # 
  # It returns this (modified) MarkovChainChatBot2.
  # 
  def learn(message)
    @markov_chain.
      append!(tokenize(message).map { |token| to_id(token) }).
      append!([to_id(EndOfMessage.new)])
    return self
  end
  
  # 
  # +question+ is String.
  # 
  # It returns String.
  # 
  def answer(question)
    answer = ""
    previous_token = nil
    catch :out_of_limit do
      for token in @markov_chain.predict()
        token = to_word(token)
        break if token.tkn_is_a? EndOfMessage or token.nil?
        delimiter = 
          if (previous_token.tkn_is_a? Word and token.tkn_is_a? Word) then " "
          else ""
          end
        answer.append_limited(delimiter + token.tkn_value, @answer_limit)
        previous_token = token
      end
    end
    return answer
  end
  
  private
  
  # :enddoc:
  
  # Accessible to #to_id() only.
  # 
  # It returns a new Integer ID of a word which is unique amongst #data.
  # 
  def new_word_id
    # 
    new_word_id = (@next_word_id_storage[:n] ||= 1)
    # Calculate next word ID.
    if new_word_id > 0 then
      @next_word_id_storage[:n] = -new_word_id
    else
      @next_word_id_storage[:n] = -new_word_id + 1
    end
    # 
    return new_word_id
  end
  
  # returns an Integer ID of the +word+ which is unique amongst #data.
  # 
  # It returns nil if +word+ is nil.
  # 
  def to_id(word)
    return nil if word.nil?
    if (id = @word_to_id[word]).nil? then
      id = new_word_id
      @word_to_id[word] = id
      @id_to_word[id] = word
    end
    return id
  end
  
  # returns the word corresponding to +id+.
  # 
  # #to_id(word) must be called and must return +id+ at least once before
  # this function can be used with such +id+.
  # 
  # +id+ is the result of #to_id.
  # 
  # Example:
  #   
  #   id = to_id("foobar")
  #   puts to_word(id)  #=> "foobar"
  #   
  #   puts to_word(nil)  #=> nil
  #   
  #   puts to_word(20)  #=> wrong!
  # 
  def to_word(id)
    return nil if id.nil?
    @id_to_word[id]
  end
  
  class ::Class
    
    # returns an alias to this Class#new.
    def to_proc
      lambda { |arg| self.new(arg) }
    end
    
  end
  
  class ::String
    
    # appends +appendment+ to this String or throws +:out_of_limit+ if
    # this String will exceed +limit+ after the appending.
    # 
    # It returns this (modified) String.
    # 
    def append_limited(appendment, limit)
      throw :out_of_limit if self.length + appendment.length > limit
      self << appendment
      return self
    end
    
  end
  
  #
  # returns Array of Token-s.
  # 
  def tokenize(text)
    tokens = []
    s = StringScanner.new(text)
    until s.eos?
      # Word.
      (
        w = s.scan(/([-–]?[a-zA-Zа-яёА-ЯЁ0-9]+)+/) and
          tokens << Word.new(w)
      ) or
      # Punctuation.
      ( 
        p = s.scan(/([#{WHITESPACE_CHARSET}]|[^\-–a-zA-Zа-яёА-ЯЁ0-9]|[-–](?![a-zA-Zа-яёА-ЯЁ0-9)]))+/o) and begin
          p.gsub(/[#{WHITESPACE_CHARSET}]+/, " ")
          if p != " " then
            tokens << PunctuationMark.new(p)
          end
          true
        end
      ) or
      break
    end
    return tokens
  end
  
  # Accessible to #tokenize() only.
  # 
  # White space characters as specified in "Unicode Standard Annex #44: Unicode
  # Character Database" (http://www.unicode.org/reports/tr44, specifically
  # http://www.unicode.org/Public/UNIDATA/PropList.txt).
  # 
  WHITESPACE_CHARSET = "\u0009-\u000D\u0020\u0085\u00A0\u1680\u180E\u2000-\u200A\u2028\u2029\u202F\u205F\u3000"
  
  Token = Object
  
  class Token
    
    def tkn_value
      self[1..-1]
    end
    
    def tkn_is_a?(clazz)
      clazz === self
    end
    
  end
  
  class Word < Token
    
    def self.new(value)
      "w" + value
    end
    
    def self.===(x)
      x.is_a? String and x[0] == "w"
    end
    
  end
  
  class PunctuationMark < Token
    
    def self.new(value)
      "p" + value
    end
    
    def self.===(x)
      x.is_a? String and x[0] == "p"
    end
    
  end
  
  # FIXME: EndOfMessage must currently coincide with an initial state of
  #   MarkovChain, i.e. nil.
  
  class EndOfMessage < Token
    
    def self.new()
      nil
    end
    
    def self.===(x)
      x.nil?
    end
    
  end
  
  # Accessible to #initialize() only.
  # 
  # Used for splitting a map into several maps only.
  # 
  # Optimization: Marshal also dumps full class name. The shorter the class
  # name the shorter the dumped value.
  # 
  WordToIDKey = I
  
  # Accessible to #initialize() only.
  # 
  # Used for splitting a map into several maps only.
  # 
  # Optimization: Marshal also dumps full class name. The shorter the class
  # name the shorter the dumped value.
  # 
  IDToWordKey = W
  
  # Accessible to #initialize() only.
  # 
  # Used for splitting a map into several maps only.
  # 
  # Optimization: Marshal also dumps full class name. The shorter the class
  # name the shorter the dumped value.
  # 
  MarkovChainDataKey = M
  
end

# bot = MarkovChainChatBot2.from(Hash.new)
# bot.learn("one two three two one")
# puts bot.answer("count up and down please")
#   #=> "one two three two three two one two one two three two one two one"
# bot.learn("three four six")
# puts bot.answer("count from three please")
#   #=> "three two one two one two three four six"
# p bot.data
