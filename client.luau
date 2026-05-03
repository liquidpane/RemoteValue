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
const Signal = require(script.Parent:FindFirstChild("Signal"))

export type RemoteValue<T> = {
	_remoteEventConnection: RBXScriptConnection,
	Value: T,
	OnChanged: Signal.Signal<T>,
	
	new: (tag: string, async: boolean?) -> RemoteValue<T>,
	Destroy: (self: RemoteValue<T>) -> (),
	
	__index: RemoteValue<T>
}

const RemoteValue = {} :: RemoteValue<any>
RemoteValue.__index = RemoteValue

function RemoteValue.new<T>(tag, async)
	local self = setmetatable({}, RemoteValue) :: RemoteValue<T>
	
	local remoteEvent = script:WaitForChild(tag .. "Event") :: RemoteEvent
	local remoteFunction = script:WaitForChild(tag .. "Function") :: RemoteFunction
	
	self.OnChanged = Signal.new()
	
	self._remoteEventConnection = remoteEvent.OnClientEvent:Connect(function(value: T)
		self.Value = value
		self.OnChanged:Fire(value)
	end)
	
	if async == true then
		task.spawn(function()
			local value = remoteFunction:InvokeServer()
			if self.Value then return end
			
			self.Value = value
		end)
	else
		self.Value = remoteFunction:InvokeServer()
	end
	
	return self
end

function RemoteValue:Destroy()
	self._remoteEventConnection:Disconnect()
	self.OnChanged:DisconnectAll()
end

return RemoteValue
