using HTTPClient,
      HttpCommon

include("db.jl")

const baseuri = "http://api-sandbox.oanda.com/v1/"
const defheaders = [("X-Accept-Datetime-Format", "UNIX")]

function oa_err(res::Response)
  print_with_color(:red, res.data)
end

function oa_request(resource::String, params::Tuple{String,Any}...)
  query = qstring(params...)
  uri = string(baseuri, resource, query)
  # println(uri)
  res = get(uri, headers = defheaders)
  if res.http_code != 200
    oa_err(res)
  end
  res
end

function oa_series(inst::Symbol, gran::Symbol, from::DateTime, to::DateTime)
  println("Requesting candles from $from to $to")
  res = oa_request("candles", ("start", from), ("end", to),
    ("instrument", inst), ("granularity", gran))

  candle_data = JSON.parse(bytestring(res.body))["candles"]

  timestamps = Array{DateTime,1}(length(candle_data))
  colnames = ASCIIString["openBid", "openAsk", "closeBid", "closeAsk",
    "highBid", "highAsk", "lowBid", "lowAsk"]
  values = zeros(length(candle_data),8)

  for i = 1:length(candle_data)
    c = candle_data[i]

    setindex!(timestamps,
      unix2datetime(Int64(parse(c["time"]) / 1000000)), i)

    values[i,1] = c["openBid"]
    values[i,2] = c["openAsk"]
    values[i,3] = c["closeBid"]
    values[i,4] = c["closeAsk"]
    values[i,5] = c["highBid"]
    values[i,6] = c["highAsk"]
    values[i,7] = c["lowBid"]
    values[i,8] = c["lowAsk"]
  end

  TimeArray(timestamps, values, colnames)
end

roundup(f::Float64) = Int(floor(f) < f ? floor(f + 1) : floor(f))

function combine(t1::TimeArray, t2::TimeArray)
  values = vcat(t1.values, t2.values)
  timestamps = vcat(t1.timestamp, t2.timestamp)
  TimeArray(timestamps, values, t1.colnames)
end

function num_candles(gran::Granularity, from::DateTime, to::DateTime)

end

function oa_candles(inst::Symbol, gran::Symbol, from::DateTime, to::DateTime)
  g = Granularity(gran)
  # to = round(to)
  # from = round(from)
  numcandles = Int(to - from) / toms(g.period)
  println("There should be $numcandles $gran candles from $from to $to")
  # If there are more than 5000 we need to request them in batches
  reqs = roundup(numcandles / 5000)
  println("We need to make $reqs request(s)")

  if reqs == 1
    series = oa_series(inst, gran, from, to)
  else
    interval = (to - from) / reqs
    println("interval $interval g $g")
    series = oa_series(inst, gran, from, from + interval)
    cur_time = from + interval + g.period
    for i = 2:reqs
      series = combine(series, oa_series(inst, gran, cur_time, cur_time + interval))
      cur_time += interval + g.period
    end
  end

  candles = Candles(inst, gran, series)
  save_candles(candles)
  candles
end
