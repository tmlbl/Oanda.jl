
immutable CandleIterator
  inst::Instrument
  gran::Symbol
  start_time::DateTime
  end_time::DateTime
  range::LevelDB.Range
end

CandleIterator(inst::Symbol, gran::Symbol,
  start_time::DateTime, end_time::DateTime) = begin

  r = db_range(db, join(map(string,[inst, gran, from]), '|'))
  CandleIterator(instruments[inst], gran, start_time, end_time, r)
end

Base.start(ci::CandleIterator) = begin
  start(ci.range)
  false
end

Base.done(ci::CandleIterator, state) = begin
  done(ci.range, nothing)
  state
end

Base.next(ci::CandleIterator, state) = begin
  c = next(ci.range)
  keyparts = split(c[1][1], '|')
  fields = split(bytestring(c[1][2]), '|')

  Candle(map(float, fields)...), (string(keyparts[3]) >= string(ci.end_time))
end

function playback(inst::Symbol, gran::Symbol, from::DateTime, to::DateTime)
  return CandleIterator(inst, gran, from, to)
end
