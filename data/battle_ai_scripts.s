#include "config.h"
#include "constants/battle.h"
#include "constants/battle_ai.h"
#include "constants/abilities.h"
#include "constants/items.h"
#include "constants/moves.h"
#include "constants/battle_move_effects.h"
#include "constants/hold_effects.h"
#include "constants/pokemon.h"
	.include "asm/macros.inc"
	.include "asm/macros/battle_ai_script.inc"
	.include "constants/constants.inc"

	.section script_data, "aw", %progbits

	.align 2
gBattleAI_ScriptsTable::
	.4byte AI_CheckBadMove          @ AI_SCRIPT_CHECK_BAD_MOVE
	.4byte AI_TryToFaint            @ AI_SCRIPT_TRY_TO_FAINT
	.4byte AI_CheckViability        @ AI_SCRIPT_CHECK_VIABILITY
	.4byte AI_SetupFirstTurn        @ AI_SCRIPT_SETUP_FIRST_TURN
	.4byte AI_Risky                 @ AI_SCRIPT_RISKY
	.4byte AI_PreferPowerExtremes   @ AI_SCRIPT_PREFER_POWER_EXTREMES
	.4byte AI_PreferBatonPass       @ AI_SCRIPT_PREFER_BATON_PASS
	.4byte AI_DoubleBattle 	        @ AI_SCRIPT_DOUBLE_BATTLE
	.4byte AI_HPAware               @ AI_SCRIPT_HP_AWARE
	.4byte AI_TrySunnyDayStart      @ AI_SCRIPT_TRY_SUNNY_DAY_START
	.4byte AI_End
	.4byte AI_End
	.4byte AI_End
	.4byte AI_End
	.4byte AI_End
	.4byte AI_End
	.4byte AI_End
	.4byte AI_End
	.4byte AI_End
	.4byte AI_End
	.4byte AI_End
	.4byte AI_End
	.4byte AI_End
	.4byte AI_End
	.4byte AI_End
	.4byte AI_End
	.4byte AI_End
	.4byte AI_End
	.4byte AI_End
	.4byte AI_Roaming               @ AI_SCRIPT_ROAMING
	.4byte AI_Safari                @ AI_SCRIPT_SAFARI
	.4byte AI_FirstBattle           @ AI_SCRIPT_FIRST_BATTLE

AI_CheckBadMove:
	if_target_is_ally AI_End
	if_status2 AI_TARGET, STATUS2_SUBSTITUTE, AI_CBM_VS_Substitute
	goto AI_CBM_CheckImmunities_PreCheck

AI_CBM_VS_Substitute:
	get_considered_move_power
	if_equal 0, AI_CBM_VS_Substitute_CheckTarget
	if_effect EFFECT_DREAM_EATER | EFFECT_EXPLOSION | EFFECT_TRAP, AI_CBM_SubstituteBlocks
	if_effect EFFECT_CURSE, AI_CBM_VS_Substitute_CurseTypeCheck
	goto AI_CBM_CheckImmunities

AI_CBM_VS_Substitute_CurseTypeCheck:
	get_user_type1
	if_equal TYPE_GHOST, AI_CBM_SubstituteBlocks
	get_user_type2
	if_equal TYPE_GHOST, AI_CBM_SubstituteBlocks
	goto AI_CheckBadMove_CheckEffect

AI_CBM_VS_Substitute_CheckTarget:
	if_target MOVE_TARGET_SELECTED, AI_CBM_VS_Substitute_CheckEffect
	goto CheckSoundproof

AI_CBM_VS_Substitute_CheckEffect:
	if_effect EFFECT_ROAR, AI_CBM_CheckSoundproof
	if_effect EFFECT_ATTRACT | EFFECT_DISABLE | EFFECT_ENCORE | EFFECT_FORESIGHT | EFFECT_HAZE | EFFECT_MEAN_LOOK | EFFECT_PSYCH_UP | EFFECT_ROLE_PLAY | EFFECT_SKILL_SWAP | EFFECT_SPITE | EFFECT_TAUNT | EFFECT_TORMENT | EFFECT_TRANSFORM, AI_CheckBadMove_CheckEffect
AI_CBM_SubstituteBlocks:
	score -10
AI_CBM_CheckImmunities_PreCheck:
	get_considered_move_power
	if_equal 0, CheckSoundproof
AI_CBM_CheckImmunities:
	if_type_effectiveness AI_EFFECTIVENESS_x0, Score_Minus30
	get_ability AI_TARGET
	if_equal ABILITY_VOLT_ABSORB, CheckIfVoltAbsorbCancelsElectric
	if_equal ABILITY_WATER_ABSORB, CheckIfWaterAbsorbCancelsWater
	if_equal ABILITY_FLASH_FIRE, CheckIfFlashFireCancelsFire
	if_equal ABILITY_WONDER_GUARD, CheckIfWonderGuardCancelsMove
	if_equal ABILITY_LEVITATE, CheckIfLevitateCancelsGroundMove
	goto AI_CBM_TestWhetherToTypeMatchup

CheckIfVoltAbsorbCancelsElectric:
	get_curr_move_type
	if_equal_ TYPE_ELECTRIC, Score_Minus30
	goto AI_CBM_TestWhetherToTypeMatchup

CheckIfWaterAbsorbCancelsWater:
	get_curr_move_type
	if_equal_ TYPE_WATER, Score_Minus30
	goto AI_CBM_TestWhetherToTypeMatchup

CheckIfFlashFireCancelsFire:
	get_curr_move_type
	if_equal_ TYPE_FIRE, Score_Minus30
	goto AI_CBM_TestWhetherToTypeMatchup

CheckIfWonderGuardCancelsMove:
	if_type_effectiveness AI_EFFECTIVENESS_x2, AI_CBM_TestWhetherToTypeMatchup
	goto Score_Minus30

CheckIfLevitateCancelsGroundMove:
	get_curr_move_type
	if_equal_ TYPE_GROUND, Score_Minus30
	goto AI_CBM_TestWhetherToTypeMatchup

AI_CBM_TestWhetherToTypeMatchup:
	if_effect EFFECT_BIDE | EFFECT_COUNTER | EFFECT_ENDEAVOR | EFFECT_FAKE_OUT | EFFECT_LEVEL_DAMAGE| EFFECT_MIRROR_COAT | EFFECT_OHKO | EFFECT_RAPID_SPIN | EFFECT_SUPER_FANG | EFFECT_TRAP, AI_CBM_CheckSoundproof
	if_effect EFFECT_PARALYZE_HIT | EFFECT_POISON_FANG | EFFECT_POISON_HIT | EFFECT_SECRET_POWER, AI_CBM_TestWhetherToTypeMatchup_Status
	if_effect EFFECT_KNOCK_OFF | EFFECT_THIEF, AI_CBM_TestWhetherToTypeMatchup_ItemCheck
	if_effect EFFECT_SPEED_DOWN_HIT, AI_CBM_TestWhetherToTypeMatchup_Speed
	goto AI_CBM_TypeMatchup_Modifiers

AI_CBM_TestWhetherToTypeMatchup_Status:
	if_status AI_TARGET, STATUS1_ANY, AI_CBM_TypeMatchup_Modifiers
	get_considered_move_second_eff_chance
	if_less_than 25, AI_CBM_TypeMatchup_Modifiers
	goto CheckSoundproof

AI_CBM_TestWhetherToTypeMatchup_ItemCheck:
	get_ability AI_TARGET
	if_equal ABILITY_STICKY_HOLD, AI_CBM_TypeMatchup_Modifiers
	get_hold_effect AI_TARGET
	if_not_in_bytes AI_CV_Thief_EncourageItemsToSteal, AI_CBM_TypeMatchup_Modifiers
	goto CheckSoundproof

AI_CBM_TestWhetherToTypeMatchup_Speed:
	get_ability AI_TARGET
	if_equal ABILITY_CLEAR_BODY | ABILITY_SHIELD_DUST | ABILITY_SPEED_BOOST | ABILITY_WHITE_SMOKE, AI_CBM_TypeMatchup_Modifiers
	if_side_affecting AI_TARGET, SIDE_STATUS_MIST, AI_CBM_TypeMatchup_Modifiers
	if_target_faster CheckSoundproof
AI_CBM_TypeMatchup_Modifiers:
	get_curr_move_type
	if_equal TYPE_BUG | TYPE_FIGHTING | TYPE_FLYING | TYPE_GHOST | TYPE_GROUND | TYPE_NORMAL | TYPE_POISON | TYPE_ROCK | TYPE_STEEL, AI_CBM_TypeMatchup_Reflect
	if_equal TYPE_DARK | TYPE_DRAGON | TYPE_GRASS | TYPE_PSYCHIC, AI_CBM_TypeMatchup_LS
	if_equal TYPE_ELECTRIC, AI_CBM_TypeMatchup_MudSport
	if_equal TYPE_FIRE, AI_CBM_TypeMatchup_WaterSport
	if_equal TYPE_ICE, AI_CBM_TypeMatchup_ThickFat
	if_equal TYPE_WATER, AI_CBM_TypeMatchup_Weather_Water
	goto AI_CBM_TypeMatchup_LS

AI_CBM_TypeMatchup_Reflect:
	if_side_affecting AI_TARGET, SIDE_STATUS_REFLECT, AI_CBM_TypeMatchup_HalfDmg
	goto AI_CBM_TypeMatchup

AI_CBM_TypeMatchup_WaterSport:
	if_status3 AI_TARGET, STATUS3_WATERSPORT, AI_CBM_TypeMatchup_ThickFat_Fire_HalfDmg
	goto AI_CBM_TypeMatchup_ThickFat_Fire

AI_CBM_TypeMatchup_ThickFat_Fire:
	get_ability AI_TARGET
	if_equal ABILITY_THICK_FAT, AI_CBM_TypeMatchup_Weather_Fire_HalfDmg
	goto AI_CBM_TypeMatchup_Weather_Fire

AI_CBM_TypeMatchup_ThickFat_Fire_HalfDmg:
	get_ability AI_TARGET
	if_equal ABILITY_THICK_FAT, AI_CBM_TypeMatchup_Weather_Fire_HalfDmg
	goto AI_CBM_TypeMatchup_Weather_Fire_HalfDmg

AI_CBM_TypeMatchup_Weather_Fire:
	get_weather
	if_equal AI_WEATHER_SUN, AI_CBM_TypeMatchup_LS_DoubleDmg
	if_equal AI_WEATHER_RAIN, AI_CBM_TypeMatchup_LS_HalfDmg
	goto AI_CBM_TypeMatchup_LS

AI_CBM_TypeMatchup_Weather_Fire_HalfDmg:
	get_weather
	if_equal AI_WEATHER_SUN, AI_CBM_TypeMatchup_LS
	if_equal AI_WEATHER_RAIN, AI_CBM_TypeMatchup_LS_QuarterDmg
	goto AI_CBM_TypeMatchup_LS_HalfDmg

AI_CBM_TypeMatchup_Weather_Fire_QuarterDmg:
	get_weather
	if_equal AI_WEATHER_SUN, AI_CBM_TypeMatchup_LS_HalfDmg
	if_equal AI_WEATHER_RAIN, AI_CBM_TypeMatchup_LS_EighthDmg
	goto AI_CBM_TypeMatchup_LS_QuarterDmg

AI_CBM_TypeMatchup_Weather_Water:
	get_weather
	if_equal AI_WEATHER_SUN, AI_CBM_TypeMatchup_LS_HalfDmg
	if_equal AI_WEATHER_RAIN, AI_CBM_TypeMatchup_LS_DoubleDmg
	goto AI_CBM_TypeMatchup_LS

AI_CBM_TypeMatchup_ThickFat:
	get_ability AI_TARGET
	if_equal ABILITY_THICK_FAT, AI_CBM_TypeMatchup_LS_HalfDmg
	goto AI_CBM_TypeMatchup_LS

AI_CBM_TypeMatchup_MudSport:
	if_status3 AI_TARGET, STATUS3_MUDSPORT, AI_CBM_TypeMatchup_LS_HalfDmg
AI_CBM_TypeMatchup_LS:
	if_side_affecting AI_TARGET, SIDE_STATUS_LIGHTSCREEN, AI_CBM_TypeMatchup_HalfDmg
	goto AI_CBM_TypeMatchup

AI_CBM_TypeMatchup_LS_DoubleDmg:
	if_side_affecting AI_TARGET, SIDE_STATUS_LIGHTSCREEN, AI_CBM_TypeMatchup
	goto AI_CBM_TypeMatchup_DoubleDmg

AI_CBM_TypeMatchup_LS_HalfDmg:
	if_side_affecting AI_TARGET, SIDE_STATUS_LIGHTSCREEN, AI_CBM_TypeMatchup_QuarterDmg
	goto AI_CBM_TypeMatchup_HalfDmg

AI_CBM_TypeMatchup_LS_QuarterDmg:
	if_side_affecting AI_TARGET, SIDE_STATUS_LIGHTSCREEN, AI_CBM_TypeMatchup_LS_EighthDmg
	goto AI_CBM_TypeMatchup_QuarterDmg

AI_CBM_TypeMatchup_LS_EighthDmg:
	if_side_affecting AI_TARGET, SIDE_STATUS_LIGHTSCREEN, AI_CBM_TypeMatchup_OneSixteenthDmg
	goto AI_CBM_TypeMatchup_LS_EighthDmg

AI_CBM_TypeMatchup_OneSixteenthDmg:
	count_usable_party_mons AI_USER
	if_equal 0, AI_CBM_TypeMatchup_OneSixteenthDmg_LastMon
	goto AI_CBM_TypeMatchup_Minus30

AI_CBM_TypeMatchup_OneSixteenthDmg_LastMon:
	if_type_effectiveness AI_EFFECTIVENESS_x4, AI_CBM_TypeMatchup_Minus3
	if_type_effectiveness AI_EFFECTIVENESS_x2, AI_CBM_TypeMatchup_Minus5
	goto AI_CBM_TypeMatchup_Minus30

AI_CBM_TypeMatchup_OneEighthDmg:
	if_type_effectiveness AI_EFFECTIVENESS_x4, AI_CBM_TypeMatchup_Minus1
	count_usable_party_mons AI_USER
	if_equal 0, AI_CBM_TypeMatchup_OneEighthDmg_LastMon
	goto AI_CBM_TypeMatchup_Minus30

AI_CBM_TypeMatchup_OneEighthDmg_LastMon:
	if_type_effectiveness AI_EFFECTIVENESS_x2, AI_CBM_TypeMatchup_Minus3
	goto AI_CBM_TypeMatchup_Minus5

AI_CBM_TypeMatchup_QuarterDmg:
	count_usable_party_mons AI_USER
	if_equal 0, AI_CBM_TypeMatchup_QuarterDmg_LastMon
	if_type_effectiveness AI_EFFECTIVENESS_x4, AI_CBM_STAB
	if_type_effectiveness AI_EFFECTIVENESS_x2, AI_CBM_TypeMatchup_Minus9
	goto AI_CBM_TypeMatchup_Minus30

AI_CBM_TypeMatchup_QuarterDmg_LastMon:
	if_type_effectiveness AI_EFFECTIVENESS_x4, AI_CBM_STAB
	if_type_effectiveness AI_EFFECTIVENESS_x2, AI_CBM_TypeMatchup_Minus1
	if_type_effectiveness AI_EFFECTIVENESS_x1, AI_CBM_TypeMatchup_Minus3
	goto AI_CBM_TypeMatchup_Minus5

AI_CBM_TypeMatchup_HalfDmg:
	count_usable_party_mons AI_USER
	if_equal 0, AI_CBM_TypeMatchup_HalfDmg_LastMon
	if_type_effectiveness AI_EFFECTIVENESS_x0_25, AI_CBM_TypeMatchup_Minus30
	if_type_effectiveness AI_EFFECTIVENESS_x0_5, AI_CBM_TypeMatchup_Minus30
	if_type_effectiveness AI_EFFECTIVENESS_x1, AI_CBM_TypeMatchup_Minus9
	goto AI_CBM_TypeMatchup_WeaknessesPreCheck

AI_CBM_TypeMatchup_HalfDmg_LastMon:
	if_type_effectiveness AI_EFFECTIVENESS_x0_25, AI_CBM_TypeMatchup_Minus5
	if_type_effectiveness AI_EFFECTIVENESS_x0_5, AI_CBM_TypeMatchup_Minus3
	if_type_effectiveness AI_EFFECTIVENESS_x1, AI_CBM_TypeMatchup_Minus1
	goto AI_CBM_TypeMatchup_WeaknessesPreCheck

AI_CBM_TypeMatchup_DoubleDmg:
	if_type_effectiveness AI_EFFECTIVENESS_x0_5, AI_CBM_TypeMatchup_WeaknessesPreCheck
	if_type_effectiveness AI_EFFECTIVENESS_x1, AI_CBM_TypeMatchup_Plus1
	count_usable_party_mons AI_USER
	if_equal 0, AI_CBM_TypeMatchup_DoubleDmg_LastMon
	if_type_effectiveness AI_EFFECTIVENESS_x0_25, AI_CBM_TypeMatchup_Minus9
	goto AI_CBM_TypeMatchup_Plus2

AI_CBM_TypeMatchup_DoubleDmg_LastMon:
	if_type_effectiveness AI_EFFECTIVENESS_x0_25, AI_CBM_TypeMatchup_Minus1
	goto AI_CBM_TypeMatchup_Plus2

AI_CBM_TypeMatchup:
	count_usable_party_mons AI_USER
	if_equal 0, AI_CBM_TypeMatchup_LastMon
	if_type_effectiveness AI_EFFECTIVENESS_x0_25, AI_CBM_TypeMatchup_Minus30
	if_type_effectiveness AI_EFFECTIVENESS_x0_5, AI_CBM_TypeMatchup_Minus9
	goto AI_CBM_TypeMatchup_WeaknessesPreCheck

AI_CBM_TypeMatchup_LastMon:
	if_type_effectiveness AI_EFFECTIVENESS_x0_25, AI_CBM_TypeMatchup_Minus3
	if_type_effectiveness AI_EFFECTIVENESS_x0_5, AI_CBM_TypeMatchup_Minus1
AI_CBM_TypeMatchup_WeaknessesPreCheck:
	if_status2 AI_USER, STATUS2_SUBSTITUTE, AI_CBM_TypeMatchup_Weaknesses
	if_effect EFFECT_FOCUS_PUNCH | EFFECT_RAZOR_WIND | EFFECT_RECHARGE | EFFECT_SEMI_INVULNERABLE | EFFECT_SKULL_BASH | EFFECT_SKY_ATTACK, AI_CBM_STAB
	get_weather
	if_equal AI_WEATHER_SUN, AI_CBM_TypeMatchup_Weaknesses
	if_effect EFFECT_SOLAR_BEAM, AI_CBM_STAB
AI_CBM_TypeMatchup_Weaknesses:
	if_type_effectiveness AI_EFFECTIVENESS_x2, AI_CBM_TypeMatchup_Plus1
	if_type_effectiveness AI_EFFECTIVENESS_x4, AI_CBM_TypeMatchup_Plus2
	goto AI_CBM_STAB

AI_CBM_TypeMatchup_Plus1:
	score +1
	goto AI_CBM_STAB

AI_CBM_TypeMatchup_Plus2:
	score +2
	goto AI_CBM_STAB

AI_CBM_TypeMatchup_Minus1:
	score -1
	goto AI_CBM_STAB

AI_CBM_TypeMatchup_Minus3:
	score -3
	goto AI_CBM_STAB

AI_CBM_TypeMatchup_Minus5:
	score -5
	goto AI_CBM_STAB

AI_CBM_TypeMatchup_Minus9:
	score -9
	goto AI_CBM_STAB

AI_CBM_TypeMatchup_Minus30:
	score -30
AI_CBM_STAB:
	get_curr_move_type
	if_equal AI_TYPE1_USER | AI_TYPE2_USER, CheckSoundproof
	score -1
CheckSoundproof:
	get_ability AI_TARGET
	if_equal ABILITY_SOUNDPROOF, AI_CBM_CheckIfSound
	goto AI_CBM_IfStatLowering

AI_CBM_CheckIfSound:
	if_move MOVE_GRASS_WHISTLE | MOVE_GROWL | MOVE_METAL_SOUND | MOVE_ROAR | MOVE_SCREECH, | MOVE_SING | MOVE_SNORE | MOVE_SUPERSONIC | MOVE_UPROAR AI_CBM_CheckIfSound_Minus10
	goto AI_CBM_IfStatLowering

AI_CBM_CheckIfSound_Minus10:
	score -10
AI_CBM_IfStatLowering:
	if_effect EFFECT_ACCURACY_DOWN | EFFECT_ACCURACY_DOWN_2 | EFFECT_ATTACK_DOWN | EFFECT_ATTACK_DOWN_2 | EFFECT_DEFENSE_DOWN | EFFECT_DEFENSE_DOWN_2 | EFFECT_EVASION_DOWN | EFFECT_EVASION_DOWN_2 | EFFECT_SPECIAL_ATTACK_DOWN | EFFECT_SPECIAL_ATTACK_DOWN_2 | EFFECT_SPECIAL_DEFENSE_DOWN | EFFECT_SPECIAL_DEFENSE_DOWN_2 | EFFECT_SPEED_DOWN | EFFECT_SPEED_DOWN_2, AI_CBM_StatLowerImmunity
	if_effect EFFECT_ATTACK_DOWN_HIT | EFFECT_DEFENSE_DOWN_HIT | EFFECT_SPECIAL_ATTACK_DOWN_HIT | EFFECT_SPECIAL_DEFENSE_DOWN_HIT | EFFECT_SPEED_DOWN_HIT, AI_CBM_StatLowerImmunity_Hit
	goto AI_CheckBadMove_CheckEffect

AI_CBM_StatLowerImmunity_Hit:
	get_ability AI_TARGET
	if_equal ABILITY_SHIELD_DUST, AI_CBM_StatLowerImmunity_Minus1
AI_CBM_StatLowerImmunity:
	get_ability AI_TARGET
	if_equal ABILITY_CLEAR_BODY | ABILITY_WHITE_SMOKE, AI_CBM_StatLowerImmunity_Minus10
	if_side_affecting AI_TARGET, SIDE_STATUS_MIST, AI_CBM_StatLowerImmunity_Minus10
	goto AI_CheckBadMove_CheckEffect

AI_CBM_StatLowerImmunity_Minus1:
	score -1
	goto AI_CheckBadMove_CheckEffect

AI_CBM_StatLowerImmunity_Minus10:
	score -10
AI_CheckBadMove_CheckEffect:
	if_effect EFFECT_SLEEP | EFFECT_YAWN, AI_CBM_Sleep
	if_effect EFFECT_ATTACK_UP | EFFECT_ATTACK_UP_2, AI_CBM_AttackUp
	if_effect EFFECT_DEFENSE_UP | EFFECT_DEFENSE_UP_2 | EFFECT_DEFENSE_CURL, AI_CBM_DefenseUp
	if_effect EFFECT_SPEED_UP | EFFECT_SPEED_UP_2, AI_CBM_SpeedUp
	if_effect EFFECT_SPECIAL_ATTACK_UP | EFFECT_SPECIAL_ATTACK_UP_2, AI_CBM_SpAtkUp
	if_effect EFFECT_SPECIAL_DEFENSE_UP | EFFECT_SPECIAL_DEFENSE_UP_2, AI_CBM_SpDefUp
	if_effect EFFECT_ACCURACY_UP | EFFECT_ACCURACY_UP_2, AI_CBM_AccUp
	if_effect EFFECT_EVASION_UP | EFFECT_EVASION_UP_2 | EFFECT_MINIMIZE, AI_CBM_EvasionUp
	if_effect EFFECT_ATTACK_DOWN | EFFECT_ATTACK_DOWN_2, AI_CBM_AttackDown
	if_effect EFFECT_DEFENSE_DOWN | EFFECT_DEFENSE_DOWN_2, AI_CBM_DefenseDown
	if_effect EFFECT_SPEED_DOWN | EFFECT_SPEED_DOWN_2, AI_CBM_SpeedDown
	if_effect EFFECT_SPECIAL_ATTACK_DOWN | EFFECT_SPECIAL_ATTACK_DOWN_2, AI_CBM_SpAtkDown
	if_effect EFFECT_SPECIAL_DEFENSE_DOWN | EFFECT_SPECIAL_DEFENSE_DOWN_2, AI_CBM_SpDefDown
	if_effect EFFECT_ACCURACY_DOWN | EFFECT_ACCURACY_DOWN_2, AI_CBM_AccDown
	if_effect EFFECT_EVASION_DOWN | EFFECT_EVASION_DOWN_2, AI_CBM_EvasionDown
	if_effect EFFECT_BELLY_DRUM, AI_CBM_BellyDrum
	if_effect EFFECT_BULK_UP, AI_CBM_BulkUp
	if_effect EFFECT_CALM_MIND, AI_CBM_CalmMind
	if_effect EFFECT_COSMIC_POWER, AI_CBM_CosmicPower
	if_effect EFFECT_DRAGON_DANCE, AI_CBM_DragonDance
	if_effect EFFECT_TICKLE, AI_CBM_Tickle
	if_effect EFFECT_CURSE, AI_CBM_Curse
	if_effect EFFECT_FOCUS_ENERGY, AI_CBM_FocusEnergy
	if_effect EFFECT_HAZE | EFFECT_PSYCH_UP, AI_CBM_Haze
	if_effect EFFECT_ROAR, AI_CBM_Roar
	if_effect EFFECT_PARALYZE, AI_CBM_Paralyze
	if_effect EFFECT_TOXIC | EFFECT_POISON, AI_CBM_Toxic
	if_effect EFFECT_WILL_O_WISP, AI_CBM_WillOWisp
	if_effect EFFECT_LEECH_SEED, AI_CBM_LeechSeed
	if_effect EFFECT_LIGHT_SCREEN, AI_CBM_LightScreen
	if_effect EFFECT_REFLECT, AI_CBM_Reflect
	if_effect EFFECT_OHKO, AI_CBM_OneHitKO
	if_effect EFFECT_EXPLOSION, AI_CBM_Explosion
	if_effect EFFECT_MEMENTO, AI_CBM_Memento
	if_effect EFFECT_MIST, AI_CBM_Mist
	if_effect EFFECT_SAFEGUARD, AI_CBM_Safeguard
	if_effect EFFECT_CONFUSE | EFFECT_FLATTER | EFFECT_SWAGGER, AI_CBM_Confuse
	if_effect EFFECT_ATTRACT, AI_CBM_Attract
	if_effect EFFECT_SUBSTITUTE, AI_CBM_Substitute
	if_effect EFFECT_DISABLE, AI_CBM_Disable
	if_effect EFFECT_ENCORE, AI_CBM_Encore
	if_effect EFFECT_SNORE | EFFECT_SLEEP_TALK, AI_CBM_DamageDuringSleep
	if_effect EFFECT_DREAM_EATER, AI_CBM_DreamEater
	if_effect EFFECT_NIGHTMARE, AI_CBM_Nightmare
	if_effect EFFECT_MEAN_LOOK, AI_CBM_CantEscape
	if_effect EFFECT_TRAP, AI_CBM_Trap
	if_effect EFFECT_SPIKES, AI_CBM_Spikes
	if_effect EFFECT_FORESIGHT, AI_CBM_Foresight
	if_effect EFFECT_PERISH_SONG, AI_CBM_PerishSong
	if_effect EFFECT_BATON_PASS, AI_CBM_BatonPass
	if_effect EFFECT_HAIL, AI_CBM_Hail
	if_effect EFFECT_RAIN_DANCE, AI_CBM_RainDance
	if_effect EFFECT_SANDSTORM, AI_CBM_Sandstorm
	if_effect EFFECT_SUNNY_DAY, AI_CBM_SunnyDay
	if_effect EFFECT_FUTURE_SIGHT, AI_CBM_FutureSight
	if_effect EFFECT_TELEPORT, Score_Minus10
	if_effect EFFECT_FAKE_OUT, AI_CBM_FakeOut
	if_effect EFFECT_STOCKPILE, AI_CBM_Stockpile
	if_effect EFFECT_SPIT_UP | EFFECT_SWALLOW, AI_CBM_SpitUpAndSwallow
	if_effect EFFECT_TAUNT, AI_CBM_Taunt
	if_effect EFFECT_TORMENT, AI_CBM_Torment
	if_effect EFFECT_HELPING_HAND, AI_CBM_HelpingHand
	if_effect EFFECT_TRICK | EFFECT_KNOCK_OFF, AI_CBM_TrickAndKnockOff
	if_effect EFFECT_RECYCLE, AI_CBM_Recycle
	if_effect EFFECT_INGRAIN, AI_CBM_Ingrain
	if_effect EFFECT_IMPRISON, AI_CBM_Imprison
	if_effect EFFECT_REFRESH, AI_CBM_Refresh
	if_effect EFFECT_HEAL_BELL, AI_CBM_HealBell
	if_effect EFFECT_MUD_SPORT, AI_CBM_MudSport
	if_effect EFFECT_WATER_SPORT, AI_CBM_WaterSport
	if_effect EFFECT_WISH, AI_CBM_Wish
	if_effect EFFECT_CAMOUFLAGE, AI_CBM_Camouflage
	if_effect EFFECT_MIRROR_MOVE, AI_CBM_MirrorMove
	end

AI_CBM_MirrorMove:
	is_first_turn_for AI_TARGET
	if_equal TRUE, AI_CBM_MirrorMovePenalty
	is_first_turn_for AI_USER
	if_equal FALSE, AI_CBM_MirrorMoveCheckSpeed
	goto AI_CBM_MirrorMovePenalty

AI_CBM_MirrorMoveCheckSpeed:
	if_user_faster AI_CBM_MirrorMoveCheckTarget
	goto AI_CBM_MirrorMovePenalty

AI_CBM_MirrorMoveCheckTarget:
	get_last_used_bank_move AI_TARGET
	get_move_target_from_result
	if_equal MOVE_TARGET_BOTH | MOVE_TARGET_FOES_AND_ALLY | MOVE_TARGET_RANDOM | MOVE_TARGET_SELECTED, AI_CheckBadMove_MirrorMove
	goto AI_CBM_MirrorMovePenalty

AI_CheckBadMove_MirrorMove:
	if_status2 AI_TARGET, STATUS2_SUBSTITUTE, AI_CBM_VS_Substitute_MirrorMove
	goto AI_CBM_CheckImmunities_PreCheck_MirrorMove

