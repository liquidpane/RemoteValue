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
	OnChanged: Signal.Signal<T>
}

type function figureOutRemoteValueGenericType(ty)
	if ty == types.unknown then
		return types.any
	else
		return ty
	end
end

const Signal = require(script.Parent.Signal)

const RemoteValue = {}
RemoteValue.__index = RemoteValue

function RemoteValue.new<T>(tag: string): RemoteValue< figureOutRemoteValueGenericType<T> >
	const self = setmetatable({}, RemoteValue) :: RemoteValue<T>
	
	const instance = script:WaitForChild(tag) :: Folder

	const signal = Signal.new()
	
	instance:GetAttributeChangedSignal("Value"):Connect(function()
		self.Value = instance:GetAttribute("Value")
		signal:Fire(self.Value)
	end)
	
	self.OnChanged = signal
	
	self.Value = instance:GetAttribute("Value")
	
	return self
end

return RemoteValue
