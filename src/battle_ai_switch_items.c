#include "global.h"
#include "battle.h"
#include "battle_anim.h"
#include "battle_controllers.h"
#include "battle_main.h"
#include "data.h"
#include "pokemon.h"
#include "random.h"
#include "util.h"
#include "constants/abilities.h"
#include "constants/battle_move_effects.h"
#include "constants/item_effects.h"
#include "constants/items.h"
#include "constants/moves.h"

// this file's functions+
static bool8 ShouldUseItem(void);

static bool8 ShouldSwitchIfPerishSong(void)
{
    if (gStatuses3[gActiveBattler] & STATUS3_PERISH_SONG
        && gDisableStructs[gActiveBattler].perishSongTimer == 0)
    {
        *(gBattleStruct->AI_monToSwitchIntoId + gActiveBattler) = PARTY_SIZE;
        BtlController_EmitTwoReturnValues(BUFFER_B, B_ACTION_SWITCH, 0);
        return TRUE;
    }
    else
    {
        return FALSE;
    }
}

static bool8 ShouldSwitchIfWonderGuard(void)
{
    u8 opposingPosition;
    u8 opposingBattler;
    u8 moveFlags;
    s32 i, j;
    s32 firstId;
    s32 lastId; // + 1
    struct Pokemon *party = NULL;
    u16 move;

    if (gBattleTypeFlags & BATTLE_TYPE_DOUBLE)
        return FALSE;

    opposingPosition = BATTLE_OPPOSITE(GetBattlerPosition(gActiveBattler));

    if (gBattleMons[GetBattlerAtPosition(opposingPosition)].ability != ABILITY_WONDER_GUARD)
        return FALSE;

    // Check if Pokemon has a super effective move.
    for (opposingBattler = GetBattlerAtPosition(opposingPosition), i = 0; i < MAX_MON_MOVES; i++)
    {
        move = gBattleMons[gActiveBattler].moves[i];
        if (move == MOVE_NONE)
            continue;

        moveFlags = AI_TypeCalc(move, gBattleMons[opposingBattler].species, gBattleMons[opposingBattler].ability);
        if (moveFlags & MOVE_RESULT_SUPER_EFFECTIVE)
            return FALSE;
    }

    // Get party information.
    if (gBattleTypeFlags & (BATTLE_TYPE_TWO_OPPONENTS | BATTLE_TYPE_TOWER_LINK_MULTI))
    {
        if ((gActiveBattler & BIT_FLANK) == B_FLANK_LEFT)
            firstId = 0, lastId = PARTY_SIZE / 2;
        else
            firstId = PARTY_SIZE / 2, lastId = PARTY_SIZE;
    }
    else
    {
        firstId = 0, lastId = PARTY_SIZE;
    }

    if (GetBattlerSide(gActiveBattler) == B_SIDE_PLAYER)
        party = gPlayerParty;
    else
        party = gEnemyParty;

    // Find a Pokemon in the party that has a super effective move.
    for (i = firstId; i < lastId; i++)
    {
        if (GetMonData(&party[i], MON_DATA_HP) == 0)
            continue;
        if (GetMonData(&party[i], MON_DATA_SPECIES_OR_EGG) == SPECIES_NONE)
            continue;
        if (GetMonData(&party[i], MON_DATA_SPECIES_OR_EGG) == SPECIES_EGG)
            continue;
        if (i == gBattlerPartyIndexes[gActiveBattler])
            continue;

        GetMonData(&party[i], MON_DATA_SPECIES); // Unused return value.
        GetMonData(&party[i], MON_DATA_ABILITY_NUM); // Unused return value.

        for (opposingBattler = GetBattlerAtPosition(opposingPosition), j = 0; j < MAX_MON_MOVES; j++)
        {
            move = GetMonData(&party[i], MON_DATA_MOVE1 + j);
            if (move == MOVE_NONE)
                continue;

            moveFlags = AI_TypeCalc(move, gBattleMons[opposingBattler].species, gBattleMons[opposingBattler].ability);
            if (moveFlags & MOVE_RESULT_SUPER_EFFECTIVE && Random() % 3 < 2)
            {
                // We found a mon.
                *(gBattleStruct->AI_monToSwitchIntoId + gActiveBattler) = i;
                BtlController_EmitTwoReturnValues(BUFFER_B, B_ACTION_SWITCH, 0);
                return TRUE;
            }
        }
    }

    return FALSE; // There is not a single Pokemon in the party that has a super effective move against a mon with Wonder Guard.
}

static bool8 ShouldSwitchIfNaturalCure(void)
{
    if (gBattleMons[gActiveBattler].ability != ABILITY_NATURAL_CURE)
        return FALSE;
    if (gBattleMons[gActiveBattler].hp < gBattleMons[gActiveBattler].maxHP / 2)
        return FALSE;
    if (!(gBattleMons[gActiveBattler].status1 & STATUS1_ANY))
        return FALSE;

    if (Random() % 7 < 2)
    {
        *(gBattleStruct->AI_monToSwitchIntoId + gActiveBattler) = PARTY_SIZE;
        BtlController_EmitTwoReturnValues(BUFFER_B, B_ACTION_SWITCH, 0);
        return TRUE;
    }

    return FALSE;
}

