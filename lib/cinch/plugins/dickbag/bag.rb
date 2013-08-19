class Bag < Cinch::Plugins::Dickbag
  attr_accessor :nick, :time, :count

  def initialize(nick, options = {})
    @nick  = nick
    @time  = options.delete(:time)  || Time.now
    @count = options.delete(:count) || 0
  end

  def to_yaml
    { nick: @nick, time: @time, count: @count }
  end

  def self.load_data
    CinchStorage.new(@@bag_file)
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
    count = Bag.current.nil? ? 0 : Bag.current.count + 1
    Bag.current = Bag.new(user, { :count => count })
  end

  private

  def self.clear(node, default = Hash.new)
    storage = load_data
    storage.data[node] = default
    storage.save
  end
end
