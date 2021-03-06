--// (c) Copyright 2020 Lukáš Horáček
--// MIT License

local coroutine = coroutine
local table = table
local os = os

local origResume = coroutine.resume

local scheduler; scheduler = {
    c = {};
    lastID = 0;
    runningIDs = {};
    waiting = {};

    resume = function(c, ...)
        local id = scheduler.lastID + 1

        scheduler.lastID = id
        local prevCount = #scheduler.runningIDs
        table.insert(scheduler.runningIDs, id)

        scheduler.c[id] = {c = c; id = id; args = {...}; start = os.clock(); performance = {calls = 0; cpuTimeSpent = 0;};}

        local start = os.clock()
        origResume(c, ...)
        scheduler.c[id].performance.calls = 1
        scheduler.c[id].performance.cpuTimeSpent = os.clock() - start

        if #scheduler.runningIDs > prevCount then
            table.remove(scheduler.runningIDs)
        end

        return id
    end;

    resumeMeIn = function(t)
        local id = scheduler.runningIDs[#scheduler.runningIDs]

        table.insert(scheduler.waiting, {t = os.clock() + t; id = id;})
        table.remove(scheduler.runningIDs)

        return id
    end;

    run = function()
        if #scheduler.waiting == 0 then return false end

        local offset = 0

        for i=1,#scheduler.waiting do
            local waiting = scheduler.waiting[i + offset]

            if os.clock() >= waiting.t then
                --local delay = scheduler.missSum + (os.clock() - waiting.t)

                local c = scheduler.c[waiting.id]

                if c then
                    local runStart = os.clock()
                    local prevCount = #scheduler.runningIDs
                    table.insert(scheduler.runningIDs, c.id)
                    local success,err = origResume(c.c, unpack(c.args))
                    local took = os.clock() - runStart
                    c.performance.calls = c.performance.calls + 1
                    c.performance.cpuTimeSpent = c.performance.cpuTimeSpent + took
                    if #scheduler.runningIDs > prevCount then
                        table.remove(scheduler.runningIDs)
                    end

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
        local id = scheduler.resumeMeIn(t or 0)
        local args = coroutine.yield()
        scheduler.c[id].args = {args} --// save arguments we can use with resume

        return true
    end;
}

return scheduler