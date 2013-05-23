require 'cinch-storage'
require 'cinch-cooldown'
require 'cinch-toolbox'
require 'time-lord'

module Cinch::Plugins
  class Bag
    include Cinch::Plugin

    self.help = "Use .dickbag to get the bag, you know you want some tasty, tasty Dick's."

    enforce_cooldown

    def initialize(*args)
      super
      @storage = CinchStorage.new(config[:filename] || 'yaml/dickbag.yaml')
      @storage.data[:current] ||= Hash.new
      @storage.data[:last]    ||= Hash.new
      @storage.data[:stats]   ||= Hash.new
    end

    listen_to :channel

    set(:prefix => '')

    match /^[!\.]dickbag$/,      method: :dickbag
    match /^[!\.]dickbag info/,  method: :info
    match /^[!\.]dickbag stats/, method: :stats

    def listen(m)
      if m.user.nick == @storage.data[:current][:nick] &&
         m.action_message &&
         m.action_message.match(/(bag of dicks|dickbag)/)

        action = m.action_message.match(/^(.*) (bag of dicks|dickbag)/)[1]
        if action.match(/noms|eats|hides/)
          @storage.data[:last] = { :action => action.match(/hides/) ? 'hid' : 'nom',
                                   :nick => m.user.nick}
          add_stat_time(m.user.nick, @storage.data[:current][:time])
          @storage.data[:current] = Hash.new
        end

        synchronize(:save_dickbag) do
          @storage.save
        end
      end
    end

    def dickbag(m)
      if m.channel.nil?
        m.user.msg "You must use that command in the main channel."
        return
      end

      current_nick = @storage.data[:current][:nick]
      current_time = @storage.data[:current][:time]

      if current_nick
        if current_nick == m.user.nick
          m.reply db_message(:same_user), true
        else
          m.channel.action db_message(:new_owner, { :new => m.user.nick, :old => current_nick })
          add_stat_time(current_nick, current_time)
          add_stat_count(m.user.nick, 1)
          give_bag_to(m.user.nick, @storage.data[:current][:times_passed] + 1)
        end
      elsif @storage.data[:last].key?(:action)
        case @storage.data[:last][:action]
        when 'nom'
          m.channel.action db_message(:nom, { :new => m.user.nick, :old => @storage.data[:last][:nick] })
        when 'hid'
          m.channel.action db_message(:hid, { :new => m.user.nick })
        else
          m.channel.action db_message(:new_owner, { :new => @storage.data[:last][:nick],
                                                    :old => current_nick })
        end

        give_bag_to(m.user.nick)
        @storage.data[:last] = {}
        add_stat_count(m.user.nick, 1)
      else
        m.channel.action db_message(:new, { :new => m.user.nick })
        give_bag_to(m.user.nick)
        add_stats(m.user.nick, 1)
      end

      synchronize(:save_dickbag) do
        @storage.save
      end
    end

    def stats(m)
      stats = []
      @storage.data[:stats].each_pair do |nick,info|
        stats << { :nick => nick, :time => info[:time], :count => info[:count] }
      end

      stats.sort! {|x,y| y[:count] <=> x[:count] }
      m.user.msg "Top 5 users by times they've had the bag:"
      stats[0..4].each_index do |i|
        m.user.msg "#{i + 1}. #{stats[i][:nick]} - #{stats[i][:count]}"
      end

      stats.sort! {|x,y| y[:time] <=> x[:time] }
      m.user.msg "Top 5 users by the total time they've had the bag:"
      stats[0..4].each_index do |i|
        m.user.msg "#{i + 1}. #{stats[i][:nick]} - #{Cinch::Toolbox.time_format(stats[i][:time])}"
      end
    end

    def info(m)
      if @storage.data[:current].key?(:nick)
        message = ["#{@storage.data[:current][:nick]} is"]
      else
        message = ['I am']
      end
      message << 'currently holding the bag of dicks.'

      if @storage.data[:current].key?(:time)
        message << "I gave it to them #{@storage.data[:current][:time].ago.to_words}."
      end

      unless @storage.data[:current].key?(:times_passed)
        message << "The current bag has been shared by #{@storage.data[:current][:times_passed]} other people."
      end

      top = get_top_users

      unless top.nil?
        if top.key?(:count)
          message << "#{top[:count][:nick]} has had the bag the most times at #{top[:count][:number]}."
        elsif top.key?(:time)
          message << "#{top[time][:nick]} has held the bag for the longest time at #{Cinch::Toolbox.time_format(top[:time][:number])}."
        end
      end

      m.reply message.join(' '), true
    end

    private

    def give_bag_to(user, count = 0)
      @storage.data[:current] = { :nick => user, :time => Time.now, :times_passed => count }
    end

    def add_stat_count(user, num = 1)
      add_stats(user, num, nil)
    end

    def add_stat_time(user, time)
      add_stats(user, nil, time)
    end

    def add_stats(user, count = nil, time = nil)
      unless @storage.data[:stats].key?(user)
        @storage.data[:stats][user] = { :count => 0, :time => 0 }
      end

      @storage.data[:stats][user][:count] += count              unless count.nil?
      @storage.data[:stats][user][:time]  += (Time.now - time)  unless time.nil?
    end

    def get_top_users
      counts = @storage.data[:stats].sort {|a,b| b[1][:count] <=> a[1][:count] }
      times = @storage.data[:stats].sort {|a,b| b[1][:time] <=> a[1][:time] }
      { :count => { :nick => counts.first[0], :number => counts.first[1][:count] },
        :time  => { :nick => times.first[0],  :number => times.first[1][:time] }}
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
