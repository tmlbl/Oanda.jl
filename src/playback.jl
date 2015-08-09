
immutable CandleIterator
  inst::Instrument
  gran::Granularity
  start_time::DateTime
  end_time::DateTime
  range::LevelDB.Range
end

CandleIterator(inst::Symbol, gran::Symbol,
  start_time::DateTime, end_time::DateTime) = begin

  cur_str = join(map(string,[inst, gran, start_time]), '|')
  r = db_range(db, cur_str)
  CandleIterator(Instrument(inst), Granularity(gran), start_time, end_time, r)
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
  isdone = (string(keyparts[3]) >= string(ci.end_time)) ||
    ci.gran.string != keyparts[2]
  Candle(map(float, fields)...), isdone
end

function playback(inst::Symbol, gran::Symbol, from::DateTime, to::DateTime)
  return CandleIterator(inst, gran, from, to)
end
