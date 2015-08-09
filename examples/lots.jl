using Oanda

# This just fetches a lot of S5 candles

const start_time = DateTime("2015-07-12T21:10:00")
const end_time = DateTime("2015-07-24T21:28:00")
const DOJI_SIZE = 0.1 # Price difference pip threshold
# For H1 candles we consider candles with an open / close difference of 0 pips
const SYMBOL = :EUR_USD
const GRAN = :M1

# Fetch / validate the historical data
# Run this once then comment out for faster iteration
c = oa_candles(SYMBOL, GRAN, start_time, end_time)
@show c

# Play the data back
ctr = 0

for c in playback(SYMBOL, GRAN, start_time, end_time)
  println(c)
  println(ctr)
  ctr += 1
end

println("Went through $ctr candles")
