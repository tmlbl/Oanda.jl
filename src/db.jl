# Uses LevelDB to create a cache of candle data for analysis
# and backtesting

using LevelDB

db = open_db("/tmp/oanda_dev", true)

function save_candles(candles::Candles)
  batch = create_write_batch()
  for c in candles.series
    val = join(map((x) -> c.(x), fieldnames(c)), "|")
    key = join([candles.symbol, candles.granularity, c.time], "|")
    batch_put(batch, key, val, length(val))
  end
  write_batch(db, batch)
end

function unpack_candle(data::Array{Uint8})
  fields = split(bytestring(data), '|')
  parsedfields = map(parse, fields)
  Candle(parsedfields...)
end

function getrange(symbol::String, granularity::String, from::DateTime, to::DateTime)
  r = db_range(db, join([symbol, granularity], '|'))
  series = Candle[]
  start_time = Dates.datetime2unix(from)
  end_time = Dates.datetime2unix(to)
  for c in r
    t = parse(split(c[1], '|')[3])
    if t >= start_time && t <= end_time
      println("Pulling $t")
      can = unpack_candle(c[2])
      push!(series, can)
    end
  end
  Candles(symbol, granularity, series)
end
