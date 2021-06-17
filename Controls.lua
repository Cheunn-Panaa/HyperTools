local WM = GetWindowManager()
function createButton(parent,name,sizeX,sizeY,xOffset,yOffset,fromAnchor,toAnchor,buttonFunction,text,textureOverride,isBackdrop)
	local button = WM:CreateControl("$(parent)"..name, parent, CT_BUTTON)
	button:SetMouseEnabled(true)
	button:SetState(BSTATE_NORMAL)
	button:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
	button:SetVerticalAlignment(TEXT_ALIGN_CENTER)
	button:SetFont("ZoFontGameSmall")
	button:SetHandler("OnMouseDown", function(self, btn, ctrl, alt, shift)
		buttonFunction(ctrl, alt, shift)
	end)
	button:SetNormalTexture(textureOverride or "")
	button:SetAnchor(fromAnchor, parent,toAnchor,xOffset,yOffset)
	button:SetDimensions(sizeX,sizeY)
	button:SetText(text)
	if isBackdrop then
		local backdrop = WM:CreateControl("$(parent)backdrop",button,  CT_BACKDROP, 4)
		backdrop:SetAnchorFill()
		backdrop:SetEdgeTexture("", 2, 2, 2)
		backdrop:SetCenterColor(0,0,0, 0)
		backdrop:SetEdgeColor(0.7, 0.7, 0.6, 1)
		button.backdrop = backdrop
	end
	return button
end


function createCheckbox(parent,name,sizeX,sizeY,xOffset,yOffset,fromAnchor,toAnchor,defaultValue,checkboxFunction)
	local checkbox = WM:CreateControl("$(parent)"..name, parent, CT_TEXTURE)
	checkbox.data = defaultValue
	checkbox:SetMouseEnabled(true)
	checkbox:SetHandler("OnMouseUp", function(self, btn, upInside)
		checkbox.data = not checkbox.data
		if checkbox.data then
			checkbox:SetTexture("/esoui/art/buttons/checkbox_checked.dds")
		else
			checkbox:SetTexture("/esoui/art/buttons/checkbox_unchecked.dds")
		end
		checkboxFunction(checkbox.data)
    end)
	checkbox:SetAnchor(fromAnchor, parent,toAnchor,xOffset,yOffset)
	checkbox:SetDimensions(sizeX,sizeY)
	if checkbox.data then
		checkbox:SetTexture("/esoui/art/buttons/checkbox_checked.dds")
	else
		checkbox:SetTexture("/esoui/art/buttons/checkbox_unchecked.dds")
	end

	local function Update(self,newValue)
		checkbox.data = newValue
		if checkbox.data then
			checkbox:SetTexture("/esoui/art/buttons/checkbox_checked.dds")
		else
			checkbox:SetTexture("/esoui/art/buttons/checkbox_unchecked.dds")
		end
	end
	checkbox.Update = Update

	return checkbox
end

function createColorpicker(parent,name,sizeX,sizeY,xOffset,yOffset,fromAnchor,toAnchor,color,colorpickerFunction)
    local colorpicker = WM:CreateControl("$(parent)"..name, parent, CT_TEXTURE)
	colorpicker.color = color
	colorpicker:SetMouseEnabled(true)
	colorpicker:SetHandler("OnMouseUp", function(self, btn, upInside)
		if upInside then
			local r, g, b, a = unpack(colorpicker.color)
			if IsInGamepadPreferredMode() then
				COLOR_PICKER_GAMEPAD:Show(function(r,g,b,a) colorpicker.color = {r,g,b,a} colorpicker:SetColor(r,g,b,a) colorpickerFunction({r,g,b,a}) end, r, g, b, a)
			else
				COLOR_PICKER:Show(function(r,g,b,a) colorpicker.color = {r,g,b,a} colorpicker:SetColor(r,g,b,a) colorpickerFunction({r,g,b,a}) end, r, g, b, a)
			end
		end
    end)
	--colorpicker:SetNormalTexture("/esoui/art/actionbar/abilityframe64_up.dds")
	colorpicker:SetAnchor(fromAnchor, parent,toAnchor,xOffset,yOffset)
	colorpicker:SetDimensions(sizeX,sizeY)
	colorpicker:SetColor(unpack(color))
	local backdrop = WM:CreateControl("$(parent)backdrop"..name,parent,  CT_BACKDROP, 4)
	
	backdrop:SetEdgeTexture("",2,2,2)
	backdrop:SetCenterColor(0,0,0, 0)
	backdrop:SetEdgeColor(1,1,1, 1)
	backdrop:SetAnchor(TOPLEFT,colorpicker,TOPLEFT,0,0)
	backdrop:SetDimensions(sizeX,sizeY)
	colorpicker.backdrop = backdrop

	return colorpicker