static bool8 ShouldSwitchIfLowScore(void)
{
    s32 i, j;
    s8 currentScore;
    u8 *dynamicMoveType;
    u8 damageVar, consideredEffect, teamHasRapidSpin, aiCanFaint, targetCanFaint, isFaster, hasPriority, hasWishCombo, BatonPassChosen;
    u16 hp, species;
    s8 maxScore = 0;
    s8 threshold = 94;

    //Frequently referenced information
    u8 currentHP = gBattleMons[gActiveBattler].hp;
    u8 item = gBattleMons[gActiveBattler].item;
    u8 lastUsedEffect = gBattleMoves[gLastMoves[gActiveBattler]].effect;
    u8 turnCount = gBattleResults.battleTurnCounter;
    u8 aiFirstTurn = gDisableStructs[gActiveBattler].isFirstTurn;

    //Arrays
    u8 statBoostingEffects[] = {EFFECT_ATTACK_UP, EFFECT_ATTACK_UP_2, EFFECT_SPECIAL_ATTACK_UP, EFFECT_SPECIAL_ATTACK_UP_2, EFFECT_BELLY_DRUM, EFFECT_BULK_UP, EFFECT_CALM_MIND, EFFECT_CURSE, EFFECT_DRAGON_DANCE};
    u8 shedinjaKOEffects[] = {EFFECT_CONFUSE, EFFECT_FLATTER, EFFECT_HAIL, EFFECT_LEECH_SEED, EFFECT_POISON, EFFECT_SANDSTORM, EFFECT_SWAGGER, EFFECT_TOXIC, EFFECT_WILL_O_WISP};
    u8 healingEffects[] = {EFFECT_MOONLIGHT, EFFECT_MORNING_SUN, EFFECT_SYNTHESIS, EFFECT_WISH, EFFECT_REST, EFFECT_SOFTBOILED, EFFECT_RESTORE_HP};

    //Initialising booleans
    teamHasRapidSpin = aiCanFaint = targetCanFaint = isFaster = hasPriority = hasWishCombo = BatonPassChosen = FALSE;

    DebugPrintf("Checking ShouldSwitchIfLowScore.");

    //Note that increasing the threshold encourages switching, and the reverse

    //Slightly lower threshold in the first few turns of the battle
    if(turnCount < 5 && aiFirstTurn && !(gDisableStructs[gBattlerTarget].isFirstTurn))
        {
            threshold += -5 + turnCount;
            DebugPrintf("First turn score lowering applied. Threshold now: %d",(signed char) threshold);
        }

    //Check badly poisoned
    if ((gBattleMons[gActiveBattler].status1 & STATUS1_TOXIC_COUNTER) >= STATUS1_TOXIC_TURN(3))
        {
            threshold += 4 + Random() % 3;

            if ((gBattleMons[gActiveBattler].status1 & STATUS1_TOXIC_COUNTER) >= STATUS1_TOXIC_TURN(5))
                {
                    threshold += 3;
                }

            if ((gBattleMons[gActiveBattler].status1 & STATUS1_TOXIC_COUNTER) >= STATUS1_TOXIC_TURN(7))
                {
                    threshold += 3;
                }

            DebugPrintf("Badly poisoned check applied. Threshold now: %d",(signed char) threshold);
        }

    //Check cursed or nightmared
    if (gBattleMons[gActiveBattler].status2 & (STATUS2_CURSED | STATUS2_NIGHTMARE))
        {
            threshold += 8;
            DebugPrintf("Curse / Nightmare check applied. Threshold now: %d",(signed char) threshold);
        }

    //Check substitute
    if (gBattleMons[gActiveBattler].status2 & (STATUS2_SUBSTITUTE))
        {
            threshold += -2;
            DebugPrintf("Substitute for self check applied. Threshold now: %d",(signed char) threshold);
        }

    //Check seeded
    if ((gStatuses3[gActiveBattler] & STATUS3_LEECHSEED))
        {
            threshold += 6;

            if(Random() % 6)
                {
                    threshold += 1;
                }

            DebugPrintf("Leech seed check applied. Threshold now: %d",(signed char) threshold);
        }

    //Check yawned, with no sleep removal item
    if ((gStatuses3[gActiveBattler] & STATUS3_YAWN)
        && item != ITEM_CHESTO_BERRY
        && item != ITEM_LUM_BERRY)
        {
            threshold += 6;

            if(Random() % 6)
                {
                    threshold += 2;
                }

            DebugPrintf("Yawn check applied. Threshold now: %d",(signed char) threshold);
        }

    //Check encored
    if (gDisableStructs[gActiveBattler].encoredMove != MOVE_NONE && item != ITEM_CHOICE_BAND)
        {
            threshold += 5 + Random() % 3;
            DebugPrintf("Encore check applied. Threshold now: %d",(signed char) threshold);
        }

    //Discourage staying in when choice locked, especially when locked into sleep talk
    if(!(aiFirstTurn) && item == ITEM_CHOICE_BAND)
        {
            threshold += 5;

            if(lastUsedEffect == EFFECT_SLEEP_TALK)
                {
                    threshold += 30;
                }

            DebugPrintf("CB check applied. Threshold now: %d",(signed char) threshold);
        }

    //Check for stat boosting moves on the opponent's side
    for (i = 0; i < MAX_MON_MOVES; i++)
        {
            for (j = 0; j < ARRAY_COUNT(statBoostingEffects); j++)
                {
                    if (gBattleMoves[gBattleMons[gBattlerTarget].moves[i]].effect == statBoostingEffects[j])
                        {
                            threshold += -2 - Random() % 4;
                            break;
                        }
                }
        }

    DebugPrintf("Stat boosting move check applied. Threshold now: %d",(signed char) threshold);

    //Check for the move substitute on the opponent's side
    for (i = 0; i < MAX_MON_MOVES; i++)
        {
            if (gBattleMoves[gBattleMons[gBattlerTarget].moves[i]].effect == EFFECT_SUBSTITUTE)
                {
                    threshold += -3 - Random() % 3;
                    break;
                }
        }

    DebugPrintf("Substitute for target check applied. Threshold now: %d",(signed char) threshold);

    //check if spikes are up
    if (gSideStatuses[B_SIDE_OPPONENT] & SIDE_STATUS_SPIKES)
        {
            threshold += -2 - Random() % 3;
            DebugPrintf("Spikes check applied. Threshold now: %d",(signed char) threshold);
        }

    //Check if own stat levels are above the minimum
    for (i = 1; i < NUM_BATTLE_STATS; i++)
        {
            if (gBattleMons[gActiveBattler].statStages[i] > DEFAULT_STAT_STAGE)
            {
                    threshold += -4 - Random() % 2;
                    break;
            }
        }

    DebugPrintf("Stat level check applied. Threshold now: %d. Next, checking if AI can faint.",(signed char) threshold);

    //Check if AI can faint
    damageVar = 0;
    gDynamicBasePower = 0;
    dynamicMoveType = &gBattleStruct->dynamicMoveType;
    *dynamicMoveType = 0;
    gBattleScripting.dmgMultiplier = 1;
    gMoveResultFlags = 0;
    gCritMultiplier = 1;

    for (i = 0; i < MAX_MON_MOVES; i++)
        {
            gCurrentMove = gBattleMons[gBattlerTarget].moves[i];

            if (gCurrentMove != MOVE_NONE)
                {
                    AI_CalcDmg(gBattlerTarget, gActiveBattler);
                    TypeCalc(gCurrentMove, gBattlerTarget, gActiveBattler);

                    // Get the highest battle move damage
                    if (damageVar < gBattleMoveDamage)
                        damageVar = gBattleMoveDamage;
                }
        }

    // Apply a higher likely damage roll
    damageVar = damageVar * 95 / 100;

    if (currentHP <= damageVar)
        {
            aiCanFaint = TRUE;
        }

    DebugPrintf("Result: %d",aiCanFaint);

    // Check if target can faint
    damageVar = 0;
    gDynamicBasePower = 0;
    dynamicMoveType = &gBattleStruct->dynamicMoveType;
    *dynamicMoveType = 0;
    gBattleScripting.dmgMultiplier = 1;
    gMoveResultFlags = 0;
    gCritMultiplier = 1;

    for (i = 0; i < MAX_MON_MOVES; i++)
        {
            gCurrentMove = gBattleMons[gActiveBattler].moves[i];

            if (gCurrentMove != MOVE_NONE)
                {
                    AI_CalcDmg(gActiveBattler, gBattlerTarget);
                    TypeCalc(gCurrentMove, gActiveBattler, gBattlerTarget);

                    // Get the highest battle move damage
                    if (damageVar < gBattleMoveDamage)
                        damageVar = gBattleMoveDamage;
                }
        }

    // Apply a higher likely damage roll
    damageVar = damageVar * 95 / 100;

    if (gBattleMons[gBattlerTarget].hp <= damageVar)
        {
            targetCanFaint = TRUE;
        }

    DebugPrintf("Result: %d",targetCanFaint);

    //Check if AI is faster
    if ((GetWhoStrikesFirst(gBattlerTarget, gActiveBattler, TRUE)))
        {
            isFaster = TRUE;
        }

    //check for certain moves
    for (i = 0; i < MAX_MON_MOVES; i++)
        {
            if (consideredEffect == EFFECT_QUICK_ATTACK
                || consideredEffect == EFFECT_ENDURE
                || (consideredEffect == EFFECT_PROTECT
                    && lastUsedEffect != EFFECT_PROTECT)
                || (consideredEffect == EFFECT_FAKE_OUT
                    && aiFirstTurn)
            )
                {
                    hasPriority = TRUE;
                }

            if (lastUsedEffect == EFFECT_WISH
                || consideredEffect == EFFECT_SEMI_INVULNERABLE)
                {
                    hasWishCombo = TRUE;
                }
        }

    DebugPrintf("isFaster: %d, hasPriority: %d",isFaster,hasPriority);

    //If the AI can faint, with other checks to ensure switching isn't a terrible idea
    if(aiCanFaint
        && hasPriority == FALSE
        && !(gBattleMons[gActiveBattler].status1 & STATUS1_FREEZE)
        && !(gBattleMons[gActiveBattler].status2 & STATUS2_SUBSTITUTE)
        && !(isFaster
            && (targetCanFaint
                || hasWishCombo
                || (Random() % 3))))
    {
        //Increase the threshold more when at a higher HP. Also a random factor
        threshold += 4 + ((currentHP - 17) / 14) + Random() % 2;

        DebugPrintf("AI can faint. Threshold now: %d",(signed char) threshold);

        //If asleep
        if ((gBattleMons[gActiveBattler].status1 & STATUS1_SLEEP) > STATUS1_SLEEP_TURN(1))
            {
                threshold += -5;

                if(lastUsedEffect == EFFECT_SLEEP_TALK
                    || lastUsedEffect == EFFECT_SNORE)
                    {
                        threshold += -3;
                    }

                DebugPrintf("AI asleep. Threshold now: %d",(signed char) threshold);
            }

        //If otherwise statused
        if(gBattleMons[gActiveBattler].status1 & (STATUS1_POISON | STATUS1_BURN | STATUS1_PARALYSIS | STATUS1_TOXIC_POISON))
            {
                threshold += -3;
                DebugPrintf("AI statused. Threshold now: %d",(signed char) threshold);
            }

        //If the AI has a healing move
        for (i = 0; i < MAX_MON_MOVES; i++)
            {
                for (j = 0; j < ARRAY_COUNT(healingEffects); j++)
                    {
                        if (gBattleMoves[gBattleMons[gActiveBattler].moves[i]].effect == healingEffects[j])
                            {
                                if (isFaster)
                                    {
                                        threshold += -4;
                                        break;
                                    }
                                else
                                    {
                                        threshold += 4;
                                        break;
                                    }
                            }
                    }
            }

        DebugPrintf("Checked for healing moves. Threshold now: %d",(signed char) threshold);
    }

    //Additional checks for shedinja
    if(gBattleMons[gActiveBattler].ability == ABILITY_WONDER_GUARD)
        {
            DebugPrintf("Shedinja found!");

            //Check if it can faint
            if(aiCanFaint == TRUE)
                {
                    threshold += 30;
                    DebugPrintf("Shedinja can faint. Threshold now: %d",(signed char) threshold);
                }

            //Check for status moves which KO Shedinja on the opposing side
            for (i = 0; i < MAX_MON_MOVES; i++)
                {
                    for (j = 0; j < ARRAY_COUNT(shedinjaKOEffects); j++)
                        {
                            if (gBattleMoves[gBattleMons[gBattlerTarget].moves[i]].effect == shedinjaKOEffects[j])
                                {
                                    threshold += 30;
                                    break;
                                }
                        }
                }

            DebugPrintf("Dangerous status moves searched for. Threshold now: %d",(signed char) threshold);

            //Check if shedinja is confused
            if ((gBattleMons[gActiveBattler].status2 & STATUS2_CONFUSION))
                {
                    threshold += 10;
                    DebugPrintf("Shedinja confused. Threshold now: %d",(signed char) threshold);
                }

            //check weather
            if (gBattleWeather & (B_WEATHER_HAIL | B_WEATHER_SANDSTORM))
                {
                    threshold += 30;
                    DebugPrintf("Deadly weather found. Threshold now: %d",(signed char) threshold);
                }

            //check party for rapid spin:
            for (i = 0; i < PARTY_SIZE; i++)
                {
                    species = GetMonData(&gEnemyParty[i], MON_DATA_SPECIES);
                    hp = GetMonData(&gEnemyParty[i], MON_DATA_HP);

                    if (species != SPECIES_NONE && species != SPECIES_EGG && hp != 0 && teamHasRapidSpin == FALSE)
                        {
                            //check each move
                            for (j = 0; j < MAX_MON_MOVES; j++)
                                {
                                    if (gBattleMoves[GetMonData(&gEnemyParty[i], MON_DATA_MOVE1 + j)].effect == EFFECT_RAPID_SPIN)
                                        {
                                            teamHasRapidSpin = TRUE;
                                        }
                                }
                        }
                }

            DebugPrintf("Checked for rapid spin. Result: %d",teamHasRapidSpin);

            if (teamHasRapidSpin == FALSE)
                {
                    //check if the target has spikes
                    for (i = 0; i < MAX_MON_MOVES; i++)
                        {
                            if (gBattleMoves[gBattleMons[gBattlerTarget].moves[i]].effect == EFFECT_SPIKES)
                                {
                                    threshold = -70;
                                    break;
                                }
                        }

                    //check if spikes are up
                    if (gSideStatuses[B_SIDE_OPPONENT] & SIDE_STATUS_SPIKES)
                        {
                            threshold = -70;
                        }

                    DebugPrintf("Spikes checks applied. Threshold now: %d",(signed char) threshold);
                }
        }

    DebugPrintf("Threshold set for %d is %d.",gBattleMons[gActiveBattler].species,(signed char) threshold);

    // Find the score of the move being used by the AI
    for (i = 0; i < MAX_MON_MOVES; i++)
    {
        currentScore = gBattleResources->ai->score[i];

        if (maxScore < currentScore)
        {
            maxScore = currentScore;
            BatonPassChosen = FALSE;
        }

        //Find whether Baton Pass could have been chosen, so the AI does not switch if it has chosen to use Baton Pass
        if (maxScore == currentScore && gBattleMoves[gBattleMons[gActiveBattler].moves[i]].effect == EFFECT_BATON_PASS)
            BatonPassChosen = TRUE;
    }

    DebugPrintf("Max score found for %d is %d.",gBattleMons[gActiveBattler].species,maxScore);

    if ((maxScore + Random() % 2) < threshold && !(BatonPassChosen))
    {
        *(gBattleStruct->AI_monToSwitchIntoId + gActiveBattler) = PARTY_SIZE;
        BtlController_EmitTwoReturnValues(BUFFER_B, B_ACTION_SWITCH, 0);
        return TRUE;
    }
    else
    {
        return FALSE;
    }
}

