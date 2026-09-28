-- OpContainer_secureUtils.lua
-- Licence: CC0-1.0(Visit https://creativecommons.org/publicdomain/zero/1.0/ to view details).
-- Maintainer: AbrahamPicos.
-- Contributors:

_07ca70cd7c514861b4b3897cbf56f40a = _07ca70cd7c514861b4b3897cbf56f40a or {
	type = type
}

local utils = _07ca70cd7c514861b4b3897cbf56f40a

----------------------------
-- Validación de objetos: --
----------------------------

local type = utils.type

-- Verifica si es seguro intentar indexar una tabla.
---@param o any La tabla que se indexará.
---@return true? isSecure Si es seguro hacerlo.
function utils.isTableSecure(o)

	if type(o) == "table" then
		return true
	end
end

-- Verifica si es seguro intentar llamar a una función.
---@param c function? La función que se quiere llamar.
---@return true? isSecure Si es seguro hacerlo.
function utils.isCallSecure(c)

	if type(c) == "function" then
		return true
	end
end

-- Verifica si es seguro usar un número.
---@param n number? El número que se quiere usar.
---@return true? isSecure Si es seguro hacerlo.
function utils.isNumberSecure(n)

	if type(n) == "number" then
		return true
	end
end

-- Verifica si es seguro usar un string.
---@param s string? El string que se quiere usar.
---@return true? isSecure Si es seguro hacerlo.
function utils.isStringSecure(s)

	if type(s) == "string" then
		return true
	end
end

-----------------------------------
-- Obtención de objetos seguros: --
-----------------------------------

local isCallSecure = utils.isCallSecure
local isTableSecure = utils.isTableSecure
local isNumberSecure = utils.isNumberSecure
local isStringSecure = utils.isStringSecure

-- Devuelve una tabla si no la había.
---@generic T
---@param t T La supuesta tabla.
---@return T table Una tabla.
function utils.secureTable(t)

	if isTableSecure(t) then
		return t
	end

	return {}
end

-- Devuelve una función si no la había.
---@generic F
---@param f F La supuesta función.
---@return F function Una función.
function utils.secureFunction(f)

	if isCallSecure(f) then
		return f
	end

	return function (...) return nil end
end

-- Devuelve un número si no lo había.
---@param n any El supuesto número.
---@return number number Un número.
function utils.secureNumber(n)

	if isNumberSecure(n) then
		return n
	end

	return 0
end

-- Devuelve un string si no lo había.
---@param s any El supuesto string.
---@return string string Un string.
function utils.secureString(s)

	if isStringSecure(s) then
		return s
	end

	return ""
end

--------------------------
-- Referencias seguras: --
--------------------------

local secureTable = utils.secureTable
local secureFunction = utils.secureFunction

utils.print = secureFunction(print)
utils.pairs = secureFunction(pairs)
utils.ipairs = secureFunction(ipairs)
utils.tonumber = secureFunction(tonumber)
utils.tostring = secureFunction(tostring)
utils.getmetatable = secureFunction(getmetatable)
utils.setmetatable = secureFunction(setmetatable)

utils.math = secureTable(math)
utils.table = secureTable(table)
utils.string = secureTable(string)
utils.coroutine = secureTable(coroutine)

-- Tenga en cuenta que las funciones seguras devolverán nil como fallback, así que debe asegurarse de añadir alternativas
--- cuando espere algo más que un valor nulo, como `tostring(value) or ""`.
