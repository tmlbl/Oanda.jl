using Oanda

start_time = DateTime("2015-07-22T21:10:13")
end_time = DateTime("2015-07-28T21:28:13")

# Fetch some historical data
c = candles(:EUR_USD, :M1, start_time, end_time)
@show c

# Play the data back
playback(:EUR_USD, :M1, start_time, end_time) do prices
  @show prices
end
