

"""
# `Eval` type for managing function evaluations 

## fields 

* `value`: current function value
* `time`: timing of evaluation
* `params`: `OrderedDict` of parameters
* `simMoments`: `OrderedDict` of moments generated by model
* `dataMoments`: `OrderedDict` of data moments
* `dataMomentsW`: `OrderedDict` of weights for data moments
* `status`: Int error status
* `prob`: probability of acceptance
* `accepted`: whether draw was accepted
* `options`: Dict of options and other info

""" 
type Eval

	value        :: Float64
	time         :: Float64
	params       :: OrderedDict
	simMoments   :: OrderedDict
	dataMoments  :: OrderedDict
	dataMomentsW :: OrderedDict
	status       :: Int64
    prob         :: Float64
    accepted     :: Bool
	options      :: Dict

	function Eval()
		this              = new()
		this.value        = -1.0
		this.time         = time()
		this.status       = -1
		this.dataMoments  = OrderedDict{Symbol,Float64}()
		this.dataMomentsW = OrderedDict{Symbol,Float64}()
		this.params       = OrderedDict{Symbol,Float64}()
		this.simMoments   = OrderedDict{Symbol,Float64}()
        this.prob = 0.0
        this.accepted = false
		this.options      = Dict()
		return this
	end
	function Eval(p::Union{Dict,OrderedDict},mom::DataFrame)
		this = new()
		this.value        = -1.0
		this.time         = time()
		this.status       = -1
		this.dataMoments  = OrderedDict{Symbol,Float64}()
		this.dataMomentsW = OrderedDict{Symbol,Float64}()
		this.params       = OrderedDict()
		this.simMoments   = OrderedDict{Symbol,Float64}()
		this.options      = Dict()
        this.prob = 0.0
        this.accepted = false

		if !in(:name,names(mom)) throw(ArgumentError("moment dataframe needs column named `name`")) end
		if !in(:value,names(mom)) throw(ArgumentError("moment dataframe needs column named `value`")) end
		if !in(:weight,names(mom)) throw(ArgumentError("moment dataframe needs column named `weight`")) end

		for i in eachrow(mom)
			kk = Symbol(i[:name])
			this.dataMoments[kk]  = i[:value]
			this.dataMomentsW[kk] = i[:weight]
		end

		for k in keys(p)
			kk = Symbol(k)
            if length(p[k]) > 3
                warn("you have a parameter with more tham 3 entries. we assume p = [val,lb,ub]")
            end
			this.params[kk] = p[k][1] # we take the first one, in case there are several values per param
			# not sure about that.
		end

		return this
	end

	function Eval(mprob::MProb,p::Union{Dict,OrderedDict})
		this              = new()
		this.value        = -1.0
		this.time         = time()
		this.status       = -1
		this.dataMoments  = OrderedDict{Symbol,Float64}()
		this.dataMomentsW = OrderedDict{Symbol,Float64}()
		this.params       = OrderedDict{Symbol,Float64}()
		this.simMoments   = OrderedDict{Symbol,Float64}()
		this.options      = Dict()
        this.prob = 0.0
        this.accepted = false

		for kk in keys(mprob.moments) 
			this.dataMoments[kk]  = mprob.moments[kk][:value]
			this.dataMomentsW[kk] = mprob.moments[kk][:weight]
		end

		for k in keys(p)
			kk = Symbol(k)
			this.params[kk] = p[k]
		end

		return this
	end
    function Eval(mprob::MProb)
        this              = new()
        this.value        = -1.0
        this.time         = time()
        this.status       = -1
        this.dataMoments  = OrderedDict{Symbol,Float64}()
        this.dataMomentsW = OrderedDict{Symbol,Float64}()
        this.params       = OrderedDict{Symbol,Float64}()
        this.simMoments   = OrderedDict{Symbol,Float64}()
        this.options      = Dict()
        this.prob = 0.0
        this.accepted = false

        for kk in keys(mprob.moments) 
            this.dataMoments[kk]  = mprob.moments[kk][:value]
            this.dataMomentsW[kk] = mprob.moments[kk][:weight]
        end

        for (k,v) in mprob.initial_value
            kk = Symbol(k)
            this.params[kk] = v
        end

        return this
    end

	function Eval(p::Union{Dict,OrderedDict},m::Dict{Symbol,Float64})
		this              = Eval()
		this.value        = -1.0
		this.time         = time()
		this.status       = -1
        this.dataMoments  = OrderedDict{Symbol,Float64}()
        this.params       = OrderedDict{Symbol,Float64}()
        for (k,v) in p
            this.params[k] = v
        end
        for (k,v) in m
            this.dataMoments[k] = v
        end
		this.dataMomentsW = OrderedDict{Symbol,Float64}()
		this.simMoments   = OrderedDict{Symbol,Float64}()
		this.options      = Dict()
        this.prob = 0.0
        this.accepted = false

		return this
	end

