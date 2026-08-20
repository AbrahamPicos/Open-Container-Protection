-- OpContainer_secureUtils.lua
-- Licence: CC0-1.0(Visit https://creativecommons.org/publicdomain/zero/1.0/ to view details).
-- Maintainer: AbrahamPicos.
-- Contributors:

_07ca70cd7c514861b4b3897cbf56f40a = _07ca70cd7c514861b4b3897cbf56f40a or {
	type = type,
	pairs = pairs,
	ipairs = ipairs
}

local utils = _07ca70cd7c514861b4b3897cbf56f40a

----------------------------
-- Validación de Objetos: --
----------------------------

local type = utils.type

-- Verifica si es seguro intentar indexar una tabla.
---@param o any La tabla que se indexará.
---@return true|nil isSecure Si es seguro hacerlo.
function utils.isTableSecure(o)

	if type(o) == "table" then
		return true
	end
end

-- Verifica si es seguro intentar llamar a una función.
---@param c function? La función que se quiere llamar.
---@return true|nil isSecure Si es seguro hacerlo.
function utils.isCallSecure(c)

	if type(c) == "function" then
		return true
	end
end

-- Verifica si es seguro usar un número.
---@param n number? El número que se quiere usar.
---@return true|nil isSecure Si es seguro hacerlo.
function utils.isNumberSecure(n)

	if type(n) == "number" then
		return true
	end
end

-----------------------------------
-- Obtención de objetos seguros: --
-----------------------------------

local isCallSecure = utils.isCallSecure
local isTableSecure = utils.isTableSecure

-- Devuelve una tabla si no la había.
---@generic T
---@param t T La supuesta tabla.
---@return T t Una tabla.
function utils.secureTable(t)

	if isTableSecure(t) then
		return t
	end

	return {}
end

-- Devuelve una función si no la había.
---@generic F
---@param f F La supuesta función.
---@return F object Una función.
function utils.secureFunction(f)

	if isCallSecure(f) then
		return f
	end

	return function (...) return false end
end

--------------------------
-- Referencias seguras: --
--------------------------

local secureTable = utils.secureTable
local secureFunction = utils.secureFunction

utils.print = secureFunction(print)
utils.tonumber = secureFunction(tonumber)
utils.tostring = secureFunction(tostring)
utils.getmetatable = secureFunction(getmetatable)
utils.setmetatable = secureFunction(setmetatable)

utils.math = secureTable(math)
utils.table = secureTable(table)
utils.string = secureTable(string)
utils.coroutine = secureTable(coroutine)

-- Tenga encuenta que las funciones seguras devolverán false como fallback, así que debe asegurarse añadir alternativas
--- cuando espere algo más que un boleano, como `tostring(value) or ""`.
