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

local legacyMoveableIsValid = ISMoveablesAction.isValid
local legacyDestroyIsValid = ISDestroyStuffAction.isValid
local legacyCanScrapObject = ISMoveableSpriteProps.canScrapObject
local legacyCanPickUpMoveableInternal = ISMoveableSpriteProps.canPickUpMoveableInternal

-- Verifica si se puede realizar una acción sobre un contenedor, según el criterio de este mod.
-- Añadí condiciones aparentemente exesivas, porque vanilla hace comprobaciones que sugieren que los tipos pueden ser diferentes.
---@param character IsoObject? El personaje que está intentando mover el objeto.
---@param square IsoGridSquare? La baldosa de mapa donde se encuentra el objeto.
---@param object IsoObject? El objecto que se está evaluando. Puede ser cualquier cosa basada en IsoObject.
---@return boolean canAction Si se puede realizar una acción sobre el objeto.
local function canAction(character, square, object)

	-- Si hay un personaje, y el objeto no es golpeable (lo que significa que no fue hecho por un jugador).
	if (character and instanceof(character, "IsoGameCharacter")) and (object and not instanceof(object, "IsoThumpable")) then
		square = square or object:getSquare()

		-- Si el objeto es un contenedor.
		if object:hasProperty("container") then
			local safehouse = instanceof(character, "IsoPlayer") and SafeHouse.getSafeHouse(square)

			-- Si el objeto no está en una safehouse, o el personaje no es un jugador que pertenezca a ella, prevenir acción.
			if not safehouse or not safehouse:playerAllowed(character) then
				return false
			end
		end
	end

	return true
end

-- Verifica si un objeto puede levantarse, pero ahora protege los contenedores del mapa.
---@param _character IsoPlayer El personaje que está intentando mover el objeto.
---@param _square IsoGridSquare La baldosa de mapa donde se encuentra el objeto.
---@param _object IsoObject? El objecto que se está evaluando. Puede ser cualquier cosa basada en IsoObject.
---@param _isMulti boolean Si el objecto es un objeto multi-sprite.
---@return boolean canPickUp Si el objeto puede levantarse.
---@diagnostic disable-next-line: duplicate-set-field
function ISMoveableSpriteProps:canPickUpMoveableInternal(_character, _square, _object, _isMulti)
	local canPickUp = legacyCanPickUpMoveableInternal(self, _character, _square, _object, _isMulti)

	-- Si vanilla dice que el objeto puede moverse, verificar si estamos de acuerdo.
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

	if isValid and not (ISMoveableDefinitions.cheat or character:isMovablesCheat()) then

		if self.mode == "rotate" then
			isValid = canAction(self.character, self.square, self.object)
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

	-- Si vanilla dice que el objeto puede desmantelarse, y el jugador no está chetado.
	if result.canScrap and not _character:isMovablesCheat() then
		local object = self.object--[[@as IsoObject]] -- Por alguna razón esto no está documentado en Umbrella.
		local canScrap ---@type boolean

		-- Si el objeto es multi-sprite, verificar todos los objetos del grupo, de lo contrario, verificar si estamos en desacuerdo.
		if self.isMultiSprite then

			-- Buscar nuevamente si alguno de los objetos no puede desmantelarse, pero esta vez usando nuestro criterio.
			for i, member in ipairs(self:getSpriteGridInfo(object:getSquare(), true)) do
				local obj = member.object

                canScrap = obj and canAction(_character, nil, obj)

				if not canScrap then
					break
				end
			end

		else
			canScrap = canAction(_character, object:getSquare(), object)
		end

		-- Si estamos en desacuerdo, negar.
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
	local object = self.item

	-- Si vanilla dice que el objeto puede destruirse, y el jugador no está chetado, verificar si estamos de acuerdo.
	if isValid and not self.character:isBuildCheat() then
		isValid = canAction(self.character, object:getSquare(), self.item)
	end

	return isValid
end

-- Esto indudablemente evita que rompan los contenedores, pero causa inconsistencias leves que los usuarios notarán.
-- Aunque está listo para producción, hará falta sobrescribir más funciones para corregir las inconsistencias.
