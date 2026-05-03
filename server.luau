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
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")

local c_agnostic = ReplicatedStorage:FindFirstChild("Code"):FindFirstChild("Agnostic")
const remoteValueClientScript = c_agnostic:FindFirstChild("Modules"):FindFirstChild("RemoteValue")

const unavailableTags: {[string]: true} = {}

export type RemoteValue<T> = {
	_tag: string,
	_remoteEvent: RemoteEvent,
	_remoteFunction: RemoteFunction,
	_values: {[Player]: T},
	_playerRemovingConnection: RBXScriptConnection,
	_playersThatInvokedServer: {[Player]: true},
	
	Get: (self: RemoteValue<T>, player: Player) -> T,
	Destroy: (self: RemoteValue<T>) -> (),
	Update: (self: RemoteValue<T>, player: Player, value: T) -> (),
	new: (tag: string) -> RemoteValue<T>,
	
	__index: RemoteValue<T>
}

const RemoteValue = {} :: RemoteValue<any>
RemoteValue.__index = RemoteValue

function RemoteValue.new<T>(tag)
	if unavailableTags[tag] then
		error("Tag already taken!")
	end
	
	const self = setmetatable({}, RemoteValue) :: RemoteValue<T>
	
	self._tag = tag
	self._values = {}
	self._playersThatInvokedServer = {}
	
	unavailableTags[tag] = true
	
	const remoteEvent = Instance.new("RemoteEvent")
	remoteEvent.Name = self._tag .. "Event"
	remoteEvent.Parent = remoteValueClientScript
	self._remoteEvent = remoteEvent
	
	const remoteFunction = Instance.new("RemoteFunction")
	remoteFunction.Name = self._tag .. "Function"
	
	remoteFunction.OnServerInvoke = function(player: Player): T?
		if self._playersThatInvokedServer[player] then return nil end
		self._playersThatInvokedServer[player] = true
		
		local value = self._values[player]
		
		while value == nil and player.Parent == Players do
			value = self._values[player]
			task.wait()
		end
		
		return value
	end
	
	remoteFunction.Parent = remoteValueClientScript
	self._remoteFunction = remoteFunction
	
	self._playerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
		self._playersThatInvokedServer[player] = nil
		self._values[player] = nil
	end)
	
	return self
end

function RemoteValue:Update(player, value)
	if player.Parent ~= Players then return end
	
	self._values[player] = value
	self._remoteEvent:FireClient(player, value)
end

function RemoteValue:Get(player)
	return self._values[player]
end

function RemoteValue:Destroy()
	self._remoteEvent:Destroy()
	self._remoteFunction:Destroy()
	self._playerRemovingConnection:Disconnect()
	
	unavailableTags[self._tag] = nil
end

return RemoteValue
