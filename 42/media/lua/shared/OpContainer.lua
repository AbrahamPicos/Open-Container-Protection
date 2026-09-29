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
local secureTable = utils.secureTable
local secureNumber = utils.secureNumber
local secureString = utils.secureString
local secureFunction = utils.secureFunction
local isCallSecure = utils.isCallSecure
local isStringSecure = utils.isStringSecure
local isNumberSecure = utils.isNumberSecure

utils.OpContainer = utils.OpContainer or {

	Events = secureTable(Events),
	SafeHouse = secureTable(SafeHouse),
	Capability = secureTable(Capability),
	SandboxVars = secureTable(SandboxVars),

	ISMoveablesAction = secureTable(ISMoveablesAction),
	ISDestroyStuffAction = secureTable(ISDestroyStuffAction),
	ISMoveableSpriteProps = secureTable(ISMoveableSpriteProps),
	ISRemoveCampfireAction = secureTable(ISRemoveCampfireAction),

	getText = secureFunction(getText--[[@as fun(s:string,...:any):string]]),
	isClient = secureFunction(isClient),
	isServer = secureFunction(isServer),
	getTexture = secureFunction(getTexture),
	instanceof = secureFunction(instanceof),
	getTimestampMs = secureFunction(getTimestampMs),
	getSandboxOptions = secureFunction(getSandboxOptions),
	getSpecificPlayer = secureFunction(getSpecificPlayer),

	ISMoveableDefinitions = secureTable(ISMoveableDefinitions)
}

local OpContainer = utils.OpContainer

---@class OCPOptions
---@field customExceptions string
---@field safeHouseCooldown integer
---@field safeHousePermission boolean
---@field vehicleInteriorPermission boolean

---@class OCPSpriteException
---@field isExempt boolean
---@field spriteName string
---@field exemptName string
---@field newConfig string

local SafeHouse = OpContainer.SafeHouse
local Options = secureTable(OpContainer.SandboxVars.OpContainer--[[@as OCPOptions]])
local BlockedMoveableModes = {pickup = true, rotate = true, scrap = true}

local ISMoveablesAction = OpContainer.ISMoveablesAction
local ISDestroyStuffAction = OpContainer.ISDestroyStuffAction
local ISMoveableSpriteProps = OpContainer.ISMoveableSpriteProps
local ISRemoveCampfireAction = OpContainer.ISRemoveCampfireAction

local getText = OpContainer.getText
local isClient = OpContainer.isClient
local isServer = OpContainer.isServer
local instanceof = OpContainer.instanceof
local getTimestampMs = OpContainer.getTimestampMs

