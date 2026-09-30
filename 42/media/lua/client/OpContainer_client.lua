-- OpContainer_client.lua
-- Licence: CC0-1.0(Visit https://creativecommons.org/publicdomain/zero/1.0/ to view details).
-- Maintainer: AbrahamPicos.
-- Contributors:

require("OpContainer")

local utils = _07ca70cd7c514861b4b3897cbf56f40a

if not utils then return end

-----------------------------------------
-- Caché de clases, métodos, y tablas: --
-----------------------------------------

local OpContainer = utils.OpContainer

if not OpContainer then return end

local secureTable = utils.secureTable
local secureString = utils.secureString
local isCallSecure = utils.isCallSecure
local isTableSecure = utils.isTableSecure
local isNumberSecure = utils.isNumberSecure

local Events = OpContainer.Events
local Capability = OpContainer.Capability

local getText = OpContainer.getText
local isClient = OpContainer.isClient
local getTexture = OpContainer.getTexture
local instanceof = OpContainer.instanceof
local getSpecificPlayer = OpContainer.getSpecificPlayer

OpContainer.ISModalDialog = OpContainer.ISModalDialog or secureTable(ISModalDialog)
OpContainer.ISWorldObjectContextMenu = OpContainer.ISWorldObjectContextMenu or secureTable(ISWorldObjectContextMenu)

local ISModalDialog = OpContainer.ISModalDialog
local ISWorldObjectContextMenu = OpContainer.ISWorldObjectContextMenu

local getSandboxOptions = OpContainer.getSandboxOptions
local isObjectProtected = OpContainer.isObjectProtected

local modIcon = getTexture("opcontainer_icon.png")

---------------------------
-- Funciones auxiliares: --
---------------------------

-- Añade una hoja de sprites a las excepciones personalizadas del mod.
---@param player IsoPlayer El jugador que añadirá la excepción.
---@param playerNum integer El número que representa al jugador que añadirá la excepción (para pantalla dividida).
---@param isExempt boolean Si hay una excepción. Lo que significa que va a removerse.
---@param patterns string La lista que contiene todos los elementos de la nueva configuración.
local function changeCustomExceptions(player, playerNum, isExempt, patterns)
    local options = getSandboxOptions()

	-- Validar opciones, y que se pueda instanciar un diálogo modal.
    if not (instanceof(options, "SandboxOptions") and isCallSecure(options.getOptionByName)
		and isCallSecure(options.toLua) and isCallSecure(options.sendToServer) and isCallSecure(ISModalDialog.new)
	) then
        return
    end

    local option = options:getOptionByName("OpContainer.customExceptions")

	-- Validar opción.
	---@cast option SandboxOptions.StringSandboxOption Validación en instanceof.
    if not (instanceof(option, "SandboxOptions$StringSandboxOption") and isCallSecure(option.setValue)) then
		return
	end

	local modal = ISModalDialog:new(0, 0, 1, 1,
		secureString(getText(isExempt and "IGUI_ModalDialog_OpContainer_RemoveException"
	or "IGUI_ModalDialog_OpContainer_AddException")), true, nil, nil, playerNum)

	-- Validar diálogo modal.
	---@cast modal -? Validación en isTableSecure.
	if not (isTableSecure(modal)
		and isCallSecure(modal.centerOnScreen) and isCallSecure(modal.initialise) and isCallSecure(modal.addToUIManager)
	) then
		return
	end

	-- Confgurar la lógica de los botones del diálogo modal.
	modal.onclick = function (target, button)

		-- Validar que el botón presionado sea "sí".
		if not (button.internal == "YES") then
			return
		end

		-- Cambiar opción al nuevo valor, y sincronizar.
		option:setValue(patterns)
		options:toLua()
		options:sendToServer()

		-- Notificar al usuario.
		if isCallSecure(player.setHaloNote) then
			player:setHaloNote(secureString(getText(
			(isExempt and "IGUI_HaloNote_OpContainer_ExceptionRemoved") or "IGUI_HaloNote_OpContainer_ExceptionAdded"
			)), 0, 255, 0, 200)
		end
	end

	-- Añadir díalogo modal a la UI, y centrar en la pantalla.
	modal:initialise()
    modal:addToUIManager()
	modal:centerOnScreen(playerNum)
end

------------------------------
-- Devoluciones de llamada: --
------------------------------

-- En el evento OnFillWorldObjectContextMenu.
-- Agrega una opción para este mod al menú contextual del mundo, cuando este se está rellenando.
---@param playerNum integer El número que representa al jugador que abríó el menú contextual (para pantalla dividida).
---@param context ISContextMenu El menú contextual que se está rellenando.
---@param worldobjects IsoObject[] El objeto que estaba bajo el cursor, y algunos otros de los que están en la baldosa.
---@param test boolean Si el menú contextual se rellena para comprobar si hay objetos interactivos en la baldosa.
local function OnFillWorldObjectContextMenu(playerNum, context, worldobjects, test)

	-- Validar entorno.
	if not isClient() or test then
		return
	end

	local player = isNumberSecure(playerNum) and getSpecificPlayer(playerNum)

	-- Validar jugador.
	---@cast player -? Validación en instanceof.
	if not (instanceof(player, "IsoPlayer") and isCallSecure(player.getRole)) then
		return
	end

	local role = player:getRole()

	-- Validar rol, y que el jugador tenga permitido modificar las opciones de sandbox.
	---@cast role -? Validación en instanceof.
	if not (instanceof(role, "Role") and isCallSecure(role.hasCapability)
		and role:hasCapability(Capability.SandboxOptions)
	) then
		return
	end

	local isRelevant, exception = isObjectProtected(
		secureTable(worldobjects)[1], nil, nil, nil
	)

	-- Validar la relevanca del objeto, y que se disponga de su excepción.
	if not isRelevant or not exception then
		return
	end

	local isExempt = exception.isExempt
	local option = isCallSecure(context.addOption) and context:addOption(secureString(getText(
		isExempt and "IGUI_ContextMenu_OpContainer_RemoveException" or "IGUI_ContextMenu_OpContainer_AddException"
	)), nil, nil)

	-- Validar opción contextual.
	---@cast option -? Validación en isTableSecure.
	if not isTableSecure(option) then
		return
	end

	local tooltip = isCallSecure(ISWorldObjectContextMenu.addToolTip) and ISWorldObjectContextMenu.addToolTip()

	-- Validar tooltip.
	---@cast tooltip -? Validación en isTableSecure.
	if not isTableSecure(tooltip) then
		return -- Un tooltip defectuoso podría romper la opción.
	end

	local texture = getTexture(exception.spriteName)

	-- Configurar tooltip.
	tooltip.description = secureString(getText((isExempt and "IGUI_ContextMenu_OpContainer_RemoveException_Tooltip"
		or "IGUI_ContextMenu_OpContainer_AddException_Tooltip"
	), exception.exemptName))
	tooltip.texture = instanceof(texture, "Texture") and texture or nil

	-- Configurar la nueva opción.
	option.toolTip = tooltip
	option.iconTexture = instanceof(modIcon, "Texture") and modIcon or nil
	option.onSelect = function() changeCustomExceptions(player, playerNum, isExempt, exception.patterns) end
end

----------------
-- Enganches: --
----------------

Events.OnFillWorldObjectContextMenu.Add(OnFillWorldObjectContextMenu)
