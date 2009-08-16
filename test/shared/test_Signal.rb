#!/usr/bin/ruby

$: << "../lib"
$: << "../base/shared_lib"

require 'rubygems'
require 'runit/testcase'
require 'runit/cui/testrunner'
require 'system/signal'
require 'csv'

class SignalTest <  RUNIT::TestCase

  # 前準備
  def setup
  end

  # 後始末
  def teardown
  end

  def test_signal
    signals = [
      Signal::MovingAverage.new,
      Signal::WeightedMovingAverage.new,
      Signal::ExponentialMovingAverage.new,
      Signal::BollingerBands.new,
      Signal::BollingerBands.new {|datas| Signal.ema(datas) },
      Signal::Vector.new,
      Signal::Momentum.new,
      Signal::MACD.new,
      Signal::RSI.new,
      Signal::ROC.new
    ]
    signals.each {|s|
      puts "\n---" + s.class.to_s
      each {|rate|
        p s.next_data( rate  )
      }
    }

    signals = [
      Signal::DMI.new
    ]
    signals.each {|s|
      puts "\n---" + s.class.to_s
      each_rates {|rate|
        p s.next_data( rate  )
      }
    }
  end

  def each
    each_rates {|r|
      yield r.start
    }
  end
  def each_rates( )
    CSV.foreach( File.dirname(__FILE__) + "/rate.csv" ) {|row|
      yield Rate.new( row[0].to_f, row[1].to_f, row[2].to_f, row[3].to_f )
    }
  end

  Rate = Struct.new( :start, :end, :max, :min )
end