OpContainer.Legacy = OpContainer.Legacy or {

	moveableIsValid = secureFunction(ISMoveablesAction.isValid),
	destroyIsValid = secureFunction(ISDestroyStuffAction.isValid),
	removeCampfireIsValid = secureFunction(ISRemoveCampfireAction.isValid), ---@diagnostic disable-next-line: param-type-mismatch
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
	---@cast object -? Validación en instanceof.
	if not instanceof(object, "IsoObject") or instanceof(object, "IsoThumpable")
		or (isCallSecure(object.isMovedThumpable) and object:isMovedThumpable())
		or (isCallSecure(object.getModData) and secureTable(object:getModData()).isPlayerPlaced)
		or not isCallSecure(object.getContainerCount)
	then
		return false
	end

	-- Validar que el objeto tenga al menos un contenedor.
	if not (secureNumber(object:getContainerCount()) > 0) then
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

	-- Si siempre se permite en los interiores del mod Project RV Interior, y el objeto está en uno, devolver verdadero.
	if Options.vehicleInteriorPermission then
		local x, y = secureNumber(isCallSecure(square.getX) and square:getX()),
			secureNumber(isCallSecure(square.getY) and square:getY())

		if x > 22500 and y > 12000 then -- A partir de aquí comienza el mapa de los interiores.
			return true
		end
	end

	-- Validar que los jugadores puedan alterar contenedores en sus safehouses.
	if not Options.safeHousePermission then
		return false
	end

	local safehouse = isCallSecure(SafeHouse.getSafeHouse) and SafeHouse.getSafeHouse(square) or nil

	-- Validar que el objeto esté en una safehouse, y el jugador esté permitido en ella.
	---@cast safehouse -? Validación en instanceof.
	if not (instanceof(safehouse, "SafeHouse") and isCallSecure(safehouse.playerAllowed)
		and safehouse:playerAllowed(character) and isCallSecure(safehouse.getDatetimeCreated)
	) then
		return false
	end

	local current = getTimestampMs()

	-- Validar que se tenga una referencia del tiempo actual.
	if not isNumberSecure(current) then
		return false
	end

	local elapsed = ((current - secureNumber(safehouse:getDatetimeCreated())) / 1000 / 60)
		- secureNumber(Options.safeHouseCooldown)

	-- Validar que ya haya pasado el tiempo de espera de la safehouse.
	if elapsed < 0 then
		return false, getText("IGUI_HaloNote_OpContainer_SafeHouseCooldown", secureNumber(
			(isCallSecure(math.abs) and math.abs(secureNumber(isCallSecure(math.floor) and math.floor(elapsed))))
		))
	end

	-- Devolver verdadero.
	return true
end

-- Verifica si un sprite está exento debido a las excepciones personalizadas.
---@param moveProps ISMoveableSpriteProps|ISThumpableSpriteProps Las propiedades del sprite.
---@return OCPSpriteException? exception Los detalles sobre la exepción.
local function getSpriteException(moveProps)
	return
end

------------------------
-- Función Principal: --
------------------------

-- Verifica si se puede realizar una acción sobre un objeto según el criterio de este mod, considerando a objetos multi-sprite.
-- Los objetos multi-sprite tienen a otros objetos asociados en celdas adyacentes, y deben tratarse como un único objeto.
---@param object IsoObject? El objeto sobre el que se intenta realizar la acción.
---@param character IsoPlayer? El personaje que intenta realizar la acción.
---@param square IsoGridSquare? La baldosa de mapa donde se encuentra el objeto.
---@param moveProps (ISMoveableSpriteProps|ISThumpableSpriteProps)? Las propiedades del sprite asociado al objeto.
---@return boolean isObjectProtected Si el objeto será protegido por este mod.
function OpContainer.isObjectProtected(object, character, square, moveProps)

	-- Validar entorno y objeto.
	---@cast object -? Validación en instanceof.
	if not (isClient() or isServer()) or not instanceof(object, "IsoObject") then
		return false
	end

	-- Asegurar baldosa.
	square = square or (isCallSecure(object.getSquare) and object:getSquare())
	square = instanceof(square, "IsoGridSquare") and square or nil

	-- Asegurar las propiedades del sprite asociado objeto.
	moveProps = secureTable(moveProps
		or (isCallSecure(ISMoveableSpriteProps.fromObject) and ISMoveableSpriteProps.fromObject(object))
	)--[[@as ISMoveableSpriteProps|ISThumpableSpriteProps]]

	local isRelevant = false

	-- Asegurar caché de cuadrícula, y buscar si alguno de los miembros es relevante (lo que vuelve relevante al objeto).
	for _, member in secureFunction(pairs(secureTable(moveProps.isMultiSprite and square
		and isCallSecure(moveProps.getSpriteGridInfo)
		and moveProps.isMultiSprite and moveProps:getSpriteGridInfo(square, true)
	or {member = {object = object}}))) do

		if isObjectRelevant(secureTable(member).object) then
			isRelevant = true
			break
		end
	end

	-- Validar la relevancia del objeto.
	if not isRelevant then
		return false
	end

	local exception = secureTable(getSpriteException(moveProps))--[[@as OCPSpriteException]]

	-- Si el objeto no es relevante, no hay jugador, o no hay baldosa, devolver si es un objeto relevante.
	---@cast character -? Validación en instanceof.
	if exception.isExempt or not (instanceof(character, "IsoPlayer") and square) then
		return isRelevant
	end

	local isAllowed, msg = isPlayerAllowedOnSquare(character, square)

	-- Validar que el jugador no esté permitido en la baldosa.
	if isAllowed then
		return false
	end

	-- Si se está del lado del cliente, notificar al jugador la razón.
	if isClient() and isCallSecure(character.setHaloNote) then
		character:setHaloNote(
			secureString(msg or getText("IGUI_HaloNote_OpContainer_Protected")), 255, 0, 0, 200
		)
	end

	-- Devolver verdadero.
	return true
end

--------------
-- Parches: --
--------------

local isObjectProtected = OpContainer.isObjectProtected

-- Se aplica a ISMoveablesAction:isValid.
-- Valida si un objeto puede recogerse, rotarse, y desmantelarse. según el criterio de este mod.
---@param self ISMoveablesAction Una instancia de la clase a la que pertenece la función a la que parcha.
---@return boolean isValid Si la acción es válida.
function OpContainer.moveablesActionIsValid(self)
	local isValid = Legacy.moveableIsValid(self)

	-- Validar acción, y que el modo sea de interés para el mod.
	if not (isValid and BlockedMoveableModes[self.mode]) or ISMoveableDefinitions.cheat then
		return isValid
	end

	local character = self.character

	-- Validar que el jugador no esté usando el MoveablesCheat.
	if instanceof(character, "IsoPlayer")
		and isCallSecure(character.isMovablesCheat) and character:isMovablesCheat()
	then
		return isValid
	end

	-- Validar que el objeto no esté protegido por este mod.
	if isObjectProtected(self.object, character, self.square, self.moveProps) then
		self:stop()
		return false
	end

	-- Devolver verdadero.
	return true
end

-- Se aplica a ISDestroyStuffAction:isValid.
-- Valida si un objeto puede ser destruído con una almádena, según el criterio de este mod.
-- Aquí, por alguna razón decidieron nombrar como self.item el campo con el objeto que se destruirá.
---@param self ISDestroyStuffAction Una instancia de la clase a la que pertenece la función a la que parcha.
---@return boolean isValid Si la acción es válida.
function OpContainer.destroyActionIsValid(self)
	local isValid = Legacy.destroyIsValid(self)

	-- Validar acción,
	if not isValid then
		return isValid
	end

	local character = self.character

	-- Validar que el jugador no esté usando el BuildCheat.
	if instanceof(character, "IsoPlayer")
		and isCallSecure(character.isBuildCheat) and character:isBuildCheat()
	then
		return isValid
	end

	-- Devolver si el objeto está protegido por este mod.
	return not isObjectProtected(self.item, character, nil, nil)
end

-- Se aplica a ISRemoveCampfireAction:isValid.
-- Valida si una hoguera puede ser recogida, según el criterio de este mod.
---@param self ISRemoveCampfireAction Una instancia de la clase a la que pertenece la función a la que parcha.
---@return boolean isValid Si la acción es válida.
function OpContainer.removeCampfireActionIsValid(self)
	local isValid = Legacy.removeCampfireIsValid(self)

	-- Validar acción, y que el modo sea de interés para el mod.
	if not isValid or ISMoveableDefinitions.cheat then
		return isValid
	end

	local character = self.character

	-- Validar que el jugador no esté usando el MovablesCheat.
	if instanceof(character, "IsoPlayer")
		and isCallSecure(character.isMovablesCheat) and character:isMovablesCheat()
	then
		return isValid
	end

	local campfire = secureTable(self.campfire)

	-- Devolver si el objeto está protegido por este mod.
	return not isObjectProtected(
		isCallSecure(campfire.getObject) and campfire:getObject(), character, nil, nil
	)
end

-- Se aplica a ISMoveableSpriteProps:placeMoveableInternal.
-- Marca como isPlayerPlaced a todos los objetos de interés colocados que no se vuelven golpeables al colocarlos.
-- Esto ayuda a diferenciarlos en casos especiales de los objetos que sí deben protegerse, como con los maniquíes.
---@param self ISMoveableSpriteProps Una instancia de la clase a la que pertenece la función a la que parcha.
---@param character IsoPlayer El jugador que colocó al objeto.
---@param square IsoGridSquare La baldosa de mapa donde se colocará al objeto.
---@param item InventoryItem El item correspondiente al objeto que se colocará.
---@param spriteName string El nombre del sprite del objeto que se colocará.
---@return IsoObject? object El objeto que fue colocado.
function OpContainer.placeMoveableInternal(self, character, square, item, spriteName)
	local object = Legacy.placeMoveableInternal(self, character, square, item, spriteName)

	-- Validar entorno, y que el objeto necesite una etiqueta.
	---@cast object -? Validación en isObjectProtected.
	if not (isServer()
		and isObjectProtected(object, nil, square, self) and isCallSecure(object.getModData)
	) then
		return object
	end

	-- Marcar objeto como colocado por un jugador.
	secureTable(object:getModData()).isPlayerPlaced = true

	-- Sincronizar con los clientes.
	if isCallSecure(object.transmitModData) then
		object:transmitModData()
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
-- En shared/Camping/TimedActions/ISRemoveCampfireAction.lua

-- Si aún no se ha hecho, aplicar los parches usando la técnica de monkey patching.
if not OpContainer.isGamePatched--[[@as boolean]] then

	function ISMoveablesAction:isValid()
		return OpContainer.moveablesActionIsValid(self)
	end; function ISDestroyStuffAction:isValid()
		return OpContainer.destroyActionIsValid(self)
	end; function ISRemoveCampfireAction:isValid()
		return OpContainer.removeCampfireActionIsValid(self)
	end; function ISMoveableSpriteProps:placeMoveableInternal(_character, _square, _item, _spriteName)
		return OpContainer.placeMoveableInternal(self, _character, _square, _item, _spriteName)
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
