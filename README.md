# Markov chain chat bot

A chat bot utilizing Markov chains. It speaks Russian and English.

<!-- exclude from gem -->

## How to build

- Install [Ruby](http://ruby-lang.org) 1.9.1 or latest.
- Give command `rake` in this directory.
- You have got a [Ruby gem](http://rubygems.org/)!

<!-- end -->

## Examples

Basic usage:

    require 'markov_chain_chat_bot2'
    
    bot = MarkovChainChatBot2.from(Hash.new)
    bot.learn("one two three two one")
    bot.answer("count up and down please")
      #=> "one two three two three two one two one two three two one two one"
    bot.learn("three four six")
    bot.answer("count from three please")
      #=> "three two one two one two three four six"

One may save the bot's knowledge into key-value storage:

    require 'markov_chain_chat_bot2'
    require 'auto_marshalling_map'
    require 'gdbm'
    
    # 1.
    kvs = GDBM.open("chat_bot.dat")
    bot = MarkovChainChatBot2.from(AutoMarhsallingMap.new(kvs))
    bot.learn("one two three two one")
    kvs.close()
    
    # 2.
    kvs = GDBM.open("chat_bot.dat")
    bot = MarkovChainChatBot2.from(AutoMarhsallingMap.new(kvs))
    bot.answer("count up and down please")
      #=> "one two three two three two three two one two one"

<!-- exclude from gem -->

## Credits

- Gem name: markov_chain_chat_bot
- Version: 0.1.5
- License: Public Domain
- Authors: Lavir the Whiolet
- E-mail: Lavir.th.Whiolet@gmail.com
- Homepage: https://github.com/LavirtheWhiolet/markov-chain-bot-module

<!-- end -->
