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
	.4byte AI_DoubleBattle          @ AI_SCRIPT_DOUBLE_BATTLE
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
	if_effect EFFECT_MIMIC, AI_CBM_Mimic
	if_effect EFFECT_MIRROR_MOVE, AI_CBM_MirrorMove
	goto AI_CBM_VS_Substitute_PreCheck

AI_CBM_Mimic:
	get_last_used_bank_move AI_TARGET
	if_in_bytes AI_CantMimic_EffList, Score_Minus10
	if_status2 AI_TARGET, STATUS2_SUBSTITUTE, Score_Minus10
	if_status3 AI_TARGET, STATUS3_SEMI_INVULNERABLE, Score_Minus10
	goto AI_CBM_Imitate

AI_CBM_MirrorMove:
	get_last_used_bank_move AI_TARGET
	if_in_bytes AI_DontMirror_EffList, Score_Minus10
	get_move_target_from_result
	if_not_equal MOVE_TARGET_SELECTED | MOVE_TARGET_BOTH | MOVE_TARGET_FOES_AND_ALLY, Score_Minus10
AI_CBM_Imitate:
	if_target_faster Score_Minus10
	is_first_turn_for AI_USER
	if_equal TRUE, Score_Minus10
	consider_imitated_move
AI_CBM_VS_Substitute_PreCheck:
	if_has_move_with_effect AI_TARGET, EFFECT_SUBSTITUTE, AI_CBM_VS_Substitute
	goto AI_CBM_CheckImmunities_PreCheck

AI_CBM_VS_Substitute:
	get_considered_move_power
	if_equal 0, AI_CBM_VS_Substitute_CheckTarget
	if_effect EFFECT_CURSE, AI_CBM_VS_Substitute_CurseTypeCheck
	get_considered_move_effect
	if_in_bytes AI_CBM_SubstituteBlocks_EffList, AI_CBM_SubstituteBlocks_SpeedCheck
	goto AI_CBM_CheckImmunities

AI_CBM_VS_Substitute_CurseTypeCheck:
	get_user_type1
	if_equal TYPE_GHOST, AI_CBM_SubstituteBlocks_SpeedCheck
	get_user_type2
	if_equal TYPE_GHOST, AI_CBM_SubstituteBlocks_SpeedCheck
	goto AI_CBM_CheckEffect

AI_CBM_VS_Substitute_CheckTarget:
	if_target MOVE_TARGET_SELECTED, AI_CBM_VS_Substitute_CheckEffect
	goto AI_CBM_CheckSoundproof

AI_CBM_VS_Substitute_CheckEffect:
	if_effect EFFECT_ROAR, AI_CBM_CheckSoundproof
	get_considered_move_effect
	if_in_bytes AI_CBM_IgnoresSubstitute_EffList, AI_CBM_CheckEffect
AI_CBM_SubstituteBlocks_SpeedCheck:
	if_status2 AI_TARGET, STATUS2_SUBSTITUTE, AI_CBM_SubstituteBlocks
	if_user_faster AI_CBM_CheckImmunities_PreCheck
	if_random_less_than 10, AI_CBM_CheckImmunities_PreCheck
AI_CBM_SubstituteBlocks:
	score -10
AI_CBM_CheckImmunities_PreCheck:
	get_considered_move_power
	if_equal 0, AI_CBM_CheckSoundproof
AI_CBM_CheckImmunities:
	if_type_effectiveness_with_modifiers AI_EFFECTIVENESS_x0, Score_Minus30
AI_CBM_TestWhetherToTypeMatchup:
	if_effect EFFECT_SPEED_DOWN_HIT, AI_CBM_TestWhetherToTypeMatchup_Speed
	get_considered_move_effect
	if_in_bytes AI_CBM_IgnoreTypeMatchup, AI_CBM_CheckSoundproof
	if_in_bytes AI_CBM_StatusSecondary, AI_CBM_TestWhetherToTypeMatchup_Status
	if_in_bytes AI_CBM_ItemRemovalAttacks_EffList, AI_CBM_TestWhetherToTypeMatchup_ItemCheck
	if_move MOVE_SACRED_FIRE, AI_CBM_TestWhetherToTypeMatchup_Status
	count_usable_party_mons AI_USER
	if_equal 0, AI_CBM_TypeMatchup_Modifiers_CheckWonderGuard
	count_usable_party_mons AI_TARGET
	if_equal 0, AI_CBM_TypeMatchup_Modifiers_CheckWonderGuard
	if_holds_item AI_USER, ITEM_CHOICE_BAND, AI_CBM_TestWhetherToTypeMatchup_ChoiceBandRNG
	goto AI_CBM_TypeMatchup_Modifiers_CheckWonderGuard

AI_CBM_TestWhetherToTypeMatchup_ChoiceBandRNG:
	if_random_less_than 234, AI_CBM_TypeMatchup_Modifiers_CheckWonderGuard
	score +10
	goto AI_CBM_CheckSoundproof

AI_CBM_TestWhetherToTypeMatchup_Status:
	if_status AI_TARGET, STATUS1_ANY, AI_CBM_TypeMatchup_Modifiers_CheckWonderGuard
	get_considered_move_second_eff_chance
	if_less_than 15, AI_CBM_TypeMatchup_Modifiers_CheckWonderGuard
	get_ability AI_TARGET
	if_equal ABILITY_SERENE_GRACE, AI_CBM_CheckSoundproof
	get_considered_move_second_eff_chance
	if_less_than 25, AI_CBM_TypeMatchup_Modifiers_CheckWonderGuard
	goto AI_CBM_CheckSoundproof

AI_CBM_TestWhetherToTypeMatchup_ItemCheck:
	get_ability AI_TARGET
	if_equal ABILITY_STICKY_HOLD, AI_CBM_TypeMatchup_Modifiers_CheckWonderGuard
	get_hold_effect AI_TARGET
	if_not_in_bytes AI_Thief_EncourageItemsToSteal, AI_CBM_TypeMatchup_Modifiers_CheckWonderGuard
	goto AI_CBM_CheckSoundproof

AI_CBM_TestWhetherToTypeMatchup_Speed:
	get_ability AI_TARGET
	if_in_bytes AI_CBM_CantLowerSpeed, AI_CBM_TypeMatchup_Modifiers_CheckWonderGuard
	if_side_affecting AI_TARGET, SIDE_STATUS_MIST, AI_CBM_TypeMatchup_Modifiers_CheckWonderGuard
	if_target_faster AI_CBM_CheckSoundproof
AI_CBM_TypeMatchup_Modifiers_CheckWonderGuard:
	if_effect EFFECT_FUTURE_SIGHT, AI_CBM_TypeMatchup_Modifiers_CheckPartySize
	get_ability AI_TARGET
	if_equal ABILITY_WONDER_GUARD, AI_CBM_TypeMatchup_Modifiers_WonderGuard
	goto AI_CBM_TypeMatchup_Modifiers_CheckPartySize

AI_CBM_TypeMatchup_Modifiers_WonderGuard:
	if_type_effectiveness AI_EFFECTIVENESS_x0_25, Score_Minus30
	if_type_effectiveness AI_EFFECTIVENESS_x0_5, Score_Minus30
	if_type_effectiveness AI_EFFECTIVENESS_x1, Score_Minus30
	goto AI_CBM_TypeMatchup_WeaknessesPreCheck

AI_CBM_TypeMatchup_Modifiers_CheckPartySize:
	count_usable_party_mons AI_USER
	if_equal 0, AI_CBM_TypeMatchup_Modifiers_LastMon
AI_CBM_TypeMatchup_Modifiers:
	if_type_effectiveness_with_modifiers AI_EFFECTIVENESS_x0_25, AI_CBM_TypeMatchup_Modifiers_CheckUnmodifiedQuarterDmg
	if_type_effectiveness_with_modifiers AI_EFFECTIVENESS_x0_5, AI_CBM_TypeMatchup_Modifiers_CheckUnmodifiedHalfDmg
	goto AI_CBM_TypeMatchup_WeaknessesPreCheck

AI_CBM_TypeMatchup_Modifiers_CheckUnmodifiedQuarterDmg:
	if_type_effectiveness AI_EFFECTIVENESS_x0_25, Score_Minus30
AI_CBM_TypeMatchup_Modifiers_CheckUnmodifiedHalfDmg:
	if_type_effectiveness AI_EFFECTIVENESS_x0_5, Score_Minus7
	goto Score_Minus1

AI_CBM_TypeMatchup_Modifiers_LastMon:
	if_type_effectiveness_with_modifiers AI_EFFECTIVENESS_x0_25, Score_Minus3
	if_type_effectiveness_with_modifiers AI_EFFECTIVENESS_x0_5, Score_Minus1
AI_CBM_TypeMatchup_WeaknessesPreCheck:
	if_status2 AI_USER, STATUS2_SUBSTITUTE, AI_CBM_TypeMatchup_Weaknesses
	get_highest_type_effectiveness_from_target
	if_equal AI_EFFECTIVENESS_x0, AI_CBM_TypeMatchup_Weaknesses
	if_any_move_encored AI_TARGET, AI_CBM_TypeMatchup_WeaknessesPreCheck_Locked
	is_first_turn_for AI_TARGET
	if_equal TRUE, AI_CBM_TypeMatchup_WeaknessesPreCheck_DiscouragedAttacks
	if_holds_item AI_TARGET, ITEM_CHOICE_BAND, AI_CBM_TypeMatchup_WeaknessesPreCheck_Locked
	goto AI_CBM_TypeMatchup_WeaknessesPreCheck_DiscouragedAttacks

AI_CBM_TypeMatchup_WeaknessesPreCheck_Locked:
	get_last_used_bank_move AI_TARGET
	get_move_power_from_result
	if_equal 0, AI_CBM_TypeMatchup_Weaknesses
	get_last_used_bank_move AI_TARGET
	get_type_effectiveness_from_result
	if_equal AI_EFFECTIVENESS_x0, AI_CBM_TypeMatchup_Weaknesses
	if_effect EFFECT_FOCUS_PUNCH, AI_CBM_STAB
	if_equal AI_EFFECTIVENESS_x0_25, AI_CBM_TypeMatchup_Weaknesses
AI_CBM_TypeMatchup_WeaknessesPreCheck_DiscouragedAttacks:
	get_considered_move_effect
	if_in_bytes AI_CBM_DontEncourageAttacks, AI_CBM_STAB
	get_weather
	if_equal AI_WEATHER_SUN, AI_CBM_TypeMatchup_Weaknesses
	if_effect EFFECT_SOLAR_BEAM, AI_CBM_STAB
AI_CBM_TypeMatchup_Weaknesses:
	if_type_effectiveness_with_modifiers AI_EFFECTIVENESS_x2, AI_CBM_TypeMatchup_Plus1
	if_type_effectiveness_with_modifiers AI_EFFECTIVENESS_x4, AI_CBM_TypeMatchup_Plus2
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

AI_CBM_TypeMatchup_Minus7:
	score -7
	goto AI_CBM_STAB

AI_CBM_TypeMatchup_Minus30:
	score -30
AI_CBM_STAB:
	check_curr_move_has_stab
	if_equal TRUE, AI_CBM_CheckSoundproof
	get_considered_move_effect
	if_equal EFFECT_EXPLOSION, AI_CBM_CheckSoundproof
	if_equal EFFECT_FOCUS_PUNCH, AI_CBM_CheckSoundproof
	score -1
AI_CBM_CheckSoundproof:
	get_ability AI_TARGET
	if_equal ABILITY_SOUNDPROOF, AI_CBM_CheckIfSound
	goto AI_CBM_IfStatLowering

AI_CBM_CheckIfSound:
	if_move MOVE_GRASS_WHISTLE, AI_CBM_CheckIfSound_Minus10
	if_move MOVE_GROWL, AI_CBM_CheckIfSound_Minus10
	if_move MOVE_METAL_SOUND, AI_CBM_CheckIfSound_Minus10
	if_move MOVE_ROAR, AI_CBM_CheckIfSound_Minus10
	if_move MOVE_SCREECH, AI_CBM_CheckIfSound_Minus10
	if_move MOVE_SING, AI_CBM_CheckIfSound_Minus10
	if_move MOVE_SNORE, AI_CBM_CheckIfSound_Minus10
	if_move MOVE_SUPERSONIC, AI_CBM_CheckIfSound_Minus10
	if_move MOVE_UPROAR, AI_CBM_CheckIfSound_Minus10
	goto AI_CBM_IfStatLowering

AI_CBM_CheckIfSound_Minus10:
	score -10
AI_CBM_IfStatLowering:
	get_considered_move_effect
	if_in_bytes AI_CBM_StatLower_Effects, AI_CBM_StatLowerImmunity
	if_in_bytes AI_CBM_StatLowerAndDamage_Effects, AI_CBM_StatLowerImmunity_Hit
	goto AI_CBM_CheckEffect

AI_CBM_StatLowerImmunity_Hit:
	get_ability AI_TARGET
	if_equal ABILITY_SHIELD_DUST, AI_CBM_StatLowerImmunity_Minus1
	if_in_bytes AI_CBM_BlockStatLowering, AI_CBM_StatLowerImmunity_Minus1
	if_side_affecting AI_TARGET, SIDE_STATUS_MIST, AI_CBM_StatLowerImmunity_Minus1
	goto AI_CBM_CheckEffect

AI_CBM_StatLowerImmunity:
	get_ability AI_TARGET
	if_in_bytes AI_CBM_BlockStatLowering, AI_CBM_StatLowerImmunity_Minus10
	if_side_affecting AI_TARGET, SIDE_STATUS_MIST, AI_CBM_StatLowerImmunity_Minus10
	goto AI_CBM_CheckEffect

AI_CBM_StatLowerImmunity_Minus1:
	score -1
	goto AI_CBM_CheckEffect

AI_CBM_StatLowerImmunity_Minus10:
	score -10
AI_CBM_CheckEffect:
	get_considered_move_effect
	if_in_bytes AI_Sleep_EffList, AI_CBM_Sleep
	if_in_bytes AI_CBM_Psn_EffList, AI_CBM_Toxic
	if_in_bytes AI_UseInSleep, AI_CBM_DamageDuringSleep
	if_in_bytes AI_CBM_Confuse_EffList, AI_CBM_Confuse
	if_in_bytes AI_CBM_AttackUp_EffList, AI_CBM_AttackUp
	if_in_bytes AI_CBM_DefenseUp_EffList, AI_CBM_DefenseUp
	if_in_bytes AI_CBM_SpeedUp_EffList, AI_CBM_SpeedUp
	if_in_bytes AI_CBM_SpAtkUp_EffList, AI_CBM_SpAtkUp
	if_in_bytes AI_CBM_SpDefUp_EffList, AI_CBM_SpDefUp
	if_in_bytes AI_CBM_AccUp_EffList, AI_CBM_AccUp
	if_in_bytes AI_CBM_EvasionUp_EffList, AI_CBM_EvasionUp
	if_in_bytes AI_CBM_AtkDown_EffList, AI_CBM_AttackDown
	if_in_bytes AI_CBM_DefDown_EffList, AI_CBM_DefenseDown
	if_in_bytes AI_SpeedDown_EffList, AI_CBM_SpeedDown
	if_in_bytes AI_SpAtkDown_EffList, AI_CBM_SpAtkDown
	if_in_bytes AI_CBM_SpDefDown_EffList, AI_CBM_SpDefDown
	if_in_bytes AI_CBM_AccDown_EffList, AI_CBM_AccDown
	if_in_bytes AI_EvasionDown_EffList, AI_CBM_EvasionDown
	if_in_bytes AI_CBM_ConsiderAllStats, AI_CBM_Haze
	if_in_bytes AI_CBM_Stockpile_EffList, AI_CBM_SpitUpAndSwallow
	if_in_bytes AI_CBM_ItemRemoval_EffList, AI_CBM_ItemRemoval
	if_in_bytes AI_CBM_DontRepeat_EffList, AI_CBM_DontRepeat
	if_effect EFFECT_BELLY_DRUM, AI_CBM_BellyDrum
	if_effect EFFECT_BULK_UP, AI_CBM_BulkUp
	if_effect EFFECT_CALM_MIND, AI_CBM_CalmMind
	if_effect EFFECT_COSMIC_POWER, AI_CBM_CosmicPower
	if_effect EFFECT_DRAGON_DANCE, AI_CBM_DragonDance
	if_effect EFFECT_TICKLE, AI_CBM_Tickle
	if_effect EFFECT_CURSE, AI_CBM_Curse
	if_effect EFFECT_FOCUS_ENERGY, AI_CBM_FocusEnergy
	if_effect EFFECT_ROAR, AI_CBM_Roar
	if_effect EFFECT_PARALYZE, AI_CBM_Paralyze
	if_effect EFFECT_WILL_O_WISP, AI_CBM_WillOWisp
	if_effect EFFECT_LEECH_SEED, AI_CBM_LeechSeed
	if_effect EFFECT_LIGHT_SCREEN, AI_CBM_LightScreen
	if_effect EFFECT_REFLECT, AI_CBM_Reflect
	if_effect EFFECT_OHKO, AI_CBM_OneHitKO
	if_effect EFFECT_EXPLOSION, AI_CBM_Explosion
	if_effect EFFECT_MEMENTO, AI_CBM_Memento
	if_effect EFFECT_MIST, AI_CBM_Mist
	if_effect EFFECT_SAFEGUARD, AI_CBM_Safeguard
	if_effect EFFECT_ATTRACT, AI_CBM_Attract
	if_effect EFFECT_SUBSTITUTE, AI_CBM_Substitute
	if_effect EFFECT_DISABLE, AI_CBM_Disable
	if_effect EFFECT_ENCORE, AI_CBM_Encore
	if_effect EFFECT_SPITE, AI_CBM_Spite
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
	if_effect EFFECT_TELEPORT, Score_Minus30
	if_effect EFFECT_FAKE_OUT, AI_CBM_FakeOut
	if_effect EFFECT_STOCKPILE, AI_CBM_Stockpile
	if_effect EFFECT_TAUNT, AI_CBM_Taunt
	if_effect EFFECT_TORMENT, AI_CBM_Torment
	if_effect EFFECT_HELPING_HAND, AI_CBM_HelpingHand
	if_effect EFFECT_RECYCLE, AI_CBM_Recycle
	if_effect EFFECT_INGRAIN, AI_CBM_Ingrain
	if_effect EFFECT_IMPRISON, AI_CBM_Imprison
	if_effect EFFECT_REFRESH, AI_CBM_Refresh
	if_effect EFFECT_HEAL_BELL, AI_CBM_HealBell
	if_effect EFFECT_REST, AI_CBM_Rest
	if_effect EFFECT_MUD_SPORT, AI_CBM_MudSport
	if_effect EFFECT_WATER_SPORT, AI_CBM_WaterSport
	if_effect EFFECT_CAMOUFLAGE, AI_CBM_Camouflage
	if_effect EFFECT_TRICK, AI_CBM_Trick
	end

AI_CBM_Sleep:
	get_ability AI_TARGET
	if_equal ABILITY_INSOMNIA, Score_Minus10
	if_equal ABILITY_VITAL_SPIRIT, Score_Minus10
	if_status AI_TARGET, STATUS1_ANY, Score_Minus10
	if_side_affecting AI_TARGET, SIDE_STATUS_SAFEGUARD, Score_Minus10
	end

AI_CBM_Paralyze:
	if_type_effectiveness AI_EFFECTIVENESS_x0, Score_Minus10
	get_ability AI_TARGET
	if_equal ABILITY_LIMBER, Score_Minus10
	goto AI_CBM_CheckTargetStatusImmune

AI_CBM_Toxic:
	get_target_type1
	if_in_bytes AI_PoisoningImmune, Score_Minus10
	get_target_type2
	if_in_bytes AI_PoisoningImmune, Score_Minus10
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
AI_CBM_CheckTargetStatusImmune:
	if_status AI_TARGET, STATUS1_ANY, Score_Minus10
	if_side_affecting AI_TARGET, SIDE_STATUS_SAFEGUARD, Score_Minus10
	if_ability AI_TARGET, ABILITY_GUTS, Score_Minus7
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
	if_status2 AI_TARGET, STATUS2_WRAPPED, Score_Minus3
	if_random_less_than 192, AI_End
	count_usable_party_mons AI_TARGET
	if_equal 0, Score_Minus1
	end

AI_CBM_Confuse:
	if_status2 AI_TARGET, STATUS2_CONFUSION, Score_Minus10
	get_ability AI_TARGET
	if_equal ABILITY_OWN_TEMPO, Score_Minus10
	if_side_affecting AI_TARGET, SIDE_STATUS_SAFEGUARD, Score_Minus10
	end

AI_CBM_Curse_Ghost:
	if_status2 AI_TARGET, STATUS2_CURSED, Score_Minus10
	end

AI_CBM_Foresight:
	if_status2 AI_TARGET, STATUS2_FORESIGHT, Score_Minus10
	end

AI_CBM_Nightmare:
	if_status2 AI_TARGET, STATUS2_NIGHTMARE, Score_Minus10
AI_CBM_DreamEater:
	if_not_status AI_TARGET, STATUS1_SLEEP, Score_Minus10
	if_waking AI_TARGET, Score_Minus10
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
	get_target_type1
	if_equal TYPE_GRASS, Score_Minus10
	get_target_type2
	if_equal TYPE_GRASS, Score_Minus10
	if_status3 AI_TARGET, STATUS3_LEECHSEED, AI_CBM_LeechSeed_RandomMinus10
	end

AI_CBM_LeechSeed_RandomMinus10:
	count_usable_party_mons AI_TARGET
	if_equal 0, Score_Minus10
	if_random_less_than 192, Score_Minus10
	end

AI_CBM_PerishSong:
	if_status3 AI_TARGET, STATUS3_PERISH_SONG, Score_Minus10
	end

AI_CBM_DamageDuringSleep:
	if_not_status AI_USER, STATUS1_SLEEP, Score_Minus10
    if_waking AI_USER, Score_Minus10
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
	if_can_use_substitute AI_USER, AI_CBM_Substitute_SubActiveCheck
	goto Score_Minus30

AI_CBM_Substitute_SubActiveCheck:
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
	get_spikes_layers_target
	if_equal 3, Score_Minus10
	end

AI_CBM_FutureSight:
	if_side_affecting AI_TARGET, SIDE_STATUS_FUTUREATTACK, Score_Minus12
	if_side_affecting AI_USER, SIDE_STATUS_FUTUREATTACK, Score_Minus12
	if_random_less_than 96, AI_End
	score +1
	end

