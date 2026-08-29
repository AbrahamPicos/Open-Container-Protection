-- OpContainer.lua
-- Licence: CC0-1.0(Visit https://creativecommons.org/publicdomain/zero/1.0/ to view details).
-- Maintainer: AbrahamPicos.
-- Contributors:

require("OpContainer_secureUtils")

local utils = _07ca70cd7c514861b4b3897cbf56f40a

if not utils then return end

-----------------------------------------
-- Caché de clases, métodos, y tablas: --
-----------------------------------------

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
---@field vehicleInteriorPermission boolean

local SafeHouse = OpContainer.SafeHouse
local Options = secureTable(OpContainer.SandboxVars.OpContainer--[[@as OPCOptions]])
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
local function isObjectRelevant(object)

	-- Validar objeto, que el objeto no sea golpeable, y que no haya sido colocado por un jugador.
	---@cast object -?
	if not instanceof(object, "IsoObject")
		or instanceof(object, "IsoThumpable")
		or (isCallSecure(object.isMovedThumpable) and object:isMovedThumpable())
		or (isCallSecure(object.getModData) and secureTable(object:getModData()).isPlayerPlaced)
	then
		return false
	end

	local containersCount = isCallSecure(object.getContainerCount) and object:getContainerCount()

	-- Validar que el objeto tenga al menos un contenedor.
	if not isNumberSecure(containersCount) or containersCount < 1 then
		return false
	end

	-- Devolver verdadero.
	return true
end

-- Verifica si el jugador debería tener permitido alterar un objeto en una baldosa en específico.
---@param character IsoPlayer El personaje que intenta realizar la acción.
---@param square IsoGridSquare La baldosa de mapa donde se encuentra el objeto.
---@return boolean isPlayerAllowed Si se permite la alteración.
---@return string? msg Un mensaje, si debería mostrarse un mensaje al usuario por esto.
local function isPlayerAllowedOnSquare(character, square)

	-- Si el jugador está en un interior del mod Project RV Interior, permitir.
	if Options.vehicleInteriorPermission and (isCallSecure(character.getX) and isCallSecure(character.getY)) then
		local x, y = character:getX(), character:getY()

		if (isNumberSecure(x) and isNumberSecure(y)) and (x > 22500 and y > 12000) then
			return true
		end
	end

	local safehouse = (Options.safeHousePermission and isCallSecure(SafeHouse.getSafeHouse))
		and SafeHouse.getSafeHouse(square) or nil

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

	-- Validar que ya haya pasado el tiempo de espera de la safehouse.
	if not (isNumberSecure(current) and isNumberSecure(created) and isNumberSecure(cooldown))
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

	-- Devolver verdadero.
	return true
end

------------------------
-- Función principal: --
------------------------

---@alias CustomItem {object:IsoObject?} -- Un objeto del grupo de un objeto multi-sprite.
---@alias CustomGridCache CustomItem[] -- La parte de SpriteGridCache que le interesa a este mod.

-- Verifica si se puede realizar una acción sobre un objeto según el criterio de este mod, considerando a objetos multi-sprite.
-- Los objetos multi-sprite tienen a otros objetos asociados en celdas adyacentes, y deben tratarse como un único objeto.
---@param object IsoObject? El objeto sobre el que se intenta realizar la acción.
---@param character IsoPlayer? El personaje que intenta realizar la acción.
---@param square IsoGridSquare? La baldosa de mapa donde se encuentra el objeto.
---@param moveProps ISMoveableSpriteProps? Las propiedades del sprite asociado al objeto.
---@return boolean isObjectProtected Si el objeto será protegido por este mod.
local function isObjectProtected(object, character, square, moveProps)

	-- Validar entorno y objeto.
	if not (isClient() or isServer()) or not instanceof(object, "IsoObject") then
		return false
	end ---@cast object -?

	-- Asegurar baldosa.
	square = square or (isCallSecure(object.getSquare) and object:getSquare())
	square = (instanceof(square, "IsoGridSquare") and square) or nil

	-- Asegurar las propiedades del sprite asociado objeto.
	moveProps = secureTable(moveProps or (
		isCallSecure(ISMoveableSpriteProps.fromObject) and ISMoveableSpriteProps.fromObject(object)
	))--[[@as ISMoveableSpriteProps]]

	local isRelevant = false

	-- Asegurar caché de cuadrícula, y buscar si alguno de los miembros es relevante (lo que vuelve relevante al objeto).
	for _, member in pairs(secureTable(((moveProps.isMultiSprite and isCallSecure(moveProps.getSpriteGridInfo))
		and (square and moveProps:getSpriteGridInfo(square, true))) or {{object = object}}
	)--[[@as CustomGridCache]]) do

		if isObjectRelevant(secureTable(member).object) then
			isRelevant = true
			break
		end
	end

	-- Si el objeto no es relevante, no hay jugador, o no hay baldosa, devolver si es un objeto relevante.
	if not isRelevant
		or not instanceof(character, "IsoPlayer")
		or not instanceof(square, "IsoGridSquare")
	then
		return isRelevant
	end ---@cast character -? ---@cast square -?

	local isAllowed, msg = isPlayerAllowedOnSquare(character, square)

	-- Validar que el jugador no esté permitido en la baldosa.
	if isAllowed then
		return false
	end

	-- Si se está del lado del cliente, notificar al jugador la razón.
	if isClient() and isCallSecure(character.setHaloNote) then
		character:setHaloNote(
			msg or tostring(getText("IGUI_HaloNote_OpContainer_Protected")), 255, 0, 0, 200
		)
	end

	-- Devolver verdadero.
	return true
end

--------------
-- Parches: --
--------------

-- Se aplica a ISMoveablesAction:isValid.
-- Valida si un objeto puede recogerse, rotarse, y desmantelarse. según el criterio de este mod.
---@param self ISMoveablesAction Una instancia de la clase a la que pertenece la función a la que parcha.
---@return boolean isValid Si la acción es válida.
function OpContainer.moveablesActionIsValid(self)
	local isValid = Legacy.moveableIsValid(self)
	local character = self.character

	-- Si la acción no es válida, el modo no está bloqueado, no hay jugador, o el jugador está usando el MoveablesCheat,
	--- devolver si la acción es válida.
	if not isValid
		or not BlockedMoveableModes[self.mode] or ISMoveableDefinitions.cheat
		or not instanceof(character, "IsoPlayer")
		or (isCallSecure(character.isMovablesCheat) and character:isMovablesCheat())
	then
		return isValid
	end

	-- Devolver si el objeto está protegido por este mod.
	return not isObjectProtected(self.object, character, self.square, self.moveProps)
end

-- Se aplica a ISDestroyStuffAction:isValid.
-- Valida si un objeto puede ser destruído con una almádena, según el criterio de este mod.
---@param self ISDestroyStuffAction Una instancia de la clase a la que pertenece la función a la que parcha.
---@return boolean isValid Si la acción es válida.
function OpContainer.destroyActionIsValid(self)
	local isValid = Legacy.destroyIsValid(self)
	local character = self.character

	-- Si la acción no es válida, no hay jugador, o el jugador está usando el BuildCheat, devolver si la acción es válida.
	if not isValid
		or not instanceof(character, "IsoPlayer")
		or (isCallSecure(character.isBuildCheat) and character:isBuildCheat())
	then
		return isValid
	end

	-- Devolver si el objeto está protegido por este mod.
	return not isObjectProtected(self.item, character, nil, nil)
end

-- Se aplica a ISMoveableSpriteProps:placeMoveableInternal.
-- Marca como isPlayerPlaced a todos los objetos de interés colocados que no se vuelven golpeables al colocarlos.
-- Esto ayuda a diferenciarlos en casos especiales de los objetos que sí deben protegerse, como con los maniquíes.
---@param self ISMoveableSpriteProps Una instancia de la clase a la que pertenece la función a la que parcha.
---@param square IsoGridSquare La baldosa de mapa donde se colocará al objeto.
---@param item InventoryItem El item correspondiente al objeto que se colocará.
---@param spriteName string El nombre del sprite del objeto que se colocará.
---@return IsoObject? object El objeto que fue colocado.
function OpContainer.placeMoveableInternal(self, square, item, spriteName)
	local object = Legacy.placeMoveableInternal(self, square, item, spriteName)

	-- Si no se está del lado del servidor, o el objeto no es relevante, devolver el objeto.
	---@cast object -?
	if not isServer()
		or not isObjectProtected(object, nil, square, nil) -- Esto también valida al objeto.
		or not (isCallSecure(object.getModData) and isCallSecure(object.transmitModData))
	then
		return object
	end

	local modData = secureTable(object:getModData())--[[@as {isPlayerPlaced:boolean}]]

	-- Si el objeto aún no estaba marcado como colocado por un jugador, marcar, y sincronizar con los clientes.
	if not modData.isPlayerPlaced then
		modData.isPlayerPlaced = true; object:transmitModData()
	end

	-- Devolver objeto.
	return object
end

----------------
-- Enganches: --
----------------

-- SOBRESCRIBIENDO FUNCIONES VANILLA:
-- En shared/Moveables/ISMoveablesAction.lua
-- En shared/Moveables/ISMoveableSpriteProps.lua
-- En shared/TimedActions/ISDestroyStuffAction.lua

-- Si aún no se ha hecho, aplicar los parches usando la técnica de monkey patching.
if not OpContainer.isGamePatched--[[@as boolean]] then

	function ISMoveablesAction:isValid()
		return OpContainer.moveablesActionIsValid(self)
	end; function ISDestroyStuffAction:isValid()
		return OpContainer.destroyActionIsValid(self)
	end; function ISMoveableSpriteProps:placeMoveableInternal(_square, _item, _spriteName)
		return OpContainer.placeMoveableInternal(self, _square, _item, _spriteName)
	end

	OpContainer.isGamePatched = true -- Previene inconsistencias graves si el archivo es recargado.
end

print("[OpContainer]: Loaded and ready.")

-- La opción para no proteger los contenedores en los interiores del mod "Project RV Interior" dejará sin proteger a todos
--- los contenedores en esas habitaciones. Hace falta una integración con un mod de protección de vehículos para sólo permitir
--- al jugador en los contenedores que le corresponden.

-- Los últimos commits solucionaron las inconsistencias leves reportadas previamente, pero mientras lo hacía, accidentalmente
--- removí cualquier protección del lado del servidor. De cualquier forma, esta protección no era más que un placebo debido a
--- que los contenedores aún podían destruirse con paquetes "falsos", -lo que ocurre en todos los mods de este tipo-, así que no
--- lo considero un problema crítico. Sin embargo, entiendo que debería solucionarlo en los próximos meses.
