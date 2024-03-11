BraxScan = BraxScan or {}
BraxScan.Trigger = {
    -- external sources
    "http\\.",
    "HTTP",

    -- people don't use this for legit purposes
    "CompileString",
    "CompileFile",
    "RunString",
    "RunStringEx",
    "%(_G%)",

    -- encryption
    "Base64Encode",
    "Base64Decode",
    "CRC",

    -- superiority complex
    ":Ban\\(",
    ":Kick\\(",

    -- players
    "player.GetByUniqueID",
    "SetUserGroup",
    "setroot",
    "setrank",

    -- configs and cheats
    "hostip",
    "hostname",
    "server.cfg",
    "autoexec.cfg",
    "\\.dll",
    "\\.exe",
    "bind\\ ",
    "connect\\ ",
    "point_servercommand",
    "lua_run",
    "\"rcon",
    "\"rcon_password",
    "\"sv_password",
    "\"sv_cheats"
}

BraxScan.Version = 0.2
print("♫ BraxScan initialized on ".. (SERVER and "server" or "client") ..". Use 'braxscan' to scan.")
local LogBuffer = "\n"

function BraxScan.Print(color, text)
    if(type(color) == "table") then
        MsgC(color, text.."\n")
        BraxScan.LogAdd(text)
    else
        MsgN(color)
        BraxScan.LogAdd(color)
    end
end

function BraxScan.LogNew()
    LogBuffer = ""
end

function BraxScan.LogAdd(text)
    LogBuffer = LogBuffer .. text .. "\n"
end

function BraxScan.LogSave()
    file.Write("braxscan/scan_"..os.date("%y-%m-%d_%H-%M-%S")..".txt", LogBuffer)
end

file.CreateDir("braxscan")

function BraxScan.ScanAddon(addon)
    if not addon.title then
        addon.title = "[Title not available]"
    end

    if not addon.file then
        addon.file = "[File not available]"
    end

    if not addon.wsid then
        addon.wsid = "[ID not available]"
    end

    BraxScan.Print(Color(0,255,255), "♫ "..addon.title.." ♫")
    BraxScan.Print(Color(200,200,200), "File: "..addon.file)
    BraxScan.Print(Color(200,200,200), "ID: "..addon.wsid)

    MsgN("")

    local luafiles = 0
    local found = 0

    Files = {}

    local function Recurs(f, a)
        local files, folders = file.Find(f .. "*", a)
        if not files then
            return
        end

        if not folders then
            folders = {}
        end

        for k,v in pairs(files) do
            local s = string.Split(v,".")
            if s[#s] == "dll" then
                BraxScan.Print(Color(255,0,0), "\n\n!!! DLL file found in the addon "..a.." !!!\n")
            end

            if s[#s] == "lua" then
                table.insert(Files, f..v)
                local luafile = file.Read(f..v, "GAME")
                if not luafile then
                    BraxScan.Print(Color(255,0,0), "Unable to read Lua file: "..f..v)
                    continue
                end

                local lines = string.Split(luafile,"\n")
                if not lines then
                    continue
                end

                if #lines == 1 then
                    BraxScan.Print(Color(255,0,0), "+-- Only one line in "..f..v.." --")
                    BraxScan.Print(Color(0,255,0), "| 1 | "..lines[1].."\n")
                    found = found + 1
                end

                for linenr, line in pairs(lines) do
                    for _, w in pairs(BraxScan.Trigger) do
                        if string.find(line, w, 0, false) then
                            BraxScan.Print(Color(255,0,0), "┌── Suspicious element '"..w.."' found in "..f..v.." at line "..linenr.." ──")
                            for i=math.Clamp(linenr-3,0,9999),math.Clamp(linenr+3,0,#lines) do
                                if not lines[i] then
                                    continue
                                end
                                BraxScan.Print(i == linenr and Color(0,255,0) or Color(255,255,0), "│ "..i.." | "..lines[i])
                            end
                            BraxScan.Print(Color(255,0,0), "└───●")
                            BraxScan.Print("\n")
                            found = found + 1
                        end
                    end

                    local steamid = string.match(line, "(STEAM_[0-9]:[0-9]:[0-9]+)")
                    if steamid then
                        BraxScan.Print(Color(255,0,0), "┌── SteamID "..steamid.." found on line "..linenr.." in "..f..v.." ──")
                        for i=math.Clamp(linenr-3,0,9999),math.Clamp(linenr+3,0,#lines) do
                            BraxScan.Print(i == linenr and Color(0,255,0) or Color(255,255,0), "│ "..i.." | "..(lines[i] or ""))
                        end
                        BraxScan.Print(Color(255,0,0), "└───●")
                        BraxScan.Print("\n")
                        found = found + 1
                    end
                end
            end
        end

        for k,v in pairs(folders) do
            Recurs(f..v.."/",a)
        end
    end

    Recurs("",addon.title)
    BraxScan.Print(Color(200,200,128), "⌐ Lua files:          "..luafiles)
    BraxScan.Print(Color(200,200,128), "⌐ Suspicious things:  "..found)
    BraxScan.Print("")
end

concommand.Add("braxscan", function(ply, com, arg)
    if IsValid(ply) and not ply:IsSuperAdmin() then
        ply:PrintMessage(HUD_PRINTCONSOLE, "Superadmin only")
        return
    end

    if not arg[1] then
        print("\n---------- BraxScan "..BraxScan.Version.." ----------\n")
        print("To search all addons: braxscan all 1")
        print("To search a specific addon: braxscan *ID* 1")
        print("Last argument is whether to save log or not.")
        print("\n----------------------------------")
        return
    end

    local savelog = arg[2] == "1" and true or false

    local addons = engine.GetAddons()

    print("\n---------- BraxScan "..BraxScan.Version.." ----------\n")

    print("Addons installed: "..#addons)
    print("\nStarting search...\n")

    if not BraxScan.Trigger then
        MsgC(Color(255,0,0), "No definitions file, odd.\n")
        return
    end

    if arg[1] == "all" then
        BraxScan.LogNew()
        for anum, addon in pairs(addons) do
            BraxScan.ScanAddon(addon)
        end

        if savelog then BraxScan.LogSave() end
    else
        BraxScan.LogNew()

        print("Specific search for ID "..arg[1].."...")

        local found = false
        for anum, addon in pairs(addons) do
            if addon.wsid == arg[1] then
                BraxScan.ScanAddon(addon)
                found = true
                break
            end
        end

        if savelog then BraxScan.LogSave() end

        if not found then
            MsgC(Color(255,0,0), "No addon with that ID installed.\n\n")
        end
    end

    MsgC(Color(0,255,0), "All done.")
    if savelog then
        MsgC(Color(0,255,0), "\nLog file saved to data directory.")
    end

    print("\n\n----------------------------------")
end)
