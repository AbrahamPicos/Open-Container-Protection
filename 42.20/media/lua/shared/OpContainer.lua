-- OpContainer.lua
-- Licence: CC0-1.0(Visit https://creativecommons.org/publicdomain/zero/1.0/ to view details).
-- Maintainer: AbrahamPicos.
-- Contributors:

require("OpContainer_secureUtils")

if not _07ca70cd7c514861b4b3897cbf56f40a then return end

-----------------------------------------
-- Caché de clases, métodos, y tablas: --
-----------------------------------------

local utils = _07ca70cd7c514861b4b3897cbf56f40a

local math = utils.math

local pairs = utils.pairs
local print = utils.print
local tostring = utils.tostring
local secureTable = utils.secureTable
local secureFunction = utils.secureFunction
local isCallSecure = utils.isCallSecure
local isNumberSecure = utils.isNumberSecure

utils.OpContainer = utils.OpContainer or {

	SafeHouse = secureTable(SafeHouse),
	SandboxVars = secureTable(SandboxVars),

	ISMoveablesAction = secureTable(ISMoveablesAction),
	ISDestroyStuffAction = secureTable(ISDestroyStuffAction),
	ISMoveableSpriteProps = secureTable(ISMoveableSpriteProps),

	getText = secureFunction(getText),
	isClient = secureFunction(isClient),
	isServer = secureFunction(isServer),
	instanceof = secureFunction(instanceof),
	getTimestampMs = secureFunction(getTimestampMs),

	ISMoveableDefinitions = secureTable(ISMoveableDefinitions)
}

local OpContainer = utils.OpContainer

---@class OPCOptions
---@field safeHouseCooldown integer
---@field safeHousePermission boolean

local SafeHouse = OpContainer.SafeHouse
local Options = OpContainer.SandboxVars.OpContainer--[[@as OPCOptions]]
local BlockedMoveableModes = {pickup = true, rotate = true, scrap = true}

local ISMoveablesAction = OpContainer.ISMoveablesAction
local ISDestroyStuffAction = OpContainer.ISDestroyStuffAction
local ISMoveableSpriteProps = OpContainer.ISMoveableSpriteProps

local getText = OpContainer.getText
local isClient = OpContainer.isClient
local isServer = OpContainer.isServer
local instanceof = OpContainer.instanceof
local getTimestampMs = OpContainer.getTimestampMs

OpContainer.Legacy = OpContainer.Legacy or {

	moveableIsValid = secureFunction(ISMoveablesAction.isValid),
	destroyIsValid = secureFunction(ISDestroyStuffAction.isValid), ---@diagnostic disable-next-line: param-type-mismatch
	placeMoveableInternal = secureFunction(ISMoveableSpriteProps.placeMoveableInternal)
}

local Legacy = OpContainer.Legacy
local ISMoveableDefinitions = OpContainer.ISMoveableDefinitions

---------------------------
-- Funciones auxiliares: --
---------------------------

-- Verifica si un objeto es de interés para este mod.
---@param object IsoObject? El objeto que se evaluará.
---@return boolean isRelevant Si es un objeto relevante.
local function isRelevantObject(object)

	-- Validar objeto, que el objeto no sea golpeable, y no haya sido colocado por un jugador.
	---@cast object -?
	if not instanceof(object, "IsoObject")
		or instanceof(object, "IsoThumpable")
		or (isCallSecure(object.isMovedThumpable) and object:isMovedThumpable())
		or (isCallSecure(object.getModData) and object:getModData().isPlayerPlaced)
	then
		return false
	end

	local containerCount = isCallSecure(object.getContainerCount) and object:getContainerCount()

	-- Validar que el objeto tenga al menos un contenedor.
	if not isNumberSecure(containerCount) or containerCount < 1 then
		return false
	end

	return true
end

-- Verifica si el jugador debería tener permitido alterar un objeto en una baldosa en específico.
---@param character IsoPlayer El personaje que intenta realizar la acción.
---@param square IsoGridSquare La baldosa de mapa donde se encuentra el objeto.
---@return boolean isPlayerAllowed Si se permite la alteración.
---@return string? msg Un mensaje, si debe mostrarse un mensaje al usuario por esto.
local function isPlayerAllowedOnSquare(character, square)
	local safehouse = isCallSecure(SafeHouse.getSafeHouse) and SafeHouse.getSafeHouse(square)

	-- Validar que el objeto esté en una safehouse, y el jugador esté permitido en ella.
	---@cast safehouse -?
	if not instanceof(safehouse, "SafeHouse")
		or not (isCallSecure(safehouse.playerAllowed) and safehouse:playerAllowed(character))
		or not isCallSecure(safehouse.getDatetimeCreated)
	then
		return false
	end

	local current = getTimestampMs()
	local cooldown = Options.safeHouseCooldown
	local created = safehouse:getDatetimeCreated()

	-- Validar que ya haya pasado el tiempo de enfriamiento de la safehouse.
	if not isNumberSecure(current) or not isNumberSecure(created) or not isNumberSecure(cooldown)
		or not (isCallSecure(math.abs) and isCallSecure(math.floor))
	then
		return false
	end

	local elapsed = ((current - created) / 1000 / 60) - cooldown
	local elapsedFloor = math.floor(elapsed)

	if elapsed < 0 then
		return false, tostring(getText("IGUI_HaloNote_OpContainer_SafeHouseCooldown", tostring(math.abs(
			(isNumberSecure(elapsedFloor) and elapsedFloor) or 0
		))))
	end

	return true
end

------------------------
-- Función principal: --
------------------------

---@alias CustomItem {object:IsoObject?} -- Un objeto del grupo de un objeto multi-sprite.
---@alias CustomGridCache CustomItem[] -- La parte de gridCache que le interesa a este mod.

-- Verifica si se puede realizar una acción sobre un objeto según el criterio de este mod, considerando a objetos multi-sprite.
-- Los objetos multi-sprite tienen a otros objetos asociados en celdas adyacentes, y deben tratarse como un único objeto.
---@param object IsoObject? El objeto sobre el que se intenta realizar la acción.
---@param character IsoPlayer? El personaje que intenta realizar la acción.
---@param square IsoGridSquare? La baldosa de mapa donde se encuentra el objeto.
---@param moveProps ISMoveableSpriteProps? Las propiedades del sprite asociado al objeto.
---@return boolean isProtectedObject Si el objeto será protegido por este mod.
local function isProtectedObject(object, character, square, moveProps)

	-- Validar entorno y objeto.
	if not (isClient() or isServer()) or not instanceof(object, "IsoObject") then
		return false
	end ---@cast object -?

	square = square or (isCallSecure(object.getSquare) and object:getSquare())
	square = (instanceof(square, "IsoGridSquare") and square) or nil

	-- Asegurar y validar caché de cuadrícula.
	moveProps = secureTable(moveProps or (
		isCallSecure(ISMoveableSpriteProps.fromObject) and ISMoveableSpriteProps.fromObject(object)
	))--[[@as ISMoveableSpriteProps]]

	local isRelevant = false

	-- Buscar si alguno de los miembros es relevante, lo que vuelve relevante al objeto.
	for _, member in pairs(secureTable(((moveProps.isMultiSprite and isCallSecure(moveProps.getSpriteGridInfo))
		and (square and moveProps:getSpriteGridInfo(square, true))) or {{object = object}}
	)--[[@as CustomGridCache]]) do

		if isRelevantObject(secureTable(member).object) then
			isRelevant = true
			break
		end
	end

	-- Si el objeto no es relevante, no hay un jugador, o no hay baldosa, devolver si es un objeto relevante.
	if not isRelevant or not instanceof(character, "IsoPlayer")
		or not instanceof(square, "IsoGridSquare")
	then
		return isRelevant
	end ---@cast character -? ---@cast square -?

	local isAllowed, msg = isPlayerAllowedOnSquare(character, square)

	-- Validar que el jugador no esté permitido en la baldosa.
	if Options.safeHousePermission and isAllowed then
		return false
	end

	-- Si se está del lado del cliente, notificar al usuario sobre el objeto protegido.
	if isClient() and isCallSecure(character.setHaloNote) then
		character:setHaloNote(
			msg or tostring(getText("IGUI_HaloNote_OpContainer_Protected")), 255, 0, 0, 200
		)
	end

	return true
end

--------------
-- Parches: --
--------------

-- Se aplica a ISMoveablesAction:isValid.
-- Valida si un objeto puede recogerse, rotarse, y desmontarse, pero ahora protege los contenedores con reloot.
---@param self ISMoveablesAction Una instancia de la clase a la que pertenece la función a la que parcha.
---@return boolean isValid Si la acción es válida.
function OpContainer.moveablesActionIsValid(self)
	local isValid = Legacy.moveableIsValid(self)
	local character = self.character

	if not isValid or not BlockedMoveableModes[self.mode] or ISMoveableDefinitions.cheat
		or not instanceof(character, "IsoPlayer")
		or (isCallSecure(character.isMovablesCheat) and character:isMovablesCheat())
	then
		return isValid
	end

	return not isProtectedObject(self.object, character, self.square, self.moveProps)
end

-- Se aplica a ISDestroyStuffAction:isValid.
-- Valida si un objeto puede ser destruído con una almádena, pero ahora protege los contenedores con reloot.
---@param self ISDestroyStuffAction Una instancia de la clase a la que pertenece la función a la que parcha.
---@return boolean isValid Si la acción es válida.
function OpContainer.destroyActionIsValid(self)
	local isValid = Legacy.destroyIsValid(self)
	local character = self.character

	if not isValid
		or not instanceof(character, "IsoPlayer")
		or (isCallSecure(character.isBuildCheat) and character:isBuildCheat())
	then
		return isValid
	end

	return not isProtectedObject(self.item, character, nil, nil)
end

-- Se aplica a ISMoveableSpriteProps:placeMoveableInternal.
-- Marca como isPlayerPlaced a todos los objetos de interés colocados que no se vuelven golpeables al colocarlos.
-- Esto ayuda a diferenciarlos en casos especiales de los objetos que sí deben protegerse, como con los maniquíes.
---@param self ISMoveableSpriteProps Una instancia de la clase a la que pertenece la función a la que parcha.
---@param square IsoGridSquare La baldosa de mapa donde se colocará el objeto.
---@param item InventoryItem El item correspondiente al objeto que se colocará.
---@param spriteName string El nombre del sprite del objeto que se colocará.
---@return IsoObject? object El objeto que fue colocado.
function OpContainer.placeMoveableInternal(self, square, item, spriteName)
	local object = Legacy.placeMoveableInternal(self, square, item, spriteName)

	---@cast object -?
	if not isServer()
		or not isProtectedObject(object, nil, square, nil)
		or not (isCallSecure(object.getModData) and isCallSecure(object.transmitModData))
	then
		return object
	end

	local modData = object:getModData()--[[@as {isPlayerPlaced:boolean}]]

	if not modData.isPlayerPlaced then
		modData.isPlayerPlaced = true; object:transmitModData()
	end

	return object
end

----------------
-- Enganches: --
----------------

-- SOBRESCRIBIENDO FUNCIONES VANILLA:
-- En shared/Moveables/ISMoveablesAction.lua
-- En shared/Moveables/ISMoveableSpriteProps.lua
-- En shared/TimedActions/ISDestroyStuffAction.lua

if not OpContainer.isGamePatched--[[@as boolean]] then

	function ISMoveablesAction:isValid()
		return OpContainer.moveablesActionIsValid(self)
	end; function ISDestroyStuffAction:isValid()
		return OpContainer.destroyActionIsValid(self)
	end; function ISMoveableSpriteProps:placeMoveableInternal(_square, _item, _spriteName)
		return OpContainer.placeMoveableInternal(self, _square, _item, _spriteName)
	end

	OpContainer.isGamePatched = true
end

print("[OpContainer]: Loaded and ready.")

-- Los últimos commits solucionaron las inconsistencias leves reportadas previamente, pero mientras lo hacía, accidentalmente
--- removí cualquier protección del lado del servidor. De cualquier forma, esta protección no era más que un placebo debido a
--- que los contenedores aún podían destruírse con paquetes "falsos", así que no lo considero un problema crítico. Sin embargo,
--- entiendo que debería solucionarlo en los próximos meses.
