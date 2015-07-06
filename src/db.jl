using LevelDB

db = open_db("/tmp/oanda_dev", true)

Base.serialize(candles::Candles) = begin
  batch = create_write_batch()
  for c in candles.series
    val = join(map((x) -> c.(x), fieldnames(c)), "|")
    key = join([candles.symbol, candles.precision, c.time], "|")
    batch_put(batch, key, val, length(val))
  end
  write_batch(db, batch)
end

function getrange(from::DateTime, to::DateTime)
  # Check if the candle range is in db

end