AI_CBM_VS_Substitute_MirrorMove:
	get_last_used_bank_move AI_TARGET
	get_move_power_from_result
	if_equal 0, AI_CBM_VS_Substitute_CheckTarget_MirrorMove
	get_last_used_bank_move AI_TARGET
	get_move_effect_from_result
	if_equal EFFECT_DREAM_EATER | EFFECT_EXPLOSION | EFFECT_TRAP, AI_CBM_SubstituteBlocks_MirrorMove
	if_equal EFFECT_CURSE, AI_CBM_VS_Substitute_CurseTypeCheck_MirrorMove
	goto AI_CBM_CheckImmunities_MirrorMove

AI_CBM_VS_Substitute_CurseTypeCheck_MirrorMove:
	get_user_type1
	if_equal TYPE_GHOST, AI_CBM_SubstituteBlocks_MirrorMove
	get_user_type2
	if_equal TYPE_GHOST, AI_CBM_SubstituteBlocks_MirrorMove
	goto AI_CBM_MirrorMove_CheckEffect

AI_CBM_VS_Substitute_CheckTarget_MirrorMove:
	get_last_used_bank_move AI_TARGET
	get_move_target_from_result
	if_equal MOVE_TARGET_SELECTED, AI_CBM_VS_Substitute_CheckEffect_MirrorMove
	goto AI_CBM_Soundproof_MirrorMove

AI_CBM_VS_Substitute_CheckEffect_MirrorMove:
	get_last_used_bank_move AI_TARGET
	get_move_effect_from_result
	if_equal EFFECT_ROAR, AI_CBM_Soundproof_MirrorMove
	if_equal EFFECT_ATTRACT | EFFECT_DISABLE | EFFECT_ENCORE | EFFECT_FORESIGHT | EFFECT_HAZE | EFFECT_MEAN_LOOK | EFFECT_PSYCH_UP | EFFECT_ROLE_PLAY | EFFECT_SKILL_SWAP | EFFECT_SPITE | EFFECT_TAUNT | EFFECT_TORMENT | EFFECT_TRANSFORM, AI_CBM_MirrorMove_CheckEffect
AI_CBM_SubstituteBlocks_MirrorMove:
	score -10
AI_CBM_CheckImmunities_PreCheck_MirrorMove:
	get_considered_move_power
	if_equal 0, AI_CBM_Soundproof_MirrorMove
AI_CBM_CheckImmunities_MirrorMove:
	get_last_used_bank_move AI_TARGET
	if_type_effectiveness_from_result AI_EFFECTIVENESS_x0, Score_Minus30
	get_ability AI_TARGET
	if_equal ABILITY_VOLT_ABSORB, AI_CBM_VoltAbs_MirrorMove
	if_equal ABILITY_WATER_ABSORB, AI_CBM_WaterAbs_MirrorMove
	if_equal ABILITY_FLASH_FIRE, AI_CBM_FlashFire_MirrorMove
	if_equal ABILITY_WONDER_GUARD, AI_CBM_WGuard_MirrorMove
	if_equal ABILITY_LEVITATE, AI_CBM_Levitate_MirrorMove
	goto AI_CBM_TestWhetherToTypeMatchup_MirrorMove

AI_CBM_VoltAbs_MirrorMove:
	get_last_used_bank_move AI_TARGET
	get_move_type_from_result
	if_equal_ TYPE_ELECTRIC, Score_Minus30
	goto AI_CBM_TestWhetherToTypeMatchup_MirrorMove

AI_CBM_WaterAbs_MirrorMove:
	get_last_used_bank_move AI_TARGET
	get_move_type_from_result
	if_equal_ TYPE_WATER, Score_Minus30
	goto AI_CBM_TestWhetherToTypeMatchup_MirrorMove

AI_CBM_FlashFire_MirrorMove:
	get_last_used_bank_move AI_TARGET
	get_move_type_from_result
	if_equal_ TYPE_FIRE, Score_Minus30
	goto AI_CBM_TestWhetherToTypeMatchup_MirrorMove

AI_CBM_WGuard_MirrorMove:
	get_last_used_bank_move AI_TARGET
	if_type_effectiveness_from_result AI_EFFECTIVENESS_x2, AI_CBM_TestWhetherToTypeMatchup_MirrorMove
	goto Score_Minus30

AI_CBM_Levitate_MirrorMove:
	get_last_used_bank_move AI_TARGET
	get_move_type_from_result
	if_equal_ TYPE_GROUND, Score_Minus30
	goto AI_CBM_TestWhetherToTypeMatchup_MirrorMove

AI_CBM_TestWhetherToTypeMatchup_MirrorMove:
	get_last_used_bank_move AI_TARGET
	get_move_effect_from_result
	if_equal EFFECT_BIDE | EFFECT_COUNTER | EFFECT_ENDEAVOR | EFFECT_FAKE_OUT | EFFECT_LEVEL_DAMAGE| EFFECT_MIRROR_COAT | EFFECT_OHKO | EFFECT_RAPID_SPIN | EFFECT_SUPER_FANG | EFFECT_TRAP, AI_CBM_Soundproof_MirrorMove
	if_equal EFFECT_PARALYZE_HIT | EFFECT_POISON_FANG | EFFECT_POISON_HIT | EFFECT_SECRET_POWER, AI_CBM_TestWhetherToTypeMatchup_Status_MirrorMove
	if_equal EFFECT_KNOCK_OFF | EFFECT_THIEF, AI_CBM_TestWhetherToTypeMatchup_ItemCheck_MirrorMove
	if_equal EFFECT_SPEED_DOWN_HIT, AI_CBM_TestWhetherToTypeMatchup_Speed_MirrorMove
	goto AI_CBM_TypeMatchup_MirrorMove_Modifiers

AI_CBM_TestWhetherToTypeMatchup_Status_MirrorMove:
	if_status AI_TARGET, STATUS1_ANY, AI_CBM_TypeMatchup_MirrorMove_Modifiers
	get_last_used_bank_move AI_TARGET
	get_considered_move_second_eff_chance_from_result
	if_less_than 25, AI_CBM_TypeMatchup_MirrorMove_Modifiers
	goto AI_CBM_Soundproof_MirrorMove

AI_CBM_TestWhetherToTypeMatchup_ItemCheck_MirrorMove:
	get_ability AI_TARGET
	if_equal ABILITY_STICKY_HOLD, AI_CBM_TypeMatchup_MirrorMove_Modifiers
	get_hold_effect AI_TARGET
	if_not_in_bytes AI_CV_Thief_EncourageItemsToSteal, AI_CBM_TypeMatchup_MirrorMove_Modifiers
	goto AI_CBM_Soundproof_MirrorMove

AI_CBM_TestWhetherToTypeMatchup_Speed_MirrorMove:
	get_ability AI_TARGET
	if_equal ABILITY_CLEAR_BODY | ABILITY_SHIELD_DUST | ABILITY_SPEED_BOOST | ABILITY_WHITE_SMOKE, AI_CBM_TypeMatchup_MirrorMove_Modifiers
	if_side_affecting AI_TARGET, SIDE_STATUS_MIST, AI_CBM_TypeMatchup_MirrorMove_Modifiers
	if_target_faster AI_CBM_Soundproof_MirrorMove
AI_CBM_TypeMatchup_MirrorMove_Modifiers:
	get_last_used_bank_move AI_TARGET
	get_move_type_from_result
	if_equal TYPE_BUG | TYPE_FIGHTING | TYPE_FLYING | TYPE_GHOST | TYPE_GROUND | TYPE_NORMAL | TYPE_POISON | TYPE_ROCK | TYPE_STEEL, AI_CBM_TypeMatchup_MirrorMove_Reflect
	if_equal TYPE_DARK | TYPE_DRAGON | TYPE_GRASS | TYPE_PSYCHIC, AI_CBM_TypeMatchup_MirrorMove_LS
	if_equal TYPE_ELECTRIC, AI_CBM_TypeMatchup_MirrorMove_MudSport
	if_equal TYPE_FIRE, AI_CBM_TypeMatchup_MirrorMove_WaterSport
	if_equal TYPE_ICE, AI_CBM_TypeMatchup_MirrorMove_ThickFat
	if_equal TYPE_WATER, AI_CBM_TypeMatchup_MirrorMove_Weather_Water
	goto AI_CBM_TypeMatchup_MirrorMove_LS

AI_CBM_TypeMatchup_MirrorMove_Reflect:
	if_side_affecting AI_TARGET, SIDE_STATUS_REFLECT, AI_CBM_TypeMatchup_MirrorMove_HalfDmg
	goto AI_CBM_TypeMatchup_MirrorMove

AI_CBM_TypeMatchup_MirrorMove_WaterSport:
	if_status3 AI_TARGET, STATUS3_WATERSPORT, AI_CBM_TypeMatchup_MirrorMove_ThickFat_Fire_HalfDmg
	goto AI_CBM_TypeMatchup_MirrorMove_ThickFat_Fire

AI_CBM_TypeMatchup_MirrorMove_ThickFat_Fire:
	get_ability AI_TARGET
	if_equal ABILITY_THICK_FAT, AI_CBM_TypeMatchup_MirrorMove_Weather_Fire_HalfDmg
	goto AI_CBM_TypeMatchup_MirrorMove_Weather_Fire

AI_CBM_TypeMatchup_MirrorMove_ThickFat_Fire_HalfDmg:
	get_ability AI_TARGET
	if_equal ABILITY_THICK_FAT, AI_CBM_TypeMatchup_MirrorMove_Weather_Fire_QuarterDmg
	goto AI_CBM_TypeMatchup_MirrorMove_Weather_Fire_HalfDmg

AI_CBM_TypeMatchup_MirrorMove_Weather_Fire:
	get_weather
	if_equal AI_WEATHER_SUN, AI_CBM_TypeMatchup_MirrorMove_LS_DoubleDmg
	if_equal AI_WEATHER_RAIN, AI_CBM_TypeMatchup_MirrorMove_LS_HalfDmg
	goto AI_CBM_TypeMatchup_MirrorMove_LS

AI_CBM_TypeMatchup_MirrorMove_Weather_Fire_HalfDmg:
	get_weather
	if_equal AI_WEATHER_SUN, AI_CBM_TypeMatchup_MirrorMove_LS
	if_equal AI_WEATHER_RAIN, AI_CBM_TypeMatchup_MirrorMove_LS_QuarterDmg
	goto AI_CBM_TypeMatchup_MirrorMove_LS_HalfDmg

AI_CBM_TypeMatchup_MirrorMove_Weather_Fire_QuarterDmg:
	get_weather
	if_equal AI_WEATHER_SUN, AI_CBM_TypeMatchup_MirrorMove_LS_HalfDmg
	if_equal AI_WEATHER_RAIN, AI_CBM_TypeMatchup_MirrorMove_LS_EighthDmg
	goto AI_CBM_TypeMatchup_MirrorMove_LS_QuarterDmg

AI_CBM_TypeMatchup_MirrorMove_Weather_Water:
	get_weather
	if_equal AI_WEATHER_SUN, AI_CBM_TypeMatchup_MirrorMove_LS_HalfDmg
	if_equal AI_WEATHER_RAIN, AI_CBM_TypeMatchup_MirrorMove_LS_DoubleDmg
	goto AI_CBM_TypeMatchup_MirrorMove_LS

AI_CBM_TypeMatchup_MirrorMove_ThickFat:
	get_ability AI_TARGET
	if_equal ABILITY_THICK_FAT, AI_CBM_TypeMatchup_MirrorMove_LS_HalfDmg
	goto AI_CBM_TypeMatchup_MirrorMove_LS

AI_CBM_TypeMatchup_MirrorMove_MudSport:
	if_status3 AI_TARGET, STATUS3_MUDSPORT, AI_CBM_TypeMatchup_MirrorMove_LS_HalfDmg
AI_CBM_TypeMatchup_MirrorMove_LS:
	if_side_affecting AI_TARGET, SIDE_STATUS_LIGHTSCREEN, AI_CBM_TypeMatchup_MirrorMove_HalfDmg
	goto AI_CBM_TypeMatchup_MirrorMove

AI_CBM_TypeMatchup_MirrorMove_LS_DoubleDmg:
	if_side_affecting AI_TARGET, SIDE_STATUS_LIGHTSCREEN, AI_CBM_TypeMatchup
	goto AI_CBM_TypeMatchup_MirrorMove_DoubleDmg

AI_CBM_TypeMatchup_MirrorMove_LS_HalfDmg:
	if_side_affecting AI_TARGET, SIDE_STATUS_LIGHTSCREEN, AI_CBM_TypeMatchup_MirrorMove_QuarterDmg
	goto AI_CBM_TypeMatchup_MirrorMove_HalfDmg

AI_CBM_TypeMatchup_MirrorMove_LS_QuarterDmg:
	if_side_affecting AI_TARGET, SIDE_STATUS_LIGHTSCREEN, AI_CBM_TypeMatchup_MirrorMove_LS_EighthDmg
	goto AI_CBM_TypeMatchup_MirrorMove_QuarterDmg

AI_CBM_TypeMatchup_MirrorMove_LS_EighthDmg:
	if_side_affecting AI_TARGET, SIDE_STATUS_LIGHTSCREEN, AI_CBM_TypeMatchup_MirrorMove_OneSixteenthDmg
	goto AI_CBM_TypeMatchup_MirrorMove_LS_EighthDmg

AI_CBM_TypeMatchup_MirrorMove_OneSixteenthDmg:
	count_usable_party_mons AI_USER
	if_equal 0, AI_CBM_TypeMatchup_MirrorMove_OneSixteenthDmg_LastMon
	goto AI_CBM_TypeMatchup_MirrorMove_Minus30

AI_CBM_TypeMatchup_MirrorMove_OneSixteenthDmg_LastMon:
	get_last_used_bank_move AI_TARGET
	if_type_effectiveness_from_result AI_EFFECTIVENESS_x4, AI_CBM_TypeMatchup_MirrorMove_Minus3
	if_type_effectiveness_from_result AI_EFFECTIVENESS_x2, AI_CBM_TypeMatchup_MirrorMove_Minus5
	goto AI_CBM_TypeMatchup_MirrorMove_Minus30

AI_CBM_TypeMatchup_MirrorMove_OneEighthDmg:
	get_last_used_bank_move AI_TARGET
	if_type_effectiveness_from_result AI_EFFECTIVENESS_x4, AI_CBM_TypeMatchup_MirrorMove_Minus1
	count_usable_party_mons AI_USER
	if_equal 0, AI_CBM_TypeMatchup_MirrorMove_OneEighthDmg_LastMon
	goto AI_CBM_TypeMatchup_MirrorMove_Minus30

AI_CBM_TypeMatchup_MirrorMove_OneEighthDmg_LastMon:
	get_last_used_bank_move AI_TARGET
	if_type_effectiveness_from_result AI_EFFECTIVENESS_x2, AI_CBM_TypeMatchup_MirrorMove_Minus3
	goto AI_CBM_TypeMatchup_MirrorMove_Minus5

AI_CBM_TypeMatchup_MirrorMove_QuarterDmg:
	count_usable_party_mons AI_USER
	if_equal 0, AI_CBM_TypeMatchup_MirrorMove_QuarterDmg_LastMon
	get_last_used_bank_move AI_TARGET
	if_type_effectiveness_from_result AI_EFFECTIVENESS_x4, AI_CBM_STAB_MirrorMove
	if_type_effectiveness_from_result AI_EFFECTIVENESS_x2, AI_CBM_TypeMatchup_MirrorMove_Minus9
	goto AI_CBM_TypeMatchup_MirrorMove_Minus30

AI_CBM_TypeMatchup_MirrorMove_QuarterDmg_LastMon:
	get_last_used_bank_move AI_TARGET
	if_type_effectiveness_from_result AI_EFFECTIVENESS_x4, AI_CBM_STAB_MirrorMove
	if_type_effectiveness_from_result AI_EFFECTIVENESS_x2, AI_CBM_TypeMatchup_MirrorMove_Minus1
	if_type_effectiveness_from_result AI_EFFECTIVENESS_x1, AI_CBM_TypeMatchup_MirrorMove_Minus3
	goto AI_CBM_TypeMatchup_MirrorMove_Minus5

AI_CBM_TypeMatchup_MirrorMove_HalfDmg:
	count_usable_party_mons AI_USER
	if_equal 0, AI_CBM_TypeMatchup_MirrorMove_HalfDmg_LastMon
	get_last_used_bank_move AI_TARGET
	if_type_effectiveness_from_result AI_EFFECTIVENESS_x0_25, AI_CBM_TypeMatchup_MirrorMove_Minus30
	if_type_effectiveness_from_result AI_EFFECTIVENESS_x0_5, AI_CBM_TypeMatchup_MirrorMove_Minus30
	if_type_effectiveness_from_result AI_EFFECTIVENESS_x1, AI_CBM_TypeMatchup_MirrorMove_Minus9
	goto AI_CBM_TypeMatchup_MirrorMove_WeaknessesPreCheck

AI_CBM_TypeMatchup_MirrorMove_HalfDmg_LastMon:
	get_last_used_bank_move AI_TARGET
	if_type_effectiveness_from_result AI_EFFECTIVENESS_x0_25, AI_CBM_TypeMatchup_MirrorMove_Minus5
	if_type_effectiveness_from_result AI_EFFECTIVENESS_x0_5, AI_CBM_TypeMatchup_MirrorMove_Minus3
	if_type_effectiveness_from_result AI_EFFECTIVENESS_x1, AI_CBM_TypeMatchup_MirrorMove_Minus1
	goto AI_CBM_TypeMatchup_MirrorMove_WeaknessesPreCheck

AI_CBM_TypeMatchup_MirrorMove_DoubleDmg:
	get_last_used_bank_move AI_TARGET
	if_type_effectiveness_from_result AI_EFFECTIVENESS_x0_5, AI_CBM_TypeMatchup_MirrorMove_WeaknessesPreCheck
	if_type_effectiveness_from_result AI_EFFECTIVENESS_x1, AI_CBM_TypeMatchup_MirrorMove_Plus1
	count_usable_party_mons AI_USER
	if_equal 0, AI_CBM_TypeMatchup_MirrorMove_DoubleDmg_LastMon
	if_type_effectiveness_from_result AI_EFFECTIVENESS_x0_25, AI_CBM_TypeMatchup_MirrorMove_Minus9
	goto AI_CBM_TypeMatchup_MirrorMove_Plus2

AI_CBM_TypeMatchup_MirrorMove_DoubleDmg_LastMon:
	get_last_used_bank_move AI_TARGET
	if_type_effectiveness_from_result AI_EFFECTIVENESS_x0_25, AI_CBM_TypeMatchup_MirrorMove_Minus1
	goto AI_CBM_TypeMatchup_MirrorMove_Plus2

AI_CBM_TypeMatchup_MirrorMove:
	count_usable_party_mons AI_USER
	if_equal 0, AI_CBM_TypeMatchup_MirrorMove_LastMon
	get_last_used_bank_move AI_TARGET
	if_type_effectiveness_from_result AI_EFFECTIVENESS_x0_25, AI_CBM_TypeMatchup_MirrorMove_Minus30
	if_type_effectiveness_from_result AI_EFFECTIVENESS_x0_5, AI_CBM_TypeMatchup_MirrorMove_Minus9
	goto AI_CBM_TypeMatchup_MirrorMove_WeaknessesPreCheck

AI_CBM_TypeMatchup_MirrorMove_LastMon:
	get_last_used_bank_move AI_TARGET
	if_type_effectiveness_from_result AI_EFFECTIVENESS_x0_25, AI_CBM_TypeMatchup_MirrorMove_Minus3
	if_type_effectiveness_from_result AI_EFFECTIVENESS_x0_5, AI_CBM_TypeMatchup_MirrorMove_Minus1
AI_CBM_TypeMatchup_MirrorMove_WeaknessesPreCheck:
	if_status2 AI_USER, STATUS2_SUBSTITUTE, AI_CBM_TypeMatchup_MirrorMove_Weaknesses
	get_last_used_bank_move AI_TARGET
	get_move_effect_from_result
	if_equal EFFECT_FOCUS_PUNCH | EFFECT_RAZOR_WIND | EFFECT_RECHARGE | EFFECT_SEMI_INVULNERABLE | EFFECT_SKULL_BASH | EFFECT_SKY_ATTACK, AI_CBM_STAB_MirrorMove
	get_weather
	if_equal AI_WEATHER_SUN, AI_CBM_TypeMatchup_MirrorMove_Weaknesses
	get_last_used_bank_move AI_TARGET
	get_move_effect_from_result
	if_equal EFFECT_SOLAR_BEAM, AI_CBM_STAB_MirrorMove
AI_CBM_TypeMatchup_MirrorMove_Weaknesses:
	if_type_effectiveness_from_result AI_EFFECTIVENESS_x2, AI_CBM_TypeMatchup_MirrorMove_Plus1
	if_type_effectiveness_from_result AI_EFFECTIVENESS_x4, AI_CBM_TypeMatchup_MirrorMove_Plus2
	goto AI_CBM_STAB_MirrorMove

AI_CBM_TypeMatchup_MirrorMove_Plus1:
	score +1
	goto AI_CBM_STAB_MirrorMove

AI_CBM_TypeMatchup_MirrorMove_Plus2:
	score +2
	goto AI_CBM_STAB_MirrorMove

AI_CBM_TypeMatchup_MirrorMove_Minus1:
	score -1
	goto AI_CBM_STAB_MirrorMove

AI_CBM_TypeMatchup_MirrorMove_Minus3:
	score -3
	goto AI_CBM_STAB_MirrorMove

AI_CBM_TypeMatchup_MirrorMove_Minus5:
	score -5
	goto AI_CBM_STAB_MirrorMove

AI_CBM_TypeMatchup_MirrorMove_Minus9:
	score -9
	goto AI_CBM_STAB_MirrorMove

AI_CBM_TypeMatchup_MirrorMove_Minus30:
	score -30
AI_CBM_STAB_MirrorMove:
	get_last_used_bank_move AI_TARGET
	get_move_type_from_result
	if_equal AI_TYPE1_USER | AI_TYPE2_USER, AI_CBM_Soundproof_MirrorMove
	score -1
	goto AI_CBM_Soundproof_MirrorMove

AI_CBM_Soundproof_MirrorMove:
	get_ability AI_TARGET
	if_equal ABILITY_SOUNDPROOF, AI_CBM_CheckIfSound_MirrorMove
	goto AI_CBM_IfStatLowering_MirrorMove

AI_CBM_CheckIfSound_MirrorMove:
	get_last_used_bank_move AI_TARGET
	if_not_in_hwords sMovesTable_SoundMoves, AI_CBM_IfStatLowering_MirrorMove
AI_CBM_CheckIfSound_MirrorMove_Minus10:
	score -10
AI_CBM_IfStatLowering_MirrorMove:
	get_last_used_bank_move AI_TARGET
	get_move_effect_from_result
	if_equal EFFECT_ACCURACY_DOWN | EFFECT_ACCURACY_DOWN_2 | EFFECT_ATTACK_DOWN | EFFECT_ATTACK_DOWN_2 | EFFECT_DEFENSE_DOWN | EFFECT_DEFENSE_DOWN_2 | EFFECT_EVASION_DOWN | EFFECT_EVASION_DOWN_2 | EFFECT_SPECIAL_ATTACK_DOWN | EFFECT_SPECIAL_ATTACK_DOWN_2 | EFFECT_SPECIAL_DEFENSE_DOWN | EFFECT_SPECIAL_DEFENSE_DOWN_2 | EFFECT_SPEED_DOWN | EFFECT_SPEED_DOWN_2, AI_CBM_StatLowerImmunity_MirrorMove
	if_equal EFFECT_ATTACK_DOWN_HIT | EFFECT_DEFENSE_DOWN_HIT | EFFECT_SPECIAL_ATTACK_DOWN_HIT | EFFECT_SPECIAL_DEFENSE_DOWN_HIT | EFFECT_SPEED_DOWN_HIT, AI_CBM_StatLowerImmunity_Hit_MirrorMove
	goto AI_CBM_MirrorMove_CheckEffect

AI_CBM_StatLowerImmunity_Hit_MirrorMove:
	get_ability AI_TARGET
	if_equal ABILITY_SHIELD_DUST, AI_CBM_StatLowerImmunity_MirrorMove_Minus1
AI_CBM_StatLowerImmunity_MirrorMove:
	get_ability AI_TARGET
	if_equal ABILITY_CLEAR_BODY | ABILITY_WHITE_SMOKE, AI_CBM_StatLowerImmunity_MirrorMove_Minus10
	if_side_affecting AI_TARGET, SIDE_STATUS_MIST, AI_CBM_StatLowerImmunity_MirrorMove_Minus10
	goto AI_CBM_MirrorMove_CheckEffect

AI_CBM_StatLowerImmunity_MirrorMove_Minus1:
	score -1
	goto AI_CBM_MirrorMove_CheckEffect

AI_CBM_StatLowerImmunity_MirrorMove_Minus10:
	score -10
AI_CBM_MirrorMove_CheckEffect:
	get_last_used_bank_move AI_TARGET
	get_move_effect_from_result
	if_equal EFFECT_SLEEP | EFFECT_YAWN, AI_CBM_Sleep
	if_equal EFFECT_ATTACK_UP | EFFECT_ATTACK_UP_2, AI_CBM_AttackUp
	if_equal EFFECT_DEFENSE_UP | EFFECT_DEFENSE_UP_2 | EFFECT_DEFENSE_CURL, AI_CBM_DefenseUp
	if_equal EFFECT_SPEED_UP | EFFECT_SPEED_UP_2, AI_CBM_SpeedUp
	if_equal EFFECT_SPECIAL_ATTACK_UP | EFFECT_SPECIAL_ATTACK_UP_2, AI_CBM_SpAtkUp
	if_equal EFFECT_SPECIAL_DEFENSE_UP | EFFECT_SPECIAL_DEFENSE_UP_2, AI_CBM_SpDefUp
	if_equal EFFECT_ACCURACY_UP | EFFECT_ACCURACY_UP_2, AI_CBM_AccUp
	if_equal EFFECT_EVASION_UP | EFFECT_EVASION_UP_2 | EFFECT_MINIMIZE, AI_CBM_EvasionUp
	if_equal EFFECT_ATTACK_DOWN | EFFECT_ATTACK_DOWN_2, AI_CBM_AttackDown
	if_equal EFFECT_DEFENSE_DOWN | EFFECT_DEFENSE_DOWN_2, AI_CBM_DefenseDown
	if_equal EFFECT_SPEED_DOWN | EFFECT_SPEED_DOWN_2, AI_CBM_SpeedDown
	if_equal EFFECT_SPECIAL_ATTACK_DOWN | EFFECT_SPECIAL_ATTACK_DOWN_2, AI_CBM_SpAtkDown
	if_equal EFFECT_SPECIAL_DEFENSE_DOWN | EFFECT_SPECIAL_DEFENSE_DOWN_2, AI_CBM_SpDefDown
	if_equal EFFECT_ACCURACY_DOWN | EFFECT_ACCURACY_DOWN_2, AI_CBM_AccDown
	if_equal EFFECT_EVASION_DOWN | EFFECT_EVASION_DOWN_2, AI_CBM_EvasionDown
	if_equal EFFECT_BELLY_DRUM, AI_CBM_BellyDrum
	if_equal EFFECT_BULK_UP, AI_CBM_BulkUp
	if_equal EFFECT_CALM_MIND, AI_CBM_CalmMind
	if_equal EFFECT_COSMIC_POWER, AI_CBM_CosmicPower
	if_equal EFFECT_DRAGON_DANCE, AI_CBM_DragonDance
	if_equal EFFECT_TICKLE, AI_CBM_Tickle
	if_equal EFFECT_CURSE, AI_CBM_Curse
	if_equal EFFECT_FOCUS_ENERGY, AI_CBM_FocusEnergy
	if_equal EFFECT_HAZE | EFFECT_PSYCH_UP, AI_CBM_Haze
	if_equal EFFECT_ROAR, AI_CBM_Roar
	if_equal EFFECT_PARALYZE, AI_CBM_Paralyze
	if_equal EFFECT_TOXIC | EFFECT_POISON, AI_CBM_Toxic
	if_equal EFFECT_WILL_O_WISP, AI_CBM_WillOWisp
	if_equal EFFECT_LEECH_SEED, AI_CBM_LeechSeed
	if_equal EFFECT_LIGHT_SCREEN, AI_CBM_LightScreen
	if_equal EFFECT_REFLECT, AI_CBM_Reflect
	if_equal EFFECT_OHKO, AI_CBM_OneHitKO
	if_equal EFFECT_EXPLOSION, AI_CBM_Explosion
	if_equal EFFECT_MEMENTO, AI_CBM_Memento
	if_equal EFFECT_MIST, AI_CBM_Mist
	if_equal EFFECT_SAFEGUARD, AI_CBM_Safeguard
	if_equal EFFECT_CONFUSE | EFFECT_FLATTER | EFFECT_SWAGGER, AI_CBM_Confuse
	if_equal EFFECT_ATTRACT, AI_CBM_Attract
	if_equal EFFECT_SUBSTITUTE, AI_CBM_Substitute
	if_equal EFFECT_DISABLE, AI_CBM_Disable
	if_equal EFFECT_ENCORE, AI_CBM_Encore
	if_equal EFFECT_SNORE | EFFECT_SLEEP_TALK, AI_CBM_DamageDuringSleep
	if_equal EFFECT_DREAM_EATER, AI_CBM_DreamEater
	if_equal EFFECT_NIGHTMARE, AI_CBM_Nightmare
	if_equal EFFECT_MEAN_LOOK, AI_CBM_CantEscape
	if_equal EFFECT_TRAP, AI_CBM_Trap
	if_equal EFFECT_SPIKES, AI_CBM_Spikes
	if_equal EFFECT_FORESIGHT, AI_CBM_Foresight
	if_equal EFFECT_PERISH_SONG, AI_CBM_PerishSong
	if_equal EFFECT_BATON_PASS, AI_CBM_BatonPass
	if_equal EFFECT_HAIL, AI_CBM_Hail
	if_equal EFFECT_RAIN_DANCE, AI_CBM_RainDance
	if_equal EFFECT_SANDSTORM, AI_CBM_Sandstorm
	if_equal EFFECT_SUNNY_DAY, AI_CBM_SunnyDay
	if_equal EFFECT_FUTURE_SIGHT, AI_CBM_FutureSight
	if_equal EFFECT_TELEPORT, Score_Minus10
	if_equal EFFECT_FAKE_OUT, AI_CBM_FakeOut
	if_equal EFFECT_STOCKPILE, AI_CBM_Stockpile
	if_equal EFFECT_SPIT_UP | EFFECT_SWALLOW, AI_CBM_SpitUpAndSwallow
	if_equal EFFECT_TAUNT, AI_CBM_Taunt
	if_equal EFFECT_TORMENT, AI_CBM_Torment
	if_equal EFFECT_HELPING_HAND, AI_CBM_HelpingHand
	if_equal EFFECT_TRICK | EFFECT_KNOCK_OFF, AI_CBM_TrickAndKnockOff
	if_equal EFFECT_RECYCLE, AI_CBM_Recycle
	if_equal EFFECT_INGRAIN, AI_CBM_Ingrain
	if_equal EFFECT_IMPRISON, AI_CBM_Imprison
	if_equal EFFECT_REFRESH, AI_CBM_Refresh
	if_equal EFFECT_HEAL_BELL, AI_CBM_HealBell
	if_equal EFFECT_MUD_SPORT, AI_CBM_MudSport
	if_equal EFFECT_WATER_SPORT, AI_CBM_WaterSport
	if_equal EFFECT_WISH, AI_CBM_Wish
	if_equal EFFECT_CAMOUFLAGE, AI_CBM_Camouflage
	end

