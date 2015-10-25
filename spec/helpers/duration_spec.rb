require 'spec_helper'
require 'volt/helpers/time'

describe Numeric do
  describe "#seconds" do
    it "returns 1 second for 1 second" do
      expect(1.second).to eq(1)
    end
    
    it "returns 1 minute for 60 seconds" do
      expect(60.seconds).to eq(1.minute)
    end
  end
  
  describe "#minutes" do
    it "returns 60 seconds for 1 minute" do
      expect(1.minute).to eq(60)
    end
    
    it "returns 1 hour for 60 minutes" do
      expect(60.minutes).to eq(1.hour)
    end
  end
  
  describe "#hours" do
    it "returns 3600 seconds for 1 hour" do
      expect(1.hour).to eq(3600)
    end
    
    it "returns 1 day for 1 day" do
      expect(24.hours).to eq(1.day)
    end
  end
  
  describe "#days" do
    it "returns 86400 seconds for 1 day" do
      expect(1.day).to eq(86400)
    end
    
    it "returns 1 week for 7 days" do
      expect(7.days).to eq(1.week)
    end
  end
  
  describe "#weeks" do
    it "returns 604800 seconds for 1 week" do
      expect(1.week).to eq(604800)
    end
    
    it "returns 1 fortnight for 2 weeks" do
      expect(2.weeks).to eq(1.fortnight)
    end
  end
  
  describe "#fortnights" do
    it "returns 1209600 for 1 fortnight" do
      expect(1.fortnight).to eq(1209600)
    end
  end
  
  describe "#months" do
    it "returns 2592000 for 1 month" do
      expect(1.month).to eq(2592000)
    end

  end
  
  describe "#years" do
    it "returns 31557600 for 1.year" do
      expect(1.year).to eq(31557600)
    end
    
    it "returns 730.5.days for 2.years" do
      expect(2.years).to eq(730.5.days)
    end
  end
end


describe Volt::Duration do
  
  describe "#+" do
    it "returns 3 seconds for 1 + 2 seconds" do
      expect(1.second + 2.seconds).to eq(3.seconds)
    end

    it "returns 3 mintues for 1 minute + 120 seconds" do
      expect(1.minute + 120.seconds).to eq(3.minutes)
    end
    
    it "returns 4 hours for 3 hours + 60 minutes" do
      expect(3.hours + 60.minutes).to eq(4.hours)
    end
    
    it "returns 3 days for 2 days + 24 hours" do
      expect(2.days + 24.hours).to eq(3.days)
    end
    
    it "returns 3 years for 1 year + 2 years" do
      expect(1.year + 2.years).to eq(3.years)
    end

  end
  
  describe "#since" do
    it "returns 1 day since the provided time" do
      expect(1.day.since(VoltTime.at(0))).to eq(VoltTime.new(:utc, 1970, 1, 2, 0, 0, 0))
    end
   
    it "returns 2 days (1 day + 24 hours) since the provided time" do
      expect((1.day + 24.hours).since(VoltTime.at(0))).to eq(VoltTime.new(:utc, 1970, 1, 3, 0, 0, 0))
    end
    
    it "returns 2 months since the provided time" do
      expect(2.months.since(VoltTime.at(0))).to eq(VoltTime.new(:utc, 1970, 3, 1, 0, 0, 0))
    end
    
    it "returns 3 years since the provided time" do
      expect(3.years.since(VoltTime.at(0))).to eq(VoltTime.new(:utc, 1973, 1, 1, 0, 0, 0))
    end
    
    it "returns 4 seconds since the provided time" do
      expect(4.seconds.since(VoltTime.at(0))).to eq(VoltTime.new(:utc, 1970, 1, 1, 0, 0, 4))
    end
    
    it "returns 1 week since the provided time" do
      expect(1.week.since(VoltTime.at(0))).to eq(VoltTime.new(:utc, 1970, 1, 8, 0, 0, 0))
    end
    
    it "returns 1 fortnight since the provided time" do
      expect(1.fortnight.since(VoltTime.at(0))).to eq(VoltTime.new(:utc, 1970, 1, 15, 0, 0, 0))
    end
    
    it "returns 24 hourse since the provided time" do
      expect(24.hours.since(VoltTime.at(0))).to eq(VoltTime.new(:utc, 1970, 1, 2, 0, 0, 0))
    end
  end
  
  describe "#ago" do
    it "returns 1 day before the provided time" do
      expect(1.day.ago(VoltTime.at(0))).to eq(VoltTime.new(:utc, 1969, 12, 31, 0, 0, 0))
    end
    
    it "returns 2 months before the provided time" do
      expect(2.months.ago(VoltTime.at(0))).to eq(VoltTime.new(:utc, 1969, 11, 1, 0, 0, 0))
    end
    
    it "returns 3 years before the provided time" do
      expect(3.years.ago(VoltTime.at(0))).to eq(VoltTime.new(:utc, 1967, 1, 1, 0, 0, 0))
    end
    
    it "returns 4 seconds before the provided time" do
      expect(4.seconds.ago(VoltTime.at(0))).to eq(VoltTime.new(:utc, 1969, 12, 31, 23, 59, 56))
    end
    
    it "returns 1 week before the provided time" do
      expect(1.week.ago(VoltTime.at(0))).to eq(VoltTime.new(:utc, 1969, 12, 25, 0, 0, 0))
    end
  end
end
