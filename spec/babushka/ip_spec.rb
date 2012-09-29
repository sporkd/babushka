require 'spec_helper'

describe "IP" do
  it "should accept IPs, arrays and strings" do
    IP.new(IP.new('10.0.1.1')).to_s.should == '10.0.1.1'
    IP.new([10, 0, 1, 1]).to_s.should == '10.0.1.1'
    IP.new('10.0.1.1').to_s.should == '10.0.1.1'
  end
  it "should work for valid IPs" do
    [
      '10.0.1.1',
      '192.168.0.1',
      '174.129.110.43'
    ].each {|string|
      IP.new(string).should be_valid
    }
  end
  it "should work for invalid IPs" do
    [
      '10.0.1.',
      '.10.0.1',
      '192.168.0',
      '192.168.0.c',
      '174.129.110.433'
    ].each {|string|
      IP.new(string).should_not be_valid
    }
  end
  describe "equality" do
    it "should be equal to equivalent IPs" do
      IP.new('10.0.1.1').should == IP.new([10, 0, 1, 1])
    end
    it "should not be equal to different IPs" do
      IP.new('10.0.1.1').should_not == IP.new('10.0.0.1')
      IP.new('10.0.1.1').should_not == IP.new('10.0.1')
    end
  end
  describe "#next" do
    it "should return the next IP in the range" do
      IP.new('10.0.1.1').next.to_s.should == '10.0.1.2'
      IP.new('10.0.1.255').next.to_s.should == '10.0.2.0'
      IP.new('10.13.37.1').next.to_s.should == '10.13.37.2'
    end
  end
  describe "#prev" do
    it "should return the previous IP in the range" do
      IP.new('10.0.1.2').prev.to_s.should == '10.0.1.1'
      IP.new('10.0.2.0').prev.to_s.should == '10.0.1.255'
      IP.new('10.13.37.255').prev.to_s.should == '10.13.37.254'
    end
  end
end

describe "IPRange" do
  it "should work for valid IPs" do
    [
      '10.0.1.x',
      '10.0.x',
      '174.129.x.x'
    ].each {|string|
      IPRange.new(string).should be_valid
    }
  end
  it "should work for invalid IPs" do
    [
      '10.0.1.1',
      '10.0.x.1',
      '10.0.x.',
      '174.129.110.',
      '174.129.x.43'
    ].each {|string|
      IPRange.new(string).should_not be_valid
    }
  end
  it "should collapse multiple wildcards" do
    IPRange.new('10.0.1.x').bytes.should == [10, 0, 1, 'x']
    IPRange.new('10.x').bytes.should == [10, 'x']
    IPRange.new('10.x.x.x').bytes.should == [10, 'x']
    IPRange.new('10.0.x').bytes.should == [10, 0, 'x']
    IPRange.new('10.0.x.x').bytes.should == [10, 0, 'x']
  end
  describe "#padded_bytes" do
    it "should pad the ranges back out to 4 terms" do
      IPRange.new('10.0.1.x').padded_bytes.should == [10, 0,   1,   'x']
      IPRange.new('10.x').padded_bytes.should     == [10, 'x', 'x', 'x']
      IPRange.new('10.x.x.x').padded_bytes.should == [10, 'x', 'x', 'x']
      IPRange.new('10.0.x').padded_bytes.should   == [10, 0,   'x', 'x']
      IPRange.new('10.0.x.x').padded_bytes.should == [10, 0,   'x', 'x']
    end
  end
  describe "#first" do
    it "should return the first IP in the range" do
      IPRange.new('10.0.x').first.should == IP.new('10.0.0.1')
      IPRange.new('10.13.37.x').first.should == IP.new('10.13.37.1')
    end
  end
  describe "#last" do
    it "should return the last IP in the range" do
      IPRange.new('10.0.x').last.should == IP.new('10.0.255.255')
      IPRange.new('10.13.37.x').last.should == IP.new('10.13.37.255')
    end
  end
  describe "#ip_for" do
    it "should combine network and address parts" do
      IPRange.new('10.0.1.x').ip_for('x.x.x.1').should == IP.new('10.0.1.1')
      IPRange.new('10.13.37.x').ip_for('x.254').should == IP.new('10.13.37.254')
    end
    it "should default uncovered sections to 0" do
      IPRange.new('10.0.x').ip_for('x.x.x.1').should == IP.new('10.0.0.1')
      IPRange.new('10.x').ip_for('x.254').should == IP.new('10.0.0.254')
    end
  end
  describe "#subnet" do
    it "should return the subnet mask" do
      IPRange.new('10.0.1.x').subnet.should == '255.255.255.0'
      IPRange.new('10.x')    .subnet.should == '255.0.0.0'
      IPRange.new('10.x.x.x').subnet.should == '255.0.0.0'
      IPRange.new('10.0.x')  .subnet.should == '255.255.0.0'
      IPRange.new('10.0.x.x').subnet.should == '255.255.0.0'
    end
  end
  describe "#broadcast" do
    it "should return the broadcast address" do
      IPRange.new('10.0.1.x').broadcast.should == '10.0.1.255'
      IPRange.new('10.x')    .broadcast.should == '10.255.255.255'
      IPRange.new('10.x.x.x').broadcast.should == '10.255.255.255'
      IPRange.new('10.0.x')  .broadcast.should == '10.0.255.255'
      IPRange.new('10.0.x.x').broadcast.should == '10.0.255.255'
    end
  end
end
