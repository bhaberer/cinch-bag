# -*- encoding: utf-8 -*-
class Score < Cinch::Plugins::Bag
  attr_accessor :nick, :time, :count, :ranks

  def initialize(nick, options = {})
    @nick = nick
    @count = options.delete(:count) || 0
    @time = options.delete(:time) || 0
  end

  def save
    storage = Cinch::Storage.new(@@score_file)
    storage.data[:stats] ||= {}
    storage.data[:stats][nick] = self
    storage.save
    Score.process_leaderboard
  end

  def self.report_top_counts(m, count = 5)
    m.user.msg "Top #{count} users by times they've had the bag:"
    Score.board(:count, count).each_with_index do |score, i|
      score_message(m, (i + 1), score.nick, score.count)
    end
  end

  def self.report_top_times(m, count = 5)
    m.user.msg "Top #{count} users by the total time they've had the bag:"
    Score.board(:time, count).each_with_index do |score, i|
      time = Cinch::Toolbox.time_format(score.time)
      score_message(m, (i + 1), score.nick, time)
    end
  end

  def self.user_rank(m, type)
    user = Score.for_user(m.user.nick)
    return if user.nil?
    unless user.ranks[type] < 5
      m.user.msg '--------------------------------------'
      data =
        type == :count ? user.count : Cinch::Toolbox.time_format(user.time)
      score_message(m, user.ranks[:count], user.nick, data)
    end
  end

  def self.score_message(m, rank, nick, stat)
    m.user.msg ["#{rank}.", nick, '-', stat].join(' ')
  end

  def self.process_leaderboard
    storage = Cinch::Storage.new(@@score_file)
    storage.data[:stats] ||= {}

    # Clone the scores hash and process the entries.
    scores = storage.data[:stats].dup
    [:count, :time].each do |type|
      ranks = scores.to_a.map { |s| { nick: s[0], score: s[1].send(type) } }
      ranks = ranks.sort { |a, b| b[:score] <=> a[:score] }
      ranks.each_with_index do |score, i|
        scores[score[:nick]].ranks ||= { count: nil, time: nil }
        scores[score[:nick]].ranks[type] = i + 1
      end
    end

    storage.data[:stats] = scores
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
    board = Score.full.values.sort { |a, b| b.send(type) <=> a.send(type) }
    board[0..(count - 1)]
  end

  def self.rank_for(nick, type)
    Score.board(type, Score.full.count)
  end

  def self.top_by(type)
    board(type, 1).first
  end

  private

  def self.read_score_file
    storage = Cinch::Storage.new(@@score_file)
    unless storage.data[:stats]
      storage.data[:stats] ||= {}
      storage.save
    end
    storage.data[:stats]
  end
end
