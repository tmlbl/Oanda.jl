granularities = Dict{Symbol,Period}(

  :S5 => Second(5),
  :S10 => Second(10),
  :S15 => Second(15),
  :S30 => Second(30),

  :M1 => Minute(1),
  :M2 => Minute(2),
  :M3 => Minute(3),
  :M4 => Minute(4),
  :M5 => Minute(5),
  :M10 => Minute(10),
  :M15 => Minute(15),
  :M30 => Minute(30),

  :H1 => Hour(1),
  :H2 => Hour(2),
  :H3 => Hour(3),
  :H4 => Hour(4),
  :H6 => Hour(6),
  :H8 => Hour(8),
  :H12 => Hour(12),

  :D => Day(1),
  :W => Week(1),
  :M => Month(1)

)

type Granularity
  symbol::Symbol
  string::ASCIIString
  period::Period
end

Granularity(s::Symbol) = Granularity(s, ascii(string(s)), granularities[s])

type Instrument
  symbol::Symbol
  string::ASCIIString
  pip::Float64
end

instruments = Dict{Symbol,Instrument}(
  :EUR_USD => Instrument(:EUR_USD, "EUR_USD", 0.0001),
  :USD_JPY => Instrument(:USD_JPY, "USD_JPY", 0.001)
)

Instrument(s::Symbol) = instruments[s]

Base.get(s::Symbol) = begin
  if haskey(granularities, s)
    granularities[s]
  elseif haskey(instruments, s)
    instruments[s]
  else
    error("Symbol $s not found")
  end
end

type Candles
  symbol::Symbol
  granularity::Symbol
  series::TimeArray
end

type Candle
  time::DateTime
  openBid::Float64
  openAsk::Float64
  closeBid::Float64
  closeAsk::Float64
  highBid::Float64
  highAsk::Float64
  lowBid::Float64
  lowAsk::Float64
end

Base.show(io::IO, c::Candles) = begin
  print("\n$(c.symbol) $(c.granularity)\n\n")
  show(io, c.series)
end
