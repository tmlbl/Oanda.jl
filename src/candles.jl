function candles(instrument::Symbol, granularity::Symbol, from::DateTime, to::DateTime)
  i = instruments[instrument]
  g = granularities[granularity]

  cans = db_candles(instrument, granularity, from, to)
end
