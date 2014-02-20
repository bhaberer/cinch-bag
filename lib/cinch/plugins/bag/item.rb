# -*- encoding: utf-8 -*-
class Item < Cinch::Plugins::Bag
  attr_accessor :nick, :time, :count

  def initialize(nick, options = {})
    @nick  = nick
    @time  = options.delete(:time)  || Time.now
    @count = options.delete(:count) || 0
  end

  def self.load_data
    Cinch::Storage.new(@@bag_file)
  end

  def self.move(m, new_nick, old_nick)
    if old_nick == new_nick
      m.reply Cinch::Plugins::Bag.db_message(:same_user), true
    else
      m.channel
        .action Cinch::Plugins::Bag.db_message(:new_owner, new: new_nick, old: old_nick)
      Score.add_time(old_nick, Item.current.time)
      Score.add_count(new_nick, 1)
      Item.give_to(new_nick)
    end
  end

  def self.init(m)
    if Item.last[:action] == :nom
      m.channel.action Cinch::Plugins::Bag.db_message(:nom, new: m.user.nick,
                                        old: Item.last[:nick])
      Item.clear_last
    else
      m.channel.action Cinch::Plugins::Bag.db_message(:new, new: m.user.nick)
    end
    Item.give_to(m.user.nick)
    Score.add_count(m.user.nick, 1)
  end


  def self.current
    storage = load_data
    storage.data[:current]
  end

  def self.current=(bag)
    storage = load_data
    storage.data[:current] = bag
    storage.save
  end

  def self.last
    storage = load_data
    storage.data[:last] || {}
  end

  def self.set_last(action, nick)
    storage = load_data
    storage.data[:last] = { action: action, nick: nick }
    storage.save
  end

  def self.clear_current
    clear(:current, nil)
  end

  def self.clear_last
    clear(:last)
  end

  def self.give_to(user)
    @count = current.nil? ? 0 : current.count + 1
    self.current = new(user, count: @count)
  end

  private

  def self.clear(node, default = {})
    storage = load_data
    storage.data[node] = default
    storage.save
  end
end
