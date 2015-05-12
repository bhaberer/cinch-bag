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
    expect(get_replies(make_message(@bot, '!bag'))).to be_empty
  end

  it 'should allow users to get the bag' do
    get_replies(make_message(@bot, '!bag', { channel: '#foo', nick: 'joe' }))
    reply = get_replies(make_message(@bot, '!bag',
                                     { channel: '#foo', nick: 'joe' }))
              .first.text.gsub(/joe:\s/, '')
    expect(['you still have the bag. Chill the fuck out.',
            'ah I see you forgot that you already have the bag, how cute.',
            'I\'d steal it from you and give it back to you, but that just seems silly.']).to include(reply)
  end

  it 'should allow users to get the bag' do
    result = get_replies(make_message(@bot, '!bag', { channel: '#foo', nick: 'joe' }))
    expect(result.first.text).to eq('reaches down and grabs a new bag and hands it to joe')
    expect(Cinch::Plugins::Bag::Item.current.nick).to eq('joe')
    expect(Item.current.nick).to eq('joe')
  end

  it 'should allow players to steal the bag' do
    get_replies(make_message(@bot, '!bag', { channel: '#foo', nick: 'joe' }))
    reply = get_replies(make_message(@bot, '!bag', { channel: '#foo', nick: 'amy' })).first.text
    expect(Item.current.nick).to eq('amy')
  end

  it 'should allow users to nom the bag' do
    get_replies(make_message(@bot, '!bag', { channel: '#foo', nick: 'joe' }))
    get_replies(make_message(@bot, 'noms the bag', { channel: '#foo', nick: 'joe' }), :action)
    # FIXME cinch-test needs to process action messages more better.
    # Item.last.should == :noms
  end

  it 'should give a info response' do
    message = get_replies(make_message(@bot, '!bag info', { channel: '#foo', nick: 'james' })).first.text
    expect(message).to include('I am currently holding the bag')
  end

  it 'should give a info response' do
    get_replies(make_message(@bot, '!bag', { channel: '#foo', nick: 'joe' }))
    message = get_replies(make_message(@bot, '!bag info', { channel: '#foo', nick: 'james' })).first.text
    expect(message).to include('james: joe is holding the bag')
  end

  it 'should allow users to get scoreboards' do
    message = get_replies(make_message(@bot, '!bag stats', { channel: '#foo', nick: 'james' }), :private).first.text
    expect(message).to eq('Top 5 users by times they\'ve had the bag:')
  end

  it 'should allow users to get scoreboards' do
    get_replies(make_message(@bot, '!bag', { channel: '#foo', nick: 'joe' }))
    sleep 2
    get_replies(make_message(@bot, '!bag', { channel: '#foo', nick: 'joel' }))
    sleep 2
    get_replies(make_message(@bot, '!bag', { channel: '#foo', nick: 'doe' }))
    sleep 2
    get_replies(make_message(@bot, '!bag', { channel: '#foo', nick: 'james' }))
    sleep 1
    get_replies(make_message(@bot, '!bag', { channel: '#foo', nick: 'jobe' }))
    sleep 2
    get_replies(make_message(@bot, '!bag', { channel: '#foo', nick: 'jaa' }))
    sleep 2
    expect(get_replies(make_message(@bot, '!bag stats', { channel: '#foo', nick: 'james' }), :private).length).to eq(15)
  end
end
