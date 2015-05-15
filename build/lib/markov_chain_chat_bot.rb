# encoding: UTF-8
require 'markov_chain'
require 'stringio'

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
    yy_parse(StringIO.new(text))
  end
  

      
      # 
      # +input+ is IO. It must have working IO#pos, IO#pos= and
      # IO#set_encoding() methods.
      # 
      # It may raise YY_SyntaxError.
      # 
      def yy_parse(input)
        input.set_encoding("UTF-8", "UTF-8")
        context = YY_ParsingContext.new(input)
        yy_from_pcv(
          yy_nonterm1(context) ||
          # TODO: context.worst_error can not be nil here. Prove it.
          raise(context.worst_error)
        )
      end

      # TODO: Allow to pass String to the entry point.
    
      
      # :nodoc:
      ### converts value to parser-compatible value (which is always non-false and
      ### non-nil).
      def yy_to_pcv(value)
        if value.nil? then :yy_nil
        elsif value == false then :yy_false
        else value
        end
      end
      
      # :nodoc:
      ### converts value got by #yy_to_pcv() to actual value.
      def yy_from_pcv(value)
        if value == :yy_nil then nil
        elsif value == :yy_false then false
        else value
        end
      end
      
      # :nodoc:
      class YY_ParsingContext
        
        # +input+ is IO.
        def initialize(input)
          @input = input
          @worst_error = nil
        end
        
        attr_reader :input
        
        # It is YY_SyntaxExpectationError or nil.
        attr_accessor :worst_error
        
        # adds possible error to this YY_ParsingContext.
        # 
        # +error+ is YY_SyntaxExpectationError.
        # 
        def << error
          # Update worst_error.
          if worst_error.nil? or worst_error.pos < error.pos then
            @worst_error = error
          elsif worst_error.pos == error.pos then
            @worst_error = @worst_error.or error
          end
          # 
          return self
        end
        
      end
      
      # :nodoc:
      def yy_string(context, string)
        # 
        string_start_pos = context.input.pos
        # Read string.
        read_string = context.input.read(string.bytesize)
        # Set the string's encoding; check if it fits the argument.
        unless read_string and (read_string.force_encoding(Encoding::UTF_8)) == string then
          # 
          context << YY_SyntaxExpectationError.new(yy_displayed(string), string_start_pos)
          # 
          return nil
        end
        # 
        return read_string
      end
      
      # :nodoc:
      def yy_end?(context)
        #
        if not context.input.eof?
          context << YY_SyntaxExpectationError.new("the end", context.input.pos)
          return nil
        end
        #
        return true
      end
      
      # :nodoc:
      def yy_begin?(context)
        #
        if not(context.input.pos == 0)
          context << YY_SyntaxExpectationError.new("the beginning", context.input.pos)
          return nil
        end
        #
        return true
      end
      
      # :nodoc:
      def yy_char(context)
        # 
        char_start_pos = context.input.pos
        # Read a char.
        c = context.input.getc
        # 
        unless c then
          #
          context << YY_SyntaxExpectationError.new("a character", char_start_pos)
          #
          return nil
        end
        #
        return c
      end
      
      # :nodoc:
      def yy_char_range(context, from, to)
        # 
        char_start_pos = context.input.pos
        # Read the char.
        c = context.input.getc
        # Check if it fits the range.
        # NOTE: c has UTF-8 encoding.
        unless c and (from <= c and c <= to) then
          # 
          context << YY_SyntaxExpectationError.new(%(#{yy_displayed from}...#{yy_displayed to}), char_start_pos)
          # 
          return nil
        end
        #
        return c
      end
      
      # :nodoc:
      ### The form of +string+ suitable for displaying in messages.
      def yy_displayed(string)
        if string.length == 1 then
          char = string[0]
          char_code = char.ord
          case char_code
          when 0x00...0x20, 0x2028, 0x2029 then %(#{yy_unicode_s char_code})
          when 0x20...0x80 then %("#{char}")
          when 0x80...Float::INFINITY then %("#{char} (#{yy_unicode_s char_code})")
          end
        else
          %("#{string}")
        end
      end
      
      # :nodoc:
      ### "U+XXXX" string corresponding to +char_code+.
      def yy_unicode_s(char_code)
        "U+#{"%04X" % char_code}"
      end
      
      class YY_SyntaxError < Exception
        
        def initialize(message, pos)
          super(message)
          @pos = pos
        end
        
        attr_reader :pos
        
      end
      
      # :nodoc:
      class YY_SyntaxExpectationError < YY_SyntaxError
        
        # 
        # +expectations+ are String-s.
        # 
        def initialize(*expectations, pos)
          super(nil, pos)
          @expectations = expectations
        end
        
        # 
        # returns other YY_SyntaxExpectationError with #expectations combined.
        # 
        # +other+ is another YY_SyntaxExpectationError.
        # 
        # #pos of this YY_SyntaxExpectationError and +other+ must be equal.
        # 
        def or other
          raise %(can not "or" #{YY_SyntaxExpectationError}s with different pos) unless self.pos == other.pos
          YY_SyntaxExpectationError.new(*(self.expectations + other.expectations), pos)
        end
        
        def message
          expectations = self.expectations.uniq
          (
            if expectations.size == 1 then expectations.first
            else [expectations[0...-1].join(", "), expectations[-1]].join(" or ")
            end
          ) + " is expected"
        end
        
        protected
        
        # Private
        attr_reader :expectations
        
      end
    
      # :nodoc:
      def yy_nonterm1(yy_context)
        val = nil
        (begin
       val = [] 
      true
    end and while true
      yy_vare = yy_context.input.pos
      if not(begin; yy_var9 = yy_context.input.pos; (begin
      yy_vara = yy_nontermf(yy_context)
      if yy_vara then
        w = yy_from_pcv(yy_vara)
      end
      yy_vara
    end and begin
       val << Word.new(w) 
      true
    end) or (yy_context.input.pos = yy_var9; (begin
      yy_varb = yy_nonterm14(yy_context)
      if yy_varb then
        p = yy_from_pcv(yy_varb)
      end
      yy_varb
    end and begin
       val << PunctuationMark.new(p) 
      true
    end)) or (yy_context.input.pos = yy_var9; yy_nonterm24(yy_context) and while true
      yy_vard = yy_context.input.pos
      if not(yy_nonterm24(yy_context)) then
        yy_context.input.pos = yy_vard
        break true
      end
    end); end) then
        yy_context.input.pos = yy_vare
        break true
      end
    end) and yy_to_pcv(val)
      end
    
      # :nodoc:
      def yy_nontermf(yy_context)
        val = nil
        (begin
       val = "" 
      true
    end and begin; yy_varp = yy_context.input.pos; begin
      yy_varq = yy_nontermx(yy_context)
      if yy_varq then
        val << yy_from_pcv(yy_varq)
      end
      yy_varq
    end or (yy_context.input.pos = yy_varp; (begin
      yy_varr = yy_string(yy_context, "-")
      if yy_varr then
        h = yy_from_pcv(yy_varr)
      end
      yy_varr
    end and begin
      yy_varu = yy_context.input.pos
      yy_varv = yy_nontermx(yy_context)
      yy_context.input.pos = yy_varu
      yy_varv
    end and begin
       val << h 
      true
    end)); end and while true
      yy_varw = yy_context.input.pos
      if not(begin; yy_varp = yy_context.input.pos; begin
      yy_varq = yy_nontermx(yy_context)
      if yy_varq then
        val << yy_from_pcv(yy_varq)
      end
      yy_varq
    end or (yy_context.input.pos = yy_varp; (begin
      yy_varr = yy_string(yy_context, "-")
      if yy_varr then
        h = yy_from_pcv(yy_varr)
      end
      yy_varr
    end and begin
      yy_varu = yy_context.input.pos
      yy_varv = yy_nontermx(yy_context)
      yy_context.input.pos = yy_varu
      yy_varv
    end and begin
       val << h 
      true
    end)); end) then
        yy_context.input.pos = yy_varw
        break true
      end
    end) and yy_to_pcv(val)
      end
    
      # :nodoc:
      def yy_nontermx(yy_context)
        val = nil
        begin; yy_vary = yy_context.input.pos; begin
      yy_varz = yy_char_range(yy_context, "a", "z")
      if yy_varz then
        val = yy_from_pcv(yy_varz)
      end
      yy_varz
    end or (yy_context.input.pos = yy_vary; begin
      yy_var10 = yy_char_range(yy_context, "A", "Z")
      if yy_var10 then
        val = yy_from_pcv(yy_var10)
      end
      yy_var10
    end) or (yy_context.input.pos = yy_vary; begin
      yy_var11 = yy_char_range(yy_context, "\u{430}", "\u{44f}")
      if yy_var11 then
        val = yy_from_pcv(yy_var11)
      end
      yy_var11
    end) or (yy_context.input.pos = yy_vary; begin
      yy_var12 = yy_char_range(yy_context, "\u{410}", "\u{42f}")
      if yy_var12 then
        val = yy_from_pcv(yy_var12)
      end
      yy_var12
    end) or (yy_context.input.pos = yy_vary; begin
      yy_var13 = yy_char_range(yy_context, "0", "9")
      if yy_var13 then
        val = yy_from_pcv(yy_var13)
      end
      yy_var13
    end); end and yy_to_pcv(val)
      end
    
      # :nodoc:
      def yy_nonterm14(yy_context)
        val = nil
        (begin
       val = "" 
      true
    end and while true
      yy_var1b = yy_context.input.pos
      if not(begin
      yy_var1a = yy_nonterm24(yy_context)
      if yy_var1a then
        val << yy_from_pcv(yy_var1a)
      end
      yy_var1a
    end) then
        yy_context.input.pos = yy_var1b
        break true
      end
    end and (begin
      yy_var1s = yy_context.worst_error
      yy_var1t = not(begin
      yy_var1u = yy_context.input.pos
      yy_var1v = yy_nontermx(yy_context)
      yy_context.input.pos = yy_var1u
      yy_var1v
    end)
      if yy_var1t
        yy_context.worst_error = yy_var1s
      else
        # NOTE: No errors were added into context but the error is still there.
        yy_context << YY_SyntaxExpectationError.new("different expression", yy_context.input.pos)
      end
      yy_var1t
    end and begin
      yy_var1w = yy_char(yy_context)
      if yy_var1w then
        val << yy_from_pcv(yy_var1w)
      end
      yy_var1w
    end) and while true
      yy_var1x = yy_context.input.pos
      if not((begin
      yy_var1s = yy_context.worst_error
      yy_var1t = not(begin
      yy_var1u = yy_context.input.pos
      yy_var1v = yy_nontermx(yy_context)
      yy_context.input.pos = yy_var1u
      yy_var1v
    end)
      if yy_var1t
        yy_context.worst_error = yy_var1s
      else
        # NOTE: No errors were added into context but the error is still there.
        yy_context << YY_SyntaxExpectationError.new("different expression", yy_context.input.pos)
      end
      yy_var1t
    end and begin
      yy_var1w = yy_char(yy_context)
      if yy_var1w then
        val << yy_from_pcv(yy_var1w)
      end
      yy_var1w
    end)) then
        yy_context.input.pos = yy_var1x
        break true
      end
    end and while true
      yy_var23 = yy_context.input.pos
      if not(begin
      yy_var22 = yy_nonterm24(yy_context)
      if yy_var22 then
        val << yy_from_pcv(yy_var22)
      end
      yy_var22
    end) then
        yy_context.input.pos = yy_var23
        break true
      end
    end) and yy_to_pcv(val)
      end
    
      # :nodoc:
      def yy_nonterm24(yy_context)
        val = nil
        (begin; yy_var27 = yy_context.input.pos; yy_char_range(yy_context, "\t", "\r") or (yy_context.input.pos = yy_var27; yy_string(yy_context, " ")) or (yy_context.input.pos = yy_var27; yy_string(yy_context, "\u{85}")) or (yy_context.input.pos = yy_var27; yy_string(yy_context, "\u{a0}")) or (yy_context.input.pos = yy_var27; yy_string(yy_context, "\u{1680}")) or (yy_context.input.pos = yy_var27; yy_string(yy_context, "\u{180e}")) or (yy_context.input.pos = yy_var27; yy_char_range(yy_context, "\u{2000}", "\u{200a}")) or (yy_context.input.pos = yy_var27; yy_string(yy_context, "\u{2028}")) or (yy_context.input.pos = yy_var27; yy_string(yy_context, "\u{2029}")) or (yy_context.input.pos = yy_var27; yy_string(yy_context, "\u{202f}")) or (yy_context.input.pos = yy_var27; yy_string(yy_context, "\u{205f}")) or (yy_context.input.pos = yy_var27; yy_string(yy_context, "\u{3000}")); end and begin
       val = " " 
      true
    end) and yy_to_pcv(val)
      end
      
end