static bool8 ShouldSwitch(void)
{
    u8 battlerIn1, battlerIn2;
    u8 *activeBattlerPtr; // Needed to match.
    s32 firstId;
    s32 lastId; // + 1
    struct Pokemon *party;
    s32 i;
    s32 availableToSwitch;

    DebugPrintf("Checking if %d should switch.",gBattleMons[gActiveBattler].species);

    if (gBattleMons[*(activeBattlerPtr = &gActiveBattler)].status2 & (STATUS2_WRAPPED | STATUS2_ESCAPE_PREVENTION))
        return FALSE;
    if (gStatuses3[gActiveBattler] & STATUS3_ROOTED)
        return FALSE;
    if (ABILITY_ON_OPPOSING_FIELD(gActiveBattler, ABILITY_SHADOW_TAG))
        return FALSE;
    if (ABILITY_ON_OPPOSING_FIELD(gActiveBattler, ABILITY_ARENA_TRAP) & !(IS_BATTLER_OF_TYPE(gActiveBattler, TYPE_FLYING)) & !(ABILITY_ON_OWN_FIELD(gActiveBattler, ABILITY_LEVITATE)))
        return FALSE;
    if (ABILITY_ON_OPPOSING_FIELD(gActiveBattler, ABILITY_MAGNET_PULL) & IS_BATTLER_OF_TYPE(gActiveBattler, TYPE_STEEL))
        return FALSE;
    if (gBattleTypeFlags & BATTLE_TYPE_ARENA)
        return FALSE;

    availableToSwitch = 0;
    if (gBattleTypeFlags & BATTLE_TYPE_DOUBLE)
    {
        battlerIn1 = *activeBattlerPtr;
        if (gAbsentBattlerFlags & gBitTable[GetBattlerAtPosition(BATTLE_PARTNER(GetBattlerPosition(*activeBattlerPtr)))])
            battlerIn2 = *activeBattlerPtr;
        else
            battlerIn2 = GetBattlerAtPosition(BATTLE_PARTNER(GetBattlerPosition(*activeBattlerPtr)));
    }
    else
    {
        battlerIn1 = *activeBattlerPtr;
        battlerIn2 = *activeBattlerPtr;
    }

    if (gBattleTypeFlags & (BATTLE_TYPE_TWO_OPPONENTS | BATTLE_TYPE_TOWER_LINK_MULTI))
    {
        if ((gActiveBattler & BIT_FLANK) == B_FLANK_LEFT)
            firstId = 0, lastId = PARTY_SIZE / 2;
        else
            firstId = PARTY_SIZE / 2, lastId = PARTY_SIZE;
    }
    else
    {
        firstId = 0, lastId = PARTY_SIZE;
    }

    if (GetBattlerSide(gActiveBattler) == B_SIDE_PLAYER)
        party = gPlayerParty;
    else
        party = gEnemyParty;

    for (i = firstId; i < lastId; i++)
    {
        if (GetMonData(&party[i], MON_DATA_HP) == 0)
            continue;
        if (GetMonData(&party[i], MON_DATA_SPECIES_OR_EGG) == SPECIES_NONE)
            continue;
        if (GetMonData(&party[i], MON_DATA_SPECIES_OR_EGG) == SPECIES_EGG)
            continue;
        if (i == gBattlerPartyIndexes[battlerIn1])
            continue;
        if (i == gBattlerPartyIndexes[battlerIn2])
            continue;
        if (i == *(gBattleStruct->monToSwitchIntoId + battlerIn1))
            continue;
        if (i == *(gBattleStruct->monToSwitchIntoId + battlerIn2))
            continue;

        availableToSwitch++;
    }

    if (availableToSwitch == 0)
        return FALSE;
    if (ShouldSwitchIfWonderGuard())
        return TRUE;
    if (ShouldSwitchIfPerishSong())
        return TRUE;
    if (ShouldSwitchIfNaturalCure())
        return TRUE;
    if (ShouldSwitchIfLowScore())
        return TRUE;

    return FALSE;
}

