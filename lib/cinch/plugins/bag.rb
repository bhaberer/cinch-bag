# -*- encoding : utf-8 -*-
require 'cinch'
require 'cinch/storage'
require 'cinch/cooldown'
require 'cinch/toolbox'
require 'time-lord'

module Cinch::Plugins
  # Cinch plugin that you shouldn't use.
  class Bag
    include Cinch::Plugin
    @@bag_file    = 'yaml/bag.yml'
    @@score_file  = 'yaml/bag_status.yml'

    self.help = 'Use .dickbag to get the bag.'

    enforce_cooldown

    def initialize(*args)
      super
      @@bag_file    = config[:bag_file]   if config.key?(:bag_file)
      @@score_file  = config[:score_file] if config.key?(:score_file)
    end

    listen_to :channel

    set(prefix: /^[!\.]/)

    match(/dickbag$/,      method: :dickbag,  react_on: :channel)
    match(/dickbag info/,  method: :info)
    match(/dickbag stats/, method: :stats)

    def listen(m)
      @bot.synchronize(:bag) do
        if Item.current && m.user.nick == Item.current.nick && m.action_message
          action = m.action_message[/^(.*) (bag of dicks|dickbag)/, 1]
          if action && action.match(/noms|eats/)
            Item.set_last(:nom, m.user.nick)
            Score.add_time(m.user.nick, Item.current.time)
            Item.clear_current
          end
        end
      end
    end

    def dickbag(m)
      @bot.synchronize(:bag) do
        new_nick = m.user.nick
        old_nick = Item.current.nick unless Item.current.nil?
        if old_nick.nil?
          Item.init(m)
        else
          Item.move(m, new_nick, old_nick)
        end
      end
    end

    def stats(m)
      Score.report_top_counts(m)
      Score.user_rank(m, :count)
      m.user.msg "\n"
      Score.report_top_times(m)
      Score.user_rank(m, :time)
    end

    def info(m)
      if Item.current.nil? || Item.current.nick.nil?
        message = ['I am currently holding the bag of dicks.']
      else
        message = ["#{Item.current.nick} is holding the bag of dicks."]
        message << "I gave it to them #{Item.current.time.ago.to_words}."
        message << "The bag has been held by #{Item.current.count} people!"
      end
      m.reply message.join(' '), true
    end


    # rubocop:disable LineLength, MethodLength
    def self.db_message(event, data = nil)
      case event
      when :same_user
        ['you still have the bag. Chill the fuck out.',
         'ah I see you forgot that you already have the bag, how cute.',
         'I\'d steal it from you and give it back to you, but that just seems silly.']
          .shuffle.first
      when :new_owner
        ["reaches over to #{data[:old]}, takes the bag of dicks, and hands it to #{data[:new]}",
         "grabs the bag from #{data[:old]} and gives it to #{data[:new]}",
         "distracts #{data[:old]} with cat gifs long enough for #{data[:new]} to grab the bag"]
           .shuffle.first
      when :nom
        "grabs a new bag of dicks for #{data[:new]} since #{data[:old]} went all nomnomonom on the last one."
      when :hid
        "grabs a new bag of dicks for #{data[:new]} since the last one seems to have vanished."
      when :new
        "reaches down and grabs a new bag of dicks and hands it to #{data[:new]}"
      end
    end
  end
end
