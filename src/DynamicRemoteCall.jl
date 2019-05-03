module DynamicRemoteCall

using Distributed

export dynamicremotecall!

mutable struct RepeatCounter
    i::Int
    lock::Bool
    RepeatCounter() = new(0, true)
end

try_(c::RepeatCounter) = c.lock

lock_(c::RepeatCounter) = c.lock = false

unlock_(c::RepeatCounter) = c.lock = true

function readandincrement(c::RepeatCounter)
    while true
        if try_(c)
            lock_(c)
            i = c.i += 1
            unlock_(c)
            return i
        end
    end
end

function remotecall_subprocess!(f, results::Vector, counter::RepeatCounter, pid::Int, repeattimes, args...; kwargs...)
    while true
        i = readandincrement(counter)
        if i <= repeattimes
            results[i] = remotecall_fetch(f, pid, args...; kwargs...)
        else
            break
        end
    end
end

function dynamicremotecall!(f, results::Vector, workers::AbstractArray{Int}, args...; kwargs...)
    counter = RepeatCounter()
    repeattimes = length(results)
    @sync for pid in workers
        @async remotecall_subprocess!(f, results, counter, pid, repeattimes, args...; kwargs...)
    end
end

dynamicremotecall!(f, results::Vector, args...; kwargs...) = dynamicremotecall!(f, results, workers(), args...; kwargs...)

end # module
