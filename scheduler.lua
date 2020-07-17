--// (c) Copyright 2020 Lukáš Horáček
--// MIT License

local coroutine = coroutine
local table = table
local os = os

local origResume = coroutine.resume

local scheduler; scheduler = {
    c = {};
    lastID = 0;
    runningID = 0;
    waiting = {};
    missCount = 0;
    missSum = 0;

    resume = function(c, ...)
        local id = scheduler.lastID + 1

        scheduler.lastID = id
        scheduler.runningID = id

        scheduler.c[id] = {c = c; id = id; args = {...}; start = os.clock(); performance = {calls = 0; cpuTimeSpent = 0;};}

        local start = os.clock()
        origResume(c)
        scheduler.c[id].performance.calls = 1
        scheduler.c[id].performance.cpuTimeSpent = os.clock() - start

        return id
    end;

    resumeMeIn = function(t)
        table.insert(scheduler.waiting, {t = os.clock() + t; id = scheduler.runningID;})
    end;

    run = function()
        if #scheduler.waiting == 0 then return false end

        local offset = 0

        for i=1,#scheduler.waiting do
            local waiting = scheduler.waiting[i + offset]

            if os.clock() >= waiting.t then
                scheduler.missCount = scheduler.missCount + 1
                scheduler.missSum = scheduler.missSum + (os.clock() - waiting.t)

                local c = scheduler.c[waiting.id]

                if c then
                    local runStart = os.clock()
                    scheduler.runningID = c.id
                    local success,err = origResume(c.c)
                    local took = os.clock() - runStart
                    c.performance.calls = c.performance.calls + 1
                    c.performance.cpuTimeSpent = c.performance.cpuTimeSpent + took

                    if not success then
                        print("Error in coroutine " .. c.id, err)
                    end
                end

                --scheduler.c[waiting.id] = nil
                table.remove(scheduler.waiting, i + offset)
                offset = offset - 1
            end
        end

        return true
    end;

    sleep = function(t)
        scheduler.resumeMeIn(t or 0)
        coroutine.yield()

        return true
    end;
}

return scheduler