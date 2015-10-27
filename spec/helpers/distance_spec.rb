require 'spec_helper'
require 'volt/helpers/time'

describe Volt::Duration do
  it 'should return a sentence describing the time' do
    dist = 1.hour + 2.days + 1.month + 305.seconds + 1.5.days

    expect(dist.duration_in_words(nil, :seconds)).to eq('1 month, 3 days, 13 hours, 5 minutes, and 5 seconds')
  end

  it 'should show a recent_message and' do
    expect(0.seconds.duration_in_words).to eq('just now')
    expect(1.minute.duration_in_words).to eq('1 minute')
    expect(0.seconds.duration_in_words(nil)).to eq('just now')
  end

  it 'should trim to the unit count' do
    dist = 1.hour + 2.days + 1.month + 305.seconds + 1.5.days
    expect(dist.duration_in_words(3)).to eq('1 month, 3 days, and 13 hours')
    expect(dist.duration_in_words(2)).to eq('1 month and 3 days')
  end

  it 'should return distance in words' do
    time1 = (1.hours + 5.minutes).ago
    expect(time1.time_distance_in_words).to eq('1 hour and 5 minutes ago')

    time2 = VoltTime.now
    time3 = time2 - (3.hours + 1.day + 2.seconds)

    expect(time3.time_distance_in_words(time2, nil, :seconds)).to eq('1 day, 3 hours, and 2 seconds ago')

    time4 = 1.second.ago
    expect(time4.time_distance_in_words).to eq('just now')
  end
end