local campaign_tech_levels =
{
  {
    name = 'initial',
    techs = {
      'automation',
    }
  },
  {
    name = 'radar',
    techs = {
      'electronics',
      'radar',
      'logistics',
    }
  },
  {
    name = 'crash',
    techs = {
      'optics',
      'military',
      'turrets',
      'heavy-armor',
      'fast-inserter',
      'weapon-shooting-speed-1',--red
      'physical-projectile-damage-1',--red
    }
  },
  {
    name = 'car',
    techs = {
      'logistic-science-pack',
      'stone-walls',
      'logistics-2',
      'engine',
      'automation-2',
      'automobilism',
      'steel-processing',
      'steel-axe',
      'concrete',
      'circuit-network',
      'toolbelt',
      'weapon-shooting-speed-2',--green
      'physical-projectile-damage-2',--green
    }
  },
  {
    name = 'trains',
    techs = {
      'railway',
      'advanced-material-processing',
      'electric-energy-distribution-1',
      'automated-rail-transportation',
      'military-2',
      'research-speed-1',
      'rail-signals',
      'gates',
      'stronger-explosives-1',--green
    }
  },
  {
    name = 'oil',
    techs = {
      'fluid-wagon',
      'oil-processing',
      'fluid-handling',
      'flammables',
      'flamethrower',
      'military-science-pack',
      'combat-robotics',
      'follower-robot-count-1',
      'follower-robot-count-2',
      'sulfur-processing',
      'explosives',
      'rocketry',
      'land-mine',
      'physical-projectile-damage-3',--black
      'physical-projectile-damage-4',
      'refined-flammables-1',--black
      'refined-flammables-2',
      'stronger-explosives-2',--black
      'weapon-shooting-speed-3',--black
      'weapon-shooting-speed-4',
    }
  },
  {
    name = 'robots',
    techs = {
      'battery',
      'electric-energy-accumulators',
      'solar-energy',
      'plastics',
      'advanced-electronics',
      'electric-engine',
      'modules',
      'speed-module',
      'productivity-module',
      'effectivity-module',
      'stack-inserter',
      'inserter-capacity-bonus-1',
      'inserter-capacity-bonus-2',
      'inserter-capacity-bonus-3',
      "laser",
      "laser-turrets",
      'lubricant',
      'robotics',
      'construction-robotics',
      'logistic-robotics',
      'worker-robots-speed-1',
      'worker-robots-storage-1',
      'advanced-material-processing-2',
      'personal-roboport-equipment',
      'chemical-science-pack',
      'advanced-oil-processing',
      'military-3',
      'modular-armor',
      'solar-panel-equipment',
      'mining-productivity-1',
      'battery-equipment',
      'night-vision-equipment',
      'energy-shield-equipment',
      'belt-immunity-equipment',
      "electric-energy-distribution-2",
    }
  },
  {
    name = 'tanks',
    techs = {
      "combat-robotics-2",
      "explosive-rocketry",
      "braking-force-1",
      "tanks",
      "personal-laser-defense-equipment",
      'power-armor',
      'rocket-fuel',
      'advanced-electronics-2',
      'low-density-structure',
      'speed-module-2',
      'productivity-module-2',
      'effectivity-module-2',
      'battery-mk2-equipment',
      'exoskeleton-equipment',
      'energy-shield-mk2-equipment',
      'discharge-defense-equipment',
      'weapon-shooting-speed-5',--blue
      'stronger-explosives-3',--blue
      'refined-flammables-3',--blue
      'follower-robot-count-3',--blue
      'follower-robot-count-4',
      'energy-weapons-damage-1',
      'energy-weapons-damage-2',
      'energy-weapons-damage-3',
      'energy-weapons-damage-4',
      'physical-projectile-damage-5',--blue
      'laser-turret-speed-1',
      'laser-turret-speed-2',
      'laser-turret-speed-3',
      'laser-turret-speed-4',
    }
  },
  {
    name = 'biters',
    techs = {
      'personal-roboport-mk2-equipment',
      'nuclear-power',
      'uranium-processing',
      'artillery',
      'utility-science-pack',
      'uranium-ammo',
      'military-4',
      'power-armor-mk2', --optional tech
      'combat-robotics-3',
      'fusion-reactor-equipment',
      'production-science-pack',
      'laser-turret-speed-5',--yellow
      'laser-turret-speed-6',
      'physical-projectile-damage-6',--yellow
      'energy-weapons-damage-5',--yellow
      'energy-weapons-damage-6',
      'follower-robot-count-5',--yellow
      'follower-robot-count-6',
      'refined-flammables-4',--yellow
      'refined-flammables-5',
      'refined-flammables-6',
      'stronger-explosives-4',--yellow
      'stronger-explosives-5',
      'stronger-explosives-6',
      'weapon-shooting-speed-6',--yellow
    }
  },
  {
    name = 'silo',
    techs = {
      'rocket-silo',
      'logistics-3',
      'automation-3',
      'logistic-system',
      'rocket-control-unit',
      'nuclear-fuel-reprocessing',
      'coal-liquefaction',
      'inserter-capacity-bonus-4',
      'speed-module-3',
      'effectivity-module-3',
      'productivity-module-3',
      'inserter-capacity-bonus-5',
      'inserter-capacity-bonus-6',
      'inserter-capacity-bonus-7',
    }
  },
}

return campaign_tech_levels