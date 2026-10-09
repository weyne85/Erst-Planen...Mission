-- =====================================================================
-- Kaukasus Allround Training - 20_bfm.lua
-- BFM on demand: a bandit spawns next to the requesting player, anywhere.
-- Parallel: one bandit per player group.
-- Moose: SPAWN, FLIGHTGROUP + AUFTRAG (INTERCEPT against the player).
-- =====================================================================

KA = KA or {}
KA.BFM = {}

local def = KA.RegisterScenario({
  id = "bfm", title = "BFM", parallel = true, restart = false, replace = true,
  timeout = KA.CFG.bfm.timeout,
})

local NM = 1852
-- distance (m), bearing offset from player heading, bandit heading offset
local SETUPS = {
  { key = "off",  text = "Offensive (bandit 1.2 nm ahead)", dist = 1.2 * NM, brg = 0,   hdg = 0 },
  { key = "def",  text = "Defensive (bandit at your 6)",    dist = 1.0 * NM, brg = 180, hdg = 0 },
  { key = "neu",  text = "Neutral (line abreast 1.5 nm)",   dist = 1.5 * NM, brg = 90,  hdg = 0 },
  { key = "head", text = "Head-on (6 nm)",                  dist = 6.0 * NM, brg = 0,   hdg = 180 },
}

function def.OnStart(s, opts)
  local C = KA.CFG.bfm
  local bandit = C.bandits[opts.bandit]
  local setup = SETUPS[opts.setup]
  local unit = s.group:GetFirstUnitAlive()
  if not (bandit and setup and unit) then return false end

  if not unit:InAir() or unit:GetAltitude(true) < UTILS.FeetToMeters(C.minAltFt) then
    s:Msg(string.format("BFM: get airborne and above %d ft AGL first.", C.minAltFt))
    return false
  end

  local hdg = unit:GetHeading()
  local side = (setup.brg == 90 and math.random(2) == 1) and -1 or 1
  local pos = unit:GetCoordinate()
  local spawnPos = pos:Translate(setup.dist, (hdg + side * setup.brg) % 360, true):SetAltitude(pos.y, true)

  local sp = KA.Spawner(bandit.template, "RED Bandit " .. bandit.name)
  if not sp then s:Msg("BFM: template missing: " .. bandit.template); return false end
  sp:InitHeading((hdg + setup.hdg) % 360)
  sp:InitSpeedKnots(math.max(300, unit:GetVelocityKNOTS()))
  local g = sp:SpawnFromCoordinate(spawnPos)
  if not g then return false end
  s:Track(g)
  s.data.bandit = g
  s.data.name = bandit.name

  local fg = FLIGHTGROUP:New(g)
  fg:AddMission(AUFTRAG:NewINTERCEPT(s.group))

  s:Msg(string.format("BFM: %s, %s. FIGHT'S ON!", bandit.name, setup.text), 20)
  return true
end

function def.OnTick(s)
  if not KA.IsAliveGroup(s.data.bandit) then
    s:Msg(string.format("Splash one %s!", s.data.name or "bandit"), 20)
    return "done"
  end
end

function def.Status(s)
  local g = s.data.bandit
  local me = s.group:GetCoordinate()
  if not (KA.IsAliveGroup(g) and me) then return "no bandit" end
  local c = g:GetCoordinate()
  return string.format("%s: %s, %d ft", s.data.name, KA.BRText(me, c), math.floor(UTILS.MetersToFeet(c.y)))
end

function KA.BFM.Init()
  local C = KA.CFG.bfm
  for i, b in ipairs(C.bandits) do
    if KA.Need("group", b.template, "BFM") then
      for j, setup in ipairs(SETUPS) do
        KA.Menu.Add({ "BFM", b.name }, setup.text, KA.MenuStart(def, { bandit = i, setup = j }))
      end
    end
  end
  KA.Menu.Add({ "BFM" }, "Knock it off", KA.MenuStop(def))
  KA.Menu.Add({ "BFM" }, "Picture (bandit position)", KA.MenuStatus(def))
  return true
end