AI_CBM_MirrorMovePenalty:
	score -7
	end

AI_CBM_Sleep:
	get_ability AI_TARGET
	if_equal ABILITY_INSOMNIA, Score_Minus10
	if_equal ABILITY_VITAL_SPIRIT, Score_Minus10
	goto AI_CBM_CheckTargetStatusImmune

AI_CBM_Paralyze:
	if_type_effectiveness AI_EFFECTIVENESS_x0, Score_Minus10
	get_ability AI_TARGET
	if_equal ABILITY_LIMBER, Score_Minus10
	goto AI_CBM_CheckTargetStatusImmune

AI_CBM_Toxic:
	get_target_type1
	if_equal TYPE_STEEL, Score_Minus10
	if_equal TYPE_POISON, Score_Minus10
	get_target_type2
	if_equal TYPE_STEEL, Score_Minus10
	if_equal TYPE_POISON, Score_Minus10
	get_ability AI_TARGET
	if_equal ABILITY_IMMUNITY, Score_Minus10
	goto AI_CBM_CheckTargetStatusImmune

AI_CBM_WillOWisp:
	get_target_type1
	if_equal TYPE_FIRE, Score_Minus10
	get_target_type2
	if_equal TYPE_FIRE, Score_Minus10
	get_ability AI_TARGET
	if_equal ABILITY_WATER_VEIL, Score_Minus10
	goto AI_CBM_CheckTargetStatusImmune

AI_CBM_CheckTargetStatusImmune:
	if_status AI_TARGET, STATUS1_ANY, Score_Minus10
	if_side_affecting AI_TARGET, SIDE_STATUS_SAFEGUARD, Score_Minus10
	if_ability AI_TARGET, ABILITY_GUTS, Score_Minus10
	end

AI_CBM_Attract:
	if_status2 AI_TARGET, STATUS2_INFATUATION, Score_Minus10
	get_ability AI_TARGET
	if_equal ABILITY_OBLIVIOUS, Score_Minus10
	get_gender AI_USER
	if_equal MON_MALE, AI_CBM_Attract_CheckIfTargetIsFemale
	if_equal MON_FEMALE, AI_CBM_Attract_CheckIfTargetIsMale
	goto Score_Minus10

AI_CBM_Attract_CheckIfTargetIsFemale:
	get_gender AI_TARGET
	if_equal MON_FEMALE, AI_End
	goto Score_Minus10

AI_CBM_Attract_CheckIfTargetIsMale:
	get_gender AI_TARGET
	if_equal MON_MALE, AI_End
	goto Score_Minus10

AI_CBM_CantEscape:
	if_status2 AI_TARGET, STATUS2_ESCAPE_PREVENTION, Score_Minus10
	end

AI_CBM_Trap:
	if_status2 AI_USER, STATUS2_WRAPPED, Score_Minus10
	end

AI_CBM_Confuse:
	if_status2 AI_TARGET, STATUS2_CONFUSION, Score_Minus10
	get_ability AI_TARGET
	if_equal ABILITY_OWN_TEMPO, Score_Minus10
	if_side_affecting AI_TARGET, SIDE_STATUS_SAFEGUARD, Score_Minus10
	end

AI_CBM_Curse:
	get_user_type1
	if_equal TYPE_GHOST, AI_CBM_Curse_Ghost
	get_user_type2
	if_equal TYPE_GHOST, AI_CBM_Curse_Ghost
	goto AI_CBM_BulkUp

AI_CBM_Curse_Ghost:
	if_status2 AI_TARGET, STATUS2_CURSED, Score_Minus10
	end

AI_CBM_Foresight:
	if_status2 AI_TARGET, STATUS2_FORESIGHT, Score_Minus10
	end

AI_CBM_Nightmare:
	if_status2 AI_TARGET, STATUS2_NIGHTMARE, Score_Minus10
	if_not_status AI_TARGET, STATUS1_SLEEP, Score_Minus10
	if_random_less_than 16, AI_End
	score +1
	end

AI_CBM_DreamEater:
	if_not_status AI_TARGET, STATUS1_SLEEP, Score_Minus10
	if_random_less_than 16, AI_End
	score +1
	end

AI_CBM_Taunt:
	if_target_taunted Score_Minus10
	end

AI_CBM_Torment:
	if_status2 AI_TARGET, STATUS2_TORMENT, Score_Minus10
	end

AI_CBM_LeechSeed:
	if_status3 AI_TARGET, STATUS3_LEECHSEED, Score_Minus10
	get_target_type1
	if_equal TYPE_GRASS, Score_Minus10
	get_target_type2
	if_equal TYPE_GRASS, Score_Minus10
	end

AI_CBM_PerishSong:
	if_status3 AI_TARGET, STATUS3_PERISH_SONG, Score_Minus10
	end

AI_CBM_DamageDuringSleep:
	if_not_status AI_USER, STATUS1_SLEEP, Score_Minus10
	end

AI_CBM_HealBell:
	if_status_in_party AI_USER, STATUS1_ANY, AI_End
AI_CBM_Refresh:
	if_not_status AI_USER, STATUS1_POISON | STATUS1_BURN | STATUS1_PARALYSIS | STATUS1_TOXIC_POISON, Score_Minus10
	end

AI_CBM_FocusEnergy:
	if_status2 AI_USER, STATUS2_FOCUS_ENERGY, Score_Minus10
	end

AI_CBM_Substitute:
	if_hp_less_than AI_USER, 26, Score_Minus30
	if_status2 AI_USER, STATUS2_SUBSTITUTE, AI_CBM_Substitute_CheckSpeed
	end

AI_CBM_Substitute_CheckSpeed:
	if_user_faster Score_Minus30
	if_random_less_than 128, Score_Minus1
	end

AI_CBM_Imprison:
	if_status3 AI_USER, STATUS3_IMPRISONED_OTHERS, Score_Minus10
	end

AI_CBM_Ingrain:
	if_status3 AI_USER, STATUS3_ROOTED, Score_Minus10
	end

AI_CBM_MudSport:
	if_status3 AI_USER, STATUS3_MUDSPORT, Score_Minus10
	end

AI_CBM_WaterSport:
	if_status3 AI_USER, STATUS3_WATERSPORT, Score_Minus10
	end

AI_CBM_LightScreen:
	if_side_affecting AI_USER, SIDE_STATUS_LIGHTSCREEN, Score_Minus10
	end

AI_CBM_Reflect:
	if_side_affecting AI_USER, SIDE_STATUS_REFLECT, Score_Minus10
	end

AI_CBM_Mist:
	if_side_affecting AI_USER, SIDE_STATUS_MIST, Score_Minus10
	end

AI_CBM_Safeguard:
	if_side_affecting AI_USER, SIDE_STATUS_SAFEGUARD, Score_Minus10
	end

AI_CBM_Spikes:
	count_usable_party_mons AI_TARGET
	if_equal 0, Score_Minus10
	if_side_affecting AI_TARGET, SIDE_STATUS_SPIKES, Score_Minus10
	end

AI_CBM_FutureSight:
	if_side_affecting AI_TARGET, SIDE_STATUS_FUTUREATTACK, Score_Minus12
	if_side_affecting AI_USER, SIDE_STATUS_FUTUREATTACK, Score_Minus12
	score +1
	end

AI_CBM_Disable:
	if_any_move_disabled AI_TARGET, Score_Minus10
	end

AI_CBM_Encore:
	if_any_move_encored AI_TARGET, Score_Minus10
	if_target_faster AI_CBM_Encore_FirstTurnCheck
	end

AI_CBM_Encore_FirstTurnCheck:
	is_first_turn_for AI_TARGET
	if_equal TRUE, Score_Minus10
	end

AI_CBM_RainDance:
	get_weather
	if_equal AI_WEATHER_RAIN, Score_Minus10
	end

AI_CBM_SunnyDay:
	get_weather
	if_equal AI_WEATHER_SUN, Score_Minus10
	end

AI_CBM_Hail:
	get_weather
	if_equal AI_WEATHER_HAIL, Score_Minus10
	end

AI_CBM_Sandstorm:
	get_weather
	if_equal AI_WEATHER_SANDSTORM, Score_Minus10
	end

AI_CBM_BatonPass:
	count_usable_party_mons AI_USER
	if_equal 0, Score_Minus10
	end

AI_CBM_Roar:
	count_usable_party_mons AI_TARGET
	if_equal 0, Score_Minus10
	get_ability AI_TARGET
	if_equal ABILITY_SUCTION_CUPS, Score_Minus10
	if_status3 AI_TARGET, STATUS3_ROOTED, Score_Minus10
	end

AI_CBM_FakeOut:
	is_first_turn_for AI_USER
	if_equal FALSE, Score_Minus10
	score +2
	end

AI_CBM_Stockpile:
	get_stockpile_count AI_USER
	if_equal 3, Score_Minus10
	end

AI_CBM_SpitUpAndSwallow:
	get_stockpile_count AI_USER
	if_equal 0, Score_Minus10
	end

AI_CBM_HelpingHand:
	if_not_double_battle Score_Minus10
	end

AI_CBM_TrickAndKnockOff:
	get_ability AI_TARGET
	if_equal ABILITY_STICKY_HOLD, Score_Minus10
	end

AI_CBM_Recycle:
	get_used_held_item AI_USER
	if_equal ITEM_NONE, Score_Minus10
	end

AI_CBM_Explosion:
	get_ability AI_TARGET
	if_equal ABILITY_DAMP, Score_Minus10
	end

AI_CBM_OneHitKO:
	get_ability AI_TARGET
	if_equal ABILITY_STURDY, Score_Minus10
	if_level_cond 1, Score_Minus10
	end

AI_CBM_Camouflage:
	get_user_type1
	if_equal TYPE_NORMAL, Score_Minus10
	get_user_type2
	if_equal TYPE_NORMAL, Score_Minus10
	end

AI_CBM_LockOn:
	get_last_used_bank_move AI_USER
	get_move_effect_from_result
	if_effect EFFECT_LOCK_ON, Score_Minus30
	end

AI_CBM_Wish:
	get_last_used_bank_move AI_USER
	get_move_effect_from_result
	if_effect EFFECT_WISH, Score_Minus30
	end

AI_CBM_BellyDrum:
	if_hp_less_than AI_USER, 51, Score_Minus10
AI_CBM_AttackUp:
	if_stat_level_equal AI_USER, STAT_ATK, MAX_STAT_STAGE, Score_Minus10
	end

AI_CBM_DefenseUp:
	if_stat_level_equal AI_USER, STAT_DEF, MAX_STAT_STAGE, Score_Minus10
	end

AI_CBM_SpeedUp:
	if_stat_level_equal AI_USER, STAT_SPEED, MAX_STAT_STAGE, Score_Minus10
	end

AI_CBM_SpAtkUp:
	if_stat_level_equal AI_USER, STAT_SPATK, MAX_STAT_STAGE, Score_Minus10
	end

AI_CBM_SpDefUp:
	if_stat_level_equal AI_USER, STAT_SPDEF, MAX_STAT_STAGE, Score_Minus10
	end

AI_CBM_AccUp:
	if_stat_level_equal AI_USER, STAT_ACC, MAX_STAT_STAGE, Score_Minus10
	end

AI_CBM_EvasionUp:
	if_stat_level_equal AI_USER, STAT_EVASION, MAX_STAT_STAGE, Score_Minus10
	end

AI_CBM_AttackDown:
	if_stat_level_equal AI_TARGET, STAT_ATK, MIN_STAT_STAGE, Score_Minus10
	get_ability AI_TARGET
	if_equal ABILITY_HYPER_CUTTER, Score_Minus10
	end

AI_CBM_DefenseDown:
	if_stat_level_equal AI_TARGET, STAT_DEF, MIN_STAT_STAGE, Score_Minus10
	end

AI_CBM_SpeedDown:
	if_stat_level_equal AI_TARGET, STAT_SPEED, MIN_STAT_STAGE, Score_Minus10
	if_ability AI_TARGET, ABILITY_SPEED_BOOST, Score_Minus10
	end

AI_CBM_SpAtkDown:
	if_stat_level_equal AI_TARGET, STAT_SPATK, MIN_STAT_STAGE, Score_Minus10
	end

AI_CBM_SpDefDown:
	if_stat_level_equal AI_TARGET, STAT_SPDEF, MIN_STAT_STAGE, Score_Minus10
	end

AI_CBM_AccDown:
	if_stat_level_equal AI_TARGET, STAT_ACC, MIN_STAT_STAGE, Score_Minus10
	get_ability AI_TARGET
	if_equal ABILITY_KEEN_EYE, Score_Minus10
	end

AI_CBM_EvasionDown:
	if_stat_level_equal AI_TARGET, STAT_EVASION, MIN_STAT_STAGE, Score_Minus10
	end

AI_CBM_Haze:
	if_stat_level_less_than AI_USER, STAT_ATK, DEFAULT_STAT_STAGE, AI_End
	if_stat_level_less_than AI_USER, STAT_DEF, DEFAULT_STAT_STAGE, AI_End
	if_stat_level_less_than AI_USER, STAT_SPEED, DEFAULT_STAT_STAGE, AI_End
	if_stat_level_less_than AI_USER, STAT_SPATK, DEFAULT_STAT_STAGE, AI_End
	if_stat_level_less_than AI_USER, STAT_SPDEF, DEFAULT_STAT_STAGE, AI_End
	if_stat_level_less_than AI_USER, STAT_ACC, DEFAULT_STAT_STAGE, AI_End
	if_stat_level_less_than AI_USER, STAT_EVASION, DEFAULT_STAT_STAGE, AI_End
	if_stat_level_more_than AI_TARGET, STAT_ATK, DEFAULT_STAT_STAGE, AI_End
	if_stat_level_more_than AI_TARGET, STAT_DEF, DEFAULT_STAT_STAGE, AI_End
	if_stat_level_more_than AI_TARGET, STAT_SPEED, DEFAULT_STAT_STAGE, AI_End
	if_stat_level_more_than AI_TARGET, STAT_SPATK, DEFAULT_STAT_STAGE, AI_End
	if_stat_level_more_than AI_TARGET, STAT_SPDEF, DEFAULT_STAT_STAGE, AI_End
	if_stat_level_more_than AI_TARGET, STAT_ACC, DEFAULT_STAT_STAGE, AI_End
	if_stat_level_more_than AI_TARGET, STAT_EVASION, DEFAULT_STAT_STAGE, AI_End
	goto Score_Minus10

AI_CBM_Memento:
	if_stat_level_more_than AI_TARGET, STAT_ATK, MIN_STAT_STAGE, AI_End
	if_stat_level_more_than AI_TARGET, STAT_SPATK, MIN_STAT_STAGE, AI_End
	goto Score_Minus10

AI_CBM_Tickle:
	if_stat_level_more_than AI_TARGET, STAT_ATK, MIN_STAT_STAGE, AI_End
	if_stat_level_more_than AI_TARGET, STAT_DEF, MIN_STAT_STAGE, AI_End
	goto Score_Minus10

AI_CBM_CosmicPower:
	if_stat_level_equal AI_USER, STAT_DEF, MAX_STAT_STAGE, Score_Minus10
	if_stat_level_equal AI_USER, STAT_SPDEF, MAX_STAT_STAGE, Score_Minus8
	end

AI_CBM_BulkUp:
	if_stat_level_less_than AI_USER, STAT_ATK, MAX_STAT_STAGE, AI_End
	if_stat_level_less_than AI_USER, STAT_DEF, MAX_STAT_STAGE, AI_End
	goto Score_Minus10

AI_CBM_CalmMind:
	if_stat_level_less_than AI_USER, STAT_SPATK, MAX_STAT_STAGE, AI_End
	if_stat_level_less_than AI_USER, STAT_SPDEF, MAX_STAT_STAGE, AI_End
	goto Score_Minus10

AI_CBM_DragonDance:
	if_stat_level_less_than AI_USER, STAT_ATK, MAX_STAT_STAGE, AI_End
	if_stat_level_less_than AI_USER, STAT_SPEED, MAX_STAT_STAGE, AI_End
	goto Score_Minus10

Score_Minus1:
	score -1
	end

Score_Minus2:
	score -2
	end

Score_Minus3:
	score -3
	end

Score_Minus5:
	score -5
	end

Score_Minus8:
	score -8
	end

Score_Minus10:
	score -10
	end

Score_Minus20:
    score -20
    end

Score_Minus12:
	score -12
	end

Score_Minus30:
	score -30
	end

Score_Plus1:
	score +1
	end

Score_Plus2:
	score +2
	end

Score_Plus3:
	score +3
	end

Score_Plus5:
	score +5
	end

Score_Plus10:
	score +10
	end

AI_CheckViability:
	if_target_is_ally AI_End
	if_effect EFFECT_MIRROR_MOVE, AI_CV_MirrorMove
	if_effect EFFECT_EXPLOSION, AI_CV_SelfKO
	if_effect EFFECT_CURSE, AI_CV_Curse
	if_effect EFFECT_BULK_UP | EFFECT_DEFENSE_CURL | EFFECT_DEFENSE_UP | EFFECT_DEFENSE_UP_2, AI_CV_DefenseUp
	if_effect EFFECT_CALM_MIND | EFFECT_SPECIAL_DEFENSE_UP | EFFECT_SPECIAL_DEFENSE_UP_2, AI_CV_SpDefUp
	if_effect EFFECT_COSMIC_POWER | EFFECT_DRAGON_DANCE | EFFECT_MINIMIZE | EFFECT_ATTACK_UP | EFFECT_ATTACK_UP_2 | EFFECT_EVASION_UP | EFFECT_EVASION_UP_2 | EFFECT_SPECIAL_ATTACK_UP | EFFECT_SPECIAL_ATTACK_UP_2 | EFFECT_ACCURACY_DOWN | EFFECT_ACCURACY_DOWN_2 | EFFECT_DEFENSE_DOWN | EFFECT_DEFENSE_DOWN_2 | EFFECT_SPECIAL_DEFENSE_DOWN | EFFECT_SPECIAL_DEFENSE_DOWN_2, AI_CV_Stats
	if_effect EFFECT_SPEED_DOWN | EFFECT_SPEED_DOWN_2 | EFFECT_SPEED_UP | EFFECT_SPEED_UP_2, AI_CV_Speed
	if_effect EFFECT_ATTACK_DOWN | EFFECT_ATTACK_DOWN_2 | EFFECT_TICKLE, AI_CV_AttackDown
	if_effect EFFECT_SPECIAL_ATTACK_DOWN | EFFECT_SPECIAL_ATTACK_DOWN_2, AI_CV_SpAtkDown
	if_effect EFFECT_EVASION_DOWN | EFFECT_EVASION_DOWN_2, AI_CV_EvasionDown
	if_effect EFFECT_SPEED_DOWN_HIT, AI_CV_SpeedDownFromChance
	if_effect EFFECT_BELLY_DRUM, AI_CV_BellyDrum
	if_effect EFFECT_HAZE, AI_CV_Haze
	if_effect EFFECT_ROAR, AI_CV_Phazing
	if_effect EFFECT_PSYCH_UP, AI_CV_PsychUp
	if_effect EFFECT_RESTORE_HP | EFFECT_SOFTBOILED | EFFECT_SWALLOW, AI_CV_Heal
	if_effect EFFECT_MOONLIGHT | EFFECT_MORNING_SUN | EFFECT_SYNTHESIS, AI_CV_HealWeather
	if_effect EFFECT_PAIN_SPLIT, AI_CV_PainSplit
	if_effect EFFECT_REST, AI_CV_Rest
	if_effect EFFECT_WISH, AI_CV_Wish
	if_effect EFFECT_HEAL_BELL | EFFECT_REFRESH, AI_CV_ClearStatus
	if_effect EFFECT_BRICK_BREAK, AI_CV_BrickBreak
	if_effect EFFECT_LIGHT_SCREEN, AI_CV_LightScreen
	if_effect EFFECT_REFLECT, AI_CV_Reflect
	if_effect EFFECT_SLEEP | EFFECT_YAWN, AI_CV_Sleep
	if_effect EFFECT_PARALYZE, AI_CV_Paralyze
	if_effect EFFECT_LEECH_SEED | EFFECT_POISON | EFFECT_TOXIC, AI_CV_Toxic
	if_effect EFFECT_SOLAR_BEAM, AI_CV_SolarBeam
	if_effect EFFECT_RAZOR_WIND | EFFECT_SKULL_BASH | EFFECT_SKY_ATTACK, AI_CV_ChargeUpMove
	if_effect EFFECT_RECHARGE, AI_CV_Recharge
	if_effect EFFECT_SUPER_FANG, AI_CV_SuperFang
	if_effect EFFECT_TRAP | EFFECT_MEAN_LOOK, AI_CV_Trap
	if_effect EFFECT_DISABLE, AI_CV_Disable
	if_effect EFFECT_ENCORE, AI_CV_Encore
	if_effect EFFECT_SUBSTITUTE, AI_CV_Substitute
	if_effect EFFECT_BIDE, AI_CV_Bide
	if_effect EFFECT_COUNTER, AI_CV_Counter
	if_effect EFFECT_MIRROR_COAT, AI_CV_MirrorCoat
	if_effect EFFECT_SNORE, AI_CV_Snore
	if_effect EFFECT_SLEEP_TALK, AI_CV_SleepTalk
	if_effect EFFECT_DESTINY_BOND, AI_CV_DestinyBond
	if_effect EFFECT_GRUDGE, AI_CV_Grudge
	if_effect EFFECT_ENDEAVOR, AI_CV_Endeavor
	if_effect EFFECT_FLAIL, AI_CV_Flail
	if_effect EFFECT_ENDURE, AI_CV_Endure
	if_effect EFFECT_PROTECT, AI_CV_Protect
	if_effect EFFECT_HAIL, AI_CV_Hail
	if_effect EFFECT_RAIN_DANCE, AI_CV_RainDance
	if_effect EFFECT_SANDSTORM, AI_CV_Sandstorm
	if_effect EFFECT_SUNNY_DAY, AI_CV_SunnyDay
	if_effect EFFECT_MEMENTO, AI_CV_SelfKO
	if_effect EFFECT_KNOCK_OFF, AI_CV_KnockOff
	if_effect EFFECT_RECYCLE, AI_CV_Recycle
	if_effect EFFECT_THIEF, AI_CV_Thief
	if_effect EFFECT_TRICK, AI_CV_Trick
	if_effect EFFECT_CAMOUFLAGE, AI_CV_Camouflage
	if_effect EFFECT_ROLE_PLAY | EFFECT_SKILL_SWAP, AI_CV_ChangeSelfAbility
	if_effect EFFECT_TRANSFORM, AI_CV_Transform
	if_effect EFFECT_IMPRISON, AI_CV_Imprison
	if_effect EFFECT_MAGIC_COAT, AI_CV_MagicCoat
	if_effect EFFECT_SNATCH, AI_CV_Snatch
	if_effect EFFECT_MUD_SPORT, AI_CV_MudSport
	if_effect EFFECT_WATER_SPORT, AI_CV_WaterSport
	if_effect EFFECT_FACADE, AI_CV_Facade
	if_effect EFFECT_THAW_HIT, AI_CV_ThawUser
	if_effect EFFECT_ALWAYS_HIT, AI_CV_AlwaysHit
	if_effect EFFECT_BATON_PASS, AI_CV_BatonPass
	if_effect EFFECT_ERUPTION, AI_CV_Eruption
	if_effect EFFECT_FOCUS_PUNCH, AI_CV_FocusPunch
	if_effect EFFECT_FORESIGHT, AI_CV_Foresight
	if_effect EFFECT_LOCK_ON, AI_CV_LockOn
	if_effect EFFECT_MULTI_HIT, AI_CV_MultiHit
	if_effect EFFECT_OVERHEAT, AI_CV_Overheat
	if_effect EFFECT_RAPID_SPIN, AI_CV_RapidSpin
	if_effect EFFECT_REVENGE, AI_CV_Revenge
	if_effect EFFECT_ROLLOUT, AI_CV_Rollout
	if_effect EFFECT_SEMI_INVULNERABLE, AI_CV_SemiInvulnerable
	if_effect EFFECT_SMELLINGSALT, AI_CV_SmellingSalt
	if_effect EFFECT_SPIT_UP, AI_CV_SpitUp
	if_effect EFFECT_PERISH_SONG, AI_CV_SuicideCheck
	if_effect EFFECT_SUPERPOWER, AI_CV_Superpower
	end

AI_CV_MirrorMove:
	is_first_turn_for AI_TARGET
	if_equal TRUE, AI_CV_MirrorMovePenalty
	if_user_faster AI_CV_MirrorMove2
	score -1
AI_CV_MirrorMove2:
	get_last_used_bank_move AI_TARGET
	get_move_target_from_result
	if_equal MOVE_TARGET_BOTH, AI_CV_CheckViability_MirrorMove
	if_equal MOVE_TARGET_FOES_AND_ALLY, AI_CV_CheckViability_MirrorMove
	if_equal MOVE_TARGET_RANDOM, AI_CV_CheckViability_MirrorMove
	if_equal MOVE_TARGET_SELECTED, AI_CV_CheckViability_MirrorMove
	score -2
	end

AI_CV_CheckViability_MirrorMove:
	get_last_used_bank_move AI_TARGET
	get_move_effect_from_result
	if_equal EFFECT_EXPLOSION, AI_CV_SelfKO
	if_equal EFFECT_CURSE, AI_CV_Curse
	if_equal EFFECT_BULK_UP | EFFECT_DEFENSE_CURL | EFFECT_DEFENSE_UP | EFFECT_DEFENSE_UP_2, AI_CV_DefenseUp
	if_equal EFFECT_CALM_MIND | EFFECT_SPECIAL_DEFENSE_UP | EFFECT_SPECIAL_DEFENSE_UP_2, AI_CV_SpDefUp
	if_effect , AI_CV_Stats
	if_equal EFFECT_COSMIC_POWER | EFFECT_DRAGON_DANCE | EFFECT_MINIMIZE | EFFECT_ATTACK_UP | EFFECT_ATTACK_UP_2 | EFFECT_EVASION_UP | EFFECT_EVASION_UP_2 | EFFECT_SPECIAL_ATTACK_UP | EFFECT_SPECIAL_ATTACK_UP_2 | EFFECT_ACCURACY_DOWN | EFFECT_ACCURACY_DOWN_2 | EFFECT_DEFENSE_DOWN | EFFECT_DEFENSE_DOWN_2 | EFFECT_SPECIAL_DEFENSE_DOWN | EFFECT_SPECIAL_DEFENSE_DOWN_2, AI_CV_Stats
	if_equal EFFECT_SPEED_DOWN | EFFECT_SPEED_DOWN_2 | EFFECT_SPEED_UP | EFFECT_SPEED_UP_2, AI_CV_Speed
	if_equal EFFECT_ATTACK_DOWN | EFFECT_ATTACK_DOWN_2 | EFFECT_TICKLE, AI_CV_AttackDown
	if_equal EFFECT_SPECIAL_ATTACK_DOWN | EFFECT_SPECIAL_ATTACK_DOWN_2, AI_CV_SpAtkDown
	if_equal EFFECT_EVASION_DOWN | EFFECT_EVASION_DOWN_2, AI_CV_EvasionDown
	if_equal EFFECT_SPEED_DOWN_HIT, AI_CV_SpeedDownFromChance
	if_equal EFFECT_BELLY_DRUM, AI_CV_BellyDrum
	if_equal EFFECT_HAZE, AI_CV_Haze
	if_equal EFFECT_ROAR, AI_CV_Phazing
	if_equal EFFECT_PSYCH_UP, AI_CV_PsychUp
	if_equal EFFECT_RESTORE_HP | EFFECT_SOFTBOILED | EFFECT_SWALLOW, AI_CV_Heal
	if_equal EFFECT_MOONLIGHT | EFFECT_MORNING_SUN | EFFECT_SYNTHESIS, AI_CV_HealWeather
	if_equal EFFECT_PAIN_SPLIT, AI_CV_PainSplit
	if_equal EFFECT_REST, AI_CV_Rest
	if_equal EFFECT_WISH, AI_CV_Wish
	if_equal EFFECT_HEAL_BELL | EFFECT_REFRESH, AI_CV_ClearStatus
	if_equal EFFECT_BRICK_BREAK, AI_CV_BrickBreak
	if_equal EFFECT_LIGHT_SCREEN, AI_CV_LightScreen
	if_equal EFFECT_REFLECT, AI_CV_Reflect
	if_equal EFFECT_SLEEP | EFFECT_YAWN, AI_CV_Sleep
	if_equal EFFECT_PARALYZE, AI_CV_Paralyze
	if_equal EFFECT_LEECH_SEED | EFFECT_POISON | EFFECT_TOXIC, AI_CV_Toxic
	if_equal EFFECT_SOLAR_BEAM, AI_CV_SolarBeam
	if_equal EFFECT_RAZOR_WIND | EFFECT_SKULL_BASH | EFFECT_SKY_ATTACK, AI_CV_ChargeUpMove
	if_equal EFFECT_RECHARGE, AI_CV_Recharge
	if_equal EFFECT_SUPER_FANG, AI_CV_SuperFang
	if_equal EFFECT_TRAP | EFFECT_MEAN_LOOK, AI_CV_Trap
	if_equal EFFECT_DISABLE, AI_CV_Disable
	if_equal EFFECT_ENCORE, AI_CV_Encore
	if_equal EFFECT_SUBSTITUTE, AI_CV_Substitute
	if_equal EFFECT_BIDE, AI_CV_Bide
	if_equal EFFECT_COUNTER, AI_CV_Counter
	if_equal EFFECT_MIRROR_COAT, AI_CV_MirrorCoat
	if_equal EFFECT_SNORE, AI_CV_Snore
	if_equal EFFECT_SLEEP_TALK, AI_CV_SleepTalk
	if_equal EFFECT_DESTINY_BOND, AI_CV_DestinyBond
	if_equal EFFECT_GRUDGE, AI_CV_Grudge
	if_equal EFFECT_ENDEAVOR, AI_CV_Endeavor
	if_equal EFFECT_FLAIL, AI_CV_Flail
	if_equal EFFECT_ENDURE, AI_CV_Endure
	if_equal EFFECT_PROTECT, AI_CV_Protect
	if_equal EFFECT_HAIL, AI_CV_Hail
	if_equal EFFECT_RAIN_DANCE, AI_CV_RainDance
	if_equal EFFECT_SANDSTORM, AI_CV_Sandstorm
	if_equal EFFECT_SUNNY_DAY, AI_CV_SunnyDay
	if_equal EFFECT_SEMI_INVULNERABLE, AI_CV_SemiInvulnerable
	if_equal EFFECT_SPIT_UP, AI_CV_SpitUp
	if_equal EFFECT_MEMENTO, AI_CV_SelfKO
	if_equal EFFECT_KNOCK_OFF, AI_CV_KnockOff
	if_equal EFFECT_RECYCLE, AI_CV_Recycle
	if_equal EFFECT_THIEF, AI_CV_Thief
	if_equal EFFECT_TRICK, AI_CV_Trick
	if_equal EFFECT_CAMOUFLAGE, AI_CV_Camouflage
	if_equal EFFECT_ROLE_PLAY | EFFECT_SKILL_SWAP, AI_CV_ChangeSelfAbility
	if_equal EFFECT_TRANSFORM, AI_CV_Transform
	if_equal EFFECT_IMPRISON, AI_CV_Imprison
	if_equal EFFECT_MAGIC_COAT, AI_CV_MagicCoat
	if_equal EFFECT_SNATCH, AI_CV_Snatch
	if_equal EFFECT_MUD_SPORT, AI_CV_MudSport
	if_equal EFFECT_WATER_SPORT, AI_CV_WaterSport
	if_equal EFFECT_FACADE, AI_CV_Facade
	if_equal EFFECT_THAW_HIT, AI_CV_ThawUser
	if_equal EFFECT_ALWAYS_HIT, AI_CV_AlwaysHit
	if_equal EFFECT_BATON_PASS, AI_CV_BatonPass
	if_equal EFFECT_ERUPTION, AI_CV_Eruption
	if_equal EFFECT_FOCUS_PUNCH, AI_CV_FocusPunch
	if_equal EFFECT_FORESIGHT, AI_CV_Foresight
	if_equal EFFECT_LOCK_ON, AI_CV_LockOn
	if_equal EFFECT_MULTI_HIT, AI_CV_MultiHit
	if_equal EFFECT_OVERHEAT, AI_CV_Overheat
	if_equal EFFECT_PERISH_SONG, AI_CV_SuicideCheck
	if_equal EFFECT_RAPID_SPIN, AI_CV_RapidSpin
	if_equal EFFECT_REVENGE, AI_CV_Revenge
	if_equal EFFECT_ROLLOUT, AI_CV_Rollout
	if_equal EFFECT_SMELLINGSALT, AI_CV_SmellingSalt
	if_equal EFFECT_SUPERPOWER, AI_CV_Superpower
	end