end

function createDropdown(parent,name,sizeX,sizeY,xOffset,yOffset,fromAnchor,toAnchor,choices,selection,dropdownFunction)
	local comboBox = WM:CreateControlFromVirtual("$(parent)"..name, parent, "ZO_ComboBox")
	comboBox.choices = choices
	comboBox.selection = selection or HT_pickAnyKey(choices)
	comboBox:SetDimensions(sizeX,sizeY)
	comboBox:SetAnchor(fromAnchor,parent,toAnchor,xOffset,yOffset)
	comboBox.dropdown = ZO_ComboBox_ObjectFromContainer(comboBox)
	comboBox.updateDropdown = function(self)
		local dropdown = self.dropdown
		dropdown:ClearItems()
		for k,v in pairs(comboBox.choices) do
			local entry = dropdown:CreateItemEntry(v,function(_,selection) self.selection = selection if dropdownFunction then dropdownFunction(selection) end end)
			dropdown:AddItem(entry)
			if self.selection == v then
				dropdown:SelectItem(entry)
			end
		end
	end
	comboBox:updateDropdown()
	return comboBox
end


function createLabel(parent,name,sizeX,sizeY,xOffset,yOffset,fromAnchor,toAnchor,text,horizontalAlignment,verticalAlignment,font,fontSize,fontWeight)
	local label = WM:CreateControl("$(parent)"..name,parent,CT_LABEL)
	label:SetFont(string.format("$(%s)|$(KB_%s)|%s",font or "BOLD_FONT", fontSize or 13, fontWeight or "soft-shadow-thin"))
	label:SetScale(1.0)
	label:SetColor(255, 255, 255, 1)
	label:SetText(text)				
	label:SetAnchor(fromAnchor,parent,toAnchor,xOffset,yOffset)
	label:SetDimensions(sizeX, sizeY)
	label:SetHorizontalAlignment(horizontalAlignment or 1)
	label:SetVerticalAlignment(verticalAlignment or 1)
	label:SetHidden(false)
	return label
end



function createContainer(parent,name,sizeX,sizeY,xOffset,yOffset,fromAnchor,toAnchor)
	local control = WM:CreateControl("$(parent)"..name,parent,CT_CONTROL)
	control:SetDimensions(sizeX, sizeY)
	control:SetAnchor(fromAnchor,parent,toAnchor,xOffset,yOffset)
	return control
end

function createEditbox(parent,name,sizeX,sizeY,xOffset,yOffset,fromAnchor,toAnchor,editboxFunction,defaultValue,textType)
	local control = WM:CreateControl("$(parent)"..name,parent,CT_CONTROL)
	control:SetDimensions(sizeX, sizeY)
	control:SetAnchor(fromAnchor,parent,toAnchor,xOffset,yOffset)
	local backdrop = WM:CreateControlFromVirtual(nil, control, "ZO_EditBackdrop")
	backdrop:SetAnchor(TOPLEFT, control, TOPLEFT,0,0)
	local editbox = WM:CreateControlFromVirtual("$(parent)editbox", control, "ZO_DefaultEditForBackdrop")
	control.editbox = editbox
	control.SetText = function(self,text)
		self.editbox:SetText(text)
	end
	control.GetText = function(self)
		return self.editbox:GetText()
	end
	editbox:SetHandler("OnFocusLost", function(self) editboxFunction(control) end)
    editbox:SetHandler("OnEscape", function(self) self:LoseFocus(control) editboxFunction() end)
	editbox:SetAnchor(TOPLEFT, control, TOPLEFT,0,0)
	editbox:SetDimensions(sizeX, sizeY)
	if defaultValue then
		editbox:SetText(defaultValue)
	end
	editbox.OriginalGetText = editbox.GetText
	editbox.GetText = function(self)
		local var = self:OriginalGetText()
		if var == "" then
			return nil
		else
			return var
		end
	end
	backdrop:SetAnchorFill()
	--control:SetResizeToFitDescendents(true)
	editbox:SetTextType(textType or TEXT_TYPE_ALL)
	editbox:SetMaxInputChars(30000)
	return control
