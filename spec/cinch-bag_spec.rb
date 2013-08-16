# -*- coding: utf-8 -*-
require 'spec_helper'

describe Cinch::Plugins::Dickbag do
  include Cinch::Test

  before(:all) do
    files = { score_file: '/tmp/score.yml', bag_file: '/tmp/bag.yml' }
    files.values.each do |file| 
      File.delete(file) if File.exist?(file)
    end
    @bot = make_bot(Cinch::Plugins::Dickbag, files)
  end

  it 'should not respond to private bag steal attemptsevents' do
    get_replies(make_message(@bot, '!dickbag')).
      should be_empty
  end

  it 'should allow users to get the bag' do
    get_replies(make_message(@bot, '!dickbag', { channel: '#foo', nick: 'joe' })).
      first.text.should == 'reaches down and grabs a new bag of dicks and hands it to joe'
  end

  it 'should allow players to steal the bag' do
    get_replies(make_message(@bot, '!dickbag', { channel: '#foo', nick: 'joe' }))
    reply = get_replies(make_message(@bot, '!dickbag', { channel: '#foo', nick: 'amy' })). first.text
    reply.should include("joe")
  end

end