AI_CBM_Disable:
	if_any_move_disabled AI_TARGET, Score_Minus10
	goto AI_CBM_Spite

AI_CBM_Encore:
	if_any_move_encored AI_TARGET, Score_Minus10
AI_CBM_Spite:
	if_target_faster AI_CBM_FirstTurnAndPPCheck
	end

AI_CBM_FirstTurnAndPPCheck:
	is_first_turn_for AI_TARGET
	if_equal TRUE, Score_Minus10
	get_target_previous_move_pp
	if_equal 0, Score_Minus10
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
	if_not_double_battle Score_Minus30
	end

AI_CBM_ItemRemoval:
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

AI_CBM_Trick:
	if_status2 AI_TARGET, STATUS2_SUBSTITUTE, Score_Minus10
	if_has_move_with_effect AI_TARGET, EFFECT_SUBSTITUTE, AI_CBM_Trick_CheckSubstitute
	end

AI_CBM_Trick_CheckSubstitute:
	if_target_faster AI_CBM_Trick_RandomMinus10
	end

AI_CBM_Trick_RandomMinus10:
	if_random_less_than 192, Score_Minus10
	end

AI_CBM_Rest:
	get_ability AI_USER
	if_in_bytes AI_SleepImmuneAbility, Score_Minus30
	end

AI_CBM_DontRepeat:
	used_considered_move_last_turn
	if_equal TRUE, Score_Minus30
	end

AI_CBM_BellyDrum:
	if_hp_less_than AI_USER, 51, Score_Minus10
AI_CBM_AttackUp:
	if_stat_level_equal AI_USER, STAT_ATK, MAX_STAT_STAGE, Score_Minus30
	end

AI_CBM_DefenseUp:
	if_stat_level_equal AI_USER, STAT_DEF, MAX_STAT_STAGE, Score_Minus30
	end

AI_CBM_SpeedUp:
	if_stat_level_equal AI_USER, STAT_SPEED, MAX_STAT_STAGE, Score_Minus30
	end

AI_CBM_SpAtkUp:
	if_stat_level_equal AI_USER, STAT_SPATK, MAX_STAT_STAGE, Score_Minus30
	end

AI_CBM_SpDefUp:
	if_stat_level_equal AI_USER, STAT_SPDEF, MAX_STAT_STAGE, Score_Minus30
	end

AI_CBM_AccUp:
	if_stat_level_equal AI_USER, STAT_ACC, MAX_STAT_STAGE, Score_Minus30
	end

AI_CBM_EvasionUp:
	if_stat_level_equal AI_USER, STAT_EVASION, MAX_STAT_STAGE, Score_Minus30
	end

AI_CBM_AttackDown:
	if_stat_level_equal AI_TARGET, STAT_ATK, MIN_STAT_STAGE, Score_Minus30
	get_ability AI_TARGET
	if_equal ABILITY_HYPER_CUTTER, Score_Minus30
	end

AI_CBM_DefenseDown:
	if_stat_level_equal AI_TARGET, STAT_DEF, MIN_STAT_STAGE, Score_Minus30
	end

AI_CBM_SpeedDown:
	if_stat_level_equal AI_TARGET, STAT_SPEED, MIN_STAT_STAGE, Score_Minus30
	if_ability AI_TARGET, ABILITY_SPEED_BOOST, Score_Minus7
	end

AI_CBM_SpAtkDown:
	if_stat_level_equal AI_TARGET, STAT_SPATK, MIN_STAT_STAGE, Score_Minus30
	end

AI_CBM_SpDefDown:
	if_stat_level_equal AI_TARGET, STAT_SPDEF, MIN_STAT_STAGE, Score_Minus30
	end

AI_CBM_AccDown:
	if_stat_level_equal AI_TARGET, STAT_ACC, MIN_STAT_STAGE, Score_Minus30
	get_ability AI_TARGET
	if_equal ABILITY_KEEN_EYE, Score_Minus30
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
	goto Score_Minus30

AI_CBM_Tickle:
	if_stat_level_more_than AI_TARGET, STAT_ATK, MIN_STAT_STAGE, AI_End
	if_stat_level_more_than AI_TARGET, STAT_DEF, MIN_STAT_STAGE, AI_End
	goto Score_Minus30

AI_CBM_CosmicPower:
	if_stat_level_less_than AI_USER, STAT_DEF, MAX_STAT_STAGE, AI_End
	if_stat_level_less_than AI_USER, STAT_SPDEF, MAX_STAT_STAGE, AI_End
	goto Score_Minus30

AI_CBM_Curse:
	get_user_type1
	if_equal TYPE_GHOST, AI_CBM_Curse_Ghost
	get_user_type2
	if_equal TYPE_GHOST, AI_CBM_Curse_Ghost
AI_CBM_BulkUp:
	if_stat_level_less_than AI_USER, STAT_ATK, MAX_STAT_STAGE, AI_End
	if_stat_level_less_than AI_USER, STAT_DEF, MAX_STAT_STAGE, AI_End
	goto Score_Minus30

AI_CBM_CalmMind:
	if_stat_level_less_than AI_USER, STAT_SPATK, MAX_STAT_STAGE, AI_End
	if_stat_level_less_than AI_USER, STAT_SPDEF, MAX_STAT_STAGE, AI_End
	goto Score_Minus30

AI_CBM_DragonDance:
	if_stat_level_less_than AI_USER, STAT_ATK, MAX_STAT_STAGE, AI_End
	if_stat_level_less_than AI_USER, STAT_SPEED, MAX_STAT_STAGE, AI_End
	goto Score_Minus30

Score_Minus1:
	score -1
	end

Score_Minus3:
	score -3
	end

Score_Minus5:
	score -5
	end

Score_Minus7:
	score -7
	end

Score_Minus8:
	score -8
	end

Score_Minus10:
	score -10
	end

Score_Minus12:
	score -12
	end

Score_Minus30:
	score -30
	end

AI_CheckViability:
	if_target_is_ally AI_End
	if_effect EFFECT_MIMIC, AI_CV_Mimic
	if_effect EFFECT_MIRROR_MOVE, AI_CV_MirrorMove
	goto AI_CV_CheckMovesAndEffects

AI_CV_Mimic:
	get_last_used_bank_move AI_TARGET
	if_in_bytes AI_CantMimic_EffList, AI_CV_ImitateMove_Minus10
	if_status2 AI_TARGET, STATUS2_SUBSTITUTE, AI_CV_ImitateMove_Minus10
	if_status3 AI_TARGET, STATUS3_SEMI_INVULNERABLE, AI_CV_ImitateMove_Minus10
	goto AI_CV_Imitate

AI_CV_MirrorMove:
	get_last_used_bank_move AI_TARGET
	if_in_bytes AI_DontMirror_EffList, AI_CV_ImitateMove_Minus10
	get_move_target_from_result
	if_not_equal MOVE_TARGET_SELECTED | MOVE_TARGET_BOTH | MOVE_TARGET_FOES_AND_ALLY, AI_CV_ImitateMove_Minus10
AI_CV_Imitate:
	if_target_faster AI_CV_ImitateMove_Minus10
	is_first_turn_for AI_USER
	if_equal TRUE, AI_CV_ImitateMove_Minus10
	consider_imitated_move
AI_CV_CheckMovesAndEffects:
	if_move MOVE_EARTHQUAKE, AI_CV_Underground
	if_move MOVE_FISSURE, AI_CV_Underground
	if_move MOVE_MAGNITUDE, AI_CV_Underground
	if_move MOVE_SURF, AI_CV_Underwater
	if_move MOVE_WHIRLPOOL, AI_CV_Underwater
	if_move MOVE_GUST, AI_CV_InTheAir
	if_move MOVE_SKY_UPPERCUT, AI_CV_InTheAir
	if_move MOVE_THUNDER, AI_CV_InTheAir
	if_move MOVE_TWISTER, AI_CV_InTheAir
	get_considered_move_effect
	if_in_bytes AI_CV_DefenseUp_EffList, AI_CV_DefenseUp
	if_in_bytes AI_CV_SpDefUp_EffList, AI_CV_SpDefUp
	if_in_bytes AI_CV_Stats_EffList, AI_CV_Stats
	if_in_bytes AI_CV_ModifySpeed, AI_CV_Speed
	if_in_bytes AI_CV_AtkDown_EffList, AI_CV_AttackDown
	if_in_bytes AI_SpAtkDown_EffList, AI_CV_SpAtkDown
	if_in_bytes AI_EvasionDown_EffList, AI_CV_EvasionDown
	if_in_bytes AI_CV_Heal_EffList, AI_CV_Heal
	if_in_bytes AI_CV_HealWeather_EffList, AI_CV_HealWeather
	if_in_bytes AI_CV_ClearStatus_EffList, AI_CV_ClearStatus
	if_in_bytes AI_Sleep_EffList, AI_CV_Sleep
	if_in_bytes AI_CV_ParalyzeHit_EffList, AI_CV_ParalyzeHit
	if_in_bytes AI_CV_ToxicAndSeed, AI_CV_Toxic
	if_in_bytes AI_CV_ChargeUp_EffList, AI_CV_ChargeUpMove
	if_in_bytes AI_CV_MultiHit_EffList, AI_CV_MultiHit
	if_in_bytes AI_CV_Trap_EffList, AI_CV_Trap
	if_in_bytes AI_CV_ChangeAbility_EffList, AI_CV_ChangeSelfAbility
	if_in_bytes AI_CV_Recoil_EffList, AI_CV_Recoil
	if_in_bytes AI_CV_SelfKO_EffList, AI_CV_SelfKO
	if_in_bytes AI_CV_Conversions_EffList, AI_CV_Conversion
	if_in_bytes AI_CV_DiscouragedEffList, AI_CV_GeneralDiscourage
	if_effect EFFECT_CURSE, AI_CV_Curse
	if_effect EFFECT_SPEED_DOWN_HIT, AI_CV_SpeedDownFromChance
	if_effect EFFECT_BELLY_DRUM, AI_CV_BellyDrum
	if_effect EFFECT_HAZE, AI_CV_Haze
	if_effect EFFECT_ROAR, AI_CV_Phazing
	if_effect EFFECT_PSYCH_UP, AI_CV_PsychUp
	if_effect EFFECT_PAIN_SPLIT, AI_CV_PainSplit
	if_effect EFFECT_REST, AI_CV_Rest
	if_effect EFFECT_WISH, AI_CV_Wish
	if_effect EFFECT_BRICK_BREAK, AI_CV_BrickBreak
	if_effect EFFECT_LIGHT_SCREEN, AI_CV_LightScreen
	if_effect EFFECT_REFLECT, AI_CV_Reflect
	if_effect EFFECT_SAFEGUARD, AI_CV_Safeguard
	if_effect EFFECT_SPIKES, AI_CV_Spikes
	if_effect EFFECT_PARALYZE, AI_CV_Paralyze
	if_effect EFFECT_WILL_O_WISP, AI_CV_Burn
	if_effect EFFECT_SOLAR_BEAM, AI_CV_SolarBeam
	if_effect EFFECT_RECHARGE, AI_CV_Recharge
	if_effect EFFECT_SUPER_FANG, AI_CV_SuperFang
	if_effect EFFECT_TAUNT, AI_CV_Taunt
	if_effect EFFECT_TORMENT, AI_CV_Torment
	if_effect EFFECT_DISABLE, AI_CV_Disable
	if_effect EFFECT_ENCORE, AI_CV_Encore
	if_effect EFFECT_SUBSTITUTE, AI_CV_Substitute
	if_effect EFFECT_BIDE, AI_CV_Bide
	if_effect EFFECT_COUNTER, AI_CV_Counter
	if_effect EFFECT_MIRROR_COAT, AI_CV_MirrorCoat
	if_effect EFFECT_SLEEP_TALK, AI_CV_SleepTalk
	if_effect EFFECT_SNORE, AI_CV_Snore
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
	if_effect EFFECT_KNOCK_OFF, AI_CV_KnockOff
	if_effect EFFECT_RECYCLE, AI_CV_Recycle
	if_effect EFFECT_THIEF, AI_CV_Thief
	if_effect EFFECT_TRICK, AI_CV_Trick
	if_effect EFFECT_CAMOUFLAGE, AI_CV_Camouflage
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
	if_effect EFFECT_OVERHEAT, AI_CV_Overheat
	if_effect EFFECT_RAPID_SPIN, AI_CV_RapidSpin
	if_effect EFFECT_REVENGE, AI_CV_Revenge
	if_effect EFFECT_ROLLOUT, AI_CV_Rollout
	if_effect EFFECT_SEMI_INVULNERABLE, AI_CV_SemiInvulnerable
	if_effect EFFECT_SMELLINGSALT, AI_CV_SmellingSalt
	if_effect EFFECT_SPIT_UP, AI_CV_SpitUp
	if_effect EFFECT_PERISH_SONG, AI_CV_SuicideCheck
	if_effect EFFECT_FAKE_OUT, AI_CV_FakeOut
	if_effect EFFECT_SUPERPOWER, AI_CV_Superpower
	end

AI_CV_ImitateMove_Minus10:
	score -10
	end

AI_CV_InTheAir:
	if_status3 AI_TARGET, STATUS3_ON_AIR, AI_CV_InvulnerableHit
	goto AI_CV_NextAI

AI_CV_Underground:
	if_status3 AI_TARGET, STATUS3_UNDERGROUND, AI_CV_InvulnerableHit
	goto AI_CV_NextAI

AI_CV_Underwater:
	if_status3 AI_TARGET, STATUS3_UNDERWATER, AI_CV_InvulnerableHit
	goto AI_CV_NextAI

AI_CV_InvulnerableHit:
	if_status3 AI_TARGET, STATUS3_ALWAYS_HITS, AI_CV_NextAI
	if_target_faster AI_CV_NextAI
	score +35
AI_CV_NextAI:
	if_move MOVE_WHIRLPOOL, AI_CV_Trap
	if_effect EFFECT_THUNDER, AI_CV_ParalyzeHit
	end

AI_CV_MultiHit:
	if_status2 AI_TARGET, STATUS2_SUBSTITUTE, AI_MultiHit_Plus3
	end

AI_MultiHit_Plus3:
	score +3
	end

AI_CV_Sleep:
	get_last_used_bank_move AI_USER
	get_move_effect_from_result
	if_not_equal EFFECT_SLEEP, AI_CV_Sleep_ItemCheck
	if_has_move_with_effect AI_USER, EFFECT_SUBSTITUTE, AI_CV_Sleep_CheckSubstitute
	goto AI_CV_Sleep_RandomPlus3

AI_CV_Sleep_CheckSubstitute:
	if_can_use_substitute AI_USER, AI_CV_Sleep_CheckSubUp
	goto AI_CV_Sleep_RandomPlus3

AI_CV_Sleep_CheckSubUp:
	if_status2 AI_USER, STATUS2_SUBSTITUTE, AI_CV_Sleep_RandomPlus3
	goto AI_CV_Sleep_ItemCheck

AI_CV_Sleep_RandomPlus3:
	if_random_less_than 224, AI_CV_Sleep_ItemCheck
	score +3
AI_CV_Sleep_ItemCheck:
	if_holds_item AI_TARGET, ITEM_CHESTO_BERRY, AI_CV_Sleep_ItemCheck_RandomMinus1
	if_holds_item AI_TARGET, ITEM_LUM_BERRY, AI_CV_Sleep_ItemCheck_RandomMinus1
	score +1
	end

AI_CV_Sleep_ItemCheck_RandomMinus1:
	if_target_faster AI_CV_Sleep_ItemCheck_Minus1
	if_random_less_than 128, AI_End
AI_CV_Sleep_ItemCheck_Minus1:
	score -1
	end

AI_CV_Burn:
	if_random_less_than 64, AI_End
	score +2
	end

AI_CV_Toxic:
	is_first_turn_for AI_USER
	if_equal FALSE, AI_CV_Toxic_StatBoosts
	score +1
AI_CV_Toxic_StatBoosts:
	if_has_move_with_effect AI_TARGET, EFFECT_BULK_UP, AI_CV_Toxic_StatBoosts_Plus1
	if_has_move_with_effect AI_TARGET, EFFECT_DEFENSE_CURL, AI_CV_Toxic_StatBoosts_Plus1
	if_has_move_with_effect AI_TARGET, EFFECT_DEFENSE_UP, AI_CV_Toxic_StatBoosts_Plus1
	if_has_move_with_effect AI_TARGET, EFFECT_DEFENSE_UP_2, AI_CV_Toxic_StatBoosts_Plus1
	if_has_move_with_effect AI_TARGET, EFFECT_CALM_MIND, AI_CV_Toxic_StatBoosts_Plus1
	if_has_move_with_effect AI_TARGET, EFFECT_SPECIAL_DEFENSE_UP, AI_CV_Toxic_StatBoosts_Plus1
	if_has_move_with_effect AI_TARGET, EFFECT_SPECIAL_DEFENSE_UP_2, AI_CV_Toxic_StatBoosts_Plus1
	if_has_move_with_effect AI_TARGET, EFFECT_COSMIC_POWER, AI_CV_Toxic_StatBoosts_Plus1
	if_has_move_with_effect AI_TARGET, EFFECT_DRAGON_DANCE, AI_CV_Toxic_StatBoosts_Plus1
	if_has_move_with_effect AI_TARGET, EFFECT_MINIMIZE, AI_CV_Toxic_StatBoosts_Plus1
	if_has_move_with_effect AI_TARGET, EFFECT_ATTACK_UP, AI_CV_Toxic_StatBoosts_Plus1
	if_has_move_with_effect AI_TARGET, EFFECT_ATTACK_UP_2, AI_CV_Toxic_StatBoosts_Plus1
	if_has_move_with_effect AI_TARGET, EFFECT_EVASION_UP, AI_CV_Toxic_StatBoosts_Plus1
	if_has_move_with_effect AI_TARGET, EFFECT_EVASION_UP_2, AI_CV_Toxic_StatBoosts_Plus1
	if_has_move_with_effect AI_TARGET, EFFECT_SPECIAL_ATTACK_UP, AI_CV_Toxic_StatBoosts_Plus1
	if_has_move_with_effect AI_TARGET, EFFECT_SPECIAL_ATTACK_UP_2, AI_CV_Toxic_StatBoosts_Plus1
	if_has_move_with_effect AI_TARGET, EFFECT_SPEED_UP, AI_CV_Toxic_StatBoosts_Plus1
	if_has_move_with_effect AI_TARGET, EFFECT_SPEED_UP_2, AI_CV_Toxic_StatBoosts_Plus1
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

AI_CV_ParalyzeHit:
	get_considered_move_second_eff_chance
	if_more_than 20, AI_CV_Paralyze
	end

AI_CV_Paralyze:
	if_target_faster AI_CV_Paralyze_TargetFaster
	if_random_less_than 64, AI_End
	score +1
	end

AI_CV_Paralyze_TargetFaster:
	if_random_less_than 20, AI_End
	score +3
	end

AI_CV_SleepTalk:
	if_holds_item AI_USER, ITEM_CHOICE_BAND, AI_CV_SleepTalk_CB
	goto AI_CV_Snore

AI_CV_SleepTalk_CB:
	count_usable_party_mons AI_USER
	if_not_equal 0, AI_CV_Snore
	count_usable_party_mons AI_TARGET
	if_not_equal 0, AI_CV_SleepTalk_Minus5
	if_ai_can_faint AI_CV_Snore
	if_hp_less_than AI_TARGET, 33, AI_CV_Snore
AI_CV_SleepTalk_Minus5:
	score -5
	end

AI_CV_Snore:
	if_waking AI_USER, AI_End
	score +10
	end

AI_CV_EvasionDown:
	if_stat_level_less_than AI_TARGET, STAT_EVASION, 5, AI_CV_Evasion_Minus10
	goto AI_CV_Stats

AI_CV_Evasion_Minus10:
	score -10
	end

AI_CV_AttackDown:
	if_has_attack_of_category AI_TARGET, TYPE_PHYSICAL, AI_CV_Stats
	score -10
	end

AI_CV_SpAtkDown:
	if_has_attack_of_category AI_TARGET, TYPE_SPECIAL, AI_CV_Stats
	if_has_move AI_TARGET, MOVE_HIDDEN_POWER, AI_CV_Stats
	score -10
	end

AI_CV_Curse:
	get_user_type1
	if_equal TYPE_GHOST, AI_CV_CurseGhost
	get_user_type2
	if_equal TYPE_GHOST, AI_CV_CurseGhost
AI_CV_DefenseUp:
	if_has_attack_of_category AI_TARGET, TYPE_PHYSICAL, AI_CV_DefensesUp_Plus1
	goto AI_CV_Stats

AI_CV_SpDefUp:
	if_has_attack_of_category AI_TARGET, TYPE_SPECIAL, AI_CV_DefensesUp_Plus1
	if_has_move AI_TARGET, MOVE_HIDDEN_POWER, AI_CV_DefensesUp_Plus1
	goto AI_CV_Stats

AI_CV_Speed:
	if_target_faster AI_CV_Speed2
	if_random_less_than 32, AI_CV_Stats
	score -2
	goto AI_CV_Stats

AI_CV_Speed2:
	if_random_less_than 70, AI_CV_Stats
	score +3
	goto AI_CV_Stats

AI_CV_DefensesUp_Plus1:
	if_random_less_than 48, AI_CV_Stats
	score +1
AI_CV_Stats:
	if_ai_can_faint AI_CV_Stats_Minus7
	if_any_move_encored AI_USER, AI_CV_Stats_Minus7
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
	end

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
	end

AI_CV_Stats_Cautious_Statused:
	if_hp_less_than AI_USER, 62, AI_CV_Stats_Minus2
	if_hp_equal AI_USER, 100, AI_CV_Stats_Plus1
	if_hp_less_than AI_USER, 73, AI_CV_Stats_Minus2_Random
	if_hp_more_than AI_USER, 90, AI_CV_Stats_Plus1_Random
	if_random_less_than 64, AI_CV_Stats_Plus1
	if_random_less_than 160, AI_CV_Stats_Minus2
	end

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

AI_CV_Stats_Minus7:
	score -7
	end

AI_CV_CurseGhost:
	if_hp_more_than AI_USER, 90, AI_End
	score -2
	if_hp_more_than AI_USER, 50, AI_End
	score -30
	end