AI_CV_MirrorMovePenalty:
	score -10
	end

AI_CV_MultiHit:
	if_status2 AI_TARGET, STATUS2_SUBSTITUTE, AI_MultiHit_ScorePlus3
	end

AI_MultiHit_ScorePlus3:
	score +3
	end

AI_CV_Sleep:
	get_last_used_bank_move AI_USER
	get_move_effect_from_result
	if_not_equal EFFECT_SLEEP, AI_CV_SleepEncourageSlpDamage_Check
	if_random_less_than 205, AI_CV_SleepEncourageSlpDamage_Check
	score +30
AI_CV_SleepEncourageSlpDamage_Check:
	if_has_move_with_effect AI_USER, EFFECT_DREAM_EATER, AI_CV_SleepEncourageSlpDamage
	if_has_move_with_effect AI_USER, EFFECT_NIGHTMARE, AI_CV_SleepEncourageSlpDamage
	goto AI_CV_Sleep_End

AI_CV_SleepEncourageSlpDamage:
	if_random_less_than 128, AI_CV_Sleep_End
	score +1
AI_CV_Sleep_End:
	end

AI_CV_Toxic:
	is_first_turn_for AI_USER
	if_equal FALSE, AI_CV_Toxic_StatBoosts
	score +1
AI_CV_Toxic_StatBoosts:
	if_has_move_with_effect AI_TARGET, EFFECT_BULK_UP | EFFECT_DEFENSE_CURL | EFFECT_DEFENSE_UP | EFFECT_DEFENSE_UP_2 | EFFECT_CALM_MIND | EFFECT_SPECIAL_DEFENSE_UP | EFFECT_SPECIAL_DEFENSE_UP_2 | EFFECT_COSMIC_POWER | EFFECT_DRAGON_DANCE | EFFECT_MINIMIZE | EFFECT_ATTACK_UP | EFFECT_ATTACK_UP_2 | EFFECT_EVASION_UP | EFFECT_EVASION_UP_2 | EFFECT_SPECIAL_ATTACK_UP | EFFECT_SPECIAL_ATTACK_UP_2 | EFFECT_SPEED_UP | EFFECT_SPEED_UP_2, AI_CV_Toxic_StatBoosts_Plus1
	goto AI_CV_LeechOverToxic

AI_CV_Toxic_StatBoosts_Plus1:
	score +1
AI_CV_LeechOverToxic:
	if_effect EFFECT_LEECH_SEED, AI_CV_LeechOverToxic2
	end

AI_CV_LeechOverToxic2:
	if_has_move_with_effect AI_USER, EFFECT_POISON | EFFECT_TOXIC, AI_CV_LeechOverToxic_Plus1
	end

AI_CV_LeechOverToxic_Plus1:
	score +1
	end

AI_CV_Paralyze:
	if_target_faster AI_CV_Paralyze2
	if_hp_more_than AI_USER, 70, AI_CV_Paralyze_End
	score -1
	goto AI_CV_Paralyze_End

AI_CV_Paralyze2:
	if_random_less_than 20, AI_CV_Paralyze_End
	score +3
AI_CV_Paralyze_End:
	end

AI_CV_Snore:
	if_status AI_USER, STATUS1_SLEEP, AI_CV_Asleep
	goto AI_CV_Awake

AI_CV_SleepTalk:
	if_status AI_USER, STATUS1_SLEEP, AI_CV_Asleep
	goto AI_CV_Awake

AI_CV_Asleep:
	get_last_used_bank_move AI_USER
	get_move_effect_from_result
	if_equal EFFECT_SLEEP_TALK, AI_CV_Asleep2
	if_equal EFFECT_SNORE, AI_CV_Asleep2
	goto AI_CV_Asleep_ScorePlus2

AI_CV_Asleep2:
	if_hp_more_than AI_USER, 33, AI_CV_SleepTalk3
	goto AI_CV_Asleep_ScorePlus2

AI_CV_SleepTalk3:
	if_hp_less_than AI_USER, 51, AI_CV_Awake
	goto AI_CV_Asleep_ScorePlus2

AI_CV_Asleep_ScorePlus2:
	score +2
	end

AI_CV_Awake:
	score -10
	end

AI_CV_EvasionDown:
	if_stat_level_less_than AI_TARGET, STAT_EVASION, 5, AI_CV_Evasion_ScoreMinus10
	goto AI_CV_Stats

AI_CV_Evasion_ScoreMinus10:
	score -10
	end

AI_CV_AttackDown:
	if_in_bytes AI_CV_FightingAttacks, AI_CV_Stats
	if_in_bytes AI_CV_GhostAttacks, AI_CV_Stats
	if_in_bytes AI_CV_GroundAttacks, AI_CV_Stats
	if_in_bytes AI_CV_NormalAttacks, AI_CV_Stats
	if_in_bytes AI_CV_PoisonAttacks, AI_CV_Stats
	if_in_bytes AI_CV_OtherPhysicalAttacks, AI_CV_Stats
	if_has_move AI_TARGET, MOVE_DOOM_DESIRE | MOVE_FURY_CUTTER | MOVE_ROLLOUT | MOVE_SNORE, AI_CV_Stats
	score -10
	end

AI_CV_SpAtkDown:
	if_in_bytes AI_CV_ElectricAttacks, AI_CV_Stats
	if_in_bytes AI_CV_FireAttacks, AI_CV_Stats
	if_in_bytes AI_CV_PsychicAttacks, AI_CV_Stats
	if_in_bytes AI_CV_WaterAttacks, AI_CV_Stats
	if_in_bytes AI_CV_OtherSpecialAttacks, AI_CV_Stats
	if_has_move AI_TARGET, MOVE_DREAM_EATER | MOVE_FUTURE_SIGHT | MOVE_ICE_BALL | MOVE_WEATHER_BALL, AI_CV_Stats
	score -10
	end

AI_CV_Curse:
	get_user_type1
	if_equal TYPE_GHOST, AI_CV_CurseGhost
	get_user_type2
	if_equal TYPE_GHOST, AI_CV_CurseGhost
AI_CV_DefenseUp:
	if_in_bytes AI_CV_FightingAttacks, AI_CV_DefensesUp_Plus1
	if_in_bytes AI_CV_GhostAttacks, AI_CV_DefensesUp_Plus1
	if_in_bytes AI_CV_GroundAttacks, AI_CV_DefensesUp_Plus1
	if_in_bytes AI_CV_NormalAttacks, AI_CV_DefensesUp_Plus1
	if_in_bytes AI_CV_PoisonAttacks, AI_CV_DefensesUp_Plus1
	if_in_bytes AI_CV_OtherPhysicalAttacks, AI_CV_DefensesUp_Plus1
	if_has_move AI_TARGET, MOVE_DOOM_DESIRE | MOVE_FURY_CUTTER | MOVE_ROLLOUT | MOVE_SNORE, AI_CV_DefensesUp_Plus1
	goto AI_CV_Stats

AI_CV_SpDefUp:
	if_in_bytes AI_CV_ElectricAttacks, AI_CV_DefensesUp_Plus1
	if_in_bytes AI_CV_FireAttacks, AI_CV_DefensesUp_Plus1
	if_in_bytes AI_CV_PsychicAttacks, AI_CV_DefensesUp_Plus1
	if_in_bytes AI_CV_WaterAttacks, AI_CV_DefensesUp_Plus1
	if_in_bytes AI_CV_OtherSpecialAttacks, AI_CV_DefensesUp_Plus1
	if_has_move AI_TARGET, MOVE_DREAM_EATER | MOVE_FUTURE_SIGHT | MOVE_ICE_BALL | MOVE_WEATHER_BALL, AI_CV_DefensesUp_Plus1
	goto AI_CV_Stats

AI_CV_DefensesUp_Plus1:
	score +1
AI_CV_Stats:
	if_hp_not_equal AI_USER, 100, AI_CV_Stats2
	if_has_move_with_effect AI_USER, EFFECT_SUBSTITUTE, AI_CV_Stats_Minus2_Random
AI_CV_Stats2:
	if_status3 AI_USER, STATUS3_YAWN, AI_CV_Stats_Minus2
	if_target_faster AI_CV_Stats_Cautious
	if_status AI_USER, STATUS1_BURN | STATUS1_PARALYSIS | STATUS1_POISON | STATUS1_TOXIC_POISON, AI_CV_Stats_Statused
	if_status2 AI_USER, STATUS2_CONFUSION | STATUS2_INFATUATION, AI_CV_Stats_Statused
	if_status3 AI_USER, STATUS3_LEECHSEED, AI_CV_Stats_Statused
	if_hp_less_than AI_USER, 37, AI_CV_Stats_Minus2
	if_hp_more_than AI_USER, 73, AI_CV_Stats_Plus1
	if_hp_less_than AI_USER, 54, AI_CV_Stats_Minus2_Random
	if_hp_more_than AI_USER, 62, AI_CV_Stats_Plus1_Random
	if_random_less_than 128, AI_CV_Stats_Plus1
	if_random_less_than 64, AI_CV_Stats_Minus2
	goto AI_CV_Stats_StatusCheck

AI_CV_Stats_Cautious:
	if_status AI_USER, STATUS1_BURN | STATUS1_PARALYSIS | STATUS1_POISON | STATUS1_TOXIC_POISON, AI_CV_Stats_Cautious_Statused
	if_status2 AI_USER, STATUS2_CONFUSION | STATUS2_CURSED | STATUS2_INFATUATION, AI_CV_Stats_Cautious_Statused
	if_status3 AI_USER, STATUS3_LEECHSEED, AI_CV_Stats_Cautious_Statused
AI_CV_Stats_Statused:
	if_hp_less_than AI_USER, 50, AI_CV_Stats_Minus2
	if_hp_more_than AI_USER, 90, AI_CV_Stats_Plus1
	if_hp_less_than AI_USER, 62, AI_CV_Stats_Minus2_Random
	if_hp_more_than AI_USER, 73, AI_CV_Stats_Plus1_Random
	if_random_less_than 96, AI_CV_Stats_Plus1
	if_random_less_than 128, AI_CV_Stats_Minus2
	goto AI_CV_Stats_StatusCheck

AI_CV_Stats_Cautious_Statused:
	if_hp_less_than AI_USER, 62, AI_CV_Stats_Minus2
	if_hp_equal AI_USER, 100, AI_CV_Stats_Plus1
	if_hp_less_than AI_USER, 73, AI_CV_Stats_Minus2_Random
	if_hp_more_than AI_USER, 90, AI_CV_Stats_Plus1_Random
	if_random_less_than 64, AI_CV_Stats_Plus1
	if_random_less_than 160, AI_CV_Stats_Minus2
	goto AI_CV_Stats_StatusCheck

AI_CV_Stats_Plus1_Random:
	if_random_less_than 96, AI_End
AI_CV_Stats_Plus1:
	score +1
	end

AI_CV_Stats_Minus2_Random:
	if_random_less_than 96, AI_End
AI_CV_Stats_Minus2:
	score -2
	end

AI_CV_CurseGhost:
	if_hp_more_than AI_USER, 90, AI_CV_Curse_End
	score -2
	if_hp_more_than AI_USER, 50, AI_CV_Curse_End
	score -30
	end

AI_CV_BellyDrum:
	if_status2 AI_USER, STATUS2_SUBSTITUTE, AI_CV_BellyDrum_Plus1
	if_hp_less_than AI_USER, 74, AI_CV_BellyDrum_Minus2
	if_stat_level_more_than AI_USER, STAT_DEF, 9, AI_CV_BellyDrum_Plus1
	if_stat_level_more_than AI_USER, STAT_SPDEF, 9, AI_CV_BellyDrum_Plus1
	if_hp_less_than AI_USER, 78, AI_CV_BellyDrum_Minus2
	if_stat_level_more_than AI_USER, STAT_DEF, 8, AI_CV_BellyDrum_Plus1
	if_stat_level_more_than AI_USER, STAT_SPDEF, 8, AI_CV_BellyDrum_Plus1
	if_hp_less_than AI_USER, 85, AI_CV_BellyDrum_Minus2
	if_stat_level_more_than AI_USER, STAT_DEF, 7, AI_CV_BellyDrum_Plus1
	if_stat_level_more_than AI_USER, STAT_SPDEF, 7, AI_CV_BellyDrum_Plus1
	if_hp_less_than AI_USER, 90, AI_CV_BellyDrum_Minus2
	if_stat_level_more_than AI_USER, STAT_DEF, 6, AI_CV_BellyDrum_Plus1
	if_stat_level_more_than AI_USER, STAT_SPDEF, 6, AI_CV_BellyDrum_Plus1
	if_hp_less_than AI_USER, 94, AI_CV_BellyDrum_Minus2
	end

AI_CV_BellyDrum_Plus1:
	score +1
	end

AI_CV_BellyDrum_Minus2:
	score -2
	end

AI_CV_SpeedDownFromChance:
	get_considered_move_second_eff_chance
	if_more_than 20, AI_CV_Speed
	end

AI_CV_Speed:
	if_target_faster AI_CV_Speed2
	score -3
	goto AI_CV_Speed_End

AI_CV_Speed2:
	if_random_less_than 70, AI_CV_Speed_End
	score +3
AI_CV_Speed_End:
	end

AI_CV_PsychUp:
	get_last_used_bank_move AI_USER
	if_equal MOVE_PSYCH_UP, AI_CV_Haze_ScoreMinus3
AI_CV_Haze:
	score -1
	if_stat_level_more_than AI_USER, STAT_ATK, 6, AI_CV_Haze_ScoreMinus3
	if_stat_level_more_than AI_USER, STAT_DEF, 6, AI_CV_Haze_ScoreMinus3
	if_stat_level_more_than AI_USER, STAT_SPATK, 6, AI_CV_Haze_ScoreMinus3
	if_stat_level_more_than AI_USER, STAT_SPDEF, 6, AI_CV_Haze_ScoreMinus3
	if_stat_level_more_than AI_USER, STAT_SPEED, 6, AI_CV_Haze_ScoreMinus3
	if_stat_level_more_than AI_USER, STAT_EVASION, 6, AI_CV_Haze_ScoreMinus3
	if_stat_level_less_than AI_TARGET, STAT_ATK, 6, AI_CV_Haze_ScoreMinus3
	if_stat_level_less_than AI_TARGET, STAT_DEF, 6, AI_CV_Haze_ScoreMinus3
	if_stat_level_less_than AI_TARGET, STAT_SPATK, 6, AI_CV_Haze_ScoreMinus3
	if_stat_level_less_than AI_TARGET, STAT_SPDEF, 6, AI_CV_Haze_ScoreMinus3
	if_stat_level_less_than AI_TARGET, STAT_SPEED, 6, AI_CV_Haze_ScoreMinus3
	if_stat_level_less_than AI_TARGET, STAT_ACC, 6, AI_CV_Haze_ScoreMinus3
	if_stat_level_more_than AI_TARGET, STAT_ATK, 7, AI_CV_Haze_ScorePlus2
	if_stat_level_more_than AI_TARGET, STAT_DEF, 6, AI_CV_Haze_ScorePlus2
	if_stat_level_more_than AI_TARGET, STAT_SPATK, 7, AI_CV_Haze_ScorePlus2
	if_stat_level_more_than AI_TARGET, STAT_SPDEF, 6, AI_CV_Haze_ScorePlus2
	if_stat_level_more_than AI_TARGET, STAT_SPEED, 6, AI_CV_Haze_ScorePlus2
	if_stat_level_more_than AI_TARGET, STAT_EVASION, 7, AI_CV_Haze_ScorePlus2
	if_stat_level_less_than AI_USER, STAT_ATK, 5, AI_CV_Haze_ScorePlus2
	if_stat_level_less_than AI_USER, STAT_DEF, 6, AI_CV_Haze_ScorePlus2
	if_stat_level_less_than AI_USER, STAT_SPATK, 5, AI_CV_Haze_ScorePlus2
	if_stat_level_less_than AI_USER, STAT_SPDEF, 6, AI_CV_Haze_ScorePlus2
	if_stat_level_less_than AI_USER, STAT_SPEED, 6, AI_CV_Haze_ScorePlus2
	if_stat_level_less_than AI_USER, STAT_ACC, 5, AI_CV_Haze_ScorePlus2
	end

AI_CV_Haze_ScorePlus2:
	score +2
	end

AI_CV_Haze_ScoreMinus3:
	score -3
	end

AI_CV_Phazing:
	count_usable_party_mons AI_TARGET
	if_equal 0, Score_Minus30
	if_side_affecting AI_TARGET, SIDE_STATUS_SPIKES, AI_CV_Phazing2
	goto AI_CV_PhazingStatCheck

AI_CV_Phazing2:
	score +1
AI_CV_PhazingStatCheck:
	if_stat_level_more_than AI_TARGET, STAT_ATK, 7, AI_CV_PhazingEncourage
	if_stat_level_more_than AI_TARGET, STAT_DEF, 7, AI_CV_PhazingEncourage
	if_stat_level_more_than AI_TARGET, STAT_SPATK, 7, AI_CV_PhazingEncourage
	if_stat_level_more_than AI_TARGET, STAT_SPDEF, 7, AI_CV_PhazingEncourage
	if_stat_level_more_than AI_TARGET, STAT_SPEED, 7, AI_CV_PhazingEncourage
	if_stat_level_more_than AI_TARGET, STAT_EVASION, 7, AI_CV_PhazingEncourage
	if_stat_level_less_than AI_TARGET, STAT_ATK, 6, AI_CV_PhazingDiscourage
	if_stat_level_less_than AI_TARGET, STAT_DEF, 6, AI_CV_PhazingDiscourage
	if_stat_level_less_than AI_TARGET, STAT_SPATK, 6, AI_CV_PhazingDiscourage
	if_stat_level_less_than AI_TARGET, STAT_SPDEF, 6, AI_CV_PhazingDiscourage
	if_stat_level_less_than AI_TARGET, STAT_SPEED, 6, AI_CV_PhazingDiscourage
	if_stat_level_less_than AI_TARGET, STAT_EVASION, 6, AI_CV_PhazingDiscourage
	if_stat_level_less_than AI_TARGET, STAT_ACC, 6, AI_CV_PhazingDiscourage
	goto AI_CV_PhazingEnd

AI_CV_PhazingDiscourage:
	score -1
	goto AI_CV_PhazingEnd

AI_CV_PhazingEncourage:
	score +1
AI_CV_PhazingEnd:
	end

AI_CV_HealWeather:
	get_weather
	if_equal AI_WEATHER_HAIL, AI_CV_HealWeather_Minus2
	if_equal AI_WEATHER_RAIN, AI_CV_HealWeather_Minus2
	if_equal AI_WEATHER_SANDSTORM, AI_CV_HealWeather_Minus2
	goto AI_CV_Heal

AI_CV_HealWeather_Minus2:
	score -2
AI_CV_Heal:
	if_hp_more_than AI_USER, 80, AI_CV_Heal_HighHP
	if_target_faster AI_CV_Heal_Slower
	if_hp_less_than AI_USER, 48, AI_CV_Heal_Plus2
	if_hp_less_than AI_USER, 60, AI_CV_Heal_CheckSnatch
	if_random_less_than 70, AI_CV_Heal_CheckSnatch
	goto AI_CV_Heal_HighHP

AI_CV_Heal_Slower:
	if_hp_less_than AI_USER, 55, AI_CV_Heal_Plus2
	if_hp_less_than AI_USER, 72, AI_CV_Heal_CheckSnatch
	if_random_less_than 30, AI_CV_Heal_CheckSnatch
AI_CV_Heal_HighHP:
	score -3
	end

AI_CV_Heal_CheckSnatch:
	if_doesnt_have_move_with_effect AI_TARGET, EFFECT_SNATCH, AI_CV_Heal_Plus2_Random
	if_random_less_than 100, AI_End
AI_CV_Heal_Plus2_Random:
	if_random_less_than 20, AI_End
AI_CV_Heal_Plus2:
	score +2
	end

AI_CV_Rest:
	if_hp_more_than AI_USER, 70, AI_CV_Rest_HighHP
	if_target_faster AI_CV_Rest_Slower
	if_hp_less_than AI_USER, 28, AI_CV_Rest_Plus2
	if_hp_less_than AI_USER, 40, AI_CV_Rest_CheckSnatch
	if_random_less_than 70, AI_CV_Rest_CheckSnatch
	goto AI_CV_Rest_HighHP

AI_CV_Rest_Slower:
	if_hp_less_than AI_USER, 40, AI_CV_Rest_Plus2
	if_hp_less_than AI_USER, 60, AI_CV_Rest_CheckSnatch
	if_random_less_than 30, AI_CV_Rest_CheckSnatch
AI_CV_Rest_HighHP:
	score -3
	end

AI_CV_Rest_CheckSnatch:
	if_doesnt_have_move_with_effect AI_TARGET, EFFECT_SNATCH, AI_CV_Rest_Plus2_Random
	if_random_less_than 50, AI_End
AI_CV_Rest_Plus2_Random:
	if_random_less_than 10, AI_End
AI_CV_Rest_Plus2:
	score +2
	end

AI_CV_Wish:
	if_hp_more_than AI_USER, 90, AI_CV_Wish_HighHP
	if_target_faster AI_CV_Wish_Slower
	if_hp_less_than AI_USER, 52, AI_CV_Wish_Plus2
	if_hp_less_than AI_USER, 70, AI_CV_Wish_Plus2_Random
	if_random_less_than 70, AI_CV_Wish_Plus2_Random
	goto AI_CV_Wish_HighHP

AI_CV_Wish_Slower:
	if_hp_less_than AI_USER, 63, AI_CV_Wish_Plus2
	if_hp_less_than AI_USER, 77, AI_CV_Wish_Plus2_Random
	if_random_less_than 128, AI_CV_Wish_Plus2_Random
AI_CV_Wish_HighHP:
	score -3
	end

AI_CV_Wish_Plus2_Random:
	if_random_less_than 96, AI_End
AI_CV_Wish_Plus2:
	score +2
	end

AI_CV_PainSplit:
	if_hp_less_than AI_TARGET, 80, AI_CV_PainSplit_Minus1
	if_target_faster AI_CV_PainSplit2
	if_hp_more_than AI_USER, 40, AI_CV_PainSplit_Minus1
	score +1
	goto AI_CV_PainSplit_End

AI_CV_PainSplit2:
	if_hp_more_than AI_USER, 60, AI_CV_PainSplit_Minus1
	score +1
	goto AI_CV_PainSplit_End

AI_CV_PainSplit_Minus1:
	score -1
AI_CV_PainSplit_End:
	end

AI_CV_Reflect:
	if_in_bytes AI_CV_FightingAttacks, AI_CV_UseScreen
	if_in_bytes AI_CV_GhostAttacks, AI_CV_UseScreen
	if_in_bytes AI_CV_GroundAttacks, AI_CV_UseScreen
	if_in_bytes AI_CV_NormalAttacks, AI_CV_UseScreen
	if_in_bytes AI_CV_PoisonAttacks, AI_CV_UseScreen
	if_in_bytes AI_CV_OtherPhysicalAttacks, AI_CV_UseScreen
	if_has_move AI_TARGET, MOVE_DOOM_DESIRE | MOVE_FURY_CUTTER | MOVE_ROLLOUT | MOVE_SNORE, AI_CV_UseScreen
	goto AI_CV_DontUseScreen

AI_CV_LightScreen:
	if_in_bytes AI_CV_ElectricAttacks, AI_CV_UseScreen
	if_in_bytes AI_CV_FireAttacks, AI_CV_UseScreen
	if_in_bytes AI_CV_PsychicAttacks, AI_CV_UseScreen
	if_in_bytes AI_CV_WaterAttacks, AI_CV_UseScreen
	if_in_bytes AI_CV_OtherSpecialAttacks, AI_CV_UseScreen
	if_has_move AI_TARGET, MOVE_DREAM_EATER | MOVE_FUTURE_SIGHT | MOVE_ICE_BALL | MOVE_WEATHER_BALL, AI_CV_UseScreen
AI_CV_DontUseScreen:
	if_random_less_than 4, AI_End
	score -2
	end

AI_CV_UseScreen:
	if_has_move_with_effect AI_TARGET, EFFECT_BRICK_BREAK, AI_CV_UseScreen_LowerOdds
	if_random_less_than 96, AI_End
	score +1
	end

AI_CV_UseScreen_LowerOdds:
	if_random_less_than 192, AI_End
	score +1
	end

AI_CV_BrickBreak:
	if_side_affecting AI_TARGET, SIDE_STATUS_REFLECT, AI_CV_BrickBreak_Plus1
	if_side_affecting AI_TARGET, SIDE_STATUS_LIGHTSCREEN, AI_CV_BrickBreak_Plus1
	end

AI_CV_BrickBreak_Plus1:
	score +1
	end

AI_CV_SuperFang:
	if_hp_more_than AI_TARGET, 40, AI_CV_SuperFang_End
	score -1
AI_CV_SuperFang_End:
	end

AI_CV_Trap:
	if_status AI_TARGET, STATUS1_TOXIC_POISON, AI_CV_Trap_Plus2
	if_status AI_TARGET, STATUS1_BURN | STATUS1_POISON, AI_CV_Trap_Plus2_Random
	if_status2 AI_TARGET, STATUS2_CURSED, AI_CV_Trap_Plus2
	if_status3 AI_TARGET, STATUS3_PERISH_SONG, AI_CV_Trap_Plus2
	goto AI_CV_TrapCombo

AI_CV_Trap_Plus2_Random:
	if_random_less_than 128, AI_CV_TrapCombo
AI_CV_Trap_Plus2:
	score +2
AI_CV_TrapCombo:
	if_has_move_with_effect AI_USER, EFFECT_PERISH_SONG, AI_CV_TrapCombo_Plus2
	get_user_type1
	if_equal TYPE_GHOST, AI_CV_TrapCombo_Curse
	get_user_type2
	if_equal TYPE_GHOST, AI_CV_TrapCombo_Curse
	goto AI_CV_Trap_Random

AI_CV_TrapCombo_Curse:
	if_has_move_with_effect AI_USER, EFFECT_CURSE, AI_CV_TrapCombo_Plus2
	goto AI_CV_Trap_Random

AI_CV_TrapCombo_Plus2:
	score +2
AI_CV_Trap_Random:
	if_random_less_than 16, AI_End
	score -1
	end

AI_CV_Transform:
	if_target_faster AI_CV_Transform_TargetFaster_ScorePlus1
	goto AI_CV_Transform_StatusCheck

AI_CV_Transform_TargetFaster_ScorePlus1:
	score +1
