--[[
Copyright 2026 liquidpane

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--]]

--!strict
export type RemoteValue<T> = {
	Value: T,
	OnChanged: RBXScriptSignal
}

type function figureOutRemoteValueGenericType(ty)
	if ty == types.unknown then
		return types.any
	else
		return ty
	end
end

const RemoteValue = {}
RemoteValue.__index = RemoteValue

function RemoteValue.new<T>(tag: string): RemoteValue< figureOutRemoteValueGenericType<T> >
	const self = setmetatable({}, RemoteValue)
	
	const remoteEvent = script:WaitForChild(tag .. "Event") :: RemoteEvent
	const remoteFunction = script:WaitForChild(tag .. "Function") :: RemoteFunction

	self.OnChanged = remoteEvent.OnClientEvent
	
	self.OnChanged:Connect(function(value: T)
		self.Value = value
	end)
	
	task.spawn(function()
		local value = remoteFunction:InvokeServer()
		if self.Value then return end

		self.Value = value
	end)
	
	return self :: RemoteValue<T>
end

return RemoteValue
