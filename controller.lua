-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
--  Created by Samedi on 24/10/2020.
--  All code (c) 2020 - present day, The Samedi Corporation.
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

IndustryMonitor = {}

function IndustryMonitor.new()
    local instance = {}
    setmetatable(instance, { __index = IndustryMonitor })
    return instance
end

function IndustryMonitor:start(elements)
    print("Initialising industry monitor.")

    local unit = elements.unit
    local system = elements.system

    self._elements = elements
    self._machines = {}
    self._machineIds = {}
    self._databanks = {}
    self._currentItem = 1
    self._screenUpdateCounter = 1000
    self._screenContent = ""
    self._showKind = false

    self._html = [[
        <style>
            .summary { font-size: 28px; font-weight: bold; margin: 2%%; }
            .kind { font-size: 20px; color: #aaaaaa; padding-right: 5px; }
            .status { font-size: 25px; font-weight: bold; text-align: right;  }
            .names { font-weight: bold; }
            .machine { font-size: 25px; }
            .warning { color: orange; }
            .clear { color: green; }
            .error { color: red; }
            .pending { color: yellow; }
            .separator { list-style-type: circle; }

            td { vertical-align: top; }
            ul {
                margin: 10px;
            }

            li { 
                float: left;
            }
            table {
                width: 98%%;
                margin: 1%%;
            }
        </style>  

        <span class="summary">%s</span>
        <table>%s</table>
    ]]

    self:setupTables()
    self:registerElements()
    self:update()

    unit.hide()
    unit.setTimer("updateCollector", 5)

    print("Industry collector initialised.")
end

function IndustryMonitor:setupTables()
    local kinds = {}
    kinds["metalwork industry"] = "M"
    kinds["electronics industry"] = "E"
    kinds["smelter"] = "S"
    kinds["assembly line"] = "A"
    kinds["3D printer"] = "P"
    kinds["chemical industry"] = "C"
    kinds["glass furnace"] = "G"
    kinds["refiner"] = "R"
    kinds["recycler"] = "Y"
    self._kinds = kinds

    self._labels = {
        STOPPED = 'Stopped',
        RUNNING = 'Running',
        PENDING = "Pending",
        JAMMED_MISSING_INGREDIENT = "Empty",
        JAMMED_NO_OUTPUT_CONTAINER = "Output Missing",
        JAMMED_OUTPUT_FULL = "Full",
        OTHER = "Unknown"
    }

    self._classes = {
        STOPPED = 'warning',
        RUNNING = 'clear',
        PENDING = "pending",
        JAMMED_MISSING_INGREDIENT = "error",
        JAMMED_NO_OUTPUT_CONTAINER = "error",
        JAMMED_OUTPUT_FULL = "error",
        OTHER = "warning"
    }
  
    self._order = {
        "JAMMED_NO_OUTPUT_CONTAINER", 
        "JAMMED_MISSING_INGREDIENT",
        "JAMMED_OUTPUT_FULL", 
        "OTHER",
        "RUNNING",
        "PENDING",
        "STOPPED",
    }
end

function IndustryMonitor:registerElements()
    for k, element in pairs(_G) do
        if (k:find("Unit_") == 1) and (element.getElementClass) then
            local class = element.getElementClass()
            if class == "ScreenUnit" then
                self._screen = element
                print("Registered screen.")
            elseif class == "DataBankUnit" then
                self._databank = element
                table.insert(self._databanks, element)
                print("Registered databank.")
            elseif class == "CoreUnitStatic" then
                self._core = element
                print("Registered core.")
            elseif class == "IndustryUnit" then
                self:registerIndustryUnit(element)
                print("Registered unit.")
            else
                print(class)
            end
        end
    end
end

function IndustryMonitor:registerIndustryUnit(element)
    local id = element.getId()
    table.insert(self._machineIds, id)
    local machine = { id = id, name = string.format("Unknown (%s)", id), link = element }
    self._machines[id] = machine
end

function IndustryMonitor:stop()
    if self._screen then
        self._screen.clear()
        local logo = [[
            <svg class="bootstrap" viewBox="0 0 480 270" style="width:100%; height:100%">
            <g id="Baron" stroke="none" stroke-width="1" fill="none" fill-rule="evenodd">
                <text x="150" y="100" style="font-size: 20px; fill: white;">Industry Monitor</text>
                <text x="150" y="120" style="font-size: 20px; fill: white;">v2.0</text>
                <text x="150" y="140" style="font-size: 20px; fill: white;">(C) Samedicorp 2020.</text>

                <g id="Group" transform="translate(22.000000, 5.000000)">
                    <g>
                        <circle id="Oval" stroke="#000000" stroke-width="6" cx="59.0024282" cy="93" r="46"></circle>
                        <circle id="Face" stroke="#000000" stroke-width="6" fill="#FFFFFF" cx="59.0024282" cy="93" r="46"></circle>
                        <path d="M88.4780159,92.2994427 C90.3681655,94.535636 91.5024282,97.3899577 91.5024282,100.5 C91.5024282,104.087833 89.9928333,107.335112 87.5548553,109.686019 C85.110176,112.043389 81.7324883,113.5 78.0024282,113.5 C74.2723681,113.5 70.8946803,112.043389 68.450001,109.686019 C66.012023,107.335112 64.5024282,104.087833 64.5024282,100.5 C64.5024282,98.2355663 65.1036127,96.1065499 66.1602941,94.2531461 L66.1602941,94.2531461 Z" id="Right-Eye" stroke="#000000" fill="#000000"></path>
                        <path d="M50.4780159,92.5194261 C52.3681655,94.7556193 53.5024282,97.6099411 53.5024282,100.719983 C53.5024282,104.307816 51.9928333,107.555095 49.5548553,109.906003 C47.110176,112.263372 43.7324883,113.719983 40.0024282,113.719983 C36.2723681,113.719983 32.8946803,112.263372 30.450001,109.906003 C28.012023,107.555095 26.5024282,104.307816 26.5024282,100.719983 C26.5024282,98.4555497 27.1036127,96.3265332 28.1602941,94.4731295 L28.1602941,94.4731295 Z" id="Left-Eye" stroke="#000000" fill="#000000" transform="translate(40.002428, 103.109992) scale(-1, 1) translate(-40.002428, -103.109992) "></path>
                        <path d="M58.0024282,2.5 C73.4041164,2.5 87.2796899,3.88063377 96.9961307,6.10717127 L97.41,6.203 L95.122309,62.5 L113.503183,62.5 L113.503603,63.8929627 C102.37325,70.9075819 81.8781196,75.5 58.5024282,75.5 C34.3998341,75.5 13.3504884,70.6262095 2.50069194,63.2398215 L2.50069194,63.2398215 L2.50108849,62.5 L21.9046734,62.5 L19.5851808,5.96571241 C29.315612,3.82279503 42.928094,2.5 58.0024282,2.5 Z" id="Hat" stroke="#000000" stroke-width="5" fill="#000000"></path>
                        <g id="Teeth" transform="translate(29.002428, 121.000000)" fill="#FFFFFF">
                            <rect id="Rectangle" x="6.49757183" y="0" width="47" height="24"></rect>
                            <g transform="translate(3.997572, 12.000000)" stroke="#000000" stroke-linecap="round" stroke-width="5">
                                <path d="M13,16 C13,11.4094143 13,8.03322221 13,5.8714237 C13,2.62872593 10.0898509,0 6.5,0 C2.91014913,0 0,2.62872593 0,5.8714237" id="Oval" transform="translate(6.500000, 8.000000) rotate(180.000000) translate(-6.500000, -8.000000) "></path>
                                <path d="M52,16 C52,11.4094143 52,8.03322221 52,5.8714237 C52,2.62872593 49.0898509,0 45.5,0 C41.9101491,0 39,2.62872593 39,5.8714237" id="Oval-Copy-8" transform="translate(45.500000, 8.000000) scale(-1, 1) rotate(180.000000) translate(-45.500000, -8.000000) "></path>
                                <path d="M26,16 C26,12.6862915 23.0898509,10 19.5,10 C15.9101491,10 13,12.6862915 13,16" id="Oval-Copy-5" transform="translate(19.500000, 13.000000) rotate(180.000000) translate(-19.500000, -13.000000) "></path>
                                <path d="M39,16 C39,12.6862915 36.0898509,10 32.5,10 C28.9101491,10 26,12.6862915 26,16" id="Oval-Copy-6" transform="translate(32.500000, 13.000000) rotate(180.000000) translate(-32.500000, -13.000000) "></path>
                            </g>
                            <rect id="Rectangle-Copy-2" x="6.49757183" y="0" width="47" height="18"></rect>
                        </g>
                    </g>
                    <path d="M58.1336626,118.002789 C60.1789834,117.87174 64,122.395418 64,124.016254 C64,125.673108 62.6568542,127.016254 61,127.016254 C59.3431458,127.016254 58,125.673108 58,124.016254 L58,124.016254 L57.9949073,124.192526 C57.9036609,125.767334 56.5976809,127.016254 55,127.016254 C53.3431458,127.016254 52,125.673108 52,124.016254 C52,122.838649 54.164473,120.04799 56.032492,118.752037 C56.558506,118.293795 57.2468414,118.016254 58,118.016254 C58.0043708,118.016254 58.0087393,118.016263 58.0131057,118.016282 Z" id="Combined-Shape" stroke="#000000" stroke-width="2" fill="#000000" stroke-linejoin="round"></path>
                </g>
            </g>
        </svg>
        ]]

        self._screen.setHTML(logo)
    end
end

function IndustryMonitor:reset()
    print("Resetting")
    for i,databank in ipairs(self._databanks) do
        databank.clear()
    end
    self:update()
end

function IndustryMonitor:update()
    self:updateStatus()
    if self._screen then
        local count = self._screenUpdateCounter + 1
        if count > 10 then
            count = 0
            self:updateScreen()
        end
        self._screenUpdateCounter = count
    end
end

function IndustryMonitor:updateStatus()
    local index = self._currentItem
    if index > #self._machineIds then
        index = 1
    end
    self._currentItem = index + 1
    local id = self._machineIds[index]
    local machine = self._machines[id]
    if machine then
        local element = machine.link
        if element then
            --self._print("Updating machine " .. machine.id)
            self._databank.setStringValue(machine.id, element.getStatus())
        end
    end
    --self._print("Update completed...")
end

function IndustryMonitor:updateScreen()
    local system = self._system
    local screen = self._screen
    local databanks = self._databanks
    local machines = self._machines
    local core = self._core


    local index = {
        STOPPED = {},
        RUNNING = {},
        PENDING = {},
        JAMMED_MISSING_INGREDIENT = {},
        JAMMED_NO_OUTPUT_CONTAINER = {},
        JAMMED_OUTPUT_FULL = {},
        OTHER = {}
    }

    local total = 0
    for i,databank in ipairs(self._databanks) do
        local keyList = databank.getKeys()
        for key in keyList:gmatch('"(.-)"') do
            total = total + 1
            local machine = machines[key]
            if not machine then
                local name = core.getElementNameById(key)
                local kind = core.getElementTypeById(key)
                machine = {id = key, name = name, kind = kind}
                machines[key] = machine
            end

            if machine.name ~= "Unused" then
                local status = databank.getStringValue(key)
                if not index[status] then
                    printf("unknown status: %s for %s %s %s", status, machine.name, machine.id, machine.kind)
                    status = "OTHER"
                end
                machine.status = status
                table.insert(index[status], machine)
            end
        end
    end

    local lines = {}
    local showKind = self._showKind

    for i,status in pairs(self._order) do
        local machines = index[status]
        local count = #machines 
        if count > 0 then
            table.sort(machines, function(m1, m2) return m1.name < m2.name end)
            local names = {}
            for i,machine in ipairs(machines) do
                if showKind then
                    local kind = self._kinds[machine.kind] or machine.kind
                    table.insert(names, string.format('<li class="machine"><span class="kind">%s</span><span>%s</span><li>', kind, machine.name))
                else
                    table.insert(names, string.format('<li class="machine">%s</li>', machine.name))
                end
            end

            local label = self._labels[status]
            local class = self._classes[status]
            table.insert(lines, string.format('<tr><td class="status %s" width="5%%">%s (%s)</td><td class="names"><ul>%s</ul></td></tr>', class, label, count, table.concat(names, '')))
        end
    end

    local summary = string.format("%s machines.", total)

    
    local content = string.format(self._html, summary, table.concat(lines, ""))
    if self._screenContent ~= content then
        self._screenContent = content
        print("Updated display.")
        screen.setHTML(content)
    end
end