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

const c_agnostic = ReplicatedStorage:FindFirstChild("Code"):FindFirstChild("Agnostic")
const remoteValueClientScript = c_agnostic:FindFirstChild("Modules"):FindFirstChild("RemoteValue")

const unavailableTags: {[string]: true} = {}

export type RemoteValue<T> = {
	Update: (self: RemoteValue<T>, player: Player, value: T) -> (),
	Get: (self: RemoteValue<T>, player: Player) -> T,
	Destroy: (self: RemoteValue<T>) -> ()
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
	if unavailableTags[tag] then
		error("Tag already taken!")
	end
	
	const self = setmetatable({}, RemoteValue)
	
	self._tag = tag
	self._values = {}
	
	unavailableTags[tag] = true
	
	self._playerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
		self._values[player] = nil
	end)
	
	return self :: RemoteValue<T>
end

function RemoteValue:Update(player, value)
	if player.Parent ~= Players then return end

	const instance = remoteValueClient:FindFirstChild(self._tag .. player.Name)
	if not instance then
		instance = Instance.new("Folder")
		instance.Name = self._tag .. player.Name
		instance.Parent = remoteValueClientScript
	end

	self._values[player] = value
	instance:SetAttribute("Value", value)
end

function RemoteValue:Get(player)
	return self._values[player]
end

function RemoteValue:Destroy()
	self._playerRemovingConnection:Disconnect()
	table.clear(self._values)

	for _, player in Players:GetPlayers() do
		const instance = remoteValueClient:FindFirstChild(self._tag .. player.Name)
		if instance then
			instance:Destroy()
		end
	end
	
	unavailableTags[self._tag] = nil
end

return RemoteValue
