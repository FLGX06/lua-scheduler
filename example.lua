local scheduler = require('scheduler')
local sleep = scheduler.sleep

--// Coroutine c1
local c1id = scheduler.resume(coroutine.create(function()
    while sleep(0.4) do
        print("c1")
    end
end))

--// Coroutine c2
scheduler.resume(coroutine.create(function()
    while sleep(0.5) do
        print("c2")
    end
end))

--// Perfomance printing of coroutine c1
scheduler.resume(coroutine.create(function()
    while sleep(1) do
        local perfData = scheduler.c[c1id].perfomance
        print("Coroutine " .. c1id .. " | Calls / AVG CPU Time / TOTAL CPU Time", perfData.calls, perfData.cpuTimeSpent / perfData.calls * 1000 .. " ms", perfData.cpuTimeSpent * 1000 .. " ms")
    end
end))

--// Garbage collection
scheduler.resume(coroutine.create(function()
    while sleep(1) do
        collectgarbage("collect")
    end
end))

while scheduler.run() do end