local _, GQ = ...

GQ.Data = GQ.Data or {}

-- A few Forever pins that stay in the hunt beside the scored lists.
-- Paladin and warrior levels 1-9 come from the scorer, same as the other classes.

local SPEC_HOLY = { holy = true }
local SPEC_SHADOW = { shadow = true }
local HORDE = { Horde = true }
local SHAMAN_CLASS = { SHAMAN = true }
local SPEC_ELEMENTAL = { elemental = true }
local SPEC_ENHANCEMENT = { enhancement = true }
local SPEC_ENHANCEMENT_TANK = { enhancement_tank = true }
local SPEC_ENHANCEMENT_ALL = { enhancement = true, enhancement_tank = true }
local SPEC_RESTORATION = { restoration = true }
local MAGE_CLASS = { MAGE = true }
local SPEC_MAGE_ALL = { frost = true, fire = true, arcane = true }
local SPEC_FROST = { frost = true }
local SPEC_FIRE = { fire = true }
local SPEC_ARCANE = { arcane = true }
local WARLOCK_CLASS = { WARLOCK = true }
local SPEC_WARLOCK_ALL = { affliction = true, demonology = true, destruction = true }
local SPEC_AFF_DEMO = { affliction = true, demonology = true }
local SPEC_DESTRUCTION = { destruction = true }
local DRUID_CLASS = { DRUID = true }
local SPEC_DRUID_ALL = { bear = true, feral = true, balance = true, restoration = true }
local SPEC_BEAR_BALANCE = { bear = true, balance = true }
local SPEC_BALANCE = { balance = true }
local SPEC_DRUID_RESTO = { restoration = true }
local SPEC_BAL_RESTO = { balance = true, restoration = true }
local ROGUE_CLASS = { ROGUE = true }
local PRIEST_CLASS = { PRIEST = true }
local SPEC_DISC = { discipline = true }
local SPEC_HOLY_DISC = { holy = true, discipline = true }
local HUNTER_CLASS = { HUNTER = true }
local SPEC_HUNTER_ALL = { beast_mastery = true, marksmanship = true, survival = true }

-- Second ring-slot milestone: level 10 band adds more Finger upgrades.
GQ.Data.RING_SLOT_2_MILESTONE_LEVEL = 10

-- Crafted output names for trainer matching when GetItemInfo is not cached yet.
local PROFESSION_ITEM_NAMES = {
    [10421] = "Rough Copper Vest",
    [2853] = "Copper Bracers",
    [3469] = "Copper Chain Boots",
    [2852] = "Copper Chain Pants",
    [3471] = "Copper Chain Vest",
    [2851] = "Copper Chain Belt",
    [2580] = "Reinforced Linen Cape",
    [2570] = "Linen Cloak",
    [3472] = "Runed Copper Gauntlets",
    [2310] = "Embossed Leather Cloak",
    [3473] = "Runed Copper Pants",
    [3474] = "Gemmed Copper Gauntlets",
    [3488] = "Copper Battle Axe",
    [253887] = "Novice Ardent's Sash",
    [253885] = "Novice Arcanist's Sash",
    [250482] = "Glowing Copper Boots",
    [250621] = "Strange Copper Boots",
    [250620] = "Gemmed Copper Boots",
    [254001] = "Gilded Slippers",
    [254003] = "Frothing Slippers",
    [254005] = "Fiery Slippers",
    [254009] = "Golden Slippers",
    [254007] = "Black Slippers",
}

