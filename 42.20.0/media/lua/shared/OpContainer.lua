-- OpContainer.lua
-- Licence: CC0-1.0(Visit https://creativecommons.org/publicdomain/zero/1.0/ to view details).
-- Maintainer: AbrahamPicos.
-- Contributors: 

-- SOBRESCRIBIENDO FUNCIONES VANILLA:
-- En shared/Moveables/ISMoveablesAction.lua
-- En shared/Moveables/ISMoveableSpriteProps.lua
-- En shared/TimedActions/ISDestroyStuffAction.lua

-- Estas modificaciones protegen los contenedores de la forma más fiable posible, negando absolutamente cualquier acción sobre
--- ellos, pero no pueden proporcionar indicaciones al usuario.
-- Por favor, añada mensajes que indiquen al usuario por qué no puede realizar acciones con estos objetos.
-- No protege maniquies debido a limitaciones técnicas. Consiga una forma de protegerlos.

local legacyMoveableIsValid = ISMoveablesAction.isValid
local legacyDestroyIsValid = ISDestroyStuffAction.isValid
local legacyCanScrapObject = ISMoveableSpriteProps.canScrapObject
local legacyCanPickUpMoveableInternal = ISMoveableSpriteProps.canPickUpMoveableInternal

-- Verifica si se puede realizar una acción sobre un contenedor, según el criterio de este mod.
-- Los tipos se vefician de forma aparentemente inecesaria, porque el código vanilla sugiere que pueden ser diferentes.
---@param character IsoObject El personaje que intenta realizar la acción.
---@param square IsoGridSquare? La baldosa de mapa donde se encuentra el objeto.
---@param object IsoObject El objecto que se está evaluando. Puede ser cualquier cosa basada en IsoObject.
---@return boolean canAction Si se puede realizar una acción sobre el objeto.
local function canAction(character, square, object)

	-- Validar personaje, objeto, y que el objeto no sea golpeable.
	if not instanceof(character, "IsoGameCharacter")
		or not instanceof(object, "IsoObject")
		or instanceof(object, "IsoThumpable")
	then
		return true
	end

	square = square or object:getSquare()

	-- Validar que el objeto esté en el mundo.
	if not instanceof(square, "IsoGridSquare") then
		return true
	end

	-- Validar que el objeto sea un contenedor.
	if not object:hasProperty("container") then

		if instanceof(object, "IsoMannequin") or object:getContainerCount() < 1 then
			return true
		end
	end

	-- Si el personaje no es un jugador, denegar acción.
	if not instanceof(character, "IsoPlayer") then
		return false -- Dudo que esto se use en NPCs, pero bueno.
	end

	local safehouse = SafeHouse.getSafeHouse(square)

	-- Si el objeto está en una safehouse, y el jugador está permitido en ella, permitir acción.
	if safehouse then
		return safehouse:playerAllowed(character)
	end

	return false
end

-- Verifica si se puede realizar una acción sobre un objeto multi-sprite, según el criterio de este mod.
---@param props ISMoveableSpriteProps Idk.
---@param character IsoPlayer El personaje que intenta realizar la acción.
---@param square IsoGridSquare La baldosa de mapa donde se encuentra el objeto multi-sptrite.
local function checkMultiSpriteObject(props, character, square)
	local getInfo = props.getSpriteGridInfo
	local grid = (type(getInfo) == "function" and getInfo(props, square, true)) or {}

	if type(grid) ~= "table" then
		return true
	end

	for _, member in pairs(grid) do

		if not canAction(character, nil, member.object) then
			return false
		end
	end

	return true
end

-- Verifica si un objeto puede levantarse, pero ahora protege los contenedores del mapa.
-- Ya se hace una verificación multi-sprite en la función `canPickupMoveable`, un nivel arriba.
---@param _character IsoPlayer El personaje que está intentando mover el objeto.
---@param _square IsoGridSquare La baldosa de mapa donde se encuentra el objeto.
---@param _object IsoObject? El objecto que se está evaluando. Puede ser cualquier cosa basada en IsoObject.
---@param _isMulti boolean Si el objecto es un objeto multi-sprite.
---@return boolean canPickUp Si el objeto puede levantarse.
---@diagnostic disable-next-line: duplicate-set-field
function ISMoveableSpriteProps:canPickUpMoveableInternal(_character, _square, _object, _isMulti)
	local canPickUp = legacyCanPickUpMoveableInternal(self, _character, _square, _object, _isMulti)

	if canPickUp then
		canPickUp = canAction(_character, _square, _object)
	end

	return canPickUp
end

-- Verifica si un objeto puede rotarse, pero ahora protege los contenedores del mapa.
---@return boolean isValid Si la acción es válida.
---@diagnostic disable-next-line: duplicate-set-field
function ISMoveablesAction:isValid()
	local isValid = legacyMoveableIsValid(self)
	local character = self.character

	if not instanceof(character, "IsoPlayer") then
		return isValid
	end

	local cheat = type(ISMoveableDefinitions) == "table" and ISMoveableDefinitions.cheat

	if isValid and self.mode == "rotate" and not (cheat or character:isMovablesCheat()) then
		local moveProps = self.moveProps

		if moveProps and type(moveProps) == "table" and moveProps.isMultiSprite then
			isValid = checkMultiSpriteObject(moveProps, character, self.square)

		else
			isValid = canAction(character, self.square, self.object)
		end
	end

	return isValid
end

-- Verifica si un objeto puede desmantelarse, pero ahora protege los contenedores del mapa.
---@param _character IsoPlayer El personaje que intenta desmantelar el objeto.
---@return umbrella.ISMoveableSpriteProps.CanScrapResult result El resultado de la verificación.
---@return number chance La probabilidad de obtener recursos de la acción.
---@return string? perk La habilidad necesaria para desmantelar el objeto.
---@diagnostic disable-next-line: duplicate-set-field
function ISMoveableSpriteProps:canScrapObject(_character)
	local result, chance, perk = legacyCanScrapObject(self, _character)
	local object = self.object--[[@as IsoObject]] -- Por alguna razón esto no está documentado en Umbrella.

	if not instanceof(object, "IsoObject") or not instanceof(_character, "IsoPlayer") then
		return result, chance, perk
	end

	if result.canScrap and not _character:isMovablesCheat() then
		local canScrap ---@type boolean

		if self.isMultiSprite then
			canScrap = checkMultiSpriteObject(self, _character, object:getSquare())

		else
			canScrap = canAction(_character, nil, object)
		end

		if not canScrap then
			perk = nil; chance = 0; result = {canScrap = false}
		end
	end

	return result, chance, perk
end

-- Valida si un objeto debería ser destruído usando una almádena, pero ahora protege los contenedores del mapa.
---@return boolean isValid Si la acción es válida.
---@diagnostic disable-next-line: duplicate-set-field
function ISDestroyStuffAction:isValid()
	local isValid = legacyDestroyIsValid(self)
	local character = self.character
	local object = self.item

	if not instanceof(object, "IsoObject") or not instanceof(character, "IsoPlayer") then
		return isValid
	end

	if isValid and not character:isBuildCheat() then
		local fromObject = type(ISMoveableSpriteProps) == "table" and ISMoveableSpriteProps.fromObject
		local moveProps = type(fromObject) == "function" and fromObject(object)

		if moveProps and moveProps.isMultiSprite then
			isValid = checkMultiSpriteObject(moveProps, character, object:getSquare())

		else
			isValid = canAction(character, nil, object)
		end
	end

	return isValid
end

-- Esto indudablemente evita que rompan los contenedores, pero causa inconsistencias leves que los usuarios notarán.
-- Aunque está listo para producción, hará falta sobrescribir más funciones para corregir las inconsistencias.
