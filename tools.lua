-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
--  Created by Samedi on 23/08/2020.
--  All code (c) 2020 - present day, The Samedi Corporation.
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

tools = { _inDust = false }

function tools.initFromDust(package)
    tools._log = {}
    tools._inDust = true
    tools._slots = package.elements
end

function tools.installGlobalFunctions(system)
    _G.print = function(...)
        for i,a in ipairs({ ... }) do
            system.print(a)
        end
    end

    _G.printf = function(s, ...)
        system.print(s:format(...))
    end

    _G.printt = function(t)
        for k,v in pairs(t) do
            printf("%s: %s", k, v)
        end
    end
    
    _G.error = function(s, ...)
        local message = s:format(...)
        system.showScreen(1)
        system.setScreen(string.format('<div class="window" style="position: absolute; top="10vh"; left="45vw"; width="10vw"><h1 style="middle">Error</h1><span>%s</span></div>', message))
    end

    print("Installed global functions.")
end

function tools.install(system, unit, library)
    if not tools._inDust then
        tools.installGlobalFunctions(system)
    end

    local all = tools.allElements()
    local elements = tools.categoriseElements(all)
    local cores = elements.CoreUnitStatic or elements.CoreUnitDynamic
    if cores and (#cores > 0) then
        elements.core = cores[1]
    else
        error("Core not found. Need to link the core to the controller.")
    end
    elements.system = system
    elements.library = library
    elements.unit = unit

    elements.firstOfKind = function(self, category)
        local list = self[category]
        if list then
            return list[1]
        end
    end

    elements.allOfKind = function(self, category)
        return self[category] or {}
    end

    elements.doFirst = function(self, category, action)
        local element = self:firstOfKind(category)
        if element then
            action(element)
        end
    end

    elements.doAll = function(self, category, action)
        for i,element in ipairs(self:allOfKind(category)) do
            action(element, i)
        end
    end

    tools._elements = elements
    tools._log = {}

    if tools._inDust then
        print("Running in DUST.")
    else
        _G.system = _G.system or system
        _G.unit = _G.unit or unit
        _G.library = _G.library or library
        print("Running in DU.")
    end

    print("Tool startup done.")
    return elements
end


function tools.allElements()
    local elements = {}
    for k,v in pairs(_G) do
        if (k:find("Unit_") == 1) and (v.getElementClass) then
            table.insert(elements, v)
        end
    end
    return elements
end

function tools.categoriseElements(elements)
    local categorised = {}
    for i,element in ipairs(elements) do
        local class = element.getElementClass()
        local classElements = categorised[class]
        if not classElements then
            classElements = {}
            categorised[class] = classElements
        end

        table.insert(classElements, element)
        printf("Found %s", class)
    end

    categorised.all = elements
    return categorised
end

function tools.dump(name, o, done)
    if done[o] then
        return "-> " .. done[o]
    else
        done[o] = name
        local items = {}
        for k,v in pairs(o) do
            if not (k == "loaded") then
                if type(v) == "table" then
                    items[k] = tools.dump(string.format("%s.%s", name, k), v, done)
                else
                    items[k] = v
                end
            end
        end
        return items
    end
end

function tools.filtered(items, filter, action)
    for k,v in pairs(items) do
        if filter(k,v) then
            action(k,v)
        end
    end
end

function tools.isTable(k,v) 
    return type(v) == "table"
end

function tools.isFunction(k,v)
    return type(v) == "function"
end

function tools.isOther(k,v)
    return not (tools.isTable(k,v) or tools.isFunction(k,v))
end

function tools.logger(s)
    table.insert(tools.logged, s)
end

function tools.logPair(k,v)
    tools.logger(string.format("%s%s = %s", tools.indent, k, v))
end

function tools.logFunction(k,v)
    tools.logger(string.format("%s%s()", tools.indent, k))
end

function tools.logModule(name, items)
    local old = tools.indent
    tools.logger(string.format("\n%s%s:", tools.indent, name))
    tools.indent = tools.indent .. "  "
    tools.filtered(items, tools.isOther, tools.logPair)
    tools.filtered(items, tools.isFunction, tools.logFunction)

    tools.filtered(items, tools.isTable, tools.logModule)
    tools.indent = old
end

function tools.dumpGlobals()
    tools.indent = ""
    tools.logged = {}
    local items = tools.dump("globals", _G, {})
    tools.logModule("(globals)", items)
    return tools.logged
end 

function tools.logArray(system, array, name)
    system.logInfo(string.format("ITEMSTART:%s", name))
    for i,s in ipairs(array) do
        system.logInfo(s)
    end
    system.logInfo(string.format("ITEMEND"))
end

function tools.logf(s, ...)
    table.insert(tools._log, s:format(...))
end

function tools.flushLog()
    tools.logArray(system, tools._log, "log")
    tools._log = {}
end

function tools.logElementsInCore(core)
    tools.logf("\n\nELEMENTS: (number, id, name, type)")
    local elements =  core.getElementIdList()
    for i,element in pairs(elements) do
        tools.logf("%s, %s, '%s', '%s'", 
            i, element, core.getElementNameById(element), core.getElementTypeById(element))
    end
end

function tools.logSlots()
    printf("Logging slots.")
    tools.logf("\n\nSLOTS: (name, type, json)")
    for name,slot in pairs(tools._slots) do
        tools.logf("'%s', '%s', %s", name, slot.getWidgetType(), slot.getData())
    end
    printf("Logging done.")
end

function tools.stickerForElement(id, direction, offset, number)
    local core = tools._elements.core

    local x,y,z = table.unpack(core.getElementPositionById(id))
    x = x - 32
    y = y - 32
    z = z - 32

    if offset then
        x = x + offset.x
        y = y + offset.y
        z = z + offset.z
    end

    if number then
        return core.spawnNumberSticker(number, x, y , z, direction)
    else
        return core.spawnArrowSticker(x, y, z, direction)
    end
end