GQ.Data.entries = {
    -- Forever phase-4 deltas (Horde shaman). Seen in the beta notebook with
    -- item IDs + tooltips. foreverDelta keeps them in the hunt across generated
    -- per-level bands; Compare still takes the top 3 by pipelineScore.
    {
        id = "forever_horde_shaman_ranged_windcarved_effigy",
        itemId = 263412,
        slot = "Ranged",
        minLevel = 1,
        maxLevel = 51,
        classes = SHAMAN_CLASS,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 0.5,
        sourceType = "quest_reward",
        instructions = "Quest reward in Shen'dar Village on Zephras Isle. Shaman totem: Lightning Bolt costs 5 less mana. Fills the relic slot until Totem of Rage (52).",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_shaman_waist_skychain_belt",
        itemId = 257272,
        slot = "Waist",
        minLevel = 1,
        maxLevel = 9,
        classes = SHAMAN_CLASS,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 0.38,
        sourceType = "quest_reward",
        instructions = "Quest reward in Thendal Village on Zephras Isle. Mail waist, 38 armor — more armor than the Classic grey/white belts in this band.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_shaman_feet_thendal_ranger_shoes",
        itemId = 257257,
        slot = "Feet",
        minLevel = 1,
        maxLevel = 9,
        classes = SHAMAN_CLASS,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 0.46,
        sourceType = "quest_reward",
        instructions = "Quest reward in Thendal Village on Zephras Isle. Mail feet, 46 armor — beats the Classic 1–9 leather greys on armor alone.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_shaman_legs_highlands_mail",
        itemId = 263423,
        slot = "Legs",
        minLevel = 1,
        maxLevel = 4,
        classes = SHAMAN_CLASS,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 0.71,
        sourceType = "quest_reward",
        instructions = "Quest reward in Shen'dar Village on Zephras Isle. Mail legs, 71 armor. Burnt Leather Breeches take over at 5.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_shaman_ele_waist_arcanist_sash",
        itemId = 253885,
        slot = "Waist",
        minLevel = 10,
        maxLevel = 19,
        classes = SHAMAN_CLASS,
        specs = SPEC_ELEMENTAL,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 5.74,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Novice Arcanist's Sash (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 8 Bolt of Linen Cloth, 2 Fine Thread, 2 Minor Mana Potion. +3 Intellect, +3 Stamina, +4 spell power. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_shaman_ele_waist_ardent_sash",
        itemId = 253887,
        slot = "Waist",
        minLevel = 10,
        maxLevel = 17,
        classes = SHAMAN_CLASS,
        specs = SPEC_ELEMENTAL,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 3.69,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Novice Ardent's Sash (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 12 Bolt of Linen Cloth, 2 Fine Thread, 2 Minor Healing Potion. +3 Intellect, +3 Spirit, +6 healing / +2 spell damage. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_shaman_resto_waist_ardent_sash",
        itemId = 253887,
        slot = "Waist",
        minLevel = 10,
        maxLevel = 35,
        classes = SHAMAN_CLASS,
        specs = SPEC_RESTORATION,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 9.39,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Novice Ardent's Sash (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 12 Bolt of Linen Cloth, 2 Fine Thread, 2 Minor Healing Potion. +3 Intellect, +3 Spirit, +6 healing / +2 spell damage. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_shaman_resto_waist_arcanist_sash",
        itemId = 253885,
        slot = "Waist",
        minLevel = 10,
        maxLevel = 17,
        classes = SHAMAN_CLASS,
        specs = SPEC_RESTORATION,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 3.24,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Novice Arcanist's Sash (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 8 Bolt of Linen Cloth, 2 Fine Thread, 2 Minor Mana Potion. +3 Intellect, +3 Stamina, +4 spell power. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_shaman_ele_feet_strange_copper",
        itemId = 250621,
        slot = "Feet",
        minLevel = 10,
        maxLevel = 26,
        classes = SHAMAN_CLASS,
        specs = SPEC_ELEMENTAL,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 5.95,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Craft Strange Copper Boots (Blacksmithing). Recipe in Shen'dar Village, Zephras Isle. 2 Copper Bar, 2 Light Leather. +4 Stamina, +5 spell power. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_shaman_ele_feet_glowing_copper",
        itemId = 250482,
        slot = "Feet",
        minLevel = 10,
        maxLevel = 26,
        classes = SHAMAN_CLASS,
        specs = SPEC_ELEMENTAL,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 5.35,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Craft Glowing Copper Boots (Blacksmithing). Recipe in Shen'dar Village, Zephras Isle. 2 Copper Bar, 2 Light Leather. +4 Intellect, +9 healing / +3 spell damage. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_shaman_resto_feet_glowing_copper",
        itemId = 250482,
        slot = "Feet",
        minLevel = 10,
        maxLevel = 44,
        classes = SHAMAN_CLASS,
        specs = SPEC_RESTORATION,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 12.65,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Craft Glowing Copper Boots (Blacksmithing). Recipe in Shen'dar Village, Zephras Isle. 2 Copper Bar, 2 Light Leather. +4 Intellect, +9 healing / +3 spell damage. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_shaman_resto_feet_strange_copper",
        itemId = 250621,
        slot = "Feet",
        minLevel = 10,
        maxLevel = 13,
        classes = SHAMAN_CLASS,
        specs = SPEC_RESTORATION,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 2.45,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Craft Strange Copper Boots (Blacksmithing). Recipe in Shen'dar Village, Zephras Isle. 2 Copper Bar, 2 Light Leather. +4 Stamina, +5 spell power. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_shaman_enh_feet_gemmed_copper",
        itemId = 250620,
        slot = "Feet",
        minLevel = 10,
        maxLevel = 14,
        classes = SHAMAN_CLASS,
        specs = SPEC_ENHANCEMENT_ALL,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 4.15,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Craft Gemmed Copper Boots (Blacksmithing). Recipe in Shen'dar Village, Zephras Isle. 2 Copper Bar, 2 Malachite, 4 Light Leather. +4 Strength, +4 Stamina. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_shaman_enh_feet_strange_copper",
        itemId = 250621,
        slot = "Feet",
        minLevel = 10,
        maxLevel = 10,
        classes = SHAMAN_CLASS,
        specs = SPEC_ENHANCEMENT,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 1.15,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Craft Strange Copper Boots (Blacksmithing). Recipe in Shen'dar Village, Zephras Isle. 2 Copper Bar, 2 Light Leather. +4 Stamina, +5 spell power. Requires level 10.",
        zone = "Zephras Isle",
    },

    -- Forever phase-4 deltas (Horde mage). Cloth only. Mail copper boots
    -- and armor-only Skyborne whites do not beat the Classic cloth list.
    {
        id = "forever_horde_mage_waist_arcanist_sash",
        itemId = 253885,
        slot = "Waist",
        minLevel = 10,
        maxLevel = 19,
        classes = MAGE_CLASS,
        specs = SPEC_MAGE_ALL,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 5.72,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Novice Arcanist's Sash (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 8 Bolt of Linen Cloth, 2 Fine Thread, 2 Minor Mana Potion. +3 Intellect, +3 Stamina, +4 spell power. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_mage_waist_ardent_sash",
        itemId = 253887,
        slot = "Waist",
        minLevel = 10,
        maxLevel = 17,
        classes = MAGE_CLASS,
        specs = SPEC_MAGE_ALL,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 3.72,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Novice Ardent's Sash (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 12 Bolt of Linen Cloth, 2 Fine Thread, 2 Minor Healing Potion. +3 Intellect, +3 Spirit, +6 healing / +2 spell damage. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_mage_frost_feet_frothing",
        itemId = 254003,
        slot = "Feet",
        minLevel = 30,
        maxLevel = 44,
        classes = MAGE_CLASS,
        specs = SPEC_FROST,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 16.25,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Frothing Slippers (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 8 Bolt of Mageweave, 4 Heavy Silken Thread, 2 Magenta Dye, 2 Cerulean Dye. +7 Intellect, +6 Stamina, +4 Spirit, +13 Frost damage. Requires level 30.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_mage_arcane_feet_frothing",
        itemId = 254003,
        slot = "Feet",
        minLevel = 30,
        maxLevel = 37,
        classes = MAGE_CLASS,
        specs = SPEC_ARCANE,
        factions = HORDE,
        curatedRank = 3,
        foreverDelta = true,
        pipelineScore = 9.19,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Frothing Slippers (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 8 Bolt of Mageweave, 4 Heavy Silken Thread, 2 Magenta Dye, 2 Cerulean Dye. +13 Frost damage also scores for Arcane. Requires level 30.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_mage_fire_feet_fiery",
        itemId = 254005,
        slot = "Feet",
        minLevel = 30,
        maxLevel = 43,
        classes = MAGE_CLASS,
        specs = SPEC_FIRE,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 16.25,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Fiery Slippers (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 8 Bolt of Mageweave, 4 Heavy Silken Thread, 2 Magenta Dye, 2 Cerulean Dye. +7 Intellect, +6 Stamina, +4 Spirit, +13 Fire damage. Requires level 30.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_mage_feet_gilded",
        itemId = 254001,
        slot = "Feet",
        minLevel = 30,
        maxLevel = 39,
        classes = MAGE_CLASS,
        specs = SPEC_MAGE_ALL,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 11.29,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Gilded Slippers (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 8 Bolt of Mageweave, 4 Heavy Silken Thread, 2 Magenta Dye, 2 Cerulean Dye. +7 Intellect, +6 Stamina, +4 Spirit, +7 spell power. Requires level 30.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_mage_arcane_feet_golden",
        itemId = 254009,
        slot = "Feet",
        minLevel = 30,
        maxLevel = 39,
        classes = MAGE_CLASS,
        specs = SPEC_ARCANE,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 11.14,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Golden Slippers (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 8 Bolt of Mageweave, 4 Heavy Silken Thread, 2 Magenta Dye, 2 Cerulean Dye. +7 Intellect, +6 Stamina, +4 Spirit, +13 Arcane damage. Requires level 30.",
        zone = "Zephras Isle",
    },

    -- Forever phase-4 deltas (Horde warlock). Cloth only; 1-9 has no notebook winner.
    {
        id = "forever_horde_warlock_waist_arcanist_sash",
        itemId = 253885,
        slot = "Waist",
        minLevel = 10,
        maxLevel = 19,
        classes = WARLOCK_CLASS,
        specs = SPEC_WARLOCK_ALL,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 5.81,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Novice Arcanist's Sash (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 8 Bolt of Linen Cloth, 2 Fine Thread, 2 Minor Mana Potion. +3 Intellect, +3 Stamina, +4 spell power. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_warlock_waist_ardent_sash",
        itemId = 253887,
        slot = "Waist",
        minLevel = 10,
        maxLevel = 17,
        classes = WARLOCK_CLASS,
        specs = SPEC_WARLOCK_ALL,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 3.72,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Novice Ardent's Sash (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 12 Bolt of Linen Cloth, 2 Fine Thread, 2 Minor Healing Potion. +3 Intellect, +3 Spirit, +6 healing / +2 spell damage. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_warlock_shadow_feet_black",
        itemId = 254007,
        slot = "Feet",
        minLevel = 30,
        maxLevel = 44,
        classes = WARLOCK_CLASS,
        specs = SPEC_AFF_DEMO,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 16.18,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Black Slippers (Tailoring). Recipe in Shen'dar Village, Zephras Isle. +7 Intellect, +6 Stamina, +4 Spirit, +13 Shadow damage. Requires level 30.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_warlock_dest_feet_black",
        itemId = 254007,
        slot = "Feet",
        minLevel = 30,
        maxLevel = 39,
        classes = WARLOCK_CLASS,
        specs = SPEC_DESTRUCTION,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 12.42,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Black Slippers (Tailoring). Recipe in Shen'dar Village, Zephras Isle. +7 Intellect, +6 Stamina, +4 Spirit, +13 Shadow damage. Requires level 30.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_warlock_feet_gilded",
        itemId = 254001,
        slot = "Feet",
        minLevel = 30,
        maxLevel = 39,
        classes = WARLOCK_CLASS,
        specs = SPEC_WARLOCK_ALL,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 11.62,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Gilded Slippers (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 8 Bolt of Mageweave, 4 Heavy Silken Thread, 2 Magenta Dye, 2 Cerulean Dye. +7 Intellect, +6 Stamina, +4 Spirit, +7 spell power. Requires level 30.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_warlock_dest_feet_fiery",
        itemId = 254005,
        slot = "Feet",
        minLevel = 30,
        maxLevel = 37,
        classes = WARLOCK_CLASS,
        specs = SPEC_DESTRUCTION,
        factions = HORDE,
        curatedRank = 3,
        foreverDelta = true,
        pipelineScore = 9.17,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Fiery Slippers (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 8 Bolt of Mageweave, 4 Heavy Silken Thread, 2 Magenta Dye, 2 Cerulean Dye. +13 Fire damage is the Destruction off-school. Requires level 30.",
        zone = "Zephras Isle",
    },

    -- Forever phase-4 deltas (Horde druid). Idol fills an empty relic slot.
    -- Cloth rares are Balance/Restoration only; feral/bear keep leather.
    {
        id = "forever_horde_druid_ranged_windcharged_leaf",
        itemId = 263411,
        slot = "Ranged",
        minLevel = 1,
        maxLevel = 51,
        classes = DRUID_CLASS,
        specs = SPEC_DRUID_ALL,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 0.5,
        sourceType = "quest_reward",
        instructions = "Quest reward in Shen'dar Village on Zephras Isle. Druid idol: shapeshifting costs 40 less mana. Fills the relic slot until the Classic idols (52+).",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_druid_ranged_windcharged_leaf_late_casters",
        itemId = 263411,
        slot = "Ranged",
        minLevel = 52,
        maxLevel = 59,
        classes = DRUID_CLASS,
        specs = SPEC_BEAR_BALANCE,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 0.5,
        sourceType = "quest_reward",
        instructions = "Quest reward in Shen'dar Village on Zephras Isle. Druid idol: shapeshifting costs 40 less mana. Bear and Balance have no Classic idol until 60.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_druid_ranged_windcharged_leaf_late_resto",
        itemId = 263411,
        slot = "Ranged",
        minLevel = 52,
        maxLevel = 56,
        classes = DRUID_CLASS,
        specs = SPEC_DRUID_RESTO,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 0.5,
        sourceType = "quest_reward",
        instructions = "Quest reward in Shen'dar Village on Zephras Isle. Druid idol: shapeshifting costs 40 less mana. Restoration's first Classic idol is 57.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_druid_balance_waist_arcanist_sash",
        itemId = 253885,
        slot = "Waist",
        minLevel = 10,
        maxLevel = 19,
        classes = DRUID_CLASS,
        specs = SPEC_BALANCE,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 5.46,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Novice Arcanist's Sash (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 8 Bolt of Linen Cloth, 2 Fine Thread, 2 Minor Mana Potion. +3 Intellect, +3 Stamina, +4 spell power. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_druid_resto_waist_arcanist_sash",
        itemId = 253885,
        slot = "Waist",
        minLevel = 10,
        maxLevel = 17,
        classes = DRUID_CLASS,
        specs = SPEC_DRUID_RESTO,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 3.10,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Novice Arcanist's Sash (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 8 Bolt of Linen Cloth, 2 Fine Thread, 2 Minor Mana Potion. +3 Intellect, +3 Stamina, +4 spell power. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_druid_resto_waist_ardent_sash",
        itemId = 253887,
        slot = "Waist",
        minLevel = 10,
        maxLevel = 35,
        classes = DRUID_CLASS,
        specs = SPEC_DRUID_RESTO,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 9.33,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Novice Ardent's Sash (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 12 Bolt of Linen Cloth, 2 Fine Thread, 2 Minor Healing Potion. +3 Intellect, +3 Spirit, +6 healing / +2 spell damage. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_druid_balance_waist_ardent_sash",
        itemId = 253887,
        slot = "Waist",
        minLevel = 10,
        maxLevel = 17,
        classes = DRUID_CLASS,
        specs = SPEC_BALANCE,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 3.50,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Novice Ardent's Sash (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 12 Bolt of Linen Cloth, 2 Fine Thread, 2 Minor Healing Potion. +3 Intellect, +3 Spirit, +6 healing / +2 spell damage. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_druid_resto_feet_gilded",
        itemId = 254001,
        slot = "Feet",
        minLevel = 30,
        maxLevel = 50,
        classes = DRUID_CLASS,
        specs = SPEC_DRUID_RESTO,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 27.61,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Gilded Slippers (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 8 Bolt of Mageweave, 4 Heavy Silken Thread, 2 Magenta Dye, 2 Cerulean Dye. +7 Intellect, +6 Stamina, +4 Spirit, +20 healing / +7 spell damage. Requires level 30.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_druid_balance_feet_gilded",
        itemId = 254001,
        slot = "Feet",
        minLevel = 30,
        maxLevel = 39,
        classes = DRUID_CLASS,
        specs = SPEC_BALANCE,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 10.72,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Gilded Slippers (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 8 Bolt of Mageweave, 4 Heavy Silken Thread, 2 Magenta Dye, 2 Cerulean Dye. +7 Intellect, +6 Stamina, +4 Spirit, +7 spell power. Requires level 30.",
        zone = "Zephras Isle",
    },

    -- Forever phase-4 deltas (Horde rogue). Leather only; cloth/mail and
    -- white 2.0-dps weapons lose to Early 1-9. No 10+ notebook winner.
    {
        id = "forever_horde_rogue_chest_bandits_jerkin",
        itemId = 263421,
        slot = "Chest",
        minLevel = 1,
        maxLevel = 2,
        classes = ROGUE_CLASS,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 0.205,
        sourceType = "quest_reward",
        instructions = "Quest reward in Shen'dar Village on Zephras Isle. Leather chest, 41 armor — more than the Classic grey vests in this band.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_rogue_chest_bandits_jerkin_l3",
        itemId = 263421,
        slot = "Chest",
        minLevel = 3,
        maxLevel = 3,
        classes = ROGUE_CLASS,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 0.205,
        sourceType = "quest_reward",
        instructions = "Quest reward in Shen'dar Village on Zephras Isle. Leather chest, 41 armor. Rank 2 at 3 behind Handstitched Leather Vest.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_rogue_wrist_vuldren_hide",
        itemId = 257280,
        slot = "Wrist",
        minLevel = 1,
        maxLevel = 2,
        classes = ROGUE_CLASS,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 0.075,
        sourceType = "quest_reward",
        instructions = "Binds when picked up. Leather wrist, 15 armor — more than the Classic grey bracers in this band. Seen in Shen'dar Village on Zephras Isle.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_rogue_wrist_vuldren_hide_l3",
        itemId = 257280,
        slot = "Wrist",
        minLevel = 3,
        maxLevel = 3,
        classes = ROGUE_CLASS,
        factions = HORDE,
        curatedRank = 3,
        foreverDelta = true,
        pipelineScore = 0.075,
        sourceType = "quest_reward",
        instructions = "Binds when picked up. Leather wrist, 15 armor. Rank 3 at 3 behind the first +stat bracers.",
        zone = "Zephras Isle",
    },

    -- Forever phase-4 deltas (Horde priest). Cloth only; 1-9 has no notebook
    -- winner (armor-only whites lose to the Classic cloth list). Radiant /
    -- Fiery / Frothing / Golden slippers are the wrong school.
    {
        id = "forever_horde_priest_holy_waist_ardent_sash",
        itemId = 253887,
        slot = "Waist",
        minLevel = 10,
        maxLevel = 37,
        classes = PRIEST_CLASS,
        specs = SPEC_HOLY,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 10.27,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Novice Ardent's Sash (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 12 Bolt of Linen Cloth, 2 Fine Thread, 2 Minor Healing Potion. +3 Intellect, +3 Spirit, +6 healing / +2 spell damage. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_priest_disc_waist_ardent_sash",
        itemId = 253887,
        slot = "Waist",
        minLevel = 10,
        maxLevel = 43,
        classes = PRIEST_CLASS,
        specs = SPEC_DISC,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 10.06,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Novice Ardent's Sash (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 12 Bolt of Linen Cloth, 2 Fine Thread, 2 Minor Healing Potion. +3 Intellect, +3 Spirit, +6 healing / +2 spell damage. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_priest_heal_waist_arcanist_sash",
        itemId = 253885,
        slot = "Waist",
        minLevel = 10,
        maxLevel = 16,
        classes = PRIEST_CLASS,
        specs = SPEC_HOLY_DISC,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 3.16,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Novice Arcanist's Sash (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 8 Bolt of Linen Cloth, 2 Fine Thread, 2 Minor Mana Potion. +3 Intellect, +3 Stamina, +4 spell power. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_priest_shadow_waist_arcanist_sash",
        itemId = 253885,
        slot = "Waist",
        minLevel = 10,
        maxLevel = 19,
        classes = PRIEST_CLASS,
        specs = SPEC_SHADOW,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 5.57,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Novice Arcanist's Sash (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 8 Bolt of Linen Cloth, 2 Fine Thread, 2 Minor Mana Potion. +3 Intellect, +3 Stamina, +4 spell power. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_priest_shadow_waist_ardent_sash",
        itemId = 253887,
        slot = "Waist",
        minLevel = 10,
        maxLevel = 17,
        classes = PRIEST_CLASS,
        specs = SPEC_SHADOW,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 3.87,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Novice Ardent's Sash (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 12 Bolt of Linen Cloth, 2 Fine Thread, 2 Minor Healing Potion. +3 Intellect, +3 Spirit, +6 healing / +2 spell damage. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_priest_heal_feet_gilded",
        itemId = 254001,
        slot = "Feet",
        minLevel = 30,
        maxLevel = 50,
        classes = PRIEST_CLASS,
        specs = SPEC_HOLY_DISC,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 29.17,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Gilded Slippers (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 8 Bolt of Mageweave, 4 Heavy Silken Thread, 2 Magenta Dye, 2 Cerulean Dye. +7 Intellect, +6 Stamina, +4 Spirit, +20 healing / +7 spell damage. Requires level 30.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_priest_shadow_feet_black",
        itemId = 254007,
        slot = "Feet",
        minLevel = 30,
        maxLevel = 44,
        classes = PRIEST_CLASS,
        specs = SPEC_SHADOW,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 16.69,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Black Slippers (Tailoring). Recipe in Shen'dar Village, Zephras Isle. +7 Intellect, +6 Stamina, +4 Spirit, +13 Shadow damage. Requires level 30.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_priest_shadow_feet_gilded",
        itemId = 254001,
        slot = "Feet",
        minLevel = 30,
        maxLevel = 39,
        classes = PRIEST_CLASS,
        specs = SPEC_SHADOW,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 11.34,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Craft Gilded Slippers (Tailoring). Recipe in Shen'dar Village, Zephras Isle. 8 Bolt of Mageweave, 4 Heavy Silken Thread, 2 Magenta Dye, 2 Cerulean Dye. +7 Intellect, +6 Stamina, +4 Spirit, +7 spell power. Requires level 30.",
        zone = "Zephras Isle",
    },

    -- Forever phase-4 deltas (Horde hunter). Mail whites win 1–9 on armor;
    -- leather Jerkin/bracers still beat the grey pile. Ranged/melee whites
    -- lose to Classic bows and 2H. No caster sash. Copper boots win at 10.
    {
        id = "forever_horde_hunter_waist_skychain_belt",
        itemId = 257272,
        slot = "Waist",
        minLevel = 1,
        maxLevel = 9,
        classes = HUNTER_CLASS,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 0.19,
        sourceType = "quest_reward",
        instructions = "Quest reward in Thendal Village on Zephras Isle. Mail waist, 38 armor — more armor than the Classic grey/white belts in this band.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_hunter_feet_thendal_ranger_shoes",
        itemId = 257257,
        slot = "Feet",
        minLevel = 1,
        maxLevel = 9,
        classes = HUNTER_CLASS,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 0.23,
        sourceType = "quest_reward",
        instructions = "Quest reward in Thendal Village on Zephras Isle. Mail feet, 46 armor — beats the Classic 1–9 leather greys on armor alone.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_hunter_legs_highlands_mail",
        itemId = 263423,
        slot = "Legs",
        minLevel = 1,
        maxLevel = 4,
        classes = HUNTER_CLASS,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 0.355,
        sourceType = "quest_reward",
        instructions = "Quest reward in Shen'dar Village on Zephras Isle. Mail legs, 71 armor. Burnt Leather Breeches take over at 5.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_hunter_chest_watchers_mail",
        itemId = 263410,
        slot = "Chest",
        minLevel = 1,
        maxLevel = 4,
        classes = HUNTER_CLASS,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 0.335,
        sourceType = "quest_reward",
        instructions = "Quest reward in Thendal Village on Zephras Isle. Mail chest, 67 armor. +stat leather vests take over at 5.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_hunter_chest_bandits_jerkin",
        itemId = 263421,
        slot = "Chest",
        minLevel = 1,
        maxLevel = 2,
        classes = HUNTER_CLASS,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 0.199,
        sourceType = "quest_reward",
        instructions = "Quest reward in Shen'dar Village on Zephras Isle. Leather chest, 41 armor. Rank 2 behind Watcher's Mail Chest.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_hunter_wrist_vuldren_hide",
        itemId = 257280,
        slot = "Wrist",
        minLevel = 1,
        maxLevel = 2,
        classes = HUNTER_CLASS,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 0.073,
        sourceType = "quest_reward",
        instructions = "Binds when picked up. Leather wrist, 15 armor — more than the Classic grey bracers in this band. Seen in Shen'dar Village on Zephras Isle.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_hunter_wrist_vuldren_hide_l3",
        itemId = 257280,
        slot = "Wrist",
        minLevel = 3,
        maxLevel = 3,
        classes = HUNTER_CLASS,
        factions = HORDE,
        curatedRank = 3,
        foreverDelta = true,
        pipelineScore = 0.073,
        sourceType = "quest_reward",
        instructions = "Binds when picked up. Leather wrist, 15 armor. Rank 3 at 3 behind the first +stat bracers.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_hunter_feet_gemmed_copper",
        itemId = 250620,
        slot = "Feet",
        minLevel = 10,
        maxLevel = 10,
        classes = HUNTER_CLASS,
        specs = SPEC_HUNTER_ALL,
        factions = HORDE,
        curatedRank = 1,
        foreverDelta = true,
        pipelineScore = 1.145,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Craft Gemmed Copper Boots (Blacksmithing). Recipe in Shen'dar Village, Zephras Isle. 2 Copper Bar, 2 Malachite, 4 Light Leather. +4 Strength, +4 Stamina, 109 armor. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_hunter_feet_glowing_copper",
        itemId = 250482,
        slot = "Feet",
        minLevel = 10,
        maxLevel = 10,
        classes = HUNTER_CLASS,
        specs = SPEC_HUNTER_ALL,
        factions = HORDE,
        curatedRank = 2,
        foreverDelta = true,
        pipelineScore = 1.145,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Craft Glowing Copper Boots (Blacksmithing). Recipe in Shen'dar Village, Zephras Isle. 2 Copper Bar, 2 Light Leather. +4 Intellect, 109 armor. Requires level 10.",
        zone = "Zephras Isle",
    },
    {
        id = "forever_horde_hunter_feet_gemmed_copper_l11",
        itemId = 250620,
        slot = "Feet",
        minLevel = 11,
        maxLevel = 12,
        classes = HUNTER_CLASS,
        specs = SPEC_HUNTER_ALL,
        factions = HORDE,
        curatedRank = 3,
        foreverDelta = true,
        pipelineScore = 1.145,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Craft Gemmed Copper Boots (Blacksmithing). Recipe in Shen'dar Village, Zephras Isle. 2 Copper Bar, 2 Malachite, 4 Light Leather. +4 Strength, +4 Stamina, 109 armor. Rank 3 at 11–12 behind Agility-suffix boots.",
        zone = "Zephras Isle",
    },

    -- Forever phase-4 deltas (Horde paladin). Mail whites are close on the
    -- 0.02 armor weight. No Forever libram in the notebook (empty relic until
    -- Classic librams). Holy takes cloth sashes / Gilded; ret/prot take copper boots.
                                                        
    -- Forever phase-4 deltas (Horde warrior). Mail whites on the 0.03 armor
    -- weight. Gemmed Copper Boots for all specs; prot also keeps Strange.
    -- Cloth sashes and white weapons lose. No relic slot.
                                    
}

local SLOT_TO_INVENTORY = {
    Head = 1,
    Neck = 2,
    Shoulder = 3,
    Back = 15,
    Chest = 5,
    Shirt = 4,
    Tabard = 19,
    Wrist = 9,
    Hands = 10,
    Waist = 6,
    Legs = 7,
    Feet = 8,
    Finger0 = 11,
    Finger1 = 12,
    Trinket0 = 13,
    Trinket1 = 14,
    MainHand = 16,
    SecondaryHand = 17,
    Ranged = 18,
}

-- Log categories: both finger/trinket inventory slots share one upgrade list each.
GQ.Data.MERGED_SLOT_INVENTORY = {
    Finger = { 11, 12 },
    Trinket = { 13, 14 },
}

function GQ.Data:NormalizeSlotName(slotName)
    if slotName == "Shield" then
        return "SecondaryHand"
    end
    if slotName == "Finger0" or slotName == "Finger1" then
        return "Finger"
    end
    if slotName == "Trinket0" or slotName == "Trinket1" then
        return "Trinket"
    end
    return slotName
end

function GQ.Data:GetInventorySlots(slotName)
    slotName = self:NormalizeSlotName(slotName)
    if self.MERGED_SLOT_INVENTORY[slotName] then
        return self.MERGED_SLOT_INVENTORY[slotName]
    end

    local inv = SLOT_TO_INVENTORY[slotName]
    if inv then
        return { inv }
    end
    return {}
end

function GQ.Data:GetInventorySlot(slotName)
    local slots = self:GetInventorySlots(slotName)
    return slots[1]
end

function GQ.Data:EntryMatchesSlot(entry, slotName)
    if not entry or not entry.slot then
        return false
    end
    return self:NormalizeSlotName(entry.slot) == self:NormalizeSlotName(slotName)
end

function GQ.Data:GetCandidateSlotKeys(slotName)
    slotName = self:NormalizeSlotName(slotName)
    if slotName == "Finger" then
        return { "Finger", "Finger0", "Finger1" }
    end
    if slotName == "Trinket" then
        return { "Trinket", "Trinket0", "Trinket1" }
    end
    if slotName == "SecondaryHand" then
        return { "SecondaryHand", "Shield" }
    end
    return { slotName }
end

function GQ.Data:GetForeverAudit(itemId)
    if not itemId or not self.foreverAudit then
        return nil
    end
    return self.foreverAudit[itemId]
end

function GQ.Data:GetForeverStatus(itemId)
    local audit = self:GetForeverAudit(itemId)
    return audit and audit.status or nil
end

function GQ.Data:IsForeverMissing(itemId)
    return self:GetForeverStatus(itemId) == "missing"
end

function GQ.Data:TipHasCombatStats(tip)
    if type(tip) ~= "string" or tip == "" then
        return false
    end
    if tip:find("%+%d") then
        return true
    end
    if tip:find("Armor", 1, true) or tip:find("Damage", 1, true) then
        return true
    end
    if tip:find("Equip:", 1, true) or tip:find("Use:", 1, true) then
        return true
    end
    if tip:find("Chance on hit", 1, true) then
        return true
    end
    return false
end

function GQ.Data:HasCombatTooltipData(entry)
    if not entry then
        return false
    end
    if entry.suffixRange and entry.suffixRange ~= "" then
        return true
    end
    if entry.proc and entry.proc ~= "" then
        return true
    end
    local fact = self:GetItemFact(entry.itemId)
    if fact and fact.proc and fact.proc ~= "" then
        return true
    end
    if fact and fact.stats then
        for _, value in pairs(fact.stats) do
            if type(value) == "number" and value ~= 0 then
                return true
            end
        end
    end
    local audit = self:GetForeverAudit(entry.itemId)
    if audit and self:TipHasCombatStats(audit.tip) then
        return true
    end
    return false
end

function GQ.Data:NeedsDatamineNotice(entry)
    if not entry then
        return false
    end
    if self:IsForeverMissing(entry.itemId) then
        return false
    end
    if self:HasCombatTooltipData(entry) then
        return false
    end
    -- A live client tooltip already has stats / suffixes / effects.
    if entry.itemId and self.ItemInfoIsReady and self:ItemInfoIsReady(entry.itemId) then
        return false
    end
    return true
end

function GQ.Data:AppendDatamineNotice(tooltip, entry)
    if not tooltip or not self:NeedsDatamineNotice(entry) then
        return
    end
    tooltip:AddLine("Has not been datamined yet", 1, 0.82, 0)
end

function GQ.Data:PruneMissingForever()
    if not self.entries or not self.foreverAudit then
        return
    end

    local kept = {}
    for i = 1, #self.entries do
        local entry = self.entries[i]
        if not self:IsForeverMissing(entry and entry.itemId) then
            kept[#kept + 1] = entry
        end
    end
    self.entries = kept
end

function GQ.Data:BuildIndex()
    self:PruneMissingForever()
    self.bySlot = {}
    self.byItemId = {}
    self.byId = {}
    self.byClass = {}
    self.byClassSlot = {}
    self.byClassSlotSpec = {}
    for _, entry in ipairs(self.entries) do
        local slot = self:NormalizeSlotName(entry.slot)
        self.bySlot[slot] = self.bySlot[slot] or {}
        table.insert(self.bySlot[slot], entry)
        self.byItemId[entry.itemId] = self.byItemId[entry.itemId] or {}
        table.insert(self.byItemId[entry.itemId], entry)
        if entry.id then
            self.byId[entry.id] = entry
        end
        if entry.classes then
            for classFile in pairs(entry.classes) do
                self.byClass[classFile] = self.byClass[classFile] or {}
                table.insert(self.byClass[classFile], entry)
                self.byClassSlot[classFile] = self.byClassSlot[classFile] or {}
                self.byClassSlot[classFile][slot] = self.byClassSlot[classFile][slot] or {}
                table.insert(self.byClassSlot[classFile][slot], entry)

                self.byClassSlotSpec[classFile] = self.byClassSlotSpec[classFile] or {}
                self.byClassSlotSpec[classFile][slot] = self.byClassSlotSpec[classFile][slot] or { _any = {} }
                local specMap = self.byClassSlotSpec[classFile][slot]
                local placed = false
                if entry.specs then
                    for specName, enabled in pairs(entry.specs) do
                        if enabled then
                            specMap[specName] = specMap[specName] or {}
                            table.insert(specMap[specName], entry)
                            placed = true
                        end
                    end
                end
                if not placed then
                    table.insert(specMap._any, entry)
                end
            end
        end
    end
    self:InvalidateQueryCache()
end

function GQ.Data:GetClassSlotEntryList(slotName)
    slotName = self:NormalizeSlotName(slotName)
    local classFile = GQ:GetEffectiveClass()
    local specMap = classFile
        and self.byClassSlotSpec
        and self.byClassSlotSpec[classFile]
        and self.byClassSlotSpec[classFile][slotName]
    if specMap then
        local spec = GQ.GetEffectiveSpec and GQ:GetEffectiveSpec()
        local cacheKey = tostring(spec or "")
        if specMap._lookup and specMap._lookupKey == cacheKey then
            return specMap._lookup
        end
        local specList = spec and specMap[spec]
        local anyList = specMap._any
        local lookup
        if specList and anyList and #anyList > 0 then
            lookup = {}
            for i = 1, #specList do
                lookup[#lookup + 1] = specList[i]
            end
            for i = 1, #anyList do
                lookup[#lookup + 1] = anyList[i]
            end
        else
            lookup = specList or anyList or {}
        end
        specMap._lookup = lookup
        specMap._lookupKey = cacheKey
        return lookup
    end
    if classFile and self.byClassSlot and self.byClassSlot[classFile] then
        return self.byClassSlot[classFile][slotName]
    end
    return self.bySlot and self.bySlot[slotName]
end

function GQ.Data:GetEntriesByItemId(itemId)
    if not itemId then
        return {}
    end
    return self.byItemId and self.byItemId[itemId] or {}
end

-- Searched in this order. Names, not a table built per call: list building
-- runs this for every catalog entry. A nil table is skipped so a loaded
-- class whose facts sit after an unloaded one is still found.
local ITEM_FACT_TABLES = {
    "itemFacts",
    "warriorItemFacts",
    "hunterItemFacts",
    "druidItemFacts",
    "shamanItemFacts",
    "rogueItemFacts",
    "priestItemFacts",
    "priestEarly1to9Facts",
    "warlockItemFacts",
    "warlockEarly1to9Facts",
    "mageItemFacts",
    "mageEarly1to9Facts",
    "paladinEarly1to9Facts",
    "warriorEarly1to9Facts",
    "hunterEarly1to9Facts",
    "druidEarly1to9Facts",
    "shamanEarly1to9Facts",
    "rogueEarly1to9Facts",
}

function GQ.Data:GetItemFact(itemId)
    if not itemId then
        return nil
    end

    local numeric = tonumber(itemId)
    local alt = (numeric and numeric ~= itemId) and numeric or nil

    for i = 1, #ITEM_FACT_TABLES do
        local facts = self[ITEM_FACT_TABLES[i]]
        if facts then
            local fact = facts[itemId]
            if not fact and alt then
                fact = facts[alt]
            end
            if fact then
                return fact
            end
        end
    end

    return nil
end

function GQ.Data:NoteClientItemMissing(itemId)
    itemId = tonumber(itemId)
    if not itemId then
        return
    end
    self._clientMissing = self._clientMissing or {}
    self._clientMissing[itemId] = true
end

function GQ.Data:IsClientItemMissing(itemId)
    itemId = tonumber(itemId)
    return itemId and self._clientMissing and self._clientMissing[itemId] == true
end

function GQ.Data:RequestItemInfo(itemIdOrLink, force)
    if not itemIdOrLink then
        return
    end

    local itemId = tonumber(itemIdOrLink)
    if not itemId and type(itemIdOrLink) == "string" then
        itemId = self:ItemLinkToId(itemIdOrLink)
    end
    if GQ.Equip and GQ.Equip.RequestItemInfo and itemId then
        GQ.Equip:RequestItemInfo(itemId, force)
    end
    if force and type(itemIdOrLink) == "string" and GetItemInfo then
        GetItemInfo(itemIdOrLink)
    end
end

function GQ.Data:IsPlaceholderItemName(name, itemId)
    if type(name) ~= "string" then
        return true
    end
    name = name:match("^%s*(.-)%s*$") or ""
    if name == "" then
        return true
    end
    -- Forever's client answers GetItemInfo with "Item 23173" until the
    -- real name is in its cache. That is not a name.
    if name:find("^Item #?%d+$") then
        return true
    end
    if itemId and name == tostring(itemId) then
        return true
    end
    return false
end

function GQ.Data:GetItemDisplayName(itemId)
    if not itemId then
        return nil
    end

    local clientName = GetItemInfo and GetItemInfo(itemId)
    if clientName and not self:IsPlaceholderItemName(clientName, itemId) then
        return clientName
    end

    local fact = self:GetItemFact(itemId)
    if fact and fact.name and not self:IsPlaceholderItemName(fact.name, itemId) then
        return fact.name
    end

    local audit = self:GetForeverAudit(itemId)
    if audit and audit.name and not self:IsPlaceholderItemName(audit.name, itemId) then
        return audit.name
    end

    local prof = PROFESSION_ITEM_NAMES[itemId]
    if prof and not self:IsPlaceholderItemName(prof, itemId) then
    local clientName
    if GetItemInfo then
        local ok, name = pcall(GetItemInfo, itemId)
        if ok then
            clientName = name
        end
    end
    end

    return nil
end

function GQ.Data:GetEntryDisplayName(entry)
    if not entry then
        return nil
    end

    local base = self:GetItemDisplayName(entry.itemId) or ("Item " .. tostring(entry.itemId))
    local suffix = entry.suffix
    if suffix and suffix ~= "" then
        suffix = tostring(suffix)
        if suffix:sub(1, 1) == " " then
            return base .. suffix
        end
        return base .. " " .. suffix
    end

    return base
end

function GQ.Data:ItemNameMatchesSuffixTarget(itemName, targetName, entry)
    itemName = self:NormalizeItemName(itemName)
    targetName = self:NormalizeItemName(targetName)
    if not itemName or not targetName then
        return false
    end

    if itemName == targetName then
        return true
    end

    if entry and entry.suffix and entry.suffix ~= "" then
        local suffix = tostring(entry.suffix)
        if suffix:sub(1, 1) ~= " " then
            suffix = " " .. suffix
        end
        if itemName:sub(-#suffix) == suffix then
            return true
        end
    end

    return false
end

function GQ.Data:EntryDisplayNameReady(entry)
    if not entry or not entry.itemId then
        return false
    end

    local base = self:GetItemDisplayName(entry.itemId)
    if not base or base:find("^Item %d+$", 1) then
        return false
    end

    return true
end

function GQ.Data:SanitizeText(text)
    text = GQ.PublicText(text)
    if not text then
        return text
    end

    text = tostring(text)
    -- WoW fonts lack these glyphs and draw them as empty boxes.
    text = text:gsub("\239\191\189", "'") -- U+FFFD replacement char
    text = text:gsub("\226\128\148", "-") -- em dash
    text = text:gsub("\226\128\147", "-") -- en dash
    text = text:gsub("\226\128\146", "-") -- figure dash
    text = text:gsub("\194\183", ", ") -- middle dot
    text = text:gsub("\226\128\166", "...") -- ellipsis
    text = text:gsub("\226\128\156", "'") -- left double quote
    text = text:gsub("\226\128\157", "'") -- right double quote
    text = text:gsub("\226\128\152", "'") -- left single quote
    text = text:gsub("\226\128\153", "'") -- right single quote
    text = text:gsub("\194\160", " ")
    text = text:gsub("\147", "'") -- cp1252 left double quote
    text = text:gsub("\148", "'") -- cp1252 right double quote
    text = text:gsub("\145", "'")
    text = text:gsub("\146", "'")
    text = text:gsub("\151", "-")
    text = text:gsub("\150", "-")
    -- Wowhead quest text keeps HTML entities. &nbsp; is a space, and
    -- &lt;name&gt; is the character. Decode those before the parchment draws.
    local named = {
        nbsp = " ", ensp = " ", emsp = " ",
        amp = "&", lt = "<", gt = ">",
        quot = '"', apos = "'",
    }
    local function decodeChar(n)
        if n == 160 or n == 32 then
            return " "
        end
        if n >= 32 and n < 127 then
            return string.char(n)
        end
        return " "
    end
    for _ = 1, 2 do
        local decoded = text:gsub("&(%a+);", function(name)
            return named[name:lower()]
        end)
        decoded = decoded:gsub("&#(%d+);", function(num)
            return decodeChar(tonumber(num) or -1)
        end)
        decoded = decoded:gsub("&#[xX](%x+);", function(hex)
            return decodeChar(tonumber(hex, 16) or -1)
        end)
        if decoded == text then
            break
        end
        text = decoded
    end
    local function playerBit(token)
        token = token:lower()
        if token == "name" then
            local name = UnitName and UnitName("player")
            if type(name) == "string" and name ~= "" and not (issecretvalue and issecretvalue(name)) then
                return name
            end
            return "you"
        end
        if token == "class" then
            local classFile = GQ.GetEffectiveClass and GQ:GetEffectiveClass()
            local localized = classFile and LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[classFile]
            if type(localized) == "string" and localized ~= "" then
                return localized
            end
            local unitClass = UnitClass and UnitClass("player")
            if type(unitClass) == "string" and unitClass ~= "" then
                return unitClass
            end
            return "adventurer"
        end
        if token == "race" then
            local race = UnitRace and UnitRace("player")
            if type(race) == "string" and race ~= "" then
                return race
            end
            return "adventurer"
        end
    end
    text = text:gsub("<(%a+)>", playerBit)
    -- <sir/madam> and the same shape. 2 is male, 3 is female.
    text = text:gsub("<([^<>]-)/([^<>]-)>", function(left, right)
        local sex = UnitSex and UnitSex("player")
        if sex == 3 then
            return right
        end
        return left
    end)
    -- <Lieutenant Haggerdin salutes.> is an action, not a tag.
    text = text:gsub("<([^<>]+)>", " %1 ")
    text = text:gsub("([!?])(%u)", "%1 %2")
    -- FFFD/em-dash pairs became quote-space-quote after a bad decode.
    text = text:gsub("' '", " - ")
    text = text:gsub('" "', " - ")
    text = text:gsub(" +", " ")
    text = text:gsub(" ,", ",")
    return text
end

-- Wowhead tips were stored with HTML stripped and no line breaks, so
-- "Item Level 27Binds when equippedShoulderMail142" reads as one word.
local FOREVER_TIP_BREAKS = {
    "Item Level ",
    "Binds when ",
    "Unique%-Equipped",
    "Unique",
    "Requires Level ",
    "Requires ",
    "Classes:",
    "Sell Price",
    "Durability",
    "Dropped by:",
    "Drop Chance:",
    "Durability",
    "Restores ",
    "Equip:",
    "Use:",
    "Chance on hit:",
}

local GREEN_STAT = {
    "Spell Power", "Damage Done", "Healing Done", "Ranged Attack Power",
    "Attack Power", "Critical Strike", "Expertise", "Hit", "Haste",
    "Defense", "Dodge", "Parry", "Resistance",
}

function GQ.Data:FormatAuditTip(tip)
    tip = self:SanitizeText(tip)
    if not tip or tip == "" then
        return tip
    end
    -- Wowhead already broke the lines. Rebuilding them is what glued
    -- "Restores" to the next stat and shoved Drop Chance into the middle.
    if tip:find("\n", 1, true) then
        tip = tip:gsub("(Binds when equipped)", "%1\n")
        tip = tip:gsub("(Binds when picked up)", "%1\n")
        -- "Unique-Equipped Finger" is a slot. "Unique-Equipped: Talisman of
        -- Battle (1)" is one Wowhead line; a break there leaves the colon.
        tip = tip:gsub("(Unique%-Equipped)%s*([^:%s])", "%1\n%2")
        tip = tip:gsub("\n+", "\n")
        return tip:match("^%s*(.-)%s*$")
    end
    tip = tip:gsub("(%d)(%u)", "%1 %2")
    tip = tip:gsub("(%l)(%u)", "%1 %2")
    tip = tip:gsub("(%l)(%d)", "%1 %2")
    tip = tip:gsub("(%l)(%+)", "%1 %2")
    tip = tip:gsub("%)(%u)", ")\n%1")
    tip = tip:gsub("%.%(", ".\n(")
    tip = tip:gsub("%.(%u)", ".\n%1")
    tip = tip:gsub("(Binds when equipped)", "%1\n")
    tip = tip:gsub("(Binds when picked up)", "%1\n")
    tip = tip:gsub("(Unique)(%s)", "%1\n")
    tip = tip:gsub(" (%d+) Armor", "\n%1 Armor")
    tip = tip:gsub("(%a)(%d+) Armor", "%1\n%2 Armor")
    tip = tip:gsub("(%d+) Block", "\n%1 Block")
    -- Wowhead prints one line per bonus: "(2) Set : +10 Intellect."
    -- "Set:" and "Set :" both occur. Keep the +N on that line; the stat
    -- splitter below is for "+6 Strength+4 Stamina", not for set bonuses.
    tip = tip:gsub("(%(%d+%)%s*Set%s*:)", "\n%1")
    tip = tip:gsub("(Requires Level %d+)%s+", "%1\n")
    for _, head in ipairs(FOREVER_TIP_BREAKS) do
        tip = tip:gsub("(" .. head .. ")", "\n%1")
    end
    tip = tip:gsub("(%(%d+%)%s*Set%s*:%s*)%+(%d+)", "%1\1%2")
    tip = tip:gsub("%+(%d+)%s+", "\n+%1 ")
    tip = tip:gsub("(%(%d+%)%s*Set%s*:%s*)\1(%d+)", "%1+%2")
    tip = tip:gsub("(%(%d+%)%s*Set%s*:)%s*\n%s*(%+%d+)", "%1 %2")
    -- "Unique-EquippedFinger" is a slot on the next line. A colon stays,
    -- so "Unique-Equipped: Talisman of Battle (1)" is not split.
    tip = tip:gsub("(Unique%-Equipped)%s*([^:%s])", "%1\n%2")
    tip = tip:gsub(" +", " ")
    tip = tip:gsub("\n+", "\n")
    return tip:match("^%s*(.-)%s*$")
end

local GOLD_COIN = "|TInterface\\MoneyFrame\\UI-GoldIcon:12:12:2:0|t"
local SILVER_COIN = "|TInterface\\MoneyFrame\\UI-SilverIcon:12:12:2:0|t"
local COPPER_COIN = "|TInterface\\MoneyFrame\\UI-CopperIcon:12:12:2:0|t"

function GQ.Data:FormatSellPriceLine(line)
    local rest = line and line:match("^Sell Price:%s*(.*)$")
    if not rest or rest == "" then
        return line
    end
    local nums = {}
    for n in rest:gmatch("%d+") do
        nums[#nums + 1] = tonumber(n)
    end
    if #nums == 0 then
        return line
    end
    local gold, silver, copper = 0, 0, 0
    if #nums == 1 then
        copper = nums[1]
    elseif #nums == 2 then
        silver, copper = nums[1], nums[2]
    else
        gold, silver, copper = nums[1], nums[2], nums[3]
    end
    local amount = gold * 10000 + silver * 100 + copper
    local coin
    if GetCoinTextureString then
        coin = GetCoinTextureString(amount)
    elseif C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString then
        coin = C_CurrencyInfo.GetCoinTextureString(amount)
    end
    if coin and coin ~= "" then
        return "Sell Price: " .. coin
    end
    local parts = {}
    if gold > 0 then
        parts[#parts + 1] = gold .. GOLD_COIN
    end
    if silver > 0 or gold > 0 then
        parts[#parts + 1] = silver .. SILVER_COIN
    end
    parts[#parts + 1] = copper .. COPPER_COIN
    return "Sell Price: " .. table.concat(parts, " ")
end

local function lua_escape(s)
    return (s:gsub("(%W)", "%%%1"))
end

-- Infer the shared piece prefix from the mashed list ("Savage Gladiator Helm
-- Savage Gladiator Chain..."), not from the set title. "The Gladiator (0/6)"
-- is the Wowhead set name; splitting on "Gladiator" alone cuts every piece.
function GQ.Data:InferSetPiecePrefix(blob, total)
    if not blob or blob == "" then
        return nil
    end
    total = tonumber(total)
    local words = {}
    for w in blob:gmatch("%S+") do
        words[#words + 1] = w
    end
    local best, bestLen = nil, 0
    for len = math.min(4, #words), 1, -1 do
        local prefix = table.concat(words, " ", 1, len)
        local count = 0
        local pos = 1
        while true do
            local a, b = blob:find(prefix, pos, true)
            if not a then
                break
            end
            count = count + 1
            pos = b + 1
        end
        if count >= 2 and len > bestLen then
            best = prefix
            bestLen = len
            if total and count == total then
                return prefix
            end
        end
    end
    return best
end

-- Wowhead stores set blocks as "Cryptstalker Armor (0/9)Cryptstalker BootsCryptstalker Girdle...".
-- After camel-case spacing that is one long line; split it like the client tooltip.
function GQ.Data:SplitSetPieceNames(header, blob, total)
    local family = self:InferSetPiecePrefix(blob, total)
    if not family or family == "" then
        return blob
    end
    local out = blob
    out = out:gsub("of the " .. family, "of the\0" .. family)
    out = out:gsub(" (" .. lua_escape(family) .. ")", "\n" .. family)
    out = out:gsub("of the\0", "of the ")
    out = out:gsub(" (Ring of )", "\nRing of ")
    out = out:gsub(" (Cloak of )", "\nCloak of ")
    out = out:gsub(" (Band of )", "\nBand of ")
    out = out:gsub(" (Pendant of )", "\nPendant of ")
    out = out:gsub(" (Medallion of )", "\nMedallion of ")
    return out
end

function GQ.Data:ExpandForeverSetLines(lines)
    local out = {}
    local i = 1
    while i <= #lines do
        local line = lines[i]
        local req, rest = line:match("^(Requires Level %d+)%s+(.+)$")
        if req and rest then
            out[#out + 1] = req
            line = rest
        end
        local classesLine, afterClasses = line:match("^(Classes: [%a, ]+)%s+(.+)$")
        if classesLine and afterClasses and afterClasses:find("%(%d+/%d+%)") then
            classesLine = classesLine:gsub("%s+$", "")
            -- Keep only real class names; "Classes: Priest Vestments..." is mashed.
            local kept = {}
            for word in classesLine:gmatch("%u%l+") do
                if word == "Warrior" or word == "Paladin" or word == "Hunter"
                    or word == "Rogue" or word == "Priest" or word == "Shaman"
                    or word == "Mage" or word == "Warlock" or word == "Druid" then
                    kept[#kept + 1] = word
                end
            end
            if #kept > 0 then
                out[#out + 1] = "Classes: " .. table.concat(kept, ", ")
                line = afterClasses:match("^%s*(.-)%s*$") or afterClasses
            end
        end
        local name, worn, total, trail = line:match("^(.-)%s*%((%d+)/(%d+)%)%s*(.*)$")
        if name and total then
            out[#out + 1] = name .. " (" .. worn .. "/" .. total .. ")"
            local blob = trail
            if (not blob or blob == "") and lines[i + 1]
                and not lines[i + 1]:find("^%(%d+%) Set")
                and not lines[i + 1]:find("^Sell Price")
                and not lines[i + 1]:find("^Equip:") then
                blob = lines[i + 1]
                i = i + 1
            end
            if blob and blob ~= "" then
                local pieces = self:SplitSetPieceNames(name .. " (" .. worn .. "/" .. total .. ")", blob, total)
                for piece in string.gmatch(pieces .. "\n", "([^\n]*)\n") do
                    piece = piece:match("^%s*(.-)%s*$") or ""
                    if piece ~= "" then
                        out[#out + 1] = self:ResolveSetPieceLine(piece)
                    end
                end
            end
            i = i + 1
        else
            if line ~= "" then
                out[#out + 1] = line
            end
            i = i + 1
        end
    end
    return out
end

function GQ.Data:ForeverLineIsName(line, ...)
    if not line or line == "" then
        return false
    end
    local folded = line:lower()
    for i = 1, select("#", ...) do
        local name = select(i, ...)
        if type(name) == "string" and name ~= "" and folded == name:lower() then
            return true
        end
    end
    return false
end

function GQ.Data:ForeverTooltipLines(tip)
    local text = self:FormatAuditTip(tip)
    if not text then
        return {}
    end
    local lines = {}
    for line in string.gmatch(text .. "\n", "([^\n]*)\n") do
        line = line:match("^%s*(.-)%s*$") or ""
        if line ~= "" then
            if line:find("^Sell Price") then
                line = self:FormatSellPriceLine(line)
            end
            lines[#lines + 1] = line
        end
    end
    local merged = {}
    local i = 1
    while i <= #lines do
        local line = lines[i]
        local nxt = lines[i + 1]
        if line == "Restores" and nxt and (nxt:find("^%+%d+ mana") or nxt:find("^%+%d+ health")) then
            merged[#merged + 1] = "Restores " .. nxt
            i = i + 2
        else
            merged[#merged + 1] = line
            i = i + 1
        end
    end
    return self:SplitForeverLayoutLines(self:ExpandForeverSetLines(merged))
end

function GQ.Data:ForeverLineColor(line)
    if line:find("^Equip:") or line:find("^Use:") or line:find("^Chance on hit")
        or line:find("^Restores") or line:find("mana per 5", 1, true) then
        return 0, 1, 0
    end
    if line:find("^%+") then
        for _, label in ipairs(GREEN_STAT) do
            if line:find(label, 1, true) then
                return 0, 1, 0
            end
        end
        return 1, 1, 1
    end
    if line:find("^%(%d+%) Set") then
        return 0.5, 0.5, 0.5
    end
    if line:find("%(%d+/%d+%)$") then
        return 1, 0.82, 0.1
    end
    if line:find("^Item Level") then
        return 1, 0.82, 0.1
    end
    if line:find("^Sell Price") then
        return 1, 1, 1
    end
    if line:find("^Dropped by") or line:find("^Drop Chance") then
        return 0.62, 0.62, 0.62
    end
    return 1, 1, 1
end

function GQ.Data:IsSetHeaderLine(line)
    return type(line) == "string" and line:find("%(%d+/%d+%)%s*$")
end

-- Client tooltips put slot on the left and armor/weapon type on the right.
-- Wowhead Forever prints them on two lines ("Feet" then "Cloth") or mashes
-- them ("Shoulder Leather"). Lua patterns have no alternation, so this is a
-- lookup, not a "|" pattern.
local EQUIP_SLOTS = {
    "Held In Off-hand", "Held In Off-Hand", "One-Hand", "Two-Hand",
    "Main Hand", "Off Hand", "Shoulder", "Finger", "Trinket", "Chest",
    "Wrist", "Hands", "Waist", "Legs", "Feet", "Head", "Neck", "Back",
    "Ranged", "Thrown", "Relic",
}
local EQUIP_TYPES = {
    "Fist Weapon", "Fishing Pole", "Leather", "Cloth", "Mail", "Plate",
    "Shield", "Sword", "Dagger", "Staff", "Polearm", "Mace", "Axe",
    "Crossbow", "Wand", "Bow", "Gun", "Thrown", "Libram", "Totem", "Idol",
    "Miscellaneous",
}
local EQUIP_SLOT_SET, EQUIP_TYPE_SET = {}, {}
for _, name in ipairs(EQUIP_SLOTS) do
    EQUIP_SLOT_SET[name] = true
end
for _, name in ipairs(EQUIP_TYPES) do
    EQUIP_TYPE_SET[name] = true
end
table.sort(EQUIP_SLOTS, function(a, b)
    return #a > #b
end)

local function mashedSlotType(line)
    for _, slot in ipairs(EQUIP_SLOTS) do
        if line:sub(1, #slot) == slot then
            local rest = line:sub(#slot + 1):match("^%s*(.-)%s*$")
            if rest and rest ~= "" and EQUIP_TYPE_SET[rest] then
                return slot, rest
            end
        end
    end
end

function GQ.Data:SplitForeverLayoutLines(lines)
    local out = {}
    local i = 1
    while i <= #lines do
        local line = lines[i]
        local nxt = lines[i + 1]
        if type(line) ~= "string" then
            out[#out + 1] = line
            i = i + 1
        else
            local left, right = mashedSlotType(line)
            if left and right then
                out[#out + 1] = { left = left, right = right }
                i = i + 1
            elseif EQUIP_SLOT_SET[line] and type(nxt) == "string" and EQUIP_TYPE_SET[nxt] then
                out[#out + 1] = { left = line, right = nxt }
                i = i + 2
            else
                local dmg, spd = line:match("^(%d+ %- %d+ Damage)%s+(Speed [%d%.]+)$")
                if dmg and spd then
                    out[#out + 1] = { left = dmg, right = spd }
                    i = i + 1
                elseif line:match("^%d+ %- %d+ Damage$") and type(nxt) == "string" and nxt:match("^Speed ") then
                    out[#out + 1] = { left = line, right = nxt }
                    i = i + 2
                else
                    out[#out + 1] = line
                    i = i + 1
                end
            end
        end
    end
    return out
end

function GQ.Data:AddForeverTooltipLines(tooltip, lines, displayName, auditName)
    local setPhase
    local worn = 0
    local lastBlank = false
    local wrapWidth = 300

    local function addBlank()
        if lastBlank then
            return
        end
        tooltip:AddLine(" ")
        lastBlank = true
    end

    -- A width has to exist before wrap, or the words sit on one row.
    -- SetMinimumWidth is what gives Equip and set-bonus lines a real edge
    -- to break on, instead of chopping them into 64-character rows.
    if wrapWidth and tooltip.SetMinimumWidth then
        tooltip:SetMinimumWidth(wrapWidth)
    end

    local function addText(text, r, g, b, wrap)
        if not wrap or not text or tooltip.SetMinimumWidth then
            tooltip:AddLine(text, r, g, b, wrap and true or false)
            return
        end
        local current = ""
        for word in text:gmatch("%S+") do
            if current ~= "" and (#current + 1 + #word) > 72 then
                tooltip:AddLine(current, r, g, b, false)
                current = word
            elseif current == "" then
                current = word
            else
                current = current .. " " .. word
            end
        end
        if current ~= "" then
            tooltip:AddLine(current, r, g, b, false)
        end
    end

    for _, line in ipairs(lines) do
        if type(line) == "table" then
            tooltip:AddDoubleLine(line.left or "", line.right or "", 1, 1, 1, 1, 1, 1)
            lastBlank = false
        else
            local isHeader = self:IsSetHeaderLine(line)
            local isBonus = line:find("^%(%d+%) Set")
            local isTail = line:find("^Sell Price") or line:find("^Dropped by") or line:find("^Drop Chance")
            if isHeader then
                addBlank()
                setPhase = "pieces"
                worn = tonumber(line:match("%((%d+)/%d+%)%s*$")) or 0
            elseif isBonus then
                setPhase = "bonus"
            elseif isTail then
                if setPhase == "bonus" or setPhase == "pieces" then
                    addBlank()
                end
                setPhase = nil
            end

            -- Skip a leftover title line. Never drop the hovered piece from the set list.
            if setPhase == "pieces" or not self:ForeverLineIsName(line, displayName, auditName) then
                local text = line
                if setPhase == "pieces" and not isHeader and not text:find("^%s") then
                    text = "  " .. text
                end
                local lr, lg, lb
                if isHeader then
                    lr, lg, lb = 1, 0.82, 0.1
                elseif isBonus then
                    local need = tonumber(line:match("^%((%d+)%) Set"))
                    if need and worn >= need then
                        lr, lg, lb = 0, 1, 0
                    else
                        lr, lg, lb = 0.5, 0.5, 0.5
                    end
                elseif setPhase == "pieces" then
                    lr, lg, lb = 0.5, 0.5, 0.5
                else
                    lr, lg, lb = self:ForeverLineColor(line)
                end

                local wrap = isBonus or (not isHeader and setPhase ~= "pieces" and not isTail)
                addText(text, lr, lg, lb, wrap)
                lastBlank = false
            end
        end
    end
end

function GQ.Data:ResolveSetPieceLine(line)
    local id = line and line:match("^Item #(%d+)$")
    if not id then
        return line
    end
    id = tonumber(id)
    local name = self:GetItemDisplayName(id)
    if name then
        return name
    end
    self:RequestItemInfo(id, true)
    return line
end

function GQ.Data:ReadScannerLeftLines(scanner)
    local name = scanner and scanner.GetName and scanner:GetName()
    local out = {}
    local n = (scanner and scanner.NumLines and scanner:NumLines()) or 0
    for i = 1, n do
        local fs = name and _G[name .. "TextLeft" .. i]
        local text = GQ.PublicText(fs and fs.GetText and fs:GetText())
        if text then
            text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("^%s+", ""):gsub("%s+$", "")
        end
        if text and text ~= "" then
            out[#out + 1] = text
        end
    end
    return out
end

function GQ.Data:ParseSetBlockFromLines(lines)
    local start
    for i = 1, #lines do
        if lines[i]:find("%(%d+/%d+%)$") then
            start = i
            break
        end
    end
    if not start then
        return nil
    end
    local block = { header = lines[start], pieces = {}, bonuses = {} }
    for i = start + 1, #lines do
        local line = lines[i]
        if line:find("^Requires Level") or line:find("^Sell Price") or line:find("^Dropped")
            or line:find("^You haven") or line:find("^Press F")
            or line:find("^Item Level") or line:find("^Binds when") or line:find("^Durability") then
            break
        end
        if line:find("^Classes:") or line:find("^Item #") or self:IsSetHeaderLine(line) then
            -- Classes can sit above or below the bonuses; Item # / extra headers are not pieces.
        elseif line:find("^%(%d+%) Set") then
            block.bonuses[#block.bonuses + 1] = line
        else
            block.pieces[#block.pieces + 1] = line
        end
    end
    return block
end

function GQ.Data:ClientSetBlockIsUsable(block)
    if not block or not block.bonuses or #block.bonuses == 0 then
        return false
    end
    if block.header then
        local total = tonumber(block.header:match("%(%d+/(%d+)%)"))
        if total == 0 then
            return false
        end
    end
    local filled = 0
    for i = 1, #block.bonuses do
        local rest = block.bonuses[i]:match("^%(%d+%) Set%s*:?%s*(.*)$")
        if rest and rest:match("%S") then
            filled = filled + 1
        end
    end
    return filled > 0
end

function GQ.Data:ScannerSetLooksComplete(lines)
    for i = 1, #lines do
        if lines[i]:find("^Sell Price") or lines[i]:find("^Classes:") or lines[i]:find("^Press F") then
            return true
        end
    end
    return false
end

function GQ.Data:InvalidateClientSetBlock(itemId)
    if itemId and self._clientSetBlock then
        self._clientSetBlock[itemId] = nil
    end
end

-- Use the live client set block only when it actually has (2)/(4)/… bonuses.
-- Empty client bonuses (Savage Gladiator) stay on the Wowhead Forever piece list.
function GQ.Data:GetClientSetBlock(itemId)
    if not itemId then
        return nil, false
    end
    self._clientSetBlock = self._clientSetBlock or {}
    local cached = self._clientSetBlock[itemId]
    if cached ~= nil then
        if cached == false then
            return nil, false
        end
        return cached, false
    end

    self:RequestItemInfo(itemId, true)
    local scanner = self:GetTooltipScanner()
    scanner:SetOwner(UIParent, "ANCHOR_NONE")
    scanner:ClearLines()
    if not self:SetTooltipItem(scanner, itemId) or self:TooltipLooksRetrieving(scanner) then
        scanner:Hide()
        return nil, true
    end
    local lines = self:ReadScannerLeftLines(scanner)
    scanner:Hide()
    local block = self:ParseSetBlockFromLines(lines)
    if not block then
        if self:ScannerSetLooksComplete(lines) then
            self._clientSetBlock[itemId] = false
            return nil, false
        end
        return nil, true
    end
    if #block.bonuses > 0 and self:ClientSetBlockIsUsable(block) then
        self._clientSetBlock[itemId] = block
        return block, false
    end
    if self:ScannerSetLooksComplete(lines) then
        self._clientSetBlock[itemId] = false
        return nil, false
    end
    return nil, true
end

function GQ.Data:SetBlockEnds(line)
    return type(line) == "string" and (
        line:find("^Sell Price") or line:find("^Dropped by") or line:find("^Drop Chance")
        or line:find("^Requires Level") or line:find("^Classes:")
        or line:find("^Equip:") or line:find("^Use:") or line:find("^Chance on hit")
        or line:find("^Item Level") or line:find("^Binds") or line:find("^Durability")
        or line:find("^%+") or line:find(" Armor$")
    )
end

-- Swap in the live client set where the Wowhead set sits. Leave every other
-- line where Wowhead put it. Pulling Requires Level and Drop Chance out is
-- what parked Drop Chance between Equip and Requires Level.
function GQ.Data:ReplaceSetBlock(lines, block)
    if not block or not block.header then
        return lines
    end
    local function emitSet(out)
        out[#out + 1] = block.header
        for p = 1, #block.pieces do
            out[#out + 1] = block.pieces[p]
        end
        for b = 1, #block.bonuses do
            out[#out + 1] = block.bonuses[b]
        end
    end

    local out = {}
    local i = 1
    local replaced = false
    while i <= #lines do
        local line = lines[i]
        local start = type(line) == "string" and (
            self:IsSetHeaderLine(line) or line:find("^Item #") or line:find("^%(%d+%) Set"))
        if start and not replaced then
            emitSet(out)
            replaced = true
            i = i + 1
            while i <= #lines do
                local nxt = lines[i]
                if type(nxt) ~= "string" or self:SetBlockEnds(nxt) then
                    break
                end
                i = i + 1
            end
        else
            out[#out + 1] = line
            i = i + 1
        end
    end
    if replaced then
        return out
    end

    local inserted = {}
    local did = false
    for n = 1, #lines do
        local line = lines[n]
        if not did and self:SetBlockEnds(line) and (
            line:find("^Sell Price") or line:find("^Dropped by") or line:find("^Drop Chance")) then
            emitSet(inserted)
            did = true
        end
        inserted[#inserted + 1] = line
    end
    if not did then
        emitSet(inserted)
    end
    return inserted
end

function GQ.Data:LinesHaveSetHeader(lines)
    for i = 1, #lines do
        if self:IsSetHeaderLine(lines[i]) then
            return true
        end
    end
    return false
end

function GQ.Data:TipLinesHaveSetBonus(lines)
    for i = 1, #lines do
        local line = lines[i]
        if type(line) == "string" and line:find("^%(%d+%) Set") then
            return true
        end
    end
    return false
end

function GQ.Data:ApplyClientSetBlock(lines, block)
    if not block or not block.bonuses or #block.bonuses == 0 then
        return lines
    end
    local pieces = {}
    for i = 1, #(block.pieces or {}) do
        local piece = block.pieces[i]
        if piece and piece ~= "" and not piece:find("^Item #") and not self:IsSetHeaderLine(piece) then
            pieces[#pieces + 1] = piece
        end
    end
    return self:ReplaceSetBlock(lines, {
        header = block.header,
        pieces = pieces,
        bonuses = block.bonuses,
    })
end

-- Imbued result items. Printed stats stay the normal colors. Only the effect
-- the scroll adds is grey. Do not repeat that effect from entry.proc.
-- In its place: "Use: Combine the <base weapon> and <scroll>."
-- Add a row here and imbueBase / imbueScroll on the client override when
-- another weapon is made the same way.
local CLIENT_IMBUE = {
    [276631] = {
        scroll = "Imbue Blade",
        base = "Blade of Silverlaine",
        effect = {
            "Melee attacks deal",
            "against Frozen",
        },
    },
}

function GQ.Data:HideImbueScrollTooltip()
    if self._imbueTip then
        self._imbueTip:Hide()
    end
end

function GQ.Data:ShowImbueScrollTooltip(owner, info)
    if not owner or not info or not info.scroll then
        return
    end
    if not self._imbueTip then
        self._imbueTip = CreateFrame("GameTooltip", "GearQuestImbueTooltip", UIParent, "GameTooltipTemplate")
    end
    local tip = self._imbueTip
    tip:SetOwner(owner, "ANCHOR_NONE")
    tip:ClearAllPoints()
    tip:SetPoint("LEFT", owner, "RIGHT", 8, 0)
    tip:SetText(info.scroll, 0.75, 0.75, 0.75)
    tip:Show()
end

function GQ.Data:ImbueInfo(itemId)
    return CLIENT_IMBUE[itemId]
end

function GQ.Data:ImbueCombineLine(info)
    if not info or not info.base or info.base == "" or not info.scroll or info.scroll == "" then
        return nil
    end
    return "Use: Combine the " .. info.base .. " and " .. info.scroll .. "."
end

function GQ.Data:LineIsImbued(text, info)
    if not text or not info or not info.effect then
        return false
    end
    for i = 1, #info.effect do
        if text:find(info.effect[i], 1, true) then
            return true
        end
    end
    return false
end

function GQ.Data:TooltipAlreadySays(tooltip, text)
    if not tooltip or not text or text == "" or not tooltip.NumLines or not tooltip.GetName then
        return false
    end
    local name = tooltip:GetName()
    if not name then
        return false
    end
    local function norm(value)
        value = tostring(value or "")
        value = value:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        value = value:gsub("%s+", " ")
        if strtrim then
            value = strtrim(value)
        end
        return value:lower()
    end
    local needle = norm(text)
    if needle == "" then
        return false
    end
    local body = needle:match("^[^:]+:%s*(.+)$")
    if not body or #body < 12 then
        body = nil
    end
    for i = 1, tooltip:NumLines() do
        local fs = _G[name .. "TextLeft" .. i]
        local line = fs and fs.GetText and fs:GetText()
        if line and line ~= "" then
            local hay = norm(line)
            if hay == needle or (hay ~= "" and hay:find(needle, 1, true)) or (body and hay:find(body, 1, true)) then
                return true
            end
        end
    end
    return false
end

function GQ.Data:AppendImbueOrProc(tooltip, entry)
    if not tooltip or not entry then
        return
    end
    local info = self:ImbueInfo(entry.itemId)
    if info then
        local line = self:ImbueCombineLine(info)
        if line and not self:TooltipAlreadySays(tooltip, line) then
            tooltip:AddLine(" ")
            tooltip:AddLine(line, 0, 1, 0, true)
        end
        return
    end
    if entry.proc and entry.proc ~= "" and not self:TooltipAlreadySays(tooltip, entry.proc) then
        tooltip:AddLine(" ")
        tooltip:AddLine(entry.proc, 1, 1, 1, true)
    end
end

function GQ.Data:ApplyImbueTooltipLines(tooltip, itemId)
    self:HideImbueScrollTooltip()
    local pool = tooltip and tooltip.gqImbueButtons
    if pool then
        for i = 1, #pool do
            pool[i]:Hide()
        end
    end
    local info = CLIENT_IMBUE[itemId]
    if not info or not tooltip or not tooltip.NumLines or not tooltip.GetName then
        return
    end
    local name = tooltip:GetName()
    if not name then
        return
    end
    if not self._imbueHooked and GameTooltip and GameTooltip.HookScript then
        GameTooltip:HookScript("OnHide", function()
            GQ.Data:HideImbueScrollTooltip()
        end)
        self._imbueHooked = true
    end
    pool = tooltip.gqImbueButtons or {}
    tooltip.gqImbueButtons = pool
    local used = 0
    local n = tooltip:NumLines() or 0
    for i = 1, n do
        local fs = _G[name .. "TextLeft" .. i]
        local text = fs and fs.GetText and fs:GetText()
        if text and self:LineIsImbued(text, info) then
            fs:SetTextColor(0.55, 0.55, 0.55)
            used = used + 1
            local btn = pool[used]
            if not btn then
                btn = CreateFrame("Button", nil, tooltip)
                btn:SetScript("OnEnter", function(self)
                    GQ.Data:ShowImbueScrollTooltip(self, self.gqImbue)
                end)
                btn:SetScript("OnLeave", function()
                    GQ.Data:HideImbueScrollTooltip()
                end)
                pool[used] = btn
            end
            btn.gqImbue = info
            btn:ClearAllPoints()
            btn:SetAllPoints(fs)
            btn:SetFrameLevel((tooltip:GetFrameLevel() or 0) + 20)
            btn:Show()
        end
    end
end

-- Paint the Wowhead Forever tooltip. The client still shows Classic Equip:
-- "Increases damage and healing done by up to N" for items that Wowhead
-- already prints as +N Spell Power / Damage Done / Healing Done.
function GQ.Data:ShowForeverItemTooltip(tooltip, entry)
    if not tooltip or not entry then
        return false
    end
    local audit = self:GetForeverAudit(entry.itemId)
    if not audit or not audit.tip or audit.tip == "" then
        return false
    end

    local displayName = self:GetEntryDisplayName(entry) or audit.name or ("Item " .. tostring(entry.itemId))
    local quality = self:GetItemQualityForDisplay(entry.itemId)
    local r, g, b = 1, 0.82, 0
    local c = ITEM_QUALITY_COLORS and quality and ITEM_QUALITY_COLORS[quality]
    if c then
        r, g, b = c.r, c.g, c.b
    elseif quality then
        r, g, b = GetItemQualityColor(quality)
    end

    tooltip:ClearLines()
    tooltip:SetText(displayName, r, g, b)

    if audit.status == "missing" then
        tooltip:AddLine("Not found on Wowhead Forever", 1, 0.2, 0.2)
    end

    local lines = self:ForeverTooltipLines(audit.tip)
    -- Wowhead already listed the bonuses. The client block was moving
    -- Requires Level and Drop Chance out of that order.
    local clientSet, setPending
    if not self:TipLinesHaveSetBonus(lines) then
        clientSet, setPending = self:GetClientSetBlock(entry.itemId)
        if clientSet and clientSet.bonuses and #clientSet.bonuses > 0 then
            lines = self:ApplyClientSetBlock(lines, clientSet)
        end
    end
    self._pendingClientSet = setPending and self:LinesHaveSetHeader(lines)
    self:AddForeverTooltipLines(tooltip, lines, displayName, audit.name)

    self:AppendImbueOrProc(tooltip, entry)
    self:AppendSuffixRangeLines(tooltip, entry)
    local suffixHint = self:GetSuffixHint(entry)
    if suffixHint then
        tooltip:AddLine(" ")
        tooltip:AddLine("Target random enchant: " .. suffixHint, 0.7, 0.9, 1)
    end
    self:AppendDatamineNotice(tooltip, entry)
    self:ApplyImbueTooltipLines(tooltip, entry.itemId)
    return true
end

function GQ.Data:GetSuffixHint(entry)
    if not entry or not entry.suffix then
        return nil
    end

    local parts = { entry.suffix }
    if entry.suffixRange and entry.suffixRange ~= "" then
        parts[#parts + 1] = entry.suffixRange
    elseif entry.suffixId then
        parts[#parts + 1] = "tier " .. tostring(entry.suffixId)
    end

    local hint = table.concat(parts, ", ")
    if entry.suffixChance then
        hint = hint .. " (slim ~" .. tostring(entry.suffixChance) .. "% roll -- BiS if you get it)"
    end

    return hint
end

-- Novelty on-use effects (fall damage/speed, drunk, party-only buffs, etc.) are not
-- real upgrades for the level band — hide them from picks and notables.
local NOVELTY_PROC_PATTERNS = {
    "fall speed",
    "fall damage",
    "slow fall",
    "safe fall",
    "parachute",
    "gets you quite drunk",
    "unless it explodes",
    "turns the target into a chicken",
    "look far into the distance",
    "nearby party members",
    "party members within",
    "summons the truesilver boar",
}

function GQ.Data:GetEntryProcText(entry)
    if not entry then
        return nil
    end

    if entry.proc and entry.proc ~= "" then
        return entry.proc
    end

    local facts = self.itemFacts
    if facts and entry.itemId then
        local fact = facts[entry.itemId]
        if fact and fact.proc and fact.proc ~= "" then
            return fact.proc
        end
    end

    return nil
end

function GQ.Data:IsNoveltyProcItem(entry)
    local proc = self:GetEntryProcText(entry)
    if not proc then
        return false
    end

    local lower = string.lower(tostring(proc))
    for i = 1, #NOVELTY_PROC_PATTERNS do
        if lower:find(NOVELTY_PROC_PATTERNS[i], 1, true) then
            return true
        end
    end

    return false
end

-- Ranged weapons whose DPS/procs only matter for Hunters (pull-slot filler for others).
GQ.Data.HUNTER_ONLY_RANGED_ITEMS = {
    [2825] = true, -- Bow of Searing Arrows
}

function GQ.Data:IsHunterOnlyRangedItem(entry)
    if not entry or not entry.itemId then
        return false
    end
    return self.HUNTER_ONLY_RANGED_ITEMS[entry.itemId] == true
end

-- Melee attack-speed on-use (not spell haste) — bear/feral only for druids.
GQ.Data.DRUID_MELEE_HASTE_ITEMS = {
    [9449] = true, -- Manual Crowd Pummeler
}

function GQ.Data:IsDruidMeleeHasteForCaster(entry)
    if not entry or not entry.itemId then
        return false
    end
    if not self.DRUID_MELEE_HASTE_ITEMS[entry.itemId] then
        return false
    end
    if not entry.specs then
        return false
    end
    return entry.specs.balance or entry.specs.restoration
end

-- Rune Broker relics are sold by different NPCs per faction (ingest_forever_wowhead.py).
-- Generated itemFacts are keyed by itemId only, so Alliance broker copy must not
-- gate Horde lists at display time until the next re-score removes bad rows.
GQ.Data.RUNE_BROKER_ALLIANCE = {
    [205420] = true, [208849] = true, [208851] = true, [211472] = true,
}
GQ.Data.RUNE_BROKER_HORDE = {
    [206381] = true, [206382] = true, [206386] = true, [206387] = true,
    [206388] = true, [225838] = true,
}
GQ.Data.RUNE_BROKER_INSTRUCTIONS = {
    Alliance = "Bought from Rune Broker in Stormwind, Ironforge, Darnassus, Elwynn Forest, Dun Morogh, and Teldrassil.",
    Horde = "Bought from Rune Broker in Orgrimmar, Thunder Bluff, Undercity, Durotar, Mulgore, and Tirisfal Glades.",
    Both = "Bought from Rune Broker in Stormwind, Ironforge, Darnassus, Elwynn Forest, Dun Morogh, and Teldrassil, "
        .. "and in Orgrimmar, Thunder Bluff, Undercity, Durotar, Mulgore, and Tirisfal Glades.",
}

-- One-faction maps (mirrors pipeline ALLIANCE_MAPS / HORDE_MAPS). A pin in the
-- other faction's city is never shown, even when the spot was tagged wrong.
GQ.Data.FACTION_ZONE_DENY = {
    Alliance = {
        ["Valley of Trials"] = true, ["Durotar"] = true, ["Razor Hill"] = true, ["Orgrimmar"] = true,
        ["Mulgore"] = true, ["Camp Narache"] = true, ["Thunder Bluff"] = true, ["Deathknell"] = true,
        ["Tirisfal Glades"] = true, ["Brill"] = true, ["Undercity"] = true,
        ["Silverpine Forest"] = true, ["The Barrens"] = true, ["Camp Mojache"] = true,
    },
    Horde = {
        ["Northshire Valley"] = true, ["Elwynn Forest"] = true, ["Dun Morogh"] = true,
        ["Coldridge Valley"] = true, ["Kharanos"] = true, ["Teldrassil"] = true, ["Shadowglen"] = true,
        ["Darnassus"] = true, ["Ironforge"] = true, ["Stormwind City"] = true, ["Loch Modan"] = true,
        ["Westfall"] = true, ["Darkshore"] = true, ["Redridge Mountains"] = true, ["Duskwood"] = true,
    },
}

-- A dungeon door, a boss, a rare, or a farm is the place itself. Wailing
-- Caverns is in the Barrens and both factions walk in, so that pin is not
-- a Horde leveling pin. Quest starts and city vendors stay on the deny list.
function GQ.Data:PinIgnoresFactionZone(row)
    local note = row and row.note
    if note == "where this rare spawns"
        or note == "a farming spot"
        or note == "entrance to dungeon or raid"
        or note == "where this boss spawns"
        or note == "one of the spots to farm it" then
        return true
    end
    -- Ratchet sits on the Barrens map, and both factions shop there. A row
    -- whose pins are all untagged and all on that one map is the shop.
    -- Darkmoon Faire keeps one pin in Elwynn and one in Mulgore, so the
    -- map list still shows each faction its own faire.
    if note == "vendor that sells this" or note == "vendor that sells the recipe" then
        local spots = row.spots
        if not spots or #spots == 0 then
            return false
        end
        local map = spots[1].map
        for i = 1, #spots do
            local spot = spots[i]
            if (spot.faction and spot.faction ~= "") or spot.map ~= map then
                return false
            end
        end
        return true
    end
    return false
end

function GQ.Data:SpotVisible(spot, faction, ignoreMapDeny)
    if not spot then
        return false
    end
    if not ignoreMapDeny then
        local deny = faction and self.FACTION_ZONE_DENY[faction]
        if deny and spot.map and deny[spot.map] then
            return false
        end
    end
    if spot.faction and spot.faction ~= "" and faction and spot.faction ~= faction then
        return false
    end
    return true
end

-- On-use AOE / novelty trinkets that are not real stat upgrades for leveling BiS.
GQ.Data.EXCLUDED_ITEMS = {
    [13515] = true, -- Ramstein's Lightning Bolts
}

function GQ.Data:IsExcludedItem(entry)
    if not entry or not entry.itemId then
        return false
    end
    return self.EXCLUDED_ITEMS[entry.itemId] == true
end

function GQ.Data:EntryMatchesPlayerFaction(entry)
    if not entry then
        return false
    end

    local faction = GQ:GetEffectiveFaction()
    if entry.factions and not entry.factions[faction] then
        return false
    end

    local itemId = entry.itemId
    if faction == "Horde" and itemId and self.RUNE_BROKER_ALLIANCE[itemId] then
        return false
    end
    if faction == "Alliance" and itemId and self.RUNE_BROKER_HORDE[itemId] then
        return false
    end

    -- Open-world rares stay listed for both factions. The patrol may sit in
    -- the other side's leveling zone (Rohh the Silent, Redridge Mountains).
    -- A generic world drop names no creature. The catalog zone is one example,
    -- so Westfall does not hide Frayed Cloak from Horde. A named creature stays
    -- in the zone it actually lives in.
    local zone = entry.zone
    local genericDrop = entry.sourceType == "world_drop"
        and (not entry.npc or entry.npc == "")
        and type(entry.instructions) == "string"
        and entry.instructions:sub(1, 10) == "World drop"
    if not genericDrop and not entry.zoneOpen and entry.sourceType ~= "rare_npc" and zone and self.FACTION_ZONE_DENY[faction] and self.FACTION_ZONE_DENY[faction][zone] then
        return false
    end

    local locked = self.questFaction and entry.itemId and self.questFaction[entry.itemId]
    if locked and locked ~= faction then
        return false
    end

    -- A quest whose every pin is the other faction's city is not this side's quest.
    if entry.sourceType == "quest_reward" and entry.itemId and self.coordinates then
        local row = self.coordinates[entry.itemId]
        if row and row.spots and #row.spots > 0 then
            local any = false
            for i = 1, #row.spots do
                if self:SpotVisible(row.spots[i], faction) then
                    any = true
                    break
                end
            end
            if not any then
                return false
            end
        end
    end

    return true
end

function GQ.Data:GetEntryInstructions(entry)
    if not entry then
        return nil
    end

    local text = entry.instructions
    local itemId = entry.itemId
    if itemId and (self.RUNE_BROKER_ALLIANCE[itemId] or self.RUNE_BROKER_HORDE[itemId]) then
        local faction = GQ:GetEffectiveFaction()
        if self.RUNE_BROKER_ALLIANCE[itemId] and self.RUNE_BROKER_HORDE[itemId] then
            text = self.RUNE_BROKER_INSTRUCTIONS.Both
        elseif faction == "Horde" and self.RUNE_BROKER_HORDE[itemId] then
            text = self.RUNE_BROKER_INSTRUCTIONS.Horde
        else
            text = self.RUNE_BROKER_INSTRUCTIONS.Alliance
        end
    end

    return text
end

-- The stored line names one seller. The pin is the closest seller, so the
-- description names that person. A later sentence, such as the honor cost, stays.
function GQ.Data:VendorBoughtLine(entry)
    if not entry or entry.sourceType ~= "vendor" then
        return nil
    end
    local spot = self.NearestCoordinateSpot and self:NearestCoordinateSpot(entry.itemId)
    local npc = spot and spot.npc
    if type(npc) ~= "string" or npc == "" then
        return nil
    end
    local text = self:GetEntryInstructions(entry) or entry.instructions or ""
    local note = " (be aware that some vendors sell items at random)"
    local rest = text:match("^Bought from .-%.%s*(.*)$")
    if rest ~= nil then
        if rest ~= "" then
            return "Bought from " .. npc .. "." .. note .. " " .. rest
        end
        return "Bought from " .. npc .. "." .. note
    end
    -- "Bought from " is 12 characters. A line with no period still names this seller.
    if text == "" or text:sub(1, 12) == "Bought from " then
        return "Bought from " .. npc .. "." .. note
    end
    return nil
end

function GQ.Data:HuntIconCount(count, texture)
    return tostring(count) .. "|T" .. texture .. ":0:0:2:0|t"
end

-- The number sits beside the same coin used in the money frame. Zero
-- denominations are left out, the same way the game writes a price.
function GQ.Data:CoinIcons(copper)
    copper = math.floor(tonumber(copper) or 0)
    if copper <= 0 then
        return nil
    end
    if GetCoinTextureString then
        local text = GetCoinTextureString(copper)
        if type(text) == "string" and text ~= "" then
            return (text:gsub("^%s+", ""):gsub("%s+$", ""))
        end
    end
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local rest = copper % 100
    local parts = {}
    if gold > 0 then
        parts[#parts + 1] = self:HuntIconCount(gold, "Interface\\MoneyFrame\\UI-GoldIcon")
    end
    if silver > 0 then
        parts[#parts + 1] = self:HuntIconCount(silver, "Interface\\MoneyFrame\\UI-SilverIcon")
    end
    if rest > 0 or #parts == 0 then
        parts[#parts + 1] = self:HuntIconCount(rest, "Interface\\MoneyFrame\\UI-CopperIcon")
    end
    return table.concat(parts, " ")
end

function GQ.Data:StripGenericVendorCost(text)
    if type(text) ~= "string" or text == "" then
        return text
    end
    local cleaned = text
    cleaned = cleaned:gsub("%s*Costs Honor Points and tokens %(Marks of Honor%)%.?", "")
    cleaned = cleaned:gsub("%s*%-?%s*[Cc]osts tokens or reputation%.?", "")
    cleaned = cleaned:gsub("%s%s+", " ")
    cleaned = cleaned:gsub("%s+%.", ".")
    cleaned = cleaned:gsub("^%s+", ""):gsub("%s+$", "")
    if cleaned == "" then
        return nil
    end
    return cleaned
end

-- copper is the in-game money price. honor is honor points. tokens are
-- {count, icon} pairs, icon without the Interface\\Icons\\ prefix.
function GQ.Data:VendorCostLine(entry)
    local row = self.vendorCost and entry and entry.itemId and self.vendorCost[entry.itemId]
    if type(row) ~= "table" then
        return nil
    end
    local copper = row.copper
    if type(row.sellers) == "table" then
        local spot = self.NearestCoordinateSpot and entry.itemId and self:NearestCoordinateSpot(entry.itemId)
        local npc = spot and spot.npc
        if type(npc) == "string" and row.sellers[npc] then
            copper = row.sellers[npc]
        end
    end
    local parts = {}
    local coins = self:CoinIcons(copper)
    if coins then
        parts[#parts + 1] = coins
    end
    local honor = tonumber(row.honor)
    if honor and honor > 0 then
        local faction = GQ.GetEffectiveFaction and GQ:GetEffectiveFaction()
        local texture = faction == "Horde"
            and "Interface\\PVPFrame\\PVP-Currency-Horde"
            or "Interface\\PVPFrame\\PVP-Currency-Alliance"
        parts[#parts + 1] = self:HuntIconCount(math.floor(honor), texture)
    end
    if type(row.tokens) == "table" then
        for i = 1, #row.tokens do
            local token = row.tokens[i]
            local count = token and tonumber(token[1])
            local icon = token and token[2]
            if count and count > 0 and type(icon) == "string" and icon ~= "" then
                parts[#parts + 1] = self:HuntIconCount(math.floor(count), "Interface\\Icons\\" .. icon)
            end
        end
    end
    if #parts == 0 then
        return nil
    end
    return "Costs " .. table.concat(parts, " ") .. "."
end

local PVP_RANK_TITLES = {
    { "Lieutenant Commander's", "Lieutenant Commander (Rank 10)" },
    { "Lieutenant General's", "Lieutenant General (Rank 11)" },
    { "Knight-Lieutenant's", "Knight-Lieutenant (Rank 7)" },
    { "Knight-Captain's", "Knight-Captain (Rank 8)" },
    { "Knight-Champion's", "Knight-Champion (Rank 9)" },
    { "Senior Sergeant's", "Senior Sergeant (Rank 4)" },
    { "Master Sergeant's", "Master Sergeant (Rank 4)" },
    { "Sergeant Major's", "Sergeant Major (Rank 5)" },
    { "First Sergeant's", "First Sergeant (Rank 5)" },
    { "Field Marshal's", "Field Marshal (Rank 13)" },
    { "Grand Marshal's", "Grand Marshal (Rank 14)" },
    { "Stone Guard's", "Stone Guard (Rank 6)" },
    { "High Warlord's", "High Warlord (Rank 14)" },
    { "Blood Guard's", "Blood Guard (Rank 7)" },
    { "Legionnaire's", "Legionnaire (Rank 8)" },
    { "Centurion's", "Centurion (Rank 9)" },
    { "Champion's", "Champion (Rank 10)" },
    { "Warlord's", "Warlord (Rank 13)" },
    { "Marshal's", "Marshal (Rank 12)" },
    { "Commander's", "Commander (Rank 11)" },
    { "General's", "General (Rank 12)" },
    { "Private's", "Private (Rank 1)" },
    { "Corporal's", "Corporal (Rank 2)" },
    { "Sergeant's", "Sergeant (Rank 3)" },
    { "Knight's", "Knight (Rank 6)" },
    { "Scout's", "Scout (Rank 1)" },
    { "Grunt's", "Grunt (Rank 2)" },
}

function GQ.Data:PvpRankLabel(name)
    if type(name) ~= "string" or name == "" then
        return nil
    end
    local bare = name
    if bare:sub(1, 8) == "Premier " then
        bare = bare:sub(9)
    end
    for i = 1, #PVP_RANK_TITLES do
        local prefix = PVP_RANK_TITLES[i][1]
        if bare:sub(1, #prefix) == prefix then
            return PVP_RANK_TITLES[i][2]
        end
    end
    if name:sub(1, 20) == "Insignia of the Horde" then
        return "Grunt (Rank 2)"
    end
    if name:sub(1, 23) == "Insignia of the Alliance" then
        return "Corporal (Rank 2)"
    end
    return nil
end

function GQ.Data:AccessLine(entry)
    if not entry then
        return nil
    end
    local src = entry.sourceType
    local dropLike = src == "boss_drop" or src == "raid_trash" or src == "world_drop" or src == "rare_npc"
    local questLike = src == "quest_reward"
    if not dropLike and not questLike then
        return nil
    end
    local function onyxiaLine()
        local faction = GQ.GetEffectiveFaction and GQ:GetEffectiveFaction()
        if faction == "Horde" then
            return "Onyxia's Lair requires the Drakefire Amulet. That chain ends with Blood of the Black Dragon Champion."
        end
        return "Onyxia's Lair requires the Drakefire Amulet. That chain ends with Drakefire Amulet."
    end
    local function dalaranLine()
        local faction = GQ.GetEffectiveFaction and GQ:GetEffectiveFaction()
        if faction == "Horde" then
            return "City of Dalaran has an attunement. Start with Key to the City from Magus Wordeen Voidglare in Tarren Mill. Heart of Disruption awards the Dalaran Sewer Key for the entrance on the northwest side of the city. One person in the group needs it. Defeating Shade of the Archmage and finishing Shrewd Negotiations makes the city guards neutral. Most citizens still will not offer their services."
        end
        return "City of Dalaran has an attunement. Pick up An Alarming Request from Emissary Jacques at the Southshore Town Hall in Hillsbrad Foothills. The Alliance entrance is in front of the city in Alterac Mountains. Image of Archmage Modera teleports you in, and the dungeon pipe is inside at Cantrips & Crows. The outside sewer on the northwest shore is the Horde entrance."
    end
    local function accessFor(name)
        if name == "Onyxia's Lair" then
            return onyxiaLine()
        end
        if name == "City of Dalaran" then
            return dalaranLine()
        end
        return nil
    end
    local function textHas(text, needle)
        return type(text) == "string" and text:find(needle, 1, true) ~= nil
    end
    local function entersDalaran()
        if entry.zone == "City of Dalaran" then
            return true
        end
        if entry.questName == "Heart of Disruption" or textHas(entry.questName, "City of Dalaran") then
            return true
        end
        if textHas(entry.instructions, "City of Dalaran") or textHas(entry.instructions, "Heart of Disruption") then
            return true
        end
        local steps = self.QuestChainSteps and self:QuestChainSteps(entry)
        if steps then
            for i = 1, #steps do
                local step = steps[i]
                local name = type(step) == "table" and step[2]
                if name == "Heart of Disruption" or textHas(name, "City of Dalaran") then
                    return true
                end
            end
        end
        return false
    end
    if dropLike then
        local line = accessFor(entry.zone)
        if line then
            return line
        end
        local row = self.coordinates and entry.itemId and self.coordinates[entry.itemId]
        if row and row.spots then
            for i = 1, #row.spots do
                line = accessFor(row.spots[i] and row.spots[i].map)
                if line then
                    return line
                end
            end
        end
    end
    if entersDalaran() then
        return dalaranLine()
    end
    return nil
end

function GQ.Data:QuestChainSteps(entry)
    local row = self.questChain and entry and entry.itemId and self.questChain[entry.itemId]
    if type(row) ~= "table" then
        return nil
    end
    local function usable(steps)
        local first = type(steps) == "table" and steps[1]
        return type(steps) == "table" and #steps >= 2
            and type(first) == "table" and type(first[2]) == "string" and first[2] ~= ""
    end
    if row.Alliance or row.Horde then
        local faction = GQ.GetEffectiveFaction and GQ:GetEffectiveFaction()
        local picked = faction and row[faction]
        if not usable(picked) then
            picked = row.Alliance or row.Horde
        end
        if usable(picked) then
            return picked
        end
        return nil
    end
    if usable(row) then
        return row
    end
    if type(row[1]) == "table" and (row[1].Alliance or row[1].Horde or type(row[1][1]) == "string") then
        local faction = GQ.GetEffectiveFaction and GQ:GetEffectiveFaction()
        local fallback
        for i = 1, #row do
            local chain = row[i]
            local side = chain[1]
            local steps = chain[2]
            if type(side) == "string" and usable(steps) then
                if faction and side == faction then
                    return steps
                end
                if side == "" and not fallback then
                    fallback = steps
                end
                local last = steps[#steps]
                local lastName = type(last) == "table" and last[2]
                if entry.questName and lastName == entry.questName then
                    return steps
                end
            end
        end
        return fallback
    end
    return nil
end

function GQ.Data:QuestChainLines(entry)
    local steps = self.questChain and entry and entry.itemId and self.questChain[entry.itemId]
    if type(steps) ~= "number" then
        return nil, nil
    end
    if steps < 2 then
        if steps == 1 then
            return "No prequests. You can pick this quest up without finishing another quest first.", nil
        end
        return nil, nil
    end
    return "Part of a quest chain.", string.format("%d quests until you get this.", math.floor(steps))
end

function GQ.Data:VisibleCoordinateSpots(itemId)
    local row = self.coordinates and itemId and self.coordinates[itemId]
    if not row or not row.spots or #row.spots == 0 then
        return nil, nil
    end
    local faction = GQ.GetEffectiveFaction and GQ:GetEffectiveFaction() or nil
    local openWorld = self:PinIgnoresFactionZone(row)
    local mine = {}
    for i = 1, #row.spots do
        local spot = row.spots[i]
        if self:SpotVisible(spot, faction, openWorld) then
            mine[#mine + 1] = spot
        end
    end
    if #mine == 0 then
        return nil, row
    end
    return mine, row
end

function GQ.Data:SpotMapId(spot)
    if not spot then
        return nil
    end
    if spot.mapId then
        return spot.mapId
    end
    if spot.map and GQ.Map and GQ.Map.ZoneMap then
        return GQ.Map:ZoneMap(spot.map)
    end
    return nil
end

local function WorldXY(world)
    if type(world) ~= "table" then
        return nil
    end
    if world.GetXY then
        local x, y = world:GetXY()
        if type(x) == "number" and type(y) == "number" then
            return x, y
        end
    end
    if type(world.x) == "number" and type(world.y) == "number" then
        return world.x, world.y
    end
    return nil
end

function GQ.Data:MapVector(x, y)
    if not CreateVector2D then
        return nil
    end
    local vec = self._mapVector
    if not vec then
        vec = CreateVector2D(x or 0, y or 0)
        self._mapVector = vec
        return vec
    end
    if vec.SetXY then
        vec:SetXY(x or 0, y or 0)
    else
        vec.x = x or 0
        vec.y = y or 0
    end
    return vec
end

function GQ.Data:PlayerWorld()
    local now = GetTime and GetTime() or 0
    if self._playerWorldAt and (now - self._playerWorldAt) < 0.4 then
        return self._playerWorld or nil
    end
    self._playerWorldAt = now
    self._playerWorld = nil
    if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition and CreateVector2D) then
        return nil
    end
    local mapId = C_Map.GetBestMapForUnit("player")
    local pos = mapId and C_Map.GetPlayerMapPosition(mapId, "player")
    if not mapId or not pos or not pos.GetXY then
        return nil
    end
    local px, py = pos:GetXY()
    if not px or not py or (px == 0 and py == 0) then
        return nil
    end
    local here = { mapId = mapId, x = px * 100, y = py * 100 }
    if C_Map.GetWorldPosFromMapPos then
        local vec = self:MapVector(px, py)
        local ok, continent, world = vec and pcall(C_Map.GetWorldPosFromMapPos, mapId, vec)
        local wx, wy = ok and WorldXY(world) or nil
        if ok and continent and wx and wy then
            here.continent = continent
            here.wx = wx
            here.wy = wy
        end
    end
    self._playerWorld = here
    return here
end

function GQ.Data:SpotWorld(spot)
    local mapId = self:SpotMapId(spot)
    if not mapId or not spot.x or not spot.y or not (C_Map and C_Map.GetWorldPosFromMapPos and CreateVector2D) then
        return nil
    end
    self._spotWorld = self._spotWorld or {}
    local key = mapId .. ":" .. tostring(spot.x) .. ":" .. tostring(spot.y)
    local cached = self._spotWorld[key]
    if cached then
        return cached
    end
    local vec = self:MapVector(spot.x / 100, spot.y / 100)
    local ok, continent, world = vec and pcall(C_Map.GetWorldPosFromMapPos, mapId, vec)
    local wx, wy = ok and WorldXY(world) or nil
    if not (continent and wx and wy) then
        return nil
    end
    local row = { continent = continent, x = wx, y = wy, mapId = mapId }
    self._spotWorld[key] = row
    return row
end

-- Squared yards when both spots share a continent. Same-map fallback uses
-- zone coordinates, which are only comparable on that one map.
function GQ.Data:SpotDistance(spot, player)
    if not spot or not player then
        return nil
    end
    local world = self:SpotWorld(spot)
    if world and player.continent and world.continent == player.continent and player.wx and player.wy then
        local dx = world.x - player.wx
        local dy = world.y - player.wy
        return dx * dx + dy * dy
    end
    local mapId = self:SpotMapId(spot)
    if mapId and mapId == player.mapId and spot.x and spot.y and player.x and player.y then
        local dx = spot.x - player.x
        local dy = spot.y - player.y
        return dx * dx + dy * dy
    end
    return nil
end

local function SameCoordinateSpot(a, b)
    return a and b and a.map == b.map and a.x == b.x and a.y == b.y and a.faction == b.faction
end

function GQ.Data:SortedCoordinateSpots(itemId)
    local spots = self:VisibleCoordinateSpots(itemId)
    if not spots then
        return nil
    end
    if #spots < 2 then
        return spots
    end
    local player = self:PlayerWorld()
    if not player then
        return spots
    end
    local dist = {}
    for i = 1, #spots do
        dist[spots[i]] = self:SpotDistance(spots[i], player)
    end
    table.sort(spots, function(a, b)
        local da = dist[a]
        local db = dist[b]
        if da and db and da ~= db then
            return da < db
        end
        if da and not db then
            return true
        end
        if db and not da then
            return false
        end
        return false
    end)
    -- Keep the last shown spot until another is clearly closer, so a camp of
    -- spawn points does not swap the line on every step.
    self._nearestChoice = self._nearestChoice or {}
    local prev = self._nearestChoice[itemId]
    local best = spots[1]
    if prev and best and not SameCoordinateSpot(prev, best) then
        local dPrev, dBest
        for i = 1, #spots do
            if SameCoordinateSpot(spots[i], prev) then
                dPrev = dist[spots[i]]
                break
            end
        end
        dBest = dist[best]
        if dPrev and dBest and (math.sqrt(dPrev) - math.sqrt(dBest)) < 20 then
            local held
            local rest = {}
            for i = 1, #spots do
                if not held and SameCoordinateSpot(spots[i], prev) then
                    held = spots[i]
                else
                    rest[#rest + 1] = spots[i]
                end
            end
            if held then
                spots = { held }
                for i = 1, #rest do
                    spots[#spots + 1] = rest[i]
                end
            end
        end
    end
    self._nearestChoice[itemId] = spots[1]
    return spots
end

function GQ.Data:NearestCoordinateSpot(itemId)
    local spots = self:SortedCoordinateSpots(itemId)
    if not spots or #spots == 0 then
        return nil
    end
    return spots[1], spots
end

function GQ.Data:CoordinateLine(itemId)
    local spot, spots = self:NearestCoordinateSpot(itemId)
    if not spot then
        return nil
    end
    local row = self.coordinates and self.coordinates[itemId]
    local line = string.format("Coordinates: %s %.1f, %.1f", spot.map or "", spot.x or 0, spot.y or 0)
    if row and row.note and row.note ~= "" then
        line = line .. " (" .. row.note .. ")"
    end
    return line, spots
end

-- The checks below read only the entry, static generated data, class and
-- faction; never level. A ding rebuilds every slot, so remember the answer
-- per entry. EnsureClassLoaded clears it when class tips arrive.
function GQ.Data:ShouldShowEntry(entry)
    if not entry then
        return false
    end
    local classFile = GQ:GetEffectiveClass()
    local faction = GQ:GetEffectiveFaction()
    local memo = self._showEntryMemo
    if not memo or memo.class ~= classFile or memo.faction ~= faction then
        memo = { class = classFile, faction = faction, results = setmetatable({}, { __mode = "k" }) }
        self._showEntryMemo = memo
    end
    local cached = memo.results[entry]
    if cached == nil then
        cached = self:ComputeShouldShowEntry(entry)
        memo.results[entry] = cached
    end
    return cached
end

function GQ.Data:ComputeShouldShowEntry(entry)
    if not entry or self:IsNoveltyProcItem(entry) or self:IsExcludedItem(entry) then
        return false
    end

    if self:IsHunterOnlyRangedItem(entry) and GQ:GetEffectiveClass() ~= "HUNTER" then
        return false
    end

    if self:IsDruidMeleeHasteForCaster(entry) then
        return false
    end

    if not self:EntryMatchesPlayerClass(entry) then
        return false
    end

    if not self:EntryMatchesPlayerFaction(entry) then
        return false
    end

    return true
end

GQ.Data.TIP_CLASS_NAMES = {
    Warrior = "WARRIOR", Paladin = "PALADIN", Hunter = "HUNTER",
    Rogue = "ROGUE", Priest = "PRIEST", Shaman = "SHAMAN",
    Mage = "MAGE", Warlock = "WARLOCK", Druid = "DRUID",
}

-- Longest first. Forever remakes often omit Classes: on a piece (Deathmist Robe).
GQ.Data.CLASS_SET_PREFIX = {
    {"beaststalker", "HUNTER"}, {"giantstalker", "HUNTER"}, {"dragonstalker", "HUNTER"},
    {"cryptstalker", "HUNTER"}, {"beastmaster", "HUNTER"},
    {"predator", "HUNTER"}, {"striker", "HUNTER"},
    {"deathmist", "WARLOCK"}, {"dreadmist", "WARLOCK"}, {"plagueheart", "WARLOCK"},
    {"felheart", "WARLOCK"}, {"demoniac", "WARLOCK"}, {"doomcaller", "WARLOCK"},
    {"nemesis", "WARLOCK"},
    {"netherwind", "MAGE"}, {"frostfire", "MAGE"}, {"illusionist", "MAGE"},
    {"sorcerer", "MAGE"}, {"arcanist", "MAGE"}, {"magister", "MAGE"}, {"enigma", "MAGE"},
    {"transcendence", "PRIEST"}, {"confessor", "PRIEST"}, {"prophecy", "PRIEST"},
    {"virtuous", "PRIEST"}, {"devout", "PRIEST"},
    {"nightslayer", "ROGUE"}, {"shadowcraft", "ROGUE"}, {"darkmantle", "ROGUE"},
    {"bonescythe", "ROGUE"}, {"deathdealer", "ROGUE"}, {"bloodfang", "ROGUE"},
    {"madcap", "ROGUE"},
    {"feralheart", "DRUID"}, {"dreamwalker", "DRUID"}, {"wildheart", "DRUID"},
    {"cenarion", "DRUID"}, {"stormrage", "DRUID"}, {"haruspex", "DRUID"},
    {"genesis", "DRUID"},
    {"lawbringer", "PALADIN"}, {"lightforge", "PALADIN"}, {"soulforge", "PALADIN"},
    {"freethinker", "PALADIN"}, {"redemption", "PALADIN"}, {"judgement", "PALADIN"},
    {"judgment", "PALADIN"}, {"avenger", "PALADIN"},
    {"earthshatter", "SHAMAN"}, {"stormcaller", "SHAMAN"}, {"earthfury", "SHAMAN"},
    {"augur", "SHAMAN"},
    {"dreadnaught", "WARRIOR"}, {"vindicator", "WARRIOR"}, {"conqueror", "WARRIOR"},
}

GQ.Data.CLASS_SET_SUFFIX = {
    {" of the gathering storm", "SHAMAN"},
    {" of the earthshatterer", "SHAMAN"},
    {" of the five thunders", "SHAMAN"},
    {" of the ten storms", "SHAMAN"},
    {" of the unseen path", "HUNTER"},
    {" of the oracle", "PRIEST"},
    {" of elements", "SHAMAN"},
    {" of heroism", "WARRIOR"},
    {" of valor", "WARRIOR"},
    {" of faith", "PRIEST"},
    {" of might", "WARRIOR"},
    {" of wrath", "WARRIOR"},
}

function GQ.Data:SetFamilyClass(name)
    if not name or name == "" then
        return nil
    end
    local cache = self._setFamilyCache
    if not cache then
        cache = {}
        self._setFamilyCache = cache
    end
    if cache[name] ~= nil then
        return cache[name] or nil
    end
    local lower = name:lower()
    local found
    for i = 1, #self.CLASS_SET_PREFIX do
        local row = self.CLASS_SET_PREFIX[i]
        if lower:sub(1, #row[1]) == row[1] then
            found = row[2]
            break
        end
    end
    if not found then
        for i = 1, #self.CLASS_SET_SUFFIX do
            local row = self.CLASS_SET_SUFFIX[i]
            if lower:sub(-#row[1]) == row[1] then
                found = row[2]
                break
            end
        end
    end
    cache[name] = found or false
    return found
end

function GQ.Data:TipRequiredClasses(tip)
    if not tip or tip == "" then
        return nil
    end
    local pos = tip:find("Classes:", 1, true)
    if not pos then
        return nil
    end
    local after = tip:sub(pos + 8)
    local found = {}
    for word in after:gmatch("(%u%l+)") do
        local token = self.TIP_CLASS_NAMES[word]
        if not token then
            break
        end
        found[#found + 1] = token
    end
    if #found == 0 then
        return nil
    end
    return found
end

function GQ.Data:EntryMatchesPlayerClass(entry)
    if not entry or not entry.itemId then
        return true
    end
    local classFile = GQ:GetEffectiveClass()
    if not classFile then
        return true
    end
    -- The same item is one row per level band and suffix. The set class does
    -- not change between those rows, so the string scan runs once per item.
    local cache = self._classMatchCache
    if not cache then
        cache = {}
        self._classMatchCache = cache
    end
    local itemCache = cache[entry.itemId]
    if itemCache and itemCache[classFile] ~= nil then
        return itemCache[classFile]
    end
    local audit = self:GetForeverAudit(entry.itemId)
    local named = audit and audit.name
    if named == nil and entry.itemId then
        local fact = self:GetItemFact(entry.itemId)
        named = (fact and fact.name) or entry.name
    end
    local family = self:SetFamilyClass(named)
    local required = family and { family } or self:TipRequiredClasses(audit and audit.tip)
    local ok = true
    if required then
        ok = false
        for i = 1, #required do
            if required[i] == classFile then
                ok = true
                break
            end
        end
    end
    if not itemCache then
        itemCache = {}
        cache[entry.itemId] = itemCache
    end
    itemCache[classFile] = ok
    return ok
end

function GQ.Data:GetTooltipScanner()
    if not self._tooltipScanner then
        self._tooltipScanner = CreateFrame("GameTooltip", "GearQuestTooltipScanner", UIParent, "GameTooltipTemplate")
    end
    return self._tooltipScanner
end

-- Craft skill from item tooltip ("Leatherworking (260)"), not equip level req.
local function StripTooltipText(text)
    text = GQ.PublicText(text)
    if not text then
        return ""
    end
    return text
        :gsub("|c%x%x%x%x%x%x%x%x", "")
        :gsub("|r", "")
        :gsub("|A:.-|a", "")
        :gsub("|T.-|t", "")
        :gsub("^%s+", "")
        :gsub("%s+$", "")
end

function GQ.Data:InvalidateCraftSkillCache(itemId)
    if not itemId or not self._craftSkillCache then
        return
    end
    self._craftSkillCache[itemId] = nil
end

-- BRD Chest of The Seven: boss reward chest after the Seven encounter, not a random world container.
local BOSS_CHEST_SEVEN = {
    sourceType = "boss_drop",
    instructions = "Drops from the Chest of The Seven after defeating the Seven in Blackrock Depths.",
    zone = "Blackrock Depths",
    npc = "The Seven",
}
GQ.Data.BOSS_CHEST_SOURCES = {
    [11921] = BOSS_CHEST_SEVEN,
    [11923] = BOSS_CHEST_SEVEN,
    [11925] = BOSS_CHEST_SEVEN,
    [11926] = BOSS_CHEST_SEVEN,
    [11927] = BOSS_CHEST_SEVEN,
    [11929] = BOSS_CHEST_SEVEN,
    [11945] = BOSS_CHEST_SEVEN,
    [11946] = BOSS_CHEST_SEVEN,
}

function GQ.Data:EnrichBossChestEntry(entry)
    if not entry or not entry.itemId then
        return entry
    end

    local override = self.BOSS_CHEST_SOURCES and self.BOSS_CHEST_SOURCES[entry.itemId]
    if not override then
        return entry
    end

    entry.sourceType = override.sourceType
    entry.instructions = override.instructions
    entry.zone = override.zone
    entry.npc = override.npc
    return entry
end

function GQ.Data:CacheTradeSkillRecipes()
    if not GetNumTradeSkills or not GetTradeSkillInfo or not GetTradeSkillItemLink then
        return
    end

    self._craftSkillCache = self._craftSkillCache or {}
    local num = GetNumTradeSkills()
    for i = 1, num do
        local _, skillType, _, _, skillLevel = GetTradeSkillInfo(i)
        if skillType ~= "header" and skillLevel and skillLevel > 0 then
            local link = GetTradeSkillItemLink(i)
            local itemId = link and self:ItemLinkToId(link)
            if itemId then
                self._craftSkillCache[itemId] = skillLevel
            end
        end
    end
end

function GQ.Data:CraftSkillFromText(text, profession)
    if not text or text == "" then
        return nil
    end
    if profession then
        local skill = tonumber(text:match(profession .. "%s*%((%d+)%)"))
        if skill and skill > 0 then
            return skill
        end
        skill = tonumber(text:match("requires skill (%d+)"))
        if skill and skill > 0 and text:find(profession, 1, true) then
            return skill
        end
    end
    local skill = tonumber(text:match("requires skill (%d+)"))
    if skill and skill > 0 then
        return skill
    end
    return nil
end

function GQ.Data:LookupProfessionCraftSkill(itemId, profession)
    if not itemId then
        return nil
    end

    if GQ.CraftSkills and GQ.CraftSkills[itemId] and GQ.CraftSkills[itemId].skill then
        return GQ.CraftSkills[itemId].skill
    end

    self._craftSkillCache = self._craftSkillCache or {}
    local cached = self._craftSkillCache[itemId]
    if cached == false then
        return nil
    end
    if cached and cached > 0 then
        return cached
    end

    local audit = self:GetForeverAudit(itemId)
    local craftSkill = self:CraftSkillFromText(audit and audit.tip, profession)
    if craftSkill and craftSkill > 0 then
        self._craftSkillCache[itemId] = craftSkill
        return craftSkill
    end

    -- Item tooltips do not include recipe skill. Do not SetHyperlink-scan here:
    -- LoadGenerated used to do that for every profession row and hit
    -- "script ran too long".
    self._craftSkillCache[itemId] = false
    return nil
end

function GQ.Data:ProfessionMaterialsLine(entry)
    if not entry or not entry.itemId or not GQ.CraftSkills then
        return nil
    end
    local known = GQ.CraftSkills[entry.itemId]
    if not known then
        return nil
    end

    local function formatReagentList(rows)
        if not rows or #rows == 0 then
            return nil
        end
        local parts = {}
        for i = 1, #rows do
            local row = rows[i]
            local name = row and row[3]
            local count = row and row[2] or 1
            if name and name ~= "" then
                parts[#parts + 1] = string.format("%s (%d)", name, count)
            end
        end
        if #parts == 0 then
            return nil
        end
        return table.concat(parts, ", ")
    end

    local required = formatReagentList(known.reagents)
    if not required then
        return nil
    end
    local line = "Materials: " .. required .. "."
    local optional = formatReagentList(known.optional)
    if optional then
        line = line .. " Optional: " .. optional .. "."
    end
    return line
end

function GQ.Data:GetProfessionInstructions(entry)
    if not entry or entry.sourceType ~= "profession" then
        return entry and entry.instructions
    end

    -- The skill lives on the line before Source. Drop the older
    -- "Crafted with … (requires skill N)." sentence, and keep anything after it.
    local rest
    local instructions = entry.instructions or ""
    local after = instructions:match("^[Cc]rafted with [^.]*%.%s*(.*)$")
    if after ~= nil then
        if after:find("%S") then
            rest = after:gsub("^%s+", ""):gsub("%s+$", "")
        end
    elseif instructions:find("%S") then
        rest = instructions
    end

    local materials = self:ProfessionMaterialsLine(entry)
    if materials and rest then
        return materials .. "\n" .. rest
    end
    return materials or rest or ""
end

-- A boss, trash, or world drop that is also a craft is the pattern. The
-- finished piece is made afterwards. Vendor recipes and trainer recipes
-- stay on their own sources.
function GQ.Data:PatternDropCraft(entry)
    if not entry or not entry.itemId then
        return nil, nil
    end
    local src = entry.sourceType
    if src ~= "boss_drop" and src ~= "raid_trash" and src ~= "world_drop"
        and src ~= "rare_npc" and src ~= "object_drop" then
        return nil, nil
    end
    local known = GQ.CraftSkills and GQ.CraftSkills[entry.itemId]
    if not known or not known.profession or not known.skill or known.skill <= 0 then
        return nil, nil
    end
    return known.profession, known.skill
end

function GQ.Data:ProfessionCraftRequirement(entry)
    if not entry or entry.sourceType ~= "profession" then
        return nil, nil
    end
    local profession = entry.profession
    local known = GQ.CraftSkills and entry.itemId and GQ.CraftSkills[entry.itemId]
    if known and known.skill and known.skill > 0 then
        return known.profession or profession, known.skill
    end
    local skill = self:CraftSkillFromText(entry.instructions, profession)
    if not skill or skill <= 1 then
        skill = nil
        if entry.reqSkills then
            for i = 1, #entry.reqSkills do
                local row = entry.reqSkills[i]
                local rank = row and row[2]
                if rank and rank > 1 and (not profession or not row[1] or row[1] == profession) then
                    skill = rank
                    profession = profession or row[1]
                    break
                end
            end
        end
    end
    if not profession or not skill or skill <= 0 then
        return nil, nil
    end
    return profession, skill
end

function GQ.Data:EnsureProfessionCraftSkillListener()
    if self._professionCraftSkillListener then
        return
    end

    local frame = CreateFrame("Frame")
    GQ.RegisterEvent(frame, "GET_ITEM_INFO_RECEIVED")
    frame:SetScript("OnEvent", function(_, _, itemId)
        if not itemId then
            return
        end

        GQ.Data:InvalidateCraftSkillCache(itemId)

        if GQ.Log and GQ.Log.frame and GQ.Log.frame:IsShown() then
            local entry = GQ.Log.selectedEntry
            if entry and entry.sourceType == "profession" and entry.itemId == itemId then
                if GQ.Equip and GQ.Equip.IsBindOnPickup and GQ.Equip:IsBindOnPickup(itemId) then
                    GQ.Data:EnrichProfessionEntry(entry)
                    GQ.Log:ApplyEntryDetail(entry)
                end
            end
        end
    end)
    self._professionCraftSkillListener = frame
end

function GQ.Data:EnrichProfessionEntry(entry)
    if not entry or entry.sourceType ~= "profession" then
        return entry
    end
    -- Leave entry.instructions alone. The parchment strips the old skill
    -- sentence at display time, and the stored sentence is still the
    -- fallback when CraftSkills has no rank.
    return entry
end

function GQ.Data:CacheOwnedSuffixItemLink(entry, link)
    if not entry or not link then
        return
    end

    local key = self:EntryListKey(entry)
    if not key then
        return
    end

    self._ownedSuffixLinks = self._ownedSuffixLinks or {}
    self._ownedSuffixLinks[key] = link
end

function GQ.Data:GetCachedSuffixItemLink(entry)
    if not entry then
        return nil
    end

    local key = self:EntryListKey(entry)
    if not key then
        return nil
    end

    if self._ownedSuffixLinks and self._ownedSuffixLinks[key] then
        return self._ownedSuffixLinks[key]
    end

    return nil
end

function GQ.Data:FindCachedItemLink(entry)
    if not entry or not entry.itemId then
        return nil
    end

    local cached = self:GetCachedSuffixItemLink(entry)
    if cached then
        return cached
    end

    local function checkLink(link)
        if not link or self:ItemLinkToId(link) ~= entry.itemId then
            return nil
        end

        if entry.suffix and entry.suffix ~= "" then
            if not self:EntrySuffixMatchesLink(entry, link) then
                return nil
            end
        end

        self:CacheOwnedSuffixItemLink(entry, link)
        return link
    end

    for invSlot = 1, 19 do
        local link = checkLink(GetInventoryItemLink("player", invSlot))
        if link then
            return link
        end
    end

    local numBags = NUM_BAG_SLOTS or 4
    for bag = 0, numBags do
        local numSlots
        if C_Container and C_Container.GetContainerNumSlots then
            numSlots = C_Container.GetContainerNumSlots(bag) or 0
        elseif GetContainerNumSlots then
            numSlots = GetContainerNumSlots(bag) or 0
        else
            numSlots = 0
        end

        for slot = 1, numSlots do
            local link
            if C_Container and C_Container.GetContainerItemLink then
                link = C_Container.GetContainerItemLink(bag, slot)
            elseif GetContainerItemLink then
                link = GetContainerItemLink(bag, slot)
            end

            link = checkLink(link)
            if link then
                return link
            end
        end
    end

    return nil
end

function GQ.Data:ExtractItemStringFromHyperlink(hyperlink)
    if not hyperlink or hyperlink == "" then
        return nil
    end

    local itemString = hyperlink:match("|H(item:[^|]+)|h")
    if itemString then
        return itemString
    end

    if hyperlink:match("^item:") then
        return hyperlink
    end

    return nil
end

function GQ.Data:SuffixIdFromLink(link)
    if not link then
        return nil
    end

    local itemString = self:ExtractItemStringFromHyperlink(link)
    if not itemString and link:match("^item:") then
        itemString = link
    end
    if not itemString then
        return nil
    end

    -- suffixId sits after enchant and the four gem fields. Take that one
    -- field only. select() would hand the rest of the link to tonumber,
    -- and an empty field (Sorcerer Collar, any unsuffixed piece) errors.
    local suffixField = itemString:match("^item:%d*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:([^:]*)")
    local id = tonumber(suffixField)
    if id and id ~= 0 then
        return id
    end
    return nil
end

function GQ.Data:ParseSuffixIdFromItemString(itemString)
    if not itemString then
        return nil
    end

    return tonumber(itemString:match("^item:%d+:0:0:0:0:0:(%-?%d+):"))
end

function GQ.Data:GetSuffixLinkLevel(entry)
    local fallback = GQ.MAX_PLAYER_LEVEL or 60
    if not entry then
        return fallback
    end

    if GetItemInfo and entry.itemId then
        local _, _, _, iLevel, reqLevel = GetItemInfo(entry.itemId)
        if iLevel and iLevel > 0 then
            return iLevel
        end
        if reqLevel and reqLevel > 0 then
            return reqLevel
        end
    end

    if entry.minLevel and entry.minLevel > 0 then
        return entry.minLevel
    end

    return fallback
end

-- Random enchant tooltips and completion use pipeline suffixId only.
-- Positive field-7 id = ItemRandomProperties (fixed tier lookup).
-- Negative field-7 id = ItemRandomSuffix (ilvl-scaled; factor in field 8).
function GQ.Data:MakeSuffixTargetLink(entry)
    if not entry or not entry.itemId then
        return nil
    end

    if not entry.suffixId or entry.suffixId == 0 then
        return nil
    end

    if entry.suffixId < 0 then
        local factor = entry.suffixFactor or self:GetSuffixLinkLevel(entry)
        return string.format("item:%d:0:0:0:0:0:%d:%d:0", entry.itemId, entry.suffixId, factor)
    end

    return string.format("item:%d:0:0:0:0:0:%d:0:0", entry.itemId, entry.suffixId)
end

function GQ.Data:EntrySuffixMatchesLink(entry, link)
    if not entry or not link then
        return false
    end

    if self:ItemLinkToId(link) ~= entry.itemId then
        return false
    end

    if not entry.suffix or entry.suffix == "" then
        return true
    end

    -- The full green name is the hunt. "of the Bear" is not "of the Falcon",
    -- even though both share the base item id. A higher suffix id is a
    -- different enchant, not a better roll of this one.
    local fullName = self:ItemLinkFullName(link)
    local target = self:GetEntryDisplayName(entry)
    if fullName and target and not self:IsPlaceholderItemName(target, entry.itemId) then
        return fullName:lower() == self:NormalizeItemName(target):lower()
    end

    local rolledId = self:SuffixIdFromLink(link)
    if entry.suffixId and entry.suffixId ~= 0 and rolledId then
        return rolledId == entry.suffixId
    end

    return false
end

function GQ.Data:ResolveSuffixItemLink(entry)
    if not entry or not entry.suffix or entry.suffix == "" or not entry.itemId then
        return nil
    end

    self:EnrichEntrySuffix(entry)
    return self:MakeSuffixTargetLink(entry)
end

function GQ.Data:FormatSuffixRangeText(text)
    text = self:NormalizeItemName(text)
    if not text or text == "" then
        return nil
    end

    -- Pipeline keys first (longest match), then leftover "sp".
    text = text:gsub("spNature", "Nature Spell Power")
    text = text:gsub("spFire", "Fire Spell Power")
    text = text:gsub("spFrost", "Frost Spell Power")
    text = text:gsub("spShadow", "Shadow Spell Power")
    text = text:gsub("spArcane", "Arcane Spell Power")
    text = text:gsub("spHoly", "Holy Spell Power")
    text = text:gsub("(%d)%s+sp%f[%A]", "%1 Spell Power")
    return text
end

function GQ.Data:AppendSuffixRangeLines(tooltip, entry)
    if not tooltip or not entry or not entry.suffixRange or entry.suffixRange == "" then
        return
    end

    for part in string.gmatch(entry.suffixRange, "[^,]+") do
        local text = self:FormatSuffixRangeText(part)
        if text and text ~= "" then
            tooltip:AddLine(text, 0, 1, 0)
        end
    end
end

-- Forever often answers SetHyperlink(item:...:suffixId) with the BASE green
-- (name + armor only). The hunt text already has the roll; the tooltip must too.
function GQ.Data:TooltipShowsEntrySuffix(tooltip, entry)
    if not tooltip or not entry or not entry.suffix or entry.suffix == "" then
        return false
    end

    local name = tooltip.GetName and tooltip:GetName()
    local fs = name and _G[name .. "TextLeft1"]
    local title = GQ.PublicText(fs and fs.GetText and fs:GetText())
    if not title or title == "" then
        return false
    end

    local suffix = tostring(entry.suffix):gsub("^%s+", "")
    return title:lower():find(suffix:lower(), 1, true) ~= nil
end

function GQ.Data:GetItemQualityForDisplay(itemId)
    if not itemId then
        return nil
    end
    -- Forever quality wins (Reinforced Woolen Shoulders is green on Wowhead,
    -- but stale items.json still says common/white).
    local audit = self:GetForeverAudit(itemId)
    if audit and type(audit.quality) == "number" then
        return audit.quality
    end
    local quality = GQ.Equip and GQ.Equip.GetKnownItemQuality and GQ.Equip:GetKnownItemQuality(itemId)
    if type(quality) == "number" then
        return quality
    end
    local fact = self:GetItemFact(itemId)
    if fact and type(fact.quality) == "number" then
        return fact.quality
    end
    return nil
end

function GQ.Data:ShowLoadingItemTooltip(tooltip, entry)
    self:ShowFactFallbackTooltip(tooltip, entry)
end

function GQ.Data:ShowFactFallbackTooltip(tooltip, entry)
    if not tooltip or not entry then
        return
    end

    local displayName = self:GetEntryDisplayName(entry) or ("Item " .. tostring(entry.itemId))
    local quality = self:GetItemQualityForDisplay(entry.itemId)
    local r, g, b = 1, 0.82, 0
    local c = ITEM_QUALITY_COLORS and quality and ITEM_QUALITY_COLORS[quality]
    if c then
        r, g, b = c.r, c.g, c.b
    elseif quality then
        r, g, b = GetItemQualityColor(quality)
    end

    tooltip:ClearLines()
    tooltip:SetText(displayName, r, g, b)

    local fact = self:GetItemFact(entry.itemId)
    local audit = self:GetForeverAudit(entry.itemId)
    if audit and audit.status == "missing" then
        tooltip:AddLine("Not found on Wowhead Forever", 1, 0.2, 0.2)
    end
    if audit and audit.tip and audit.tip ~= "" then
        local lines = self:ForeverTooltipLines(audit.tip)
        if not self:TipLinesHaveSetBonus(lines) then
            local clientSet = self:GetClientSetBlock(entry.itemId)
            if clientSet and clientSet.bonuses and #clientSet.bonuses > 0 then
                lines = self:ApplyClientSetBlock(lines, clientSet)
            end
        end
        self:AddForeverTooltipLines(tooltip, lines, displayName, audit.name)
    else
        if entry.slot then
            tooltip:AddLine(entry.slot, 1, 1, 1)
        end
        if fact and fact.kind then
            tooltip:AddLine(fact.kind, 0.8, 0.8, 0.8)
        end
        local reqLevel = fact and fact.reqLevel
        if reqLevel and reqLevel > 0 then
            tooltip:AddLine("Requires Level " .. tostring(reqLevel), 1, 1, 1)
        end
        if fact and fact.stats then
            for stat, value in pairs(fact.stats) do
                if type(value) == "number" and value ~= 0 then
                    tooltip:AddLine(string.format("+%s %s", tostring(value), tostring(stat)), 0, 1, 0)
                end
            end
        end
        local instructions = self:GetEntryInstructions(entry) or (fact and fact.instructions)
        if instructions and instructions ~= "" then
            instructions = self:SanitizeText(instructions) or instructions
            tooltip:AddLine(" ")
            tooltip:AddLine(instructions, 0.8, 0.8, 0.8, true)
        end
    end
    self:AppendImbueOrProc(tooltip, entry)
    self:AppendSuffixRangeLines(tooltip, entry)
    self:AppendDatamineNotice(tooltip, entry)
end

function GQ.Data:ItemInfoIsReady(itemIdOrLink)
    if not itemIdOrLink or not GetItemInfo then
        return false
    end

    local itemId = tonumber(itemIdOrLink)
    if not itemId and type(itemIdOrLink) == "string" then
        itemId = self:ItemLinkToId(itemIdOrLink)
    end

    local cached = itemId and GQ.Equip and GQ.Equip.IsItemDataCached and GQ.Equip:IsItemDataCached(itemId)
    local name, _, quality = GetItemInfo(itemIdOrLink)
    if (not name or name == "") and itemId then
        name, _, quality = GetItemInfo(itemId)
    end
    if not name or name == "" then
        return false
    end
    if cached then
        return true
    end
    -- Stub GetItemInfo often returns quality 0 until the tooltip payload arrives.
    return type(quality) == "number" and quality > 0
end

function GQ.Data:TooltipLooksRetrieving(tooltip)
    if not tooltip then
        return false
    end

    local retrieving = RETRIEVING_ITEM_INFO or "Retrieving item information"
    local name = tooltip.GetName and tooltip:GetName()
    local lineCount = (tooltip.NumLines and tooltip:NumLines()) or 0
    for i = 1, math.min(lineCount, 5) do
        local fs = name and _G[name .. "TextLeft" .. i]
        local text = GQ.PublicText(fs and fs.GetText and fs:GetText())
        if text and (text == retrieving or text:find("Retrieving", 1, true)) then
            return true
        end
    end
    return false
end

function GQ.Data:SetTooltipItem(tooltip, itemIdOrLink)
    if not tooltip or not itemIdOrLink then
        return false
    end

    local ok
    if type(itemIdOrLink) == "number" then
        if tooltip.SetItemByID then
            ok = pcall(tooltip.SetItemByID, tooltip, itemIdOrLink)
            if ok and not self:TooltipLooksRetrieving(tooltip) then
                return true
            end
        end
        ok = pcall(tooltip.SetHyperlink, tooltip, "item:" .. itemIdOrLink)
        return ok == true
    end

    ok = pcall(tooltip.SetHyperlink, tooltip, itemIdOrLink)
    return ok == true
end

function GQ.Data:RefreshPendingTooltip(tooltip, entry, forceFallback)
    if not tooltip or not entry then
        return
    end
    if tooltip.gqItemInfoRefreshing then
        return
    end

    tooltip.gqItemInfoRefreshing = true
    tooltip.gqSkipScoreHook = true
    tooltip.gqScoreLineAdded = nil
    tooltip.gqEnchantAdded = nil
    if forceFallback then
        if not self:ShowForeverItemTooltip(tooltip, entry) then
            self:ShowFactFallbackTooltip(tooltip, entry)
        end
        self:ClearPendingItemTooltip(tooltip)
    else
        self:PopulateEntryItemTooltip(tooltip, entry)
    end
    if entry.itemId then
        self:ApplyImbueTooltipLines(tooltip, entry.itemId)
    end
    self:AppendAuctionatorTooltip(tooltip, entry)
    self:AppendGearScoreLine(tooltip, entry)
    if tooltip.Show then
        tooltip:Show()
    end
    tooltip.gqSkipScoreHook = nil
    tooltip.gqItemInfoRefreshing = nil
end

function GQ.Data:EnsurePendingTooltipRefresh()
    if self._pendingTooltipRefresh then
        return
    end

    local frame = CreateFrame("Frame")
    GQ.RegisterEvent(frame, "GET_ITEM_INFO_RECEIVED")
    frame:SetScript("OnEvent", function(_, _, itemId, success)
        itemId = tonumber(itemId)
        local pending = self._pendingItemTooltips
        if not pending then
            return
        end

        for tooltip, entry in pairs(pending) do
            if not tooltip or not tooltip.IsShown or not tooltip:IsShown() then
                pending[tooltip] = nil
            elseif entry and itemId and entry.itemId == itemId then
                self:InvalidateClientSetBlock(itemId)
                local failed = success == false and entry and entry.itemId == itemId
                self:RefreshPendingTooltip(tooltip, entry, failed)
            end
        end
    end)
    self._pendingTooltipRefresh = frame
end

function GQ.Data:EnsurePendingTooltipPoll()
end

function GQ.Data:TrackPendingItemTooltip(tooltip, entry)
    if not tooltip or not entry then
        return
    end

    self:EnsurePendingTooltipRefresh()
    self._pendingItemTooltips = self._pendingItemTooltips or {}
    self._pendingItemTooltips[tooltip] = entry
    if entry.itemId then
        self:RequestItemInfo(entry.itemId, true)
        local link = self:ResolveSuffixItemLink(entry)
        if link then
            self:RequestItemInfo(link, true)
        end
    end
end

function GQ.Data:ClearPendingItemTooltip(tooltip)
    self:HideImbueScrollTooltip()
    if self._pendingItemTooltips and tooltip then
        self._pendingItemTooltips[tooltip] = nil
    end
    if self._pendingTooltipStartedAt and tooltip then
        self._pendingTooltipStartedAt[tooltip] = nil
    end
end

function GQ.Data:TryShowSuffixTargetTooltip(tooltip, entry)
    if not tooltip or not entry then
        return false
    end

    self:EnrichEntrySuffix(entry)
    local link = self:MakeSuffixTargetLink(entry)
    if not link then
        return false
    end

    self:RequestItemInfo(link)
    if not self:ItemInfoIsReady(link) then
        return false
    end

    if not self:SetTooltipItem(tooltip, link) or self:TooltipLooksRetrieving(tooltip) then
        return false
    end
    return self:TooltipShowsEntrySuffix(tooltip, entry)
end

function GQ.Data:CopyTooltipLinesFromScanner(tooltip, scanner, skipTitle)
    local scannerName = scanner:GetName()
    local startLine = skipTitle and 2 or 1

    for i = startLine, scanner:NumLines() do
        local left = _G[scannerName .. "TextLeft" .. i]
        local right = _G[scannerName .. "TextRight" .. i]
        if left then
            local text = GQ.PublicText(left:GetText())
            if text then
                local lr, lg, lb = left:GetTextColor()
                if right then
                    local rightText = GQ.PublicText(right:GetText())
                    if rightText then
                        local rr, rg, rb = right:GetTextColor()
                        tooltip:AddDoubleLine(text, rightText, lr, lg, lb, rr, rg, rb)
                    else
                        tooltip:AddLine(text, lr, lg, lb)
                    end
                else
                    tooltip:AddLine(text, lr, lg, lb)
                end
            end
        end
    end
end

function GQ.Data:ShowSuffixFallbackTooltip(tooltip, entry)
    local itemId = entry.itemId
    local scanner = self:GetTooltipScanner()
    scanner:SetOwner(UIParent, "ANCHOR_NONE")
    scanner:ClearLines()
    scanner:SetHyperlink("item:" .. itemId)

    local displayName = self:GetEntryDisplayName(entry)
    local _, _, quality = GetItemInfo(itemId)
    local r, g, b = GetItemQualityColor(quality or 1)

    tooltip:ClearLines()
    tooltip:SetText(displayName, r, g, b)
    self:CopyTooltipLinesFromScanner(tooltip, scanner, true)
    self:AppendSuffixRangeLines(tooltip, entry)

    local suffixHint = self:GetSuffixHint(entry)
    if suffixHint then
        tooltip:AddLine(" ")
        tooltip:AddLine("Target random enchant: " .. suffixHint, 0.7, 0.9, 1)
    end
    self:AppendDatamineNotice(tooltip, entry)

    scanner:Hide()
end

function GQ.Data:GetEntryItemHyperlink(entry)
    if not entry or not entry.itemId then
        return nil
    end

    if entry.suffix and entry.suffix ~= "" then
        self:EnrichEntrySuffix(entry)
        local link = self:MakeSuffixTargetLink(entry)
        if link then
            local _, itemHyperlink = GetItemInfo(link)
            if itemHyperlink and itemHyperlink ~= "" then
                return itemHyperlink
            end
            return link
        end
    end

    local _, itemHyperlink = GetItemInfo(entry.itemId)
    if itemHyperlink and itemHyperlink ~= "" then
        return itemHyperlink
    end

    return "item:" .. entry.itemId
end

function GQ.Data:ShowClientItemTooltip(tooltip, entry)
    if not tooltip or not entry or not entry.itemId then
        return false
    end
    if entry.suffix and entry.suffix ~= "" then
        return self:TryShowSuffixTargetTooltip(tooltip, entry)
    end
    if not self:SetTooltipItem(tooltip, entry.itemId) or self:TooltipLooksRetrieving(tooltip) then
        return false
    end
    return true
end

function GQ.Data:EntryUsesRebuiltTooltip(entry)
    if not entry then
        return false
    end
    -- Random-suffix greens keep the rebuilt jackpot tooltip.
    if entry.suffix and entry.suffix ~= "" then
        return true
    end
    -- A fixed green world drop or rare uses the Wowhead tip. A blue from a
    -- rare is not a jackpot green either.
    if entry.sourceType ~= "world_drop" and entry.sourceType ~= "rare_npc" then
        return false
    end
    local quality = self:GetItemQualityForDisplay(entry.itemId)
    return quality == 2
end

function GQ.Data:AppendImbueCombineLine(tooltip, entry)
    if not tooltip or not entry then
        return
    end
    local info = self:ImbueInfo(entry.itemId)
    if not info then
        return
    end
    local line = self:ImbueCombineLine(info)
    if not line then
        return
    end
    tooltip:AddLine(" ")
    tooltip:AddLine(line, 0, 1, 0, true)
end

function GQ.Data:ShowClientWaitTooltip(tooltip, entry, missing)
    local displayName = self:GetEntryDisplayName(entry) or ("Item " .. tostring(entry.itemId))
    local quality = self:GetItemQualityForDisplay(entry.itemId)
    local r, g, b = 1, 0.82, 0
    local c = ITEM_QUALITY_COLORS and quality and ITEM_QUALITY_COLORS[quality]
    if c then
        r, g, b = c.r, c.g, c.b
    elseif quality then
        r, g, b = GetItemQualityColor(quality)
    end
    tooltip:ClearLines()
    tooltip:SetText(displayName, r, g, b)
    if missing then
        tooltip:AddLine("Not found in the client", 1, 0.2, 0.2)
    else
        tooltip:AddLine(RETRIEVING_ITEM_INFO or "Retrieving item information", 1, 1, 1)
    end
end

local SCORED_STAT_ORDER = {
    { key = "armor", label = "Armor" },
    { key = "str", label = "Strength" },
    { key = "agi", label = "Agility" },
    { key = "sta", label = "Stamina" },
    { key = "int", label = "Intellect" },
    { key = "spi", label = "Spirit" },
    { key = "sp", label = "Spell Power" },
    { key = "heal", label = "Healing" },
    { key = "ap", label = "Attack Power" },
}

function GQ.Data:TooltipPlainText(tooltip)
    if not tooltip or not tooltip.GetName or not tooltip.NumLines then
        return ""
    end
    local name = tooltip:GetName()
    local parts = {}
    for i = 1, tooltip:NumLines() or 0 do
        local fs = name and _G[name .. "TextLeft" .. i]
        local text = GQ.PublicText(fs and fs.GetText and fs:GetText())
        if text and text ~= "" then
            parts[#parts + 1] = text
        end
    end
    return table.concat(parts, "\n")
end

-- Items with no Wowhead tip still have the stats we score from. If the
-- client tooltip already printed them, leave it alone.
function GQ.Data:AppendScoredStatLines(tooltip, itemId)
    local row = self.scoredStats and itemId and self.scoredStats[itemId]
    if not tooltip or not row then
        return
    end
    local body = self:TooltipPlainText(tooltip):lower()
    for i = 1, #SCORED_STAT_ORDER do
        local spec = SCORED_STAT_ORDER[i]
        local value = row[spec.key]
        if type(value) == "number" and value ~= 0 and not body:find(spec.label:lower(), 1, true) then
            local line
            if spec.key == "armor" then
                line = string.format("%d Armor", value)
            elseif value > 0 then
                line = string.format("+%d %s", value, spec.label)
            else
                line = string.format("%d %s", value, spec.label)
            end
            local r, g, b = 0, 1, 0
            if value < 0 then
                r, g, b = 1, 0.2, 0.2
            end
            tooltip:AddLine(line, r, g, b)
            body = body .. "\n" .. spec.label:lower()
        end
    end
end

function GQ.Data:PopulateEntryItemTooltip(tooltip, entry)
    if not tooltip or not entry or not entry.itemId then
        return false
    end

    -- Green world drops keep the rebuilt jackpot tooltip. Every other item
    -- uses the Wowhead tip. A missing client item must not replace that hover.
    if self:EntryUsesRebuiltTooltip(entry) then
        if self:ShowForeverItemTooltip(tooltip, entry) then
            if self._pendingClientSet then
                self:TrackPendingItemTooltip(tooltip, entry)
            else
                self:ClearPendingItemTooltip(tooltip)
            end
            return true
        end

        if self:ShowClientItemTooltip(tooltip, entry) then
            self:ClearPendingItemTooltip(tooltip)
            return true
        end

        self:ShowFactFallbackTooltip(tooltip, entry)
        self:TrackPendingItemTooltip(tooltip, entry)
        return true
    end

    -- Quest, dungeon, and set pieces use the Wowhead tip. The client item
    -- is often missing until that level, and that must not replace the tip.
    if self:ShowForeverItemTooltip(tooltip, entry) then
        self:ClearPendingItemTooltip(tooltip)
        return true
    end

    -- No stored tip. The client tooltip has the armor and stats when the
    -- item is known. Scored stats fill in only the lines still missing.
    if self:ShowClientItemTooltip(tooltip, entry) and not self:TooltipLooksRetrieving(tooltip) then
        self:AppendScoredStatLines(tooltip, entry.itemId)
        self:ClearPendingItemTooltip(tooltip)
        return true
    end

    self:ShowFactFallbackTooltip(tooltip, entry)
    self:AppendScoredStatLines(tooltip, entry.itemId)
    self:ClearPendingItemTooltip(tooltip)
    return true
end

function GQ.Data:AuctionatorTooltipEnabled()
    local auctionator = Auctionator
    if not auctionator or not auctionator.Tooltip or not auctionator.Tooltip.ShowTipWithPricing then
        return false
    end
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        return C_AddOns.IsAddOnLoaded("Auctionator") and true or false
    end
    if IsAddOnLoaded then
        return IsAddOnLoaded("Auctionator") and true or false
    end
    return false
end

function GQ.Data:AppendAuctionatorTooltip(tooltip, entry)
    if not tooltip or not entry or not entry.itemId or not self:AuctionatorTooltipEnabled() then
        return
    end
    local link = self:GetEntryItemHyperlink(entry)
    if not link then
        return
    end
    pcall(Auctionator.Tooltip.ShowTipWithPricing, tooltip, link, 1)
end

function GQ.Data:ShowEntryItemTooltip(tooltip, owner, entry, anchor, ...)
    if not tooltip or not entry or not entry.itemId then
        return
    end

    tooltip.gqSkipScoreHook = true
    tooltip.gqScoreLineAdded = nil
    tooltip.gqEnchantAdded = nil
    tooltip:SetOwner(owner, anchor or "ANCHOR_RIGHT", ...)
    self:PopulateEntryItemTooltip(tooltip, entry)
    self:ApplyImbueTooltipLines(tooltip, entry.itemId)
    self:AppendAuctionatorTooltip(tooltip, entry)
    self:AppendGearScoreLine(tooltip, entry)
    tooltip:Show()
    self:SolidItemTooltip(tooltip)
    tooltip.gqSkipScoreHook = nil
end

-- The log sits under this hover. A clear tooltip center lets "Select an
-- upgrade..." show through the set list.
function GQ.Data:SolidItemTooltip(tooltip)
    if not tooltip or not tooltip.CreateTexture then
        return
    end
    tooltip:SetFrameStrata("TOOLTIP")
    local bg = tooltip.gqSolidBg
    if not bg then
        bg = tooltip:CreateTexture(nil, "BACKGROUND", nil, -8)
        bg:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 2, -2)
        bg:SetPoint("BOTTOMRIGHT", tooltip, "BOTTOMRIGHT", -2, 2)
        if bg.SetColorTexture then
            bg:SetColorTexture(0.07, 0.07, 0.07, 1)
        else
            bg:SetTexture("Interface\\Buttons\\WHITE8X8")
            bg:SetVertexColor(0.07, 0.07, 0.07, 1)
        end
        tooltip.gqSolidBg = bg
    end
    bg:Show()
end

function GQ.Data:CacheContainerItemLinks()
    if not self.byItemId then
        return
    end

    local function cacheLink(link)
        if not link then
            return
        end

        local itemId = self:ItemLinkToId(link)
        if not itemId then
            return
        end

        local itemName = self:ItemNameFromLink(link)
        if not itemName or not itemName:find(" of ", 1, true) then
            return
        end

        for _, entry in ipairs(self.byItemId[itemId] or {}) do
            if entry.suffix and self:EntrySuffixMatchesLink(entry, link) then
                self:CacheOwnedSuffixItemLink(entry, link)
            end
        end
    end

    for invSlot = 1, 19 do
        cacheLink(GetInventoryItemLink("player", invSlot))
    end

    local numBags = NUM_BAG_SLOTS or 4
    for bag = 0, numBags do
        local numSlots
        if C_Container and C_Container.GetContainerNumSlots then
            numSlots = C_Container.GetContainerNumSlots(bag) or 0
        elseif GetContainerNumSlots then
            numSlots = GetContainerNumSlots(bag) or 0
        else
            numSlots = 0
        end

        for slot = 1, numSlots do
            local link
            if C_Container and C_Container.GetContainerItemLink then
                link = C_Container.GetContainerItemLink(bag, slot)
            elseif GetContainerItemLink then
                link = GetContainerItemLink(bag, slot)
            end
            cacheLink(link)
        end
    end
end

function GQ.Data:NormalizeItemName(name)
    if not name then
        return nil
    end

    if strtrim then
        return strtrim(name)
    end

    return (name:gsub("^%s*(.-)%s*$", "%1"))
end

function GQ.Data:ItemNameMatchesEntry(itemName, entry)
    if not itemName or not entry then
        return false
    end

    return self:NormalizeItemName(itemName) == self:GetEntryDisplayName(entry)
end

function GQ.Data:ItemLinkToId(link)
    if not link then
        return nil
    end

    return tonumber(link:match("item:(%d+)"))
end

function GQ.Data:ItemLinkFullName(link)
    if not link then
        return nil
    end

    local bracket = link:match("%[(.-)%]")
    if bracket and bracket ~= "" and not self:IsPlaceholderItemName(bracket) then
        return self:NormalizeItemName(bracket)
    end

    if GetItemInfo then
        local name = GetItemInfo(link)
        if type(name) == "string" and name ~= "" and not self:IsPlaceholderItemName(name) then
            return self:NormalizeItemName(name)
        end
    end

    return nil
end

function GQ.Data:ItemNameFromLink(link)
    if not link then
        return nil
    end

    local itemId = self:ItemLinkToId(link)
    if itemId then
        local name = self:GetItemDisplayName(itemId)
        if name then
            return name
        end
    end

    local bracket = link:match("%[(.-)%]")
    if bracket and not self:IsPlaceholderItemName(bracket, itemId) then
        return bracket
    end
    return nil
end

function GQ.Data:PlayerOwnsEntryItem(entry)
    if not entry or not entry.itemId then
        return false
    end

    self:EnrichEntrySuffix(entry)

    local itemId = entry.itemId
    local needsSuffix = entry.suffix and entry.suffix ~= ""

    local function linkMatches(link)
        if self:ItemLinkToId(link) ~= itemId then
            return false
        end

        if needsSuffix then
            return self:EntrySuffixMatchesLink(entry, link)
        end

        return true
    end

    local ok, owned = pcall(function()
        for invSlot = 1, 19 do
            if linkMatches(GetInventoryItemLink("player", invSlot)) then
                return true
            end
        end

        local numBags = NUM_BAG_SLOTS or 4
        for bag = 0, numBags do
            local numSlots
            if C_Container and C_Container.GetContainerNumSlots then
                numSlots = C_Container.GetContainerNumSlots(bag) or 0
            elseif GetContainerNumSlots then
                numSlots = GetContainerNumSlots(bag) or 0
            else
                numSlots = 0
            end

            for slot = 1, numSlots do
                local link
                if C_Container and C_Container.GetContainerItemLink then
                    link = C_Container.GetContainerItemLink(bag, slot)
                elseif GetContainerItemLink then
                    link = GetContainerItemLink(bag, slot)
                end

                if linkMatches(link) then
                    return true
                end
            end
        end

        return false
    end)

    return ok and owned or false
end

function GQ.Data:GetEntryById(id)
    if not id then
        return nil
    end
    -- byId is built once login finishes. A miss is a stale saved hunt id.
    -- Walking self.entries here scans every generated row (about 467k) and
    -- the Completed tab does that once per slot, which trips "script ran too long".
    if self.byId then
        return self.byId[id] or self:GetNotableEntryById(id)
    end
    for _, entry in ipairs(self.entries or {}) do
        if entry.id == id then
            return entry
        end
    end
    return self:GetNotableEntryById(id)
end

function GQ.Data:InvalidatePlayerBandCache()
    self:InvalidateQueryCache()
end

function GQ.Data:InvalidateSpecCache()
    self._queryCache = nil
    self._activeBandCache = nil
end

function GQ.Data:InvalidateQueryCache()
    self._queryCache = nil
    self._activeBandCache = nil
    self._notableEntryCache = nil
    self._gearScoreCache = nil
    self._linkEntryCache = nil
    self._scoreMissCache = nil
    if GQ.Log then
        GQ.Log._slotRankCache = nil
        GQ.Log._slotRankBand = nil
    end
    if GQ.Log and GQ.Log.InvalidateSourceFilterCache then
        GQ.Log:InvalidateSourceFilterCache()
    end
end

function GQ.Data:ScheduleQueryRefresh()
    self:InvalidateQueryCache()
    if GQ.Log and GQ.Log.GetItTodayEnabled and GQ.Log:GetItTodayEnabled() and GQ.Log.InvalidateSourceFilterCache then
        GQ.Log:InvalidateSourceFilterCache()
    end
    if self._queryRefreshScheduled then
        return
    end
    self._queryRefreshScheduled = true
    local function fire()
        self._queryRefreshScheduled = false
        if GQ.RefreshUI then
            GQ:RefreshUI()
        end
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0.25, fire)
    else
        fire()
    end
end

-- Re-filter once GetItemInfo reports a real required level (unknown was allowed).
function GQ.Data:NotePendingRequiredLevel(itemId)
end

function GQ.Data:EnsureRequiredLevelListener()
    if self._requiredLevelListener then
        return
    end

    local frame = CreateFrame("Frame")
    GQ.RegisterEvent(frame, "GET_ITEM_INFO_RECEIVED")
    frame:SetScript("OnEvent", function(_, _, itemId)
        itemId = tonumber(itemId)
        local pending = GQ.Data._pendingRequiredLevel
        if not itemId or not pending or not pending[itemId] then
            return
        end
        pending[itemId] = nil
        GQ.Data:ScheduleQueryRefresh()
    end)
    self._requiredLevelListener = frame
end

function GQ.Data:InvalidateClassCache()
    self:InvalidateQueryCache()
    self.notableBySlot = nil
    self._notableBySlotClass = nil
end

function GQ.Data:GetQueryCacheKey()
    return self:GetActiveBandCacheKey()
end

function GQ.Data:EnsureQueryCache()
    local cacheKey = self:GetQueryCacheKey()
    if self._queryCache and self._queryCache.key == cacheKey then
        return
    end

    self._queryCache = {
        key = cacheKey,
        candidates = {},
        topUpgrades = {},
        notables = {},
        activeBandMin = nil,
    }
end

function GQ.Data:GetActiveBandCacheKey()
    local spec = GQ.GetEffectiveSpec and GQ:GetEffectiveSpec() or ""
    return (GQ:GetEffectiveLevel() or 0) .. ":"
        .. (GQ:GetEffectiveClass() or "") .. ":"
        .. (GQ:GetEffectiveFaction() or "") .. ":"
        .. tostring(spec)
end

function GQ.Data:EntryMatchesPlayerBand(entry)
    if not entry or not entry.slot then
        return false
    end

    if not self:IsSlotUnlocked(entry.slot) then
        return false
    end

    local classFile = GQ:GetEffectiveClass()
    if entry.classes and not entry.classes[classFile] then
        return false
    end

    local faction = GQ:GetEffectiveFaction()
    if entry.factions and not entry.factions[faction] then
        return false
    end

    if not GQ.Equip:EntryWithinLevelBand(entry) then
        return false
    end

    if GQ.Equip.EntryMatchesSpec and not GQ.Equip:EntryMatchesSpec(entry) then
        return false
    end

    return true
end

function GQ.Data:EntryMatchesPlayer(entry)
    if not self:EntryMatchesPlayerBand(entry) then
        return false
    end

    -- The stored band can cover levels before this piece can be worn. Fiery
    -- War Axe is required level 35, and a 30-35 band was still listing it at
    -- 30. Use the stored Wowhead required level. Do not ask the client while
    -- building the list: priming every tooltip dropped FPS, and an uncached
    -- GetItemInfo treated the requirement as unknown and let the piece show.
    local fact = self:GetItemFact(entry.itemId)
    local req = fact and fact.reqLevel
    if type(req) == "number" and req > 1 and req > (GQ:GetEffectiveLevel() or 1) then
        return false
    end

    -- Required level, class equip, and spec. Simulator uses GetEffectiveLevel.
    if not GQ.Equip:EntryMatchesItemRules(entry) then
        return false
    end

    return true
end

function GQ.Data:SelectActiveBand(entries, playerLevel)
    playerLevel = playerLevel or GQ:GetEffectiveLevel()
    local bestMinLevel
    local bestMaxLevel

    for _, entry in ipairs(entries or {}) do
        local minLevel = entry.minLevel or 1
        local maxLevel = entry.maxLevel or playerLevel
        if playerLevel >= minLevel and playerLevel <= maxLevel then
            if not bestMinLevel
                or minLevel > bestMinLevel
                or (minLevel == bestMinLevel and maxLevel < bestMaxLevel) then
                bestMinLevel = minLevel
                bestMaxLevel = maxLevel
            end
        end
    end

    if not bestMinLevel then
        -- Wide bands (e.g. seasonal head through level 8): fall back to highest minLevel reached.
        for _, entry in ipairs(entries or {}) do
            local minLevel = entry.minLevel or 1
            if playerLevel >= minLevel then
                if not bestMinLevel or minLevel > bestMinLevel then
                    bestMinLevel = minLevel
                    bestMaxLevel = nil
                end
            end
        end
    end

    return bestMinLevel, bestMaxLevel
end

function GQ.Data:EntryInActiveBand(entry, activeMinLevel, activeMaxLevel)
    if not entry then
        return false
    end

    -- Forever hand-adds stay in the hunt for every overlapping generated band.
    -- Compare still caps the list at top 3 by score.
    if entry.foreverDelta then
        local playerLevel = GQ:GetEffectiveLevel()
        return playerLevel >= (entry.minLevel or 1)
            and playerLevel <= (entry.maxLevel or playerLevel)
    end

    if not activeMinLevel then
        return false
    end

    if (entry.minLevel or 1) ~= activeMinLevel then
        return false
    end

    if activeMaxLevel then
        return (entry.maxLevel or activeMaxLevel) == activeMaxLevel
    end

    return true
end

function GQ.Data:FilterToActiveBand(entries)
    if not entries or #entries == 0 then
        return entries
    end

    local playerLevel = GQ:GetEffectiveLevel()
    local activeMinLevel, activeMaxLevel = self:SelectActiveBand(entries, playerLevel)

    if not activeMinLevel then
        return entries
    end

    local filtered = {}
    for _, entry in ipairs(entries) do
        if self:EntryInActiveBand(entry, activeMinLevel, activeMaxLevel) then
            table.insert(filtered, entry)
        end
    end

    return filtered
end

function GQ.Data:EntryListKey(entry)
    if not entry or not entry.itemId then
        return nil
    end

    if entry.suffix and entry.suffix ~= "" then
        if entry.suffixId and entry.suffixId ~= 0 then
            return entry.itemId .. "\0" .. tostring(entry.suffixId)
        end
        return entry.itemId .. "\0" .. entry.suffix
    end

    return tostring(entry.itemId)
end

function GQ.Data:PreferEntry(a, b)
    if not a then
        return false
    end
    if not b then
        return true
    end

    if a.generated ~= b.generated then
        return not a.generated
    end

    local rankA = a.curatedRank or 99
    local rankB = b.curatedRank or 99
    if rankA ~= rankB then
        return rankA < rankB
    end

    return (a.minLevel or 0) > (b.minLevel or 0)
end

function GQ.Data:DeduplicateEntriesByItem(entries)
    local best = {}
    local order = {}

    for _, entry in ipairs(entries or {}) do
        local key = self:EntryListKey(entry)
        if key then
            local prev = best[key]
            if not prev then
                order[#order + 1] = key
                best[key] = entry
            elseif self:PreferEntry(entry, prev) then
                best[key] = entry
            end
        end
    end

    local results = {}
    for i = 1, #order do
        results[i] = best[order[i]]
    end

    return results
end

function GQ.Data:BackfillCandidates(allEntries, filtered, minCount)
    minCount = minCount or 3
    filtered = self:DeduplicateEntriesByItem(filtered)
    if not filtered or #filtered >= minCount then
        return filtered
    end

    local playerLevel = GQ:GetEffectiveLevel()
    local activeMinLevel, activeMaxLevel = self:SelectActiveBand(allEntries, playerLevel)

    local seen = {}
    local seenItem = {}
    for _, entry in ipairs(filtered) do
        seen[entry.id] = true
        local key = self:EntryListKey(entry)
        if key then
            seenItem[key] = true
        end
    end

    local extras = {}
    for _, entry in ipairs(allEntries or {}) do
        if not seen[entry.id] and not entry.notable and self:ShouldShowEntry(entry)
            and self:EntryMatchesPlayer(entry) then
            local key = self:EntryListKey(entry)
            if key and not seenItem[key] and activeMinLevel
                and self:EntryInActiveBand(entry, activeMinLevel, activeMaxLevel) then
                extras[#extras + 1] = entry
            end
        end
    end

    table.sort(extras, function(a, b)
        local rankA = a.curatedRank or 99
        local rankB = b.curatedRank or 99
        if rankA ~= rankB then
            return rankA < rankB
        end
        return (a.minLevel or 0) > (b.minLevel or 0)
    end)

    for _, entry in ipairs(extras) do
        if #filtered >= minCount then
            break
        end
        local key = self:EntryListKey(entry)
        if key and not seenItem[key] then
            seen[entry.id] = true
            seenItem[key] = true
            filtered[#filtered + 1] = entry
        end
    end

    return self:DeduplicateEntriesByItem(filtered)
end

local NOTABLE_CLASS = {
    PALADIN = { rows = "paladinNotable", facts = "itemFacts" },
    WARRIOR = { rows = "warriorNotable", facts = "warriorItemFacts" },
    HUNTER  = { rows = "hunterNotable",  facts = "hunterItemFacts" },
    DRUID   = { rows = "druidNotable",   facts = "druidItemFacts" },
    SHAMAN  = { rows = "shamanNotable",  facts = "shamanItemFacts" },
    ROGUE   = { rows = "rogueNotable",   facts = "rogueItemFacts" },
    PRIEST  = { rows = "priestNotable",  facts = "priestItemFacts" },
    WARLOCK = { rows = "warlockNotable", facts = "warlockItemFacts" },
    MAGE    = { rows = "mageNotable",    facts = "mageItemFacts" },
}

local NOTABLE_SPECS = {
    PALADIN = {
        retribution = { retribution = true },
        protection = { protection = true },
        holy = { holy = true },
    },
    WARRIOR = {
        arms = { arms = true },
        fury = { fury = true },
        protection = { protection = true },
    },
    HUNTER = {
        beast_mastery = { beast_mastery = true },
        marksmanship  = { marksmanship  = true },
        survival      = { survival      = true },
    },
    DRUID = {
        bear        = { bear        = true },
        feral       = { feral       = true },
        balance     = { balance     = true },
        restoration = { restoration = true },
    },
    SHAMAN = {
        elemental   = { elemental   = true },
        enhancement = { enhancement = true },
        enhancement_tank = { enhancement_tank = true },
        restoration = { restoration = true },
    },
    ROGUE = {
        combat        = { combat        = true },
        assassination = { assassination = true },
        subtlety      = { subtlety      = true },
    },
    PRIEST = {
        holy       = { holy       = true },
        discipline = { discipline = true },
        shadow     = { shadow     = true },
    },
    WARLOCK = {
        affliction  = { affliction  = true },
        demonology  = { demonology  = true },
        destruction = { destruction = true },
    },
    MAGE = {
        frost  = { frost  = true },
        fire   = { fire   = true },
        arcane = { arcane = true },
    },
}

function GQ.Data:BuildNotableEntry(row, facts, classFile)
    if not row or not facts then
        return nil
    end

    local itemId, slot, minL, maxL = row[1], row[2], row[3], row[4]
    local spec, faction = row[5], row[6]
    local f = facts[itemId]
    if not f then
        return nil
    end

    if self:IsExcludedItem({ itemId = itemId, proc = f.proc }) then
        return nil
    end

    if f.proc then
        local probe = { itemId = itemId, proc = f.proc }
        if self:IsNoveltyProcItem(probe) then
            return nil
        end
    end

    local classTbl = { [classFile] = true }
    local specTbl = NOTABLE_SPECS[classFile]
    local FACTION = {
        Alliance = { Alliance = true },
        Horde = { Horde = true },
    }

    local entry = {
        id = string.format("notable:%s:%d:%s:%d:%s:%s", classFile, itemId, slot, minL, tostring(spec), tostring(faction)),
        itemId = itemId,
        slot = slot,
        minLevel = minL,
        maxLevel = maxL,
        classes = classTbl,
        specs = spec and specTbl and specTbl[spec] or nil,
        factions = faction and FACTION[faction] or nil,
        sourceType = f.sourceType,
        instructions = f.instructions,
        setPiece = f.setPiece,
        zone = f.zone,
        npc = f.npc,
        questName = f.questName,
        profession = f.profession,
        proc = f.proc,
        suffix = row.suffix,
        suffixChance = row.suffixChance,
        suffixId = row.suffixId,
        suffixRange = row.suffixRange,
        pipelineScore = self:LookupPipelineScore(itemId, slot, minL, faction, spec),
        generated = true,
        notable = true,
    }

    self._notableEntryCache = self._notableEntryCache or {}
    local cached = self._notableEntryCache[entry.id]
    if cached then
        return cached
    end

    entry = self:EnrichEntrySuffix(entry)
    entry = self:EnrichProfessionEntry(entry)
    self._notableEntryCache[entry.id] = entry
    return entry
end

function GQ.Data:AsMainBiSEntry(entry)
    if not entry or not entry.notable then
        return entry
    end

    local copy = {}
    for key, value in pairs(entry) do
        copy[key] = value
    end
    copy.notable = false
    return copy
end

function GQ.Data:ShouldDisplayAsNotable(entry, slotName)
    if not entry or not entry.notable then
        return false
    end

    slotName = slotName and self:NormalizeSlotName(slotName)
    if not slotName then
        return true
    end

    local itemKey = self:EntryListKey(entry)
    if not itemKey then
        return true
    end

    for _, top in ipairs(self:GetTopUpgradesForSlot(slotName)) do
        if self:EntryListKey(top) == itemKey then
            return false
        end
    end

    return true
end

local function NormalizeEntryIdToken(value)
    if value == nil or value == "" or value == "nil" then
        return nil
    end
    return value
end

function GQ.Data:GetNotableEntryById(id)
    if type(id) ~= "string" or not id:match("^notable:") then
        return nil
    end

    local classFile, itemId, slot, minL, spec, faction = id:match(
        "^notable:([^:]+):(%d+):([^:]+):(%d+):([^:]*):([^:]*)$"
    )
    if not classFile then
        return nil
    end

    itemId = tonumber(itemId)
    minL = tonumber(minL)
    spec = NormalizeEntryIdToken(spec)
    faction = NormalizeEntryIdToken(faction)

    local src = NOTABLE_CLASS[classFile]
    if not src then
        return nil
    end

    local rows = self[src.rows]
    local facts = self[src.facts]
    if not rows or not facts then
        return nil
    end

    for i = 1, #rows do
        local row = rows[i]
        if row[1] == itemId
            and row[2] == slot
            and row[3] == minL
            and (row[5] or nil) == spec
            and (row[6] or nil) == faction then
            return self:BuildNotableEntry(row, facts, classFile)
        end
    end

    return nil
end

function GQ.Data:EnsureNotableBySlot(classFile)
    classFile = classFile or GQ:GetEffectiveClass()
    if self._notableBySlotClass == classFile and self.notableBySlot then
        return
    end

    self._notableEntryCache = nil
    self.notableBySlot = {}
    self._notableBySlotClass = classFile

    local src = NOTABLE_CLASS[classFile]
    local rows = src and self[src.rows]
    if not rows then
        return
    end

    for i = 1, #rows do
        local row = rows[i]
        local slot = self:NormalizeSlotName(row[2])
        self.notableBySlot[slot] = self.notableBySlot[slot] or {}
        table.insert(self.notableBySlot[slot], row)
    end
end

function GQ.Data:GetNotableForSlot(slotName)
    -- Notables are ranked with everything else. Nothing is pulled out as a fourth hunt.
    return {}
end

function GQ.Data:GetActiveBandMinLevel()
    local cacheKey = self:GetActiveBandCacheKey()
    if self._activeBandCache and self._activeBandCache.key == cacheKey then
        return self._activeBandCache.value
    end

    self:EnsureQueryCache()
    if self._queryCache.activeBandMin ~= nil then
        self._activeBandCache = { key = cacheKey, value = self._queryCache.activeBandMin }
        return self._queryCache.activeBandMin
    end

    local merged = {}
    for _, slotName in ipairs(self.BASE_SLOTS) do
        if self:IsSlotUnlocked(slotName) then
            local candidates = self:GetCandidatesForSlot(slotName)
            for i = 1, math.min(#candidates, 8) do
                merged[#merged + 1] = candidates[i]
            end
            if #merged >= 16 then
                break
            end
        end
    end

    local activeMinLevel = self:SelectActiveBand(merged)
    self._queryCache.activeBandMin = activeMinLevel
    self._activeBandCache = { key = cacheKey, value = activeMinLevel }
    return activeMinLevel
end

function GQ.Data:PreviousLevelShownKeys()
    self:EnsureQueryCache()
    local cache = self._queryCache
    if cache.previousListKeys then
        return cache.previousListKeys
    end

    local level = GQ:GetEffectiveLevel() or 1
    if level <= 1 or GQ._listProbeLevel then
        cache.previousListKeys = {}
        return cache.previousListKeys
    end

    -- Last level's lists are another full catalog walk. After a ding that is
    -- a second hitch, so build one slot per frame and show no "new" labels
    -- until it is done.
    if cache.previousListBuilding then
        return nil
    end
    cache.previousListBuilding = true

    local keys = {}
    local probe = { level = level - 1 }
    local function withProbe(fn)
        local savedCache = self._queryCache
        local savedBand = self._activeBandCache
        GQ._listProbeLevel = probe.level
        self._queryCache = probe.cache
        self._activeBandCache = probe.band
        local ok, result = pcall(fn)
        probe.cache = self._queryCache
        probe.band = self._activeBandCache
        GQ._listProbeLevel = nil
        self._queryCache = savedCache
        self._activeBandCache = savedBand
        return ok, result
    end
    local function addSlot(slotName)
        return withProbe(function()
            local top = self:GetTopUpgradesForSlot(slotName)
            for j = 1, #top do
                local key = self:EntryListKey(top[j])
                if key then
                    keys[key] = true
                end
            end
            local notables = self:GetNotableForSlot(slotName) or {}
            for j = 1, #notables do
                local key = self:EntryListKey(notables[j])
                if key then
                    keys[key] = true
                end
            end
        end)
    end
    local _, slots = withProbe(function()
        return self:WarmSlotNames()
    end)
    slots = type(slots) == "table" and slots or {}

    if not (C_Timer and C_Timer.After) then
        for i = 1, #slots do
            addSlot(slots[i])
        end
        cache.previousListBuilding = nil
        cache.previousListKeys = keys
        return keys
    end

    local index = 0
    local gapLeft = 0
    local gap = GQ._levelUpGap or 0
    GQ._levelUpGap = nil
    local function step()
        if self._queryCache ~= cache then
            return
        end
        if gapLeft > 0 then
            gapLeft = gapLeft - 1
            C_Timer.After(0, step)
            return
        end
        index = index + 1
        if slots[index] then
            addSlot(slots[index])
            gapLeft = gap
            C_Timer.After(0, step)
            return
        end
        cache.previousListBuilding = nil
        cache.previousListKeys = keys
        if GQ.Log and GQ.Log.ScheduleListRefresh then
            GQ.Log:ScheduleListRefresh()
        end
    end
    C_Timer.After(0, step)
    return nil
end

function GQ.Data:IsEntryNewForPlayer(entry)
    if not entry or GQ._listProbeLevel then
        return false
    end

    local key = self:EntryListKey(entry)
    if not key then
        return false
    end

    local level = GQ:GetEffectiveLevel() or 1
    if level <= 1 then
        return false
    end

    local previous = self:PreviousLevelShownKeys()
    if not previous then
        return false
    end
    return not previous[key]
end

-- First level of the current run on the hunt list. A row counts when its
-- stored rank was inside the hunt count, or at least as good as the row
-- showing now. A gap ends the run.
function GQ.Data:EntryListSinceLevel(entry)
    local function flagsMatch(a, b)
        if a == b then
            return true
        end
        if not a or not b then
            return false
        end
        for key, value in pairs(a) do
            if value and not b[key] then
                return false
            end
        end
        for key, value in pairs(b) do
            if value and not a[key] then
                return false
            end
        end
        return true
    end
    if not entry or not entry.itemId then
        return nil
    end
    local level = GQ:GetEffectiveLevel() or 1
    local limit = 3
    if GQ.Log and GQ.Log.HuntsPerSlot then
        limit = GQ.Log:HuntsPerSlot()
    end
    local rankLine = entry.curatedRank or limit
    if rankLine < limit then
        rankLine = limit
    end
    local classFile = GQ.GetEffectiveClass and GQ:GetEffectiveClass()
    local slot = self.NormalizeSlotName and self:NormalizeSlotName(entry.slot) or entry.slot
    local suffix = entry.suffix or ""
    if classFile and self.IsClassExpanded and not self:IsClassExpanded(classFile) then
        return entry.minLevel or level
    end
    local cacheKey = table.concat({
        tostring(entry.id),
        tostring(level),
        tostring(limit),
        tostring(rankLine),
        tostring(classFile),
        tostring(slot),
        suffix,
    }, ":")
    self._sinceLevel = self._sinceLevel or {}
    local cached = self._sinceLevel[cacheKey]
    if cached ~= nil then
        if cached == false then
            return nil
        end
        return cached
    end
    local spans = {}
    local rows = self:GetEntriesByItemId(entry.itemId)
    for i = 1, #rows do
        local row = rows[i]
        local rowSlot = self.NormalizeSlotName and self:NormalizeSlotName(row.slot) or row.slot
        if rowSlot == slot
            and (row.suffix or "") == suffix
            and (not row.classes or not classFile or row.classes[classFile])
            and flagsMatch(row.specs, entry.specs)
            and flagsMatch(row.factions, entry.factions)
        then
            local lo = row.minLevel or 1
            local hi = row.maxLevel or lo
            local covers = level >= lo and level <= hi
            local rank = row.curatedRank or 99
            if covers or rank <= rankLine then
                spans[#spans + 1] = { lo, hi }
            end
        end
    end
    if #spans == 0 then
        local fallback = entry.minLevel or level
        self._sinceLevel[cacheKey] = fallback
        return fallback
    end
    local since = level
    local cursor = level
    local guard = 0
    while cursor >= 1 and guard < 80 do
        guard = guard + 1
        local found
        for i = 1, #spans do
            local lo = spans[i][1]
            local hi = spans[i][2]
            if lo <= cursor and hi >= cursor and (not found or lo < found) then
                found = lo
            end
        end
        if not found then
            break
        end
        since = found
        if found <= 1 then
            break
        end
        cursor = found - 1
    end
    self._sinceLevel[cacheKey] = since
    return since
end

-- Active-band candidates the player can equip now (required level uses GetEffectiveLevel).
-- Runs inside one class/level/faction/spec snapshot (GQ:WithContextSnapshot).
function GQ.Data:GetCandidatesForSlot(slotName)
    return GQ:WithContextSnapshot(self.BuildCandidatesForSlot, self, slotName)
end

function GQ.Data:BuildCandidatesForSlot(slotName)
    slotName = self:NormalizeSlotName(slotName)
    self:EnsureQueryCache()

    local cached = self._queryCache.candidates[slotName]
    if cached then
        return cached
    end

    local results = {}
    local seen = {}
    local equip = GQ.Equip
    local prevSuppress = equip and equip._suppressItemPrime
    if equip then
        equip._suppressItemPrime = true
    end

    -- Level is a number compare. The class-set name check is not, and most
    -- rows are other bands. Skip those before ShouldShowEntry.
    local playerLevel = GQ:GetEffectiveLevel() or 1
    local grace = (equip and equip.LEVEL_GRACE) or 0

    for _, key in ipairs(self:GetCandidateSlotKeys(slotName)) do
        for _, entry in ipairs(self:GetClassSlotEntryList(key) or {}) do
            if not seen[entry.id]
                and playerLevel >= (entry.minLevel or 1)
                and playerLevel <= (entry.maxLevel or playerLevel) + grace
                and self:ShouldShowEntry(entry)
                and self:EntryMatchesPlayer(entry)
                and (not equip or not equip.EntryArmorIsWearable or equip:EntryArmorIsWearable(entry, slotName)) then
                seen[entry.id] = true
                table.insert(results, entry)
            end
        end
    end

    if equip then
        equip._suppressItemPrime = prevSuppress
    end

    local allMatching = results
    results = self:FilterToActiveBand(results)
    results = self:BackfillCandidates(allMatching, results, 3)
    results = self:DeduplicateEntriesByItem(results)
    self._queryCache.candidates[slotName] = results
    return results
end

GQ.Data.SLOT_LABELS = {
    Head = "Head",
    Neck = "Neck",
    Shoulder = "Shoulder",
    Back = "Back",
    Chest = "Chest",
    Wrist = "Wrist",
    Hands = "Hands",
    Waist = "Waist",
    Legs = "Legs",
    Feet = "Feet",
    Finger = "Finger",
    Trinket = "Trinket",
    MainHand = "Main Hand",
    SecondaryHand = "Off Hand",
    Ranged = "Ranged",
}

GQ.Data.BASE_SLOTS = {
    "Head", "Neck", "Shoulder", "Back", "Chest", "Wrist", "Hands",
    "Waist", "Legs", "Feet", "Finger", "Trinket",
    "MainHand", "SecondaryHand",
}

-- CharacterFrame slot buttons (Character{Name}Slot). Ranged is one UI slot for all
-- class relics: librams/relics, idols, totems, wands, bows/guns/crossbows.
GQ.Data.PAPER_DOLL_SLOTS = {
    "Head", "Neck", "Shoulder", "Back", "Chest", "Wrist", "Hands",
    "Waist", "Legs", "Feet", "Finger0", "Finger1", "Trinket0", "Trinket1",
    "MainHand", "SecondaryHand", "Ranged",
}

GQ.Data.CLASS_RANGED = {
    WARRIOR = true,
    ROGUE = true,
    HUNTER = true,
    MAGE = true,
    PRIEST = true,
    WARLOCK = true,
    SHAMAN = true,
    PALADIN = true,
    DRUID = true,
}

-- GearQuest log/popup slots that unlock at specific character levels.
-- Milestone chat messages for these slots: see docs/DATA_RULES.md § Slot unlock & level-up messages.
GQ.Data.SLOT_UNLOCK_LEVEL = {
    Finger = 9,
    Shoulder = 9,
}

function GQ.Data:GetSlotUnlockLevel(slotName)
    slotName = self:NormalizeSlotName(slotName)
    return self.SLOT_UNLOCK_LEVEL[slotName] or 1
end

function GQ.Data:IsSlotUnlocked(slotName)
    return GQ:GetEffectiveLevel() >= self:GetSlotUnlockLevel(slotName)
end

function GQ.Data:SlotHasHunts(slotName)
    local candidates = self:GetCandidatesForSlot(slotName)
    return candidates and #candidates > 0
end

function GQ.Data:GetSlotsForClass(classFile)
    local slots = {}
    local seen = {}

    for _, slotName in ipairs(self.BASE_SLOTS) do
        slotName = self:NormalizeSlotName(slotName)
        if not seen[slotName] and self:IsSlotUnlocked(slotName) and self:SlotHasHunts(slotName) then
            seen[slotName] = true
            table.insert(slots, slotName)
        end
    end

    if self.CLASS_RANGED[classFile] and not seen.Ranged and self:SlotHasHunts("Ranged") then
        table.insert(slots, "Ranged")
    end

    return slots
end

function GQ.Data:GetMaxUpgradesForSlot(slotName)
    return 3
end

function GQ.Data:RegisterPipelineScore(itemId, slot, minLevel, faction, spec, score)
    if not score then
        return
    end
    self._pipelineScoreLookup = self._pipelineScoreLookup or {}
    local key = string.format(
        "%d:%s:%d:%s:%s",
        itemId or 0,
        slot or "",
        minLevel or 0,
        tostring(faction),
        tostring(spec)
    )
    self._pipelineScoreLookup[key] = score
end

function GQ.Data:LookupPipelineScore(itemId, slot, minLevel, faction, spec)
    if not self._pipelineScoreLookup then
        return nil
    end
    local key = string.format(
        "%d:%s:%d:%s:%s",
        itemId or 0,
        slot or "",
        minLevel or 0,
        tostring(faction),
        tostring(spec)
    )
    return self._pipelineScoreLookup[key]
end

-- Tooltip display only. pipelineScore and curatedRank stay the hunt order.
-- This maps the slot's raw scores onto 0..100 so the best piece in the
-- slot reads 100 and the worst reads 0.
function GQ.Data:SlotScoreSpan(slotName, handKind)
    local minScore, maxScore
    local function push(score)
        if type(score) ~= "number" then
            return
        end
        if not minScore or score < minScore then
            minScore = score
        end
        if not maxScore or score > maxScore then
            maxScore = score
        end
    end
    if GQ.Log and GQ.Log.GetSlotRankList and slotName then
        for _, entry in ipairs(GQ.Log:GetSlotRankList(slotName, handKind) or {}) do
            push(entry.pipelineScore)
        end
    end
    local dataSlot = slotName == "WeaponPair" and "MainHand" or slotName
    if dataSlot and self.GetNotableForSlot then
        for _, notable in ipairs(self:GetNotableForSlot(dataSlot) or {}) do
            if not handKind or not GQ.Log or not GQ.Log.EntryInWeaponHand
                or GQ.Log:EntryInWeaponHand(notable, dataSlot, handKind) then
                push(notable.pipelineScore)
            end
        end
    end
    return minScore, maxScore
end

function GQ.Data:WornSlotIndex(slotName, itemId, handKind)
    if not itemId then
        return 0
    end
    local score = self:EquippedPipelineScore(itemId, slotName)
    if type(score) ~= "number" then
        return 0
    end
    local minScore, maxScore = self:SlotScoreSpan(slotName, handKind)
    if not minScore then
        return 0
    end
    return self:GearScoreIndex(score, minScore, maxScore) or 0
end

-- One row per slot that goes into the bar. An empty slot counts as 0.
-- A two-hand weapon does not also count an empty off hand.
function GQ.Data:GearScoreWornRows()
    local classFile = GQ.GetEffectiveClass and GQ:GetEffectiveClass()
    if not classFile then
        return {}
    end
    local slots = self:GetSlotsForClass(classFile) or {}
    local mainLink = GetInventoryItemLink and GetInventoryItemLink("player", 16)
    local mainId = mainLink and tonumber(string.match(mainLink, "item:(%d+)"))
    local mainLoc
    if mainId and GetItemInfo then
        mainLoc = select(9, GetItemInfo(mainId))
    end
    local twoHandWorn = mainLoc == "INVTYPE_2HWEAPON"
    local skipOff = twoHandWorn or self:UsesTwoHandOnlyWeapons()
    local rows = {}

    local function add(slotName, invSlot, handKind)
        local link = GetInventoryItemLink and GetInventoryItemLink("player", invSlot)
        local itemId = link and tonumber(string.match(link, "item:(%d+)"))
        local name = link and string.match(link, "%[(.-)%]")
        if name == "" then
            name = nil
        end
        local label = slotName
        if self.SlotHeaderLabel then
            label = self:SlotHeaderLabel(slotName)
        end
        local index = 0
        if itemId then
            index = self:WornSlotIndex(slotName, itemId, handKind)
        end
        rows[#rows + 1] = {
            slot = label,
            name = name,
            itemId = itemId,
            empty = not itemId,
            index = index,
        }
    end

    for i = 1, #slots do
        local slotName = slots[i]
        if slotName == "SecondaryHand" and skipOff then
            -- A two-hand weapon fills this slot. It is not a second piece of gear.
        elseif slotName == "Finger" then
            add("Finger", 11)
            add("Finger", 12)
        elseif slotName == "Trinket" then
            add("Trinket", 13)
            add("Trinket", 14)
        elseif slotName == "MainHand" then
            -- The whole main-hand list, two-hand and one-hand together.
            -- The weapon filter hides hunt rows. It does not change this index.
            add("MainHand", 16)
        else
            local invSlot = self:GetInventorySlot(slotName)
            if invSlot then
                add(slotName, invSlot)
            end
        end
    end

    return rows
end

-- Average index of the gear this character is wearing, clamped to 0..100.
function GQ.Data:GearScoreBarAverage()
    local rows = self:GearScoreWornRows()
    local count = #rows
    if count == 0 then
        return 0
    end
    local sum = 0
    for i = 1, count do
        local index = rows[i].index or 0
        if index < 0 then
            index = 0
        end
        sum = sum + index
    end
    local avg = sum / count
    if avg < 0 then
        return 0
    end
    if avg > 100 then
        return 100
    end
    return avg
end

function GQ.Data:GearScoreIndex(score, minScore, maxScore)
    if type(score) ~= "number" then
        return nil
    end
    if type(minScore) ~= "number" or type(maxScore) ~= "number" or maxScore <= minScore then
        return 100
    end
    local index = ((score - minScore) / (maxScore - minScore)) * 100
    if index > 100 then
        index = 100
    elseif index < 0 then
        index = 0
    end
    return math.floor(index + 0.5)
end

function GQ.Data:EquippedItemId(invSlot)
    if not invSlot or not GetInventoryItemLink then
        return nil
    end
    local link = GetInventoryItemLink("player", invSlot)
    if not link then
        return nil
    end
    return tonumber(string.match(link, "item:(%d+)"))
end

function GQ.Data:ShownPipelineScore(itemId, slotName)
    if not itemId or not slotName then
        return nil
    end
    local best
    local function consider(entry)
        if entry and entry.itemId == itemId and type(entry.pipelineScore) == "number"
            and self:EntryMatchesPlayerBand(entry) then
            if not best or entry.pipelineScore > best then
                best = entry.pipelineScore
            end
        end
    end
    for _, entry in ipairs(self:GetCandidatesForSlot(slotName) or {}) do
        consider(entry)
    end
    if self.GetNotableForSlot then
        for _, entry in ipairs(self:GetNotableForSlot(slotName) or {}) do
            consider(entry)
        end
    end
    return best
end

function GQ.Data:GearScoreEquipKey(slotName)
    local slots = slotName and self:GetInventorySlots(slotName) or {}
    local parts = {}
    for i = 1, #slots do
        parts[i] = tostring(self:EquippedItemId(slots[i]) or 0)
    end
    return table.concat(parts, ",")
end

function GQ.Data:GearScoreContext(slotName, handKind)
    local dataSlot = slotName == "WeaponPair" and "MainHand" or slotName
    local band = self:GetActiveBandCacheKey()
    local cacheKey = band .. ":" .. tostring(slotName) .. ":" .. tostring(handKind) .. ":" .. self:GearScoreEquipKey(dataSlot)
    local cache = self._gearScoreCache
    if cache and cache[cacheKey] ~= nil then
        return cache[cacheKey] or nil
    end
    local scores = {}
    local bestList
    local function push(score, fromList)
        if type(score) ~= "number" then
            return
        end
        scores[#scores + 1] = score
        if fromList and (not bestList or score > bestList) then
            bestList = score
        end
    end

    if GQ.Log and GQ.Log.GetSlotRankList and slotName then
        for _, entry in ipairs(GQ.Log:GetSlotRankList(slotName, handKind) or {}) do
            push(entry.pipelineScore, true)
        end
    end
    if dataSlot and self.GetNotableForSlot then
        for _, notable in ipairs(self:GetNotableForSlot(dataSlot) or {}) do
            if not handKind or not GQ.Log or not GQ.Log.EntryInWeaponHand
                or GQ.Log:EntryInWeaponHand(notable, dataSlot, handKind) then
                push(notable.pipelineScore, true)
            end
        end
    end

    local equippedIds = {}
    local worn = {}
    local wornOff
    local empty = false
    local slots = dataSlot and self:GetInventorySlots(dataSlot) or {}
    for i = 1, #slots do
        local itemId = self:EquippedItemId(slots[i])
        if not itemId then
            empty = true
        else
            equippedIds[itemId] = true
            local score = self:EquippedPipelineScore(itemId, dataSlot)
            if score then
                worn[#worn + 1] = score
                push(score)
            end
        end
    end

    -- The merged weapon list compares each hand to the piece worn there.
    if handKind == "both" then
        for _, invSlot in ipairs(self:GetInventorySlots("SecondaryHand") or {}) do
            local offId = self:EquippedItemId(invSlot)
            if offId then
                equippedIds[offId] = true
                local offScore = self:EquippedPipelineScore(offId, "SecondaryHand")
                if offScore then
                    wornOff = offScore
                    push(offScore)
                end
            end
        end
    end

    if #scores == 0 then
        self._gearScoreCache = self._gearScoreCache or {}
        self._gearScoreCache[cacheKey] = false
        return nil
    end
    local minScore, maxScore = scores[1], scores[1]
    for i = 2, #scores do
        if scores[i] < minScore then
            minScore = scores[i]
        end
        if scores[i] > maxScore then
            maxScore = scores[i]
        end
    end

    local baselineScore
    -- A free finger or trinket slot is a fill, not a replacement.
    if #slots > 1 then
        if not empty and #worn > 0 then
            baselineScore = worn[1]
            for i = 2, #worn do
                if worn[i] < baselineScore then
                    baselineScore = worn[i]
                end
            end
        end
    elseif #worn > 0 then
        baselineScore = worn[1]
    end
    local baseline
    if baselineScore ~= nil then
        baseline = self:GearScoreIndex(baselineScore, minScore, maxScore)
    end
    local handBaseline
    if handKind == "both" then
        handBaseline = {}
        if baseline ~= nil then
            handBaseline.MainHand = baseline
        end
        if wornOff ~= nil then
            handBaseline.SecondaryHand = self:GearScoreIndex(wornOff, minScore, maxScore)
        end
    end
    local ctx = {
        minScore = minScore,
        maxScore = maxScore,
        baseline = baseline,
        baselineScore = baselineScore,
        handBaseline = handBaseline,
        equippedIds = equippedIds,
        bestListScore = bestList,
        lines = {},
    }
    self._gearScoreCache = self._gearScoreCache or {}
    self._gearScoreCache[cacheKey] = ctx
    return ctx
end

function GQ.Data:EquippedPipelineScore(itemId, slotName)
    local current = self:ShownPipelineScore(itemId, slotName)
    if current then
        return current
    end
    slotName = self:NormalizeSlotName(slotName)
    local spec = GQ.GetEffectiveSpec and GQ:GetEffectiveSpec()
    local faction = GQ.GetEffectiveFaction and GQ:GetEffectiveFaction()
    local level = GQ.GetEffectiveLevel and GQ:GetEffectiveLevel() or 1
    local below, belowEnd, above, aboveStart
    for _, entry in ipairs(self:GetEntriesByItemId(itemId)) do
        if type(entry.pipelineScore) == "number"
            and self:NormalizeSlotName(entry.slot) == slotName
            and (not spec or not entry.specs or entry.specs[spec])
            and (not faction or not entry.factions or entry.factions[faction]) then
            local lo = entry.minLevel or 0
            local hi = entry.maxLevel or lo
            if hi <= level then
                if not belowEnd or hi > belowEnd then
                    below = entry.pipelineScore
                    belowEnd = hi
                end
            elseif not aboveStart or lo < aboveStart then
                above = entry.pipelineScore
                aboveStart = lo
            end
        end
    end
    return below or above
end

-- How much of an upgrade this piece is versus what is worn in the slot.
-- The number is raw pipeline score, the same currency in every slot, so a
-- weapon upgrade can beat filling an empty shoulder. An empty slot's gain
-- is the piece's own score. It is not the index jump from nothing to +100.
-- Already wearing it is 0.
function GQ.Data:GearScoreUpgradeDelta(entry, slotName, handKind)
    if not entry or type(entry.pipelineScore) ~= "number" then
        return nil
    end
    local ctx = self:GearScoreContext(slotName, handKind)
    if not ctx then
        return nil
    end
    if entry.itemId and ctx.equippedIds and ctx.equippedIds[entry.itemId] then
        if not entry.suffix or entry.suffix == "" then
            return 0
        end
        local dataSlot = slotName == "WeaponPair" and "MainHand" or slotName
        local wearingRoll = false
        if GetInventoryItemLink then
            for _, invSlot in ipairs(self:GetInventorySlots(dataSlot) or {}) do
                local link = GetInventoryItemLink("player", invSlot)
                if link and self:ItemLinkToId(link) == entry.itemId
                    and self:EntrySuffixMatchesLink(entry, link) then
                    wearingRoll = true
                    break
                end
            end
        end
        if wearingRoll then
            return 0
        end
    end
    if ctx.baselineScore ~= nil then
        return entry.pipelineScore - ctx.baselineScore, true
    end
    return entry.pipelineScore, false
end

function GQ.Data:GearScoreDeltaText(index, baseline)
    if not index or not baseline then
        return ""
    end
    local delta = index - baseline
    if delta == 0 then
        return ""
    end
    local addon = GQ.ADDON_NAME or "GearQuestForever"
    local file = delta > 0 and "GQ-ArrowUp.png" or "GQ-ArrowDown.png"
    local arrow = "|TInterface\\AddOns\\" .. addon .. "\\Art\\" .. file .. ":14:14:0:0|t"
    if delta > 0 then
        return string.format("  %s |cff00ff00+%d|r", arrow, delta)
    end
    return string.format("  %s |cffff4040%d|r", arrow, delta)
end

function GQ.Data:GearScoreTrail(entry, ctx)
    if not ctx or not entry or type(entry.pipelineScore) ~= "number" then
        return ""
    end
    local index = self:GearScoreIndex(entry.pipelineScore, ctx.minScore, ctx.maxScore)
    if not index then
        return ""
    end
    local baseline = ctx.baseline
    if ctx.handBaseline then
        local slot = entry.slot
        if self.NormalizeSlotName then
            slot = self:NormalizeSlotName(slot) or slot
        end
        if slot == "OffHand" then
            slot = "SecondaryHand"
        end
        baseline = ctx.handBaseline[slot]
    end
    local delta = ""
    if not (entry.itemId and ctx.equippedIds and ctx.equippedIds[entry.itemId]) then
        delta = self:GearScoreDeltaText(index, baseline)
    end
    return string.format("|cffffffff%d|r%s", index, delta)
end

function GQ.Data:GearScoreTooltipLine(entry)
    if GQ.IsPreviewEnabled and GQ:IsPreviewEnabled() then
        return "|cffb0b0b0Turn off simulation mode to see your GearQuest Score for this item|r"
    end
    if not entry then
        return nil
    end
    local slotName, handKind
    if GQ.Log and GQ.Log.RankListContext then
        slotName, handKind = GQ.Log:RankListContext(entry)
    else
        slotName = self:NormalizeSlotName(entry.slot)
    end
    local ctx = self:GearScoreContext(slotName, handKind)
    local lineKey = entry.id or entry.itemId
    if ctx and ctx.lines and lineKey and ctx.lines[lineKey] ~= nil then
        local cached = ctx.lines[lineKey]
        if cached == false then
            return nil
        end
        return cached.line, cached.note
    end
    local visibleRank = GQ.Log and GQ.Log.VisibleSlotRank and GQ.Log:VisibleSlotRank(entry)
    local level = GQ.GetEffectiveLevel and GQ:GetEffectiveLevel() or 1
    local inBand = level >= (entry.minLevel or 1) and level <= (entry.maxLevel or level)
    local rankText
    if visibleRank then
        rankText = string.format("Rank #%d for your level", visibleRank)
    elseif inBand and entry.curatedRank then
        rankText = string.format("Rank #%d for your level", entry.curatedRank)
    else
        rankText = nil
    end
    if rankText and GQ.Log and GQ.Log.OffHandPairNote then
        local pairNote = GQ.Log:OffHandPairNote(entry)
        if pairNote then
            rankText = rankText .. " " .. pairNote
        end
    end
    local trail = ctx and self:GearScoreTrail(entry, ctx) or ""
    local note
    if entry.setPiece and entry.curatedRank == 1 and ctx and ctx.bestListScore
        and type(entry.pipelineScore) == "number"
        and entry.pipelineScore < ctx.bestListScore - 0.01 then
        note = "|cffd9bf73Rank 1 when you wear multiple pieces of this set.|r"
    end
    local line
    if not rankText then
        line = nil
    elseif trail == "" then
        line = "|cffffd100" .. rankText .. "|r"
    else
        line = "|cffffd100" .. rankText .. "|r  " .. trail
    end
    if ctx and ctx.lines and lineKey then
        ctx.lines[lineKey] = line and { line = line, note = note } or false
    end
    return line, note
end

function GQ.Data:GearScoreTooltipEnabled()
    local settings = GearQuestForeverDB and GearQuestForeverDB.settings
    if settings and settings.showGearScore == false then
        return false
    end
    return true
end

function GQ.Data:AppendGearScoreLine(tooltip, entry)
    if not tooltip or not tooltip.AddLine or not entry or tooltip.gqScoreLineAdded then
        return
    end
    local showScore = self:GearScoreTooltipEnabled()
    local line, note
    if showScore then
        line, note = self:GearScoreTooltipLine(entry)
    end
    local enchant = GQ.Enchant and GQ.Enchant.Text and not tooltip.gqEnchantAdded and GQ.Enchant:Text(nil, entry)
    if not line and not enchant then
        return
    end
    tooltip.gqScoreLineAdded = true
    tooltip:AddLine(" ")
    if enchant then
        tooltip.gqEnchantAdded = true
        tooltip:AddLine(enchant, 1, 1, 1)
    end
    if line then
        tooltip:AddLine(line, 1, 1, 1)
        if note then
            tooltip:AddLine(note, 1, 1, 1)
        end
    end
end

function GQ.Data:EntryForItemLink(link)
    local itemId = self:ItemLinkToId(link)
    if not itemId then
        return nil
    end
    local band = self:GetActiveBandCacheKey()
    local bucket = self._linkEntryCache
    if not bucket or bucket.band ~= band then
        bucket = { band = band }
        self._linkEntryCache = bucket
    end
    local suffixId = self:SuffixIdFromLink(link) or 0
    local fullName = self:ItemLinkFullName(link)
    local cacheKey = itemId .. ":" .. suffixId .. ":" .. (fullName and fullName:lower() or "")
    local hit = bucket[cacheKey]
    if hit ~= nil then
        return hit or nil
    end
    local function prefer(current, entry)
        if not current then
            return entry
        end
        local rankA = current.curatedRank or 99
        local rankB = entry.curatedRank or 99
        if rankA ~= rankB then
            if rankB < rankA then
                return entry
            end
            return current
        end
        if (entry.pipelineScore or 0) > (current.pipelineScore or 0) then
            return entry
        end
        return current
    end
    local suffixRows, rows = {}, {}
    for _, entry in ipairs(self:GetEntriesByItemId(itemId)) do
        if type(entry.pipelineScore) == "number" and self:EntryMatchesPlayerBand(entry) then
            if entry.suffix and entry.suffix ~= "" then
                if self:EntrySuffixMatchesLink(entry, link) then
                    suffixRows[#suffixRows + 1] = entry
                end
            else
                rows[#rows + 1] = entry
            end
        end
    end
    local pool = #suffixRows > 0 and suffixRows or rows
    local active = self:FilterToActiveBand(pool)
    if active and #active > 0 then
        pool = active
    end
    local best
    for i = 1, #pool do
        best = prefer(best, pool[i])
    end
    bucket[cacheKey] = best or false
    return best
end

function GQ.Data:AddGearScoreToItemTooltip(tooltip)
    if not tooltip or tooltip.gqSkipScoreHook or tooltip.gqScoreLineAdded or tooltip.gqScoreBusy then
        return
    end
    local name = tooltip.GetName and tooltip:GetName()
    if name and string.find(name, "ShoppingTooltip", 1, true) then
        return
    end
    if not tooltip.GetItem then
        return
    end
    local _, link = tooltip:GetItem()
    local scoreOn = self:GearScoreTooltipEnabled()
    if not scoreOn then
        if GQ.Enchant and GQ.Enchant.Text and not tooltip.gqEnchantAdded then
            local enchant = GQ.Enchant:Text(link, nil)
            if enchant then
                tooltip.gqScoreLineAdded = true
                tooltip.gqEnchantAdded = true
                tooltip:AddLine(" ")
                tooltip:AddLine(enchant, 1, 1, 1)
            end
        end
        return
    end
    tooltip.gqScoreBusy = true
    local entry = self:EntryForItemLink(link)
    if not entry then
        local miss = self:GearScoreMissText(link)
        local enchant = GQ.Enchant and GQ.Enchant.Text and not tooltip.gqEnchantAdded and GQ.Enchant:Text(link, nil)
        if not miss and not enchant then
            tooltip.gqScoreBusy = nil
            return
        end
        tooltip.gqScoreLineAdded = true
        tooltip:AddLine(" ")
        if enchant then
            tooltip.gqEnchantAdded = true
            tooltip:AddLine(enchant, 1, 1, 1)
        end
        if miss then
            tooltip:AddLine(miss, 0.69, 0.69, 0.69)
        end
        tooltip.gqScoreBusy = nil
        return
    end
    self:AppendGearScoreLine(tooltip, entry)
    if not tooltip.gqScoreLineAdded then
        local miss = self:GearScoreMissText(link)
        local enchant = GQ.Enchant and GQ.Enchant.Text and not tooltip.gqEnchantAdded and GQ.Enchant:Text(link, entry)
        if miss or enchant then
            tooltip.gqScoreLineAdded = true
            tooltip:AddLine(" ")
            if enchant then
                tooltip.gqEnchantAdded = true
                tooltip:AddLine(enchant, 1, 1, 1)
            end
            if miss then
                tooltip:AddLine(miss, 0.69, 0.69, 0.69)
            end
        end
    end
    tooltip.gqScoreBusy = nil
end

function GQ.Data:LinkIsGear(link, itemId)
    if itemId and #(self:GetEntriesByItemId(itemId) or {}) > 0 then
        return true
    end
    if not GetItemInfo then
        return false
    end
    local _, _, _, _, _, _, _, _, equipLoc = GetItemInfo(link or itemId)
    if not equipLoc or equipLoc == "" then
        return false
    end
    if equipLoc == "INVTYPE_BAG" or equipLoc == "INVTYPE_QUIVER" or equipLoc == "INVTYPE_AMMO" then
        return false
    end
    return true
end

function GQ.Data:GearScoreMissText(link)
    local itemId = self:ItemLinkToId(link)
    if not itemId or not self:LinkIsGear(link, itemId) then
        return nil
    end
    local band = self:GetActiveBandCacheKey()
    local bucket = self._scoreMissCache
    if not bucket or bucket.band ~= band then
        bucket = { band = band }
        self._scoreMissCache = bucket
    end
    local suffixId = self:SuffixIdFromLink(link) or 0
    local fullName = self:ItemLinkFullName(link)
    local cacheKey = itemId .. ":" .. suffixId .. ":" .. (fullName and fullName:lower() or "")
    local hit = bucket[cacheKey]
    if hit ~= nil then
        return hit or nil
    end
    local function remember(text)
        bucket[cacheKey] = text or false
        return text
    end
    local rows = self:GetEntriesByItemId(itemId)
    if #rows == 0 then
        return remember("GearQuest has no score for this item.")
    end

    local classFile = GQ.GetEffectiveClass and GQ:GetEffectiveClass()
    local spec = GQ.GetEffectiveSpec and GQ:GetEffectiveSpec()
    local faction = GQ.GetEffectiveFaction and GQ:GetEffectiveFaction()
    local level = GQ.GetEffectiveLevel and GQ:GetEffectiveLevel() or 1
    local forClass, forSpec, forSide, forLevel = 0, 0, 0, 0
    local lo, hi
    local suffixNames = {}
    for _, entry in ipairs(rows) do
        if type(entry.pipelineScore) == "number" then
            local classOk = not entry.classes or (classFile and entry.classes[classFile])
            local specOk = not entry.specs or (spec and entry.specs[spec])
            local sideOk = not entry.factions or (faction and entry.factions[faction])
            local levelOk = level >= (entry.minLevel or 1) and level <= (entry.maxLevel or level)
            if classOk then
                forClass = forClass + 1
                if specOk then
                    forSpec = forSpec + 1
                    if sideOk then
                        forSide = forSide + 1
                        local bandLo = entry.minLevel or 1
                        local bandHi = entry.maxLevel or bandLo
                        if not lo or bandLo < lo then
                            lo = bandLo
                        end
                        if not hi or bandHi > hi then
                            hi = bandHi
                        end
                        if levelOk then
                            forLevel = forLevel + 1
                            if entry.suffix and entry.suffix ~= "" then
                                local label = self.GetEntryDisplayName and self:GetEntryDisplayName(entry)
                                suffixNames[label or entry.suffix] = true
                            end
                        end
                    end
                end
            end
        end
    end

    if forClass == 0 then
        return remember("Not ranked for your class.")
    end
    if forSpec == 0 then
        local specName = spec
        if GQ.Spec and GQ.Spec.GetOptions and classFile then
            for _, opt in ipairs(GQ.Spec:GetOptions(classFile) or {}) do
                if opt.id == spec then
                    specName = opt.label
                    break
                end
            end
        end
        return remember("Not ranked for " .. (specName or "your current spec") .. ".")
    end
    if forSide == 0 then
        return remember("Not ranked for your faction.")
    end
    if forLevel == 0 then
        if lo and hi and lo ~= hi then
            return remember(string.format("Not ranked at your level. Ranked from %d to %d.", lo, hi))
        end
        if lo then
            return remember(string.format("Not ranked at your level. Ranked at level %d.", lo))
        end
        return remember("Not ranked at your level.")
    end

    local names = {}
    for label in pairs(suffixNames) do
        names[#names + 1] = label
    end
    table.sort(names)
    if #names == 1 then
        return remember("Only " .. names[1] .. " is ranked for your level.")
    end
    if #names > 1 then
        return remember("Not this roll. Ranked for your level: " .. table.concat(names, ", ") .. ".")
    end
    return remember("Not ranked for your level.")
end

function GQ.Data:HookItemScoreTooltips()
    local function hookClear(tip)
        if not tip or tip.gqScoreClearHooked or not tip.HookScript then
            return
        end
        tip.gqScoreClearHooked = true
        tip:HookScript("OnTooltipCleared", function(self)
            self.gqScoreLineAdded = nil
            self.gqEnchantAdded = nil
        end)
    end

    local hasProcessor = TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall
        and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item

    -- OnTooltipSetItem runs inside the bag button. That taints the button, and
    -- a right-click sell at a vendor is then blocked. The tooltip processor
    -- adds the score line without that. Showing the tooltip from the hook
    -- redraws it during the click and swallows the sell.
    if hasProcessor then
        hookClear(GameTooltip)
        hookClear(ItemRefTooltip)
        if not self._scoreTooltipProcessor then
            self._scoreTooltipProcessor = true
            TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip)
                GQ.Data:AddGearScoreToItemTooltip(tooltip)
            end)
        end
        return
    end

    local function hook(tip)
        if not tip or tip.gqScoreHooked or not tip.HookScript then
            return
        end
        tip.gqScoreHooked = true
        hookClear(tip)
        pcall(tip.HookScript, tip, "OnTooltipSetItem", function(self)
            GQ.Data:AddGearScoreToItemTooltip(self)
        end)
    end
    hook(GameTooltip)
    hook(ItemRefTooltip)
    if not self._scoreTooltipWatcher and CreateFrame then
        local watcher = CreateFrame("Frame")
        watcher:RegisterEvent("PLAYER_LOGIN")
        watcher:SetScript("OnEvent", function()
            GQ.Data:HookItemScoreTooltips()
        end)
        self._scoreTooltipWatcher = watcher
    end
end

GQ.Data:HookItemScoreTooltips()

function GQ.Data:GetRankableEntriesForSlot(slotName)
    slotName = self:NormalizeSlotName(slotName)
    local merged = {}
    local seen = {}

    local function add(entry)
        if not entry or not entry.id or seen[entry.id] then
            return
        end
        seen[entry.id] = true
        merged[#merged + 1] = entry
    end

    for _, entry in ipairs(self:GetCandidatesForSlot(slotName)) do
        add(entry)
    end

    for _, entry in ipairs(self:GetNotableForSlot(slotName)) do
        add(entry)
    end

    return merged
end

function GQ.Data:ClearTopUpgradeCache()
    if self._queryCache and self._queryCache.topUpgrades then
        self._queryCache.topUpgrades = {}
    end
end

-- Runs inside one class/level/faction/spec snapshot (GQ:WithContextSnapshot).
function GQ.Data:GetTopUpgradesForSlot(slotName, maxResults, ignoreWeaponFilter)
    return GQ:WithContextSnapshot(self.BuildTopUpgradesForSlot, self, slotName, maxResults, ignoreWeaponFilter)
end

function GQ.Data:BuildTopUpgradesForSlot(slotName, maxResults, ignoreWeaponFilter)
    slotName = self:NormalizeSlotName(slotName)
    maxResults = maxResults or self:GetMaxUpgradesForSlot(slotName)
    self:EnsureQueryCache()

    local cacheKey = slotName .. ":" .. maxResults .. (ignoreWeaponFilter and ":open" or "")
    local cached = self._queryCache.topUpgrades[cacheKey]
    if cached then
        return cached
    end

    local removedAny = false
    local mains = {}
    local reserves = {}
    for _, entry in ipairs(self:GetCandidatesForSlot(slotName)) do
        if not self:EntryFitsPaperDollSlot(entry, slotName, ignoreWeaponFilter) then
            -- Main-hand-only weapons stay in the log. The Main Hand slot is the
            -- two-hand list, and they cannot be equipped in the off hand.
        elseif GQ.Log and GQ.Log.IsHuntRemoved and GQ.Log:IsHuntRemoved(entry) then
            removedAny = true
        elseif entry.reserve then
            reserves[#reserves + 1] = entry
        else
            mains[#mains + 1] = entry
        end
    end
    local ranked = GQ.Compare:RankEntries(mains, slotName, maxResults)
    if removedAny and #ranked < maxResults and #reserves > 0 then
        local fill = GQ.Compare:RankEntries(reserves, slotName, maxResults - #ranked)
        for i = 1, #fill do
            ranked[#ranked + 1] = fill[i]
        end
    end
    local results = {}
    for i = 1, #ranked do
        results[i] = self:AsMainBiSEntry(ranked[i])
    end
    self._queryCache.topUpgrades[cacheKey] = results
    return results
end

-- Nil when this level, class, and spec have not built the slot yet.
-- Does not build it. Auto-complete on a loot event must not.
function GQ.Data:PeekTopUpgradesForSlot(slotName)
    local cache = self._queryCache
    if not cache or cache.key ~= self:GetQueryCacheKey() or not cache.topUpgrades then
        return nil
    end
    slotName = self:NormalizeSlotName(slotName)
    local maxResults = self:GetMaxUpgradesForSlot(slotName)
    return cache.topUpgrades[slotName .. ":" .. maxResults]
end

function GQ.Data:WarmSlotNames()
    local names = {}
    local seen = {}
    for _, slotName in ipairs(self.BASE_SLOTS) do
        slotName = self:NormalizeSlotName(slotName)
        if not seen[slotName] and self:IsSlotUnlocked(slotName) then
            seen[slotName] = true
            names[#names + 1] = slotName
        end
    end
    local classFile = GQ:GetEffectiveClass()
    if classFile and self.CLASS_RANGED[classFile] and not seen.Ranged then
        names[#names + 1] = "Ranged"
    end
    return names
end

function GQ.Data:IsQueryCacheWarm()
    local cache = self._queryCache
    if not cache or cache.key ~= self:GetQueryCacheKey() then
        return false
    end
    local failed = cache.warmFailed
    for _, slotName in ipairs(self:WarmSlotNames()) do
        if not (failed and failed[slotName]) then
            local candidates = cache.candidates and cache.candidates[slotName]
            if not candidates then
                return false
            end
            local maxResults = self:GetMaxUpgradesForSlot(slotName)
            if #candidates > 0 and not (cache.topUpgrades and cache.topUpgrades[slotName .. ":" .. maxResults]) then
                return false
            end
        end
    end
    return true
end

function GQ.Data:QueryCacheNeedsWarm()
    return not self:IsQueryCacheWarm()
end

local WARM_MAX_PASSES = 3

-- One slot per frame. Building every slot on a ding, or inside a bag event
-- after a dungeon kill, trips a hitch or "script ran too long".
-- gapFrames is extra idle frames after each slot. A ding passes 1 so the
-- level-up frame and the game's own level-up work are not on top of a scan.
function GQ.Data:WarmQueryCacheAsync(onComplete, gapFrames)
    if not (C_Timer and C_Timer.After) or self:IsQueryCacheWarm() then
        if onComplete then
            onComplete()
        end
        return
    end

    gapFrames = tonumber(gapFrames) or 0
    if gapFrames < 0 then
        gapFrames = 0
    end

    self._warmCallbacks = self._warmCallbacks or {}
    if onComplete then
        self._warmCallbacks[#self._warmCallbacks + 1] = onComplete
    end
    if self._warmRunning then
        if gapFrames > (self._warmGap or 0) then
            self._warmGap = gapFrames
        end
        return
    end
    self._warmRunning = true
    self._warmGap = gapFrames

    local slots = {}
    local index = 0
    local passes = 0
    local gapLeft = 0
    local function finish()
        self._warmRunning = false
        self._warmGap = nil
        local callbacks = self._warmCallbacks or {}
        self._warmCallbacks = nil
        for i = 1, #callbacks do
            local ok, err = pcall(callbacks[i])
            if not ok and geterrorhandler then
                geterrorhandler()(err)
            end
        end
    end
    local function step()
        if gapLeft > 0 then
            gapLeft = gapLeft - 1
            C_Timer.After(0, step)
            return
        end
        if index >= #slots then
            -- A talent or preview change mid-warm swaps the cache key. Go
            -- round again; slots already built come straight from the cache.
            if self:IsQueryCacheWarm() or passes >= WARM_MAX_PASSES then
                finish()
                return
            end
            passes = passes + 1
            slots = self:WarmSlotNames()
            index = 0
        end
        index = index + 1
        local slotName = slots[index]
        if slotName then
            local built = pcall(function()
                if #self:GetCandidatesForSlot(slotName) > 0 then
                    self:GetTopUpgradesForSlot(slotName)
                end
            end)
            if not built and self._queryCache and self._queryCache.key == self:GetQueryCacheKey() then
                self._queryCache.warmFailed = self._queryCache.warmFailed or {}
                self._queryCache.warmFailed[slotName] = true
            end
            gapLeft = self._warmGap or 0
        end
        C_Timer.After(0, step)
    end
    C_Timer.After(0, step)
end

function GQ.Data:GetWeaponRouteForBand()
    for _, slot in ipairs({ "MainHand", "SecondaryHand" }) do
        for _, entry in ipairs(self:GetCandidatesForSlot(slot)) do
            if entry.route then
                return entry.route
            end
        end
    end
    return nil
end

local SHIELD_SPECS = {
    PALADIN = { protection = true, holy = true, shockadin = true },
    WARRIOR = { protection = true },
    SHAMAN = { elemental = true, restoration = true, enhancement_tank = true },
}

local DUAL_WIELD_SPECS = {
    HUNTER = { beast_mastery = true, marksmanship = true, survival = true },
    ROGUE = { combat = true, assassination = true, subtlety = true },
    WARRIOR = { fury = true },
}

local TWO_HAND_SPECS = {
    PALADIN = { retribution = true },
    WARRIOR = { arms = true },
}

-- Hunter: Two-hand on the Main Hand slot, either-hand weapons on the Off Hand
-- slot. A main-hand weapon (tooltip "Main Hand") is one-handed but cannot go
-- in the off hand, so it stays in the log and on neither paper-doll slot.
-- Enhancement: two-handers only.
function GQ.Data:RuleSpec()
    local spec = GQ.GetEffectiveSpec and GQ:GetEffectiveSpec()
    if GQ.Spec and GQ.Spec.GetRuleSpec then
        return GQ.Spec:GetRuleSpec(spec)
    end
    return spec
end

function GQ.Data:UsesHunterWeaponPairs()
    local classFile = GQ.GetEffectiveClass and GQ:GetEffectiveClass()
    return classFile == "HUNTER"
end

function GQ.Data:UsesRogueWeaponHands()
    local classFile = GQ.GetEffectiveClass and GQ:GetEffectiveClass()
    return classFile == "ROGUE"
end

function GQ.Data:UsesTwoHandOnlyWeapons()
    local classFile = GQ.GetEffectiveClass and GQ:GetEffectiveClass()
    local spec = GQ.GetEffectiveSpec and GQ:GetEffectiveSpec()
    return classFile == "SHAMAN" and spec == "enhancement"
end

function GQ.Data:PairsWeaponWithOffHand()
    local classFile = GQ.GetEffectiveClass and GQ:GetEffectiveClass()
    local spec = self.RuleSpec and self:RuleSpec() or (GQ.GetEffectiveSpec and GQ:GetEffectiveSpec())
    if classFile == "PRIEST" or classFile == "MAGE" or classFile == "WARLOCK" then
        return true
    end
    if classFile == "DRUID" and spec ~= "feral" then
        return true
    end
    if classFile == "SHAMAN" and (spec == "elemental" or spec == "restoration") then
        return true
    end
    return false
end

function GQ.Data:UsesBothWeaponStyles()
    local classFile = GQ.GetEffectiveClass and GQ:GetEffectiveClass()
    local spec = GQ.GetEffectiveSpec and GQ:GetEffectiveSpec()
    -- A staff or other two-hander and a one-hander are both worn, so the
    -- one-hander that pairs with the off-hand starts on beside the staff.
    if classFile == "SHAMAN" and (spec == "elemental" or spec == "restoration") then
        return true
    end
    if classFile == "PALADIN" and (spec == "holy" or spec == "shockadin") then
        return true
    end
    if classFile == "PRIEST" or classFile == "MAGE" or classFile == "WARLOCK" then
        return true
    end
    if classFile == "DRUID" and spec ~= "feral" then
        return true
    end
    return false
end

function GQ.Data:EntryIsMainHandOnly(entry)
    if not entry then
        return false
    end
    if entry.hand == "main" then
        return true
    end
    if entry.hand == "two" or entry.hand == "one" then
        return false
    end
    if entry.itemId and GetItemInfo then
        local equipLoc = select(9, GetItemInfo(entry.itemId))
        return equipLoc == "INVTYPE_WEAPONMAINHAND"
    end
    return false
end

function GQ.Data:EntryIsEitherHand(entry)
    if not entry then
        return false
    end
    if entry.hand == "one" then
        return true
    end
    if entry.hand == "main" or entry.hand == "two" or entry.hand == "off" then
        return false
    end
    if entry.itemId and GetItemInfo then
        local equipLoc = select(9, GetItemInfo(entry.itemId))
        return equipLoc == "INVTYPE_WEAPON"
    end
    return false
end

function GQ.Data:EntryIsOffHandOnly(entry)
    if not entry then
        return false
    end
    if entry.hand == "off" then
        return true
    end
    if entry.hand == "main" or entry.hand == "two" or entry.hand == "one" then
        return false
    end
    if entry.itemId and GetItemInfo then
        local equipLoc = select(9, GetItemInfo(entry.itemId))
        return equipLoc == "INVTYPE_WEAPONOFFHAND"
    end
    return false
end

function GQ.Data:EntryFitsPaperDollSlot(entry, slotName, ignoreWeaponFilter)
    slotName = self:NormalizeSlotName(slotName)
    local function allow(ok)
        if not ok then
            return false
        end
        if ignoreWeaponFilter or not (GQ.Log and GQ.Log.WeaponStyleEnabled and GQ.Log.WeaponTypeAllowed) then
            return true
        end
        local hand = "main"
        if self:EntryIsTwoHand(entry) then
            hand = "two"
        elseif slotName == "SecondaryHand" then
            hand = "off"
        end
        if not GQ.Log:WeaponStyleEnabled(hand) or not GQ.Log:WeaponTypeAllowed(entry, hand) then
            return false
        end
        return true
    end
    if self:UsesTwoHandOnlyWeapons() then
        if slotName == "SecondaryHand" then
            return false
        end
        if slotName == "MainHand" then
            return allow(self:EntryIsTwoHand(entry))
        end
    end
    if self:UsesHunterWeaponPairs() then
        if slotName == "MainHand" then
            return allow(self:EntryIsTwoHand(entry))
        end
        if slotName == "SecondaryHand" then
            -- The off-hand character panel bar is one-handers only.
            return allow(self:EntryIsEitherHand(entry))
        end
    end
    if self:UsesRogueWeaponHands() then
        if slotName == "MainHand" then
            -- A One-Hand weapon can be worn in the main hand. Main-hand-only
            -- stays here. Off-hand-only stays on the off-hand slot.
            return allow(self:EntryIsMainHandOnly(entry) or self:EntryIsEitherHand(entry))
        end
        if slotName == "SecondaryHand" then
            return allow(self:EntryIsEitherHand(entry) or self:EntryIsOffHandOnly(entry))
        end
    end
    if slotName == "Ranged" then
        local classFile = GQ.GetEffectiveClass and GQ:GetEffectiveClass()
        if classFile == "HUNTER" and not ignoreWeaponFilter and GQ.Log and GQ.Log.RangedPassesFilter then
            return GQ.Log:RangedPassesFilter(entry)
        end
        return true
    end
    if slotName ~= "MainHand" and slotName ~= "SecondaryHand" then
        return true
    end
    if not self:EntryIsDamagingWeapon(entry) then
        -- Shields and held items stay on the off-hand slot.
        return slotName == "SecondaryHand"
    end
    -- The paper doll and the popup follow the weapon filter. Bag arrows pass
    -- ignoreWeaponFilter so the unfiltered best still gets an arrow.
    if not ignoreWeaponFilter and GQ.Log and GQ.Log.WeaponStyleEnabled and GQ.Log.WeaponTypeAllowed then
        local hand = self:EntryIsTwoHand(entry) and "two" or (slotName == "SecondaryHand" and "off" or "main")
        if not GQ.Log:WeaponStyleEnabled(hand) or not GQ.Log:WeaponTypeAllowed(entry, hand) then
            return false
        end
    end
    local style = self:EntryIsTwoHand(entry) and "two" or "one"
    return self:WeaponFitsPaperSlot(entry, slotName, style)
end

function GQ.Data:EntryIsTwoHand(entry)
    if not entry then
        return false
    end
    if entry.hand == "two" then
        return true
    end
    if entry.hand == "main" or entry.hand == "one" then
        return false
    end
    if entry.itemId and GQ.Equip and GQ.Equip.IsTwoHandWeapon then
        return GQ.Equip:IsTwoHandWeapon(entry.itemId) and true or false
    end
    return false
end

function GQ.Data:TopUniqueEntries(entries, maxCount)
    maxCount = maxCount or 3
    table.sort(entries, function(a, b)
        local rankA = a.curatedRank or 99
        local rankB = b.curatedRank or 99
        if rankA ~= rankB then
            return rankA < rankB
        end
        return (a.pipelineScore or 0) > (b.pipelineScore or 0)
    end)
    local out = {}
    local seen = {}
    for i = 1, #entries do
        local entry = entries[i]
        local name = self.GetEntryDisplayName and self:GetEntryDisplayName(entry) or ""
        if name ~= "" and not seen[name] then
            seen[name] = true
            out[#out + 1] = entry
            if #out >= maxCount then
                break
            end
        end
    end
    return out
end

function GQ.Data:WeaponHeaderSuffix(slotName)
    local classFile = GQ:GetEffectiveClass()
    local spec = self:RuleSpec()
    local shield = SHIELD_SPECS[classFile]
    if shield and shield[spec] then
        if slotName == "SecondaryHand" then
            return "Shield"
        end
        return nil
    end
    if classFile == "HUNTER" then
        if slotName == "MainHand" then
            return "Two-hand or dual wield"
        end
        return nil
    end
    local dual = DUAL_WIELD_SPECS[classFile]
    if dual and dual[spec] then
        if slotName == "MainHand" then
            return "Dual wield"
        end
        return nil
    end
    local twoHand = TWO_HAND_SPECS[classFile]
    if twoHand and twoHand[spec] then
        if slotName == "MainHand" then
            return "Two-hand"
        end
        return nil
    end
    if classFile == "SHAMAN" and spec == "enhancement" then
        if slotName == "MainHand" then
            return "Two-hand or main hand"
        end
        return nil
    end
    if classFile == "MAGE" or classFile == "PRIEST" or classFile == "WARLOCK" then
        if slotName == "MainHand" then
            return "Staff or main hand"
        end
        return nil
    end
    if classFile == "DRUID" then
        if slotName == "MainHand" then
            return "Two-hand or main hand"
        end
        return nil
    end
    if slotName == "MainHand" and self:GetWeaponRouteForBand() then
        return "Two-hand or main hand"
    end
    return nil
end

-- Hunters, rogues, and fury warriors can put a damaging weapon in the off hand.
-- Shamans cannot dual wield. A shield spec still uses the off-hand slot for a shield.
function GQ.Data:CanDualWield()
    local classFile = GQ.GetEffectiveClass and GQ:GetEffectiveClass()
    local spec = self:RuleSpec()
    if classFile == "SHAMAN" then
        return false
    end
    if classFile == "HUNTER" or classFile == "ROGUE" then
        return true
    end
    local dual = DUAL_WIELD_SPECS[classFile]
    return dual and spec and dual[spec] and true or false
end

function GQ.Data:DefaultWeaponStyle()
    local classFile = GQ.GetEffectiveClass and GQ:GetEffectiveClass()
    local spec = self:RuleSpec()
    if classFile == "HUNTER" then
        return "two"
    end
    if classFile == "SHAMAN" and spec == "enhancement" then
        return "two"
    end
    if classFile == "SHAMAN" then
        return "one"
    end
    if classFile == "DRUID" and spec == "feral" then
        return "two"
    end
    local two = TWO_HAND_SPECS[classFile]
    if two and spec and two[spec] then
        return "two"
    end
    return "one"
end

function GQ.Data:OffHandShowsShieldOrHeld()
    local classFile = GQ.GetEffectiveClass and GQ:GetEffectiveClass()
    local spec = GQ.GetEffectiveSpec and GQ:GetEffectiveSpec()
    local shield = classFile and SHIELD_SPECS[classFile]
    if shield and spec and shield[spec] then
        return true
    end
    if classFile == "MAGE" or classFile == "PRIEST" or classFile == "WARLOCK" then
        return true
    end
    if classFile == "DRUID" and spec ~= "feral" then
        return true
    end
    return false
end

local WEAPON_TYPE_LINES = {
    ["Dagger"] = "Dagger",
    ["Sword"] = "Sword",
    ["Mace"] = "Mace",
    ["Axe"] = "Axe",
    ["Fist Weapon"] = "Fist",
    ["Polearm"] = "Polearm",
    ["Staff"] = "Staff",
}

-- Some Forever tips put the hand and the type on one line:
-- "Binds when equippedOne-HandMace", "Main HandAxe", "Two-HandSword".
local WEAPON_TYPE_MARKS = {
    { "Fist Weapon", "Fist" },
    { "Polearm", "Polearm" },
    { "Dagger", "Dagger" },
    { "Sword", "Sword" },
    { "Mace", "Mace" },
    { "Axe", "Axe" },
    { "Staff", "Staff" },
}

local NOT_A_WEAPON_LINE = {
    ["Shield"] = true,
    ["Held In Off-hand"] = true,
    ["Fishing Pole"] = true,
    ["Libram"] = true,
    ["Totem"] = true,
    ["Idol"] = true,
    ["Wand"] = true,
    ["Bow"] = true,
    ["Gun"] = true,
    ["Crossbow"] = true,
    ["Thrown"] = true,
}

local RANGED_TYPE_LINES = {
    ["Crossbow"] = "Crossbow",
    ["Bow"] = "Bow",
    ["Gun"] = "Gun",
}
local RANGED_TYPE_MARKS = {
    { "Crossbow", "Crossbow" },
    { "Bow", "Bow" },
    { "Gun", "Gun" },
}

function GQ.Data:RangedTypeOf(entry)
    if not entry or not entry.itemId then
        return nil
    end
    self._rangedTypeById = self._rangedTypeById or {}
    local cached = self._rangedTypeById[entry.itemId]
    if cached ~= nil then
        if cached == "" then
            return nil
        end
        return cached
    end
    local found = ""
    local audit = self.GetForeverAudit and self:GetForeverAudit(entry.itemId)
    local tip = audit and audit.tip or ""
    if tip ~= "" then
        local head = tip
        local damageAt = string.find(string.lower(tip), "damage", 1, true)
        if damageAt and damageAt > 1 then
            head = string.sub(tip, 1, damageAt - 1)
        end
        for line in string.gmatch(head, "[^\n]+") do
            local mapped = RANGED_TYPE_LINES[line]
            if mapped then
                found = mapped
                break
            end
        end
        if found == "" then
            for i = 1, #RANGED_TYPE_MARKS do
                local mark = RANGED_TYPE_MARKS[i]
                if string.find(head, mark[1], 1, true) then
                    found = mark[2]
                    break
                end
            end
        end
    end
    self._rangedTypeById[entry.itemId] = found
    if found == "" then
        return nil
    end
    return found
end

function GQ.Data:WeaponTypeOf(entry)
    if not entry or not entry.itemId then
        return nil
    end
    self._weaponTypeById = self._weaponTypeById or {}
    local cached = self._weaponTypeById[entry.itemId]
    if cached ~= nil then
        if cached == "" then
            return nil
        end
        return cached
    end
    local found = ""
    local audit = self.GetForeverAudit and self:GetForeverAudit(entry.itemId)
    local tip = audit and audit.tip or ""
    if tip ~= "" then
        local head = tip
        local damageAt = string.find(string.lower(tip), "damage", 1, true)
        if damageAt and damageAt > 1 then
            head = string.sub(tip, 1, damageAt - 1)
        end
        for line in string.gmatch(head, "[^\n]+") do
            local mapped = WEAPON_TYPE_LINES[line]
            if mapped then
                found = mapped
                break
            end
        end
        if found == "" then
            for i = 1, #WEAPON_TYPE_MARKS do
                local mark = WEAPON_TYPE_MARKS[i]
                if string.find(head, mark[1], 1, true) then
                    found = mark[2]
                    break
                end
            end
        end
    end
    self._weaponTypeById[entry.itemId] = found
    if found == "" then
        return nil
    end
    return found
end

function GQ.Data:EntryIsDamagingWeapon(entry)
    if not entry or not entry.itemId then
        return false
    end
    self._damagingWeapon = self._damagingWeapon or {}
    local cached = self._damagingWeapon[entry.itemId]
    if cached ~= nil then
        return cached
    end
    local slot = self:NormalizeSlotName(entry.slot)
    local result = false
    if slot == "MainHand" or slot == "SecondaryHand" then
        local audit = self.GetForeverAudit and self:GetForeverAudit(entry.itemId)
        local tip = audit and audit.tip or ""
        local blocked = false
        local hasDps = false
        if tip ~= "" then
            local lower = string.lower(tip)
            hasDps = string.find(lower, "damage per second", 1, true) ~= nil
            for line in string.gmatch(tip, "[^\n]+") do
                if NOT_A_WEAPON_LINE[line] then
                    blocked = true
                    break
                end
            end
        end
        if not blocked then
            local hand = entry.hand
            if hand == "two" or hand == "main" or hand == "one" or hand == "off" then
                result = tip == "" or hasDps
            elseif slot == "MainHand" and (tip == "" or hasDps) then
                result = true
            end
        end
    end
    self._damagingWeapon[entry.itemId] = result
    return result
end

-- Hands a weapon can be worn in. For a dual-wield spec, a One-Hand weapon
-- belongs to both Main Hand and Off Hand, so each hand can turn that type
-- off on its own. Main-hand-only stays out of Off Hand. Off-hand-only stays
-- out of Main Hand. A spec that cannot dual wield has no Off Hand, and Main
-- Hand keeps the one-handers.
function GQ.Data:WeaponCanEquipHand(entry, hand)
    if hand ~= "two" and hand ~= "main" and hand ~= "off" then
        return false
    end
    if not entry or not self:EntryIsDamagingWeapon(entry) then
        return false
    end
    if hand == "two" then
        return self:EntryIsTwoHand(entry)
    end
    if self:EntryIsTwoHand(entry) or self:UsesTwoHandOnlyWeapons() then
        return false
    end
    local offOnly = entry.hand == "off" or self:EntryIsOffHandOnly(entry)
    local mainOnly = entry.hand == "main" or (entry.hand ~= "off" and entry.hand ~= "one" and self:EntryIsMainHandOnly(entry))
    if entry.hand == "one" then
        mainOnly = false
        offOnly = false
    end
    if hand == "off" then
        if not self:CanDualWield() then
            return false
        end
        return not mainOnly
    end
    return not offOnly
end

-- Tooltip split kept for style checks. The menu and the hunt use
-- WeaponCanEquipHand, so a One-Hand weapon is listed under both hands.
function GQ.Data:WeaponFitsFilterHand(entry, hand)
    if hand ~= "two" and hand ~= "main" and hand ~= "off" then
        return false
    end
    if not entry or not self:EntryIsDamagingWeapon(entry) then
        return false
    end
    if hand == "two" then
        return self:EntryIsTwoHand(entry)
    end
    if self:EntryIsTwoHand(entry) or self:UsesTwoHandOnlyWeapons() then
        return false
    end
    local offOnly = entry.hand == "off" or self:EntryIsOffHandOnly(entry)
    local mainOnly = entry.hand == "main" or (entry.hand ~= "off" and entry.hand ~= "one" and self:EntryIsMainHandOnly(entry))
    if entry.hand == "one" then
        mainOnly = false
        offOnly = false
    end
    if hand == "off" then
        if not self:CanDualWield() then
            return false
        end
        return not mainOnly
    end
    if self:CanDualWield() then
        return mainOnly
    end
    return not offOnly
end

function GQ.Data:WeaponFitsStyle(entry, style)
    if not entry then
        return false
    end
    if style == "main" or style == "off" then
        return self:WeaponFitsFilterHand(entry, style)
    end
    local two = self:EntryIsTwoHand(entry)
    if style == "two" then
        return two
    end
    return not two
end

function GQ.Data:WeaponFitsPaperSlot(entry, slotName, style)
    if not self:WeaponFitsStyle(entry, style) then
        return false
    end
    if style == "two" then
        return slotName == "MainHand"
    end
    local offOnly = entry.hand == "off" or self:EntryIsOffHandOnly(entry)
    local mainOnly = entry.hand == "main" or (entry.hand ~= "off" and entry.hand ~= "one" and self:EntryIsMainHandOnly(entry))
    if entry.hand == "one" then
        mainOnly = false
        offOnly = false
    end
    if slotName == "MainHand" then
        return not offOnly
    end
    if slotName == "SecondaryHand" then
        if not self:CanDualWield() then
            return false
        end
        return not mainOnly
    end
    return false
end

function GQ.Data:EntryOffWeaponRoute(entry, slotName)
    if not entry or not entry.route then
        return false
    end
    slotName = self:NormalizeSlotName(slotName)
    if entry.route == "twohand" then
        return slotName == "SecondaryHand"
    end
    if entry.route == "onehand" and slotName == "MainHand" and GQ.Equip then
        return GQ.Equip:IsTwoHandWeapon(entry.itemId)
    end
    return false
end

function GQ.Data:SlotHeaderLabel(slotName)
    slotName = self:NormalizeSlotName(slotName)
    local label = self:SlotLabel(slotName)
    local routeLabel = self:WeaponHeaderSuffix(slotName)
    if routeLabel then
        if slotName == "Ranged" then
            return routeLabel
        end
        return label .. " — " .. routeLabel
    end
    return label
end

function GQ.Data:SlotLabel(slotName)
    slotName = self:NormalizeSlotName(slotName)
    if slotName == "Ranged" then
        local classFile = GQ:GetEffectiveClass()
        if classFile == "SHAMAN" then
            return "Totem"
        end
        if classFile == "DRUID" then
            return "Idol"
        end
        if classFile == "PALADIN" then
            return "Relic"
        end
        if classFile == "MAGE" or classFile == "PRIEST" or classFile == "WARLOCK" then
            return "Wand"
        end
    end
    return self.SLOT_LABELS[slotName] or slotName
end