AI_CV_BellyDrum:
	if_status2 AI_USER, STATUS2_SUBSTITUTE, AI_CV_BellyDrum_Plus1
	if_hp_less_than AI_USER, 81, AI_CV_BellyDrum_Minus10
	if_stat_level_more_than AI_USER, STAT_DEF, 9, AI_CV_BellyDrum_Plus1
	if_stat_level_more_than AI_USER, STAT_SPDEF, 9, AI_CV_BellyDrum_Plus1
	if_hp_less_than AI_USER, 84, AI_CV_BellyDrum_Minus10
	if_stat_level_more_than AI_USER, STAT_DEF, 8, AI_CV_BellyDrum_Plus1
	if_stat_level_more_than AI_USER, STAT_SPDEF, 8, AI_CV_BellyDrum_Plus1
	if_hp_less_than AI_USER, 88, AI_CV_BellyDrum_Minus10
	if_stat_level_more_than AI_USER, STAT_DEF, 7, AI_CV_BellyDrum_Plus1
	if_stat_level_more_than AI_USER, STAT_SPDEF, 7, AI_CV_BellyDrum_Plus1
	if_hp_less_than AI_USER, 92, AI_CV_BellyDrum_Minus10
	if_stat_level_more_than AI_USER, STAT_DEF, 6, AI_CV_BellyDrum_Plus1
	if_stat_level_more_than AI_USER, STAT_SPDEF, 6, AI_CV_BellyDrum_Plus1
	if_hp_less_than AI_USER, 98, AI_CV_BellyDrum_Minus10
	end

AI_CV_BellyDrum_Plus1:
	score +1
	end

AI_CV_BellyDrum_Minus10:
	score -10
	end

AI_CV_SpeedDownFromChance:
	get_considered_move_second_eff_chance
	if_more_than 20, AI_CV_Speed
	end

AI_CV_PsychUp:
	get_last_used_bank_move AI_USER
	get_move_effect_from_result
	if_equal EFFECT_PSYCH_UP, AI_CV_Haze_Minus9
AI_CV_Haze:
	score -1
	if_stat_level_more_than AI_USER, STAT_ATK, 6, AI_CV_Haze_Minus9
	if_stat_level_more_than AI_USER, STAT_DEF, 6, AI_CV_Haze_Minus9
	if_stat_level_more_than AI_USER, STAT_SPATK, 6, AI_CV_Haze_Minus9
	if_stat_level_more_than AI_USER, STAT_SPDEF, 6, AI_CV_Haze_Minus9
	if_stat_level_more_than AI_USER, STAT_SPEED, 6, AI_CV_Haze_Minus9
	if_stat_level_more_than AI_USER, STAT_EVASION, 6, AI_CV_Haze_Minus9
	if_stat_level_less_than AI_TARGET, STAT_ATK, 6, AI_CV_Haze_Minus9
	if_stat_level_less_than AI_TARGET, STAT_DEF, 6, AI_CV_Haze_Minus9
	if_stat_level_less_than AI_TARGET, STAT_SPATK, 6, AI_CV_Haze_Minus9
	if_stat_level_less_than AI_TARGET, STAT_SPDEF, 6, AI_CV_Haze_Minus9
	if_stat_level_less_than AI_TARGET, STAT_SPEED, 6, AI_CV_Haze_Minus9
	if_stat_level_less_than AI_TARGET, STAT_ACC, 6, AI_CV_Haze_Minus9
	if_stat_level_more_than AI_TARGET, STAT_ATK, 6, AI_CV_Haze_Plus2
	if_stat_level_more_than AI_TARGET, STAT_DEF, 6, AI_CV_Haze_Plus2
	if_stat_level_more_than AI_TARGET, STAT_SPATK, 6, AI_CV_Haze_Plus2
	if_stat_level_more_than AI_TARGET, STAT_SPDEF, 6, AI_CV_Haze_Plus2
	if_stat_level_more_than AI_TARGET, STAT_SPEED, 6, AI_CV_Haze_Plus2
	if_stat_level_more_than AI_TARGET, STAT_EVASION, 6, AI_CV_Haze_Plus2
	if_stat_level_less_than AI_USER, STAT_ATK, 6, AI_CV_Haze_Plus2
	if_stat_level_less_than AI_USER, STAT_DEF, 6, AI_CV_Haze_Plus2
	if_stat_level_less_than AI_USER, STAT_SPATK, 6, AI_CV_Haze_Plus2
	if_stat_level_less_than AI_USER, STAT_SPDEF, 6, AI_CV_Haze_Plus2
	if_stat_level_less_than AI_USER, STAT_SPEED, 6, AI_CV_Haze_Plus2
	if_stat_level_less_than AI_USER, STAT_ACC, 6, AI_CV_Haze_Plus2
AI_CV_Haze_Minus9:
	score -9
	end

AI_CV_Haze_Plus2:
	score +2
	end

AI_CV_Phazing:
	if_ai_can_faint AI_CV_PhazingDiscourage
	get_spikes_layers_target
	if_equal 3, AI_CV_Phazing_MaxSpikes
	if_side_affecting AI_TARGET, SIDE_STATUS_SPIKES, AI_CV_Phazing_OneLayer
	goto AI_CV_PhazingStatCheck

AI_CV_Phazing_MaxSpikes:
	if_random_less_than 32, AI_CV_PhazingStatCheck
	goto AI_CV_Phazing_Plus2

AI_CV_Phazing_OneLayer:
	if_random_less_than 192, AI_CV_PhazingStatCheck
AI_CV_Phazing_Plus2:
	score +2
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
	if_random_less_than 96, AI_End
	score -1
	end

AI_CV_PhazingDiscourage:
	score -3
	end

AI_CV_PhazingEncourage:
	score +1
	end

AI_CV_HealWeather:
	get_weather
	if_equal AI_WEATHER_HAIL, AI_CV_HealWeather_Minus8
	if_equal AI_WEATHER_RAIN, AI_CV_HealWeather_Minus8
	if_equal AI_WEATHER_SANDSTORM, AI_CV_HealWeather_Minus8
	goto AI_CV_Heal

AI_CV_HealWeather_Minus8:
	score -8
AI_CV_Heal:
	if_hp_more_than AI_USER, 80, AI_CV_Heal_HighHP
	if_target_faster AI_CV_Heal_Slower
	if_ai_can_faint AI_CV_Heal_Plus2
	if_hp_less_than AI_USER, 48, AI_CV_Heal_Plus2
	if_hp_less_than AI_USER, 60, AI_CV_Heal_CheckSnatch
	if_random_less_than 70, AI_CV_Heal_CheckSnatch
	goto AI_CV_Heal_HighHP

AI_CV_Heal_Slower:
	if_hp_less_than AI_USER, 55, AI_CV_Heal_Plus2
	if_hp_less_than AI_USER, 72, AI_CV_Heal_CheckSnatch
	if_random_less_than 30, AI_CV_Heal_CheckSnatch
AI_CV_Heal_HighHP:
	score -8
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
	score -8
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
	score -8
	end

AI_CV_Wish_Plus2_Random:
	if_random_less_than 48, AI_End
AI_CV_Wish_Plus2:
	score +2
	end

AI_CV_PainSplit:
	if_hp_less_than AI_TARGET, 60, AI_CV_PainSplit_Minus10
	if_hp_less_than AI_TARGET, 80, AI_CV_PainSplit_Minus1
	if_target_faster AI_CV_PainSplit2
	if_hp_more_than AI_USER, 60, AI_CV_PainSplit_Minus10
	if_hp_more_than AI_USER, 40, AI_CV_PainSplit_Minus1
	goto AI_CV_PainSplit_Plus1

AI_CV_PainSplit2:
	if_hp_more_than AI_USER, 80, AI_CV_PainSplit_Minus10
	if_hp_more_than AI_USER, 60, AI_CV_PainSplit_Minus1
AI_CV_PainSplit_Plus1:
	if_random_less_than 48, AI_End
	score +1
	end

AI_CV_PainSplit_Minus10:
	score -9
AI_CV_PainSplit_Minus1:
	score -1
	end

AI_CV_Reflect:
	if_has_attack_of_category AI_TARGET, TYPE_PHYSICAL, AI_CV_UseScreen
	goto AI_CV_DontUseScreen

AI_CV_LightScreen:
	if_has_attack_of_category AI_TARGET, TYPE_SPECIAL, AI_CV_UseScreen
	if_has_move AI_TARGET, MOVE_HIDDEN_POWER, AI_CV_UseScreen
AI_CV_DontUseScreen:
	if_random_less_than 4, AI_End
	score -8
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
	if_has_move_with_effect AI_TARGET, EFFECT_SUBSTITUTE, AI_CV_SuperFang_HasSub
	if_hp_more_than AI_TARGET, 40, AI_End
	goto AI_CV_SuperFang_Minus1

AI_CV_SuperFang_HasSub:
	if_hp_more_than AI_TARGET, 74, AI_End
AI_CV_SuperFang_Minus1:
	score -1
	end

AI_CV_Trap:
	if_status AI_TARGET, STATUS1_TOXIC_POISON, AI_CV_Trap_Plus2
	if_status2 AI_TARGET, STATUS2_CURSED, AI_CV_Trap_Plus2
	if_status3 AI_TARGET, STATUS3_PERISH_SONG, AI_CV_Trap_Plus2
	if_status AI_TARGET, STATUS1_BURN | STATUS1_POISON, AI_CV_Trap_Plus2_Random
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
	if_target_faster AI_CV_Transform_TargetFaster_Plus1
	goto AI_CV_Transform_StatusCheck

AI_CV_Transform_TargetFaster_Plus1:
	score +1
AI_CV_Transform_StatusCheck:
	if_status AI_TARGET, STATUS1_SLEEP | STATUS1_FREEZE, AI_CV_Transform_Status_Plus1
	goto AI_CV_Transform_EncoreCheck

AI_CV_Transform_Status_Plus1:
	score +1
AI_CV_Transform_EncoreCheck:
	if_any_move_encored AI_TARGET, AI_CV_Transform_Encore_Plus1
	goto AI_CV_Transform_ScreenCheck

AI_CV_Transform_Encore_Plus1:
	score +1
AI_CV_Transform_ScreenCheck:
	if_side_affecting AI_USER, SIDE_STATUS_REFLECT | SIDE_STATUS_LIGHTSCREEN, AI_CV_Transform_Screen_Plus1
	goto AI_CV_Transform_HPCheck

AI_CV_Transform_Screen_Plus1:
	score +1
AI_CV_Transform_HPCheck:
	if_hp_less_than AI_USER, 50, AI_CV_Transform_HP_Minus1
	end

AI_CV_Transform_HP_Minus1:
	score -1
	end

AI_CV_Camouflage:
	if_has_attack_of_type AI_TARGET, TYPE_FIGHTING, AI_CV_Camouflage_Fighting_Minus10
	goto AI_CV_Camouflage_CheckTypeMatchup

AI_CV_Camouflage_Fighting_Minus10:
	score -10
AI_CV_Camouflage_CheckTypeMatchup:
	get_highest_type_effectiveness_from_target
	if_equal AI_EFFECTIVENESS_x2, AI_CV_Camouflage_Plus1
	if_equal AI_EFFECTIVENESS_x4, AI_CV_Camouflage_Plus1
	if_equal AI_EFFECTIVENESS_x0, AI_CV_Camouflage_Minus10
	if_equal AI_EFFECTIVENESS_x0_25, AI_CV_Camouflage_Minus10
	if_equal AI_EFFECTIVENESS_x0_5, AI_CV_Camouflage_Minus2
	end

AI_CV_Camouflage_Plus1:
	score +1
	end

 AI_CV_Camouflage_Minus2:
	score -2
	end

AI_CV_Camouflage_Minus10:
	score -10
	end

AI_CV_ChangeSelfAbility:
	get_ability AI_USER
	if_in_bytes AI_SleepImmuneAbility, AI_CV_ChangeSelfAbility_SleepImmune
	if_in_bytes AI_CV_ChangeSelfAbility_AbilitiesToEncourage, AI_CV_ChangeSelfAbility_Minus10
	goto AI_CV_ChangeSelfAbility_CheckTarget

AI_CV_ChangeSelfAbility_SleepImmune:
	if_has_move_with_effect AI_USER, EFFECT_REST, AI_CV_ChangeSelfAbility_SleepImmune_CheckTarget
	goto AI_CV_ChangeSelfAbility_CheckTarget

AI_CV_ChangeSelfAbility_SleepImmune_CheckTarget:
	get_ability AI_TARGET
	if_in_bytes AI_SleepImmuneAbility, AI_CV_ChangeSelfAbility_Minus10
	if_in_bytes AI_CV_DontCopyAbilities, AI_CV_ChangeSelfAbility_Minus10
	goto AI_CV_ChangeSelfAbility_RandomPlus2

AI_CV_ChangeSelfAbility_CheckTarget:
	get_ability AI_TARGET
	if_in_bytes AI_CV_ChangeSelfAbility_AbilitiesToEncourage, AI_CV_ChangeSelfAbility_RandomPlus2
AI_CV_ChangeSelfAbility_Minus10:
	score -10
	end

AI_CV_ChangeSelfAbility_RandomPlus2:
	if_random_less_than 51, AI_End
	score +2
	end

AI_CV_ThawUser:
	if_status AI_USER, STATUS1_FREEZE, AI_CV_ThawUser_Plus32
	end

AI_CV_ThawUser_Plus32:
	score +32
	end

AI_CV_Facade:
	if_not_status AI_USER, STATUS1_POISON | STATUS1_BURN | STATUS1_PARALYSIS | STATUS1_TOXIC_POISON, AI_End
	score +1
	end

AI_CV_Substitute:
	if_status AI_TARGET, STATUS1_FREEZE | STATUS1_SLEEP, AI_CV_Substitute_TargetImmobile_Plus2
	if_status AI_TARGET, STATUS1_PARALYSIS, AI_CV_Substitute_TargetParalyzed_Plus1
	goto AI_CV_Substitute_CheckUserStatus

AI_CV_Substitute_TargetImmobile_Plus2:
	score +1
AI_CV_Substitute_TargetParalyzed_Plus1:
	score +1
AI_CV_Substitute_CheckUserStatus:
	if_status AI_USER, STATUS1_POISON | STATUS1_BURN | STATUS1_PARALYSIS | STATUS1_TOXIC_POISON, AI_CV_Substitute_Minus8
	if_status2 AI_USER, STATUS2_CURSED, AI_CV_Substitute_Minus8
	if_status3 AI_USER, STATUS3_LEECHSEED | STATUS3_YAWN, AI_CV_Substitute_Minus8
	if_user_faster AI_CV_Substitute_UserFaster
	get_highest_type_effectiveness_from_target
	if_equal AI_EFFECTIVENESS_x0, AI_CV_Substitute_StatusMoveCheck_Slower
	if_equal AI_EFFECTIVENESS_x0_25, AI_CV_Substitute_StatusMoveCheck_Slower
	if_hp_more_than AI_USER, 70, AI_CV_Substitute_SlowHighHP
	goto AI_CV_Substitute_Minus8

AI_CV_Substitute_UserFaster:
	if_has_move_with_effect AI_USER, EFFECT_FLAIL, AI_CV_Substitute_Plus8
	if_has_move_with_effect AI_USER, EFFECT_ENDEAVOR, AI_CV_Substitute_Plus8
	get_hold_effect AI_USER
	if_in_bytes AI_CV_Substitute_PinchBerries, AI_CV_Substitute_Plus1_Random
	if_hp_more_than AI_USER, 33, AI_CV_Substitute_AbilityCheck
	goto AI_CV_Substitute_StatusMoveCheck

AI_CV_Substitute_AbilityCheck:
	if_ability AI_USER, ABILITY_BLAZE, AI_CV_Substitute_Blaze
	if_ability AI_USER, ABILITY_OVERGROW, AI_CV_Substitute_Overgrow
	if_ability AI_USER, ABILITY_SWARM, AI_CV_Substitute_Swarm
	if_ability AI_USER, ABILITY_TORRENT, AI_CV_Substitute_Torrent
	goto AI_CV_Substitute_StatusMoveCheck

AI_CV_Substitute_Blaze:
	if_has_attack_of_type AI_USER, TYPE_FIRE, AI_CV_Substitute_Plus1_Random
	goto AI_CV_Substitute_StatusMoveCheck

AI_CV_Substitute_Overgrow:
	if_has_attack_of_type AI_USER, TYPE_GRASS, AI_CV_Substitute_Plus1_Random
	goto AI_CV_Substitute_StatusMoveCheck

AI_CV_Substitute_Swarm:
	if_has_attack_of_type AI_USER, TYPE_BUG, AI_CV_Substitute_Plus1_Random
	goto AI_CV_Substitute_StatusMoveCheck

AI_CV_Substitute_Torrent:
	if_has_attack_of_type AI_USER, TYPE_WATER, AI_CV_Substitute_Plus1_Random
AI_CV_Substitute_StatusMoveCheck:
	if_has_move_with_effect AI_TARGET, EFFECT_LEECH_SEED, AI_CV_Substitute_DodgeStatus_RandomPlus2
	if_has_move_with_effect AI_TARGET, EFFECT_PARALYZE, AI_CV_Substitute_DodgeStatus_RandomPlus2
	if_has_move_with_effect AI_TARGET, EFFECT_SLEEP, AI_CV_Substitute_DodgeStatus_RandomPlus2
	if_has_move_with_effect AI_TARGET, EFFECT_TOXIC, AI_CV_Substitute_DodgeStatus_RandomPlus2
	if_has_move_with_effect AI_TARGET, EFFECT_WILL_O_WISP, AI_CV_Substitute_DodgeStatus_RandomPlus2
	if_has_move_with_effect AI_TARGET, EFFECT_YAWN, AI_CV_Substitute_DodgeStatus_RandomPlus2
	goto AI_CV_Substitute_LastMoveCheck

AI_CV_Substitute_DodgeStatus_RandomPlus2:
	if_random_less_than 64, AI_CV_Substitute_LastMoveCheck
	score +2
	goto AI_CV_Substitute_LastMoveCheck

AI_CV_Substitute_StatusMoveCheck_Slower:
	if_has_move_with_effect AI_TARGET, EFFECT_LEECH_SEED, AI_CV_Substitute_Minus8
	if_has_move_with_effect AI_TARGET, EFFECT_PARALYZE, AI_CV_Substitute_Minus8
	if_has_move_with_effect AI_TARGET, EFFECT_SLEEP, AI_CV_Substitute_Minus8
	if_has_move_with_effect AI_TARGET, EFFECT_TOXIC, AI_CV_Substitute_Minus8
	if_has_move_with_effect AI_TARGET, EFFECT_WILL_O_WISP, AI_CV_Substitute_Minus8
	if_has_move_with_effect AI_TARGET, EFFECT_YAWN, AI_CV_Substitute_Minus8
	if_has_move_with_effect AI_TARGET, EFFECT_ROAR, AI_CV_Substitute_Minus8
AI_CV_Substitute_SlowHighHP:
	if_random_less_than 128, AI_CV_Substitute_LastMoveCheck
	score -1
AI_CV_Substitute_LastMoveCheck:
	get_last_used_bank_move AI_TARGET
	get_move_effect_from_result
	if_equal EFFECT_ROAR, AI_CV_Substitute_TargetRoared
	get_last_used_bank_move AI_TARGET
	get_move_power_from_result
	if_equal 0, AI_CV_SubTect
	if_random_less_than 77, AI_CV_SubTect
	score +1
	goto AI_CV_SubTect

AI_CV_Substitute_TargetRoared:
	if_random_less_than 64, AI_CV_SubTect
	score -1
AI_CV_SubTect:
	if_has_move_with_effect AI_USER, EFFECT_PROTECT, AI_CV_SubTect_CheckLastMove
	goto AI_CV_Substitute_Plus1_Random

AI_CV_SubTect_CheckLastMove:
	get_last_used_bank_move AI_USER
	get_move_effect_from_result
	if_equal EFFECT_SUBSTITUTE, AI_CV_Substitute_Minus3
AI_CV_Substitute_Plus1_Random:
	if_random_less_than 32, AI_End
AI_CV_Substitute_Plus1:
	score +1
	end

AI_CV_Substitute_Plus8:
	score +8
	end

AI_CV_Substitute_Minus1:
	score -1
	end

AI_CV_Substitute_Minus3:
	score -3
	end

AI_CV_Substitute_Minus8:
	score -8
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
	get_type_effectiveness_from_result
	if_equal AI_EFFECTIVENESS_x0, AI_CV_Encore_Plus3
	if_equal AI_EFFECTIVENESS_x0_25, AI_CV_Encore_Plus3
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
	if_status2 AI_USER, STATUS2_SUBSTITUTE, AI_CV_LockOn_RandomMinus1
	if_ai_can_faint AI_CV_LockOn_Minus10
AI_CV_LockOn_RandomMinus1:
	if_random_less_than 128, AI_End
	score -1
	end

AI_CV_LockOn_Minus10:
	score -10
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
	get_curr_move_type
	if_in_bytes AI_PhysicalTypeList, AI_CV_AlwaysHit_CheckHustle
	end

AI_CV_AlwaysHit_CheckHustle:
	get_ability AI_USER
	if_equal ABILITY_HUSTLE, AI_CV_AlwaysHit_Plus1
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
	goto AI_CV_SelfKO_CheckProtect

AI_CV_SelfKO_HighRisk:
	if_random_less_than 192, AI_CV_SelfKO_CheckProtect
	score -2
AI_CV_SelfKO_CheckProtect:
	if_has_move_with_effect AI_TARGET, EFFECT_PROTECT, AI_CV_SelfKO_CheckProtect2
	goto AI_CV_SuicideCheck

AI_CV_SelfKO_CheckProtect2:
	get_protect_count AI_TARGET
	if_less_than 2, AI_CV_SelfKO_RiskOfProtect
	goto AI_CV_SelfKO_CheckCanFaint

AI_CV_SelfKO_RiskOfProtect:
	if_random_less_than 160, AI_CV_SelfKO_CheckCanFaint
	score -2
AI_CV_SelfKO_CheckCanFaint:
	if_ai_can_faint AI_CV_SelfKO_CanFaint
	goto AI_CV_SuicideCheck

AI_CV_SelfKO_CanFaint:
	if_can_faint AI_CV_SuicideCheck
	if_random_less_than 32, AI_CV_SuicideCheck
	score +4
	goto AI_CV_SuicideCheck

AI_CV_Grudge:
	count_usable_party_mons AI_USER
	if_equal 0, AI_CV_Grudge_DontUse
