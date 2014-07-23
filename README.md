<!-- summary -->
# Markov chain chat bot
<!-- end -->

<!-- description -->
A chat bot utilizing Markov chains. It speaks Russian and English.
<!-- end -->

<!-- exclude from gem -->

## Bureaucracy

<!-- bureaucracy -->
Gem name: markov_chain_chat_bot
Version: 0.0.1
License: Public Domain
<!-- end of bureaucracy -->

## How to compile

- Install [Ruby](http://ruby-lang.org) 1.9.1 or latest.
- Download [peg2rb.rb](https://github.com/LavirtheWhiolet/self-bootstrap/blob/master/peg2rb.rb) from [self-bootstrap](https://github.com/LavirtheWhiolet/self-bootstrap) into this directory. If you will not do this then the scripts will try to do it for you.
- Give command `rake` in this directory.
- You have got a [Ruby gem](http://rubygems.org/)!

<!-- end of exclusion-->

## Examples

Basic usage:

    require 'chat_bot'
    
    bot = ChatBot.from(Hash.new)
    bot.learn("one two three two one")
    bot.answer("count up and down please")
      #=> "one two three two three two one two one two three two one two one"
    bot.learn("three four six")
    bot.answer("count from three please")
      #=> "three two one two one two three four six"

One may save the bot's knowledge into key-value storage:

    require 'chat_bot'
    require 'auto_marshalling_map'
    require 'gdbm'
    
    # 1.
    kvs = GDBM.open("chat_bot.dat")
    bot = ChatBot.from(AutoMarhsallingMap.new(kvs))
    bot.learn("one two three two one")
    kvs.close()
    
    # 2.
    kvs = GDBM.open("chat_bot.dat")
    bot = ChatBot.from(AutoMarhsallingMap.new(kvs))
    bot.answer("count up and down please")
      #=> "one two three two three two three two one two one"