end




function createMultilineEditbox(parent,name,sizeX,sizeY,xOffset,yOffset,fromAnchor,toAnchor,editboxFunction,defaultValue,textType)
	local control = WM:CreateControl("$(parent)"..name,parent,CT_CONTROL)
	control:SetDimensions(sizeX, sizeY)
	control:SetAnchor(fromAnchor,parent,toAnchor,xOffset,yOffset)
	local backdrop = WM:CreateControlFromVirtual(nil, control, "ZO_EditBackdrop")
	backdrop:SetAnchor(TOPLEFT, control, TOPLEFT,0,0)
	local editbox = WM:CreateControlFromVirtual("$(parent)editbox", control, "ZO_DefaultEditMultiLineForBackdrop")
	control.editbox = editbox
	control.SetText = function(self,text)
		self.editbox:SetText(text)
	end
	control.GetText = function(self)
		return self.editbox:GetText()
	end
	editbox:SetHandler("OnFocusLost", function(self) editboxFunction(control) end)
    editbox:SetHandler("OnEscape", function(self) self:LoseFocus(control) editboxFunction() end)
	editbox:SetAnchor(TOPLEFT, control, TOPLEFT,0,0)
	editbox:SetDimensions(sizeX, sizeY)
	if defaultValue then
		editbox:SetText(defaultValue)
	end
	editbox.OriginalGetText = editbox.GetText
	editbox.GetText = function(self)
		local var = self:OriginalGetText()
		if var == "" then
			return nil
		else
			return var
		end
	end
	backdrop:SetAnchorFill()
	--control:SetResizeToFitDescendents(true)
	editbox:SetTextType(textType or TEXT_TYPE_ALL)
	editbox:SetMaxInputChars(30000)
	return control
end




function createBackground(parent,name,sizeX,sizeY,xOffset,yOffset,fromAnchor,toAnchor)
	local control = WM:CreateControl("$(parent)"..name,parent,CT_CONTROL)
	control:SetDimensions(sizeX, sizeY)
	control:SetAnchor(fromAnchor,parent,toAnchor,xOffset,yOffset)
	local backdrop = WM:CreateControl("$(parent)backdrop",control,  CT_BACKDROP, 4)
	backdrop:SetAnchorFill()
	backdrop:SetAnchor(TOPLEFT,control,TOPLEFT,0,0)
	backdrop:SetHidden(false)
	backdrop:SetEdgeTexture("", 2, 2, 2)
	backdrop:SetCenterColor(0,0,0, 0.9)
	backdrop:SetEdgeColor(0.7, 0.7, 0.6, 1)
	return control

end

function createTexture(parent,name,sizeX,sizeY,xOffset,yOffset,fromAnchor,toAnchor,texturePath,backdropThickness,backdropColor)
	local texture = WM:CreateControl("$(parent)"..name,parent,  CT_TEXTURE, 4)
	texture:SetDimensions(sizeX,sizeY)
	texture:SetAnchor(fromAnchor,parent,toAnchor,xOffset,yOffset)
	texture:SetHidden(false)
	texture:SetTexture(texturePath)
	if backdropThickness then
		local backdropColor = backdropColor or {0.7, 0.7, 0.6, 1}
		local backdrop = WM:CreateControl("$(parent)backdrop",texture,  CT_BACKDROP, 4)
		
		backdrop:SetCenterColor(0,0,0,0)
		backdrop:SetEdgeTexture("",backdropThickness, backdropThickness)
		backdrop:SetEdgeColor(unpack(backdropColor))
		backdrop:SetAnchor(CENTER,texture,CENTER,0,0)
		backdrop:SetDimensions(sizeX,sizeY)
		texture:SetDimensions(sizeX-backdropThickness,sizeY-backdropThickness)
		texture:SetAnchor(fromAnchor,parent,toAnchor,xOffset+(backdropThickness/2),yOffset+(backdropThickness/2))
		texture.backdrop = backdrop
	end
	return texture
end