AI_CV_DestinyBond:
	if_target_faster AI_CV_DestinyBond_Minus1
	if_ai_can_faint AI_CV_DestinyBond_RandomPlus3
AI_CV_DestinyBond_Minus1:
	score -1
	goto AI_CV_SuicideCheck

AI_CV_Grudge_DontUse:
	score -30
	end

AI_CV_DestinyBond_RandomPlus3:
	if_random_less_than 32, AI_CV_SuicideCheck
	score +3
	goto AI_CV_SuicideCheck

AI_CV_Taunt:
	if_target_faster AI_CV_Taunt_Discourage
	if_waking AI_TARGET, AI_CV_Taunt_CheckTypeEffectiveness
	if_has_move AI_TARGET, MOVE_SLEEP_TALK, AI_CV_Taunt_SleepTalk
	if_has_move AI_TARGET, MOVE_SNORE, AI_CV_Taunt_SleepTalk
	goto AI_CV_Taunt_Discourage

AI_CV_Taunt_SleepTalk:
	get_user_type1
	if_equal TYPE_GHOST, AI_CV_Taunt_Encourage
	get_user_type2
	if_equal TYPE_GHOST, AI_CV_Taunt_Encourage
	if_has_move AI_TARGET, MOVE_SNORE, AI_CV_Taunt_Discourage
	goto AI_CV_Taunt_Encourage

AI_CV_Taunt_CheckTypeEffectiveness:
	get_highest_type_effectiveness_from_target
	if_equal AI_EFFECTIVENESS_x2, AI_CV_Taunt_Discourage
	if_equal AI_EFFECTIVENESS_x4, AI_CV_Taunt_Discourage
	if_equal AI_EFFECTIVENESS_x0, AI_CV_Taunt_Encourage
	if_equal AI_EFFECTIVENESS_x0_25, AI_CV_Taunt_Encourage
AI_CV_Taunt_PreventHealing_PreCheck:
	if_hp_more_than AI_TARGET, 72, AI_CV_Taunt_PreventRefresh_PreCheck
	if_has_move_with_effect AI_TARGET, EFFECT_WISH, AI_CV_Taunt_PreventHealing_Wish
	if_hp_more_than AI_TARGET, 63, AI_CV_Taunt_PreventRefresh_PreCheck
	if_has_move_with_effect AI_TARGET, EFFECT_MOONLIGHT, AI_CV_Taunt_PreventHealing
	if_has_move_with_effect AI_TARGET, EFFECT_MORNING_SUN AI_CV_Taunt_PreventHealing
	if_has_move_with_effect AI_TARGET, EFFECT_RESTORE_HP AI_CV_Taunt_PreventHealing
	if_has_move_with_effect AI_TARGET, EFFECT_SOFTBOILED AI_CV_Taunt_PreventHealing
	if_has_move_with_effect AI_TARGET, EFFECT_SWALLOW AI_CV_Taunt_PreventHealing
	if_has_move_with_effect AI_TARGET, EFFECT_SYNTHESIS, AI_CV_Taunt_PreventHealing
	if_hp_more_than AI_TARGET, 55, AI_CV_Taunt_PreventRefresh_PreCheck
	if_has_move_with_effect AI_TARGET, EFFECT_REST, AI_CV_Taunt_PreventHealing
	goto AI_CV_Taunt_PreventRefresh_PreCheck

AI_CV_Taunt_PreventHealing_Wish:
	if_hp_less_than AI_TARGET, 45, AI_CV_Taunt_Encourage
	goto AI_CV_Taunt_PreventHealing_RandomEncourage

AI_CV_Taunt_PreventHealing:
	if_hp_less_than AI_TARGET, 35, AI_CV_Taunt_Encourage
AI_CV_Taunt_PreventHealing_RandomEncourage:
	if_random_less_than 160, AI_CV_Taunt_Encourage
AI_CV_Taunt_PreventRefresh_PreCheck:
	if_status AI_TARGET, STATUS1_BURN | STATUS1_PARALYSIS | STATUS1_POISON | STATUS1_TOXIC_POISON, AI_CV_Taunt_PreventRefresh_PreCheck2
	goto AI_CV_Taunt_CheckTypeEffectiveness2

AI_CV_Taunt_PreventRefresh_PreCheck2:
	if_has_move_with_effect AI_TARGET, EFFECT_HEAL_BELL, AI_CV_Taunt_PreventRefresh
	if_has_move_with_effect AI_TARGET, EFFECT_REFRESH, AI_CV_Taunt_PreventRefresh
	goto AI_CV_Taunt_CheckTypeEffectiveness2

AI_CV_Taunt_PreventRefresh:
	if_hp_less_than AI_TARGET, 30, AI_CV_Taunt_Encourage
	if_random_less_than 128, AI_CV_Taunt_CheckTypeEffectiveness2
	goto AI_CV_Taunt_Encourage

AI_CV_Taunt_CheckTypeEffectiveness2:
	get_highest_type_effectiveness_from_target
	if_equal AI_EFFECTIVENESS_x1, AI_CV_Taunt_Discourage
	if_equal AI_EFFECTIVENESS_x0_5, AI_CV_Taunt_Encourage
AI_CV_Taunt_Discourage:
	score -2
	end

AI_CV_Taunt_Encourage:
	score +2
	end

AI_CV_Torment:
	if_status2 AI_USER, STATUS2_SUBSTITUTE, AI_CV_Torment_Plus1
	if_random_less_than 64, AI_End
	score -1
	end

AI_CV_Torment_Plus1:
	score +1
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
	goto AI_CV_Flail_TargetFaster_CheckCanFaint

AI_CV_Flail_Endure:
	if_holds_item AI_USER, ITEM_SALAC_BERRY, AI_CV_Flail_Minus10
AI_CV_Flail_TargetFaster_CheckCanFaint:
	if_ai_can_faint AI_CV_Flail_Minus1
	if_hp_less_than AI_USER, 33, AI_CV_Flail_Plus1
AI_CV_Flail_Minus1:
	score -1
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
	if_status2 AI_USER, STATUS2_SUBSTITUTE, AI_CV_FocusPunch_Plus2
	get_highest_type_effectiveness_from_target
	if_equal AI_EFFECTIVENESS_x0, AI_CV_FocusPunch_Plus2
	if_any_move_encored AI_TARGET, AI_CV_FocusPunch_MoveLocked
	is_first_turn_for AI_TARGET
	if_equal TRUE, AI_CV_FocusPunch_TypeEffectiveness
	if_holds_item AI_TARGET, ITEM_CHOICE_BAND, AI_CV_FocusPunch_MoveLocked
AI_CV_FocusPunch_TypeEffectiveness:
	get_highest_type_effectiveness_from_target
	if_equal AI_EFFECTIVENESS_x0_25, AI_CV_FocusPunch_Random_Plus1
	if_equal AI_EFFECTIVENESS_x0_5, AI_CV_FocusPunch_Random_Plus1
	goto AI_CV_FocusPunch_StatusCheck

AI_CV_FocusPunch_MoveLocked:
	get_last_used_bank_move AI_TARGET
	get_type_effectiveness_from_result
	if_equal AI_EFFECTIVENESS_x0, AI_CV_FocusPunch_Plus2
AI_CV_FocusPunch_Random_Plus1:
	if_random_less_than 32, AI_CV_FocusPunch_StatusCheck
AI_CV_FocusPunch_Plus1:
	score +1
	goto AI_CV_FocusPunch_StatusCheck

AI_CV_FocusPunch_Plus2:
	score +2
AI_CV_FocusPunch_StatusCheck:
	if_status AI_TARGET, STATUS1_SLEEP | STATUS1_FREEZE, AI_CV_FocusPunch_Status_Plus2
	if_status AI_TARGET, STATUS1_PARALYSIS, AI_CV_FocusPunch_Status_Plus1
	if_status AI_TARGET, STATUS3_YAWN, AI_CV_FocusPunch_Status_Yawned
	goto AI_CV_FocusPunch_Infatuation

AI_CV_FocusPunch_Status_Yawned:
	if_status AI_TARGET, STATUS2_ESCAPE_PREVENTION | STATUS2_WRAPPED, AI_CV_FocusPunch_Infatuation
	if_holds_item AI_TARGET, ITEM_CHESTO_BERRY, AI_CV_FocusPunch_Infatuation
	if_holds_item AI_TARGET, ITEM_LUM_BERRY, AI_CV_FocusPunch_Infatuation
	if_random_less_than 96, AI_CV_FocusPunch_Infatuation
	goto AI_CV_FocusPunch_Status_Plus1

AI_CV_FocusPunch_Status_Plus2:
	score +1
	if_random_less_than 64, AI_CV_FocusPunch_Infatuation
AI_CV_FocusPunch_Status_Plus1:
	score +1
AI_CV_FocusPunch_Infatuation:
	if_status2 AI_TARGET, STATUS2_INFATUATION, AI_CV_FocusPunch_Infatuated_Plus1
	goto AI_CV_FocusPunch_Confusion

AI_CV_FocusPunch_Infatuated_Plus1:
	if_random_less_than 32, AI_CV_FocusPunch_Confusion
	score +1
AI_CV_FocusPunch_Confusion:
	if_status2 AI_TARGET, STATUS2_CONFUSION, AI_CV_FocusPunch_Confused_Plus1
	goto AI_CV_FocusPunch_Random

AI_CV_FocusPunch_Confused_Plus1:
	if_random_less_than 32, AI_CV_FocusPunch_Seeded
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
	goto AI_CV_Thief_Minus8

AI_CV_Thief_CheckTarget:
	get_hold_effect AI_TARGET
	if_not_in_bytes AI_Thief_EncourageItemsToSteal, AI_CV_Thief_Minus8
	if_random_less_than 50, AI_End
	score +1
	end

AI_CV_Thief_Minus8:
	score -8
	end

AI_CV_Trick:
	get_last_used_bank_move AI_USER
	get_move_effect_from_result
	if_equal EFFECT_TRICK, AI_CV_Trick_Minus10
	get_hold_effect AI_USER
	if_in_bytes AI_CV_Trick_EffectsToEncourage, AI_CV_Trick_Encourage
	goto AI_CV_Trick_Minus10

AI_CV_Trick_Encourage:
	get_hold_effect AI_TARGET
	if_in_bytes AI_CV_Trick_EffectsToEncourage, AI_CV_Trick_Minus10
	if_random_less_than 50, AI_End
	score +2
	end

AI_CV_Trick_Minus10:
	score -10
	end

AI_CV_KnockOff:
	if_holds_item AI_TARGET, ITEM_NONE, AI_CV_KnockOff_Minus10
	if_hp_less_than AI_TARGET, 30, AI_CV_KnockOff_Minus2
	if_random_less_than 180, AI_End
	score +1
	end

AI_CV_KnockOff_Minus10:
	score -8
AI_CV_KnockOff_Minus2:
	score -2
	end

AI_CV_Recycle:
	get_used_held_item AI_USER
	if_not_in_bytes AI_CV_Recycle_ItemsToEncourage, AI_CV_Recycle_Minus10
	if_random_less_than 50, AI_End
	score +1
	end

AI_CV_Recycle_Minus10:
	score -10
	end

AI_CV_Protect:
	is_first_turn_for AI_USER
	if_equal TRUE, AI_CV_ProtectCurse
	if_random_less_than 128, AI_CV_ProtectCurse
	score +1
AI_CV_ProtectCurse:
	if_status2 AI_USER, STATUS2_CURSED, AI_CV_Protect_Curse_Minus8
	goto AI_CV_ProtectSeed

AI_CV_Protect_Curse_Minus8:
	score -8
AI_CV_ProtectSeed:
	if_status3 AI_USER, STATUS3_LEECHSEED, AI_CV_Protect_Seeded_Minus8
	goto AI_CV_ProtectInfatuation

AI_CV_Protect_Seeded_Minus8:
	score -8
AI_CV_ProtectInfatuation:
	if_status2 AI_USER, STATUS2_INFATUATION, AI_CV_Protect_Infatuated_Minus1
	goto AI_CV_ProtectStatus

AI_CV_Protect_Infatuated_Minus1:
	score -1
AI_CV_ProtectStatus:
	if_status AI_USER, STATUS1_BURN | STATUS1_PSN_ANY, AI_CV_Protect_BadStatus_Minus8
	if_status3 AI_USER, STATUS3_YAWN, AI_CV_Protect_BadStatus_Minus8
	if_status AI_USER, STATUS1_PARALYSIS, AI_CV_Protect_Paralyzed_Minus1
	goto AI_CV_ProtectTargetStatus

AI_CV_Protect_BadStatus_Minus8:
	score -8
	goto AI_CV_ProtectTargetStatus

AI_CV_Protect_Paralyzed_Minus1:
	score -1
AI_CV_ProtectTargetStatus:
	if_status AI_TARGET, STATUS1_FREEZE | STATUS1_PARALYSIS | STATUS1_SLEEP, AI_CV_Protect_Immobile_Minus10
	if_status2 AI_TARGET, STATUS2_CONFUSION | STATUS2_INFATUATION, AI_CV_Protect_Immobile_Minus2
	goto AI_CV_ProtectTargetStatus2

AI_CV_Protect_Immobile_Minus10:
	score -8
AI_CV_Protect_Immobile_Minus2:
	score -2
AI_CV_ProtectTargetStatus2:
	if_status3 AI_TARGET, STATUS3_YAWN, AI_CV_Protect_TargetStatus2_Plus1
	if_status AI_TARGET, STATUS1_BURN | STATUS1_PSN_ANY, AI_CV_Protect_TargetStatus2_Plus1
	goto AI_CV_Protect_TargetSeeded

AI_CV_Protect_TargetStatus2_Plus1:
	score +1
AI_CV_Protect_TargetSeeded:
	if_status3 AI_TARGET, STATUS3_LEECHSEED, AI_CV_Protect_TargetSeeded_RandomPlus1
	goto AI_CV_Protect_TargetCursed

AI_CV_Protect_TargetSeeded_RandomPlus1:
	if_random_less_than 64, AI_CV_Protect_TargetCursed
	score +1
AI_CV_Protect_TargetCursed:
	if_status2 AI_TARGET, STATUS2_CURSED, AI_CV_Protect_TargetCursed_RandomPlus1
	goto AI_CV_Protect_PunishSemiInv

AI_CV_Protect_TargetCursed_RandomPlus1:
	if_random_less_than 64, AI_CV_Protect_PunishSemiInv
	score +1
AI_CV_Protect_PunishSemiInv:
	if_status3 AI_TARGET, STATUS3_SEMI_INVULNERABLE, AI_CV_Protect_SemiInv_Plus2
	goto AI_CV_Protect_LefoversDisparity

AI_CV_Protect_SemiInv_Plus2:
	score +2
AI_CV_Protect_LefoversDisparity:
	if_holds_item AI_USER, ITEM_LEFTOVERS, AI_CV_Protect_Lefovers_Plus1
	if_holds_item AI_TARGET, ITEM_LEFTOVERS, AI_CV_Protect_Lefovers_Minus1
	goto AI_CV_Protect_PrevMove

AI_CV_Protect_Lefovers_Minus1:
	score -1
	goto AI_CV_Protect_PrevMove

AI_CV_Protect_Lefovers_Plus1:
	score +1
AI_CV_Protect_PrevMove:
	get_last_used_bank_move AI_USER
	get_move_effect_from_result
	if_equal EFFECT_WISH, AI_CV_Protect_Wish_Plus2
	if_equal EFFECT_SUBSTITUTE, AI_CV_Protect_Sub_Plus1
	if_not_equal EFFECT_PROTECT, AI_End
	if_ai_can_faint AI_CV_Protect_AICanFaint
	goto AI_CV_ProtectMulti

AI_CV_Protect_AICanFaint:
	if_user_faster AI_CV_ProtectMulti
	count_usable_party_mons AI_USER
	if_equal 0, AI_CV_Protect_Plus3
	score -10
	end

AI_CV_ProtectMulti:
	get_protect_count AI_USER
	if_equal 1, AI_CV_DoubleProtect_RandomMinus6
	if_random_less_than 8, AI_End
	score -6
	end

AI_CV_Protect_Plus3:
	score +3
	end

AI_CV_Protect_Wish_Plus2:
	score +2
	end

AI_CV_Protect_Sub_Plus1:
	score +1
	end

AI_CV_DoubleProtect_RandomMinus6:
	if_random_less_than 96, AI_End
	score -6
	end

AI_CV_Endure:
	if_ai_can_faint AI_CV_Endure_TwoTurn
	score -10
	end

AI_CV_Endure_TwoTurn:
	if_status3 AI_TARGET, STATUS3_SEMI_INVULNERABLE, AI_CV_Endure_Plus10
	if_status2 AI_TARGET, STATUS2_MULTIPLETURNS, AI_CV_Endure_TwoTurn_CheckEffect
	goto AI_CV_Endure_UtilityCheck

AI_CV_Endure_TwoTurn_CheckEffect:
	if_has_move_with_effect AI_TARGET, EFFECT_RAZOR_WIND, AI_CV_Endure_Plus10
	if_has_move_with_effect AI_TARGET, EFFECT_SKULL_BASH, AI_CV_Endure_Plus10
	if_has_move_with_effect AI_TARGET, EFFECT_SOLAR_BEAM, AI_CV_Endure_Plus10
	if_has_move_with_effect AI_TARGET, EFFECT_SKY_ATTACK, AI_CV_Endure_Plus10
AI_CV_Endure_UtilityCheck:
	if_status AI_USER, STATUS1_BURN | STATUS1_PSN_ANY, AI_CV_Endure_DontUse
	get_weather
	if_status2 AI_USER, STATUS2_CURSED | STATUS2_SUBSTITUTE, AI_CV_Endure_DontUse
	if_status3 AI_USER, STATUS3_LEECHSEED | STATUS3_YAWN, AI_CV_Endure_DontUse
	if_equal AI_WEATHER_HAIL, AI_CV_Endure_UtilityCheck_Hail
	if_equal AI_WEATHER_SANDSTORM, AI_CV_Endure_UtilityCheck_Sand
	goto AI_CV_Endure_UtilityCheck_MoveItemCheck

AI_CV_Endure_UtilityCheck_Hail:
	get_user_type1
	if_equal TYPE_ICE, AI_CV_Endure_UtilityCheck_MoveItemCheck
	get_user_type2
	if_equal TYPE_ICE, AI_CV_Endure_UtilityCheck_MoveItemCheck
	goto AI_CV_Endure_DontUse

AI_CV_Endure_UtilityCheck_Sand:
	get_user_type1
	if_in_bytes AI_CV_SandstormResistantTypes, AI_CV_Endure_UtilityCheck_MoveItemCheck
	get_user_type2
	if_in_bytes AI_CV_SandstormResistantTypes, AI_CV_Endure_UtilityCheck_MoveItemCheck
	goto AI_CV_Endure_DontUse

AI_CV_Endure_UtilityCheck_MoveItemCheck:
	if_hp_less_than AI_USER, 4, AI_CV_Endure_DontUse
	if_has_move_with_effect AI_USER, EFFECT_ENDEAVOR, AI_CV_Endure_Useful
	if_has_move_with_effect AI_USER, EFFECT_FLAIL, AI_CV_Endure_Useful
	if_hp_less_than AI_USER, 25, AI_CV_Endure_DontUse
	get_hold_effect AI_USER
	if_in_bytes AI_CV_Endure_PinchBerries, AI_CV_Endure_Useful
	if_target_faster AI_CV_Endure_UtilityCheck_Salac
	goto AI_CV_Endure_UtilityCheck_AbilityCheck

AI_CV_Endure_UtilityCheck_Salac:
	if_holds_item AI_USER, ITEM_SALAC_BERRY, AI_CV_Endure_Useful
AI_CV_Endure_UtilityCheck_AbilityCheck:
	if_hp_less_than AI_USER, 33, AI_CV_Endure_DontUse
	if_ability AI_USER, ABILITY_BLAZE, AI_CV_Endure_Blaze
	if_ability AI_USER, ABILITY_OVERGROW, AI_CV_Endure_Overgrow
	if_ability AI_USER, ABILITY_SWARM, AI_CV_Endure_Swarm
	if_ability AI_USER, ABILITY_TORRENT, AI_CV_Endure_Torrent
	goto AI_CV_Endure_DontUse

AI_CV_Endure_Blaze:
	if_has_attack_of_type AI_USER, TYPE_FIRE, AI_CV_Endure_Useful
	goto AI_CV_Endure_DontUse

AI_CV_Endure_Overgrow:
	if_has_attack_of_type AI_USER, TYPE_GRASS, AI_CV_Endure_Useful
	goto AI_CV_Endure_DontUse

AI_CV_Endure_Swarm:
	if_has_attack_of_type AI_USER, TYPE_BUG, AI_CV_Endure_Useful
	goto AI_CV_Endure_DontUse

AI_CV_Endure_Torrent:
	if_has_attack_of_type AI_USER, TYPE_WATER, AI_CV_Endure_Useful
	goto AI_CV_Endure_DontUse

AI_CV_Endure_Useful:
	if_target_taunted AI_CV_Endure_Plus10
	if_status2 AI_TARGET, STATUS2_MULTIPLETURNS, AI_CV_Endure_TwoTurn_CheckEffect2
	goto AI_CV_Endure_Useful_CheckRepeatUse

AI_CV_Endure_TwoTurn_CheckEffect2:
	get_last_used_bank_move AI_TARGET
	get_move_effect_from_result
	if_in_bytes AI_CV_LockedIn_EffList, AI_CV_Endure_Plus10
AI_CV_Endure_Useful_CheckRepeatUse:
	get_last_used_bank_move AI_USER
	get_move_effect_from_result
	if_equal EFFECT_ENDURE, AI_CV_Endure_RepeatUse
	goto AI_CV_Endure_Useful_CheckBurn

AI_CV_Endure_RepeatUse:
	if_random_less_than 192, AI_CV_Endure_DontUse
AI_CV_Endure_Useful_CheckBurn:
	if_ability AI_USER, ABILITY_WATER_VEIL, AI_CV_Endure_Useful_CheckPsn
	get_user_type1
	if_equal TYPE_FIRE, AI_CV_Endure_Useful_CheckPsn
	get_user_type2
	if_equal TYPE_FIRE, AI_CV_Endure_Useful_CheckPsn
	if_has_move_with_effect AI_TARGET, EFFECT_WILL_O_WISP, AI_CV_Endure_DontUse_HighOdds
