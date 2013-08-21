require 'cinch'
require 'cinch-storage'
require 'cinch/cooldown'
require 'cinch/toolbox'
require 'time-lord'

module Cinch::Plugins
  class Dickbag
    include Cinch::Plugin

    @@score_file = 'yaml/dickbag_scores.yaml'
    @@bag_file   = 'yaml/dickbag_status.yaml'
    @@bot = @bot

    self.help = "Use .dickbag to get the bag, you know you want some tasty, tasty Dick's."
    enforce_cooldown

    def initialize(*args)
      super
      @@score_file = config[:score_file] if config.key?(:score_file)
      @@bag_file   = config[:bag_file]   if config.key?(:bag_file)
    end

    listen_to :action

    set(:prefix => '')

    match /^[!\.]dickbag$/,      method: :dickbag,  react_on: :channel
    match /^[!\.]dickbag info/,  method: :info
    match /^[!\.]dickbag stats/, method: :stats

    def listen(m)
      @bot.synchronize(:bag) do
        if Bag.current && m.user.nick == Bag.current.nick 
          action = m.action_message.match(/^(.*) (bag of dicks|dickbag)/)[1]
          if action.match(/noms|eats/)
            Bag.set_last(:nom, m.user.nick)
            Score.add_time(m.user.nick, Bag.current.time)
            Bag.clear_current
          end
        end
      end
    end

    def dickbag(m)
      @bot.synchronize(:bag) do
        new_nick = m.user.nick
        old_nick = Bag.current.nick if Bag.current
        if old_nick
          if old_nick == new_nick
            m.reply db_message(:same_user), true
          else
            m.channel.action db_message(:new_owner, { new: new_nick, old: old_nick })
            Score.add_time(old_nick, Bag.current.time)
            Score.add_count(new_nick, 1)
            Bag.give_to(new_nick)
          end
        else
          init_bag(m)
        end
      end
    end

    def stats(m)
      report_top_counts(m)
      user_rank(m, :count)
      m.user.msg "\n"
      report_top_times(m)
      user_rank(m, :time)
    end

    def info(m)
      if Bag.current.nick.nil?
        message = ['I am currently holding the bag of dicks.']
      else
        message = ["#{Bag.current.nick} is currently holding the bag of dicks."]
        message << "I gave it to them #{Bag.current.time.ago.to_words}."
        message << "The current bag has been shared by #{Bag.current.count} other people."
      end
      m.reply message.join(' '), true
    end

    private
    
    def report_top_counts(m, count = 5)
      m.user.msg "Top #{count} users by times they've had the bag:"
      Score.board(:count, count).each_with_index do |score, i|
        score_message(m, (i + 1), score.nick, score.count)
      end
    end

    def report_top_times(m, count = 5)
      m.user.msg "Top #{count} users by the total time they've had the bag:"
      Score.board(:time, count).each_with_index do |score, i|
        time = Cinch::Toolbox.time_format(score.time)
        score_message(m, (i + 1), score.nick, time)
      end
    end

    def user_rank(m, type)
      user = Score.for_user(m.user.nick)
      return if user.nil?
      unless user.ranks[type] < 5
        m.user.msg "--------------------------------------"
        data =  if type == :count
                  user.count
                else
                  Cinch::Toolbox.time_format(user.time)
                end
        score_message(m, user.ranks[:count], user.nick, data)
      end
    end

    def score_message(m, rank, nick, stat)
      m.user.msg ["#{rank}.", nick, '-', stat].join(' ')
    end

    def init_bag(m)
      if Bag.last[:action] == :nom
        m.channel.action db_message(:nom, { new: m.user.nick,
                                            old: Bag.last[:nick] })
        Bag.clear_last
      else
        m.channel.action db_message(:new, { new: m.user.nick })
      end
      Bag.give_to(m.user.nick)
      Score.add_count(m.user.nick, 1)
    end

    def db_message(event, data = nil)
      case event
      when :same_user
        [ 'you still have the bag of dicks. Chill the fuck out.',
          'ah I see you forgot that you already have the bag, how cute.',
          'I\'d steal it from you and give it back to you, but that just seems silly.'].
        shuffle.first
      when :new_owner
        [ "reaches over to #{data[:old]}, takes the bag of dicks, and hands it to #{data[:new]}",
          "grabs the bag from #{data[:old]} and gives it to #{data[:new]}",
          "distracts #{data[:old]} with cat gifs long enough for #{data[:new]} to grab the bag"].
        shuffle.first
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