void AI_TrySwitchOrUseItem(void)
{
    struct Pokemon *party;
    u8 battlerIn1, battlerIn2;
    s32 firstId;
    s32 lastId; // + 1
    u8 battlerIdentity = GetBattlerPosition(gActiveBattler);

    DebugPrintf("Runnung AI_TrySwitchOrUseItem.");

    if (GetBattlerSide(gActiveBattler) == B_SIDE_PLAYER)
        party = gPlayerParty;
    else
        party = gEnemyParty;

    if (gBattleTypeFlags & BATTLE_TYPE_TRAINER)
    {
        DebugPrintf("Checking ShouldSwitch.");

        if (ShouldSwitch())
        {
            DebugPrintf("ShouldSwitch returned TRUE.");

            if (*(gBattleStruct->AI_monToSwitchIntoId + gActiveBattler) == PARTY_SIZE)
            {
                s32 monToSwitchId = GetMostSuitableMonToSwitchInto();
                if (monToSwitchId == PARTY_SIZE)
                {
                    if (!(gBattleTypeFlags & BATTLE_TYPE_DOUBLE))
                    {
                        battlerIn1 = GetBattlerAtPosition(battlerIdentity);
                        battlerIn2 = battlerIn1;
                    }
                    else
                    {
                        battlerIn1 = GetBattlerAtPosition(battlerIdentity);
                        battlerIn2 = GetBattlerAtPosition(BATTLE_PARTNER(battlerIdentity));
                    }

                    if (gBattleTypeFlags & (BATTLE_TYPE_TWO_OPPONENTS | BATTLE_TYPE_TOWER_LINK_MULTI))
                    {
                        if ((gActiveBattler & BIT_FLANK) == B_FLANK_LEFT)
                            firstId = 0, lastId = PARTY_SIZE / 2;
                        else
                            firstId = PARTY_SIZE / 2, lastId = PARTY_SIZE;
                    }
                    else
                    {
                        firstId = 0, lastId = PARTY_SIZE;
                    }

                    for (monToSwitchId = firstId; monToSwitchId < lastId; monToSwitchId++)
                    {
                        if (GetMonData(&party[monToSwitchId], MON_DATA_HP) == 0)
                            continue;
                        if (monToSwitchId == gBattlerPartyIndexes[battlerIn1])
                            continue;
                        if (monToSwitchId == gBattlerPartyIndexes[battlerIn2])
                            continue;
                        if (monToSwitchId == *(gBattleStruct->monToSwitchIntoId + battlerIn1))
                            continue;
                        if (monToSwitchId == *(gBattleStruct->monToSwitchIntoId + battlerIn2))
                            continue;

                        break;
                    }
                }

                *(gBattleStruct->AI_monToSwitchIntoId + gActiveBattler) = monToSwitchId;
            }

            *(gBattleStruct->monToSwitchIntoId + gActiveBattler) = *(gBattleStruct->AI_monToSwitchIntoId + gActiveBattler);
            return;
        }
        else if (ShouldUseItem())
        {
            return;
        }
    }

    BtlController_EmitTwoReturnValues(BUFFER_B, B_ACTION_USE_MOVE, BATTLE_OPPOSITE(gActiveBattler) << 8);
}