AI_CV_Endure_Useful_CheckPsn:
	if_ability AI_USER, ABILITY_IMMUNITY, AI_CV_Endure_Useful_CheckPara
	get_user_type1
	if_in_bytes AI_PoisoningImmune, AI_CV_Endure_Useful_CheckPara
	get_user_type2
	if_in_bytes AI_PoisoningImmune, AI_CV_Endure_Useful_CheckPara
	if_has_move_with_effect AI_TARGET, EFFECT_POISON, AI_CV_Endure_DontUse_HighOdds
	if_has_move_with_effect AI_TARGET, EFFECT_TOXIC, AI_CV_Endure_DontUse_HighOdds
AI_CV_Endure_Useful_CheckPara:
	if_ability AI_USER, ABILITY_LIMBER, AI_CV_Endure_Useful_CheckSeed
	get_user_type1
	if_equal TYPE_GROUND, AI_CV_Endure_Useful_CheckGlare
	get_user_type2
	if_equal TYPE_GROUND, AI_CV_Endure_Useful_CheckGlare
	if_has_move AI_TARGET, MOVE_THUNDER_WAVE, AI_CV_Endure_DontUse_HighOdds
	if_ability AI_USER, ABILITY_SHIELD_DUST, AI_CV_Endure_Useful_CheckGlare
	if_has_move AI_TARGET, MOVE_ZAP_CANNON, AI_CV_Endure_DontUse_HighOdds
AI_CV_Endure_Useful_CheckGlare:
	get_user_type1
	if_equal TYPE_GHOST, AI_CV_Endure_Useful_CheckSeed
	get_user_type2
	if_equal TYPE_GHOST, AI_CV_Endure_Useful_CheckSeed
	if_has_move AI_TARGET, MOVE_GLARE, AI_CV_Endure_DontUse_HighOdds
AI_CV_Endure_Useful_CheckSeed:
	get_user_type1
	if_equal TYPE_GRASS, AI_CV_Endure_Useful_CheckSleep
	get_user_type2
	if_equal TYPE_GRASS, AI_CV_Endure_Useful_CheckSleep
	if_has_move_with_effect AI_TARGET, EFFECT_LEECH_SEED, AI_CV_Endure_DontUse_HighOdds
AI_CV_Endure_Useful_CheckSleep:
	if_ability AI_USER, ABILITY_INSOMNIA, AI_CV_Endure_Useful_CheckConfusion
	if_ability AI_USER, ABILITY_VITAL_SPIRIT, AI_CV_Endure_Useful_CheckConfusion
	if_has_move_with_effect AI_TARGET, EFFECT_SLEEP, AI_CV_Endure_DontUse_HighOdds
	if_has_move_with_effect AI_TARGET, EFFECT_YAWN, AI_CV_Endure_DontUse_HighOdds
AI_CV_Endure_Useful_CheckSpeed:
	if_target_faster AI_CV_Endure_Useful_CheckConfusion
	if_has_move_with_effect AI_TARGET, EFFECT_DRAGON_DANCE, AI_CV_Endure_DontUse_HighOdds
	if_has_move_with_effect AI_TARGET, EFFECT_SPEED_UP, AI_CV_Endure_DontUse_HighOdds
	if_has_move_with_effect AI_TARGET, EFFECT_SPEED_UP_2, AI_CV_Endure_DontUse_HighOdds
	if_ability AI_USER, ABILITY_CLEAR_BODY, AI_CV_Endure_Useful_CheckConfusion
	if_ability AI_USER, ABILITY_WHITE_SMOKE, AI_CV_Endure_Useful_CheckConfusion
	if_has_move_with_effect AI_TARGET, EFFECT_SPEED_DOWN, AI_CV_Endure_DontUse_HighOdds
	if_has_move_with_effect AI_TARGET, EFFECT_SPEED_DOWN_2, AI_CV_Endure_DontUse_HighOdds
AI_CV_Endure_Useful_CheckConfusion:
	if_ability AI_USER, ABILITY_OWN_TEMPO, AI_CV_Endure_Useful_CheckGhost_Para_LowOdds
	if_status2 AI_USER, STATUS2_CONFUSION, AI_CV_Endure_Useful_CheckShieldDust
	if_has_move_with_effect AI_TARGET, EFFECT_CONFUSE, AI_CV_Endure_DontUse_HighOdds
	if_has_move_with_effect AI_TARGET, EFFECT_FLATTER, AI_CV_Endure_DontUse_HighOdds
	if_has_move_with_effect AI_TARGET, EFFECT_SWAGGER, AI_CV_Endure_DontUse_HighOdds
	if_has_move_with_effect AI_TARGET, EFFECT_TEETER_DANCE, AI_CV_Endure_DontUse_HighOdds
AI_CV_Endure_Useful_CheckShieldDust:
	if_ability AI_USER, ABILITY_SHIELD_DUST, AI_CV_Endure_Useful_CheckSubstitute
AI_CV_Endure_Useful_CheckSignalBeam:
	if_status2 AI_USER, STATUS2_CONFUSION, AI_CV_Endure_Useful_CheckGhost_Para_LowOdds
	if_has_move AI_TARGET, MOVE_SIGNAL_BEAM, AI_CV_Endure_DontUse_LowOdds
AI_CV_Endure_Useful_CheckWaterPulse:
	if_ability AI_USER, ABILITY_WATER_ABSORB, AI_CV_Endure_Useful_CheckConfusion_DarkCheck
	if_has_move AI_TARGET, MOVE_WATER_PULSE, AI_CV_Endure_DontUse_LowOdds
AI_CV_Endure_Useful_CheckConfusion_DarkCheck:
	get_user_type1
	if_equal TYPE_DARK, AI_CV_Endure_Useful_CheckGhost_Confusion_LowOdds
	get_user_type2
	if_equal TYPE_DARK, AI_CV_Endure_Useful_CheckGhost_Confusion_LowOdds
	if_has_move AI_TARGET, MOVE_CONFUSION, AI_CV_Endure_DontUse_LowOdds
	if_has_move AI_TARGET, MOVE_PSYBEAM, AI_CV_Endure_DontUse_LowOdds
AI_CV_Endure_Useful_CheckGhost_Confusion_LowOdds:
	get_user_type1
	if_equal TYPE_GHOST, AI_CV_Endure_Useful_CheckGround_LowOdds
	get_user_type2
	if_equal TYPE_GHOST, AI_CV_Endure_Useful_CheckGround_LowOdds
	if_has_move AI_TARGET, MOVE_DIZZY_PUNCH, AI_CV_Endure_DontUse_LowOdds
	if_has_move AI_TARGET, MOVE_DYNAMIC_PUNCH, AI_CV_Endure_DontUse_LowOdds
	goto AI_CV_Endure_Useful_CheckBodySlamAndSecretPower

AI_CV_Endure_Useful_CheckGhost_Para_LowOdds:
	if_ability AI_USER, ABILITY_LIMBER, AI_CV_Endure_Useful_CheckBurn_LowOdds
	get_user_type1
	if_equal TYPE_GHOST, AI_CV_Endure_Useful_CheckGround_LowOdds
	get_user_type2
	if_equal TYPE_GHOST, AI_CV_Endure_Useful_CheckGround_LowOdds
AI_CV_Endure_Useful_CheckBodySlamAndSecretPower:
	if_has_move AI_TARGET, MOVE_BODY_SLAM, AI_CV_Endure_DontUse_LowOdds
	if_has_move AI_TARGET, MOVE_SECRET_POWER, AI_CV_Endure_DontUse_LowOdds
	if_has_move AI_TARGET, MOVE_TRI_ATTACK, AI_CV_Endure_DontUse_LowOdds
AI_CV_Endure_Useful_CheckGround_LowOdds:
	get_user_type1
	if_equal TYPE_GROUND, AI_CV_Endure_Useful_CheckLick
	get_user_type2
	if_equal TYPE_GROUND, AI_CV_Endure_Useful_CheckLick
	if_has_move AI_TARGET, MOVE_SPARK, AI_CV_Endure_DontUse_LowOdds
	if_has_move AI_TARGET, MOVE_THUNDER, AI_CV_Endure_DontUse_LowOdds
	if_has_move AI_TARGET, MOVE_THUNDERBOLT, AI_CV_Endure_DontUse_LowOdds
	if_has_move AI_TARGET, MOVE_THUNDER_PUNCH, AI_CV_Endure_DontUse_LowOdds
	if_has_move AI_TARGET, MOVE_THUNDER_SHOCK, AI_CV_Endure_DontUse_LowOdds
AI_CV_Endure_Useful_CheckLick:
	get_user_type1
	if_equal TYPE_NORMAL, AI_CV_Endure_Useful_CheckDBreath
	get_user_type2
	if_equal TYPE_NORMAL, AI_CV_Endure_Useful_CheckDBreath
	if_has_move AI_TARGET, MOVE_LICK, AI_CV_Endure_DontUse_LowOdds
AI_CV_Endure_Useful_CheckDBreath:
	if_has_move AI_TARGET, MOVE_DRAGON_BREATH, AI_CV_Endure_DontUse_LowOdds
AI_CV_Endure_Useful_CheckBurn_LowOdds:
	if_ability AI_USER, ABILITY_FLASH_FIRE, AI_CV_Endure_Useful_CheckPsn_LowOdds
	if_ability AI_USER, ABILITY_WATER_VEIL, AI_CV_Endure_Useful_CheckPsn_LowOdds
	get_user_type1
	if_equal TYPE_FIRE, AI_CV_Endure_Useful_CheckPsn_LowOdds
	get_user_type2
	if_equal TYPE_FIRE, AI_CV_Endure_Useful_CheckPsn_LowOdds
	if_has_move_with_effect AI_TARGET, EFFECT_BURN_HIT, AI_CV_Endure_DontUse_LowOdds
	if_has_move AI_TARGET, MOVE_SACRED_FIRE, AI_CV_Endure_DontUse_LowOdds
AI_CV_Endure_Useful_CheckPsn_LowOdds:
	if_ability AI_USER, ABILITY_IMMUNITY, AI_CV_Endure_Useful_CheckSpeed_LowOdds
	get_user_type1
	if_in_bytes AI_PoisoningImmune, AI_CV_Endure_Useful_CheckSpeed_LowOdds
	get_user_type2
	if_in_bytes AI_PoisoningImmune, AI_CV_Endure_Useful_CheckSpeed_LowOdds
	if_has_move_with_effect AI_TARGET, EFFECT_POISON_FANG, AI_CV_Endure_DontUse_LowOdds
	if_has_move_with_effect AI_TARGET, EFFECT_POISON_HIT, AI_CV_Endure_DontUse_LowOdds
	if_has_move_with_effect AI_TARGET, EFFECT_POISON_TAIL, AI_CV_Endure_DontUse_LowOdds
	if_has_move_with_effect AI_TARGET, EFFECT_TWINEEDLE, AI_CV_Endure_DontUse_LowOdds
AI_CV_Endure_Useful_CheckSpeed_LowOdds:
	if_target_faster AI_CV_Endure_Useful_CheckFrz
	if_ability AI_USER, ABILITY_CLEAR_BODY, AI_CV_Endure_Useful_CheckFrz
	if_ability AI_USER, ABILITY_WHITE_SMOKE, AI_CV_Endure_Useful_CheckFrz
	if_has_move_with_effect AI_TARGET, EFFECT_SPEED_DOWN_HIT, AI_CV_Endure_DontUse_LowOdds
AI_CV_Endure_Useful_CheckFrz:
	get_user_type1
	if_equal TYPE_ICE, AI_CV_Endure_Useful_CheckSubstitute
	get_user_type2
	if_equal TYPE_ICE, AI_CV_Endure_Useful_CheckSubstitute
	if_has_move_with_effect AI_TARGET, EFFECT_FREEZE_HIT, AI_CV_Endure_DontUse_VeryLowOdds
	goto AI_CV_Endure_Useful_CheckSubstitute

AI_CV_Endure_DontUse_VeryLowOdds:
	if_random_less_than 96, AI_CV_Endure_Useful_CheckSubstitute
AI_CV_Endure_DontUse_LowOdds:
	if_random_less_than 192, AI_CV_Endure_Useful_CheckSubstitute
AI_CV_Endure_DontUse_HighOdds:
	if_random_less_than 208, AI_CV_Endure_DontUse
AI_CV_Endure_Useful_CheckSubstitute:
	if_has_move_with_effect AI_TARGET, EFFECT_SUBSTITUTE, AI_CV_Endure_Useful_Substitute
	if_random_less_than 16, AI_CV_Endure_DontUse
	goto AI_CV_Endure_Plus10

AI_CV_Endure_Useful_Substitute:
	if_random_less_than 196, AI_CV_Endure_DontUse
AI_CV_Endure_Plus10:
	score +10
	end

AI_CV_Endure_DontUse:
	score -10
	end

AI_CV_BatonPass:
	if_status3 AI_USER, STATUS3_LEECHSEED, AI_CV_BatonPass_Minus7
	if_status2 AI_USER, STATUS2_SUBSTITUTE, AI_CV_BatonPass_Plus1
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
AI_CV_BatonPass_Plus1:
	score +1
	end

AI_CV_BatonPass_Minus7:
	score -7
	end

AI_CV_RainDance:
	if_has_move_with_effect AI_USER, EFFECT_THUNDER, AI_CV_RainDance_Thunder_Plus1
	goto AI_CV_RainDance_Thunder_Target

AI_CV_RainDance_Thunder_Plus1:
	score +1
AI_CV_RainDance_Thunder_Target:
	if_has_move_with_effect AI_TARGET, EFFECT_THUNDER, AI_CV_RainDance_TargetHasThunder
	goto AI_CV_RainDance_CheckTargetFire

AI_CV_RainDance_TargetHasThunder:
	get_ability AI_USER
	if_equal ABILITY_VOLT_ABSORB, AI_CV_RainDance_CheckTargetFire
	get_user_type1
	if_equal TYPE_GROUND, AI_CV_RainDance_CheckTargetFire
	get_user_type2
	if_equal TYPE_GROUND, AI_CV_RainDance_CheckTargetFire
	score -5
AI_CV_RainDance_CheckTargetFire:
	if_has_attack_of_type AI_TARGET, TYPE_FIRE, AI_CV_RainDance_WeakenFire
	goto AI_CV_RainDance_CheckUserWater

AI_CV_RainDance_WeakenFire:
	score +1
AI_CV_RainDance_CheckUserWater:
	if_has_attack_of_type AI_USER, TYPE_WATER, AI_CV_RainDance_PowerUpWater
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
	if_not_equal ABILITY_SWIFT_SWIM, AI_CV_RainDance_CheckRainDish_Target
	if_target_faster AI_CV_RainDance_WeatherCheck
	score -1
	goto AI_CV_RainDance_WeatherCheck

AI_CV_RainDance_CheckRainDish_Target:
	get_ability AI_TARGET
	if_not_equal ABILITY_RAIN_DISH, AI_CV_RainDance_WeatherCheck
	score -1
AI_CV_RainDance_WeatherCheck:
	get_weather
	if_equal AI_WEATHER_HAIL | AI_WEATHER_SANDSTORM | AI_WEATHER_SUN, AI_CV_ReplaceWeather
	goto AI_CV_Weather_LowHP_Check

AI_CV_SunnyDay:
	if_has_move_with_effect AI_USER, EFFECT_MOONLIGHT, AI_CV_SunnyDay_MoveFound
	if_has_move_with_effect AI_USER, EFFECT_MORNING_SUN, AI_CV_SunnyDay_MoveFound
	if_has_move_with_effect AI_USER, EFFECT_SOLAR_BEAM, AI_CV_SunnyDay_MoveFound
	if_has_move_with_effect AI_USER, EFFECT_SYNTHESIS, AI_CV_SunnyDay_MoveFound
	goto AI_CV_SunnyDay_CheckUserFireWeak

AI_CV_SunnyDay_MoveFound:
	score +1
AI_CV_SunnyDay_CheckUserFireWeak:
	get_user_type1
	if_in_bytes AI_CV_FireWeak, AI_CV_SunnyDay_CheckTargetFire
	get_user_type2
	if_in_bytes AI_CV_FireWeak, AI_CV_SunnyDay_CheckTargetFire
	goto AI_CV_SunnyDay_CheckTargetWater

AI_CV_SunnyDay_CheckTargetFire:
	if_has_attack_of_type AI_TARGET, TYPE_FIRE, AI_CV_SunnyDay_CheckTargetStatus
	goto AI_CV_SunnyDay_CheckTargetWater

AI_CV_SunnyDay_CheckTargetStatus:
	if_status AI_TARGET, STATUS1_SLEEP | STATUS1_FREEZE, AI_CV_SunnyDay_CheckTargetWater
	if_status2 AI_USER, STATUS2_SUBSTITUTE, AI_CV_SunnyDay_CheckTargetWater
	score -5
AI_CV_SunnyDay_CheckTargetWater:
	if_has_attack_of_type AI_TARGET, TYPE_WATER, AI_CV_SunnyDay_WeakenWater
	if_has_move AI_TARGET, MOVE_THUNDER, AI_CV_SunnyDay_Thunder
	goto AI_CV_SunnyDay_CheckUserFire

AI_CV_SunnyDay_Thunder:
	get_user_type1
	if_equal TYPE_GROUND, AI_CV_SunnyDay_CheckUserFire
	get_user_type2
	if_equal TYPE_GROUND, AI_CV_SunnyDay_CheckUserFire
AI_CV_SunnyDay_WeakenWater:
	score +1
AI_CV_SunnyDay_CheckUserFire:
	if_has_attack_of_type AI_USER, TYPE_FIRE, AI_CV_SunnyDay_BoostFire
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
	if_equal AI_WEATHER_HAIL | AI_WEATHER_RAIN | AI_WEATHER_SANDSTORM, AI_CV_ReplaceWeather
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
	if_equal AI_WEATHER_HAIL | AI_WEATHER_RAIN | AI_WEATHER_SUN, AI_CV_ReplaceWeather
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
	if_equal AI_WEATHER_RAIN | AI_WEATHER_SANDSTORM | AI_WEATHER_SUN, AI_CV_ReplaceWeather
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
	goto AI_CV_CloudNineCheck

AI_CV_Forecast_Found:
	score +1
AI_CV_CloudNineCheck:
	get_ability AI_TARGET
	if_equal ABILITY_AIR_LOCK, AI_CV_WeatherImmune
	if_equal ABILITY_CLOUD_NINE, AI_CV_WeatherImmune
	get_ability AI_USER
	if_equal ABILITY_AIR_LOCK, AI_CV_WeatherImmune
	if_equal ABILITY_CLOUD_NINE, AI_CV_WeatherImmune
	end

AI_CV_WeatherImmune:
	score -2
	end

AI_CV_Counter:
	if_has_attack_of_category AI_TARGET, TYPE_PHYSICAL, AI_CV_Counter_SemiInvCheck
	if_has_move AI_TARGET, MOVE_HIDDEN_POWER, AI_CV_Counter_SemiInvCheck
	if_has_move_with_effect AI_TARGET, EFFECT_ENDEAVOR, AI_CV_Counter_SemiInvCheck
	if_has_move_with_effect AI_TARGET, EFFECT_LEVEL_DAMAGE, AI_CV_Counter_SemiInvCheck
	if_has_move_with_effect AI_TARGET, EFFECT_SONICBOOM, AI_CV_Counter_SemiInvCheck
	if_has_move_with_effect AI_TARGET, EFFECT_SUPER_FANG, AI_CV_Counter_SemiInvCheck
	goto AI_CV_CounterCoat_Useless

AI_CV_MirrorCoat:
	if_has_attack_of_category AI_TARGET, TYPE_SPECIAL, AI_CV_Counter_SemiInvCheck
	if_has_move_with_effect AI_TARGET, EFFECT_DRAGON_RAGE, AI_CV_Counter_SemiInvCheck
	if_has_move_with_effect AI_TARGET, EFFECT_PSYWAVE, AI_CV_Counter_SemiInvCheck
AI_CV_CounterCoat_Useless:
	score -10
	end

AI_CV_Counter_SemiInvCheck:
	if_status3 AI_TARGET, STATUS3_ON_AIR | STATUS3_UNDERGROUND, AI_CV_CounterCoat_Plus2
	if_status2 AI_TARGET, STATUS2_MULTIPLETURNS, AI_CV_Counter_Charging
	goto AI_CV_CounterCoat_FaintCheck_TauntCheck

AI_CV_MirrorCoat_SemiInvCheck:
	if_status3 AI_TARGET, STATUS3_UNDERWATER, AI_CV_CounterCoat_Plus2
	if_status2 AI_TARGET, STATUS2_MULTIPLETURNS, AI_CV_MirrorCoat_Charging
	goto AI_CV_CounterCoat_FaintCheck_TauntCheck

AI_CV_Counter_Charging:
	get_last_used_bank_move AI_TARGET
	get_move_effect_from_result
	if_equal EFFECT_RAMPAGE, AI_CV_CounterCoat_Plus2
	if_equal EFFECT_ROLLOUT, AI_CV_CounterCoat_Plus2
	if_has_move_with_effect AI_TARGET, EFFECT_RAZOR_WIND, AI_CV_CounterCoat_Plus2
	if_has_move_with_effect AI_TARGET, EFFECT_SKULL_BASH, AI_CV_CounterCoat_Plus2
	if_has_move_with_effect AI_TARGET, EFFECT_SKY_ATTACK, AI_CV_CounterCoat_Plus2
	if_has_move_with_effect AI_TARGET, EFFECT_UPROAR, AI_CV_CounterCoat_Plus2
	goto AI_CV_CounterCoat_FaintCheck_TauntCheck

AI_CV_MirrorCoat_Charging:
	get_last_used_bank_move AI_TARGET
	get_move_effect_from_result
	if_equal EFFECT_RAMPAGE, AI_CV_CounterCoat_Plus2
	if_equal EFFECT_ROLLOUT, AI_CV_CounterCoat_Plus2
	if_has_move_with_effect AI_TARGET, EFFECT_SOLAR_BEAM, AI_CV_CounterCoat_Plus2
	goto AI_CV_CounterCoat_FaintCheck_TauntCheck

AI_CV_CounterCoat_Plus2:
	score +2
AI_CV_CounterCoat_FaintCheck_TauntCheck:
	if_ai_can_faint AI_CV_CounterCoat_Minus10
	if_target_taunted AI_CV_CounterCoat_Taunted_Plus1
	goto AI_CV_CounterCoat_StatusCheck

AI_CV_CounterCoat_Taunted_Plus1:
	if_random_less_than 64, AI_CV_CounterCoat_StatusCheck
	score +1
