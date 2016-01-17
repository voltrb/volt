require 'spec_helper'
require 'volt/helpers/time'


describe VoltTime do
   let(:vt0) { VoltTime.at(0) }
   let(:vt120) { VoltTime.at(120) }
   let(:rt0) { Time.at(0) }


   let(:local_beginning) do
      if rt0.utc_offset >= 0
        Time.new(1970, 1, 1)
      else
        Time.new(1969, 12, 31)
      end
  end

  let(:local_end) do
      if rt0.utc_offset >= 0
        Time.new(1970, 1, 1, 23, 59, 59.999)
      else
        Time.new(1969, 12, 31, 23, 59, 59.999)
      end
  end

  let(:local_middle) do
    if rt0.utc_offset >= 0
      Time.new(1970, 1, 1, 12, 0, 0)
    else
      Time.new(1969, 12, 31, 12, 0, 0)
    end
  end


  describe "#new" do
    it "assumes the time provided is utc" do
      expect(VoltTime.new(:utc, 1970, 1, 1, 0, 0, 0)).to eq(vt0)
    end

    it "assumes the time provided is local" do
      expect(VoltTime.new(:local, 1970, 1, 1, 0, 0, 0)).to eq(rt0 - rt0.utc_offset)
    end

  end

  describe "#+" do
    it "returns the time plus a second" do
      expect(vt0 + 1).to eq(VoltTime.at(1))
    end

    it "returns the time plus a duration" do
      expect(vt0 + 1.month).to eq(VoltTime.new(:utc, 1970, 2, 1))
    end
  end

  describe "#-" do
    it "returns the time minus a second" do
      expect(vt0 - 1).to eq(VoltTime.at(-1))
    end

    it "returns the seconds between two VoltTime object" do
      expect(VoltTime.at(100) - vt0).to eq(100)
    end

    it "returns the seconds between a VoltTime and a Time object" do
      expect(VoltTime.at(100) - vt0).to eq(100)
    end

    it "returns the time minus the duration" do
      expect(vt0 - 1.month).to eq(VoltTime.new(:utc, 1969, 12, 1))
    end
  end

  describe "#==" do
    it "returns true for two equal times" do
      expect((vt0 + 1) == VoltTime.at(1)).to eq(true)
    end

    it "returns false for a VoltTime and nil" do
      expect(VoltTime.at(1) == nil).to eq(false)
    end
  end

  describe "#<=>" do
    it "returns 0 for two equal times" do
      expect((vt0 + 1) <=> VoltTime.at(1)).to eq(0)
    end
  end

  describe "#local_strftime" do
    it "returns formatted local time" do
      if RUBY_PLATFORM == 'opal'
        expect(vt0.local_strftime("%d %m %Y")).to eq(local_beginning.strftime("%d %m %Y"))
      else
        expect { vt0.local_strftime("%d %m %Y") }.to raise_error
      end
    end
  end

  describe "#local_beginning_of_day" do
    it "returns the start of the local day i.e. 00:00:00" do

      if RUBY_PLATFORM == 'opal'
        expect(vt120.local_beginning_of_day).to eq(VoltTime.from_time(local_beginning))
      else
        expect { vt120.local_beginning_of_day }.to raise_error
      end
    end
  end

  describe "#local_end_of_day" do
    it "returns the end of the local day i.e. 23:59:59.999" do
        if RUBY_PLATFORM == 'opal'
          expect(vt120.local_end_of_day).to eq(VoltTime.from_time(local_end))
        else
          expect { vt120.local_end_of_day }.to raise_error
        end
    end
  end

  describe "#local_middle_of_day" do
    it "returns midday of the local day" do
      if RUBY_PLATFORM == 'opal'
        expect(vt120.local_middle_of_day).to eq(VoltTime.from_time(local_middle))
      else
        expect { vt120.local_middle_of_day }.to raise_error
      end
    end
  end

  describe "#local_seconds_since_midnight" do
    it "returns the number of seconds since local midnight" do
      if RUBY_PLATFORM == 'opal'
        expect(vt120.local_seconds_since_midnight).to eq(vt120 - VoltTime.from_time(local_beginning))
      else
        expect { vt120.local_seconds_since_midnight }.to raise_error
      end
    end
  end

  describe "#local_seconds_until_end_of_day" do
    it "returns the number of seconds to the end of the local day" do
      if RUBY_PLATFORM == 'opal'
        expect(vt120.local_seconds_until_end_of_day).to eq(VoltTime.from_time(local_end) - vt120)
      else
        expect { vt120.local_seconds_until_end_of_day }.to raise_error
      end
    end
  end

  describe "#local_all_day" do
    it "returns a Range for the whole day" do
      if RUBY_PLATFORM == 'opal'
         r = vt120.local_all_day
        expect(r.end - r.begin).to eq(86399.999)
        expect(r.end).to eq(VoltTime.from_time(local_end))
        expect(r.begin).to eq(VoltTime.from_time(local_beginning))
      else
        expect { vt120.local_all_day }.to raise_error
      end
    end
  end

  describe "#beginning_of_day" do
    it "returns the start of day i.e. 00:00:00" do
      expect(vt120.beginning_of_day).to eq(VoltTime.new(:utc, 1970, 01, 01, 0, 0, 0))
    end
  end

  describe "#end_of_day" do
    it "returns the end of day ie. 23:59:59" do
      expect(vt120.end_of_day).to eq(VoltTime.new(:utc, 1970, 01, 01, 23, 59, 59.999))
    end
  end

  describe "#seconds_since_midnight" do
    it "returns the number of seconds since 00:00:00" do
      expect(vt120.seconds_since_midnight).to eq(120)
    end
  end

  describe "#seconds_until_end_of_day" do
    it "returns the number of seconds to 23:59:59" do
      expect((vt120.seconds_until_end_of_day)).to eq(86399.999 - 120)
    end
  end

  describe "#ago" do
    it "returns a VoltTime for an integer number of seconds ago" do
      expect(VoltTime.at(30).ago(30)).to eq(VoltTime.new(:utc, 1970, 01, 01, 00, 00, 0))
    end
  end

  describe "#since" do
    it "returns a VoltTime for an integer number of seconds since the instance VoltTime" do
      expect(vt0.since(30)).to eq(VoltTime.new(:utc, 1970, 01, 01, 00, 00, 30))
    end
  end

  describe "#middle_of_day" do
    it "returns a VoltTime for the middle of the day" do
      expect(vt0.middle_of_day).to eq(VoltTime.new(:utc, 1970, 01, 01, 12, 0, 0))
    end
  end

  describe "#beginning_of_hour" do
    it "returns a VoltTime for the beginning of the current hour" do
      expect(VoltTime.at(90).beginning_of_hour).to eq(VoltTime.new(:utc, 1970, 01, 01, 0, 0, 0))
    end
  end

  describe "#end_of_hour" do
    it "returns a VoltTime for the end of the current hour" do
      expect(vt0.end_of_hour).to eq(VoltTime.new(:utc, 1970, 01, 01, 00, 59, 59.999))
    end
  end

  describe "#beginning_of_minute" do
    it "returns a VoltTime for the beginning of the current minute" do
      expect(VoltTime.at(30).beginning_of_minute).to eq(VoltTime.new(:utc, 1970, 01, 01, 00, 00, 0))
    end
  end

  describe "#end_of_minute" do
    it "returns a VoltTime for the end of the current minute" do
      expect(vt0.end_of_minute).to eq(VoltTime.new(:utc, 1970, 01, 01, 00, 00, 59.999))
    end
  end

  describe "#all_day" do
    it "returns a Range for the whole day" do
      r = VoltTime.at(100).all_day
      expect(r.end - r.begin).to eq(86399.999)
    end
  end

  describe "#days_in_month" do
    it "returns the number of days in March" do
      expect(VoltTime.days_in_month(3)).to eq(31)
    end

    it "returns the number of days in Feb leap year" do
      expect(VoltTime.days_in_month(2, 2016)).to eq(29)
    end
  end

  describe "#local_offset" do
    it "returns the offset from UTC of the local time" do
      expect(vt0.local_offset).to eq(Time.at(0).utc_offset)
    end
  end

  describe "#compare and #compare?" do
    it "checks if the years are the same" do
      expect(vt0.compare(VoltTime.at(10000), :year)).to eq(0)
      expect(vt0.compare?(VoltTime.at(10000), :year)).to be true
    end

    it "checks if the months are the same" do
      expect(vt0.compare(VoltTime.new(:utc, 1970, 1, 30), :month)).to eq(0)
      expect(vt0.compare?(VoltTime.new(:utc, 1970, 1, 30), :month)).to be true
    end

    it "checks if the day is the same" do
      expect(vt0.compare(VoltTime.new(:utc, 1971, 1,1), :day)).to eq(-1)
      expect(vt0.compare?(VoltTime.new(:utc, 1971, 1,1), :day)).to be false
    end

    it "checks if the minute is the same" do
      expect(VoltTime.at(61).compare(VoltTime.at(0), :min)).to eq(1)
      expect(VoltTime.at(61).compare?(VoltTime.at(0), :min)).to be false
    end

  end



end