static void ModulateByTypeEffectiveness(u8 atkType, u8 defType1, u8 defType2, u8 *var)
{
    s32 i = 0;

    while (TYPE_EFFECT_ATK_TYPE(i) != TYPE_ENDTABLE)
    {
        if (TYPE_EFFECT_ATK_TYPE(i) == TYPE_FORESIGHT)
        {
            i += 3;
            continue;
        }
        else if (TYPE_EFFECT_ATK_TYPE(i) == atkType)
        {
            // Check type1.
            if (TYPE_EFFECT_DEF_TYPE(i) == defType1)
                *var = (*var * TYPE_EFFECT_MULTIPLIER(i)) / TYPE_MUL_NORMAL;
            // Check type2.
            if (TYPE_EFFECT_DEF_TYPE(i) == defType2 && defType1 != defType2)
                *var = (*var * TYPE_EFFECT_MULTIPLIER(i)) / TYPE_MUL_NORMAL;
        }
        i += 3;
    }
}

u8 GetMostSuitableMonToSwitchInto(void)
{
    u8 opposingBattler;
    s32 bestDmg;
    u8 bestMonId;
    u8 battlerIn1, battlerIn2;
    s32 firstId;
    s32 lastId;
    struct Pokemon *party;
    s32 i, j;
    u8 invalidMons;
    u16 move;
    u16 consideredSpeed, bestSpeed;

    if (*(gBattleStruct->monToSwitchIntoId + gActiveBattler) != PARTY_SIZE)
        return *(gBattleStruct->monToSwitchIntoId + gActiveBattler);
    if (gBattleTypeFlags & BATTLE_TYPE_ARENA)
        return gBattlerPartyIndexes[gActiveBattler] + 1;

    if (gBattleTypeFlags & BATTLE_TYPE_DOUBLE)
    {
        battlerIn1 = gActiveBattler;
        if (gAbsentBattlerFlags & gBitTable[GetBattlerAtPosition(BATTLE_PARTNER(GetBattlerPosition(gActiveBattler)))])
            battlerIn2 = gActiveBattler;
        else
            battlerIn2 = GetBattlerAtPosition(BATTLE_PARTNER(GetBattlerPosition(gActiveBattler)));

        opposingBattler = Random() & BIT_FLANK;
        if (gAbsentBattlerFlags & gBitTable[opposingBattler])
            opposingBattler ^= BIT_FLANK;
    }
    else
    {
        opposingBattler = GetBattlerAtPosition(BATTLE_OPPOSITE(GetBattlerPosition(gActiveBattler)));
        battlerIn1 = gActiveBattler;
        battlerIn2 = gActiveBattler;
    }

    if (gBattleTypeFlags & (BATTLE_TYPE_TWO_OPPONENTS | BATTLE_TYPE_TOWER_LINK_MULTI))
    {
        if ((gActiveBattler & BIT_FLANK) == B_FLANK_LEFT)
            firstId = 0, lastId = PARTY_SIZE / 2;
        else
            firstId = PARTY_SIZE / 2, lastId = PARTY_SIZE;
    }
    else
    {
        firstId = 0, lastId = PARTY_SIZE;
    }

    if (GetBattlerSide(gActiveBattler) == B_SIDE_PLAYER)
        party = gPlayerParty;
    else
        party = gEnemyParty;

    bestSpeed = 0;

    // Find the fastest Pokemon
    for (i = firstId; i < lastId; i++)
    {
        if ((u16)(GetMonData(&party[i], MON_DATA_SPECIES)) == SPECIES_NONE)
            continue;
        if (GetMonData(&party[i], MON_DATA_HP) == 0)
            continue;
        if (gBattlerPartyIndexes[battlerIn1] == i)
            continue;
        if (gBattlerPartyIndexes[battlerIn2] == i)
            continue;
        if (i == *(gBattleStruct->monToSwitchIntoId + battlerIn1))
            continue;
        if (i == *(gBattleStruct->monToSwitchIntoId + battlerIn2))
            continue;

        consideredSpeed = GetMonData(&party[i], MON_DATA_SPEED);

        if (consideredSpeed > bestSpeed)
        {
            bestSpeed = consideredSpeed;
            bestMonId = i;
        }
    }

    return bestMonId;
}