AI_CV_CounterCoat_StatusCheck:
	if_status AI_TARGET, STATUS1_FREEZE | STATUS1_PARALYSIS | STATUS1_SLEEP, AI_CV_CounterCoat_Status_Minus1
	goto AI_CV_CounterCoat_Confusion

AI_CV_CounterCoat_Status_Minus1:
	score -1
AI_CV_CounterCoat_Confusion:
	if_status2 AI_TARGET, STATUS2_CONFUSION, AI_CV_CounterCoat_Confused_Minus1
	goto AI_CV_CounterCoat_Infatuation

AI_CV_CounterCoat_Confused_Minus1:
	score -1
AI_CV_CounterCoat_Infatuation:
	if_status2 AI_TARGET, STATUS2_INFATUATION, AI_CV_CounterCoat_Infatuated_Minus1
	goto AI_CV_HP_Check

AI_CV_CounterCoat_Infatuated_Minus1:
	score -1
AI_CV_HP_Check:
	if_hp_less_than AI_USER, 40, AI_CV_CounterCoat_LowHP_Minus1
	if_hp_less_than AI_USER, 70, AI_CV_CounterCoat_MidHP_RandomMinus1
	goto AI_CV_CounterCoat_RandDown

AI_CV_CounterCoat_LowHP_Minus1:
	score -1
AI_CV_CounterCoat_MidHP_RandomMinus1:
	if_random_less_than 160, AI_CV_CounterCoat_RandDown
	score -1
AI_CV_CounterCoat_RandDown:
	if_random_less_than 160, AI_End
	score -1
	end

AI_CV_CounterCoat_Minus10:
	score -10
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
	if_target_faster AI_CV_Recharge_TargetFaster
	if_hp_less_than AI_USER, 30, AI_End
	goto AI_CV_Recharge_Minus5

AI_CV_Recharge_TargetFaster:
	if_hp_less_than AI_USER, 50, AI_End
AI_CV_Recharge_Minus5:
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
	score -6
AI_CV_SemiInvulnerable_CheckTargetSeeded:
	if_status3 AI_TARGET, STATUS3_LEECHSEED, AI_CV_SemiInvulnerable_TargetSeeded
	goto AI_CV_SemiInvulnerable_CheckUserSeeded

AI_CV_SemiInvulnerable_TargetSeeded:
	score +1
AI_CV_SemiInvulnerable_CheckUserSeeded:
	if_status3 AI_USER, STATUS3_LEECHSEED, AI_CV_SemiInvulnerable_UserSeeded
	goto AI_CV_SemiInvulnerable_CheckTargetStatused

AI_CV_SemiInvulnerable_UserSeeded:
	score -6
AI_CV_SemiInvulnerable_CheckTargetStatused:
	if_status AI_TARGET, STATUS1_BURN | STATUS1_PSN_ANY, AI_CV_SemiInvulnerable_TargetStatused
	if_status3 AI_TARGET, STATUS3_YAWN, AI_CV_SemiInvulnerable_TargetStatused
	goto AI_CV_SemiInvulnerable_CheckUserStatused

AI_CV_SemiInvulnerable_TargetStatused:
	score +1
AI_CV_SemiInvulnerable_CheckUserStatused:
	if_status AI_USER, STATUS1_BURN | STATUS1_PSN_ANY, AI_CV_SemiInvulnerable_UserStatused
	if_status3 AI_USER, STATUS3_YAWN, AI_CV_SemiInvulnerable_UserStatused
	goto AI_CV_SemiInvulnerable_CheckUserConfused

AI_CV_SemiInvulnerable_UserStatused:
	score -6
AI_CV_SemiInvulnerable_CheckUserConfused:
	if_status2 AI_USER, STATUS2_CONFUSION, AI_CV_SemiInvulnerable_UserConfused
	goto AI_CV_SemiInvulnerable_CheckProtect

AI_CV_SemiInvulnerable_UserConfused:
	score -1
AI_CV_SemiInvulnerable_CheckProtect:
	if_doesnt_have_move_with_effect AI_TARGET, EFFECT_PROTECT, AI_End
	score -5
	end

AI_CV_SpitUp:
	get_stockpile_count AI_USER
	if_less_than 2, AI_CV_SpitUp_Minus2
	if_less_than 3, AI_CV_SpitUp_HPCheck
	goto AI_CV_SpitUp_Plus1

AI_CV_SpitUp_HPCheck:
	if_hp_less_than AI_USER, 50, AI_CV_SpitUp_Plus1
AI_CV_SpitUp_Minus2:
	score -2
	end

AI_CV_SpitUp_Plus1:
	score +1
	end

AI_CV_SmellingSalt:
	if_status AI_TARGET, STATUS1_PARALYSIS, AI_CV_SmellingSalt_Plus1
	end

AI_CV_SmellingSalt_Plus1:
	score +1
	end

AI_CV_FakeOut:
	if_ability AI_TARGET, ABILITY_INNER_FOCUS, AI_CV_FakeOut_End
	if_ability AI_TARGET, ABILITY_SHIELD_DUST, AI_CV_FakeOut_End
	score +2
AI_CV_FakeOut_End:
	end

AI_CV_Superpower:
	if_stat_level_less_than AI_USER, STAT_ATK, DEFAULT_STAT_STAGE, AI_CV_Superpower_Minus1
	end

AI_CV_Superpower_Minus1:
	score -1
	if_stat_level_less_than AI_USER, STAT_ATK, 5, AI_CV_Superpower_Minus10
	end

AI_CV_Superpower_Minus10:
	score -9
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
	if_hp_less_than AI_USER, 60, AI_CV_Eruption_Minus10
	if_target_faster AI_CV_Eruption_TypeMatchup
	if_hp_less_than AI_USER, 75, AI_CV_Eruption_Minus1
	score +1
	end

AI_CV_Eruption_TypeMatchup:
	get_highest_type_effectiveness_from_target
	if_equal AI_EFFECTIVENESS_x1, AI_CV_Eruption_Minus10
	if_equal AI_EFFECTIVENESS_x2, AI_CV_Eruption_Minus10
	if_equal AI_EFFECTIVENESS_x4, AI_CV_Eruption_Minus10
AI_CV_Eruption_CheckHP:
	if_hp_more_than AI_USER, 90, AI_CV_Eruption_Random
	score -1
AI_CV_Eruption_Random:
	if_random_less_than 128, AI_End
AI_CV_Eruption_Minus1:
	score -1
	end

AI_CV_Eruption_Minus10:
	score -10
	end

AI_CV_Overheat:
	if_holds_item AI_USER, ITEM_WHITE_HERB, AI_End
	get_curr_move_type
	if_equal TYPE_FIRE, AI_CV_CheckOverheat
	if_equal TYPE_PSYCHIC, AI_CV_CheckPsychoBoost
	end

AI_CV_CheckOverheat:
	if_has_move AI_USER, MOVE_BLAZE_KICK, AI_CV_Overheat_Discourage
	if_has_move AI_USER, MOVE_FIRE_BLAST, AI_CV_Overheat_Discourage
	if_has_move AI_USER, MOVE_FIRE_PUNCH, AI_CV_Overheat_Discourage
	if_has_move AI_USER, MOVE_FLAMETHROWER, AI_CV_Overheat_Discourage
	if_has_move AI_USER, MOVE_HEAT_WAVE, AI_CV_Overheat_Discourage
	if_has_move AI_USER, MOVE_SACRED_FIRE, AI_CV_Overheat_Discourage
	if_hp_more_than AI_USER, 50, AI_End
	if_has_move AI_USER, MOVE_ERUPTION, AI_CV_Overheat_Discourage
	end

AI_CV_CheckPsychoBoost:
	if_has_move AI_USER, MOVE_EXTRASENSORY, AI_CV_Overheat_Discourage
	if_has_move AI_USER, MOVE_LUSTER_PURGE, AI_CV_Overheat_Discourage
	if_has_move AI_USER, MOVE_MIST_BALL, AI_CV_Overheat_Discourage
	if_has_move AI_USER, MOVE_PSYBEAM, AI_CV_Overheat_Discourage
	if_has_move AI_USER, MOVE_PSYCHIC, AI_CV_Overheat_Discourage
	end

AI_CV_Overheat_Discourage:
	score -2
	end

AI_CV_MagicCoat:
	score -1
	if_ai_can_faint AI_CV_MagicCoat_CanFaint
	goto AI_CV_MagicCoat_SpeedLowering_PreCheck

AI_CV_MagicCoat_CanFaint:
	if_random_less_than 16, AI_CV_MagicCoat_SpeedLowering_PreCheck
	score -10
AI_CV_MagicCoat_SpeedLowering_PreCheck:
	if_has_move_with_effect AI_TARGET, EFFECT_SPEED_DOWN, AI_CV_MagicCoat_SpeedLowering
	if_has_move_with_effect AI_TARGET, EFFECT_SPEED_DOWN_2, AI_CV_MagicCoat_SpeedLowering
	goto AI_CV_MagicCoat_StatLowering

AI_CV_MagicCoat_SpeedLowering:
	if_target_faster AI_CV_MagicCoat_StatLowering
	get_last_used_bank_move AI_TARGET
	get_move_effect_from_result
	if_in_bytes AI_SpeedDown_EffList, AI_CV_MagicCoat_StatLowering
	if_random_less_than 96, AI_CV_MagicCoat_StatLowering
	score +2
AI_CV_MagicCoat_StatLowering:
	if_has_move_with_effect AI_TARGET, EFFECT_ACCURACY_DOWN, AI_CV_MagicCoat_StatLowering_Plus2
 	if_has_move_with_effect AI_TARGET, EFFECT_ACCURACY_DOWN_2, AI_CV_MagicCoat_StatLowering_Plus2
 	if_has_move_with_effect AI_TARGET, EFFECT_ATTACK_DOWN, AI_CV_MagicCoat_StatLowering_Plus2
 	if_has_move_with_effect AI_TARGET, EFFECT_ATTACK_DOWN_2, AI_CV_MagicCoat_StatLowering_Plus2
 	if_has_move_with_effect AI_TARGET, EFFECT_DEFENSE_DOWN, AI_CV_MagicCoat_StatLowering_Plus2
 	if_has_move_with_effect AI_TARGET, EFFECT_DEFENSE_DOWN_2, AI_CV_MagicCoat_StatLowering_Plus2
 	if_has_move_with_effect AI_TARGET, EFFECT_SPECIAL_ATTACK_DOWN, AI_CV_MagicCoat_StatLowering_Plus2
 	if_has_move_with_effect AI_TARGET, EFFECT_SPECIAL_ATTACK_DOWN_2, AI_CV_MagicCoat_StatLowering_Plus2
 	if_has_move_with_effect AI_TARGET, EFFECT_SPECIAL_DEFENSE_DOWN, AI_CV_MagicCoat_StatLowering_Plus2
 	if_has_move_with_effect AI_TARGET, EFFECT_SPECIAL_DEFENSE_DOWN_2, AI_CV_MagicCoat_StatLowering_Plus2
 	if_has_move_with_effect AI_TARGET, EFFECT_EVASION_DOWN, AI_CV_MagicCoat_StatLowering_Plus2
 	if_has_move_with_effect AI_TARGET, EFFECT_EVASION_DOWN_2, AI_CV_MagicCoat_StatLowering_Plus2
 	if_has_move_with_effect AI_TARGET, EFFECT_TICKLE, AI_CV_MagicCoat_StatLowering_Plus2
	goto AI_CV_MagicCoat_LeechSeed

AI_CV_MagicCoat_StatLowering_Plus2:
	if_has_move AI_TARGET, MOVE_KINESIS, AI_CV_MagicCoat_LeechSeed @ Magic Coat does not work with Kinesis in gen 3 only!
	if_random_less_than 96, AI_CV_MagicCoat_LeechSeed
	score +2
AI_CV_MagicCoat_LeechSeed:
	if_status3 AI_USER, STATUS3_LEECHSEED, AI_CV_MagicCoat_Status
	get_user_type1
	if_equal TYPE_GRASS, AI_CV_MagicCoat_Status
	get_user_type2
	if_equal TYPE_GRASS, AI_CV_MagicCoat_Status
	if_has_move_with_effect AI_TARGET, EFFECT_LEECH_SEED, AI_CV_MagicCoat_LeechSeed_Plus2
	goto AI_CV_MagicCoat_Status

AI_CV_MagicCoat_LeechSeed_Plus2:
	if_random_less_than 64, AI_CV_MagicCoat_LeechSeed
	score +2
AI_CV_MagicCoat_Status:
	if_status AI_USER, STATUS1_ANY, AI_CV_MagicCoat_Misc
	if_has_move_with_effect AI_TARGET, EFFECT_PARALYZE, AI_CV_MagicCoat_Status_TargetCheck
	if_has_move_with_effect AI_TARGET, EFFECT_POISON, AI_CV_MagicCoat_Status_TargetCheck
	if_has_move_with_effect AI_TARGET, EFFECT_SLEEP, AI_CV_MagicCoat_Status_TargetCheck
	if_has_move_with_effect AI_TARGET, EFFECT_TOXIC, AI_CV_MagicCoat_Status_TargetCheck
	if_has_move_with_effect AI_TARGET, EFFECT_WILL_O_WISP, AI_CV_MagicCoat_Status_TargetCheck
	goto AI_CV_MagicCoat_Misc

AI_CV_MagicCoat_Status_TargetCheck:
	if_status AI_TARGET, STATUS1_ANY, AI_CV_MagicCoat_Status_Plus2_LowerOdds
	if_random_less_than 224, AI_CV_MagicCoat_Status_Plus2
	goto AI_CV_MagicCoat_Misc

AI_CV_MagicCoat_Status_Plus2_LowerOdds:
	if_random_less_than 128, AI_CV_MagicCoat_Misc
AI_CV_MagicCoat_Status_Plus2:
	score +2
AI_CV_MagicCoat_Misc:
	if_has_move_with_effect AI_TARGET, EFFECT_CONFUSE, AI_CV_MagicCoat_Misc_Plus2_LowOdds
	if_has_move_with_effect AI_TARGET, EFFECT_FLATTER, AI_CV_MagicCoat_Misc_Plus2_LowOdds
	if_has_move_with_effect AI_TARGET, EFFECT_SWAGGER, AI_CV_MagicCoat_Misc_Plus2_LowOdds
	if_has_move_with_effect AI_TARGET, EFFECT_TEETER_DANCE, AI_CV_MagicCoat_Misc_Plus2_LowOdds
	if_has_move_with_effect AI_TARGET, EFFECT_MEAN_LOOK, AI_CV_MagicCoat_Misc_Plus2_LowOdds
	end

AI_CV_MagicCoat_Misc_Plus2_LowOdds:
	if_random_less_than 240, AI_End
	score +2
	end

AI_CV_MagicCoat_Minus2:
	score -2
	end

AI_CV_Imprison:
	if_shares_move_with_user AI_CV_ImprisonWontFail
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
	if_status AI_TARGET, STATUS1_BURN | STATUS1_PARALYSIS | STATUS1_POISON | STATUS1_TOXIC_POISON, AI_CV_Snatch_StatusRemoval
	goto AI_CV_Snatch_RecoveryMoves

AI_CV_Snatch_StatusRemoval:
	if_has_move_with_effect AI_TARGET, EFFECT_HEAL_BELL, AI_CV_Snatch_StatusRemoval_Plus2
	if_has_move_with_effect AI_TARGET, EFFECT_REFRESH, AI_CV_Snatch_StatusRemoval_Plus2
	goto AI_CV_Snatch_RecoveryMoves

AI_CV_Snatch_StatusRemoval_Plus2:
	if_random_less_than 128, AI_CV_Snatch_RecoveryMoves
	score +2
AI_CV_Snatch_RecoveryMoves:
	if_has_move_with_effect AI_TARGET, EFFECT_MOONLIGHT, AI_CV_Snatch_RecoveryMoves_HPCheck
	if_has_move_with_effect AI_TARGET, EFFECT_MORNING_SUN, AI_CV_Snatch_RecoveryMoves_HPCheck
	if_has_move_with_effect AI_TARGET, EFFECT_REST, AI_CV_Snatch_RecoveryMoves_HPCheck
	if_has_move_with_effect AI_TARGET, EFFECT_RESTORE_HP, AI_CV_Snatch_RecoveryMoves_HPCheck
	if_has_move_with_effect AI_TARGET, EFFECT_SOFTBOILED, AI_CV_Snatch_RecoveryMoves_HPCheck
	if_has_move_with_effect AI_TARGET, EFFECT_SYNTHESIS, AI_CV_Snatch_RecoveryMoves_HPCheck
	goto AI_CV_Snatch_BoostingMoves

AI_CV_Snatch_RecoveryMoves_HPCheck:
	if_hp_less_than AI_TARGET, 30, AI_CV_Snatch_RecoveryMoves_Plus2
	if_user_faster AI_CV_Snatch_RecoveryMoves_HPCheck_TargetSlower
	if_hp_less_than AI_TARGET, 55, AI_CV_Snatch_RecoveryMoves_Plus2_Random
	goto AI_CV_Snatch_BoostingMoves

AI_CV_Snatch_RecoveryMoves_HPCheck_TargetSlower:
	if_hp_less_than AI_TARGET, 75, AI_CV_Snatch_RecoveryMoves_Plus2_Random
	goto AI_CV_Snatch_BoostingMoves

AI_CV_Snatch_RecoveryMoves_Plus2_Random:
	if_random_less_than 128, AI_CV_Snatch_BoostingMoves
AI_CV_Snatch_RecoveryMoves_Plus2:
	score +2
AI_CV_Snatch_BoostingMoves:
	if_has_move_with_effect AI_TARGET, EFFECT_ATTACK_UP, AI_CV_Snatch_BoostingMove_Plus2_Random
	if_has_move_with_effect AI_TARGET, EFFECT_ATTACK_UP_2, AI_CV_Snatch_BoostingMove_Plus2_Random
	if_has_move_with_effect AI_TARGET, EFFECT_DEFENSE_UP, AI_CV_Snatch_BoostingMove_Plus2_Random
	if_has_move_with_effect AI_TARGET, EFFECT_DEFENSE_UP_2, AI_CV_Snatch_BoostingMove_Plus2_Random
	if_has_move_with_effect AI_TARGET, EFFECT_DEFENSE_CURL, AI_CV_Snatch_BoostingMove_Plus2_Random
	if_has_move_with_effect AI_TARGET, EFFECT_SPECIAL_ATTACK_UP, AI_CV_Snatch_BoostingMove_Plus2_Random
	if_has_move_with_effect AI_TARGET, EFFECT_SPECIAL_ATTACK_UP_2, AI_CV_Snatch_BoostingMove_Plus2_Random
	if_has_move_with_effect AI_TARGET, EFFECT_SPECIAL_DEFENSE_UP, AI_CV_Snatch_BoostingMove_Plus2_Random
	if_has_move_with_effect AI_TARGET, EFFECT_SPECIAL_DEFENSE_UP_2, AI_CV_Snatch_BoostingMove_Plus2_Random
	if_has_move_with_effect AI_TARGET, EFFECT_SPEED_UP, AI_CV_Snatch_BoostingMove_Plus2_Random
	if_has_move_with_effect AI_TARGET, EFFECT_SPEED_UP_2, AI_CV_Snatch_BoostingMove_Plus2_Random
	if_has_move_with_effect AI_TARGET, EFFECT_EVASION_UP, AI_CV_Snatch_BoostingMove_Plus2_Random
	if_has_move_with_effect AI_TARGET, EFFECT_EVASION_UP_2, AI_CV_Snatch_BoostingMove_Plus2_Random
	if_has_move_with_effect AI_TARGET, EFFECT_BULK_UP, AI_CV_Snatch_BoostingMove_Plus2_Random
	if_has_move_with_effect AI_TARGET, EFFECT_CALM_MIND, AI_CV_Snatch_BoostingMove_Plus2_Random
	if_has_move_with_effect AI_TARGET, EFFECT_COSMIC_POWER, AI_CV_Snatch_BoostingMove_Plus2_Random
	if_has_move_with_effect AI_TARGET, EFFECT_DRAGON_DANCE, AI_CV_Snatch_BoostingMove_Plus2_Random
	if_has_move_with_effect AI_TARGET, EFFECT_MINIMIZE, AI_CV_Snatch_BoostingMove_Plus2_Random
	goto AI_CV_Snatch_UserHP

AI_CV_Snatch_BoostingMove_Plus2_Random:
	if_random_less_than 128, AI_CV_Snatch_OtherMoves
	score +2
AI_CV_Snatch_OtherMoves:
	if_has_move_with_effect AI_TARGET, EFFECT_CHARGE, AI_CV_Snatch_OtherMoves_Random_Plus1
	if_has_move_with_effect AI_TARGET, EFFECT_INGRAIN, AI_CV_Snatch_OtherMoves_Random_Plus1
	if_has_move_with_effect AI_TARGET, EFFECT_PSYCH_UP, AI_CV_Snatch_OtherMoves_Random_Plus1
	if_has_move_with_effect AI_TARGET, EFFECT_SAFEGUARD, AI_CV_Snatch_OtherMoves_Random_Plus1
	if_has_move_with_effect AI_TARGET, EFFECT_STOCKPILE, AI_CV_Snatch_OtherMoves_Random_Plus1
	if_has_move_with_effect AI_TARGET, EFFECT_SWALLOW, AI_CV_Snatch_OtherMoves_Random_Plus1
	goto AI_CV_Snatch_UserHP

AI_CV_Snatch_OtherMoves_Random_Plus1:
	if_random_less_than 240, AI_CV_Snatch_UserHP
	score +2
AI_CV_Snatch_UserHP:
	if_hp_less_than AI_USER, 35, AI_CV_Snatch_UserHP_Minus2_Random
	end

AI_CV_Snatch_UserHP_Minus2_Random:
	if_random_less_than 64, AI_End
	score -2
	end

AI_CV_MudSport:
	if_hp_less_than AI_USER, 50, AI_CV_Sport_Minus1
	if_has_attack_of_type AI_TARGET, TYPE_ELECTRIC, AI_CV_Sport_Plus1
	goto AI_CV_Sport_Minus1

AI_CV_WaterSport:
	if_hp_less_than AI_USER, 50, AI_CV_Sport_Minus1
	if_has_attack_of_type AI_TARGET, TYPE_FIRE, AI_CV_Sport_Plus1
	goto AI_CV_Sport_Minus1

AI_CV_Sport_Plus1:
	score +1
	end