end

function ==(ev::Eval,ev2::Eval)
	x = true
	x = x && (ev.value == ev2.value)
	x = x && (ev.status == ev2.status)
	x = x && (ev.params == ev2.params)
	x = x && (ev.simMoments == ev2.simMoments)
	x = x && (ev.dataMoments == ev2.dataMoments)
	x = x && (ev.accepted == ev2.accepted)
	x
end


function start(ev::Eval)
	ev.time = time()
end

function finish(ev::Eval)
	ev.time =  time() - ev.time
end

param(ev::Eval,ll::Array{Symbol,1})    = Float64[ ev.params[i] for i in ll]
param(ev::Eval,ll::Array{Any,1})       = Float64[ ev.params[i] for i in ll]
param(ev::Eval)                        = param(ev,collect(keys(ev.params)))
param(ev::Eval,s::Symbol)              = ev.params[s]

paramd(ev::Eval)                       = ev.params


dataMoment(ev::Eval,ll::Array{Symbol,1})  = Float64[ ev.dataMoments[i] for i in ll]
dataMoment(ev::Eval,s::Symbol)         = ev.dataMoments[s]
dataMoment(ev::Eval)                      = dataMoment(ev,collect(keys(ev.dataMoments)))


"""
    dataMomentd(ev::Eval)

Obtain all data momoents as dict
"""
dataMomentd(ev::Eval) = ev.dataMoments

dataMomentW(ev::Eval)                      = dataMomentW(ev,collect(keys(ev.dataMomentW)))
dataMomentW(ev::Eval,ll::Array{Symbol,1}) = Float64[ ev.dataMomentsW[i] for i in ll]
dataMomentW(ev::Eval,s::Symbol)= ev.dataMomentsW[s]


"""
Obtain all moment weights as dict
"""
dataMomentWd(ev::Eval)                  = ev.dataMomentsW


function fill(p::Any,ev::Eval)
	for k in keys(ev.params)
		setfield!(p,k,ev.params[k])
	end
end

function setValue(ev::Eval,value::Float64)
	ev.value = value
end


function setMoment(ev::Eval,k::Symbol,value::Float64)
	ev.simMoments[k] = value
end

function setMoment(ev::Eval,d::Dict)
	for k in keys(d)
		ev.simMoments[k] = d[k]
	end
end

# this assumes that colum :name has the names as strings
# and that column :value stores the value
function setMoment(ev::Eval,d::DataFrame)
	for i in 1:nrow(d)
		ev.simMoments[ Symbol(d[i,:name]) ] = d[i,:value]
	end
end

function getBest(evs::Array{Eval,1}) 
  best_val = Inf
  best = None
  for ev in evs
  	if (ev.status>0) & (ev.value<best_val)
  		best = ev
  		best_val = ev.value
  	end
  end
  return best
end


"""
	check_moments(ev::Eval)

returns all data and simluated moments as a dataframe.

"""
function check_moments(ev::Eval)

	d = DataFrame(moment = collect(keys(ev.dataMoments)),data = collect(values(ev.dataMoments)),data_sd = collect(values(ev.dataMomentsW)))
	dsim = DataFrame(moment = collect(keys(ev.simMoments)),simulation= collect(values(ev.simMoments)))
	r = join(d,dsim, on=:moment)
	r[:distance] =  r[:simulation] .- r[:data]
    r[:abs_percent_dev] = abs(100 * r[:distance] ./ r[:data])
    if length(ev.dataMomentsW) > 0
       r[:weighted_dist2] = ((r[:simulation] .- r[:data]) ./ r[:data_sd] ).^2 
	   r[:weighted_precent] = abs((r[:abs_percent_dev] .- r[:data]) ./ r[:data_sd] )
    end
	return r
end

function show(io::IO,e::Eval)
  print(io,"Eval Object:\n")
  print(io,"============\n\n")
  print(io,"Objective function value: $(e.value)\n")
  print(io,"Evaluation Time: $(e.time)\n")
  print(io,"Evaluation Status: $(e.status)\n")
  print(io,"Parameters:\n")
  print(io,collect(keys(e.params)))
  print(io,"\nMoments:\n")
  print(io,collect(keys(e.dataMoments)))
  print(io,"\n===========================\n")
end
