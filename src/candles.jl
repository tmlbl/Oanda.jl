# Simple validation. If start and end times are covered by the
# data set, we call it good.
function validate(cans::Candles, from::DateTime, to::DateTime)
  valid = true
  g = granularities[cans.granularity]
  if !(first(cans.series.timestamp) <= (from + g))
    valid = false
  end
  if !(last(cans.series.timestamp) >= (to - g))
    valid = false
  end
  valid
end

function candles(inst::Symbol, gran::Symbol, from::DateTime,  to::DateTime)
  g = granularities[gran]
  # Try to get candles from the database first
  cans = db_candles(inst, gran, from, to)
  # See what we got and if we have to fetch
  if length(cans.series) < 1
    cans = oa_candles(inst, gran, from, to)
  else
    valid = validate(cans, from, to)
    if !valid
      cans = oa_candles(inst, gran, from, to)
    end
  end
  cans
end
