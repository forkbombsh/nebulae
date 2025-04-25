local stateManager = {}
local states = {}
local currentState = {
	draw = function()
		love.graphics.print("No state")
	end
}
local currentStateName = nil

function stateManager.registerState(name, state)
	states[name] = state
end

function stateManager.unregisterState(name)
	states[name] = nil
end

function stateManager.switch(state, ...)
	local theNewState = states[state]
	if theNewState == nil then
		print("the state '" .. (type(state) == "string" and state or tostring(state)) .. "' doesnt exist!!")
		return
	end

	if currentState ~= theNewState then
		-- Call exit on the current state if it exists
		stateManager.passEvent("leave")

		-- Switch to the new state
		currentState = theNewState
		currentStateName = state

		-- Call enter on the new state if it exists
		stateManager.passEvent("enter", ...)
	end
end

function stateManager.passEvent(name, ...)
	if currentState and type(currentState[name]) == "function" then
		currentState[name](currentState, ...)
	end
end

function stateManager.getCurrentState()
	return currentState
end

function stateManager.getCurrentStateName()
	return currentStateName
end

return stateManager
