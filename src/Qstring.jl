using HttpCommon, Base.Dates

# Creating a query string that will encode unix datetimes
# given Julia DateTimes
function qstring(kv::Tuple...)
  encodeval(v::String) = encodeURI(v)
  encodeval(n::Real) = string(n)
  encodeval(s::Symbol) = encodeval(string(s))
  encodeval(dt::DateTime) = string(round(Int64, Dates.datetime2unix(dt)))
  encodepair(p::Tuple) = string(encodeval(p[1]), "=", encodeval(p[2]), "&")
  q = string("?", join(map(encodepair, kv)))
  q[1:length(q) - 1]
end
