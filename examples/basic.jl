using Oanda

# A basic backtest of a "doji" candle strategy
# When we see a "doji", as defined by our parameters, we will place
# a trade in the opposite direction of momentum

const start_time = DateTime("2015-06-27T00:00:00")
const end_time = DateTime("2015-07-28T00:00:00")
const DOJI_SIZE = 0.1 # Price difference pip threshold
# For H1 candles we consider candles with an open / close difference of 0 pips
const SYMBOL = :EUR_USD
const GRAN = :H1

# Fetch the historical data
c = candles(SYMBOL, GRAN, start_time, end_time)
@show c

# Play the data back
ctr = 0

for c in playback(SYMBOL, GRAN, start_time, end_time)
  # Ask and bid price differences
  ask_diff = floor((c.closeAsk - c.openAsk) * 10000)
  bid_diff = floor((c.closeBid - c.openBid) * 10000)
  # Check if they are below the threshold
  isdoji = false
  for diff in [ask_diff, bid_diff]
    if abs(diff) < DOJI_SIZE
      isdoji = true
    end
  end
  println(c.time)
  if isdoji
    print("Doji: ")
    @show c
  end
end
