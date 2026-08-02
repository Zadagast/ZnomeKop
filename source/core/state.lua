-- Tiny state stack for title / explore / (future) battle menus.

State = {
    stack = {},
    current = nil,
}

function State.switch(newState, ...)
    if State.current and State.current.exit then
        State.current:exit()
    end
    State.stack = { newState }
    State.current = newState
    if newState.enter then
        newState:enter(...)
    end
end

function State.push(newState, ...)
    if State.current and State.current.pause then
        State.current:pause()
    end
    State.stack[#State.stack + 1] = newState
    State.current = newState
    if newState.enter then
        newState:enter(...)
    end
end

function State.pop(...)
    if State.current and State.current.exit then
        State.current:exit()
    end
    State.stack[#State.stack] = nil
    State.current = State.stack[#State.stack]
    if State.current and State.current.resume then
        State.current:resume(...)
    end
end

function State.update()
    if State.current and State.current.update then
        State.current:update()
    end
end

function State.draw()
    if State.current and State.current.draw then
        State.current:draw()
    end
end
