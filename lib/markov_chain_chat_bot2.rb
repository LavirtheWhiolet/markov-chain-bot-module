# encoding: UTF-8
require 'markov_chain'
require 'strscan'

# 
# A chat bot utilizing MarkovChain.
# 
class MarkovChainChatBot2
  
  private_class_method :new
  
  #
  # +data+ is a map. It may be empty, in this case a brand new
  # MarkovChainChatBot is created. +data+ becomes owned by the returned
  # MarkovChainChatBot.
  # 
  # +answer_limit+ is maximum size of the result of #answer().
  # 
  def self.from(data, answer_limit = 1000)
    new(data, answer_limit)
  end
  
  def initialize(data, answer_limit)  # :nodoc:
    @next_word_id_storage = data
    @markov_chain = MarkovChain.from(data)
    @answer_limit = answer_limit
  end
  
  # +data+ passed to MarkovChainChatBot.from().
  def data
    @markov_chain.data
  end
  
  # 
  # +message+ is String.
  # 
  # It returns this (modified) MarkovChainChatBot.
  # 
  def learn(message)
    @markov_chain.append!(tokenize(message)).append!([EndOfMessage.new])
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
  
  class EndOfMessage < Token
    
    def self.new()
      nil
    end
    
    def self.===(x)
      x.nil?
    end
    
  end
  
end

bot = MarkovChainChatBot2.from(Hash.new)
bot.learn("one two three two one")
puts bot.answer("count up and down please")
  #=> "one two three two three two one two one two three two one two one"
bot.learn("three four six")
puts bot.answer("count from three please")
  #=> "three two one two one two three four six"