AI_CV_Transform_StatusCheck:
	if_status AI_TARGET, STATUS1_SLEEP | STATUS1_FREEZE, AI_CV_Transform_Status_ScorePlus1
	goto AI_CV_Transform_EncoreCheck

AI_CV_Transform_Status_ScorePlus1:
	score +1
AI_CV_Transform_EncoreCheck:
	if_any_move_encored AI_TARGET, AI_CV_Transform_Encore_ScorePlus1
	goto AI_CV_Transform_ScreenCheck

AI_CV_Transform_Encore_ScorePlus1:
	score +1
AI_CV_Transform_ScreenCheck:
	if_side_affecting AI_USER, SIDE_STATUS_REFLECT | SIDE_STATUS_LIGHTSCREEN, AI_CV_Transform_Screen_ScorePlus1
	goto AI_CV_Transform_HPCheck

AI_CV_Transform_Screen_ScorePlus1:
	score +1
AI_CV_Transform_HPCheck:
	if_hp_less_than AI_USER, 50, AI_CV_Transform_HP_ScoreMinus1
	end

AI_CV_Transform_HP_ScoreMinus1:
	score -1
	end

AI_CV_Camouflage:
	get_target_type1
	if_equal TYPE_FIGHTING, AI_CV_Camouflage_Fighting_ScoreMinus1
	get_target_type2
	if_equal TYPE_FIGHTING, AI_CV_Camouflage_Fighting_ScoreMinus1
	get_last_used_bank_move AI_TARGET
	get_move_type_from_result
	if_not_equal TYPE_FIGHTING, AI_CV_Camouflage_CheckTypeMatchup
	get_last_used_bank_move AI_TARGET
	get_move_power_from_result
	if_equal 0, AI_CV_Camouflage_CheckTypeMatchup
	goto AI_CV_Camouflage_Fighting_ScoreMinus1

AI_CV_Camouflage_Fighting_ScoreMinus1:
	score -1
AI_CV_Camouflage_CheckTypeMatchup:
	get_target_type1
	if_equal TYPE_BUG, AI_CV_Camouflage_ImproveTypeMatchup_ScorePlus1
	if_equal TYPE_DARK, AI_CV_Camouflage_ImproveTypeMatchup_ScorePlus1
	if_equal TYPE_ELECTRIC, AI_CV_Camouflage_ImproveTypeMatchup_ScorePlus1
	if_equal TYPE_GHOST, AI_CV_Camouflage_ImproveTypeMatchup_ScorePlus1
	if_equal TYPE_GRASS, AI_CV_Camouflage_ImproveTypeMatchup_ScorePlus1
	get_target_type2
	if_equal TYPE_BUG, AI_CV_Camouflage_ImproveTypeMatchup_ScorePlus1
	if_equal TYPE_DARK, AI_CV_Camouflage_ImproveTypeMatchup_ScorePlus1
	if_equal TYPE_ELECTRIC, AI_CV_Camouflage_ImproveTypeMatchup_ScorePlus1
	if_equal TYPE_GHOST, AI_CV_Camouflage_ImproveTypeMatchup_ScorePlus1
	if_equal TYPE_GRASS, AI_CV_Camouflage_ImproveTypeMatchup_ScorePlus1
	end

AI_CV_Camouflage_ImproveTypeMatchup_ScorePlus1:
	score +1
	end

AI_CV_ChangeSelfAbility:
	get_ability AI_USER
	if_in_bytes AI_CV_ChangeSelfAbility_AbilitiesToEncourage, AI_CV_ChangeSelfAbility2
	get_ability AI_TARGET
	if_in_bytes AI_CV_ChangeSelfAbility_AbilitiesToEncourage, AI_CV_ChangeSelfAbility3
AI_CV_ChangeSelfAbility2:
	score -10
	goto AI_CV_ChangeSelfAbility_End

AI_CV_ChangeSelfAbility3:
	if_random_less_than 50, AI_CV_ChangeSelfAbility_End
	score +2
AI_CV_ChangeSelfAbility_End:
	end

AI_CV_ThawUser:
	if_status AI_USER, STATUS1_FREEZE, AI_CV_ThawUser_ScorePlus32
	end

AI_CV_ThawUser_ScorePlus32:
	score +32
	end

AI_CV_Facade:
	if_not_status AI_USER, STATUS1_POISON | STATUS1_BURN | STATUS1_PARALYSIS | STATUS1_TOXIC_POISON, AI_CV_Facade_End
	score +1
AI_CV_Facade_End:
	end

AI_CV_Substitute:
	if_status AI_TARGET, STATUS1_FREEZE | STATUS1_SLEEP, AI_CV_Substitute_TargetImmobile_Plus2
	if_status AI_TARGET, STATUS1_PARALYSIS, AI_CV_Substitute_TargetParalyzed_Plus1
	goto AI_CV_Substitute2

AI_CV_Substitute_TargetParalyzed_Plus1:
	score +1
	goto AI_CV_Substitute2

AI_CV_Substitute_TargetImmobile_Plus2:
	score +2
AI_CV_Substitute2:
	if_status AI_USER, STATUS1_POISON | STATUS1_BURN | STATUS1_PARALYSIS | STATUS1_TOXIC_POISON, AI_CV_Substitute_ScoreMinus2
	if_user_faster AI_CV_Substitute_UserFaster
	if_hp_more_than AI_USER, 70, AI_CV_Substitute_SlowHighHP
	goto AI_CV_Substitute_ScoreMinus1

AI_CV_Substitute_UserFaster:
	if_has_move_with_effect AI_USER, EFFECT_FLAIL | EFFECT_ENDEAVOR, AI_CV_Substitute_ScorePlus10
	if_holds_item AI_USER, ITEM_APICOT_BERRY | ITEM_GANLON_BERRY | ITEM_LIECHI_BERRY | ITEM_PETAYA_BERRY | ITEM_SALAC_BERRY | ITEM_STARF_BERRY, AI_CV_Substitute_ScorePlus1
	if_hp_more_than AI_USER, 33, AI_CV_Substitute_AbilityCheck
	goto AI_CV_Substitute_MoveCheck

AI_CV_Substitute_AbilityCheck:
	if_ability AI_USER, ABILITY_BLAZE, AI_CV_Substitute_Blaze
	if_ability AI_USER, ABILITY_OVERGROW, AI_CV_Substitute_Overgrow
	if_ability AI_USER, ABILITY_SWARM, AI_CV_Substitute_Swarm
	if_ability AI_USER, ABILITY_TORRENT, AI_CV_Substitute_Torrent
	goto AI_CV_Substitute_MoveCheck

AI_CV_Substitute_Blaze:
	if_has_move AI_USER, MOVE_BLAST_BURN | MOVE_BLAZE_KICK | MOVE_FIRE_BLAST | MOVE_FIRE_PUNCH | MOVE_FLAME_WHEEL | MOVE_FLAMETHROWER | MOVE_HEAT_WAVE | MOVE_OVERHEAT | MOVE_SACRED_FIRE, AI_CV_Substitute_ScorePlus1
	goto AI_CV_Substitute_MoveCheck

AI_CV_Substitute_Overgrow:
	if_has_move AI_USER, MOVE_FRENZY_PLANT | MOVE_GIGA_DRAIN | MOVE_LEAF_BLADE | MOVE_MAGICAL_LEAF | MOVE_MEGA_DRAIN | MOVE_NEEDLE_ARM | MOVE_PETAL_DANCE | MOVE_RAZOR_LEAF, AI_CV_Substitute_ScorePlus1
	goto AI_CV_Substitute_MoveCheck

AI_CV_Substitute_Swarm:
	if_has_move AI_USER, MOVE_MEGAHORN | MOVE_PIN_MISSILE | MOVE_SIGNAL_BEAM | MOVE_SILVER_WIND | MOVE_TWINEEDLE, AI_CV_Substitute_ScorePlus1
	goto AI_CV_Substitute_MoveCheck

AI_CV_Substitute_Torrent:
	if_has_move AI_USER, MOVE_BUBBLE_BEAM | MOVE_CRABHAMMER | MOVE_DIVE | MOVE_HYDRO_CANNON | MOVE_HYDRO_PUMP | MOVE_MUDDY_WATER | MOVE_OCTAZOOKA | MOVE_SURF | MOVE_WATER_PULSE | MOVE_WATERFALL, AI_CV_Substitute_ScorePlus1
	goto AI_CV_Substitute_MoveCheck

AI_CV_Substitute_MoveCheck:
	get_last_used_bank_move AI_TARGET
	get_move_effect_from_result
	if_equal EFFECT_ROAR, AI_CV_Substitute_TargetRoared
	if_has_move_with_effect AI_TARGET, EFFECT_LEECH_SEED | EFFECT_PARALYZE | EFFECT_SLEEP | EFFECT_TOXIC | EFFECT_WILL_O_WISP | EFFECT_YAWN, AI_CV_Substitute_ScoreRandomPlus2
	goto AI_CV_Substitute_ScorePlus1

AI_CV_Substitute_SlowHighHP:
	if_random_less_than 128, AI_End
	score -1
	end

AI_CV_Substitute_TargetRoared:
	if_random_less_than 224, AI_End
	score -1
	end

AI_CV_Substitute_TargetAttacked:
	if_random_less_than 77, AI_End
	score +1
	end

AI_CV_Substitute_ScoreMinus2:
	score -2
	end

AI_CV_Substitute_ScoreMinus1:
	score -1
	end

AI_CV_Substitute_ScorePlus1:
	score +1
	end

AI_CV_Substitute_ScoreRandomPlus2:
	if_random_less_than 64, AI_End
	score +2
	end

AI_CV_Substitute_ScorePlus10:
	score +10
	end

AI_CV_Disable:
	if_random_less_than 160, AI_End
	score -1
	end

AI_CV_Encore:
	if_target_faster AI_CV_Encore_Minus2
	is_first_turn_for AI_TARGET
	if_equal TRUE, AI_CV_Encore_Minus30
	get_last_used_bank_move AI_TARGET
	if_type_effectiveness_from_result AI_EFFECTIVENESS_x0, AI_CV_Encore_Plus3
	if_type_effectiveness_from_result AI_EFFECTIVENESS_x0_25, AI_CV_Encore_Plus3
	if_status2 AI_USER, STATUS2_SUBSTITUTE, AI_CV_Encore_BehindSub
	get_last_used_bank_move AI_TARGET
	get_move_effect_from_result
	if_not_in_bytes AI_CV_Encore_EncouragedMovesToEncore, AI_CV_Encore_Minus2
	goto AI_CV_Encore_Plus3

AI_CV_Encore_BehindSub:
	get_last_used_bank_move AI_TARGET
	get_move_effect_from_result
	if_not_in_bytes AI_CV_Encore_EncouragedMovesToEncore_WhileBehindSub, AI_CV_Encore_Minus2
	goto AI_CV_Encore_Plus3

AI_CV_Encore_Minus30:
	score -30
	end

AI_CV_Encore_Minus2:
	score -2
	end

AI_CV_Encore_Plus3:
	score +3
	end

AI_CV_LockOn:
	if_random_less_than 128, AI_CV_LockOn_End
	score -1
AI_CV_LockOn_End:
	end

AI_CV_Foresight:
	get_target_type1
	if_equal TYPE_GHOST, AI_CV_Foresight2
	get_target_type2
	if_equal TYPE_GHOST, AI_CV_Foresight2
	if_stat_level_more_than AI_TARGET, STAT_EVASION, 7, AI_CV_Foresight2
	score -10
	end

AI_CV_Foresight2:
	if_random_less_than 80, AI_End
	score +1
	end

AI_CV_AlwaysHit:
	if_stat_level_more_than AI_TARGET, STAT_EVASION, 8, AI_CV_AlwaysHit_Plus1
	if_stat_level_less_than AI_USER, STAT_ACC, 4, AI_CV_AlwaysHit_Plus1
	if_stat_level_more_than AI_TARGET, STAT_EVASION, 7, AI_CV_AlwaysHitRandom
	if_stat_level_less_than AI_USER, STAT_ACC, 5, AI_CV_AlwaysHitRandom
	end

AI_CV_AlwaysHit_Plus1:
	score +1
AI_CV_AlwaysHitRandom:
	if_random_less_than 100, AI_End
	score +1
	end

AI_CV_SelfKO:
	score -1
	if_stat_level_more_than AI_TARGET, STAT_EVASION, 6, AI_CV_SelfKO_HighRisk
	goto AI_CV_SuicideCheck

AI_CV_SelfKO_HighRisk:
	if_random_less_than 192, AI_CV_SuicideCheck
	score -2
	goto AI_CV_SuicideCheck

AI_CV_Grudge:
	count_usable_party_mons AI_USER
	if_equal 0, AI_CV_Grudge_DontUse
AI_CV_DestinyBond:
	if_target_faster, AI_CV_DestinyBond_Minus1
	if_hp_less_than AI_USER, 10, AI_CV_DestinyBond_Plus1
	if_hp_less_than AI_USER, 33, AI_CV_DestinyBond_Plus1_HighOdds
	if_hp_less_than AI_USER, 50, AI_CV_DestinyBond_Plus1_MediumOdds
	if_hp_less_than AI_USER, 70, AI_CV_DestinyBond_Plus1_LowOdds
AI_CV_DestinyBond_Minus1:
	score -1
	goto AI_CV_SuicideCheck

AI_CV_Grudge_DontUse:
	score -30
	end

AI_CV_DestinyBond_Plus1_HighOdds:
	if_random_less_than 160, AI_CV_SuicideCheck
AI_CV_DestinyBond_Plus1_MediumOdds:
	if_random_less_than 64, AI_CV_SuicideCheck
AI_CV_DestinyBond_Plus1_HighOdds:
	if_random_less_than 32, AI_CV_SuicideCheck
AI_CV_DestinyBond_Plus1:
	score +1
	goto AI_CV_SuicideCheck

AI_CV_Taunt:
	if_target_faster AI_CV_Taunt_Discourage
	if_status AI_TARGET, STATUS1_SLEEP, AI_CV_Taunt_Sleep
	AI_CV_Taunt_LookForElectricMove_PreCheck

AI_CV_Taunt_Sleep:
	if_has_move AI_TARGET, MOVE_SLEEP_TALK, AI_CV_Taunt_SleepTalk
	goto AI_CV_Taunt_Discourage

AI_CV_Taunt_SleepTalk:
	get_user_type1
	if_equal TYPE_GHOST, AI_CV_Taunt_Encourage
	get_user_type2
	if_equal TYPE_GHOST, AI_CV_Taunt_Encourage
	if_has_move AI_TARGET, MOVE_SNORE, AI_CV_Taunt_Discourage
	goto AI_CV_Taunt_Encourage

AI_CV_Taunt_LookForElectricMove_PreCheck:
	get_ability AI_USER
	if_equal ABILITY_VOLT_ABSORB, AI_CV_Taunt_LookForFightingMove_PreCheck
	get_user_type1
	if_equal TYPE_GROUND, AI_CV_Taunt_LookForFightingMove_PreCheck
	get_user_type2
	if_equal TYPE_GROUND, AI_CV_Taunt_LookForFightingMove_PreCheck
AI_CV_Taunt_LookForElectricMove:
	if_in_bytes AI_CV_ElectricAttacks, AI_CV_Taunt_PreventHealing_PreCheck
AI_CV_Taunt_LookForFightingMove_PreCheck:
	get_user_type1
	if_equal TYPE_GHOST, AI_CV_Taunt_LookForFireMove_PreCheck
	get_user_type2
	if_equal TYPE_GHOST, AI_CV_Taunt_LookForFireMove_PreCheck
AI_CV_Taunt_LookForFightingMove:
	if_in_bytes AI_CV_FightingAttacks, AI_CV_Taunt_PreventHealing_PreCheck
AI_CV_Taunt_LookForFireMove_PreCheck:
	get_ability AI_USER
	if_equal ABILITY_FLASH_FIRE, AI_CV_Taunt_LookForGhostMove_PreCheck
AI_CV_Taunt_LookForFireMove:
	if_in_bytes AI_CV_FireAttacks, AI_CV_Taunt_PreventHealing_PreCheck
	get_weather
	if_not_equal AI_WEATHER_SUN, AI_CV_Taunt_LookForGhostMove_PreCheck
	if_has_move AI_TARGET, MOVE_WEATHER_BALL, AI_CV_Taunt_PreventHealing_PreCheck
AI_CV_Taunt_LookForGhostMove_PreCheck:
	get_user_type1
	if_equal TYPE_NORMAL, AI_CV_Taunt_LookForGoundMove_PreCheck
	get_user_type2
	if_equal TYPE_NORMAL, AI_CV_Taunt_LookForGroundMove_PreCheck
AI_CV_Taunt_LookForGhostMove:
	if_in_bytes AI_CV_GhostAttacks, AI_CV_Taunt_PreventHealing_PreCheck
AI_CV_Taunt_LookForGroundMove_PreCheck:
	get_ability AI_USER
	if_equal ABILITY_LEVITATE, AI_CV_Taunt_LookForNormalMove_PreCheck
	get_user_type1
	if_equal TYPE_FLYING, AI_CV_Taunt_LookForNormalMove_PreCheck
	get_user_type2
	if_equal TYPE_FLYING, AI_CV_Taunt_LookForNormalMove_PreCheck
AI_CV_Taunt_LookForGroundMove:
	if_in_bytes AI_CV_GroundAttacks, AI_CV_Taunt_PreventHealing_PreCheck
	if_has_move AI_TARGET, MOVE_FISSURE, AI_CV_Taunt_PreventHealing_PreCheck
AI_CV_Taunt_LookForNormalMove_PreCheck:
	get_user_type1
	if_equal TYPE_GHOST, AI_CV_Taunt_LookForPoisonMove_PreCheck
	get_user_type2
	if_equal TYPE_GHOST, AI_CV_Taunt_LookForPoisonMove_PreCheck
AI_CV_Taunt_LookForNormalMove:
	if_in_bytes AI_CV_NormalAttacks, AI_CV_Taunt_PreventHealing_PreCheck
	if_has_move AI_TARGET, MOVE_GUILLOTINE | MOVE_HORN_DRILL, AI_CV_Taunt_PreventHealing_PreCheck
AI_CV_Taunt_LookForPoisonMove_PreCheck:
	get_user_type1
	if_equal TYPE_STEEL, AI_CV_Taunt_LookForPsychicMove_PreCheck
	get_user_type2
	if_equal TYPE_STEEL, AI_CV_Taunt_LookForPsychicMove_PreCheck
AI_CV_Taunt_LookForPoisonMove:
	if_in_bytes AI_CV_PoisonAttacks, AI_CV_Taunt_PreventHealing_PreCheck
AI_CV_Taunt_LookForPsychicMove_PreCheck:
	get_user_type1
	if_equal TYPE_DARK, AI_CV_Taunt_LookForPsychicMove_PreCheck
	get_user_type2
	if_equal TYPE_DARK, AI_CV_Taunt_LookForPsychicMove_PreCheck
AI_CV_Taunt_LookForPsychicMove:
	if_in_bytes AI_CV_PsychicAttacks, AI_CV_Taunt_PreventHealing_PreCheck
AI_CV_Taunt_LookForWaterMove_PreCheck:
	get_ability AI_USER
	if_equal ABILITY_WATER_ABSORB, AI_CV_Taunt_LookForNormalMove_PreCheck
AI_CV_Taunt_LookForWaterMove:
	if_in_bytes AI_CV_WaterAttacks, AI_CV_Taunt_PreventHealing_PreCheck
	get_weather
	if_not_equal AI_WEATHER_RAIN, AI_CV_Taunt_LookForOtherAttacks
	if_has_move AI_TARGET, MOVE_WEATHER_BALL, AI_CV_Taunt_PreventHealing_PreCheck
AI_CV_Taunt_LookForOtherAttacks:
	if_in_bytes AI_CV_OtherPhysicalAttacks, AI_CV_Taunt_PreventHealing_PreCheck
	if_in_bytes AI_CV_OtherSpecialAttacks, AI_CV_Taunt_PreventHealing_PreCheck
	get_last_used_bank_move AI_TARGET
	if_equal MOVE_FURY_CUTTER | MOVE_ICE_BALL | MOVE_ROLLOUT, AI_CV_Taunt_PreventHealing_PreCheck
	if_has_move AI_TARGET, MOVE_SHEER_COLD, AI_CV_Taunt_PreventHealing_PreCheck
	goto AI_CV_Taunt_Encourage

AI_CV_Taunt_PreventHealing_PreCheck:
	if_hp_more_than AI_TARGET, 70, AI_CV_Taunt_PreventRefresh_PreCheck
	if_has_move_with_effect AI_TARGET, EFFECT_MOONLIGHT | EFFECT_MORNING_SUN | EFFECT_RESTORE_HP | EFFECT_SYNTHESIS, AI_CV_Taunt_PreventHealing
	if_has_move_with_effect AI_TARGET, EFFECT_WISH, AI_CV_Taunt_PreventHealing_Wish
	if_has_move_with_effect AI_TARGET, EFFECT_REST, AI_CV_Taunt_PreventHealing_Rest
	goto AI_CV_Taunt_PreventRefresh_PreCheck

AI_CV_Taunt_PreventHealing:
	if_hp_more_than AI_TARGET, 60, AI_CV_Taunt_PreventRefresh_PreCheck
	if_hp_more_than AI_TARGET, 33, AI_CV_Taunt_Encourage
	goto AI_CV_Taunt_PreventHealing_RandomEncourage

AI_CV_Taunt_PreventHealing_Wish:
	if_hp_more_than AI_TARGET, 72, AI_CV_Taunt_PreventRefresh_PreCheck
	if_hp_more_than AI_TARGET, 45, AI_CV_Taunt_Encourage
	goto AI_CV_Taunt_PreventHealing_RandomEncourage

AI_CV_Taunt_PreventHealing_Rest:
	if_hp_more_than AI_TARGET, 55, AI_CV_Taunt_PreventRefresh_PreCheck
	if_hp_more_than AI_TARGET, 40, AI_CV_Taunt_Encourage
AI_CV_Taunt_PreventHealing_RandomEncourage:
	if_random_less_than 160, AI_CV_Taunt_Encourage
AI_CV_Taunt_PreventRefresh_PreCheck:
	if_status AI_TARGET, STATUS1_BURN | STATUS1_PARALYSIS | STATUS1_POISON | STATUS1_TOXIC_POISON, AI_CV_Taunt_PreventRefresh_PreCheck2
	goto AI_CV_Taunt_Discourage

AI_CV_Taunt_PreventRefresh_PreCheck2:
	if_has_move_with_effect AI_TARGET, EFFECT_HEAL_BELL | EFFECT_REFRESH, AI_CV_Taunt_PreventRefresh
	goto AI_CV_Taunt_Discourage

AI_CV_Taunt_PreventRefresh:
	if_hp_more_than AI_TARGET, 70, AI_End
	if_hp_less_than AI_TARGET, 30, AI_CV_Taunt_Encourage
	if_random_less_than 128, AI_End
AI_CV_Taunt_Encourage:
	score +2
	end

AI_CV_Taunt_Discourage:
	score -2
	end

AI_CV_Flail:
	if_target_faster AI_CV_Flail_TargetFaster
	if_hp_less_than AI_USER, 5, AI_CV_Flail_Plus2
	if_hp_less_than AI_USER, 10, AI_CV_Flail_Plus1
	if_hp_less_than AI_USER, 25, AI_End
	if_hp_less_than AI_USER, 33, AI_CV_Flail_SubCheck
	goto AI_CV_Flail_Minus10

AI_CV_Flail_SubCheck:
	if_status2 AI_USER, STATUS2_SUBSTITUTE, AI_End
	if_has_move AI_USER, MOVE_SUBSTITUTE, AI_CV_Flail_Minus10
	end

AI_CV_Flail_TargetFaster:
	if_has_move AI_USER, MOVE_ENDURE, AI_CV_Flail_Endure
	goto AI_CV_Flail_TargetFaster_CheckHP

AI_CV_Flail_Endure:
	if_holds_item AI_USER, ITEM_SALAC_BERRY, AI_CV_Flail_Minus10
AI_CV_Flail_TargetFaster_CheckHP:
	if_hp_less_than AI_USER, 40, AI_CV_Flail_Minus10
	if_random_less_than 196, AI_CV_Flail_Minus10
	end

AI_CV_Flail_Plus2:
	score +2
	end

AI_CV_Flail_Plus1:
	score +1
	end

AI_CV_Flail_Minus10:
	score -10
	end

AI_CV_Endeavor:
	if_target_faster AI_CV_Endeavor_Slower
	goto AI_CV_Endeavor_CheckHP

AI_CV_Endeavor_Slower:
	if_status2 AI_USER, STATUS2_SUBSTITUTE, AI_CV_Endeavor_CheckHP
	if_hp_more_than AI_USER, 50, AI_CV_Endeavor_Minus1
	end

AI_CV_Endeavor_CheckHP:
	if_hp_more_than AI_USER, 25, AI_CV_Endeavor_Minus1
	end

AI_CV_Endeavor_Minus1:
	score -1
	end

AI_CV_FocusPunch:
	score -1
	if_status2 AI_USER, STATUS2_SUBSTITUTE, AI_CV_FocusPunch_ScorePlus2
	goto AI_CV_FocusPunch_StatusCheck

AI_CV_FocusPunch_ScorePlus2:
	score +2
AI_CV_FocusPunch_StatusCheck:
	if_status AI_TARGET, STATUS1_SLEEP | STATUS1_FREEZE, AI_CV_FocusPunch_Status_ScorePlus2
	if_status AI_TARGET, STATUS1_PARALYSIS, AI_CV_FocusPunch_Status_ScorePlus1
	if_status AI_TARGET, STATUS3_YAWN, AI_CV_FocusPunch_Status_Yawned
	goto AI_CV_FocusPunch_Infatuation

AI_CV_FocusPunch_Status_Yawned:
	if_status AI_TARGET, STATUS2_ESCAPE_PREVENTION | STATUS2_WRAPPED, AI_CV_FocusPunch_Infatuatio
	if_random_less_than 96, AI_CV_FocusPunch_Infatuation
AI_CV_FocusPunch_Status_ScorePlus1:
	score +1
	goto AI_CV_FocusPunch_Infatuation

AI_CV_FocusPunch_Status_ScorePlus2:
	score +1
	if_random_less_than 64, AI_CV_FocusPunch_Infatuation
	score +1
AI_CV_FocusPunch_Infatuation:
	if_status2 AI_TARGET, STATUS2_INFATUATION, AI_CV_FocusPunch_Infatuated_ScorePlus1
	goto AI_CV_FocusPunch_Confusion

AI_CV_FocusPunch_Infatuated_ScorePlus1:
	score +1
AI_CV_FocusPunch_Confusion:
	if_status2 AI_TARGET, STATUS2_CONFUSION, AI_CV_FocusPunch_Confused_ScorePlus1
	goto AI_CV_FocusPunch_Random

AI_CV_FocusPunch_Confused_ScorePlus1:
	score +1
AI_CV_FocusPunch_Seeded:
	if_status AI_TARGET, STATUS2_ESCAPE_PREVENTION | STATUS2_WRAPPED, AI_CV_FocusPunch_Random
	if_status AI_TARGET, STATUS3_LEECHSEED, AI_CV_FocusPunch_Status_Seeded_Plus1
	goto AI_CV_FocusPunch_Curse

AI_CV_FocusPunch_Status_Seeded_Plus1:
	if_random_less_than 160, AI_CV_FocusPunch_Curse
	score +1
AI_CV_FocusPunch_Curse:
	if_status2 AI_TARGET, STATUS2_CURSED, AI_CV_FocusPunch_Curse_Plus2

AI_CV_FocusPunch_Curse_Plus2:
	if_random_less_than 16, AI_CV_FocusPunch_PerishSong
	score +2
AI_CV_FocusPunch_PerishSong:
	if_status3 AI_TARGET, STATUS3_PERISH_SONG, AI_CV_FocusPunch_PerishSong_Plus1
	goto AI_CV_FocusPunch_Random

AI_CV_FocusPunch_PerishSong_Plus1:
	if_random_less_than 128, AI_CV_FocusPunch_Random
	score +1
AI_CV_FocusPunch_Random:
	if_random_less_than 220, AI_End
	score +1
	end

AI_CV_ClearStatus:
	if_hp_less_than AI_TARGET, 50, AI_CV_ClearStatus_Minus1
	end

AI_CV_ClearStatus_Minus1:
	score -1
	end

AI_CV_Thief:
	if_holds_item AI_USER, ITEM_NONE, AI_CV_Thief_CheckTarget
	goto AI_CV_Thief_Minus2

AI_CV_Thief_CheckTarget:
	get_hold_effect AI_TARGET
	if_not_in_bytes AI_CV_Thief_EncourageItemsToSteal, AI_CV_Thief_Minus2
	if_random_less_than 50, AI_End
	score +1
	end

AI_CV_Thief_Minus2:
	score -2
	end

AI_CV_Trick:
	get_last_used_bank_move AI_USER
	get_move_effect_from_result
	if_equal EFFECT_TRICK, AI_CV_Trick_ScoreMinus3
	get_hold_effect AI_USER
	if_in_bytes AI_CV_Trick_EffectsToEncourage, AI_CV_Trick_Encourage
	goto AI_CV_Trick_ScoreMinus3

AI_CV_Trick_Encourage:
	get_hold_effect AI_TARGET
	if_in_bytes AI_CV_Trick_EffectsToEncourage, AI_CV_Trick_ScoreMinus3
	if_random_less_than 50, AI_End
	score +2
	end

AI_CV_Trick_ScoreMinus3:
	score -3
	end

AI_CV_KnockOff:
	if_holds_item AI_TARGET, ITEM_NONE, AI_CV_KnockOff_ScoreMinus2
	if_hp_less_than AI_TARGET, 30, AI_CV_KnockOff_ScoreMinus2
	if_random_less_than 180, AI_End
	score +1
	end

AI_CV_KnockOff_ScoreMinus2:
	score -2
	end

AI_CV_Recycle:
	get_used_held_item AI_USER
	if_not_in_bytes AI_CV_Recycle_ItemsToEncourage, AI_CV_Recycle_Minus2
	if_random_less_than 50, AI_End
	score +1
	end

AI_CV_Recycle_Minus2:
	score -2
	end

AI_CV_Protect:
	is_first_turn_for AI_USER
	if_not_equal 0, AI_CV_ProtectCurse
	if_random_less_than 128, AI_CV_ProtectCurse
	score +1
