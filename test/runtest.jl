using DynamicRemoteCall
using Distributed

addprocs(3)

@everywhere function testfunc()
    r = rand()/10
    sleep(r)
    return r
end

results = zeros(100)

begin
    starttime = time()
    dynamicremotecall!(testfunc, results)
    endtime = time()
    (endtime-starttime)*nworkers()/sum(results)
end
