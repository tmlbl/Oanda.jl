const GAP_TOLERANCE = 3 # Candles

# Finds significant gaps in candle data and returns them as tuples of datetimes
function validate(cans::Candles)
  println("Validating candles from $(first(cans.series.timestamp)) ",
    "to $(last(cans.series.timestamp))")
  ret = Tuple[]
  g = granularities[cans.granularity]

  cur = first(cans.series.timestamp)
  for c in cans.series.timestamp[2:end]
    gap = c - cur
    if gap > Millisecond(g)
      gap_width = Int(floor(Int(gap) / Int(Millisecond(g))))
      if gap_width > GAP_TOLERANCE
        println("Gap detected: $gap_width candles")
        push!(ret, (cur, c))
      end
    end
    cur = c
  end
  ret
end

function candles(inst::Symbol, gran::Symbol, from::DateTime,  to::DateTime)
  # Estimate the candles that should exist
  g = granularities[gran]
  println("Interval is $g")
  numcandles = Int(floor((to - from) / Millisecond(g)))
  println("There should be $numcandles $gran candles from $from to $to")
  cans = db_candles(inst, gran, from, to)
  # If the number in the db does not match the target, figure out what is missing
  # Apparently it is not uncommon to see many gaps of 1 or 2 candles, so this
  # number does not line up for minute-by-minute data at least
  println("Got $(length(cans.series)) candles from db")
  if length(cans.series) < numcandles
    gaps = validate(cans)
    if length(gaps) > 0
      cans = oa_candles(inst, gran, from, to)
    end
  end
  cans
end
