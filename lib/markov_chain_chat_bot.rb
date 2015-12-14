# encoding: UTF-8
require 'markov_chain'
require 'strscan'

# 
# A chat bot utilizing MarkovChain.
# 
class MarkovChainChatBot
  
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
    @markov_chain =
      if data.empty? then MarkovChain.new(data)
      else MarkovChain.from(data)
      end
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
  
  #
  # returns Array of Token-s.
  # 
  def tokenize(text)
    tokens = []
    s = StringScanner.new(text)
    until s.eos?
      # Word.
      (
        w = s.scan(/(-?[a-zA-Zа-яёА-ЯЁ0-9]+)+/) and
          tokens << Word.new(w)
      ) or
      # Punctuation.
      ( 
        p = s.scan(/([#{WHITESPACE_CHARSET}]*)(([^\-a-zA-Zа-яёА-ЯЁ0-9#{WHITESPACE_CHARSET}]|-(?![a-zA-Zа-яёА-ЯЁ0-9#{WHITESPACE_CHARSET}]))+)([#{WHITESPACE_CHARSET}]*)/o) and
          tokens << PunctuationMark.new("#{to_single_whitespace(s[1])}#{s[2]}#{to_single_whitespace(s[4])}") ) or
      # White-space.
      (
        s.skip(/#{WHITESPACE_CHARSET}+/o)
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
  WHITESPACE_CHARSET = "[\u0009-\u000D\u0020\u0085\u00A0\u1680\u180E\u2000-\u200A\u2028\u2029\u202F\u205F\u3000]"
  
  # Accessible to #tokenize() only.
  def to_single_whitespace(str)
    if str.empty? then ""
    else " "
    end
  end
  
end
