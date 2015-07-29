# Uses LevelDB to create a cache of candle data for analysis
# and backtesting

using LevelDB

db = open_db("/tmp/oanda_dev", true)

function save_candles(candles::Candles)
  batch = create_write_batch()
  for i in candles.series
    val = join(i[2], '|')
    key = join([candles.symbol, candles.granularity, string(i[1])], '|')
    batch_put(batch, key, val, length(val))
  end
  write_batch(db, batch)
end

function unpack_candle(data::Array{Uint8})
  fields = split(bytestring(data), '|')
  parsedfields = map(parse, fields)
  Candle(parsedfields...)
end

function get_candles(symbol::String, granularity::String, from::DateTime, to::DateTime)
  r = db_range(db, join([symbol, granularity], '|'))

  timestamps = Array{DateTime,1}()
  colnames = ASCIIString["openBid", "openAsk", "closeBid", "closeAsk",
    "highBid", "highAsk", "lowBid", "lowAsk"]
  vals = Any[]

  for c in r
    t = DateTime(split(c[1], '|')[3])
    if t >= from && t <= to
      push!(timestamps, t)
      fields = split(bytestring(c[2]), '|')
      push!(vals, map(parse, fields))
    end
  end

  values = zeros(length(vals),8)
  println(length(values))

  for i in eachindex(vals)
    values[i,1] = vals[i][1]
    values[i,2] = vals[i][2]
    values[i,3] = vals[i][3]
    values[i,4] = vals[i][4]
    values[i,5] = vals[i][5]
    values[i,6] = vals[i][6]
    values[i,7] = vals[i][7]
    values[i,8] = vals[i][8]
  end

  series = TimeArray(timestamps, values, colnames)
  @show series
  Candles(symbol, granularity, series)
end