AI_CV_ProtectCurse:
	if_status2 AI_USER, STATUS2_CURSED, AI_CV_Protect1
	goto AI_CV_ProtectSeed

AI_CV_Protect1:
	score -2
AI_CV_ProtectSeed:
	if_status3 AI_USER, STATUS3_LEECHSEED, AI_CV_Protect2
	goto AI_CV_ProtectPerish

AI_CV_Protect2:
	score -2
AI_CV_ProtectPerish:
	if_status3 AI_USER, STATUS3_PERISH_SONG, AI_CV_Protect3
	goto AI_CV_ProtectInfatuation

AI_CV_Protect3:
	score -2
AI_CV_ProtectInfatuation:
	if_status2 AI_USER, STATUS2_INFATUATION, AI_CV_Protect4
	goto AI_CV_ProtectStatus

AI_CV_Protect4:
	score -1
AI_CV_ProtectStatus:
	if_status AI_USER, STATUS1_PSN_ANY, AI_CV_Protect5
	if_status3 AI_USER, STATUS3_YAWN, AI_CV_Protect5
	if_status AI_USER, STATUS1_PARALYSIS, AI_CV_Protect6
	goto AI_CV_ProtectTargetStatus

AI_CV_Protect5:
	score -2
	goto AI_CV_ProtectTargetStatus

AI_CV_Protect6:
	score -1
AI_CV_ProtectTargetStatus:
	if_status3 AI_TARGET, STATUS3_YAWN, AI_CV_Protect7
	if_status AI_TARGET, STATUS1_FREEZE, AI_CV_Protect8
	if_status AI_TARGET, STATUS1_SLEEP, AI_CV_Protect8
	if_status AI_TARGET, STATUS1_PARALYSIS, AI_CV_Protect8
	goto AI_CV_ProtectTargetConf

AI_CV_Protect7:
	score +1
	goto AI_CV_ProtectTargetConf

AI_CV_Protect8:
	score -15
AI_CV_ProtectTargetConf:
	if_status2 AI_TARGET, STATUS2_CONFUSION, AI_CV_Protect9
	goto AI_CV_ProtectTargetInfat

AI_CV_Protect9:
	score -15
AI_CV_ProtectTargetInfat:
	if_status2 AI_TARGET, STATUS2_INFATUATION, AI_CV_Protect10
	goto AI_CV_ProtectDouble

AI_CV_Protect10:
	score -1
AI_CV_ProtectDouble:
	get_protect_count AI_USER
	if_less_than 1, AI_CV_ProtectWish
	if_hp_less_than AI_TARGET 13, AI_CV_ProtectVeryLowHP
	if_hp_less_than AI_TARGET 25, AI_CV_ProtectLowHP
	goto AI_CV_ProtectRecount

AI_CV_ProtectLowHP:
	if_status2 AI_TARGET, STATUS2_CURSED, AI_CV_Protect11
	if_status3 AI_TARGET, STATUS3_LEECHSEED, AI_CV_ProtectVeryLowHP
	goto AI_CV_ProtectRecount

AI_CV_ProtectVeryLowHP:
	if_status AI_TARGET, STATUS1_PSN_ANY, AI_CV_Protect11
	if_status AI_TARGET, STATUS1_BURN, AI_CV_Protect11
	if_status3 AI_TARGET, STATUS3_LEECHSEED, AI_CV_Protect11
	if_status2 AI_TARGET, STATUS2_CURSED, AI_CV_Protect11
AI_CV_ProtectRecount:
	get_protect_count AI_USER
	if_less_than 2, AI_CV_Protect12
	score -5
	goto AI_CV_ProtectLeftoversUser

AI_CV_ProtectWish:
	get_last_used_bank_move AI_USER
	if_effect EFFECT_WISH, AI_CV_Protect13
	goto AI_CV_ProtectLeftoversUser

AI_CV_Protect11:
	score +2
	goto AI_CV_ProtectLeftoversUser

AI_CV_Protect12:
	score -2
	goto AI_CV_ProtectLeftoversUser

AI_CV_Protect13:
	if_hp_more_than AI_USER, 75, AI_CV_ProtectLeftoversUser
	score +1
AI_CV_ProtectLeftoversUser:
	get_hold_effect AI_USER
	if_not_in_bytes AI_CV_Protect_Leftovers, AI_CV_ProtectLeftoversTarget
	if_random_less_than 128, AI_CV_ProtectLeftoversTarget
	score +1
AI_CV_ProtectLeftoversTarget:
	get_hold_effect AI_TARGET
	if_not_in_bytes AI_CV_Protect_Leftovers, AI_CV_ProtectEnd
	score -1
AI_CV_ProtectEnd:
	end

AI_CV_Protect_Leftovers:
	.byte HOLD_EFFECT_LEFTOVERS
	.byte -1

AI_CV_Endure:
	if_hp_less_than AI_USER, 4, AI_CV_Endure2
	if_hp_less_than AI_USER, 35, AI_CV_Endure3
AI_CV_Endure2:
	score -1
	goto AI_CV_Endure_End

AI_CV_Endure3:
	if_random_less_than 70, AI_CV_Endure_End
	score +1
AI_CV_Endure_End:
	end

AI_CV_BatonPass:
	if_stat_level_more_than AI_USER, STAT_ATK, 6, AI_CV_BatonPass_Plus1_Random
	if_stat_level_more_than AI_USER, STAT_DEF, 6, AI_CV_BatonPass_Plus1_Random
	if_stat_level_more_than AI_USER, STAT_SPATK, 6, AI_CV_BatonPass_Plus1_Random
	if_stat_level_more_than AI_USER, STAT_SPDEF, 6, AI_CV_BatonPass_Plus1_Random
	if_stat_level_more_than AI_USER, STAT_SPEED, 6, AI_CV_BatonPass_Plus1_Random
	if_stat_level_more_than AI_USER, STAT_EVASION, 6, AI_CV_BatonPass_Plus1_Random
	score -1
	end

AI_CV_BatonPass_Plus1_Random:
	if_random_less_than 96, AI_End
	score +1
	end

AI_CV_RainDance:
	if_has_move_with_effect AI_TARGET, EFFECT_THUNDER, AI_CV_RainDance_Thunder
	goto AI_CV_RainDance_CheckTargetFire

AI_CV_RainDance_Thunder:
	score +1
AI_CV_RainDance_CheckTargetFire:
	get_target_type1
	if_equal TYPE_FIRE, AI_CV_RainDance_WeakenFire
	get_target_type2
	if_equal TYPE_FIRE, AI_CV_RainDance_WeakenFire
	goto AI_CV_RainDance_CheckUserWater

AI_CV_RainDance_WeakenFire:
	score +1
AI_CV_RainDance_CheckUserWater:
	get_user_type1
	if_equal TYPE_WATER, AI_CV_RainDance_PowerUpWater
	get_user_type2
	if_equal TYPE_WATER, AI_CV_RainDance_PowerUpWater
	goto AI_CV_RainDance_CheckRainDish

AI_CV_RainDance_PowerUpWater:
	score +1
AI_CV_RainDance_CheckRainDish:
	get_ability AI_USER
	if_not_equal ABILITY_RAIN_DISH, AI_CV_RainDance_UserSwims
	score +1
	goto AI_CV_RainDance_TargetSwims

AI_CV_RainDance_UserSwims:
	get_ability AI_USER
	if_not_equal ABILITY_SWIFT_SWIM, AI_CV_RainDance_TargetSwims
	if_user_faster AI_CV_RainDance_TargetSwims
	score +1
AI_CV_RainDance_TargetSwims:
	get_ability AI_TARGET
	if_not_equal ABILITY_SWIFT_SWIM, AI_CV_RainDance_WeatherCheck
	if_target_faster AI_CV_RainDance_WeatherCheck
	score -1
	goto AI_CV_RainDance_WeatherCheck

AI_CV_RainDance_RainDishCheck:
	get_ability AI_TARGET
	if_not_equal ABILITY_RAIN_DISH, AI_CV_RainDance_WeatherCheck
	score -1
AI_CV_RainDance_WeatherCheck:
	get_weather
	if_equal AI_WEATHER_HAIL, AI_CV_ReplaceWeather
	if_equal AI_WEATHER_SUN, AI_CV_ReplaceWeather
	if_equal AI_WEATHER_SANDSTORM, AI_CV_ReplaceWeather
	goto AI_CV_Weather_LowHP_Check

AI_CV_SunnyDay:
	if_has_move_with_effect AI_USER, EFFECT_SOLAR_BEAM, AI_CV_SunnyDay_SB_Found
	goto AI_CV_SunnyDay_CheckUserFireWeak

AI_CV_SunnyDay_SB_Found:
	score +1
AI_CV_SunnyDay_CheckUserFireWeak:
	get_user_type1
	if_equal TYPE_BUG, AI_CV_SunnyDay_CheckTargetFire
	if_equal TYPE_GRASS, AI_CV_SunnyDay_CheckTargetFire
	if_equal TYPE_ICE, AI_CV_SunnyDay_CheckTargetFire
	if_equal TYPE_STEEL, AI_CV_SunnyDay_CheckTargetFire
	get_user_type2
	if_equal TYPE_BUG, AI_CV_SunnyDay_CheckTargetFire
	if_equal TYPE_GRASS, AI_CV_SunnyDay_CheckTargetFire
	if_equal TYPE_ICE, AI_CV_SunnyDay_CheckTargetFire
	if_equal TYPE_STEEL, AI_CV_SunnyDay_CheckTargetFire
	goto AI_CV_SunnyDay_CheckTargetWater

AI_CV_SunnyDay_CheckTargetFire:
	get_target_type1
	if_equal TYPE_FIRE, AI_CV_SunnyDay_CheckTargetStatus
	get_target_type2
	if_equal TYPE_FIRE, AI_CV_SunnyDay_CheckTargetStatus
	goto AI_CV_SunnyDay_CheckTargetWater

AI_CV_SunnyDay_CheckTargetStatus:
	if_status AI_TARGET, STATUS1_SLEEP, AI_CV_SunnyDay_CheckTargetWater
	if_status AI_TARGET, STATUS1_FREEZE, AI_CV_SunnyDay_CheckTargetWater
	if_status2 AI_USER, STATUS2_SUBSTITUTE, AI_CV_SunnyDay_CheckTargetWater
	score -5
AI_CV_SunnyDay_CheckTargetWater:
	get_target_type1
	if_equal TYPE_WATER, AI_CV_SunnyDay_WeakenWater
	get_target_type2
	if_equal TYPE_WATER, AI_CV_SunnyDay_WeakenWater
	goto AI_CV_SunnyDay_CheckUserFire

AI_CV_SunnyDay_WeakenWater:
	score +1
AI_CV_SunnyDay_CheckUserFire:
	get_user_type1
	if_equal TYPE_FIRE, AI_CV_SunnyDay_BoostFire
	get_user_type2
	if_equal TYPE_FIRE, AI_CV_SunnyDay_BoostFire
	goto AI_CV_SunnyDay_UserChloro

AI_CV_SunnyDay_BoostFire:
	score +1
AI_CV_SunnyDay_UserChloro:
	get_ability AI_USER
	if_not_equal ABILITY_CHLOROPHYLL, AI_CV_SunnyDay_TargetChloro
	if_user_faster AI_CV_SunnyDay_TargetChloro
	score +1
AI_CV_SunnyDay_TargetChloro:
	get_ability AI_TARGET
	if_not_equal ABILITY_CHLOROPHYLL, AI_CV_SunnyDay_WeatherCheck
	if_target_faster AI_CV_SunnyDay_WeatherCheck
	score -1
AI_CV_SunnyDay_WeatherCheck:
	get_weather
	if_equal AI_WEATHER_HAIL, AI_CV_ReplaceWeather
	if_equal AI_WEATHER_RAIN, AI_CV_ReplaceWeather
	if_equal AI_WEATHER_SANDSTORM, AI_CV_ReplaceWeather
	goto AI_CV_Weather_LowHP_Check

AI_CV_Sandstorm:
	get_ability AI_TARGET
	if_not_equal ABILITY_WONDER_GUARD, AI_CV_Sandstorm_TypeCheck
	score +1
AI_CV_Sandstorm_TypeCheck:
	get_target_type1
	if_in_bytes AI_CV_SandstormResistantTypes, AI_CV_Sand_TargetIsSandImmune
	get_target_type2
	if_in_bytes AI_CV_SandstormResistantTypes, AI_CV_Sand_TargetIsSandImmune
	goto AI_CV_Sand_WeatherCheck

AI_CV_Sand_TargetIsSandImmune:
	score -1
AI_CV_Sand_WeatherCheck:
	get_weather
	if_equal AI_WEATHER_SUN, AI_CV_ReplaceWeather
	if_equal AI_WEATHER_RAIN, AI_CV_ReplaceWeather
	if_equal AI_WEATHER_HAIL, AI_CV_ReplaceWeather
	goto AI_CV_Weather_LowHP_Check

AI_CV_Hail:
	get_ability AI_TARGET
	if_not_equal ABILITY_WONDER_GUARD, AI_CV_Hail_TypeCheck
	score +1
AI_CV_Hail_TypeCheck:
	get_target_type1
	if_equal TYPE_ICE, AI_CV_Hail_TargetIsIce
	get_target_type2
	if_equal TYPE_ICE, AI_CV_Hail_TargetIsIce
	goto AI_CV_Hail_WeatherCheck

AI_CV_Hail_TargetIsIce:
	score -1
AI_CV_Hail_WeatherCheck:
	get_weather
	if_equal AI_WEATHER_SUN, AI_CV_ReplaceWeather
	if_equal AI_WEATHER_RAIN, AI_CV_ReplaceWeather
	if_equal AI_WEATHER_SANDSTORM, AI_CV_ReplaceWeather
	goto AI_CV_Weather_LowHP_Check

AI_CV_ReplaceWeather:
	score +1
AI_CV_Weather_LowHP_Check:
	if_hp_less_than AI_USER, 25, AI_CV_Weather_LowHP
	goto AI_CV_Forecast_Check

AI_CV_Weather_LowHP:
	score -1
AI_CV_Forecast_Check:
	get_ability AI_USER
	if_equal ABILITY_FORECAST, AI_CV_Forecast_Found

AI_CV_Forecast_Found:
	score +1
AI_CV_CloudNineCheck:
	get_ability AI_TARGET
	if_equal ABILITY_AIR_LOCK, AI_CV_WeatherImmune
	if_equal ABILITY_CLOUD_NINE, AI_CV_WeatherImmune
	get_ability AI_USER
	if_equal ABILITY_AIR_LOCK, AI_CV_WeatherImmune
	if_equal ABILITY_CLOUD_NINE, AI_CV_WeatherImmune
	goto AI_CV_Weather_End

AI_CV_WeatherImmune:
	score -2
AI_CV_Weather_End:
	end

AI_CV_Counter:
	get_last_used_bank_move AI_TARGET
	get_move_power_from_result
	if_not_equal 0, AI_CV_Counter_PhysCheck
	if_target_not_taunted AI_CV_CounterCoatMinus
	get_target_type1
	if_in_bytes AI_PhysicalTypeList, AI_CV_CounterCoat_StatusCheck
	get_target_type2
	if_in_bytes AI_PhysicalTypeList, AI_CV_CounterCoat_StatusCheck
	goto AI_CV_CounterCoatMinus

AI_CV_Counter_PhysCheck:
	get_last_used_bank_move AI_TARGET
	get_move_type_from_result
	if_not_in_bytes AI_PhysicalTypeList, AI_CV_CounterCoatMinus
	goto AI_CV_Counter_Taunt

AI_CV_Counter_CheckHiddenPower:
	get_last_used_bank_move AI_TARGET
	if_not_equal MOVE_HIDDEN_POWER, AI_CV_CounterCoatMinus
AI_CV_Counter_Taunt:
	if_target_taunted AI_CV_CounterCoatPlus
	goto AI_CV_CounterCoat_StatusCheck

AI_CV_MirrorCoat:
	get_last_used_bank_move AI_TARGET
	get_move_power_from_result
	if_not_equal 0, AI_CV_MirrorCoat_SpcCheck
	if_target_not_taunted AI_CV_CounterCoatMinus
	get_target_type1
	if_in_bytes AI_SpecialTypeList, AI_CV_CounterCoat_StatusCheck
	get_target_type2
	if_in_bytes AI_SpecialTypeList, AI_CV_CounterCoat_StatusCheck
	goto AI_CV_CounterCoatMinus

AI_CV_MirrorCoat_SpcCheck:
	get_last_used_bank_move AI_TARGET
	get_move_type_from_result
	if_not_in_bytes AI_SpecialTypeList, AI_CV_CounterCoatMinus
	get_last_used_bank_move AI_TARGET
	if_equal MOVE_HIDDEN_POWER, AI_CV_CounterCoatMinus
	if_target_taunted AI_CV_CounterCoatPlus
	goto AI_CV_CounterCoat_StatusCheck

AI_CV_CounterCoatPlus:
	if_random_less_than 64, AI_CV_CounterCoat_StatusCheck
	score +1
	goto AI_CV_CounterCoat_StatusCheck

AI_CV_CounterCoatMinus:
	score -1
AI_CV_CounterCoat_StatusCheck:
	if_status AI_TARGET, STATUS1_SLEEP, AI_CV_CounterCoat1
	if_status AI_TARGET, STATUS1_FREEZE, AI_CV_CounterCoat1
	if_status AI_TARGET, STATUS1_PARALYSIS, AI_CV_CounterCoat1
	goto AI_CV_CounterCoat_Confusion

AI_CV_CounterCoat1:
	score -1
AI_CV_CounterCoat_Confusion:
	if_status2 AI_TARGET, STATUS2_CONFUSION, AI_CV_CounterCoat2
	goto AI_CV_CounterCoat_Infatuation

AI_CV_CounterCoat2:
	score -1
AI_CV_CounterCoat_Infatuation:
	if_status2 AI_TARGET, STATUS2_INFATUATION, AI_CV_CounterCoat3
	goto AI_CV_HP_Check

AI_CV_CounterCoat3:
	score -1
AI_CV_HP_Check:
	if_hp_less_than AI_USER, 40, AI_CV_CounterCoat4
	if_hp_less_than AI_USER, 70, AI_CV_CounterCoat5
	goto AI_CV_CounterCoat_RandDown

AI_CV_CounterCoat4:
	score -1
AI_CV_CounterCoat5:
	if_random_less_than 16, AI_CV_CounterCoat_RandDown
	score -1
AI_CV_CounterCoat_RandDown:
	if_random_less_than 80, AI_CV_CounterCoat_End
	score -1
AI_CV_CounterCoat_End:
	end

AI_CV_Bide:
	if_target_faster AI_CV_Bide_Discourage
	if_hp_more_than AI_USER, 90, AI_Bide_Random
AI_CV_Bide_Discourage:
	score -2
	end

AI_Bide_Random:
	if_random_less_than 128, AI_End
	score -1
	end

AI_CV_SolarBeam:
	get_weather
	if_equal AI_WEATHER_SUN, AI_End
AI_CV_ChargeUpMove:
	if_has_move_with_effect AI_TARGET, EFFECT_PROTECT, AI_CV_ChargeUpMove_Minus5
	if_status2 AI_USER, STATUS2_SUBSTITUTE, AI_End
AI_CV_ChargeUpMove_Minus5:
	score -5
	end

AI_CV_Recharge:
	if_status2 AI_USER, STATUS2_SUBSTITUTE, AI_End
	if_target_faster, AI_CV_Recharge_TargetFaster
	if_hp_less_than AI_USER, 30, AI_End
	goto AI_CV_Recharge_ScoreMinus5

AI_CV_Recharge_TargetFaster:
	if_hp_less_than AI_USER, 50, AI_End
AI_CV_Recharge_ScoreMinus5:
	score -5
	end

AI_CV_SemiInvulnerable:
	if_status2 AI_USER, STATUS2_SUBSTITUTE, AI_CV_SemiInvulnerable_Wish
	score -1
AI_CV_SemiInvulnerable_Wish:
	get_last_used_bank_move AI_USER
	get_move_effect_from_result
	if_equal EFFECT_WISH, AI_CV_SemiInvulnerable_AfterWish
	goto AI_CV_SemiInvulnerable_CheckTargetCurse

AI_CV_SemiInvulnerable_AfterWish:
	if_hp_more_than AI_USER, 80, AI_CV_SemiInvulnerable_CheckTargetCurse
	score +2
AI_CV_SemiInvulnerable_CheckTargetCurse:
	if_status2 AI_TARGET, STATUS2_CURSED, AI_CV_SemiInvulnerable_TargetCursed
	goto AI_CV_SemiInvulnerable_CheckUserCursed

AI_CV_SemiInvulnerable_TargetCursed:
	score +1
AI_CV_SemiInvulnerable_CheckUserCursed:
	if_status2 AI_USER, STATUS2_CURSED, AI_CV_SemiInvulnerable_UserCursed
	goto AI_CV_SemiInvulnerable_CheckTargetSeeded

AI_CV_SemiInvulnerable_UserCursed:
	score -2
AI_CV_SemiInvulnerable_CheckTargetSeeded:
	if_status3 AI_TARGET, STATUS3_LEECHSEED, AI_CV_SemiInvulnerable_TargetSeeded
	goto AI_CV_SemiInvulnerable_CheckUserSeeded

AI_CV_SemiInvulnerable_TargetSeeded:
	score +1
AI_CV_SemiInvulnerable_CheckUserSeeded:
	if_status3 AI_USER, STATUS3_LEECHSEED, AI_CV_SemiInvulnerable_UserSeeded
	goto AI_CV_SemiInvulnerable_CheckTargetStatused

AI_CV_SemiInvulnerable_UserSeeded:
	score -1
AI_CV_SemiInvulnerable_CheckTargetStatused:
	if_status AI_TARGET, STATUS1_BURN, AI_CV_SemiInvulnerable_TargetStatused
	if_status AI_TARGET, STATUS1_PSN_ANY, AI_CV_SemiInvulnerable_TargetStatused
	if_status3 AI_TARGET, STATUS3_YAWN, AI_CV_SemiInvulnerable_TargetStatused
	goto AI_CV_SemiInvulnerable_CheckUserStatused

AI_CV_SemiInvulnerable_TargetStatused:
	score +1
AI_CV_SemiInvulnerable_CheckUserStatused:
	if_status AI_USER, STATUS1_BURN, AI_CV_SemiInvulnerable_UserStatused
	if_status AI_USER, STATUS1_PSN_ANY, AI_CV_SemiInvulnerable_UserStatused
	if_status3 AI_USER, STATUS3_YAWN, AI_CV_SemiInvulnerable_UserStatused
	goto AI_CV_SemiInvulnerable_CheckUserConfused

AI_CV_SemiInvulnerable_UserStatused:
	score -1
AI_CV_SemiInvulnerable_CheckUserConfused:
	if_status2 AI_USER, STATUS2_CONFUSION, AI_CV_SemiInvulnerable_UserConfused
	goto AI_CV_SemiInvulnerable_CheckProtect

AI_CV_SemiInvulnerable_UserConfused:
	score -1
AI_CV_SemiInvulnerable_CheckProtect:
	if_doesnt_have_move_with_effect AI_TARGET, EFFECT_PROTECT, AI_CV_SemiInvulnerable_End
	score -1
AI_CV_SemiInvulnerable_End:
	end

AI_CV_SpitUp:
	get_stockpile_count AI_USER
	if_less_than 2, AI_CV_SpitUp_ScoreMinus2
	if_less_than 3, AI_CV_SpitUp_HPCheck
	goto AI_CV_SpitUp_ScorePlus1

AI_CV_SpitUp_HPCheck:
	if_hp_less_than AI_USER, 50, AI_CV_SpitUp_ScorePlus1
AI_CV_SpitUp_ScoreMinus2:
	score -2
	end

AI_CV_SpitUp_ScorePlus1:
	score +1
	end

AI_CV_SmellingSalt:
	if_status AI_TARGET, STATUS1_PARALYSIS, AI_CV_SmellingSalt_Plus1
	end

AI_CV_SmellingSalt_Plus1:
	score +1
	end

AI_CV_Superpower:
	if_stat_level_less_than AI_USER, STAT_ATK, DEFAULT_STAT_STAGE, AI_CV_Superpower_Minus1
	end

AI_CV_Superpower_Minus1:
	score -1
	if_stat_level_less_than AI_USER, STAT_ATK, 5, AI_CV_Superpower_Minus10
	end

AI_CV_Superpower_Minus10:
	score -10
	end

AI_CV_Revenge:
	if_target_faster AI_CV_Revenge_CheckStatus
	score -3
AI_CV_Revenge_CheckStatus:
	if_status AI_TARGET, STATUS1_SLEEP | STATUS1_FREEZE, AI_CV_Revenge_Minus2
	if_status2 AI_TARGET, STATUS2_INFATUATION | STATUS2_CONFUSION, AI_CV_Revenge_Minus2
	end

AI_CV_Revenge_Minus2:
	score -2
	end

AI_CV_Eruption:
	if_target_faster AI_CV_Eruption_TypeMatchup
	if_hp_less_than AI_USER, 70, AI_CV_Eruption_Minus1
	score +1
	end

AI_CV_Eruption_TypeMatchup:
	get_curr_move_type
	if_equal TYPE_FIRE, AI_CV_Eruption_TypeMatchup_Fire
	if_equal TYPE_WATER, AI_CV_Eruption_TypeMatchup_Water
	end

AI_CV_Eruption_TypeMatchup_Fire:
	get_target_type1
	if_equal TYPE_WATER, AI_CV_Eruption_BadMatchup
	if_equal TYPE_ROCK, AI_CV_Eruption_BadMatchup
	if_equal TYPE_GROUND, AI_CV_Eruption_BadMatchup
	get_target_type2
	if_equal TYPE_WATER, AI_CV_Eruption_BadMatchup
	if_equal TYPE_ROCK, AI_CV_Eruption_BadMatchup
	if_equal TYPE_GROUND, AI_CV_Eruption_BadMatchup
	goto AI_CV_Eruption_CheckHP

AI_CV_Eruption_TypeMatchup_Water:
	get_target_type1
	if_equal TYPE_GRASS, AI_CV_Eruption_BadMatchup
	if_equal TYPE_ELECTRIC, AI_CV_Eruption_BadMatchup
	get_target_type2
	if_equal TYPE_GRASS, AI_CV_Eruption_BadMatchup
	if_equal TYPE_ELECTRIC, AI_CV_Eruption_BadMatchup
	goto AI_CV_Eruption_CheckHP

AI_CV_Eruption_BadMatchup:
	score -1
AI_CV_Eruption_CheckHP:
	if_hp_more_than AI_USER, 90, AI_CV_Eruption_Random
	score -1
AI_CV_Eruption_Random:
	if_random_less_than 128, AI_End
AI_CV_Eruption_Minus1:
	score -1
	end

AI_CV_Overheat:
	if_holds_item AI_USER, ITEM_WHITE_HERB, AI_CV_Overheat_End
	get_curr_move_type
	if_equal TYPE_FIRE, AI_CV_CheckOverheat
	if_equal TYPE_PSYCHIC, AI_CV_CheckPsychoBoost
	goto AI_CV_Overheat_End

AI_CV_CheckOverheat:
	if_has_move AI_USER, MOVE_BLAZE_KICK | MOVE_FIRE_BLAST | MOVE_FIRE_PUNCH | MOVE_FLAMETHROWER | MOVE_HEAT_WAVE | MOVE_SACRED_FIRE, AI_CV_Overheat_Discourage
	if_hp_more_than AI_USER, 50, AI_CV_Overheat_End
	if_has_move AI_USER, MOVE_ERUPTION, AI_CV_Overheat_Discourage
	goto AI_CV_Overheat_End

AI_CV_CheckPsychoBoost:
	if_has_move AI_USER, MOVE_EXTRASENSORY | MOVE_LUSTER_PURGE | MOVE_MIST_BALL | MOVE_PSYBEAM | MOVE_PSYCHIC, AI_CV_Overheat_Discourage
	goto AI_CV_Overheat_End

AI_CV_Overheat_Discourage:
	score -2
AI_CV_Overheat_End:
	end

AI_CV_MagicCoat:
	score -1
	if_has_move_with_effect AI_TARGET, EFFECT_SPEED_DOWN | EFFECT_SPEED_DOWN_2, AI_CV_MagicCoat_SpeedLowering
	goto AI_CV_MagicCoat_StatLowering

AI_CV_MagicCoat_SpeedLowering:
	if_target_faster AI_CV_MagicCoat_StatLowering
	get_last_used_bank_move
	get_move_effect_from_result
	if_equal EFFECT_SPEED_DOWN | EFFECT_SPEED_DOWN_2, AI_CV_MagicCoat_StatLowering
	if_random_less_than 96, AI_CV_MagicCoat_StatLowering
	score +2
AI_CV_MagicCoat_StatLowering:
	if_has_move_with_effect AI_TARGET, EFFECT_ACCURACY_DOWN | EFFECT_ACCURACY_DOWN_2 | EFFECT_ATTACK_DOWN | EFFECT_ATTACK_2 | EFFECT_DEFENSE_DOWN | EFFECT_DEFENSE_DOWN_2 | EFFECT_SPECIAL_ATTACK_DOWN | EFFECT_SPECIAL_ATTACK_DOWN_2 | EFFECT_SPECIAL_DEFENSE_DOWN | EFFECT_SPECIAL_DEFENSE_DOWN_2 | EFFECT_EVASION_DOWN | EFFECT_EVASION_DOWN_2 | EFFECT_TICKLE, AI_CV_MagicCoat_StatLowering_Plus2
	goto AI_CV_MagicCoat_LeechSeed

AI_CV_MagicCoat_StatLowering_Plus2:
	if_has_move AI_TARGET, MOVE_KINESIS, AI_CV_MagicCoat_LeechSeed
	if_random_less_than 96, AI_CV_MagicCoat_LeechSeed
	score +2
AI_CV_MagicCoat_LeechSeed:
	if_status3 AI_USER, STATUS3_LEECHSEED, AI_CV_MagicCoat_Status
	if_has_move_with_effect AI_TARGET, EFFECT_LEECH_SEED, AI_CV_MagicCoat_LeechSeed_Plus2
	goto AI_CV_MagicCoat_Status

AI_CV_MagicCoat_LeechSeed_Plus2:
	if_random_less_than 64, AI_CV_MagicCoat_LeechSeed
	score +2
