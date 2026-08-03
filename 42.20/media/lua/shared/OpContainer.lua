-- OpContainer.lua
-- Licence: CC0-1.0(Visit https://creativecommons.org/publicdomain/zero/1.0/ to view details).
-- Maintainer: AbrahamPicos.
-- Contributors:

-- Corrigiendo un campo faltante en Umbrella.
---@class ISMoveableSpriteProps
---@field object IsoObject

---@alias CanScrapResult umbrella.ISMoveableSpriteProps.CanScrapResult -- Por practicidad.

------------------------------
-- Utilidades de seguridad: --
------------------------------

local type = type -- El pilar que sostiene a este mod.

-- Devuélve una tabla si no la había.
---@generic T
---@param t T La supuesta tabla.
---@return T t Una tabla.
local function secureTable(t)

	if type(t) == "table" then
		return t
	end

	return {}
end

-- Devuélve una función si no la había.
---@generic F
---@param f F La supuesta función.
---@return F object Una función.
local function secureFunction(f)

	if type(f) == "function" then
		return f
	end

	return function (...) return false end
end

-- Verifica si es seguro intentar llamar a una función.
---@param call function La función que quiere llamar.
---@return boolean isSecure Si es seguro hacerlo.
local function isCallSecure(call)

	if type(call) == "function" then
		return true
	end

	return false
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
	getText = secureFunction(getText),
	isClient = secureFunction(isClient),
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
local getText = OpContainer.getText
local isClient = OpContainer.isClient
local instanceof = OpContainer.instanceof
local getSafeHouse = secureFunction(SafeHouse.getSafeHouse)

OpContainer.Legacy = OpContainer.Legacy or {

	moveableIsValid = secureFunction(ISMoveablesAction.isValid),
	destroyIsValid = secureFunction(ISDestroyStuffAction.isValid)
}

local Legacy = OpContainer.Legacy
local ISMoveableDefinitions = OpContainer.ISMoveableDefinitions

local getMovePropsFromObject = secureFunction(ISMoveableSpriteProps.fromObject)

---------------------------
-- Funciones auxiliares: --
---------------------------

-- Verifica si se puede realizar una acción sobre un objecto individual, según el criterio de este mod.
---@param character IsoGameCharacter El personaje que intenta realizar la acción.
---@param square IsoGridSquare La baldosa de mapa donde se encuentra el objeto.
---@param object IsoObject? El objeto que se está evaluando. Puede ser cualquier cosa basada en IsoObject.
---@return boolean canAction Si se puede realizar una acción sobre el objeto.
local function checkObject(character, square, object)

	-- Validar personaje, objeto, y que el objeto esté en el mundo y no sea golpeable.
	if instanceof(object, "IsoThumpable")
		or not instanceof(object, "IsoObject")
		or not instanceof(character, "IsoGameCharacter")
		or not instanceof(square, "IsoGridSquare")
	then
		return true
	end ---@cast object -? -- Garantizado por instanceof.

	-- Validar que el objeto sea un contenedor.
	if not isCallSecure(object.hasProperty) or not object:hasProperty("container") then

		-- No podemos proteger esto actualmente.
		if instanceof(object, "IsoMannequin") then
			return true
		end

		local containerCount = isCallSecure(object.getContainerCount) and object:getContainerCount()

		-- Si además de no tener la etiqueta, tampoco tiene algún inventario, no es un contenedor.
		if type(containerCount) ~= "number" or containerCount < 1 then
			return true
		end
	end

	-- Si el personaje no es un jugador, denegar acción.
	if not instanceof(character, "IsoPlayer") then
		return false -- Dudo que esto se use en NPCs, pero bueno.
	end

	local safehouse = getSafeHouse(square)

	-- Si el objeto está en una safehouse, y el jugador está permitido en ella, permitir acción.
	if instanceof(safehouse, "SafeHouse") and isCallSecure(safehouse.playerAllowed) then
		return safehouse:playerAllowed(character)
	end

	return false
end

-- Verifica si se puede realizar una acción sobre un objeto, según el criterio de este mod, considerando a objetos multi-sprite.
-- Los objetos multi-sprite tienen a otros objetos asociados en celdas adyacentes, y deben tratarse como un único objeto.
---@param moveProps ISMoveableSpriteProps Las propiedades del sprite asociado al objeto.
---@param character IsoPlayer El personaje que intenta realizar la acción.
---@param square IsoGridSquare La baldosa de mapa donde se encuentra el objeto.
---@param object IsoObject? El objeto sobre el que se intenta realizar la acción.
---@return boolean canAction Si se puede realizar una acción sobre el objeto.
local function checkMultiSpriteObject(moveProps, character, square, object)
	moveProps = secureTable(moveProps)

	local grid = (moveProps.isMultiSprite and isCallSecure(moveProps.getSpriteGridInfo))
		and moveProps:getSpriteGridInfo(square, true)
		or {{object = object}}

	if type(grid) ~= "table" then
		return true
	end

	local canAction = true

	-- Buscar si alguno de los miembros debería protegerse. Si es así, denegar acción.
	for _, member in pairs(grid) do

		if not checkObject(character, square, member.object) then
			canAction = false
		end
	end

	if not canAction and isClient() and isCallSecure(character.setHaloNote) then
		character:setHaloNote(getText("IGUI_HaloNote_OpContainer_Protected"), 255, 0, 0, 200)
	end

	return canAction
end

--------------
-- Parches: --
--------------

-- Se aplica a ISMoveablesAction:isValid.
-- Verifica si un objeto puede recogerse, rotarse, y desmontarse, pero ahora protege los contenedores con reloot.
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

	return checkMultiSpriteObject(self.moveProps, character, self.square, self.object)
end

-- Se aplica a ISDestroyStuffAction:isValid.
-- Valida si un objeto puede ser destruído con una almádena, pero ahora protege los contenedores con reloot.
---@param self ISDestroyStuffAction La clase a la que pertenece la función a la que parcha.
---@return boolean isValid Si la acción es válida.
function OpContainer.destroyActionIsValid(self)
	local isValid = Legacy.destroyIsValid(self)
	local character = self.character
	local object = self.item

	if not isValid
		or not instanceof(character, "IsoPlayer")
		or (isCallSecure(character.isBuildCheat) and character:isBuildCheat())
		or not (instanceof(object, "IsoObject") and isCallSecure(object.getSquare))
	then
		return isValid
	end

	return checkMultiSpriteObject(
		getMovePropsFromObject(object), character, object:getSquare(), object
	)
end

----------------
-- Enganches: --
----------------

-- SOBRESCRIBIENDO FUNCIONES VANILLA:
-- En shared/Moveables/ISMoveablesAction.lua
-- En shared/TimedActions/ISDestroyStuffAction.lua

function ISMoveablesAction:isValid()
	return OpContainer.moveablesActionIsValid(self)
end; function ISDestroyStuffAction:isValid()
	return OpContainer.destroyActionIsValid(self)
end

-- Esto indudablemente evita que rompan los contenedores, pero causa inconsistencias leves que los usuarios notarán.