AI_CV_Sport_Minus1:
	score -1
	end

AI_CV_RapidSpin:
	score -8
	if_side_affecting AI_USER, SIDE_STATUS_SPIKES, AI_CV_RapidSpin_ClearSpikes
	goto AI_CV_RapidSpin_SeededCheck

AI_CV_RapidSpin_ClearSpikes:
	count_usable_party_mons AI_USER
	if_equal 0, AI_CV_RapidSpin_SeededCheck
	score +10
AI_CV_RapidSpin_SeededCheck:
	if_status3 AI_USER, STATUS3_LEECHSEED, AI_CV_RapidSpin_ClearSeed
	goto AI_CV_RapidSpin_TrappedCheck

AI_CV_RapidSpin_ClearSeed:
	score +10
AI_CV_RapidSpin_TrappedCheck:
	if_status2 AI_USER, STATUS2_WRAPPED, AI_CV_RapidSpin_Trapped
	end

AI_CV_RapidSpin_Trapped:
	score +9
	end

AI_CV_Rollout:
	if_stat_level_more_than AI_USER, STAT_ATK, 7, AI_CV_Rollout_Possible
	if_stat_level_more_than AI_USER, STAT_DEF, 7, AI_CV_Rollout_Possible
	if_stat_level_more_than AI_USER, STAT_SPDEF, 7, AI_CV_Rollout_Possible
	goto AI_CV_Rollout_Minus3

AI_CV_Rollout_Possible:
	if_hp_less_than AI_USER, 67, AI_CV_Rollout_Minus3
	if_stat_level_more_than AI_USER, STAT_ATK, 9, AI_CV_Rollout_Plus1
	if_stat_level_more_than AI_USER, STAT_DEF, 9, AI_CV_Rollout_Plus1
	if_stat_level_more_than AI_USER, STAT_SPDEF, 9, AI_CV_Rollout_Plus1
	if_hp_less_than AI_USER, 85, AI_CV_Rollout_Minus3
	if_stat_level_more_than AI_USER, STAT_ATK, 8, AI_CV_Rollout_Plus1_Random
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

AI_CV_Rollout_Minus3:
	score -3
	end

AI_CV_Spikes:
	get_spikes_layers_target
	if_equal 2, AI_CV_Spikes_GetThirdLayer
	if_equal 1, AI_CV_Spikes_DiscourageSecondLayer
	end

AI_CV_Spikes_GetThirdLayer:
	score +1
	end

AI_CV_Spikes_DiscourageSecondLayer:
	if_hp_less_than AI_USER, 50, AI_CV_Spikes_LowHP
	if_hp_less_than AI_USER, 75, AI_CV_Spikes_LowHP_Random
	end

AI_CV_Spikes_LowHP_Random:
	if_random_less_than 128, AI_End
AI_CV_Spikes_LowHP:
	score -1
	end

AI_CV_Conversion:
	get_highest_type_effectiveness_from_target
	if_equal AI_EFFECTIVENESS_x0, AI_CV_Conversion_Minus10
	if_equal AI_EFFECTIVENESS_x0_25, AI_CV_Conversion_Minus10
	if_equal AI_EFFECTIVENESS_x0_5, AI_CV_Conversion_Minus10
	if_target_faster AI_CV_Conversion_Slower_Minus3
	if_status AI_TARGET, STATUS1_FREEZE | STATUS1_PARALYSIS | STATUS1_SLEEP, AI_CV_Conversion_Minus1
	get_last_used_bank_move AI_TARGET
	get_move_power_from_result
	if_equal 0, AI_CV_Conversion_Minus1
	goto AI_CV_Conversion_DontRepeat

AI_CV_Conversion_Minus1:
	score -1
AI_CV_Conversion_DontRepeat:
	get_last_used_bank_move AI_USER
	get_move_effect_from_result
	if_equal EFFECT_CONVERSION_2, AI_CV_Conversion_DontRepeat_Minus1
	goto AI_CV_Conversion_RandomMinus1

AI_CV_Conversion_DontRepeat_Minus1:
	score -1
AI_CV_Conversion_RandomMinus1:
	if_random_less_than 96, AI_End
	score -1
	end

AI_CV_Conversion_Slower_Minus3:
	score -3
	end

AI_CV_Conversion_Minus10:
	score -10
	end

AI_CV_GeneralDiscourage:
	if_status2 AI_USER, STATUS2_SUBSTITUTE, AI_CV_GeneralDiscourage_BetterOdds
	if_random_less_than 16, AI_End
	goto AI_CV_GeneralDiscourage_Minus2

AI_CV_GeneralDiscourage_BetterOdds:
	if_random_less_than 196, AI_End
AI_CV_GeneralDiscourage_Minus2:
	score -2
	end

AI_CV_Safeguard:
	if_status AI_TARGET, STATUS1_FREEZE | STATUS1_SLEEP, AI_CV_Safeguard_CheckSleep
	if_target_faster AI_CV_Safeguard_Discourage
AI_CV_Safeguard_CheckSleep:
	if_ability AI_USER, ABILITY_INSOMNIA, AI_CV_Safeguard_CheckPsn
	if_ability AI_USER, ABILITY_VITAL_SPIRIT, AI_CV_Safeguard_CheckPsn
	if_has_move_with_effect AI_TARGET, EFFECT_SLEEP, AI_CV_Safeguard_Encourage
	if_status3 AI_USER, STATUS3_YAWN, AI_CV_Safeguard_Discourage
	if_has_move_with_effect AI_TARGET, EFFECT_YAWN, AI_CV_Safeguard_Encourage
AI_CV_Safeguard_CheckPsn:
	if_ability AI_USER, ABILITY_IMMUNITY, AI_CV_Safeguard_CheckPara
	get_user_type1
	if_in_bytes AI_PoisoningImmune, AI_CV_Safeguard_CheckPara
	get_user_type2
	if_in_bytes AI_PoisoningImmune, AI_CV_Safeguard_CheckPara
	if_has_move_with_effect AI_TARGET, EFFECT_POISON, AI_CV_Safeguard_Encourage
	if_has_move_with_effect AI_TARGET, EFFECT_TOXIC, AI_CV_Safeguard_Encourage
AI_CV_Safeguard_CheckPara:
	if_ability AI_USER, ABILITY_LIMBER, AI_CV_Safeguard_CheckBurn
	get_user_type1
	if_equal TYPE_GROUND, AI_CV_Safeguard_CheckPara_Glare
	get_user_type2
	if_equal TYPE_GROUND, AI_CV_Safeguard_CheckPara_Glare
	if_has_move AI_TARGET, MOVE_THUNDER_WAVE, AI_CV_Safeguard_Encourage
AI_CV_Safeguard_CheckPara_Glare:
	get_user_type1
	if_equal TYPE_GHOST, AI_CV_Safeguard_CheckPara_ShieldDust
	get_user_type2
	if_equal TYPE_GHOST, AI_CV_Safeguard_CheckPara_ShieldDust
	if_has_move AI_TARGET, MOVE_GLARE, AI_CV_Safeguard_Encourage
AI_CV_Safeguard_CheckPara_ShieldDust:
	if_ability AI_USER, ABILITY_SHIELD_DUST, AI_CV_Safeguard_CheckBurn
	get_user_type1
	if_equal TYPE_GROUND, AI_CV_Safeguard_CheckPara_Ghost
	get_user_type2
	if_equal TYPE_GROUND, AI_CV_Safeguard_CheckPara_Ghost
	if_has_move AI_TARGET, MOVE_THUNDER, AI_CV_Safeguard_Encourage
	if_has_move AI_TARGET, MOVE_ZAP_CANNON, AI_CV_Safeguard_Encourage
AI_CV_Safeguard_CheckPara_Ghost:
	get_user_type1
	if_equal TYPE_GHOST, AI_CV_Safeguard_CheckPara_Lick
	get_user_type2
	if_equal TYPE_GHOST, AI_CV_Safeguard_CheckPara_Lick
	if_has_move AI_TARGET, MOVE_BODY_SLAM, AI_CV_Safeguard_Encourage
	if_has_move AI_TARGET, MOVE_SECRET_POWER, AI_CV_Safeguard_Encourage
AI_CV_Safeguard_CheckPara_Lick:
	get_user_type1
	if_equal TYPE_NORMAL, AI_CV_Safeguard_CheckBurn
	get_user_type2
	if_equal TYPE_NORMAL, AI_CV_Safeguard_CheckBurn
	if_has_move AI_TARGET, MOVE_LICK, AI_CV_Safeguard_Encourage
AI_CV_Safeguard_CheckBurn:
	if_ability AI_USER, ABILITY_FLASH_FIRE, AI_CV_Safeguard_CheckSeed
	if_ability AI_USER, ABILITY_WATER_VEIL, AI_CV_Safeguard_CheckSeed
	get_user_type1
	if_equal TYPE_FIRE, AI_CV_Safeguard_CheckSeed
	get_user_type2
	if_equal TYPE_FIRE, AI_CV_Safeguard_CheckSeed
	if_has_move_with_effect AI_TARGET, EFFECT_WILL_O_WISP, AI_CV_Safeguard_Encourage
AI_CV_Safeguard_CheckSeed:
	get_user_type1
	if_equal TYPE_GRASS, AI_CV_Safeguard_Discourage
	get_user_type2
	if_equal TYPE_GRASS, AI_CV_Safeguard_Discourage
	if_has_move_with_effect AI_TARGET, EFFECT_LEECH_SEED, AI_CV_Safeguard_Encourage
AI_CV_Safeguard_Discourage:
	if_random_less_than 4, AI_End
	score -2
	end

AI_CV_Safeguard_Encourage:
	if_random_less_than 48, AI_End
	score +2
	end

AI_CV_Recoil:
	if_hp_more_than AI_USER, 15, AI_End
AI_CV_SuicideCheck:
	count_usable_party_mons AI_USER
	if_more_than 0, AI_End
	count_usable_party_mons AI_TARGET
	if_equal 0, AI_End
	score -40
	end

AI_TryToFaint:
	if_target_is_ally AI_End
	if_effect EFFECT_MIRROR_MOVE, AI_TTF_MirrorMove
	goto AI_TTF_Check

AI_TTF_MirrorMove:
	get_last_used_bank_move AI_TARGET
	if_in_bytes AI_DontMirror_EffList, AI_TTF_Minus10
	get_move_target_from_result
	if_not_equal MOVE_TARGET_SELECTED | MOVE_TARGET_BOTH | MOVE_TARGET_FOES_AND_ALLY, AI_TTF_Minus10
	if_target_faster AI_TTF_Minus10
	is_first_turn_for AI_USER
	if_equal TRUE, AI_TTF_Minus10
	consider_imitated_move
AI_TTF_Check:
	if_can_faint AI_TTF_DBond
	end

AI_TTF_DBond:
	if_status2 AI_TARGET, STATUS2_DESTINY_BOND, AI_TTF_DBond_RandomMinus7
	goto AI_TTF_Grudge

AI_TTF_DBond_RandomMinus7:
	if_random_less_than 48, AI_TTF_Grudge
	score -7
AI_TTF_Grudge:
	if_status3 AI_TARGET, STATUS3_GRUDGE, AI_TTF_Grudge_RandomMinus6
	goto AI_TTF_TryToEncouragePriority

AI_TTF_Grudge_RandomMinus6:
	if_random_less_than 196, AI_TTF_TryToEncouragePriority
	score -6
AI_TTF_TryToEncouragePriority:
	get_considered_move_effect
	if_in_bytes AI_TTF_DiscouragedEffList, AI_End
	if_in_bytes AI_TTF_PriorityMoves, AI_TTF_Plus6
	if_in_bytes AI_TTF_LessPreferred, AI_TTF_EvasionCheck
	if_effect EFFECT_VITAL_THROW, AI_TTF_AccBonus_1
	if_effect EFFECT_EXPLOSION, AI_TTF_AccBonus_2
	if_holds_item AI_USER, ITEM_WHITE_HERB, AI_TTF_SubstituteCheck
	get_considered_move_effect
	if_in_bytes AI_TTF_NoWhiteHerb, AI_TTF_AccBonus_1
AI_TTF_SubstituteCheck:
	if_status2 AI_USER, STATUS2_SUBSTITUTE, AI_TTF_Plus4
	if_effect EFFECT_SEMI_INVULNERABLE, AI_TTF_EvasionCheck
	goto AI_TTF_Plus4

AI_TTF_Plus6:
	score +2
AI_TTF_Plus4:
	score +4
AI_TTF_EvasionCheck:
	if_status3 AI_TARGET, STATUS3_ALWAYS_HITS, AI_TTF_AccBonus_3
	if_stat_level_less_than AI_TARGET, STAT_EVASION, -1, AI_TTF_AccBonus_2
	if_stat_level_less_than AI_TARGET, STAT_EVASION, 0, AI_TTF_AccBonus_CompEyesCheck
	if_ability AI_USER, ABILITY_COMPOUND_EYES, AI_TTF_AccBonus_LessEvasive
	if_ability AI_USER, ABILITY_HUSTLE, AI_TTF_AccBonus_Hustle_PreCheck
	goto AI_TTF_AccBonus

AI_TTF_AccBonus_Hustle_PreCheck:
	get_curr_move_type
	if_in_bytes AI_PhysicalTypeList, AI_TTF_AccBonus_Hustle
AI_TTF_AccBonus:
	if_effect EFFECT_ALWAYS_HIT, AI_TTF_AccBonus_4
	get_considered_move_accuracy
	if_equal 100, AI_TTF_AccBonus_4
	if_equal 95, AI_TTF_AccBonus_3
	if_equal 90, AI_TTF_AccBonus_2
	if_equal 85, AI_TTF_AccBonus_2
	if_equal 80, AI_TTF_AccBonus_1
	if_equal 75, AI_TTF_AccBonus_1
	if_equal 70, AI_TTF_AccBonus_1
	end

AI_TTF_AccBonus_Hustle:
	if_effect EFFECT_ALWAYS_HIT, AI_TTF_AccBonus_4
	get_considered_move_accuracy
	if_equal 100, AI_TTF_AccBonus_3
	if_equal 95, AI_TTF_AccBonus_3
	if_equal 90, AI_TTF_AccBonus_2
	if_equal 85, AI_TTF_AccBonus_2
	if_equal 80, AI_TTF_AccBonus_2
	if_equal 75, AI_TTF_AccBonus_1
	if_equal 70, AI_TTF_AccBonus_1
	end

AI_TTF_AccBonus_CompEyesCheck:
	if_ability AI_USER, ABILITY_COMPOUND_EYES, AI_End
AI_TTF_AccBonus_LessEvasive:
	get_considered_move_accuracy
	if_equal 70, AI_TTF_AccBonus_2
	if_equal 50, AI_TTF_AccBonus_1
	goto AI_TTF_AccBonus_3

AI_TTF_AccBonus_4:
	score +1
AI_TTF_AccBonus_3:
	score +1
AI_TTF_AccBonus_2:
	score +1
AI_TTF_AccBonus_1:
	score +1
	end

AI_TTF_Minus10:
	score -10
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
	get_type AI_TYPE1_USER_PARTNER
	if_equal TYPE_FLYING, Score_Plus2
	get_type AI_TYPE2_USER_PARTNER
	if_equal TYPE_FLYING, Score_Plus2
	get_type AI_TYPE1_USER_PARTNER
	if_in_bytes AI_DoubleBattle_GroundWeak, Score_Minus10
	get_type AI_TYPE2_USER_PARTNER
	if_in_bytes AI_DoubleBattle_GroundWeak, Score_Minus10
	goto Score_Minus3

AI_DoubleBattleSkillSwap:
	get_ability AI_USER
	if_equal ABILITY_TRUANT, Score_Plus5
	get_ability AI_TARGET
	if_equal ABILITY_SHADOW_TAG, Score_Plus2
	if_equal ABILITY_PURE_POWER, Score_Plus2
	end

AI_DoubleBattleElectricMove:
	if_no_ability AI_TARGET_PARTNER, ABILITY_LIGHTNING_ROD, AI_End
	score -2
	get_type AI_TYPE1_TARGET
	if_equal TYPE_GROUND, AI_End
	get_type AI_TYPE2_TARGET
	if_equal TYPE_GROUND, AI_End
	score -8
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
	goto Score_Minus30

AI_TrySkillSwapOnAlly:
	get_ability AI_TARGET
	if_equal ABILITY_TRUANT, Score_Plus10
	get_ability AI_USER
	if_not_equal ABILITY_LEVITATE, AI_TrySkillSwapOnAlly2
	get_ability AI_TARGET
	if_equal ABILITY_LEVITATE, Score_Minus30
	get_target_type1
	if_not_equal TYPE_ELECTRIC, AI_TrySkillSwapOnAlly2
	score +1
	get_target_type2
	if_not_equal TYPE_ELECTRIC, AI_TrySkillSwapOnAlly2
	score +1
	end

AI_TrySkillSwapOnAlly2:
	if_not_equal ABILITY_COMPOUND_EYES, Score_Minus30
	if_has_move AI_USER_PARTNER, MOVE_FIRE_BLAST, AI_TrySkillSwapOnAllyPlus3
	if_has_move AI_USER_PARTNER, MOVE_THUNDER, AI_TrySkillSwapOnAllyPlus3
	if_has_move AI_USER_PARTNER, MOVE_CROSS_CHOP, AI_TrySkillSwapOnAllyPlus3
	if_has_move AI_USER_PARTNER, MOVE_HYDRO_PUMP, AI_TrySkillSwapOnAllyPlus3
	if_has_move AI_USER_PARTNER, MOVE_DYNAMIC_PUNCH, AI_TrySkillSwapOnAllyPlus3
	if_has_move AI_USER_PARTNER, MOVE_BLIZZARD, AI_TrySkillSwapOnAllyPlus3
	if_has_move AI_USER_PARTNER, MOVE_MEGAHORN, AI_TrySkillSwapOnAllyPlus3
	goto Score_Minus30

AI_TrySkillSwapOnAllyPlus3:
	goto Score_Plus3

AI_TryStatusOnAlly:
	get_ability AI_TARGET
	if_not_equal ABILITY_GUTS, Score_Minus30
	if_status AI_TARGET, STATUS1_ANY, Score_Minus30
	if_hp_less_than AI_USER, 91, Score_Minus30
	goto Score_Plus5

AI_TryHelpingHandOnAlly:
	if_random_less_than 64, Score_Minus1
	goto Score_Plus2

AI_TrySwaggerOnAlly:
	if_holds_item AI_TARGET, ITEM_PERSIM_BERRY, AI_TrySwaggerOnAlly2
	goto Score_Minus30

AI_TrySwaggerOnAlly2:
	if_stat_level_more_than AI_TARGET, STAT_ATK, 7, AI_End
	score +3
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

AI_Roaming:
	if_status2 AI_USER, STATUS2_WRAPPED, AI_End
	if_status2 AI_USER, STATUS2_ESCAPE_PREVENTION, AI_End
	get_ability AI_TARGET
	if_equal ABILITY_SHADOW_TAG, AI_End
	get_ability AI_USER
	if_equal ABILITY_LEVITATE, AI_Roaming_Flee
	get_ability AI_TARGET
	if_equal ABILITY_ARENA_TRAP, AI_End
AI_Roaming_Flee:
	flee

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

AI_CBM_SubstituteBlocks_EffList:
	.byte EFFECT_DREAM_EATER
	.byte EFFECT_EXPLOSION
	.byte EFFECT_TRAP
	.byte -1

AI_CBM_IgnoresSubstitute_EffList:
	.byte EFFECT_ATTRACT
	.byte EFFECT_DISABLE
	.byte EFFECT_ENCORE
	.byte EFFECT_FORESIGHT
	.byte EFFECT_HAZE
	.byte EFFECT_MEAN_LOOK
	.byte EFFECT_PSYCH_UP
	.byte EFFECT_ROLE_PLAY
	.byte EFFECT_SKILL_SWAP
	.byte EFFECT_SPITE
	.byte EFFECT_TAUNT
	.byte EFFECT_TORMENT
	.byte EFFECT_TRANSFORM
	.byte -1

AI_CBM_IgnoreTypeMatchup:
	.byte EFFECT_BIDE
	.byte EFFECT_COUNTER
	.byte EFFECT_DRAGON_RAGE
	.byte EFFECT_ENDEAVOR
	.byte EFFECT_FAKE_OUT
	.byte EFFECT_LEVEL_DAMAGE
	.byte EFFECT_MIRROR_COAT
	.byte EFFECT_OHKO
	.byte EFFECT_PSYWAVE
	.byte EFFECT_RAPID_SPIN
	.byte EFFECT_SUPER_FANG
	.byte EFFECT_TRAP
	.byte -1

AI_CBM_StatusSecondary:
	.byte EFFECT_PARALYZE_HIT
	.byte EFFECT_POISON_FANG
	.byte EFFECT_POISON_HIT
	.byte EFFECT_SECRET_POWER
	.byte EFFECT_TWINEEDLE
	.byte EFFECT_THUNDER
	.byte EFFECT_TRI_ATTACK
	.byte -1

AI_CBM_ItemRemovalAttacks_EffList:
	.byte EFFECT_KNOCK_OFF
	.byte EFFECT_THIEF
	.byte -1

AI_CBM_DontEncourageAttacks:
	.byte EFFECT_FOCUS_PUNCH
	.byte EFFECT_RAGE
	.byte EFFECT_RAMPAGE
	.byte EFFECT_RAZOR_WIND
	.byte EFFECT_RECHARGE
	.byte EFFECT_ROLLOUT
	.byte EFFECT_SEMI_INVULNERABLE
	.byte EFFECT_SKULL_BASH
	.byte EFFECT_SKY_ATTACK
	.byte EFFECT_UPROAR
	.byte -1

AI_CBM_StatLower_Effects:
	.byte EFFECT_ACCURACY_DOWN
	.byte EFFECT_ACCURACY_DOWN_2
	.byte EFFECT_ATTACK_DOWN
	.byte EFFECT_ATTACK_DOWN_2
	.byte EFFECT_DEFENSE_DOWN
	.byte EFFECT_DEFENSE_DOWN_2
	.byte EFFECT_EVASION_DOWN
	.byte EFFECT_EVASION_DOWN_2
	.byte EFFECT_SPECIAL_ATTACK_DOWN
	.byte EFFECT_SPECIAL_ATTACK_DOWN_2
	.byte EFFECT_SPECIAL_DEFENSE_DOWN
	.byte EFFECT_SPECIAL_DEFENSE_DOWN_2
	.byte EFFECT_SPEED_DOWN
	.byte EFFECT_SPEED_DOWN_2
	.byte -1

