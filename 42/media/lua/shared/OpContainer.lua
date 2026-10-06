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
local table = utils.table
local string = utils.string

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
	getSprite = secureFunction(getSprite),
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
---@field patterns string
---@field isExempt boolean
---@field exemptName string
---@field spriteName string

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
local getSprite = OpContainer.getSprite
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
	then
		return false
	end

	local data = secureTable(isCallSecure(object.getModData) and object:getModData())--[[@as table]]

	-- Validar que el objeto tenga modData que lo haga relevante, o que tenga al menos un contenedor.
	if not data.fuelAmount and (data.isPlayerPlaced
		or (isCallSecure(object.getContainerCount) and secureNumber(object:getContainerCount()) < 1)
	) then
		return false
	end

	-- Devolver verdadero.
	return true
end

-- Verifica si el jugador debería tener permitido alterar un objeto en una baldosa en específico.
---@param character IsoPlayer El personaje que intenta realizar la acción.
---@param square IsoGridSquare La baldosa de mapa donde se encuentra el objeto.
---@return boolean isPlayerAllowed Si se permite la alteración.
---@return string? msg Un mensaje (si debería mostrarse un mensaje al usuario por esto).
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
---@return OCPSpriteException? exception Los detalles sobre la excepción.
local function getSpriteException(moveProps)

	-- Validar herramientas necesarias.
	if not (isCallSecure(string.gsub) and isCallSecure(table.concat) and isCallSecure(string.find)
		and isCallSecure(string.gmatch) and isCallSecure(moveProps.hasFaces) and isCallSecure(moveProps.getFaces)
	) then
		return
	end

	local names = {} ---@type string[]
	local spriteName = secureString(moveProps.spriteName)

	-- Buscar los nombres de todos los sprites relacionados con este.
	for _, face in secureFunction(pairs(
		secureTable(moveProps:hasFaces() and moveProps:getFaces() or {N = spriteName})
	)) do
		local sprite = getSprite(secureString(face))
		local grid = instanceof(sprite, "IsoSprite") and isCallSecure(sprite.getSpriteGrid)
			and sprite:getSpriteGrid() or nil

		---@cast grid -? Validación en instanceof.
		for _, spr in secureFunction(pairs(secureTable(instanceof(grid, "IsoSpriteGrid")
			and isCallSecure(grid.getSprites) and grid:getSprites() or {[1] = sprite or {}}
		)--[[@as (IsoSprite[])]])) do
			names[#names + 1] = secureString(
				instanceof(sprite, "IsoSprite") and isCallSecure(spr.getName) and spr:getName()
			)
		end
	end

	local exception = {isExempt = false}
	local namesStr, patterns = secureString(table.concat(names, ",")), {}

	-- Buscar si alguno de los patrones en la configuración coincide con uno de los nombres.
	for pattern in secureFunction(string.gmatch(
		secureString(string.gsub(secureString(Options.customExceptions), "%s+", "")), "([^,]+)"
	)) do

		if not isStringSecure(pattern) then -- Preservar la configuración.
			return
		end

		if not exception.isExempt and string.find(namesStr, pattern, 1, true) then
			exception.isExempt, exception.exemptName = true, pattern

		else -- Almacenar sólo los patrones que no coincidan.
			patterns[#patterns + 1] = pattern
		end
	end

	-- Si no hubo coincidencia, añadir el nombre del sprite a las excepciones.
	if not exception.isExempt--[[@as boolean]] then
		patterns[#patterns + 1], exception.exemptName = spriteName, spriteName
	end

	-- Preparar los patrones para ser almacenados en la configuración.
	exception.patterns, exception.spriteName = table.concat(patterns, ","), spriteName

	-- Devolver resultado.
	return isStringSecure(exception.patterns) and exception or nil
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
---@return OCPSpriteException? exception Los detalles sobre la excepción.
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
	if not (instanceof(character, "IsoPlayer") and square) then
		return isRelevant, exception
	end

	-- validar que el objeto no esté exento.
	if exception.isExempt then
		return false
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

-- Se aplica a ISMoveablesAction:isValid.
-- Valida si un objeto puede recogerse, rotarse, o desmantelarse, según el criterio de este mod.
---@param o ISMoveablesAction Una instancia de la clase a la que pertenece la función a la que parcha.
---@return boolean isValid Si la acción es válida.
function OpContainer.isMoveablesActionValid(o)
	local isValid = Legacy.moveableIsValid(o)

	-- Validar acción, y que el modo de funcionamiento sea de interés para este mod.
	if not (isValid and BlockedMoveableModes[o.mode]) or ISMoveableDefinitions.cheat then
		return isValid
	end

	local character = o.character

	-- Validar que el jugador no esté usando el MoveablesCheat.
	if instanceof(character, "IsoPlayer")
		and isCallSecure(character.isMovablesCheat) and character:isMovablesCheat()
	then
		return isValid
	end

	-- Validar que el objeto no esté protegido por este mod.
	if OpContainer.isObjectProtected(o.object, character, o.square, o.moveProps) then
		o:stop()
		return false
	end

	-- Devolver verdadero.
	return true
end

-- Se aplica a ISDestroyStuffAction:isValid.
-- Valida si un objeto puede ser destruído con una almádena, según el criterio de este mod.
-- Aquí, por alguna razón decidieron nombrar como self.item el campo con el objeto que se destruirá.
---@param o ISDestroyStuffAction Una instancia de la clase a la que pertenece la función a la que parcha.
---@return boolean isValid Si la acción es válida.
function OpContainer.isDestroyActionValid(o)
	local isValid = Legacy.destroyIsValid(o)

	-- Validar acción,
	if not isValid then
		return isValid
	end

	local character = o.character

	-- Validar que el jugador no esté usando el BuildCheat.
	if instanceof(character, "IsoPlayer")
		and isCallSecure(character.isBuildCheat) and character:isBuildCheat()
	then
		return isValid
	end

	-- Devolver si el objeto está protegido por este mod.
	return not OpContainer.isObjectProtected(o.item, character, nil, nil)
end

-- Se aplica a ISRemoveCampfireAction:isValid.
-- Valida si una hoguera puede ser recogida, según el criterio de este mod.
---@param o ISRemoveCampfireAction Una instancia de la clase a la que pertenece la función a la que parcha.
---@return boolean isValid Si la acción es válida.
function OpContainer.isRemoveCampfireActionValid(o)
	local isValid = Legacy.removeCampfireIsValid(o)

	-- Validar acción, y que el modo de funcionamiento sea de interés para este mod.
	if not isValid or ISMoveableDefinitions.cheat then
		return isValid
	end

	local character = o.character

	-- Validar que el jugador no esté usando el MovablesCheat.
	if instanceof(character, "IsoPlayer")
		and isCallSecure(character.isMovablesCheat) and character:isMovablesCheat()
	then
		return isValid
	end

	local campfire = secureTable(o.campfire)

	-- Devolver si el objeto está protegido por este mod.
	return not OpContainer.isObjectProtected(
		isCallSecure(campfire.getObject) and campfire:getObject(), character, nil, nil
	)
end

-- Se aplica a ISMoveableSpriteProps:placeMoveableInternal.
-- Marca como isPlayerPlaced a todos los objetos de interés colocados que no se vuelven golpeables al colocarlos.
-- Esto ayuda a diferenciarlos en casos especiales de los objetos que sí deben protegerse, como con los maniquíes.
---@param o ISMoveableSpriteProps Una instancia de la clase a la que pertenece la función a la que parcha.
---@param character IsoPlayer El jugador que colocará el objeto.
---@param square IsoGridSquare La baldosa de mapa donde se colocará el objeto.
---@param item InventoryItem El item correspondiente al objeto que se colocará.
---@param spriteName string El nombre del sprite del objeto que se colocará.
---@return IsoObject? object El objeto que fue colocado.
function OpContainer.placeMoveableInternal(o, character, square, item, spriteName)
	local object = Legacy.placeMoveableInternal(o, character, square, item, spriteName)

	-- Validar entorno, y que el objeto necesite una etiqueta.
	---@cast object -? Validación en isObjectProtected.
	if not (isServer()
		and OpContainer.isObjectProtected(object, nil, square, nil) and isCallSecure(object.getModData)
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
		return OpContainer.isMoveablesActionValid(self)
	end; function ISDestroyStuffAction:isValid()
		return OpContainer.isDestroyActionValid(self)
	end; function ISRemoveCampfireAction:isValid()
		return OpContainer.isRemoveCampfireActionValid(self)
	end; function ISMoveableSpriteProps:placeMoveableInternal(_character, _square, _item, _spriteName)
		return OpContainer.placeMoveableInternal(self, _character, _square, _item, _spriteName)
	end

	OpContainer.isGamePatched = true -- Previene inconsistencias graves si el archivo es recargado.
end

-------------------------------
-- Resumen de deuda técnica. --
-------------------------------

-- La opción para no proteger los contenedores en los interiores del mod "Project RV Interior" dejará sin proteger a todos
--- los contenedores en esas habitaciones. Hace falta una integración con un mod de protección de vehículos para sólo permitir
--- al jugador en los contenedores que le corresponden.

-- Los últimos commits solucionaron las inconsistencias leves reportadas previamente, pero mientras lo hacía, accidentalmente
--- removí cualquier protección del lado del servidor. De cualquier forma, esta protección no era más que un placebo debido a
--- que los contenedores aún podían destruirse con paquetes "falsos", -lo que ocurre en todos los mods de este tipo-, así que no
--- lo considero un problema crítico. Sin embargo, entiendo que debería solucionarlo en los próximos meses.

-- Las nuevas excepciones personalizados tienen 3 problemas no-criticos. Los dos primeros, son que la opción del menú contextual
--- no aparecerá con contenedores que hayan sido colocados por jugadores, y que aparecerá al dar click derecho sobre un
--- dispensador de gasolina. El tercero, es que aún son difíciles de usar sin un menú que muestre las excepciones añadidas para
--- poder eliminarlas. Todo esto es al menos molesto.

print("[OpContainer]: Loaded and ready.")
