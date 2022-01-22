--[[
   Script to update outfits and ships from a saved game in the case they don't exist.
--]]

--[[
   The format is ["oldname"] = newvalue where newvalue can either take a string
   for the new name of the outfit (if there is a direct equivalent) or a number
   value indicating the amount of credits to refund the player.
--]]
local outfit_list = {
   -- Below is a list of changes from 0.9.0 to 0.10.0
   ["Drone Fighter Bay"] = "Drone Bay",
   ["Empire Lancelot Fighter Bay"] = "Empire Lancelot Bay",
   ["Fidelity Fighter Bay"] = "Fidelity Bay",
   ["Hyena Fighter Dock"] = "Hyena Bay",
   ["Hyena Fighter Bay"] = "Hyena Dock",
   ["Lancelot Fighter Bay"] = "Lancelot Bay",
   ["Pirate Hyena Fighter Dock"] = "Pirate Hyena Bay",
   ["Pirate Hyena Fighter Bay"] = "Pirate Hyena Dock",
   ["Proteron Derivative Fighter Bay"] = "Proteron Derivative Bay",
   ["Soromid Brigand Fighter Bay"] = "Soromid Brigand Bay",
   ["Thurion Perspicacity Fighter Dock"] = "Thurion Perspicacity Bay",
   ["Thurion Perspicacity Fighter Bay"] = "Thurion Perspicacity Dock",
   ["Za'lek Bomber Drone Fighter Dock"] = "Za'lek Bomber Drone Bay",
   ["Za'lek Bomber Drone Fighter Bay"] = "Za'lek Bomber Drone Mini Bay",
   ["Za'lek Heavy Drone Fighter Dock"] = "Za'lek Heavy Drone Bay",
   ["Za'lek Heavy Drone Fighter Bay"] = "Za'lek Heavy Drone Mini Bay",
   ["Za'lek Light Drone Fighter Dock"] = "Za'lek Light Drone Bay",
   ["Za'lek Light Drone Fighter Bay"] = "Za'lek Light Drone Mini Bay",
   ["Unicorp Banshee Launcher"] = 35e3,
   ["Unicorp Mace Launcher"] = 19e3,
   ["Unicorp Fury Launcher"] = 65e3,
   ["Unicorp Headhunter Launcher"] = 70e3,
   ["Unicorp Medusa Launcher"] = 73e3,
   ["Unicorp Vengeance Launcher"] = 78e3,
   -- Below is a list of changes from 0.8.2 to 0.9.0
   ["Unicorp PT-900 Core System"] = "Unicorp PT-500 Core System",
   ["Unicorp PT-600 Core System"] = "Unicorp PT-310 Core System",
   ["Unicorp PT-1000 Core System"] = "Unicorp PT-2200 Core System",
   ["Unicorp PT-100 Core System"] = "Unicorp PT-16 Core System",
   ["Unicorp Hawk 150 Engine"] = "Nexus Dart 150 Engine",
   ["Unicorp Falcon 550 Engine"] = "Unicorp Falcon 1300 Engine",
   ["Unicorp Falcon 1200 Engine"] = "Unicorp Falcon 1300 Engine",
   ["Unicorp Eagle 6500 Engine"] = "Unicorp Eagle 7000 Engine",
   ["Unicorp Eagle 4500 Engine"] = "Unicorp Eagle 7000 Engine",
   ["Unicorp D-8 Medium Plating"] = "Unicorp D-12 Medium Plating",
   ["Unicorp D-20 Heavy Plating"] = "Unicorp D-68 Heavy Plating",
   ["Unicorp D-16 Heavy Plating"] = "Unicorp D-68 Heavy Plating",
   ["Unicorp B-8 Medium Plating"] = "Unicorp D-12 Medium Plating",
   ["Unicorp B-4 Light Plating"] = "Unicorp D-4 Light Plating",
   ["Unicorp B-20 Heavy Plating"] = "Unicorp D-68 Heavy Plating",
   ["Unicorp B-2 Light Plating"] = "Unicorp D-2 Light Plating",
   ["Unicorp B-16 Heavy Plating"] = "Unicorp D-24 Medium Plating",
   ["Unicorp B-12 Medium Plating"] = "Unicorp D-24 Medium Plating",
   ["Ultralight Bioship Strong Fin Stage X"] = "Ultralight Strong Gene Drive Stage X",
   ["Ultralight Bioship Strong Fin Stage 2"] = "Ultralight Strong Gene Drive Stage 2",
   ["Ultralight Bioship Strong Fin Stage 1"] = "Ultralight Strong Gene Drive Stage 1",
   ["Ultralight Bioship Shell Stage X"] = "Ultralight Shell Stage X",
   ["Ultralight Bioship Shell Stage 2"] = "Ultralight Shell Stage 2",
   ["Ultralight Bioship Shell Stage 1"] = "Ultralight Shell Stage 1",
   ["Ultralight Bioship Fast Fin Stage X"] = "Ultralight Fast Gene Drive Stage X",
   ["Ultralight Bioship Fast Fin Stage 2"] = "Ultralight Fast Gene Drive Stage 2",
   ["Ultralight Bioship Fast Fin Stage 1"] = "Ultralight Fast Gene Drive Stage 1",
   ["Ultralight Bioship Brain Stage X"] = "Ultralight Brain Stage X",
   ["Ultralight Bioship Brain Stage 2"] = "Ultralight Brain Stage 2",
   ["Ultralight Bioship Brain Stage 1"] = "Ultralight Brain Stage 1",
   ["Thurion Reactor Class III"] = 155e4,
   ["Thurion Reactor Class II"] = 97e4,
   ["Thurion Reactor Class I"] = 53e4,
   ["Thurion Engine Reroute"] = "Engine Reroute",
   ["Thurion Energy Cell III"] = 0,
   ["Thurion Energy Cell II"] = 0,
   ["Thurion Energy Cell I"] = 0,
   ["Superheavy Bioship Strong Fin Stage X"] = "Superheavy Strong Gene Drive Stage X",
   ["Superheavy Bioship Strong Fin Stage 7"] = "Superheavy Strong Gene Drive Stage 7",
   ["Superheavy Bioship Strong Fin Stage 6"] = "Superheavy Strong Gene Drive Stage 6",
   ["Superheavy Bioship Strong Fin Stage 5"] = "Superheavy Strong Gene Drive Stage 5",
   ["Superheavy Bioship Strong Fin Stage 4"] = "Superheavy Strong Gene Drive Stage 4",
   ["Superheavy Bioship Strong Fin Stage 3"] = "Superheavy Strong Gene Drive Stage 3",
   ["Superheavy Bioship Strong Fin Stage 2"] = "Superheavy Strong Gene Drive Stage 2",
   ["Superheavy Bioship Strong Fin Stage 1"] = "Superheavy Strong Gene Drive Stage 1",
   ["Superheavy Bioship Shell Stage X"] = "Superheavy Shell Stage X",
   ["Superheavy Bioship Shell Stage 7"] = "Superheavy Shell Stage 7",
   ["Superheavy Bioship Shell Stage 6"] = "Superheavy Shell Stage 6",
   ["Superheavy Bioship Shell Stage 5"] = "Superheavy Shell Stage 5",
   ["Superheavy Bioship Shell Stage 4"] = "Superheavy Shell Stage 4",
   ["Superheavy Bioship Shell Stage 3"] = "Superheavy Shell Stage 3",
   ["Superheavy Bioship Shell Stage 2"] = "Superheavy Shell Stage 2",
   ["Superheavy Bioship Shell Stage 1"] = "Superheavy Shell Stage 1",
   ["Superheavy Bioship Fast Fin Stage X"] = "Superheavy Fast Gene Drive Stage X",
   ["Superheavy Bioship Fast Fin Stage 7"] = "Superheavy Fast Gene Drive Stage 7",
   ["Superheavy Bioship Fast Fin Stage 6"] = "Superheavy Fast Gene Drive Stage 6",
   ["Superheavy Bioship Fast Fin Stage 5"] = "Superheavy Fast Gene Drive Stage 5",
   ["Superheavy Bioship Fast Fin Stage 4"] = "Superheavy Fast Gene Drive Stage 4",
   ["Superheavy Bioship Fast Fin Stage 3"] = "Superheavy Fast Gene Drive Stage 3",
   ["Superheavy Bioship Fast Fin Stage 2"] = "Superheavy Fast Gene Drive Stage 2",
   ["Superheavy Bioship Fast Fin Stage 1"] = "Superheavy Fast Gene Drive Stage 1",
   ["Superheavy Bioship Brain Stage X"] = "Superheavy Brain Stage X",
   ["Superheavy Bioship Brain Stage 7"] = "Superheavy Brain Stage 7",
   ["Superheavy Bioship Brain Stage 6"] = "Superheavy Brain Stage 6",
   ["Superheavy Bioship Brain Stage 5"] = "Superheavy Brain Stage 5",
   ["Superheavy Bioship Brain Stage 4"] = "Superheavy Brain Stage 4",
   ["Superheavy Bioship Brain Stage 3"] = "Superheavy Brain Stage 3",
   ["Superheavy Bioship Brain Stage 2"] = "Superheavy Brain Stage 2",
   ["Superheavy Bioship Brain Stage 1"] = "Superheavy Brain Stage 1",
   ["Steering Thrusters"] = 13e4,
   ["Solar Panel"] = 25e3,
   ["Shield Nullifier"] = 1,
   ["Shield Capacitor"] = "Shield Capacitor I",
   ["Shattershield Lance"] = 28e3,
   ["S&K Ultralight Stealth Plating"] = 95e3,
   ["S&K Medium-Heavy Stealth Plating"] = 48e4,
   ["S&K Medium Stealth Plating"] = 27e4,
   ["S&K Light Stealth Plating"] = 18e4,
   ["Razor Turret MK3"] = "Razor Turret MK1",
   ["Razor MK3"] = "Razor MK1",
   ["Pulse Beam"] = 26e3,
   ["Power Regulation Override"] = 55e3,
   ["Plasma Cluster Cannon MK3"] = "Plasma Cluster Cannon",
   ["Plasma Cluster Cannon MK2"] = "Plasma Cluster Cannon",
   ["Plasma Cluster Cannon MK1"] = "Plasma Cluster Cannon",
   ["Plasma Blaster MK3"] = 26e3,
   ["Plasma Blaster MK2"] = 17e3,
   ["Plasma Blaster MK1"] = 9e3,
   ["Nexus Dart 300 Engine"] = "Nexus Dart 150 Engine",
   ["Nexus Bolt 6500 Engine"] = "Nexus Bolt 3500 Engine",
   ["Nexus Bolt 4500 Engine"] = "Nexus Bolt 3500 Engine",
   ["Nexus Arrow 550 Engine"] = "Nexus Arrow 700 Engine",
   ["Nexus Arrow 1200 Engine"] = "Nexus Arrow 700 Engine",
   ["Milspec Prometheus 9803 Core System"] = "Milspec Thalos 9802 Core System",
   ["Milspec Prometheus 8503 Core System"] = "Milspec Thalos 8502 Core System",
   ["Milspec Prometheus 5403 Core System"] = "Milspec Thalos 5402 Core System",
   ["Milspec Prometheus 4703 Core System"] = "Milspec Thalos 4702 Core System",
   ["Milspec Prometheus 3603 Core System"] = "Milspec Thalos 3602 Core System",
   ["Milspec Prometheus 2203 Core System"] = "Milspec Thalos 2202 Core System",
   ["Milspec Hermes 9802 Core System"] = "Milspec Orion 9901 Core System",
   ["Milspec Hermes 8502 Core System"] = "Milspec Orion 8601 Core System",
   ["Milspec Hermes 5402 Core System"] = "Milspec Orion 5501 Core System",
   ["Milspec Hermes 4702 Core System"] = "Milspec Orion 4801 Core System",
   ["Milspec Hermes 3602 Core System"] = "Milspec Orion 3701 Core System",
   ["Milspec Hermes 2202 Core System"] = "Milspec Orion 2301 Core System",
   ["Milspec Aegis 9801 Core System"] = "Milspec Thalos 9802 Core System",
   ["Milspec Aegis 8501 Core System"] = "Milspec Thalos 8502 Core System",
   ["Milspec Aegis 5401 Core System"] = "Milspec Thalos 5402 Core System",
   ["Milspec Aegis 4701 Core System"] = "Milspec Thalos 4702 Core System",
   ["Milspec Aegis 3601 Core System"] = "Milspec Thalos 3602 Core System",
   ["Milspec Aegis 2201 Core System"] = "Milspec Thalos 2202 Core System",
   ["Melendez Ox Engine"] = "Melendez Ox XL Engine",
   ["Melendez Mammoth Engine"] = "Melendez Mammoth XL Engine",
   ["Melendez Buffalo Engine"] = "Melendez Buffalo XL Engine",
   ["Medium-Heavy Bioship Strong Fin Stage X"] = "Medium-Heavy Strong Gene Drive Stage X",
   ["Medium-Heavy Bioship Strong Fin Stage 5"] = "Medium-Heavy Strong Gene Drive Stage 5",
   ["Medium-Heavy Bioship Strong Fin Stage 4"] = "Medium-Heavy Strong Gene Drive Stage 4",
   ["Medium-Heavy Bioship Strong Fin Stage 3"] = "Medium-Heavy Strong Gene Drive Stage 3",
   ["Medium-Heavy Bioship Strong Fin Stage 2"] = "Medium-Heavy Strong Gene Drive Stage 2",
   ["Medium-Heavy Bioship Strong Fin Stage 1"] = "Medium-Heavy Strong Gene Drive Stage 1",
   ["Medium-Heavy Bioship Shell Stage X"] = "Medium-Heavy Shell Stage X",
   ["Medium-Heavy Bioship Shell Stage 5"] = "Medium-Heavy Shell Stage 5",
   ["Medium-Heavy Bioship Shell Stage 4"] = "Medium-Heavy Shell Stage 4",
   ["Medium-Heavy Bioship Shell Stage 3"] = "Medium-Heavy Shell Stage 3",
   ["Medium-Heavy Bioship Shell Stage 2"] = "Medium-Heavy Shell Stage 2",
   ["Medium-Heavy Bioship Shell Stage 1"] = "Medium-Heavy Shell Stage 1",
   ["Medium-Heavy Bioship Fast Fin Stage X"] = "Medium-Heavy Fast Gene Drive Stage X",
   ["Medium-Heavy Bioship Fast Fin Stage 5"] = "Medium-Heavy Fast Gene Drive Stage 5",
   ["Medium-Heavy Bioship Fast Fin Stage 4"] = "Medium-Heavy Fast Gene Drive Stage 4",
   ["Medium-Heavy Bioship Fast Fin Stage 3"] = "Medium-Heavy Fast Gene Drive Stage 3",
   ["Medium-Heavy Bioship Fast Fin Stage 2"] = "Medium-Heavy Fast Gene Drive Stage 2",
   ["Medium-Heavy Bioship Fast Fin Stage 1"] = "Medium-Heavy Fast Gene Drive Stage 1",
   ["Medium-Heavy Bioship Brain Stage X"] = "Medium-Heavy Brain Stage X",
   ["Medium-Heavy Bioship Brain Stage 5"] = "Medium-Heavy Brain Stage 5",
   ["Medium-Heavy Bioship Brain Stage 4"] = "Medium-Heavy Brain Stage 4",
   ["Medium-Heavy Bioship Brain Stage 3"] = "Medium-Heavy Brain Stage 3",
   ["Medium-Heavy Bioship Brain Stage 2"] = "Medium-Heavy Brain Stage 2",
   ["Medium-Heavy Bioship Brain Stage 1"] = "Medium-Heavy Brain Stage 1",
   ["Medium Bioship Strong Fin Stage X"] = "Medium Strong Gene Drive Stage X",
   ["Medium Bioship Strong Fin Stage 4"] = "Medium Strong Gene Drive Stage 4",
   ["Medium Bioship Strong Fin Stage 3"] = "Medium Strong Gene Drive Stage 3",
   ["Medium Bioship Strong Fin Stage 2"] = "Medium Strong Gene Drive Stage 2",
   ["Medium Bioship Strong Fin Stage 1"] = "Medium Strong Gene Drive Stage 1",
   ["Medium Bioship Shell Stage X"] = "Medium Shell Stage X",
   ["Medium Bioship Shell Stage 4"] = "Medium Shell Stage 4",
   ["Medium Bioship Shell Stage 3"] = "Medium Shell Stage 3",
   ["Medium Bioship Shell Stage 2"] = "Medium Shell Stage 2",
   ["Medium Bioship Shell Stage 1"] = "Medium Shell Stage 1",
   ["Medium Bioship Fast Fin Stage X"] = "Medium Fast Gene Drive Stage X",
   ["Medium Bioship Fast Fin Stage 4"] = "Medium Fast Gene Drive Stage 4",
   ["Medium Bioship Fast Fin Stage 3"] = "Medium Fast Gene Drive Stage 3",
   ["Medium Bioship Fast Fin Stage 2"] = "Medium Fast Gene Drive Stage 2",
   ["Medium Bioship Fast Fin Stage 1"] = "Medium Fast Gene Drive Stage 1",
   ["Medium Bioship Brain Stage X"] = "Medium Brain Stage X",
   ["Medium Bioship Brain Stage 4"] = "Medium Brain Stage 4",
   ["Medium Bioship Brain Stage 3"] = "Medium Brain Stage 3",
   ["Medium Bioship Brain Stage 2"] = "Medium Brain Stage 2",
   ["Medium Bioship Brain Stage 1"] = "Medium Brain Stage 1",
   ["Mass Driver MK3"] = "Mass Driver",
   ["Mass Driver MK2"] = "Mass Driver",
   ["Mass Driver MK1"] = "Mass Driver",
   ["Light Bioship Strong Fin Stage X"] = "Light Strong Gene Drive Stage X",
   ["Light Bioship Strong Fin Stage 3"] = "Light Strong Gene Drive Stage 3",
   ["Light Bioship Strong Fin Stage 2"] = "Light Strong Gene Drive Stage 2",
   ["Light Bioship Strong Fin Stage 1"] = "Light Strong Gene Drive Stage 1",
   ["Light Bioship Shell Stage X"] = "Light Shell Stage X",
   ["Light Bioship Shell Stage 3"] = "Light Shell Stage 3",
   ["Light Bioship Shell Stage 2"] = "Light Shell Stage 2",
   ["Light Bioship Shell Stage 1"] = "Light Shell Stage 1",
   ["Light Bioship Fast Fin Stage X"] = "Light Fast Gene Drive Stage X",
   ["Light Bioship Fast Fin Stage 3"] = "Light Fast Gene Drive Stage 3",
   ["Light Bioship Fast Fin Stage 2"] = "Light Fast Gene Drive Stage 2",
   ["Light Bioship Fast Fin Stage 1"] = "Light Fast Gene Drive Stage 1",
   ["Light Bioship Brain Stage X"] = "Light Brain Stage X",
   ["Light Bioship Brain Stage 3"] = "Light Brain Stage 3",
   ["Light Bioship Brain Stage 2"] = "Light Brain Stage 2",
   ["Light Bioship Brain Stage 1"] = "Light Brain Stage 1",
   ["Laser PD MK3"] = 125e2,
   ["Laser PD MK2"] = 185e2,
   ["Laser PD MK1"] = 125e2,
   ["Laser Cannon MK3"] = "Laser Cannon MK1",
   ["Laser Cannon MK0"] = "Laser Cannon MK1",
   ["Improved Refrigeration Cycle"] = 19e4,
   ["Improved Power Regulator"] = 23e4,
   ["Heavy Laser"] = "Heavy Laser Turret",
   ["Heavy Bioship Strong Fin Stage X"] = "Heavy Strong Gene Drive Stage X",
   ["Heavy Bioship Strong Fin Stage 6"] = "Heavy Strong Gene Drive Stage 6",
   ["Heavy Bioship Strong Fin Stage 5"] = "Heavy Strong Gene Drive Stage 5",
   ["Heavy Bioship Strong Fin Stage 4"] = "Heavy Strong Gene Drive Stage 4",
   ["Heavy Bioship Strong Fin Stage 3"] = "Heavy Strong Gene Drive Stage 3",
   ["Heavy Bioship Strong Fin Stage 2"] = "Heavy Strong Gene Drive Stage 2",
   ["Heavy Bioship Strong Fin Stage 1"] = "Heavy Strong Gene Drive Stage 1",
   ["Heavy Bioship Shell Stage X"] = "Heavy Shell Stage X",
   ["Heavy Bioship Shell Stage 6"] = "Heavy Shell Stage 6",
   ["Heavy Bioship Shell Stage 5"] = "Heavy Shell Stage 5",
   ["Heavy Bioship Shell Stage 4"] = "Heavy Shell Stage 4",
   ["Heavy Bioship Shell Stage 3"] = "Heavy Shell Stage 3",
   ["Heavy Bioship Shell Stage 2"] = "Heavy Shell Stage 2",
   ["Heavy Bioship Shell Stage 1"] = "Heavy Shell Stage 1",
   ["Heavy Bioship Fast Fin Stage X"] = "Heavy Fast Gene Drive Stage X",
   ["Heavy Bioship Fast Fin Stage 6"] = "Heavy Fast Gene Drive Stage 6",
   ["Heavy Bioship Fast Fin Stage 5"] = "Heavy Fast Gene Drive Stage 5",
   ["Heavy Bioship Fast Fin Stage 4"] = "Heavy Fast Gene Drive Stage 4",
   ["Heavy Bioship Fast Fin Stage 3"] = "Heavy Fast Gene Drive Stage 3",
   ["Heavy Bioship Fast Fin Stage 2"] = "Heavy Fast Gene Drive Stage 2",
   ["Heavy Bioship Fast Fin Stage 1"] = "Heavy Fast Gene Drive Stage 1",
   ["Heavy Bioship Brain Stage X"] = "Heavy Brain Stage X",
   ["Heavy Bioship Brain Stage 6"] = "Heavy Brain Stage 6",
   ["Heavy Bioship Brain Stage 5"] = "Heavy Brain Stage 5",
   ["Heavy Bioship Brain Stage 4"] = "Heavy Brain Stage 4",
   ["Heavy Bioship Brain Stage 3"] = "Heavy Brain Stage 3",
   ["Heavy Bioship Brain Stage 2"] = "Heavy Brain Stage 2",
   ["Heavy Bioship Brain Stage 1"] = "Heavy Brain Stage 1",
   ["Generic Afterburner"] = "Unicorp Light Afterburner",
   ["Fuel Pod"] = "Small Fuel Pod",
   ["Forward Shock Absorbers"] = 35e3,
   ["Enygma Systems Turreted Vengeance Launcher"] = "Enygma Systems Turreted Headhunter Launcher",
   ["Energy Torpedo"] = 1e5,
   ["Energy Missile"] = 75e3,
   ["Energy Dart"] = 5e4,
   ["Cargo Pod"] = "Small Cargo Pod",
   ["BioPlasma Organ Stage X"] = "BioPlasma Stinger Stage X",
   ["BioPlasma Organ Stage 3"] = "BioPlasma Stinger Stage 3",
   ["BioPlasma Organ Stage 2"] = "BioPlasma Stinger Stage 2",
   ["BioPlasma Organ Stage 1"] = "BioPlasma Stinger Stage 1",
   ["Battery"] = "Battery I",
}
--[[--
   Takes an outfit name and should return either a new outfit name or the amount of credits to give back to the player.
--]]
function outfit( name )
   return outfit_list[name]
end

local license_list = {
   -- Below is a list of changes from 0.9.0-alpha to 0.9.0-beta
   ["Heavy Combat Vessel License"] = "Heavy Combat Vessel",
   ["Heavy Weapon License"] = "Heavy Weapon",
   ["Large Civilian Vessel License"] = "Large Civilian Vessel",
   ["Light Combat Vessel License"] = "Light Combat Vessel",
   ["Medium Combat Vessel License"] = "Medium Combat Vessel",
   ["Medium Weapon License"] = "Medium Weapon",
   ["Mercenary License"] = "Mercenary",
}
--[[--
   Takes a license name and should return either a new license name or the amount of credits to give back to the player.
--]]
function license( name )
   return license_list[name]
end
