require 'spec_helper'
require 'volt/helpers/time'


describe Volt::VoltTime do
  
  describe "#new" do
    it "assumes the time provided is utc" do
      expect(Volt::VoltTime.new(1970, 1, 1, 0, 0, 0, :utc)).to eq(Volt::VoltTime.at(0))
    end
    
    it "assumes the time provided is local" do
      expect(Volt::VoltTime.new(1970, 1, 1, 0, 0, 0, :local)).to eq(::Time.at(0) - ::Time.at(0).utc_offset)
    end
    
    it "assumes that the date provided is utc" do
      expect(Volt::VoltTime.new(1970)).to eq(Volt::VoltTime.at(0))
    end
    
    it "raises an ArgumentError is a time is specified without zone" do
      expect { Volt::VoltTime.new(1970,1,1,0,0,0) }.to raise_error(ArgumentError)
    end
  end
  
  describe "#+" do
    it "returns the time plus a second" do
      expect(Volt::VoltTime.at(0) + 1).to eq(Volt::VoltTime.at(1))
    end
  end
  
  describe "#-" do
    it "returns the time minus a second" do
      expect(Volt::VoltTime.at(0) - 1).to eq(Volt::VoltTime.at(-1))
    end
    
    it "returns the seconds between two VoltTime object" do
      expect(Volt::VoltTime.at(100) - Volt::VoltTime.at(0)).to eq(100)
    end
    
    it "returns the seconds between a VoltTime and a Time object" do
      expect(Volt::VoltTime.at(100) - Time.at(0)).to eq(100)
    end
  end
  
  describe "#==" do
    it "returns true for two equal times" do
      expect((Volt::VoltTime.at(0) + 1) == Volt::VoltTime.at(1)).to eq(true)
    end
  end
  
  describe "#<=>" do
    it "returns 0 for two equal times" do
      expect((Volt::VoltTime.at(0) + 1) <=> Volt::VoltTime.at(1)).to eq(0)
    end
  end
  
  describe "#local_strftime" do
    it "returns formatted local time" do
      expect(Volt::VoltTime.at(0).local_strftime("%d %m %Y")).to eq("31 12 1969")
    end
  end
  
  describe "#beginning_of_day" do
    it "returns the start of day i.e. 00:00:00" do
      expect(Volt::VoltTime.at(120).beginning_of_day).to eq(Volt::VoltTime.new(1970, 01, 01, 0, 0, 0, :utc))
    end
  end
  
  describe "#end_of_day" do
    it "returns the end of day ie. 23:59:59" do
      expect(Volt::VoltTime.at(120).end_of_day).to eq(Volt::VoltTime.new(1970, 01, 01, 23, 59, 59.999, :utc))
    end
  end
  
  describe "#seconds_since_midnight" do
    it "returns the number of seconds since 00:00:00" do
      expect(Volt::VoltTime.at(120).seconds_since_midnight).to eq(120)
    end
  end
  
  describe "#seconds_until_end_of_day" do
    it "returns the number of seconds to 23:59:59" do
      expect((Volt::VoltTime.at(120).seconds_until_end_of_day)).to eq(86399.999 - 120)
    end
  end

  describe "#ago" do
    it "returns a Volt::VoltTime for an integer number of seconds ago" do
      expect(Volt::VoltTime.at(30).ago(30)).to eq(Volt::VoltTime.new(1970, 01, 01, 00, 00, 0, :utc))
    end
  end
  
  describe "#since" do
    it "returns a Volt::VoltTime for an integer number of seconds since the instance Volt::VoltTime" do
      expect(Volt::VoltTime.at(0).since(30)).to eq(Volt::VoltTime.new(1970, 01, 01, 00, 00, 30, :utc))
    end
  end
  
  describe "#middle_of_day" do
    it "returns a Volt::VoltTime for the middle of the day" do
      expect(Volt::VoltTime.at(0).middle_of_day).to eq(Volt::VoltTime.new(1970, 01, 01, 12, 0, 0, :utc))
    end
  end
  
  describe "#beginning_of_hour" do
    it "returns a Volt::VoltTime for the beginning of the current hour" do
      expect(Volt::VoltTime.at(90).beginning_of_hour).to eq(Volt::VoltTime.new(1970, 01, 01, 0, 0, 0, :utc))
    end
  end
  
  describe "#end_of_hour" do
    it "returns a Volt::VoltTime for the end of the current hour" do
      expect(Volt::VoltTime.at(0).end_of_hour).to eq(Volt::VoltTime.new(1970, 01, 01, 00, 59, 59.999, :utc))
    end
  end
  
  describe "#beginning_of_minute" do
    it "returns a Volt::VoltTime for the beginning of the current minute" do
      expect(Volt::VoltTime.at(30).beginning_of_minute).to eq(Volt::VoltTime.new(1970, 01, 01, 00, 00, 0, :utc))
    end
  end
  
  describe "#end_of_minute" do
    it "returns a Volt::VoltTime for the end of the current minute" do
      expect(Volt::VoltTime.at(0).end_of_minute).to eq(Volt::VoltTime.new(1970, 01, 01, 00, 00, 59.999, :utc))
    end
  end
  
  describe "#all_day" do
    it "returns a Range for the whole day" do
      r = Volt::VoltTime.at(100).all_day
      expect(r.end - r.begin).to eq(86399.999)
    end 
  end
  
  describe "#days_in_month" do
    it "returns the number of days in March" do
      expect(Volt::VoltTime.days_in_month(3)).to eq(31)
    end
    
    it "returns the number of days in Feb leap year" do
      expect(Volt::VoltTime.days_in_month(2, 2016)).to eq(29)
    end
  end
  
  describe "#compare" do
    it "checks if the years are the same" do
      expect(Volt::VoltTime.at(0).compare(Volt::VoltTime.at(10000), :year)).to eq(0)
    end
    
    it "checks if the months are the same" do
      expect(Volt::VoltTime.new(1970,1,1).compare(Volt::VoltTime.new(1970, 1, 30), :month)).to eq(0)
    end
    
    it "checks if the day is the same" do
      expect(Volt::VoltTime.new(1970,1,1).compare(Volt::VoltTime.new(1971, 1,1), :day)).to eq(-1)
    end
    
    it "checks if the minute is the same" do
      expect(Volt::VoltTime.at(61).compare(Volt::VoltTime.at(0), :min)).to eq(1)
    end
    
  end

end