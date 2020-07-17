# Lua coroutine scheduler
## How does this work?
Every coroutine has to yield itself using `coroutine.yield` in order for the scheduler to resume another coroutine. Coroutines get resumed if they asked the scheduler to resume them in specified `time` using `scheduler.sleep`. It's also possible to monitor each coroutine's performance.

## Example
See example in `example.lua`

## License
See license in `LICENSE.txt`