AI_CBM_StatLowerAndDamage_Effects:
	.byte EFFECT_ATTACK_DOWN_HIT
	.byte EFFECT_DEFENSE_DOWN_HIT
	.byte EFFECT_SPECIAL_ATTACK_DOWN_HIT
	.byte EFFECT_SPECIAL_DEFENSE_DOWN_HIT
	.byte EFFECT_SPEED_DOWN_HIT
	.byte -1

AI_CBM_BlockStatLowering:
	.byte ABILITY_CLEAR_BODY
	.byte ABILITY_WHITE_SMOKE
	.byte -1

AI_CBM_AttackUp_EffList:
	.byte EFFECT_ATTACK_UP
	.byte EFFECT_ATTACK_UP_2
	.byte -1

AI_CBM_DefenseUp_EffList:
	.byte EFFECT_DEFENSE_UP
	.byte EFFECT_DEFENSE_UP_2
	.byte EFFECT_DEFENSE_CURL
	.byte -1

AI_CBM_SpeedUp_EffList:
	.byte EFFECT_SPEED_UP
	.byte EFFECT_SPEED_UP_2
	.byte -1

AI_CBM_SpAtkUp_EffList:
	.byte EFFECT_SPECIAL_ATTACK_UP
	.byte EFFECT_SPECIAL_ATTACK_UP_2
	.byte -1

AI_CBM_SpDefUp_EffList:
	.byte EFFECT_SPECIAL_DEFENSE_UP
	.byte EFFECT_SPECIAL_DEFENSE_UP_2
	.byte -1

AI_CBM_AccUp_EffList:
	.byte EFFECT_ACCURACY_UP
	.byte EFFECT_ACCURACY_UP_2
	.byte -1

AI_CBM_EvasionUp_EffList:
	.byte EFFECT_EVASION_UP
	.byte EFFECT_EVASION_UP_2
	.byte EFFECT_MINIMIZE
	.byte -1

AI_CBM_AtkDown_EffList:
	.byte EFFECT_ATTACK_DOWN
	.byte EFFECT_ATTACK_DOWN_2
	.byte -1

AI_CBM_DefDown_EffList:
	.byte EFFECT_DEFENSE_DOWN
	.byte EFFECT_DEFENSE_DOWN_2
	.byte -1

AI_CBM_SpDefDown_EffList:
	.byte EFFECT_SPECIAL_DEFENSE_DOWN
	.byte EFFECT_SPECIAL_DEFENSE_DOWN_2
	.byte -1

AI_CBM_AccDown_EffList:
	.byte EFFECT_ACCURACY_DOWN
	.byte EFFECT_ACCURACY_DOWN_2
	.byte -1

AI_CBM_ConsiderAllStats:
	.byte EFFECT_HAZE
	.byte EFFECT_PSYCH_UP
	.byte -1

AI_CBM_Psn_EffList:
	.byte EFFECT_TOXIC
	.byte EFFECT_POISON
	.byte -1

AI_CBM_Confuse_EffList:
	.byte EFFECT_CONFUSE
	.byte EFFECT_FLATTER
	.byte EFFECT_SWAGGER
	.byte EFFECT_TEETER_DANCE
	.byte -1

AI_CBM_Stockpile_EffList:
	.byte EFFECT_SPIT_UP
	.byte EFFECT_SWALLOW
	.byte -1

AI_CBM_ItemRemoval_EffList:
	.byte EFFECT_KNOCK_OFF
	.byte EFFECT_THIEF
	.byte EFFECT_TRICK
	.byte -1

AI_CBM_DontRepeat_EffList:
	.byte EFFECT_CHARGE
	.byte EFFECT_LOCK_ON
	.byte EFFECT_WISH
	.byte -1

AI_CBM_CantLowerSpeed:
	.byte ABILITY_CLEAR_BODY
	.byte ABILITY_SHIELD_DUST
	.byte ABILITY_SPEED_BOOST
	.byte ABILITY_WHITE_SMOKE
	.byte -1

AI_CV_SandstormResistantTypes:
	.byte TYPE_GROUND
	.byte TYPE_ROCK
	.byte TYPE_STEEL
	.byte -1

AI_CV_Encore_EncouragedMovesToEncore_WhileBehindSub:
	.byte EFFECT_ATTACK_UP
	.byte EFFECT_ATTACK_UP_2
	.byte EFFECT_ATTRACT
	.byte EFFECT_BELLY_DRUM
	.byte EFFECT_CAMOUFLAGE
	.byte EFFECT_CHARGE
	.byte EFFECT_CONFUSE
	.byte EFFECT_CONVERSION
	.byte EFFECT_CONVERSION_2
	.byte EFFECT_COUNTER
	.byte EFFECT_CURSE
	.byte EFFECT_DEFENSE_UP
	.byte EFFECT_DEFENSE_UP_2
	.byte EFFECT_DISABLE
	.byte EFFECT_DREAM_EATER
	.byte EFFECT_ENDURE
	.byte EFFECT_FAKE_OUT
	.byte EFFECT_FLATTER
	.byte EFFECT_FOCUS_ENERGY
	.byte EFFECT_FOLLOW_ME
	.byte EFFECT_FORESIGHT
	.byte EFFECT_FUTURE_SIGHT
	.byte EFFECT_GRUDGE
	.byte EFFECT_HAIL
	.byte EFFECT_HAZE
	.byte EFFECT_HEAL_BELL
	.byte EFFECT_HELPING_HAND
	.byte EFFECT_IMPRISON
	.byte EFFECT_INGRAIN
	.byte EFFECT_KNOCK_OFF
	.byte EFFECT_LEECH_SEED
	.byte EFFECT_LIGHT_SCREEN
	.byte EFFECT_LOCK_ON
	.byte EFFECT_MEAN_LOOK
	.byte EFFECT_MIRROR_COAT
	.byte EFFECT_MIST
	.byte EFFECT_MUD_SPORT
	.byte EFFECT_NIGHTMARE
	.byte EFFECT_PARALYZE
	.byte EFFECT_PERISH_SONG
	.byte EFFECT_POISON
	.byte EFFECT_PROTECT
	.byte EFFECT_PSYCH_UP
	.byte EFFECT_RAIN_DANCE
	.byte EFFECT_RAPID_SPIN
	.byte EFFECT_RECYCLE
	.byte EFFECT_REFRESH
	.byte EFFECT_REST
	.byte EFFECT_ROLE_PLAY
	.byte EFFECT_SAFEGUARD
	.byte EFFECT_SANDSTORM
	.byte EFFECT_SKILL_SWAP
	.byte EFFECT_SPECIAL_ATTACK_UP
	.byte EFFECT_SPECIAL_ATTACK_UP_2
	.byte EFFECT_SPECIAL_DEFENSE_UP
	.byte EFFECT_SPECIAL_DEFENSE_UP_2
	.byte EFFECT_SPIT_UP
	.byte EFFECT_SPLASH
	.byte EFFECT_STOCKPILE
	.byte EFFECT_SUNNY_DAY
	.byte EFFECT_SUPER_FANG
	.byte EFFECT_SWAGGER
	.byte EFFECT_SWALLOW
	.byte EFFECT_TEETER_DANCE
	.byte EFFECT_TELEPORT
	.byte EFFECT_THIEF
	.byte EFFECT_TORMENT
	.byte EFFECT_TOXIC
	.byte EFFECT_TRICK
	.byte EFFECT_WATER_SPORT
	.byte EFFECT_WILL_O_WISP
	.byte -1

AI_CV_Encore_EncouragedMovesToEncore:
	.byte EFFECT_ATTACK_UP
	.byte EFFECT_ATTACK_UP_2
	.byte EFFECT_ATTRACT
	.byte EFFECT_BELLY_DRUM
	.byte EFFECT_CAMOUFLAGE
	.byte EFFECT_CHARGE
	.byte EFFECT_CONVERSION
	.byte EFFECT_CONVERSION_2
	.byte EFFECT_COUNTER
	.byte EFFECT_CURSE
	.byte EFFECT_DEFENSE_UP
	.byte EFFECT_DEFENSE_UP_2
	.byte EFFECT_DISABLE
	.byte EFFECT_DREAM_EATER
	.byte EFFECT_ENDURE
	.byte EFFECT_FAKE_OUT
	.byte EFFECT_FOCUS_ENERGY
	.byte EFFECT_FOLLOW_ME
	.byte EFFECT_FORESIGHT
	.byte EFFECT_FUTURE_SIGHT
	.byte EFFECT_GRUDGE
	.byte EFFECT_HAIL
	.byte EFFECT_HAZE
	.byte EFFECT_HEAL_BELL
	.byte EFFECT_HELPING_HAND
	.byte EFFECT_IMPRISON
	.byte EFFECT_INGRAIN
	.byte EFFECT_KNOCK_OFF
	.byte EFFECT_LIGHT_SCREEN
	.byte EFFECT_LOCK_ON
	.byte EFFECT_MEAN_LOOK
	.byte EFFECT_MIRROR_COAT
	.byte EFFECT_MIST
	.byte EFFECT_MUD_SPORT
	.byte EFFECT_NIGHTMARE
	.byte EFFECT_PERISH_SONG
	.byte EFFECT_PROTECT
	.byte EFFECT_PSYCH_UP
	.byte EFFECT_RAIN_DANCE
	.byte EFFECT_RAPID_SPIN
	.byte EFFECT_RECYCLE
	.byte EFFECT_REFRESH
	.byte EFFECT_REST
	.byte EFFECT_ROAR
	.byte EFFECT_ROLE_PLAY
	.byte EFFECT_SAFEGUARD
	.byte EFFECT_SANDSTORM
	.byte EFFECT_SKILL_SWAP
	.byte EFFECT_SPECIAL_ATTACK_UP
	.byte EFFECT_SPECIAL_ATTACK_UP_2
	.byte EFFECT_SPECIAL_DEFENSE_UP
	.byte EFFECT_SPECIAL_DEFENSE_UP_2
	.byte EFFECT_SPIT_UP
	.byte EFFECT_SPLASH
	.byte EFFECT_STOCKPILE
	.byte EFFECT_SUNNY_DAY
	.byte EFFECT_SWALLOW
	.byte EFFECT_TELEPORT
	.byte EFFECT_THIEF
	.byte EFFECT_TORMENT
	.byte EFFECT_TRICK
	.byte EFFECT_WATER_SPORT
	.byte -1

AI_CV_Substitute_PinchBerries:
	.byte HOLD_EFFECT_ATTACK_UP
	.byte HOLD_EFFECT_DEFENSE_UP
	.byte HOLD_EFFECT_RANDOM_STAT_UP
	.byte HOLD_EFFECT_SPEED_UP
	.byte HOLD_EFFECT_SP_ATTACK_UP
	.byte HOLD_EFFECT_SP_DEFENSE_UP
	.byte -1

AI_CV_Endure_PinchBerries:
	.byte HOLD_EFFECT_ATTACK_UP
	.byte HOLD_EFFECT_DEFENSE_UP
	.byte HOLD_EFFECT_RANDOM_STAT_UP
	.byte HOLD_EFFECT_SP_ATTACK_UP
	.byte HOLD_EFFECT_SP_DEFENSE_UP
	.byte -1

AI_CV_Trick_EffectsToEncourage:
	.byte HOLD_EFFECT_CHOICE_BAND
	.byte HOLD_EFFECT_MACHO_BRACE
	.byte -1

AI_Thief_EncourageItemsToSteal:
	.byte HOLD_EFFECT_ATTACK_UP
	.byte HOLD_EFFECT_CONFUSE_BITTER
	.byte HOLD_EFFECT_CONFUSE_DRY
	.byte HOLD_EFFECT_CONFUSE_SOUR
	.byte HOLD_EFFECT_CONFUSE_SPICY
	.byte HOLD_EFFECT_CONFUSE_SWEET
	.byte HOLD_EFFECT_CURE_SLP
	.byte HOLD_EFFECT_CURE_STATUS
	.byte HOLD_EFFECT_DEEP_SEA_SCALE
	.byte HOLD_EFFECT_DEEP_SEA_TOOTH
	.byte HOLD_EFFECT_DEFENSE_UP
	.byte HOLD_EFFECT_EVASION_UP
	.byte HOLD_EFFECT_LEFTOVERS
	.byte HOLD_EFFECT_LIGHT_BALL
	.byte HOLD_EFFECT_RANDOM_STAT_UP
	.byte HOLD_EFFECT_RESTORE_HP
	.byte HOLD_EFFECT_SPEED_UP
	.byte HOLD_EFFECT_SP_ATTACK_UP
	.byte HOLD_EFFECT_SP_DEFENSE_UP
	.byte HOLD_EFFECT_THICK_CLUB
	.byte -1

AI_CV_ChangeSelfAbility_AbilitiesToEncourage:
	.byte ABILITY_ARENA_TRAP
	.byte ABILITY_CHLOROPHYLL
	.byte ABILITY_FLASH_FIRE
	.byte ABILITY_GUTS
	.byte ABILITY_HUGE_POWER
	.byte ABILITY_LEVITATE
	.byte ABILITY_MAGNET_PULL
	.byte ABILITY_MARVEL_SCALE
	.byte ABILITY_NATURAL_CURE
	.byte ABILITY_PURE_POWER
	.byte ABILITY_RAIN_DISH
	.byte ABILITY_SHED_SKIN
	.byte ABILITY_SPEED_BOOST
	.byte ABILITY_SWIFT_SWIM
	.byte ABILITY_THICK_FAT
	.byte ABILITY_VOLT_ABSORB
	.byte ABILITY_WATER_ABSORB
	.byte -1

AI_CV_DontCopyAbilities:
	.byte ABILITY_TRUANT
	.byte ABILITY_WONDER_GUARD
	.byte -1

AI_CV_Recycle_ItemsToEncourage:
	.byte ITEM_CHESTO_BERRY
	.byte ITEM_LEPPA_BERRY
	.byte ITEM_LUM_BERRY
	.byte ITEM_STARF_BERRY
	.byte -1

AI_CV_DefenseUp_EffList:
	.byte EFFECT_BULK_UP
	.byte EFFECT_DEFENSE_UP
	.byte EFFECT_DEFENSE_UP_2
	.byte EFFECT_DEFENSE_CURL
	.byte -1

AI_CV_SpDefUp_EffList:
	.byte EFFECT_CALM_MIND
	.byte EFFECT_SPECIAL_DEFENSE_UP
	.byte EFFECT_SPECIAL_DEFENSE_UP_2
	.byte -1

AI_CV_AtkDown_EffList:
	.byte EFFECT_ATTACK_DOWN
	.byte EFFECT_ATTACK_DOWN_2
	.byte EFFECT_TICKLE
	.byte -1

AI_CV_Stats_EffList:
	.byte EFFECT_COSMIC_POWER
	.byte EFFECT_DRAGON_DANCE
	.byte EFFECT_MINIMIZE
	.byte EFFECT_ATTACK_UP
	.byte EFFECT_ATTACK_UP_2
	.byte EFFECT_EVASION_UP
	.byte EFFECT_EVASION_UP_2
	.byte EFFECT_SPECIAL_ATTACK_UP
	.byte EFFECT_SPECIAL_ATTACK_UP_2
	.byte EFFECT_ACCURACY_DOWN
	.byte EFFECT_ACCURACY_DOWN_2
	.byte EFFECT_DEFENSE_DOWN
	.byte EFFECT_DEFENSE_DOWN_2
	.byte EFFECT_SPECIAL_DEFENSE_DOWN
	.byte EFFECT_SPECIAL_DEFENSE_DOWN_2
	.byte -1

AI_CV_ModifySpeed:
	.byte EFFECT_SPEED_DOWN
	.byte EFFECT_SPEED_DOWN_2
	.byte EFFECT_SPEED_UP
	.byte EFFECT_SPEED_UP_2
	.byte -1

AI_CV_Heal_EffList:
	.byte EFFECT_RESTORE_HP
	.byte EFFECT_SOFTBOILED
	.byte EFFECT_SWALLOW
	.byte -1

AI_CV_HealWeather_EffList:
	.byte EFFECT_MOONLIGHT
	.byte EFFECT_MORNING_SUN
	.byte EFFECT_SYNTHESIS
	.byte -1

AI_CV_ClearStatus_EffList:
	.byte EFFECT_HEAL_BELL
	.byte EFFECT_REFRESH
	.byte -1

AI_CV_ParalyzeHit_EffList:
	.byte EFFECT_PARALYZE_HIT
	.byte EFFECT_SECRET_POWER
	.byte EFFECT_THUNDER
	.byte -1

AI_CV_ToxicAndSeed:
	.byte EFFECT_LEECH_SEED
	.byte EFFECT_POISON
	.byte EFFECT_TOXIC
	.byte -1

AI_CV_ChargeUp_EffList:
	.byte EFFECT_RAZOR_WIND
	.byte EFFECT_SKULL_BASH
	.byte EFFECT_SKY_ATTACK
	.byte -1

AI_CV_MultiHit_EffList:
	.byte EFFECT_DOUBLE_HIT
	.byte EFFECT_MULTI_HIT
	.byte EFFECT_TRIPLE_KICK
	.byte EFFECT_TWINEEDLE
	.byte -1

AI_CV_Trap_EffList:
	.byte EFFECT_MEAN_LOOK
	.byte EFFECT_TRAP
	.byte -1

AI_CV_ChangeAbility_EffList:
	.byte EFFECT_ROLE_PLAY
	.byte EFFECT_SKILL_SWAP
	.byte -1

AI_CV_Recoil_EffList:
	.byte EFFECT_DOUBLE_EDGE
	.byte EFFECT_RECOIL
	.byte -1

AI_CV_SelfKO_EffList:
	.byte EFFECT_EXPLOSION
	.byte EFFECT_MEMENTO
	.byte -1

AI_CV_Conversions_EffList:
	.byte EFFECT_CONVERSION
	.byte EFFECT_CONVERSION_2
	.byte -1

AI_CV_DiscouragedEffList:
	.byte EFFECT_ASSIST
	.byte EFFECT_CHARGE
	.byte EFFECT_METRONOME
	.byte EFFECT_MIST
	.byte EFFECT_PRESENT
	.byte EFFECT_RAGE
	.byte EFFECT_SPITE
	.byte EFFECT_UPROAR
	.byte -1

AI_CV_LockedIn_EffList:
	.byte EFFECT_RAGE
	.byte EFFECT_RAMPAGE
	.byte EFFECT_ROLLOUT
	.byte EFFECT_UPROAR
	.byte -1

AI_CV_FireWeak:
	.byte TYPE_BUG
	.byte TYPE_GRASS
	.byte TYPE_ICE
	.byte TYPE_STEEL
	.byte -1

AI_CV_StrongVsFire:
	.byte TYPE_GROUND
	.byte TYPE_ROCK
	.byte TYPE_WATER
	.byte -1

AI_CV_StrongVsWater:
	.byte TYPE_ELECTRIC
	.byte TYPE_GRASS
	.byte -1

AI_TTF_DiscouragedEffList:
	.byte EFFECT_FOCUS_PUNCH
	.byte EFFECT_PRESENT
	.byte -1

AI_TTF_PriorityMoves:
	.byte EFFECT_FAKE_OUT
	.byte EFFECT_QUICK_ATTACK
	.byte -1

AI_TTF_LessPreferred:
	.byte EFFECT_DOUBLE_EDGE
	.byte EFFECT_RAGE
	.byte EFFECT_RAMPAGE
	.byte EFFECT_RAZOR_WIND
	.byte EFFECT_RECHARGE
	.byte EFFECT_RECOIL
	.byte EFFECT_RECOIL_IF_MISS
	.byte EFFECT_ROLLOUT
	.byte EFFECT_SKULL_BASH
	.byte EFFECT_SKY_ATTACK
	.byte EFFECT_SOLAR_BEAM
	.byte EFFECT_UPROAR
	.byte -1

AI_TTF_NoWhiteHerb:
	.byte EFFECT_OVERHEAT
	.byte EFFECT_SUPERPOWER
	.byte -1

AI_DoubleBattle_GroundWeak:
	.byte TYPE_ELECTRIC
	.byte TYPE_FIRE
	.byte TYPE_POISON
	.byte TYPE_ROCK
	.byte -1

AI_CantMimic_EffList:
	.byte EFFECT_METRONOME
	.byte EFFECT_MIMIC
	.byte EFFECT_SKETCH
	.byte EFFECT_TRANSFORM
	.byte -1

AI_DontMirror_EffList:
	.byte EFFECT_MIMIC
	.byte EFFECT_MIRROR_MOVE
	.byte EFFECT_SKETCH
	.byte EFFECT_TRANSFORM
	.byte -1

AI_UseInSleep:
	.byte EFFECT_SNORE
	.byte EFFECT_SLEEP_TALK
	.byte -1

AI_Sleep_EffList:
	.byte EFFECT_SLEEP
	.byte EFFECT_YAWN
	.byte -1

AI_SpAtkDown_EffList:
	.byte EFFECT_SPECIAL_ATTACK_DOWN
	.byte EFFECT_SPECIAL_ATTACK_DOWN_2
	.byte -1

AI_SpeedDown_EffList:
	.byte EFFECT_SPEED_DOWN
	.byte EFFECT_SPEED_DOWN_2
	.byte -1

AI_EvasionDown_EffList:
	.byte EFFECT_EVASION_DOWN
	.byte EFFECT_EVASION_DOWN_2
	.byte -1

AI_SleepImmuneAbility:
	.byte ABILITY_INSOMNIA
	.byte ABILITY_VITAL_SPIRIT
	.byte -1

AI_PhysicalTypeList:
	.byte TYPE_BUG
	.byte TYPE_FIGHTING
	.byte TYPE_FLYING
	.byte TYPE_GHOST
	.byte TYPE_GROUND
	.byte TYPE_NORMAL
	.byte TYPE_POISON
	.byte TYPE_ROCK
	.byte TYPE_STEEL
	.byte -1

AI_SpecialTypeList:
	.byte TYPE_DARK
	.byte TYPE_DRAGON
	.byte TYPE_ELECTRIC
	.byte TYPE_FIRE
	.byte TYPE_GRASS
	.byte TYPE_ICE
	.byte TYPE_PSYCHIC
	.byte TYPE_WATER
	.byte -1

AI_PoisoningImmune:
	.byte TYPE_POISON
	.byte TYPE_STEEL
	.byte -1
