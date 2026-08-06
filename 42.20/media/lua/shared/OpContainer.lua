-- OpContainer.lua
-- Licence: CC0-1.0(Visit https://creativecommons.org/publicdomain/zero/1.0/ to view details).
-- Maintainer: AbrahamPicos.
-- Contributors:

------------------------------
-- Utilidades de seguridad: --
------------------------------

local type = type -- El pilar que sostiene a este mod.

-- Verifica si es seguro intentar indexar una tabla.
---@param o any La tabla que se indexará.
---@return true|nil isSecure si la tabla es segura.
local function isTableSecure(o)

	if type(o) == "table" then
		return true
	end

	return nil
end

-- Devuelve una tabla si no la había.
---@generic T
---@param t T La supuesta tabla.
---@return T t Una tabla.
local function secureTable(t)

	if isTableSecure(t) then
		return t
	end

	return {}
end

-- Verifica si es seguro intentar llamar a una función.
---@param c function La función que quiere llamar.
---@return true|nil isSecure Si es seguro hacerlo.
local function isCallSecure(c)

	if type(c) == "function" then
		return true
	end

	return nil
end

-- Devuelve una función si no la había.
---@generic F
---@param f F La supuesta función.
---@return F object Una función.
local function secureFunction(f)

	if isCallSecure(f) then
		return f
	end

	return function (...) return false end
end

-----------------------------------------
-- Caché de clases, métodos, y tablas: --
-----------------------------------------

OpContainer = OpContainer or {

	SafeHouse = secureTable(SafeHouse),

	ISMoveablesAction = secureTable(ISMoveablesAction),
	ISDestroyStuffAction = secureTable(ISDestroyStuffAction),
	ISMoveableSpriteProps = secureTable(ISMoveableSpriteProps),

	pairs = pairs,
	print = print,
	getText = secureFunction(getText),
	isClient = secureFunction(isClient),
	isServer = secureFunction(isServer),
	instanceof = secureFunction(instanceof),

	ISMoveableDefinitions = secureTable(ISMoveableDefinitions)
}

local OpContainer = OpContainer
local SafeHouse = OpContainer.SafeHouse
local BlockedMoveableModes = {pickup = true, rotate = true, scrap = true}

local ISMoveablesAction = OpContainer.ISMoveablesAction
local ISDestroyStuffAction = OpContainer.ISDestroyStuffAction
local ISMoveableSpriteProps = OpContainer.ISMoveableSpriteProps

local pairs = OpContainer.pairs
local print = OpContainer.print
local getText = OpContainer.getText
local isClient = OpContainer.isClient
local isServer = OpContainer.isServer
local instanceof = OpContainer.instanceof
local getSafeHouse = secureFunction(SafeHouse.getSafeHouse)

OpContainer.Legacy = OpContainer.Legacy or {

	moveableIsValid = secureFunction(ISMoveablesAction.isValid),
	destroyIsValid = secureFunction(ISDestroyStuffAction.isValid), ---@diagnostic disable-next-line: param-type-mismatch
	placeMoveableInternal = secureFunction(ISMoveableSpriteProps.placeMoveableInternal)
}

local Legacy = OpContainer.Legacy
local ISMoveableDefinitions = OpContainer.ISMoveableDefinitions

local getMovePropsFromObject = secureFunction(ISMoveableSpriteProps.fromObject)

---------------------------
-- Funciones auxiliares: --
---------------------------

-- Verifica si un objeto es de interés para este mod.
---@param object IsoObject? El objeto que se evaluará.
---@return boolean isRelevant Si es un objeto relevante.
local function isRelevantObject(object)

	---@cast object -?
	-- Validar que el objeto exista, esté en el mundo, que no sea golpeable, y que no haya sido colocado por un jugador.
	if not instanceof(object, "IsoObject")
		or not (isCallSecure(object.getSquare) and instanceof(object:getSquare(), "IsoGridSquare"))
		or instanceof(object, "IsoThumpable")
		or (isCallSecure(object.isMovedThumpable) and object:isMovedThumpable())
		or (isCallSecure(object.getModData) and object:getModData().IsPlayerPlaced)
	then
		return false
	end

	local containerCount = isCallSecure(object.getContainerCount) and object:getContainerCount()

	-- Validar que el objeto tenga al menos un contenedor.
	if type(containerCount) ~= "number" or containerCount < 1 then
		return false
	end

	return true
end

-- Verifica si se puede realizar una acción sobre un objeto según el criterio de este mod, considerando a objetos multi-sprite.
-- Los objetos multi-sprite tienen a otros objetos asociados en celdas adyacentes, y deben tratarse como un único objeto.
---@alias CustomItem {object:IsoObject?}
---@alias CustomGridCache table<number,CustomItem>
---@param moveProps ISMoveableSpriteProps? Las propiedades del sprite asociado al objeto.
---@param character IsoPlayer? El personaje que intenta realizar la acción.
---@param square IsoGridSquare? La baldosa de mapa donde se encuentra el objeto.
---@param object IsoObject? El objeto sobre el que se intenta realizar la acción.
---@return boolean isProtectedObject Si se puede realizar una acción sobre el objeto.
local function isProtectedObject(moveProps, character, square, object)

	-- Validar entorno y objeto.
	if not (isClient() or isServer()) or not instanceof(object, "IsoObject") then
		return false
	end ---@cast object -?

	-- Asegurar y validar baldosa.
	square = square or (isCallSecure(object.getSquare) and object:getSquare())

	if not instanceof(square, "IsoGridSquare") then
		return false
	end ---@cast square -?

	-- Asegurar y validar caché de cuadrícula.
	moveProps = secureTable(moveProps or getMovePropsFromObject(object))

	local grid = secureTable((moveProps.isMultiSprite and isCallSecure(moveProps.getSpriteGridInfo))
		and moveProps:getSpriteGridInfo(square, true))--[[@as CustomGridCache]]
	local hasValidGird = false

	for _, member in pairs(grid) do

		if secureTable(member).object == object then
			hasValidGird = true
			break
		end
	end

	if not hasValidGird then
		grid = {[1] = {object = object}}
	end ---@cast grid CustomGridCache

	local isRelevant = false

	-- Buscar si alguno de los miembros debería protegerse.
	for _, member in pairs(grid) do

		if isRelevantObject(secureTable(member).object) then
			isRelevant = true
			break
		end
	end

	-- Si no hay un jugador, o el objeto no es relevante, devolver si es un objeto relevante.
	if not isRelevant or not instanceof(character, "IsoPlayer") then
		return isRelevant
	end ---@cast character -?

	local safehouse = getSafeHouse(square)

	-- Validar que si el objeto está en una safehouse, el jugador no esté permitido en ella.
	if instanceof(safehouse, "SafeHouse")
		and (isCallSecure(safehouse.playerAllowed) and safehouse:playerAllowed(character))
	then
		return false
	end

	-- Si se está del lado del cliente, notificar al usuario.
	if isClient() and isCallSecure(character.setHaloNote) then
		character:setHaloNote(getText("IGUI_HaloNote_OpContainer_Protected") or "", 255, 0, 0, 200)
	end

	return true
end

--------------
-- Parches: --
--------------

-- Se aplica a ISMoveablesAction:isValid.
-- Valida si un objeto puede recogerse, rotarse, y desmontarse, pero ahora protege los contenedores con reloot.
---@param self ISMoveablesAction La clase a la que pertenece la función a la que parcha.
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

	return not isProtectedObject(self.moveProps, character, self.square, self.object)
end

-- Se aplica a ISDestroyStuffAction:isValid.
-- Valida si un objeto puede ser destruído con una almádena, pero ahora protege los contenedores con reloot.
---@param self ISDestroyStuffAction La clase a la que pertenece la función a la que parcha.
---@return boolean isValid Si la acción es válida.
function OpContainer.destroyActionIsValid(self)
	local isValid = Legacy.destroyIsValid(self)
	local character = self.character
	local object = self.item

	if not isValid or not instanceof(character, "IsoPlayer")
		or (isCallSecure(character.isBuildCheat) and character:isBuildCheat())
	then
		return isValid
	end

	return not isProtectedObject(nil, character, nil, object)
end

-- Marca como isPlayerPlaced a todos los objetos de interés colocados que no se vuelven golpeables al colocarlos.
-- Esto ayuda a diferenciarlos en casos especiales de los objetos que sí deben protegerse, como con los maniquíes.
---@param self ISMoveableSpriteProps La clase a la que pertenece la función a la que parcha.
---@param square IsoGridSquare La baldosa de mapa donde se colocará el objeto.
---@param item InventoryItem El item correspondiente al objeto que se colocará.
---@param spriteName string El nombre del sprite del objeto que se colocará.
function OpContainer.placeMoveableInternal(self, square, item, spriteName)
	local object = Legacy.placeMoveableInternal(self, square, item, spriteName)

	---@cast object -?
	if not isServer()
		or not isProtectedObject(nil, nil, nil, object)
		or not (isCallSecure(object.getModData) and isCallSecure(object.transmitModData))
	then
		return object
	end

	local modData = object:getModData()

	if not modData.IsPlayerPlaced--[[@as boolean]] then
		modData.IsPlayerPlaced = true; object:transmitModData()
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

-- Esto indudablemente evita que rompan los contenedores, pero causa inconsistencias leves que los usuarios notarán.