AI_CV_MagicCoat_Status:
	if_status AI_USER, STATUS1_ANY, AI_CV_MagicCoat_Random
	if_has_move_with_effect AI_TARGET, EFFECT_PARALYZE | EFFECT_POISON | EFFECT_SLEEP | EFFECT_TOXIC | EFFECT_WILL_O_WISP, AI_CV_MagicCoat_Status_TargetCheck
	goto AI_CV_MagicCoat_Random

AI_CV_MagicCoat_Status_TargetCheck:
	if_status AI_TARGET, STATUS1_ANY, AI_CV_MagicCoat_Status_Plus2_LowerOdds
	if_random_less_than 220, AI_End
	score +2
	goto AI_CV_MagicCoat_Random

AI_CV_MagicCoat_Status_Plus2_LowerOdds:
	if_random_less_than 128, AI_End
	score +2
AI_CV_MagicCoat_Random:
	if_hp_less_than 50, AI_CV_MagicCoat_Random_LowHP
	if_random_less_than 96, AI_CV_MagicCoat_Random_Minus2
	end

AI_CV_MagicCoat_Random_LowHP:
	if_random_less_than 220, AI_CV_MagicCoat_Random_Minus2
	end

AI_CV_MagicCoat_Random_Minus2:
	score -2
	end

AI_CV_Imprison:
	if_has_move AI_TARGET, MOVE_SHADOW_BALL, AI_CV_ImprisonWontFail
	if_has_move AI_USER, MOVE_WILL_O_WISP, AI_CV_ImprisonDusclops
	goto AI_CV_ImprisonMisdreavus

AI_CV_ImprisonDusclops:
	if_has_move AI_TARGET, MOVE_WILL_O_WISP, AI_CV_ImprisonWontFail
	if_has_move AI_TARGET, MOVE_REST, AI_CV_ImprisonWontFail
	goto AI_CV_ImprisonFails

AI_CV_ImprisonMisdreavus:
	if_has_move AI_TARGET, MOVE_DESTINY_BOND, AI_CV_ImprisonWontFail
	if_has_move AI_TARGET, MOVE_TAUNT, AI_CV_ImprisonWontFail
	goto AI_CV_ImprisonFails

AI_CV_ImprisonWontFail:
	if_random_less_than 196, AI_End
	score -1
	end

AI_CV_ImprisonFails:
	score -30
	end

AI_CV_Snatch:
	score -1
	if_status AI_TARGET, STATUS1_ANY, AI_CV_Snatch_StatusRemoval
	AI_CV_Snatch_RecoveryMoves

AI_CV_Snatch_StatusRemoval:
	if_has_move_with_effect AI_TARGET, EFFECT_HEAL_BELL | EFFECT_REFRESH, AI_CV_Snatch_StatusRemoval_Plus2
	AI_CV_Snatch_RecoveryMoves

AI_CV_Snatch_StatusRemoval_Plus2:
	if_random_less_than 128, AI_CV_Snatch_RecoveryMoves
	score +2

AI_CV_Snatch_RecoveryMoves:
	if_has_move_with_effect AI_TARGET, EFFECT_MOONLIGHT | EFFECT_MORNING_SUN | EFFECT_REST | EFFECT_RESTORE_HP | EFFECT_SYNTHESIS, AI_CV_Snatch_RecoveryMoves_HPCheck
	goto AI_CV_Snatch_BoostingMoves

AI_CV_Snatch_RecoveryMoves_HPCheck:
	if_hp_less_than AI_TARGET, 30, AI_CV_Snatch_RecoveryMoves_ScorePlus2
	if_user_faster AI_CV_Snatch_RecoveryMoves_HPCheck_TargetSlower
	if_hp_less_than AI_TARGET, 55, AI_CV_Snatch_RecoveryMoves_ScorePlus2_Random
	goto AI_CV_Snatch_BoostingMoves

AI_CV_Snatch_RecoveryMoves_HPCheck_TargetFaster:
	if_hp_less_than AI_TARGET, 75, AI_CV_Snatch_RecoveryMoves_ScorePlus2_Random
	goto AI_CV_Snatch_BoostingMoves

AI_CV_Snatch_RecoveryMoves_ScorePlus2_Random:
	if_random_less_than 128, AI_CV_Snatch_BoostingMoves
AI_CV_Snatch_RecoveryMoves_ScorePlus2:
	score +2
AI_CV_Snatch_BoostingMoves:
	if_has_move_with_effect AI_TARGET, EFFECT_ATTACK_UP | EFFECT_ATTACK_UP_2 | EFFECT_DEFENSE_UP | EFFECT_DEFENSE_UP_2 | EFFECT_DEFENSE_CURL | EFFECT_SPECIAL_ATTACK_UP | EFFECT_SPECIAL_ATTACK_UP_2 | EFFECT_SPECIAL_DEFENSE_UP | EFFECT_SPECIAL_DEFENSE_UP_2 | EFFECT_SPEED_UP | EFFECT_SPEED_UP_2 | EFFECT_EVASION_UP | EFFECT_EVASION_UP_2 | EFFECT_BULK_UP | EFFECT_CALM_MIND | EFFECT_COSMIC_POWER | EFFECT_DRAGON_DANCE | EFFECT_MINIMIZE, AI_CV_Snatch_BoostingMove_ScorePlus2_Random
	if_has_move_with_effect AI_TARGET, EFFECT_CURSE, AI_CV_Snatch_BoostingMove_CurseTypeCheck
	goto AI_CV_Snatch_UserHP

AI_CV_Snatch_BoostingMove_CurseTypeCheck:
	get_target_type1
	if_equal TYPE_GHOST, AI_CV_Snatch_OtherMoves
	get_target_type2
	if_equal TYPE_GHOST, AI_CV_Snatch_OtherMoves
	get_user_type1
	if_equal TYPE_GHOST, AI_CV_Snatch_OtherMoves
	get_user_type2
	if_equal TYPE_GHOST, AI_CV_Snatch_OtherMoves
AI_CV_Snatch_BoostingMove_ScorePlus2_Random:
	if_random_less_than 128, AI_CV_Snatch_OtherMoves
	score +2
AI_CV_Snatch_OtherMoves:
	if_has_move_with_effect AI_TARGET, EFFECT_CHARGE | EFFECT_INGRAIN | EFFECT_PSYCH_UP | EFFECT_SAFEGUARD | EFFECT_STOCKPILE | EFFECT_SWALLOW, AI_CV_Snatch_OtherMoves_RandomChance_Plus1
	goto AI_CV_Snatch_UserHP

AI_CV_Snatch_OtherMoves_RandomChance_Plus1:
	if_random_less_than 240, AI_End
	score +2
AI_CV_Snatch_UserHP:
	if_hp_less_than AI_USER, 35, AI_CV_Snatch_UserHP_ScoreMinus2_Random
	end

AI_CV_Snatch_UserHP_ScoreMinus2_Random:
	if_random_less_than 64, AI_End
	score -2
	end

AI_CV_MudSport:
	if_hp_less_than AI_USER, 50, AI_CV_Sport_Minus1
	get_target_type1
	if_equal TYPE_ELECTRIC, AI_CV_Sport_Plus1
	get_target_type2
	if_equal TYPE_ELECTRIC, AI_CV_Sport_Plus1
	goto AI_CV_Sport_Minus1

AI_CV_WaterSport:
	if_hp_less_than AI_USER, 50, AI_CV_Sport_Minus1
	get_target_type1
	if_equal TYPE_FIRE, AI_CV_Sport_Plus1
	get_target_type2
	if_equal TYPE_FIRE, AI_CV_Sport_Plus1
	goto AI_CV_Sport_Minus1

AI_CV_Sport_Plus1:
	score +1
	end

AI_CV_Sport_Minus1:
	score -1
	end

AI_CV_RapidSpin:
	score -1
	count_usable_party_mons AI_USER
	if_equal 0, Score_Minus30
	get_target_type1
	if_equal TYPE_GHOST, Score_Minus30
	get_target_type2
	if_equal TYPE_GHOST, Score_Minus30
	if_side_affecting AI_USER, SIDE_STATUS_SPIKES, AI_CV_RapidSpin2
	goto AI_CV_RapidSpin_SeededCheck

AI_CV_RapidSpin2:
	score +2
AI_CV_RapidSpin_SeededCheck:
	if_status3 AI_USER, STATUS3_LEECHSEED, AI_CV_RapidSpin3
	goto AI_CV_RapidSpinEnd

AI_CV_RapidSpin3:
	score +2
AI_CV_RapidSpinEnd:
	end

AI_CV_Rollout:
	if_stat_level_more_than AI_USER, STAT_DEF, 7, AI_CV_Rollout_Possible
	if_stat_level_more_than AI_USER, STAT_SPDEF, 7, AI_CV_Rollout_Possible
	score -3
	end

AI_CV_Rollout_Possible:
	if_stat_level_more_than AI_USER, STAT_DEF, 9, AI_CV_Rollout_Plus1
	if_stat_level_more_than AI_USER, STAT_SPDEF, 9, AI_CV_Rollout_Plus1
	if_stat_level_more_than AI_USER, STAT_DEF, 8, AI_CV_Rollout_Plus1_Random
	if_stat_level_more_than AI_USER, STAT_SPDEF, 8, AI_CV_Rollout_Plus1_Random
	get_last_used_bank_move AI_USER
	get_move_effect_from_result
	if_equal EFFECT_DEFENSE_CURL, AI_CV_Rollout_Plus1_Random
	if_random_less_than 48, AI_End
	score -1
	end

AI_CV_Rollout_Plus1_Random:
	if_random_less_than 160, AI_End
AI_CV_Rollout_Plus1:
	score +1
	end

AI_CV_SuicideCheck:
	count_usable_party_mons AI_USER
	if_more_than 0, AI_CV_SuicideCheckEnd
	count_usable_party_mons AI_TARGET
	if_equal 0, AI_CV_SuicideCheckEnd
	score -40
AI_CV_SuicideCheckEnd:
	end

AI_CV_ElectricAttacks:
	.byte MOVE_SHOCK_WAVE
	.byte MOVE_SPARK
	.byte MOVE_THUNDER
	.byte MOVE_THUNDERBOLT
	.byte MOVE_THUNDER_PUNCH
	.byte MOVE_THUNDER_SHOCK
	.byte MOVE_VOLT_TACKLE
	.byte MOVE_ZAP_CANNON
	.byte -1

AI_CV_FireAttacks:
	.byte MOVE_BLAST_BURN
	.byte MOVE_BLAZE_KICK
	.byte MOVE_EMBER
	.byte MOVE_ERUPTION
	.byte MOVE_FIRE_BLAST
	.byte MOVE_FIRE_PUNCH
	.byte MOVE_FIRE_SPIN
	.byte MOVE_FLAME_WHEEL
	.byte MOVE_FLAMETHROWER
	.byte MOVE_HEAT_WAVE
	.byte MOVE_OVERHEAT
	.byte MOVE_SACRED_FIRE
	.byte -1

AI_CV_FightingAttacks:
	.byte MOVE_ARM_THRUST
	.byte MOVE_BRICK_BREAK
	.byte MOVE_CROSS_CHOP
	.byte MOVE_DOUBLE_KICK
	.byte MOVE_DYNAMIC_PUNCH
	.byte MOVE_FOCUS_PUNCH
	.byte MOVE_HIGH_JUMP_KICK
	.byte MOVE_JUMP_KICK
	.byte MOVE_KARATE_CHOP
	.byte MOVE_LOW_KICK
	.byte MOVE_MACH_PUNCH
	.byte MOVE_REVENGE
	.byte MOVE_REVERSAL
	.byte MOVE_ROCK_SMASH
	.byte MOVE_ROLLING_KICK
	.byte MOVE_SEISMIC_TOSS
	.byte MOVE_SKY_UPPERCUT
	.byte MOVE_SUBMISSION
	.byte MOVE_SUPERPOWER
	.byte MOVE_TRIPLE_KICK
	.byte MOVE_VITAL_THROW
	.byte -1

AI_CV_GhostAttacks:
	.byte MOVE_ASTONISH
	.byte MOVE_LICK
	.byte MOVE_NIGHT_SHADE
	.byte MOVE_SHADOW_BALL
	.byte MOVE_SHADOW_PUNCH
	.byte -1

AI_CV_GroundAttacks:
	.byte MOVE_BONE_CLUB
	.byte MOVE_BONE_RUSH
	.byte MOVE_BONEMERANG
	.byte MOVE_DIG
	.byte MOVE_EARTHQUAKE
	.byte MOVE_MAGNITUDE
	.byte MOVE_MUD_SHOT
	.byte MOVE_MUD_SLAP
	.byte MOVE_SAND_TOMB
	.byte -1

AI_CV_NormalAttacks:
	.byte MOVE_BARRAGE
	.byte MOVE_BIDE
	.byte MOVE_BIND
	.byte MOVE_BODY_SLAM
	.byte MOVE_COMET_PUNCH
	.byte MOVE_COVET
	.byte MOVE_CRUSH_CLAW
	.byte MOVE_CUT
	.byte MOVE_DIZZY_PUNCH
	.byte MOVE_DOUBLE_EDGE
	.byte MOVE_DOUBLE_SLAP
	.byte MOVE_EGG_BOMB
	.byte MOVE_ENDEAVOR
	.byte MOVE_EXPLOSION
	.byte MOVE_EXTREME_SPEED
	.byte MOVE_FACADE
	.byte MOVE_FAKE_OUT
	.byte MOVE_FALSE_SWIPE
	.byte MOVE_FLAIL
	.byte MOVE_FRUSTRATION
	.byte MOVE_FURY_ATTACK
	.byte MOVE_FURY_SWIPES
	.byte MOVE_HEADBUTT
	.byte MOVE_HORN_ATTACK
	.byte MOVE_HYPER_BEAM
	.byte MOVE_HYPER_FANG
	.byte MOVE_HYPER_VOICE
	.byte MOVE_MEGA_KICK
	.byte MOVE_MEGA_PUNCH
	.byte MOVE_PAY_DAY
	.byte MOVE_POUND
	.byte MOVE_PRESENT
	.byte MOVE_QUICK_ATTACK
	.byte MOVE_RAGE
	.byte MOVE_RAZOR_WIND
	.byte MOVE_RETURN
	.byte MOVE_SCRATCH
	.byte MOVE_SECRET_POWER
	.byte MOVE_SELF_DESTRUCT
	.byte MOVE_SKULL_BASH
	.byte MOVE_SLAM
	.byte MOVE_SLASH
	.byte MOVE_SMELLING_SALTS
	.byte MOVE_SNORE
	.byte MOVE_SPIKE_CANNON
	.byte MOVE_SPIT_UP
	.byte MOVE_STOMP
	.byte MOVE_STRENGTH
	.byte MOVE_SUPER_FANG
	.byte MOVE_SWIFT
	.byte MOVE_TACKLE
	.byte MOVE_TAKE_DOWN
	.byte MOVE_THRASH
	.byte MOVE_TRI_ATTACK
	.byte MOVE_UPROAR
	.byte MOVE_VICE_GRIP
	.byte MOVE_WRAP
	.byte -1

AI_CV_PoisonAttacks:
	.byte MOVE_ACID
	.byte MOVE_POISON_FANG
	.byte MOVE_POISON_STING
	.byte MOVE_POISON_TAIL
	.byte MOVE_SLUDGE
	.byte MOVE_SLUDGE_BOMB
	.byte MOVE_SMOG
	.byte -1

AI_CV_PsychicAttacks:
	.byte MOVE_CONFUSION
	.byte MOVE_EXTRASENSORY
	.byte MOVE_LUSTER_PURGE
	.byte MOVE_MIST_BALL
	.byte MOVE_PSYBEAM
	.byte MOVE_PSYCHIC
	.byte MOVE_PSYCHO_BOOST
	.byte MOVE_PSYWAVE
	.byte -1

AI_CV_WaterAttacks:
	.byte MOVE_BUBBLE
	.byte MOVE_BUBBLE_BEAM
	.byte MOVE_CLAMP
	.byte MOVE_CRABHAMMER
	.byte MOVE_DIVE
	.byte MOVE_HYDRO_CANNON
	.byte MOVE_HYDRO_PUMP
	.byte MOVE_MUDDY_WATER
	.byte MOVE_OCTAZOOKA
	.byte MOVE_SURF
	.byte MOVE_WATER_GUN
	.byte MOVE_WATER_PULSE
	.byte MOVE_WATER_SPOUT
	.byte MOVE_WATERFALL
	.byte MOVE_WHIRLPOOL
	.byte -1

AI_CV_OtherPhysicalAttacks:
	.byte MOVE_LEECH_LIFE
	.byte MOVE_MEGAHORN
	.byte MOVE_PIN_MISSILE
	.byte MOVE_SIGNAL_BEAM
	.byte MOVE_SILVER_WIND
	.byte MOVE_TWINEEDLE
	.byte MOVE_AERIAL_ACE
	.byte MOVE_AEROBLAST
	.byte MOVE_AIR_CUTTER
	.byte MOVE_BOUNCE
	.byte MOVE_DRILL_PECK
	.byte MOVE_FLY
	.byte MOVE_GUST
	.byte MOVE_PECK
	.byte MOVE_SKY_ATTACK
	.byte MOVE_WING_ATTACK
	.byte MOVE_ANCIENT_POWER
	.byte MOVE_ROCK_BLAST
	.byte MOVE_ROCK_SLIDE
	.byte MOVE_ROCK_THROW
	.byte MOVE_ROCK_TOMB
	.byte MOVE_IRON_TAIL
	.byte MOVE_METAL_CLAW
	.byte MOVE_METEOR_MASH
	.byte MOVE_STEEL_WING
	.byte -1

AI_CV_OtherSpecialAttacks:
	.byte MOVE_BITE
	.byte MOVE_CRUNCH
	.byte MOVE_FEINT_ATTACK
	.byte MOVE_HIDDEN_POWER
	.byte MOVE_KNOCK_OFF
	.byte MOVE_PURSUIT
	.byte MOVE_THIEF
	.byte MOVE_DRAGON_BREATH
	.byte MOVE_DRAGON_CLAW
	.byte MOVE_DRAGON_RAGE
	.byte MOVE_OUTRAGE
	.byte MOVE_TWISTER
	.byte MOVE_ABSORB
	.byte MOVE_BULLET_SEED
	.byte MOVE_FRENZY_PLANT
	.byte MOVE_GIGA_DRAIN
	.byte MOVE_LEAF_BLADE
	.byte MOVE_MAGICAL_LEAF
	.byte MOVE_MEGA_DRAIN
	.byte MOVE_NEEDLE_ARM
	.byte MOVE_PETAL_DANCE
	.byte MOVE_RAZOR_LEAF
	.byte MOVE_SOLAR_BEAM
	.byte MOVE_VINE_WHIP
	.byte MOVE_AURORA_BEAM
	.byte MOVE_BLIZZARD
	.byte MOVE_ICE_BEAM
	.byte MOVE_ICE_PUNCH
	.byte MOVE_ICICLE_SPEAR
	.byte MOVE_ICY_WIND
	.byte MOVE_POWDER_SNOW
	.byte -1

AI_CV_SandstormResistantTypes:
	.byte TYPE_GROUND
	.byte TYPE_ROCK
	.byte TYPE_STEEL
	.byte -1

AI_CV_Encore_EncouragedMovesToEncore_WhileBehindSub:
	.byte EFFECT_DREAM_EATER
	.byte EFFECT_ATTACK_UP
	.byte EFFECT_DEFENSE_UP
	.byte EFFECT_SPEED_UP
	.byte EFFECT_SPECIAL_ATTACK_UP
	.byte EFFECT_HAZE
	.byte EFFECT_CONVERSION
	.byte EFFECT_TOXIC
	.byte EFFECT_LIGHT_SCREEN
	.byte EFFECT_REST
	.byte EFFECT_SUPER_FANG
	.byte EFFECT_SPECIAL_DEFENSE_UP_2
	.byte EFFECT_CONFUSE
	.byte EFFECT_POISON
	.byte EFFECT_PARALYZE
	.byte EFFECT_LEECH_SEED
	.byte EFFECT_SPLASH
	.byte EFFECT_ATTACK_UP_2
	.byte EFFECT_ENCORE
	.byte EFFECT_CONVERSION_2
	.byte EFFECT_LOCK_ON
	.byte EFFECT_HEAL_BELL
	.byte EFFECT_MEAN_LOOK
	.byte EFFECT_NIGHTMARE
	.byte EFFECT_PROTECT
	.byte EFFECT_SKILL_SWAP
	.byte EFFECT_FORESIGHT
	.byte EFFECT_PERISH_SONG
	.byte EFFECT_SANDSTORM
	.byte EFFECT_ENDURE
	.byte EFFECT_SWAGGER
	.byte EFFECT_ATTRACT
	.byte EFFECT_SAFEGUARD
	.byte EFFECT_RAIN_DANCE
	.byte EFFECT_SUNNY_DAY
	.byte EFFECT_BELLY_DRUM
	.byte EFFECT_PSYCH_UP
	.byte EFFECT_FUTURE_SIGHT
	.byte EFFECT_FAKE_OUT
	.byte EFFECT_STOCKPILE
	.byte EFFECT_SPIT_UP
	.byte EFFECT_SWALLOW
	.byte EFFECT_HAIL
	.byte EFFECT_TORMENT
	.byte EFFECT_WILL_O_WISP
	.byte EFFECT_FOLLOW_ME
	.byte EFFECT_CHARGE
	.byte EFFECT_TRICK
	.byte EFFECT_ROLE_PLAY
	.byte EFFECT_INGRAIN
	.byte EFFECT_RECYCLE
	.byte EFFECT_KNOCK_OFF
	.byte EFFECT_SKILL_SWAP
	.byte EFFECT_IMPRISON
	.byte EFFECT_REFRESH
	.byte EFFECT_GRUDGE
	.byte EFFECT_TEETER_DANCE
	.byte EFFECT_MUD_SPORT
	.byte EFFECT_WATER_SPORT
	.byte EFFECT_DRAGON_DANCE
	.byte EFFECT_CAMOUFLAGE
	.byte -1

AI_CV_Encore_EncouragedMovesToEncore:
	.byte EFFECT_DREAM_EATER
	.byte EFFECT_ATTACK_UP
	.byte EFFECT_DEFENSE_UP
	.byte EFFECT_SPEED_UP
	.byte EFFECT_SPECIAL_ATTACK_UP
	.byte EFFECT_HAZE
	.byte EFFECT_ROAR
	.byte EFFECT_CONVERSION
	.byte EFFECT_LIGHT_SCREEN
	.byte EFFECT_REST
	.byte EFFECT_SPECIAL_DEFENSE_UP_2
	.byte EFFECT_SPLASH
	.byte EFFECT_ATTACK_UP_2
	.byte EFFECT_ENCORE
	.byte EFFECT_CONVERSION_2
	.byte EFFECT_LOCK_ON
	.byte EFFECT_HEAL_BELL
	.byte EFFECT_MEAN_LOOK
	.byte EFFECT_NIGHTMARE
	.byte EFFECT_PROTECT
	.byte EFFECT_SKILL_SWAP
	.byte EFFECT_FORESIGHT
	.byte EFFECT_PERISH_SONG
	.byte EFFECT_SANDSTORM
	.byte EFFECT_ENDURE
	.byte EFFECT_ATTRACT
	.byte EFFECT_SAFEGUARD
	.byte EFFECT_RAIN_DANCE
	.byte EFFECT_SUNNY_DAY
	.byte EFFECT_BELLY_DRUM
	.byte EFFECT_PSYCH_UP
	.byte EFFECT_FUTURE_SIGHT
	.byte EFFECT_FAKE_OUT
	.byte EFFECT_STOCKPILE
	.byte EFFECT_SPIT_UP
	.byte EFFECT_SWALLOW
	.byte EFFECT_HAIL
	.byte EFFECT_TORMENT
	.byte EFFECT_FOLLOW_ME
	.byte EFFECT_CHARGE
	.byte EFFECT_TRICK
	.byte EFFECT_ROLE_PLAY
	.byte EFFECT_INGRAIN
	.byte EFFECT_RECYCLE
	.byte EFFECT_KNOCK_OFF
	.byte EFFECT_SKILL_SWAP
	.byte EFFECT_IMPRISON
	.byte EFFECT_REFRESH
	.byte EFFECT_GRUDGE
	.byte EFFECT_TEETER_DANCE
	.byte EFFECT_MUD_SPORT
	.byte EFFECT_WATER_SPORT
	.byte EFFECT_CAMOUFLAGE
	.byte -1

AI_CV_Trick_EffectsToEncourage:
	.byte HOLD_EFFECT_MACHO_BRACE
	.byte HOLD_EFFECT_CHOICE_BAND
	.byte -1

AI_CV_Thief_EncourageItemsToSteal:
	.byte HOLD_EFFECT_CURE_SLP
	.byte HOLD_EFFECT_CURE_STATUS
	.byte HOLD_EFFECT_RESTORE_HP
	.byte HOLD_EFFECT_LEFTOVERS
	.byte HOLD_EFFECT_EVASION_UP
	.byte HOLD_EFFECT_ATTACK_UP
	.byte HOLD_EFFECT_DEFENSE_UP
	.byte HOLD_EFFECT_SP_ATTACK_UP
	.byte HOLD_EFFECT_SP_DEFENSE_UP
	.byte HOLD_EFFECT_SPEED_UP
	.byte HOLD_EFFECT_RANDOM_STAT_UP
	.byte HOLD_EFFECT_LIGHT_BALL
	.byte HOLD_EFFECT_THICK_CLUB
	.byte HOLD_EFFECT_DEEP_SEA_TOOTH
	.byte HOLD_EFFECT_DEEP_SEA_SCALE
	.byte HOLD_EFFECT_CONFUSE_SPICY
	.byte HOLD_EFFECT_CONFUSE_DRY
	.byte HOLD_EFFECT_CONFUSE_SWEET
	.byte HOLD_EFFECT_CONFUSE_BITTER
	.byte HOLD_EFFECT_CONFUSE_SOUR
	.byte -1

AI_CV_ChangeSelfAbility_AbilitiesToEncourage:
	.byte ABILITY_SPEED_BOOST
	.byte ABILITY_FLASH_FIRE
	.byte ABILITY_WONDER_GUARD
	.byte ABILITY_SWIFT_SWIM
	.byte ABILITY_HUGE_POWER
	.byte ABILITY_RAIN_DISH
	.byte ABILITY_SHED_SKIN
	.byte ABILITY_MARVEL_SCALE
	.byte ABILITY_PURE_POWER
	.byte ABILITY_CHLOROPHYLL
	.byte ABILITY_LEVITATE
	.byte ABILITY_ARENA_TRAP
	.byte ABILITY_MAGNET_PULL
	.byte ABILITY_NATURAL_CURE
	.byte ABILITY_VOLT_ABSORB
	.byte ABILITY_WATER_ABSORB
	.byte ABILITY_GUTS
	.byte ABILITY_THICK_FAT
	.byte -1

AI_CV_Recycle_ItemsToEncourage:
	.byte ITEM_CHESTO_BERRY
	.byte ITEM_LUM_BERRY
	.byte ITEM_STARF_BERRY
	.byte -1

AI_PhysicalTypeList:
	.byte TYPE_NORMAL
	.byte TYPE_FIGHTING
	.byte TYPE_GROUND
	.byte TYPE_ROCK
	.byte TYPE_BUG
	.byte TYPE_STEEL
	.byte TYPE_POISON
	.byte TYPE_FLYING
	.byte TYPE_GHOST
	.byte -1

AI_SpecialTypeList:
	.byte TYPE_FIRE
	.byte TYPE_WATER
	.byte TYPE_GRASS
	.byte TYPE_ELECTRIC
	.byte TYPE_PSYCHIC
	.byte TYPE_ICE
	.byte TYPE_DRAGON
	.byte TYPE_DARK
	.byte -1

AI_TryToFaint:
	if_target_is_ally AI_End
	if_can_faint AI_TryToFaint_TryToEncouragePriority
	get_how_powerful_move_is
	if_equal MOVE_NOT_MOST_POWERFUL, Score_Minus1
	end

AI_TryToFaint_TryToEncouragePriority:
	if_effect EFFECT_FOCUS_PUNCH, AI_End
	if_effect EFFECT_FAKE_OUT | EFFECT_QUICK_ATTACK, AI_TryToFaint_Plus6
	if_effect EFFECT_REVENGE | EFFECT_VITAL_THROW, AI_TryToFaint_AccBonus_1
	if_effect EFFECT_EXPLOSION, AI_TryToFaint_AccBonus_2
	if_effect EFFECT_RAZOR_WIND | EFFECT_RECHARGE | EFFECT_SKULL_BASH | EFFECT_SKY_ATTACK, AI_TryToFaint_EvasionCheck
	if_holds_item AI_TARGET, ITEM_WHITE_HERB, AI_TryToFaint_SubstituteCheck
	if_effect EFFECT_OVERHEAT | EFFECT_SUPERPOWER, AI_TryToFaint_AccBonus_1
AI_TryToFaint_SubstituteCheck:
	if_status2 AI_USER, STATUS2_SUBSTITUTE, AI_TryToFaint_Plus4
	if_effect EFFECT_SEMI_INVULNERABLE, AI_TryToFaint_EvasionCheck
	goto AI_TryToFaint_Plus4

AI_TryToFaint_Plus6:
	score +2
AI_TryToFaint_Plus4:
	score +4
AI_TryToFaint_EvasionCheck:
	if_stat_level_less_than AI_TARGET, STAT_EVASION, -1, AI_TryToFaint_AccBonus_2
	if_stat_level_less_than AI_TARGET, STAT_EVASION, 0, AI_TryToFaint_AccBonus_CompEyesCheck
	if_ability AI_USER, ABILITY_COMPOUND_EYES, AI_TryToFaint_AccBonus_LessEvasive
	if_ability AI_USER, ABILITY_HUSTLE, AI_TryToFaint_AccBonus_Hustle
	goto AI_TryToFaint_AccBonus

AI_TryToFaint_AccBonus:
	if_effect EFFECT_ALWAYS_HIT, AI_TryToFaint_AccBonus_4
	get_considered_move_accuracy
	if_equal 100, AI_TryToFaint_AccBonus_4
	if_equal 95, AI_TryToFaint_AccBonus_3
	if_equal 90, AI_TryToFaint_AccBonus_2
	if_equal 85, AI_TryToFaint_AccBonus_2
	if_equal 80, AI_TryToFaint_AccBonus_1
	if_equal 75, AI_TryToFaint_AccBonus_1
	if_equal 70, AI_TryToFaint_AccBonus_1
	goto AI_TryToFaint_End

