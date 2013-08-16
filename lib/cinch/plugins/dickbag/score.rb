class Score < Cinch::Plugins::Dickbag
  attr_accessor :nick, :time, :count

  def initialize(nick, options = {})
    @nick = nick
    @count = options.delete(:count) || 0
    @time = options.delete(:time) || 0
  end

  def to_yaml
    { nick: @nick, time: @time, count: @count }
  end

  def save
    storage = CinchStorage.new(@@score_file)
    storage.data[:stats] ||= Hash.new
    storage.data[:stats][self.nick] = self
    storage.save
  end

  def self.add_count(user, num = 1)
    score = Score.for_user(user) || Score.new(user)
    score.count += num
    score.save
  end

  def self.add_time(user, time)
    score = Score.for_user(user) || Score.new(user)
    score.time += (Time.now - time)
    score.save
  end

  def self.full
    read_score_file
  end

  def self.for_user(nick)
    full[nick]
  end

  def self.board(type, count = 5)
    board = Score.full.values.sort {|a,b| b.send(type) <=> a.send(type) }
    board[0..(count - 1)]
  end

  def self.top_by(type)
    board(type, 1).first
  end

  private

  def self.read_score_file
    storage = CinchStorage.new(@@score_file)
    unless storage.data[:stats]
      storage.data[:stats] ||= Hash.new
      storage.save
    end
    return storage.data[:stats]
  end
end
