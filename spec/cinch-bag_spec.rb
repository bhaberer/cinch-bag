# -*- coding: utf-8 -*-
require 'spec_helper'

describe Cinch::Plugins::Bag do
  include Cinch::Test

  before(:each) do
    @files = { score_file: '/tmp/score.yml', bag_file: '/tmp/bag.yml' }
    @files.values.each do |file|
      File.delete(file) if File.exist?(file)
    end
    @bot = make_bot(Cinch::Plugins::Bag, @files)
  end

  it 'should not respond to private bag steal attemptsevents' do
    get_replies(make_message(@bot, '!dickbag')).
      should be_empty
  end

  it 'should allow users to get the bag' do
    get_replies(make_message(@bot, '!dickbag', { channel: '#foo', nick: 'joe' }))
    reply = get_replies(make_message(@bot, '!dickbag',
                                     { channel: '#foo', nick: 'joe' }))
              .first.text.gsub(/joe:\s/, '')
    ['you still have the bag. Chill the fuck out.',
     'ah I see you forgot that you already have the bag, how cute.',
     'I\'d steal it from you and give it back to you, but that just seems silly.']
      .should include(reply)
  end

  it 'should allow users to get the bag' do
    get_replies(make_message(@bot, '!dickbag', { channel: '#foo', nick: 'joe' })).
      first.text.should == 'reaches down and grabs a new bag of dicks and hands it to joe'
    Cinch::Plugins::Bag::Item.current.nick.should  == 'joe'
    Item.current.nick.should  == 'joe'
  end

  it 'should allow players to steal the bag' do
    get_replies(make_message(@bot, '!dickbag', { channel: '#foo', nick: 'joe' }))
    reply = get_replies(make_message(@bot, '!dickbag', { channel: '#foo', nick: 'amy' })). first.text
    Item.current.nick.
      should  == 'amy'
  end

  it 'should allow users to nom the bag' do
    get_replies(make_message(@bot, '!dickbag', { channel: '#foo', nick: 'joe' }))
    get_replies(make_message(@bot, 'noms the dickbag', { channel: '#foo', nick: 'joe' }), :action)
    # FIXME cinch-test needs to process action messages more better.
    # Item.last.should == :noms
  end

  it 'should give a info response' do
    message = get_replies(make_message(@bot, '!dickbag info', { channel: '#foo', nick: 'james' })).first.text
    message.should include('I am currently holding the bag')
  end

  it 'should give a info response' do
    get_replies(make_message(@bot, '!dickbag', { channel: '#foo', nick: 'joe' }))
    message = get_replies(make_message(@bot, '!dickbag info', { channel: '#foo', nick: 'james' })).first.text
    message.should include('james: joe is holding the bag')
  end

  it 'should allow users to get scoreboards' do
    get_replies(make_message(@bot, '!dickbag stats', { channel: '#foo', nick: 'james' }), :private).
      first.text.should == 'Top 5 users by times they\'ve had the bag:'
  end

  it 'should allow users to get scoreboards' do
    get_replies(make_message(@bot, '!dickbag', { channel: '#foo', nick: 'joe' }))
    sleep 2
    get_replies(make_message(@bot, '!dickbag', { channel: '#foo', nick: 'joel' }))
    sleep 2
    get_replies(make_message(@bot, '!dickbag', { channel: '#foo', nick: 'doe' }))
    sleep 2
    get_replies(make_message(@bot, '!dickbag', { channel: '#foo', nick: 'james' }))
    sleep 1
    get_replies(make_message(@bot, '!dickbag', { channel: '#foo', nick: 'jobe' }))
    sleep 2
    get_replies(make_message(@bot, '!dickbag', { channel: '#foo', nick: 'jaa' }))
    sleep 2
    get_replies(make_message(@bot, '!dickbag stats', { channel: '#foo', nick: 'james' }), :private)
      .length.should == 15
  end
end
