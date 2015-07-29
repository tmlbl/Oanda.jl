using Requests,
      HttpCommon

const baseuri = "http://api-sandbox.oanda.com/v1/"
const defheaders = Dict{String,String}("X-Accept-Datetime-Format" => "UNIX")

function oa_err(res::Response)
  print_with_color(:red, res.data)
end

function oa_request(resource::String, params::Tuple{String,Any}...)
  query = qstring(params...)
  uri = string(baseuri, "candles", query)
  println(uri)
  res = get(uri, headers = defheaders)
  if res.status != 200
    oa_err(res)
  end
  res
end

function oa_candles(instrument::Symbol, granularity::Symbol, from::DateTime, to::DateTime)

  res = oa_request("candles", ("start", from), ("end", to),
    ("instrument", instrument), ("granularity", granularity))

  candle_data = JSON.parse(res.data)["candles"]

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

  series = TimeArray(timestamps, values, colnames)
  Candles(instrument, granularity, series)
end