static u8 GetAI_ItemType(u8 itemId, const u8 *itemEffect) // NOTE: should take u16 as item Id argument
{
    if (itemId == ITEM_FULL_RESTORE)
        return AI_ITEM_FULL_RESTORE;
    else if (itemEffect[4] & ITEM4_HEAL_HP)
        return AI_ITEM_HEAL_HP;
    else if (itemEffect[3] & ITEM3_STATUS_ALL)
        return AI_ITEM_CURE_CONDITION;
    else if (itemEffect[0] & (ITEM0_DIRE_HIT | ITEM0_X_ATTACK) || itemEffect[1] != 0 || itemEffect[2] != 0)
        return AI_ITEM_X_STAT;
    else if (itemEffect[3] & ITEM3_GUARD_SPEC)
        return AI_ITEM_GUARD_SPEC;
    else
        return AI_ITEM_NOT_RECOGNIZABLE;
}

static bool8 ShouldUseItem(void)
{
    struct Pokemon *party;
    s32 i;
    u8 validMons = 0;
    bool8 shouldUse = FALSE;

    if (gBattleTypeFlags & BATTLE_TYPE_INGAME_PARTNER && GetBattlerPosition(gActiveBattler) == B_POSITION_PLAYER_RIGHT)
        return FALSE;

    if (GetBattlerSide(gActiveBattler) == B_SIDE_PLAYER)
        party = gPlayerParty;
    else
        party = gEnemyParty;

    for (i = 0; i < PARTY_SIZE; i++)
    {
        if (GetMonData(&party[i], MON_DATA_HP) != 0
            && GetMonData(&party[i], MON_DATA_SPECIES_OR_EGG) != SPECIES_NONE
            && GetMonData(&party[i], MON_DATA_SPECIES_OR_EGG) != SPECIES_EGG)
        {
            validMons++;
        }
    }

    for (i = 0; i < MAX_TRAINER_ITEMS; i++)
    {
        u16 item;
        const u8 *itemEffects;
        u8 paramOffset;
        u8 battlerSide;

        if (i != 0 && validMons > (gBattleResources->battleHistory->itemsNo - i) + 1)
            continue;
        item = gBattleResources->battleHistory->trainerItems[i];
        if (item == ITEM_NONE)
            continue;
        if (gItemEffectTable[item - ITEM_POTION] == NULL)
            continue;

        if (item == ITEM_ENIGMA_BERRY)
            itemEffects = gSaveBlock1Ptr->enigmaBerry.itemEffect;
        else
            itemEffects = gItemEffectTable[item - ITEM_POTION];

        *(gBattleStruct->AI_itemType + gActiveBattler / 2) = GetAI_ItemType(item, itemEffects);

        switch (*(gBattleStruct->AI_itemType + gActiveBattler / 2))
        {
        case AI_ITEM_FULL_RESTORE:
            if (gBattleMons[gActiveBattler].hp >= gBattleMons[gActiveBattler].maxHP / 4)
                break;
            if (gBattleMons[gActiveBattler].hp == 0)
                break;
            shouldUse = TRUE;
            break;
        case AI_ITEM_HEAL_HP:
            paramOffset = GetItemEffectParamOffset(item, 4, ITEM4_HEAL_HP);
            if (paramOffset == 0)
                break;
            if (gBattleMons[gActiveBattler].hp == 0)
                break;
            if (gBattleMons[gActiveBattler].hp < gBattleMons[gActiveBattler].maxHP / 4 || gBattleMons[gActiveBattler].maxHP - gBattleMons[gActiveBattler].hp > itemEffects[paramOffset])
                shouldUse = TRUE;
            break;
        case AI_ITEM_CURE_CONDITION:
            *(gBattleStruct->AI_itemFlags + gActiveBattler / 2) = 0;
            if (itemEffects[3] & ITEM3_SLEEP && gBattleMons[gActiveBattler].status1 & STATUS1_SLEEP)
            {
                *(gBattleStruct->AI_itemFlags + gActiveBattler / 2) |= (1 << AI_HEAL_SLEEP);
                shouldUse = TRUE;
            }
            if (itemEffects[3] & ITEM3_POISON && (gBattleMons[gActiveBattler].status1 & STATUS1_POISON
                                               || gBattleMons[gActiveBattler].status1 & STATUS1_TOXIC_POISON))
            {
                *(gBattleStruct->AI_itemFlags + gActiveBattler / 2) |= (1 << AI_HEAL_POISON);
                shouldUse = TRUE;
            }
            if (itemEffects[3] & ITEM3_BURN && gBattleMons[gActiveBattler].status1 & STATUS1_BURN)
            {
                *(gBattleStruct->AI_itemFlags + gActiveBattler / 2) |= (1 << AI_HEAL_BURN);
                shouldUse = TRUE;
            }
            if (itemEffects[3] & ITEM3_FREEZE && gBattleMons[gActiveBattler].status1 & STATUS1_FREEZE)
            {
                *(gBattleStruct->AI_itemFlags + gActiveBattler / 2) |= (1 << AI_HEAL_FREEZE);
                shouldUse = TRUE;
            }
            if (itemEffects[3] & ITEM3_PARALYSIS && gBattleMons[gActiveBattler].status1 & STATUS1_PARALYSIS)
            {
                *(gBattleStruct->AI_itemFlags + gActiveBattler / 2) |= (1 << AI_HEAL_PARALYSIS);
                shouldUse = TRUE;
            }
            if (itemEffects[3] & ITEM3_CONFUSION && gBattleMons[gActiveBattler].status2 & STATUS2_CONFUSION)
            {
                *(gBattleStruct->AI_itemFlags + gActiveBattler / 2) |= (1 << AI_HEAL_CONFUSION);
                shouldUse = TRUE;
            }
            break;
        case AI_ITEM_X_STAT:
            *(gBattleStruct->AI_itemFlags + gActiveBattler / 2) = 0;
            if (gDisableStructs[gActiveBattler].isFirstTurn == 0)
                break;
            if (itemEffects[0] & ITEM0_X_ATTACK)
                *(gBattleStruct->AI_itemFlags + gActiveBattler / 2) |= (1 << AI_X_ATTACK);
            if (itemEffects[1] & ITEM1_X_DEFEND)
                *(gBattleStruct->AI_itemFlags + gActiveBattler / 2) |= (1 << AI_X_DEFEND);
            if (itemEffects[1] & ITEM1_X_SPEED)
                *(gBattleStruct->AI_itemFlags + gActiveBattler / 2) |= (1 << AI_X_SPEED);
            if (itemEffects[2] & ITEM2_X_SPATK)
                *(gBattleStruct->AI_itemFlags + gActiveBattler / 2) |= (1 << AI_X_SPATK);
            if (itemEffects[2] & ITEM2_X_ACCURACY)
                *(gBattleStruct->AI_itemFlags + gActiveBattler / 2) |= (1 << AI_X_ACCURACY);
            if (itemEffects[0] & ITEM0_DIRE_HIT)
                *(gBattleStruct->AI_itemFlags + gActiveBattler / 2) |= (1 << AI_DIRE_HIT);
            shouldUse = TRUE;
            break;
        case AI_ITEM_GUARD_SPEC:
            battlerSide = GetBattlerSide(gActiveBattler);
            if (gDisableStructs[gActiveBattler].isFirstTurn != 0 && gSideTimers[battlerSide].mistTimer == 0)
                shouldUse = TRUE;
            break;
        case AI_ITEM_NOT_RECOGNIZABLE:
            return FALSE;
        }

        if (shouldUse)
        {
            BtlController_EmitTwoReturnValues(BUFFER_B, B_ACTION_USE_ITEM, 0);
            *(gBattleStruct->chosenItem + (gActiveBattler / 2) * 2) = item;
            gBattleResources->battleHistory->trainerItems[i] = ITEM_NONE;
            return shouldUse;
        }
    }

    return FALSE;
}