AI_TryToFaint_AccBonus_Hustle:
	if_effect EFFECT_ALWAYS_HIT, AI_TryToFaint_AccBonus_4
	get_considered_move_accuracy
	if_equal 100, AI_TryToFaint_AccBonus_3
	if_equal 95, AI_TryToFaint_AccBonus_3
	if_equal 90, AI_TryToFaint_AccBonus_2
	if_equal 85, AI_TryToFaint_AccBonus_2
	if_equal 80, AI_TryToFaint_AccBonus_2
	if_equal 75, AI_TryToFaint_AccBonus_1
	if_equal 70, AI_TryToFaint_AccBonus_1
	goto AI_TryToFaint_End

AI_TryToFaint_AccBonus_CompEyesCheck:
	if_ability AI_USER, ABILITY_COMPOUND_EYES, AI_TryToFaint_End
AI_TryToFaint_AccBonus_LessEvasive:
	get_considered_move_accuracy
	if_equal 70, AI_TryToFaint_AccBonus_2
	if_equal 50, AI_TryToFaint_AccBonus_1
	goto AI_TryToFaint_AccBonus_3

AI_TryToFaint_AccBonus_4:
	score +1
AI_TryToFaint_AccBonus_3:
	score +1
AI_TryToFaint_AccBonus_2:
	score +1
AI_TryToFaint_AccBonus_1:
	score +1
AI_TryToFaint_End:
	end

AI_SetupFirstTurn:
	if_target_is_ally AI_End
	get_turn_count
	if_not_equal 0, AI_SetupFirstTurn_End
	get_considered_move_effect
	if_not_in_bytes AI_SetupFirstTurn_SetupEffectsToEncourage, AI_SetupFirstTurn_End
	if_random_less_than 80, AI_SetupFirstTurn_End
	score +2
AI_SetupFirstTurn_End:
	end

AI_SetupFirstTurn_SetupEffectsToEncourage:
	.byte EFFECT_ATTACK_UP
	.byte EFFECT_DEFENSE_UP
	.byte EFFECT_SPEED_UP
	.byte EFFECT_SPECIAL_ATTACK_UP
	.byte EFFECT_SPECIAL_DEFENSE_UP
	.byte EFFECT_ACCURACY_UP
	.byte EFFECT_EVASION_UP
	.byte EFFECT_ATTACK_DOWN
	.byte EFFECT_DEFENSE_DOWN
	.byte EFFECT_SPEED_DOWN
	.byte EFFECT_SPECIAL_ATTACK_DOWN
	.byte EFFECT_SPECIAL_DEFENSE_DOWN
	.byte EFFECT_ACCURACY_DOWN
	.byte EFFECT_EVASION_DOWN
	.byte EFFECT_CONVERSION
	.byte EFFECT_LIGHT_SCREEN
	.byte EFFECT_SPECIAL_DEFENSE_UP_2
	.byte EFFECT_FOCUS_ENERGY
	.byte EFFECT_CONFUSE
	.byte EFFECT_ATTACK_UP_2
	.byte EFFECT_DEFENSE_UP_2
	.byte EFFECT_SPEED_UP_2
	.byte EFFECT_SPECIAL_ATTACK_UP_2
	.byte EFFECT_SPECIAL_DEFENSE_UP_2
	.byte EFFECT_ACCURACY_UP_2
	.byte EFFECT_EVASION_UP_2
	.byte EFFECT_ATTACK_DOWN_2
	.byte EFFECT_DEFENSE_DOWN_2
	.byte EFFECT_SPEED_DOWN_2
	.byte EFFECT_SPECIAL_ATTACK_DOWN_2
	.byte EFFECT_SPECIAL_DEFENSE_DOWN_2
	.byte EFFECT_ACCURACY_DOWN_2
	.byte EFFECT_EVASION_DOWN_2
	.byte EFFECT_REFLECT
	.byte EFFECT_POISON
	.byte EFFECT_PARALYZE
	.byte EFFECT_SUBSTITUTE
	.byte EFFECT_LEECH_SEED
	.byte EFFECT_MINIMIZE
	.byte EFFECT_CURSE
	.byte EFFECT_SWAGGER
	.byte EFFECT_CAMOUFLAGE
	.byte EFFECT_YAWN
	.byte EFFECT_DEFENSE_CURL
	.byte EFFECT_TORMENT
	.byte EFFECT_FLATTER
	.byte EFFECT_WILL_O_WISP
	.byte EFFECT_INGRAIN
	.byte EFFECT_IMPRISON
	.byte EFFECT_TEETER_DANCE
	.byte EFFECT_TICKLE
	.byte EFFECT_COSMIC_POWER
	.byte EFFECT_BULK_UP
	.byte EFFECT_CALM_MIND
	.byte EFFECT_CAMOUFLAGE
	.byte -1

@ ~60% chance to prefer moves that do 0 or 1 damage, or are in sIgnoredPowerfulMoveEffects
@ Oddly this group includes moves like Explosion and Eruption, so the AI strategy isn't very coherent
AI_PreferPowerExtremes:
	if_target_is_ally AI_End
	get_how_powerful_move_is
	if_not_equal MOVE_POWER_OTHER, AI_PreferPowerExtremes_End
	if_random_less_than 100, AI_PreferPowerExtremes_End
	score +2
AI_PreferPowerExtremes_End:
	end

AI_Risky:
	if_target_is_ally AI_End
	get_considered_move_effect
	if_not_in_bytes AI_Risky_EffectsToEncourage, AI_Risky_End
	if_random_less_than 128, AI_Risky_End
	score +2
AI_Risky_End:
	end

AI_Risky_EffectsToEncourage:
	.byte EFFECT_SLEEP
	.byte EFFECT_YAWN
	.byte EFFECT_EXPLOSION
	.byte EFFECT_MIRROR_MOVE
	.byte EFFECT_OHKO
	.byte EFFECT_HIGH_CRITICAL
	.byte EFFECT_CONFUSE
	.byte EFFECT_METRONOME
	.byte EFFECT_PSYWAVE
	.byte EFFECT_COUNTER
	.byte EFFECT_DESTINY_BOND
	.byte EFFECT_SWAGGER
	.byte EFFECT_ATTRACT
	.byte EFFECT_PRESENT
	.byte EFFECT_ALL_STATS_UP_HIT
	.byte EFFECT_BELLY_DRUM
	.byte EFFECT_MIRROR_COAT
	.byte EFFECT_FOCUS_PUNCH
	.byte EFFECT_REVENGE
	.byte EFFECT_TEETER_DANCE
	.byte -1

AI_PreferBatonPass:
	if_target_is_ally AI_End
	count_usable_party_mons AI_USER
	if_equal 0, AI_PreferBatonPassEnd
	get_how_powerful_move_is
	if_not_equal MOVE_POWER_OTHER, AI_PreferBatonPassEnd
	if_has_move_with_effect AI_USER, EFFECT_BATON_PASS, AI_PreferBatonPass_GoForBatonPass
	if_random_less_than 80, AI_Risky_End
AI_PreferBatonPass_GoForBatonPass:
	if_move MOVE_SWORDS_DANCE, AI_PreferBatonPass2
	if_move MOVE_DRAGON_DANCE, AI_PreferBatonPass2
	if_move MOVE_CALM_MIND, AI_PreferBatonPass2
	if_effect EFFECT_PROTECT, AI_PreferBatonPass_End
	if_move MOVE_BATON_PASS, AI_PreferBatonPass_EncourageIfHighStats
	if_random_less_than 20, AI_Risky_End
	score +3
AI_PreferBatonPass2:
	get_turn_count
	if_equal 0, Score_Plus5
	if_hp_less_than AI_USER, 60, Score_Minus10
	goto Score_Plus1

AI_PreferBatonPass_End:
	get_last_used_bank_move AI_USER
	if_in_hwords sMovesTable_ProtectMoves, Score_Minus2
	score +2
	end

sMovesTable_ProtectMoves:
	.2byte MOVE_PROTECT
	.2byte MOVE_DETECT
	.2byte -1

sMovesTable_SoundMoves:
	.2byte MOVE_GROWL
	.2byte MOVE_ROAR
	.2byte MOVE_SING
	.2byte MOVE_SUPERSONIC
	.2byte MOVE_SCREECH
	.2byte MOVE_SNORE
	.2byte MOVE_UPROAR
	.2byte MOVE_METAL_SOUND
	.2byte MOVE_GRASS_WHISTLE
	.2byte -1

AI_PreferBatonPass_EncourageIfHighStats:
	get_turn_count
	if_equal 0, Score_Minus2
	if_stat_level_more_than AI_USER, STAT_ATK, DEFAULT_STAT_STAGE + 2, Score_Plus3
	if_stat_level_more_than AI_USER, STAT_ATK, DEFAULT_STAT_STAGE + 1, Score_Plus2
	if_stat_level_more_than AI_USER, STAT_ATK, DEFAULT_STAT_STAGE, Score_Plus1
	if_stat_level_more_than AI_USER, STAT_SPATK, DEFAULT_STAT_STAGE + 2, Score_Plus3
	if_stat_level_more_than AI_USER, STAT_SPATK, DEFAULT_STAT_STAGE + 1, Score_Plus2
	if_stat_level_more_than AI_USER, STAT_SPATK, DEFAULT_STAT_STAGE, Score_Plus1
	end

AI_PreferBatonPassEnd:
	end

AI_DoubleBattle:
	if_target_is_ally AI_TryOnAlly
	if_move MOVE_SKILL_SWAP, AI_DoubleBattleSkillSwap
	if_move MOVE_EARTHQUAKE, AI_DoubleBattleAllHittingGroundMove
	if_move MOVE_MAGNITUDE, AI_DoubleBattleAllHittingGroundMove
	get_curr_move_type
	if_equal TYPE_ELECTRIC, AI_DoubleBattleElectricMove
	if_equal TYPE_FIRE, AI_DoubleBattleFireMove
	get_ability AI_USER
	if_not_equal ABILITY_GUTS, AI_DoubleBattleCheckUserStatus
	if_has_move AI_USER_PARTNER, MOVE_HELPING_HAND, AI_DoubleBattlePartnerHasHelpingHand
	end

AI_DoubleBattlePartnerHasHelpingHand:
	get_how_powerful_move_is
	if_not_equal MOVE_POWER_OTHER, Score_Plus1
	end

AI_DoubleBattleCheckUserStatus:
	if_status AI_USER, STATUS1_ANY, AI_DoubleBattleCheckUserStatus2
	end

AI_DoubleBattleCheckUserStatus2:
	get_how_powerful_move_is
	if_equal MOVE_POWER_OTHER, Score_Minus5
	score +1
	if_equal MOVE_MOST_POWERFUL, Score_Plus2
	end

AI_DoubleBattleAllHittingGroundMove:
	if_ability AI_USER_PARTNER, ABILITY_LEVITATE, Score_Plus2
	if_type AI_USER_PARTNER, TYPE_FLYING, Score_Plus2
	if_type AI_USER_PARTNER, TYPE_FIRE, Score_Minus10
	if_type AI_USER_PARTNER, TYPE_ELECTRIC, Score_Minus10
	if_type AI_USER_PARTNER, TYPE_POISON, Score_Minus10
	if_type AI_USER_PARTNER, TYPE_ROCK, Score_Minus10
	goto Score_Minus3

AI_DoubleBattleSkillSwap:
	get_ability AI_USER
	if_equal ABILITY_TRUANT, Score_Plus5
	get_ability AI_TARGET
	if_equal ABILITY_SHADOW_TAG, Score_Plus2
	if_equal ABILITY_PURE_POWER, Score_Plus2
	end

AI_DoubleBattleElectricMove:
	if_no_ability AI_TARGET_PARTNER, ABILITY_LIGHTNING_ROD, AI_DoubleBattleElectricMoveEnd
	score -2
	if_no_type AI_TARGET_PARTNER, TYPE_GROUND, AI_DoubleBattleElectricMoveEnd
	score -8
AI_DoubleBattleElectricMoveEnd:
	end

AI_DoubleBattleFireMove:
	if_flash_fired AI_USER, AI_DoubleBattleFireMove2
	end

AI_DoubleBattleFireMove2:
	goto Score_Plus1

AI_TryOnAlly:
	get_how_powerful_move_is
	if_equal MOVE_POWER_OTHER, AI_TryStatusMoveOnAlly
	get_curr_move_type
	if_equal TYPE_FIRE, AI_TryFireMoveOnAlly
AI_DiscourageOnAlly:
	goto Score_Minus30

AI_TryFireMoveOnAlly:
	if_ability AI_USER_PARTNER, ABILITY_FLASH_FIRE, AI_TryFireMoveOnAlly_FlashFire
	goto AI_DiscourageOnAlly

AI_TryFireMoveOnAlly_FlashFire:
	if_flash_fired AI_USER_PARTNER, AI_DiscourageOnAlly
	goto Score_Plus3

AI_TryStatusMoveOnAlly:
	if_move MOVE_SKILL_SWAP, AI_TrySkillSwapOnAlly
	if_move MOVE_WILL_O_WISP, AI_TryStatusOnAlly
	if_move MOVE_TOXIC, AI_TryStatusOnAlly
	if_move MOVE_HELPING_HAND, AI_TryHelpingHandOnAlly
	if_move MOVE_SWAGGER, AI_TrySwaggerOnAlly
	goto Score_Minus30_

AI_TrySkillSwapOnAlly:
	get_ability AI_TARGET
	if_equal ABILITY_TRUANT, Score_Plus10
	get_ability AI_USER
	if_not_equal ABILITY_LEVITATE, AI_TrySkillSwapOnAlly2
	get_ability AI_TARGET
	if_equal ABILITY_LEVITATE, Score_Minus30_
	get_target_type1
	if_not_equal TYPE_ELECTRIC, AI_TrySkillSwapOnAlly2
	score +1
	get_target_type2
	if_not_equal TYPE_ELECTRIC, AI_TrySkillSwapOnAlly2
	score +1
	end

AI_TrySkillSwapOnAlly2:
	if_not_equal ABILITY_COMPOUND_EYES, Score_Minus30_
	if_has_move AI_USER_PARTNER, MOVE_FIRE_BLAST, AI_TrySkillSwapOnAllyPlus3
	if_has_move AI_USER_PARTNER, MOVE_THUNDER, AI_TrySkillSwapOnAllyPlus3
	if_has_move AI_USER_PARTNER, MOVE_CROSS_CHOP, AI_TrySkillSwapOnAllyPlus3
	if_has_move AI_USER_PARTNER, MOVE_HYDRO_PUMP, AI_TrySkillSwapOnAllyPlus3
	if_has_move AI_USER_PARTNER, MOVE_DYNAMIC_PUNCH, AI_TrySkillSwapOnAllyPlus3
	if_has_move AI_USER_PARTNER, MOVE_BLIZZARD, AI_TrySkillSwapOnAllyPlus3
	if_has_move AI_USER_PARTNER, MOVE_MEGAHORN, AI_TrySkillSwapOnAllyPlus3
	goto Score_Minus30_

AI_TrySkillSwapOnAllyPlus3:
	goto Score_Plus3

AI_TryStatusOnAlly:
	get_ability AI_TARGET
	if_not_equal ABILITY_GUTS, Score_Minus30_
	if_status AI_TARGET, STATUS1_ANY, Score_Minus30_
	if_hp_less_than AI_USER, 91, Score_Minus30_
	goto Score_Plus5

AI_TryHelpingHandOnAlly:
	if_random_less_than 64, Score_Minus1
	goto Score_Plus2

AI_TrySwaggerOnAlly:
	if_holds_item AI_TARGET, ITEM_PERSIM_BERRY, AI_TrySwaggerOnAlly2
	goto Score_Minus30_

AI_TrySwaggerOnAlly2:
	if_stat_level_more_than AI_TARGET, STAT_ATK, 7, AI_TrySwaggerOnAlly_End
	score +3
AI_TrySwaggerOnAlly_End:
	end

Score_Minus30_:
	score -30
	end

AI_HPAware:
	if_target_is_ally AI_TryOnAlly
	if_hp_more_than AI_USER, 70, AI_HPAware_UserHasHighHP
	if_hp_more_than AI_USER, 30, AI_HPAware_UserHasMediumHP
	get_considered_move_effect
	if_in_bytes AI_HPAware_DiscouragedEffectsWhenLowHP, AI_HPAware_TryToDiscourage
	goto AI_HPAware_ConsiderTarget

AI_HPAware_UserHasHighHP:
	get_considered_move_effect
	if_in_bytes AI_HPAware_DiscouragedEffectsWhenHighHP, AI_HPAware_TryToDiscourage
	goto AI_HPAware_ConsiderTarget

AI_HPAware_UserHasMediumHP:
	get_considered_move_effect
	if_in_bytes AI_HPAware_DiscouragedEffectsWhenMediumHP, AI_HPAware_TryToDiscourage
	goto AI_HPAware_ConsiderTarget

AI_HPAware_TryToDiscourage:
	if_random_less_than 50, AI_HPAware_ConsiderTarget
	score -2
AI_HPAware_ConsiderTarget:
	if_hp_more_than AI_TARGET, 70, AI_HPAware_TargetHasHighHP
	if_hp_more_than AI_TARGET, 30, AI_HPAware_TargetHasMediumHP
	get_considered_move_effect
	if_in_bytes AI_HPAware_DiscouragedEffectsWhenTargetLowHP, AI_HPAware_TargetTryToDiscourage
	goto AI_HPAware_End

AI_HPAware_TargetHasHighHP:
	get_considered_move_effect
	if_in_bytes AI_HPAware_DiscouragedEffectsWhenTargetHighHP, AI_HPAware_TargetTryToDiscourage
	goto AI_HPAware_End

AI_HPAware_TargetHasMediumHP:
	get_considered_move_effect
	if_in_bytes AI_HPAware_DiscouragedEffectsWhenTargetMediumHP, AI_HPAware_TargetTryToDiscourage
	goto AI_HPAware_End

AI_HPAware_TargetTryToDiscourage:
	if_random_less_than 50, AI_HPAware_End
	score -2
AI_HPAware_End:
	end

AI_HPAware_DiscouragedEffectsWhenHighHP:
	.byte EFFECT_EXPLOSION
	.byte EFFECT_RESTORE_HP
	.byte EFFECT_REST
	.byte EFFECT_DESTINY_BOND
	.byte EFFECT_FLAIL
	.byte EFFECT_ENDURE
	.byte EFFECT_MORNING_SUN
	.byte EFFECT_SYNTHESIS
	.byte EFFECT_MOONLIGHT
	.byte EFFECT_SOFTBOILED
	.byte EFFECT_MEMENTO
	.byte EFFECT_GRUDGE
	.byte EFFECT_OVERHEAT
	.byte -1

AI_HPAware_DiscouragedEffectsWhenMediumHP:
	.byte EFFECT_EXPLOSION
	.byte EFFECT_ATTACK_UP
	.byte EFFECT_DEFENSE_UP
	.byte EFFECT_SPEED_UP
	.byte EFFECT_SPECIAL_ATTACK_UP
	.byte EFFECT_SPECIAL_DEFENSE_UP
	.byte EFFECT_ACCURACY_UP
	.byte EFFECT_EVASION_UP
	.byte EFFECT_ATTACK_DOWN
	.byte EFFECT_DEFENSE_DOWN
	.byte EFFECT_SPEED_DOWN
	.byte EFFECT_SPECIAL_ATTACK_DOWN
	.byte EFFECT_SPECIAL_DEFENSE_DOWN
	.byte EFFECT_ACCURACY_DOWN
	.byte EFFECT_EVASION_DOWN
	.byte EFFECT_BIDE
	.byte EFFECT_CONVERSION
	.byte EFFECT_LIGHT_SCREEN
	.byte EFFECT_MIST
	.byte EFFECT_FOCUS_ENERGY
	.byte EFFECT_ATTACK_UP_2
	.byte EFFECT_DEFENSE_UP_2
	.byte EFFECT_SPEED_UP_2
	.byte EFFECT_SPECIAL_ATTACK_UP_2
	.byte EFFECT_SPECIAL_DEFENSE_UP_2
	.byte EFFECT_ACCURACY_UP_2
	.byte EFFECT_EVASION_UP_2
	.byte EFFECT_ATTACK_DOWN_2
	.byte EFFECT_DEFENSE_DOWN_2
	.byte EFFECT_SPEED_DOWN_2
	.byte EFFECT_SPECIAL_ATTACK_DOWN_2
	.byte EFFECT_SPECIAL_DEFENSE_DOWN_2
	.byte EFFECT_ACCURACY_DOWN_2
	.byte EFFECT_EVASION_DOWN_2
	.byte EFFECT_CONVERSION_2
	.byte EFFECT_SAFEGUARD
	.byte EFFECT_BELLY_DRUM
	.byte EFFECT_TICKLE
	.byte EFFECT_DRAGON_DANCE
	.byte -1

AI_HPAware_DiscouragedEffectsWhenLowHP:
	.byte EFFECT_ATTACK_UP
	.byte EFFECT_DEFENSE_UP
	.byte EFFECT_SPEED_UP
	.byte EFFECT_SPECIAL_ATTACK_UP
	.byte EFFECT_SPECIAL_DEFENSE_UP
	.byte EFFECT_ACCURACY_UP
	.byte EFFECT_EVASION_UP
	.byte EFFECT_ATTACK_DOWN
	.byte EFFECT_DEFENSE_DOWN
	.byte EFFECT_SPEED_DOWN
	.byte EFFECT_SPECIAL_ATTACK_DOWN
	.byte EFFECT_SPECIAL_DEFENSE_DOWN
	.byte EFFECT_ACCURACY_DOWN
	.byte EFFECT_EVASION_DOWN
	.byte EFFECT_BIDE
	.byte EFFECT_CONVERSION
	.byte EFFECT_LIGHT_SCREEN
	.byte EFFECT_MIST
	.byte EFFECT_FOCUS_ENERGY
	.byte EFFECT_ATTACK_UP_2
	.byte EFFECT_DEFENSE_UP_2
	.byte EFFECT_SPEED_UP_2
	.byte EFFECT_SPECIAL_ATTACK_UP_2
	.byte EFFECT_SPECIAL_DEFENSE_UP_2
	.byte EFFECT_ACCURACY_UP_2
	.byte EFFECT_EVASION_UP_2
	.byte EFFECT_ATTACK_DOWN_2
	.byte EFFECT_DEFENSE_DOWN_2
	.byte EFFECT_SPEED_DOWN_2
	.byte EFFECT_SPECIAL_ATTACK_DOWN_2
	.byte EFFECT_SPECIAL_DEFENSE_DOWN_2
	.byte EFFECT_ACCURACY_DOWN_2
	.byte EFFECT_EVASION_DOWN_2
	.byte EFFECT_RAGE
	.byte EFFECT_CONVERSION_2
	.byte EFFECT_LOCK_ON
	.byte EFFECT_SAFEGUARD
	.byte EFFECT_BELLY_DRUM
	.byte EFFECT_PSYCH_UP
	.byte EFFECT_MIRROR_COAT
	.byte EFFECT_SOLAR_BEAM
	.byte EFFECT_ERUPTION
	.byte EFFECT_TICKLE
	.byte EFFECT_COSMIC_POWER
	.byte EFFECT_BULK_UP
	.byte EFFECT_CALM_MIND
	.byte EFFECT_DRAGON_DANCE
	.byte -1

AI_HPAware_DiscouragedEffectsWhenTargetHighHP:
	.byte -1

AI_HPAware_DiscouragedEffectsWhenTargetMediumHP:
	.byte EFFECT_ATTACK_UP
	.byte EFFECT_DEFENSE_UP
	.byte EFFECT_SPEED_UP
	.byte EFFECT_SPECIAL_ATTACK_UP
	.byte EFFECT_SPECIAL_DEFENSE_UP
	.byte EFFECT_ACCURACY_UP
	.byte EFFECT_EVASION_UP
	.byte EFFECT_ATTACK_DOWN
	.byte EFFECT_DEFENSE_DOWN
	.byte EFFECT_SPEED_DOWN
	.byte EFFECT_SPECIAL_ATTACK_DOWN
	.byte EFFECT_SPECIAL_DEFENSE_DOWN
	.byte EFFECT_ACCURACY_DOWN
	.byte EFFECT_EVASION_DOWN
	.byte EFFECT_MIST
	.byte EFFECT_FOCUS_ENERGY
	.byte EFFECT_ATTACK_UP_2
	.byte EFFECT_DEFENSE_UP_2
	.byte EFFECT_SPEED_UP_2
	.byte EFFECT_SPECIAL_ATTACK_UP_2
	.byte EFFECT_SPECIAL_DEFENSE_UP_2
	.byte EFFECT_ACCURACY_UP_2
	.byte EFFECT_EVASION_UP_2
	.byte EFFECT_ATTACK_DOWN_2
	.byte EFFECT_DEFENSE_DOWN_2
	.byte EFFECT_SPEED_DOWN_2
	.byte EFFECT_SPECIAL_ATTACK_DOWN_2
	.byte EFFECT_SPECIAL_DEFENSE_DOWN_2
	.byte EFFECT_ACCURACY_DOWN_2
	.byte EFFECT_EVASION_DOWN_2
	.byte EFFECT_POISON
	.byte EFFECT_PAIN_SPLIT
	.byte EFFECT_PERISH_SONG
	.byte EFFECT_SAFEGUARD
	.byte EFFECT_TICKLE
	.byte EFFECT_COSMIC_POWER
	.byte EFFECT_BULK_UP
	.byte EFFECT_CALM_MIND
	.byte EFFECT_DRAGON_DANCE
	.byte -1

AI_HPAware_DiscouragedEffectsWhenTargetLowHP:
	.byte EFFECT_SLEEP
	.byte EFFECT_YAWN
	.byte EFFECT_EXPLOSION
	.byte EFFECT_ATTACK_UP
	.byte EFFECT_DEFENSE_UP
	.byte EFFECT_SPEED_UP
	.byte EFFECT_SPECIAL_ATTACK_UP
	.byte EFFECT_SPECIAL_DEFENSE_UP
	.byte EFFECT_ACCURACY_UP
	.byte EFFECT_EVASION_UP
	.byte EFFECT_ATTACK_DOWN
	.byte EFFECT_DEFENSE_DOWN
	.byte EFFECT_SPEED_DOWN
	.byte EFFECT_SPECIAL_ATTACK_DOWN
	.byte EFFECT_SPECIAL_DEFENSE_DOWN
	.byte EFFECT_ACCURACY_DOWN
	.byte EFFECT_EVASION_DOWN
	.byte EFFECT_BIDE
	.byte EFFECT_CONVERSION
	.byte EFFECT_TOXIC
	.byte EFFECT_LIGHT_SCREEN
	.byte EFFECT_OHKO
	.byte EFFECT_RAZOR_WIND
	.byte EFFECT_SUPER_FANG
	.byte EFFECT_MIST
	.byte EFFECT_FOCUS_ENERGY
	.byte EFFECT_CONFUSE
	.byte EFFECT_ATTACK_UP_2
	.byte EFFECT_DEFENSE_UP_2
	.byte EFFECT_SPEED_UP_2
	.byte EFFECT_SPECIAL_ATTACK_UP_2
	.byte EFFECT_SPECIAL_DEFENSE_UP_2
	.byte EFFECT_ACCURACY_UP_2
	.byte EFFECT_EVASION_UP_2
	.byte EFFECT_ATTACK_DOWN_2
	.byte EFFECT_DEFENSE_DOWN_2
	.byte EFFECT_SPEED_DOWN_2
	.byte EFFECT_SPECIAL_ATTACK_DOWN_2
	.byte EFFECT_SPECIAL_DEFENSE_DOWN_2
	.byte EFFECT_ACCURACY_DOWN_2
	.byte EFFECT_EVASION_DOWN_2
	.byte EFFECT_POISON
	.byte EFFECT_PARALYZE
	.byte EFFECT_PAIN_SPLIT
	.byte EFFECT_CONVERSION_2
	.byte EFFECT_LOCK_ON
	.byte EFFECT_SPITE
	.byte EFFECT_PERISH_SONG
	.byte EFFECT_SWAGGER
	.byte EFFECT_FURY_CUTTER
	.byte EFFECT_ATTRACT
	.byte EFFECT_SAFEGUARD
	.byte EFFECT_PSYCH_UP
	.byte EFFECT_MIRROR_COAT
	.byte EFFECT_WILL_O_WISP
	.byte EFFECT_TICKLE
	.byte EFFECT_COSMIC_POWER
	.byte EFFECT_BULK_UP
	.byte EFFECT_CALM_MIND
	.byte EFFECT_DRAGON_DANCE
	.byte -1

@ Given the AI_TryOnAlly at the beginning it's possible that this was the start of a more
@ comprehensive double battle AI script
AI_TrySunnyDayStart:
	if_target_is_ally AI_TryOnAlly
	if_not_effect EFFECT_SUNNY_DAY, AI_TrySunnyDayStart_End
#ifndef BUGFIX  @ funcResult has not been set in this script yet, below call is nonsense
	if_equal FALSE, AI_TrySunnyDayStart_End
#endif
	is_first_turn_for AI_USER
	if_equal FALSE, AI_TrySunnyDayStart_End
	score +5
AI_TrySunnyDayStart_End:
	end

AI_Roaming:
	if_status2 AI_USER, STATUS2_WRAPPED, AI_Roaming_End
	if_status2 AI_USER, STATUS2_ESCAPE_PREVENTION, AI_Roaming_End
	get_ability AI_TARGET
	if_equal ABILITY_SHADOW_TAG, AI_Roaming_End
	get_ability AI_USER
	if_equal ABILITY_LEVITATE, AI_Roaming_Flee
	get_ability AI_TARGET
	if_equal ABILITY_ARENA_TRAP, AI_Roaming_End
AI_Roaming_Flee:
	flee

AI_Roaming_End:
	end

AI_Safari:
	if_random_safari_flee AI_Safari_Flee
	watch

AI_Safari_Flee:
	flee

AI_FirstBattle:
	if_hp_equal AI_TARGET, 20, AI_FirstBattle_Flee
	if_hp_less_than AI_TARGET, 20, AI_FirstBattle_Flee
	end

AI_FirstBattle_Flee:
	flee

AI_End:
	end
