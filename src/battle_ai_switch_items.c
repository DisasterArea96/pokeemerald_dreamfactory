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

#define AI_THINKING_STRUCT ((struct AI_ThinkingStruct *)(gBattleResources->ai))

// this file's functions
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

static bool8 ShouldSwitchIfLowScore(void)
{
    s32 i, j, k;
    s32 firstId, lastId;
    s8 currentScore;
    u16 currentMove2, hp, species;
    u8 *activeBattlerPtr;
    u8 *dynamicMoveType;
    u8 aiCanFaint, BatonPassChosen, chosenSwitchIn, consideredEffect, damageVar;
    u8 hasPriority, hasWishCombo;
    u8 teamHasRapidSpin;
    u8 targetCanFaint;
    u8 moveFlags;
    u8 battlerIn1, battlerIn2;
    u8 monAbility, monSpecies, monType1, monType2;
    u8 canKoShedinja, isFaster, statusImmune;
    u8 hasHaze, hasPerish, hasPhysicalAttack, hasRapidSpin, hasRoar, hasSleepAtk, hasWW;
    u8 targetHasIngrain, targetHasPhysicalAttack, targetHasRapidSpin;
    u8 targetNeutralEffectiveFound, targetNotVeryEffectiveFound, targetSuperEffectiveFound;
    u8 targetCanKoShedinja, targetMoveType, targetMovesChecked, targetStatsRaised;
    u8 targetAsleep, targetLastMove, targetLockedMove, targetPartySize;
    u8 neutralEffectiveFound, superEffectiveFound;
    s8 switchInScore = 0;
    s8 maxSwitchInScore = 0;
    s8 maxScore = 0;
    s8 threshold = 91;

    /*

    Some comments on the numbers:

    Consider the following scenario
    The AI has a reasonable first turn move, this would have a score of about 100-102
    Suppose there is a pokemon in the back which resists all of the active pokemon's attacks.
    Its score would be 10.
    Suppose the AI can faint. This is +9-10 to the threshold, so a threshold of 100-101

    The check is max move score + 0-1 < threshold + max switch score to trigger a switch.
    In this case:
    102 + 0-1 < 100-101 + 10, so 102-103 < 110-111
    Guaranteeing a switch.

    Suppose the best pokemon in the back is neutral to the pokemon that is active, We want it to sometimes come in when all pokemon are at full
    100-102 + 0-1 < 100-101 + 2, so 100-103 < 102-103
    i.e. 25% chance if the AI has a good attack, or a significantly higher chance if it doesnt

    */

    //Initialising arrays
    u8 statBoostingEffects[] = {EFFECT_ATTACK_UP, EFFECT_ATTACK_UP_2, EFFECT_SPECIAL_ATTACK_UP, EFFECT_SPECIAL_ATTACK_UP_2, EFFECT_BELLY_DRUM, EFFECT_BULK_UP, EFFECT_CALM_MIND, EFFECT_CURSE, EFFECT_DRAGON_DANCE};
    u8 shedinjaKOEffects[] = {EFFECT_CONFUSE, EFFECT_FLATTER, EFFECT_HAIL, EFFECT_LEECH_SEED, EFFECT_POISON, EFFECT_SANDSTORM, EFFECT_SWAGGER, EFFECT_TOXIC, EFFECT_WILL_O_WISP};
    u8 healingEffects[] = {EFFECT_MOONLIGHT, EFFECT_MORNING_SUN, EFFECT_SYNTHESIS, EFFECT_WISH, EFFECT_REST, EFFECT_SOFTBOILED, EFFECT_RESTORE_HP};

    //Fixed, frequently referenced variables
    u8 aiFirstTurn = gDisableStructs[gActiveBattler].isFirstTurn;
    u8 currentHP = gBattleMons[gActiveBattler].hp;
    u8 item = gBattleMons[gActiveBattler].item;
    u8 lastUsedEffect = gBattleMoves[gLastMoves[gActiveBattler]].effect;

    //Initialising variables
    aiCanFaint = BatonPassChosen = hasPriority = hasWishCombo = isFaster = targetPartySize = targetCanFaint = teamHasRapidSpin = 0;

    DebugPrintf("Checking ShouldSwitchIfLowScore.");

    //Note that increasing the threshold encourages switching

    //Check badly poisoned. equal chance of +0, +1, +2 threshold for each turn of badly poisoned. Expected gain in threshold is equal to the number of turns poisoned
    for (i = 1; (gBattleMons[gActiveBattler].status1 & STATUS1_TOXIC_COUNTER) >= STATUS1_TOXIC_TURN(i); i++)
        {
            threshold += Random() % 3;
        }

    DebugPrintf("Badly poisoned check applied. Threshold now: %d",(signed char) threshold);

    //Check cursed or nightmared
    if (gBattleMons[gActiveBattler].status2 & (STATUS2_CURSED | STATUS2_NIGHTMARE))
        threshold += 8;

    DebugPrintf("Curse / Nightmare check applied. Threshold now: %d",(signed char) threshold);

    //Check substitute
    if (gBattleMons[gActiveBattler].status2 & (STATUS2_SUBSTITUTE))
        threshold += -2;

    DebugPrintf("Substitute for self check applied. Threshold now: %d",(signed char) threshold);

    //Check seeded
    if (gStatuses3[gActiveBattler] & STATUS3_LEECHSEED)
        {
            threshold += 5;

            if(!(Random() % 5))
                threshold += 3;
        }

    DebugPrintf("Leech seed check applied. Threshold now: %d",(signed char) threshold);

    //Check yawned, with no sleep removal item
    if (gStatuses3[gActiveBattler] & STATUS3_YAWN
        && item != ITEM_CHESTO_BERRY
        && item != ITEM_LUM_BERRY
        && gBattleMons[gActiveBattler].ability != ABILITY_NATURAL_CURE
    )
        {
            threshold += 6;

            if(Random() % 6)
                threshold += 2;
        }

    DebugPrintf("Yawn check applied. Threshold now: %d",(signed char) threshold);

    //Check encored
    if (gDisableStructs[gActiveBattler].encoredMove != MOVE_NONE
        && item != ITEM_CHOICE_BAND
    )
        threshold += 5 + Random() % 3;

    DebugPrintf("Encore check applied. Threshold now: %d",(signed char) threshold);

    //Check for natural cure & status combo
    if (gBattleMons[gActiveBattler].ability == ABILITY_NATURAL_CURE
        && gBattleMons[gActiveBattler].status1 & STATUS1_ANY
    )
        threshold += 8;

    DebugPrintf("Natural cure check applied. Threshold now: %d",(signed char) threshold);

    //Discourage staying in when choice locked, especially when locked into sleep talk
    if (!(aiFirstTurn)
        && item == ITEM_CHOICE_BAND)
        {
            threshold += 5;

            if(lastUsedEffect == EFFECT_SLEEP_TALK)
                threshold += 30;
        }

    DebugPrintf("CB check applied. Threshold now: %d",(signed char) threshold);

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
        threshold += -2 - Random() % 3;

    DebugPrintf("Spikes check applied. Threshold now: %d",(signed char) threshold);

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

    if (gBattleMons[gActiveBattler].ability == ABILITY_WONDER_GUARD)
        {
            for (i = 0; i < MAX_MON_MOVES; i++)
                {
                    gCurrentMove = gBattleMons[gBattlerTarget].moves[i];

                    moveFlags = AI_TypeCalc(gCurrentMove, gActiveBattler, ABILITY_WONDER_GUARD);

                    // If the opponent has an attacking move that can KO shedinja
                    if (gBattleMoves[gBattleMons[gBattlerTarget].moves[i]].power > 0
                        && moveFlags & MOVE_RESULT_SUPER_EFFECTIVE
                    )
                        damageVar = 100;

                    //Check each effect that can KO shedinja
                    for (j = 0; j < ARRAY_COUNT(shedinjaKOEffects); j++)
                        {
                            if (gBattleMoves[gBattleMons[gBattlerTarget].moves[i]].effect == shedinjaKOEffects[j])
                                damageVar = 100;
                        }
                }
        }
    else
        {
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
        }

    // Apply a higher likely damage roll
    damageVar = damageVar * 95 / 100;

    if (currentHP <= damageVar)
        aiCanFaint = TRUE;

    DebugPrintf("aiCanFaint: %d",aiCanFaint);

    // Check if target can faint
    damageVar = 0;
    gDynamicBasePower = 0;
    dynamicMoveType = &gBattleStruct->dynamicMoveType;
    *dynamicMoveType = 0;
    gBattleScripting.dmgMultiplier = 1;
    gMoveResultFlags = 0;
    gCritMultiplier = 1;

    if (gBattleMons[gBattlerTarget].ability == ABILITY_WONDER_GUARD)
        {
            for (i = 0; i < MAX_MON_MOVES; i++)
                {
                    gCurrentMove = gBattleMons[gActiveBattler].moves[i];

                    moveFlags = AI_TypeCalc(gCurrentMove, gBattlerTarget, ABILITY_WONDER_GUARD);

                    // If the player an attacking move that can KO shedinja
                    if (gBattleMoves[gBattleMons[gActiveBattler].moves[i]].power > 0
                        && moveFlags & MOVE_RESULT_SUPER_EFFECTIVE
                    )
                        damageVar = 100;

                    //Check each effect that can KO shedinja
                    for (j = 0; j < ARRAY_COUNT(shedinjaKOEffects); j++)
                        {
                            if (gBattleMoves[gBattleMons[gActiveBattler].moves[i]].effect == shedinjaKOEffects[j])
                                damageVar = 100;
                        }
                }
        }
    else
        {
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
        }

    // Apply a higher likely damage roll
    damageVar = damageVar * 95 / 100;

    if (gBattleMons[gBattlerTarget].hp <= damageVar)
        targetCanFaint = TRUE;

    DebugPrintf("targetCanFaint: %d",targetCanFaint);

    //Check if AI is faster
    if (GetWhoStrikesFirst(gBattlerTarget, gActiveBattler, TRUE))
        isFaster = TRUE;

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
                hasPriority = TRUE;

            if (lastUsedEffect == EFFECT_WISH
                || consideredEffect == EFFECT_SEMI_INVULNERABLE)
                hasWishCombo = TRUE;
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
                || Random() % 3))
    )
        {
            //Increase the threshold more when at a higher HP. Also a random factor
            threshold += 4 + ((currentHP - 17) / 14) + Random() % 2;

            DebugPrintf("AI can faint. Threshold now: %d",(signed char) threshold);

            //If asleep
            if ((gBattleMons[gActiveBattler].status1 & STATUS1_SLEEP) > STATUS1_SLEEP_TURN(1))
                {
                    threshold += -5;

                    //Discourage switching after using these moves, since it resets the sleep counter!
                    if(lastUsedEffect == EFFECT_SLEEP_TALK
                        || lastUsedEffect == EFFECT_SNORE
                    )
                        threshold += -3;

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
                                        threshold += -4;
                                    else
                                        threshold += 4;

                                    break;
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

                    if (species != SPECIES_NONE
                        && species != SPECIES_EGG
                        && hp != 0
                        && teamHasRapidSpin == FALSE
                    )
                        {
                            //check each move
                            for (j = 0; j < MAX_MON_MOVES; j++)
                                {
                                    if (gBattleMoves[GetMonData(&gEnemyParty[i], MON_DATA_MOVE1 + j)].effect == EFFECT_RAPID_SPIN)
                                        teamHasRapidSpin = TRUE;
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
                        threshold = -70;

                    DebugPrintf("Spikes checks applied. Threshold now: %d",(signed char) threshold);
                }
        }

    //Final Threshold is set
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
        if (maxScore == currentScore
            && gBattleMoves[gBattleMons[gActiveBattler].moves[i]].effect == EFFECT_BATON_PASS
        )
            BatonPassChosen = TRUE;
    }

    //Final Max Score is set
    DebugPrintf("Max score found for %d is %d.",gBattleMons[gActiveBattler].species,maxScore);

    //Set targetPartySize variable
    for (i = 0; i < PARTY_SIZE; i++)
    {
        if (GetMonData(&gPlayerParty[i], MON_DATA_HP) == 0)
            continue;
        if (GetMonData(&gPlayerParty[i], MON_DATA_SPECIES_OR_EGG) == SPECIES_NONE)
            continue;
        if (GetMonData(&gPlayerParty[i], MON_DATA_SPECIES_OR_EGG) == SPECIES_EGG)
            continue;
        if (i == gBattlerPartyIndexes[gBattlerTarget])
            continue;
        if (i == *(gBattleStruct->monToSwitchIntoId + gBattlerTarget))
            continue;

        targetPartySize++;
    }

    //Set other variables describing the target
    targetLastMove = gLastMoves[gBattlerTarget];
    targetLockedMove = gLockedMoves[gBattlerTarget];
    targetStatsRaised = 0;

    //If asleep & not waking up this turn, ~80% chance we set targetAsleep and change checks executed further in the code
    if ((gBattleMons[gBattlerTarget].status1 & STATUS1_SLEEP) > STATUS1_SLEEP_TURN(1)
        && !(Random() % 5)
    )
        {
            targetAsleep = 1;
        }
    else
        {
            targetAsleep = 0;
        }

    //Check if opponent's stat levels are above the minimum
    for (j = 1; j < NUM_BATTLE_STATS; j++)
        {
            if (gBattleMons[gBattlerTarget].statStages[j] > DEFAULT_STAT_STAGE)
            {
                    targetStatsRaised = 1;
                    break;
            }
        }

    for (i = 0; i < PARTY_SIZE; i++)
    {
        // Skip over invalid options
        if ((u16)(GetMonData(&gEnemyParty[i], MON_DATA_SPECIES)) == SPECIES_NONE)
            continue;
        if (GetMonData(&gEnemyParty[i], MON_DATA_HP) == 0)
            continue;
        if (gBattlerPartyIndexes[gActiveBattler] == i)
            continue;
        if (i == *(gBattleStruct->monToSwitchIntoId + gActiveBattler))
            continue;

        //Initialise all pokemon-specific variables (candidate pokemon)
        hasHaze = hasPerish = hasRoar = hasPhysicalAttack = targetHasPhysicalAttack = hasWW = 0;
        neutralEffectiveFound = superEffectiveFound = 0;
        canKoShedinja = 0;
        statusImmune = 0;

        //Initialise all pokemon-specific variables (target)
        targetNeutralEffectiveFound = targetNotVeryEffectiveFound = targetSuperEffectiveFound = 0;
        targetCanKoShedinja = 0;
        targetHasIngrain = 0;
        targetHasRapidSpin = 0;
        targetMovesChecked = 0;
        targetMoveType = TYPE_NONE;

        //Information about the current Pokemon being considered
        monSpecies = GetMonData(&gEnemyParty[i], MON_DATA_SPECIES);
        monAbility = GetAbilityBySpecies(monSpecies, GetMonData(&gEnemyParty[i], MON_DATA_ABILITY_NUM));
        monType1 = gSpeciesInfo[monSpecies].types[0];
        monType2 = gSpeciesInfo[monSpecies].types[1];

        //If the candidate Pokemon has trace, then use the target's ability in logic
        if (monAbility == ABILITY_TRACE)
            monAbility = gBattleMons[gBattlerTarget].ability;

        //Set an initial score based on the HP% divided by 15. This gives a range of 0-6
        switchInScore = (GetMonData(&gEnemyParty[i], MON_DATA_HP) * 100)
                        / (GetMonData(&gEnemyParty[i], MON_DATA_MAX_HP) * 15);

        //Add a baseline of 19, to prevent underflows. 23 will be deducted from score at the end
        switchInScore += 19;

        //Initial score set
        DebugPrintf("switch-in score initialised at %d for %d.",switchInScore,GetMonData(&gEnemyParty[i], MON_DATA_SPECIES));

        //If the AI is faster than the opponent, boost the score slightly
        if (GetMonData(&gEnemyParty[i], MON_DATA_SPEED) > gBattleMons[gBattlerTarget].speed)
            switchInScore += 1;

        //Check if safeguard is up, the candidate Pokemon has Natural Cure, or is already statused
        if (gSideStatuses[B_SIDE_OPPONENT] & SIDE_STATUS_SAFEGUARD
            || monAbility == ABILITY_NATURAL_CURE
            || GetMonData(&gEnemyParty[i], MON_DATA_STATUS) & STATUS1_ANY
        )
            statusImmune = 1;

        //Loop through the moves of the candidate pokemon and set related variables
        for (j = 0; j < MAX_MON_MOVES; j++)
            {
                //Get the move ID
                gCurrentMove = GetMonData(&gEnemyParty[i], MON_DATA_MOVE1 + j);

                //if refresh or rest
                if (gCurrentMove == MOVE_REST
                    || gCurrentMove == MOVE_REFRESH
                )
                    statusImmune = 1;

                //If the move does damage
                if (gBattleMoves[gCurrentMove].power > 0)
                    {
                        //Check whether the mon has a physical attack which is affected meaningfully by burn
                        if(IS_TYPE_PHYSICAL(gBattleMoves[gCurrentMove].type)
                            && gBattleMoves[gCurrentMove].effect != EFFECT_HIDDEN_POWER
                            && gBattleMoves[gCurrentMove].effect != EFFECT_LEVEL_DAMAGE
                            && gBattleMoves[gCurrentMove].effect != EFFECT_RAPID_SPIN
                            && gBattleMoves[gCurrentMove].effect != EFFECT_SNORE
                            && gBattleMoves[gCurrentMove].effect != EFFECT_SONICBOOM
                            && gBattleMoves[gCurrentMove].effect != EFFECT_SUPER_FANG
                            && gBattleMoves[gCurrentMove].effect != EFFECT_THIEF
                            && gBattleMoves[gCurrentMove].effect != EFFECT_TRAP)
                            hasPhysicalAttack = 1;

                        //Pull the flags
                        moveFlags = AI_TypeCalc(gCurrentMove, gBattlerTarget, gBattleMons[gBattlerTarget].ability);

                        //Set flags for super effective & neutrally effective attacks
                        if (moveFlags & MOVE_RESULT_SUPER_EFFECTIVE)
                            superEffectiveFound = 1;

                        if (!(moveFlags & MOVE_RESULT_SUPER_EFFECTIVE)
                            && !(moveFlags & MOVE_RESULT_NOT_VERY_EFFECTIVE)
                            && !(moveFlags & MOVE_RESULT_DOESNT_AFFECT_FOE)
                        )
                            neutralEffectiveFound = 1;
                    }

                if (gBattleMoves[gCurrentMove].effect == EFFECT_RAPID_SPIN)
                    hasRapidSpin = 1;

                //Check for snore & sleep talk
                if (gBattleMoves[gCurrentMove].effect == EFFECT_SNORE
                    || gBattleMoves[gCurrentMove].effect == EFFECT_SLEEP_TALK
                )
                    hasSleepAtk = 1;

                //If the opponent is shedinja, check if there is a move can KO it.
                if (gBattleMons[gBattlerTarget].ability == ABILITY_WONDER_GUARD
                    && gCurrentMove != MOVE_NONE
                    && gCurrentMove != MOVE_UNAVAILABLE
                )
                    {
                        moveFlags = AI_TypeCalc(gCurrentMove, gBattlerTarget, ABILITY_WONDER_GUARD);

                        // If the player an attacking move that can KO shedinja
                        if (gBattleMoves[gBattleMons[gActiveBattler].moves[i]].power > 0
                            && moveFlags & MOVE_RESULT_SUPER_EFFECTIVE
                        )
                            canKoShedinja = 1;

                        //Check each effect that can KO shedinja
                        for (j = 0; j < ARRAY_COUNT(shedinjaKOEffects); j++)
                            {
                                if (gBattleMoves[gBattleMons[gActiveBattler].moves[i]].effect == shedinjaKOEffects[j])
                                   canKoShedinja = 1;
                            }
                    }

                if (gCurrentMove == MOVE_ROAR)
                    hasRoar = 1;

                if (gCurrentMove == MOVE_WHIRLWIND)
                    hasWW = 1;

                if (gCurrentMove == MOVE_HAZE)
                    hasHaze = 1;

                if (gCurrentMove == MOVE_PERISH_SONG)
                    hasPerish = 1;
            }

        //If the opponent has choice band and has attacked, the AI can take advantage of it
        if (gBattleMons[gBattlerTarget].item == ITEM_CHOICE_BAND
            && targetLastMove != MOVE_NONE
            && targetLastMove != MOVE_UNAVAILABLE
        )
            {
                //Check if the move is a status move or an attack
                if (gBattleMoves[targetLastMove].power == 0)
                    {
                        if (targetLastMove == MOVE_TOXIC)
                            {
                                if (monType1 == TYPE_POISON
                                    || monType1 == TYPE_STEEL
                                    || monType2 == TYPE_POISON
                                    || monType2 == TYPE_STEEL
                                    || monAbility == ABILITY_IMMUNITY
                                )
                                    {
                                        switchInScore += 12;
                                    }
                                else
                                    {
                                        if (statusImmune)
                                            switchInScore += 5;
                                    }
                            }

                        if (targetLastMove == MOVE_GLARE)
                            {
                                if (monType1 == TYPE_GHOST
                                    || monType2 == TYPE_GHOST
                                    || monAbility == ABILITY_LIMBER
                                )
                                    {
                                        switchInScore += 12;
                                    }
                                else
                                    {
                                        if (statusImmune)
                                            switchInScore += 5;
                                    }
                            }

                        if (targetLastMove == MOVE_THUNDER_WAVE)
                            {
                                if (monType1 == TYPE_GROUND
                                    || monType2 == TYPE_GROUND
                                    || monAbility == ABILITY_LIMBER
                                )
                                    {
                                        switchInScore += 12;
                                    }
                                else
                                    {
                                        if (statusImmune)
                                            switchInScore += 5;
                                    }
                            }

                        if (targetLastMove == MOVE_STUN_SPORE)
                            {
                                if (monAbility == ABILITY_LIMBER)
                                    {
                                        switchInScore += 12;
                                    }
                                else
                                    {
                                        if (statusImmune)
                                            switchInScore += 5;
                                    }
                            }

                        // special handling for wisp, as we want to discourage physical attackers coming in especially
                        if (targetLastMove == MOVE_WILL_O_WISP)
                            {
                                if (monType1 == TYPE_FIRE
                                    || monType2 == TYPE_FIRE
                                    || monAbility == ABILITY_WATER_VEIL
                                )
                                    {
                                        switchInScore += 12;
                                    }
                                else
                                    {
                                        if (statusImmune)
                                            {
                                                switchInScore += 5;
                                            }
                                        else
                                            {
                                                //If the candidate mon has a physical attack, make it less likely to be switched in
                                                if (hasPhysicalAttack)
                                                    switchInScore -= 5;
                                            }
                                    }
                            }

                        if (gBattleMoves[targetLastMove].effect == EFFECT_SLEEP)
                            {
                                if (monAbility == ABILITY_INSOMNIA
                                    || monAbility == ABILITY_VITAL_SPIRIT
                                )
                                    {
                                        switchInScore += 12;
                                    }
                                else
                                    {
                                        //If status immune, early bird, or has snore/sleep talk
                                        if (statusImmune
                                            || monAbility == ABILITY_EARLY_BIRD
                                            || hasSleepAtk
                                        )
                                            switchInScore += 5;
                                    }
                            }

                        if (targetLastMove == MOVE_LEECH_SEED
                            && (monType1 == TYPE_GRASS
                                || monType2 == TYPE_GRASS
                                || monAbility == ABILITY_LIQUID_OOZE)
                        )
                            switchInScore += 12;

                        targetMovesChecked = 1;
                    }
                else
                    {
                        // Get the move type to perform extra checks that TypeCalc misses. Ironically, it's all special types, so mostly relevant with TrickBand
                        targetMoveType = gBattleMoves[gCurrentMove].type;

                        //If they are locked into a fire-type move
                        if (targetMoveType == TYPE_FIRE
                            && monAbility == ABILITY_FLASH_FIRE
                        )
                            {
                                switchInScore += 12;
                                targetMovesChecked = 1;
                            }

                        //If they are locked into a water-type move
                        if (targetMoveType == TYPE_WATER
                            && monAbility == ABILITY_WATER_ABSORB
                        )
                            {
                                switchInScore += 12;
                                targetMovesChecked = 1;
                            }

                        //If they are locked into a electric-type move
                        if (targetMoveType == TYPE_ELECTRIC
                            && monAbility == ABILITY_VOLT_ABSORB
                        )
                            {
                                switchInScore += 12;
                                targetMovesChecked = 1;
                            }

                        //If the target has a physical attack
                        if (IS_TYPE_PHYSICAL(targetMoveType)
                            && gBattleMoves[gCurrentMove].effect != EFFECT_HIDDEN_POWER
                            && gBattleMoves[gCurrentMove].effect != EFFECT_LEVEL_DAMAGE
                            && gBattleMoves[gCurrentMove].effect != EFFECT_RAPID_SPIN
                            && gBattleMoves[gCurrentMove].effect != EFFECT_SNORE
                            && gBattleMoves[gCurrentMove].effect != EFFECT_SONICBOOM
                            && gBattleMoves[gCurrentMove].effect != EFFECT_SUPER_FANG
                            && gBattleMoves[gCurrentMove].effect != EFFECT_THIEF
                            && gBattleMoves[gCurrentMove].effect != EFFECT_TRAP
                            )
                        targetHasPhysicalAttack = 1;

                        if (!(targetMovesChecked))
                            {
                                //Pull the flags
                                moveFlags = AI_TypeCalc(gCurrentMove, monSpecies, monAbility);

                                // check type matchup, then adjust score accordingly
                                if (moveFlags & MOVE_RESULT_SUPER_EFFECTIVE)
                                    switchInScore -= 5;
                                if (moveFlags & MOVE_RESULT_NOT_VERY_EFFECTIVE)
                                    switchInScore += 7;
                                if (moveFlags & MOVE_RESULT_DOESNT_AFFECT_FOE)
                                    switchInScore += 12;

                                targetMovesChecked = 1;
                            }
                    }
            }

        //Opponent has used Bounce or Fly
        if (gStatuses3[gBattlerTarget] & STATUS3_ON_AIR)
            {
                //Pull the flags
                moveFlags = AI_TypeCalc(MOVE_FLY, monSpecies, monAbility);

                // check type matchup, then adjust score accordingly
                if (moveFlags & MOVE_RESULT_SUPER_EFFECTIVE)
                    switchInScore -= 5;
                if (moveFlags & MOVE_RESULT_NOT_VERY_EFFECTIVE)
                    switchInScore += 7;

                targetMovesChecked = 1;
                targetHasPhysicalAttack = 1;
            }

        //Opponent has used Dig
        if (gStatuses3[gBattlerTarget] & STATUS3_UNDERGROUND)
            {
                //Pull the flags
                moveFlags = AI_TypeCalc(MOVE_DIG, monSpecies, monAbility);

                // check type matchup, then adjust score accordingly
                if (moveFlags & MOVE_RESULT_SUPER_EFFECTIVE)
                    switchInScore -= 5;
                if (moveFlags & MOVE_RESULT_NOT_VERY_EFFECTIVE)
                    switchInScore += 7;
                if (moveFlags & MOVE_RESULT_DOESNT_AFFECT_FOE)
                    switchInScore += 12;

                targetMovesChecked = 1;
                targetHasPhysicalAttack = 1;
            }

        //Opponent has used Dive
        if (gStatuses3[gBattlerTarget] & STATUS3_UNDERWATER)
            {
                if (monAbility == ABILITY_WATER_ABSORB)
                    {
                        switchInScore += 12;
                    }
                else {
                    //Pull the flags
                    moveFlags = AI_TypeCalc(MOVE_DIVE, monSpecies, monAbility);

                    // check type matchup, then adjust score accordingly
                    if (moveFlags & MOVE_RESULT_SUPER_EFFECTIVE)
                        switchInScore -= 5;
                    if (moveFlags & MOVE_RESULT_NOT_VERY_EFFECTIVE)
                        switchInScore += 7;
                }

                targetMovesChecked = 1;
            }

        //If the target is locked into a move, suck as Sky Attack or Rollout, then go to a pokemon that resists it
        if(!(targetMovesChecked)
            && gBattleMons[gBattlerTarget].status2 == STATUS2_MULTIPLETURNS
            && targetLockedMove != MOVE_HYPER_BEAM
        )
            {
                moveFlags = AI_TypeCalc(targetLockedMove, monSpecies, monAbility);

                // check type matchup, then adjust score accordingly
                if (moveFlags & MOVE_RESULT_SUPER_EFFECTIVE)
                    switchInScore -= 5;
                if (moveFlags & MOVE_RESULT_NOT_VERY_EFFECTIVE)
                    switchInScore += 7;
                if (moveFlags & MOVE_RESULT_DOESNT_AFFECT_FOE)
                    switchInScore += 12;

                //If the attack is not physical, then set targetHasPhysicalAttack
                if(IS_TYPE_PHYSICAL(gBattleMoves[targetLockedMove].type))
                    targetHasPhysicalAttack = 1;

                targetMovesChecked = 1;
            }

        //If the last used move was hyper beam, and the opponent is charging, don't treat the opponent as having special attacks
        if (gBattleMons[gBattlerTarget].status2 == STATUS2_MULTIPLETURNS
            && targetLockedMove == MOVE_HYPER_BEAM
        )
            {
                targetHasPhysicalAttack = 1;
                targetMovesChecked = 1;
            }

        //If the opponent is shedinja, lower the score if Shedinja can't be KO'd. Otherwise, increase it slightly
        if (gBattleMons[gBattlerTarget].ability == ABILITY_WONDER_GUARD)
            {
                if (canKoShedinja)
                    switchInScore += 3;
                else
                    switchInScore -= 5;

                targetMovesChecked = 1;
            }

        //If none of the special cases above apply, and the target is not sleeping, then loop through the opponent's moves
        if (!(targetMovesChecked)
            && !(targetAsleep)
        )
        {
            //Loop through each of the moves
            for (j = 0; j < MAX_MON_MOVES; j++)
                {
                    //Get the move ID
                    gCurrentMove = gBattleMons[gBattlerTarget].moves[j];

                    //Check for ingrain
                    if (gCurrentMove == MOVE_INGRAIN)
                        targetHasIngrain = 1;

                    //Check for rapid spin
                    if (gCurrentMove == MOVE_RAPID_SPIN)
                        targetHasRapidSpin = 1;

                    //Pull the flags
                    moveFlags = AI_TypeCalc(gCurrentMove, monSpecies, monAbility);

                    //If the candidate Pokemon is Shedinja, set the targetCanKoShedinja flag if the target can KO Shedinja
                    if (monAbility == ABILITY_WONDER_GUARD)
                        {
                            // If the target an attacking move that can KO shedinja
                            if (gBattleMoves[gCurrentMove].power > 0
                                && moveFlags & MOVE_RESULT_SUPER_EFFECTIVE
                            )
                                targetCanKoShedinja = 1;

                            //Check each effect that can KO shedinja
                            for (k = 0; k < ARRAY_COUNT(shedinjaKOEffects); k++)
                                {
                                    if (gBattleMoves[gCurrentMove].effect == shedinjaKOEffects[k])
                                        targetCanKoShedinja = 1;
                                }
                        }
                    else
                        {
                            //If the move does damage
                            if (gBattleMoves[gCurrentMove].power > 0)
                                {
                                    //Set flags for super effective, neutral, and not very effective moves, and adjust the score accordingly after the loop
                                    if (moveFlags & MOVE_RESULT_SUPER_EFFECTIVE)
                                        targetSuperEffectiveFound = 1;

                                    if (!(moveFlags & MOVE_RESULT_SUPER_EFFECTIVE)
                                        && !(moveFlags & MOVE_RESULT_NOT_VERY_EFFECTIVE)
                                        && !(moveFlags & MOVE_RESULT_DOESNT_AFFECT_FOE)
                                    )
                                        targetNeutralEffectiveFound = 1;

                                    if (moveFlags & MOVE_RESULT_NOT_VERY_EFFECTIVE)
                                        targetNotVeryEffectiveFound = 1;

                                    //If the target has a physical attack
                                    if (IS_TYPE_PHYSICAL(gBattleMoves[gCurrentMove].type)
                                        && gBattleMoves[gCurrentMove].effect != EFFECT_HIDDEN_POWER
                                        && gBattleMoves[gCurrentMove].effect != EFFECT_LEVEL_DAMAGE
                                        && gBattleMoves[gCurrentMove].effect != EFFECT_RAPID_SPIN
                                        && gBattleMoves[gCurrentMove].effect != EFFECT_SNORE
                                        && gBattleMoves[gCurrentMove].effect != EFFECT_SONICBOOM
                                        && gBattleMoves[gCurrentMove].effect != EFFECT_SUPER_FANG
                                        && gBattleMoves[gCurrentMove].effect != EFFECT_THIEF
                                        && gBattleMoves[gCurrentMove].effect != EFFECT_TRAP
                                    )
                                        targetHasPhysicalAttack = 1;

                                    //If the opponent has focus punch and the user does not resist it
                                    if(gCurrentMove == MOVE_FOCUS_PUNCH
                                        && !(moveFlags & MOVE_RESULT_NOT_VERY_EFFECTIVE)
                                        && !(moveFlags & MOVE_RESULT_DOESNT_AFFECT_FOE)
                                        && Random() % 3
                                    )
                                        switchInScore -= 3;

                                    //If the opponent has zap cannon, and the candidate pokemon can be paralyzed by it, then score -3
                                    if (gCurrentMove == MOVE_ZAP_CANNON
                                        && (monAbility == ABILITY_VOLT_ABSORB
                                            || monAbility == ABILITY_LIMBER
                                            || monAbility == ABILITY_SHIELD_DUST
                                            || monType1 == TYPE_GROUND
                                            || monType2 == TYPE_GROUND)
                                    )
                                        switchInScore -= 3;

                                    //If the opponent has explosion, then plus for ghost/steel/rock/damp/low hp (random chance)
                                    if(gBattleMoves[gCurrentMove].effect == EFFECT_EXPLOSION
                                        && !(Random() % 5)
                                    )
                                        {
                                            if (monAbility == ABILITY_DAMP
                                                || moveFlags & MOVE_RESULT_NOT_VERY_EFFECTIVE
                                                || moveFlags & MOVE_RESULT_DOESNT_AFFECT_FOE
                                                || (GetMonData(&gEnemyParty[i], MON_DATA_HP) * 100
                                                    < GetMonData(&gEnemyParty[i], MON_DATA_MAX_HP) * 30)
                                            )
                                                switchInScore += 12;
                                        }

                                    if (gCurrentMove == MOVE_SOLAR_BEAM
                                        && gBattleWeather & B_WEATHER_SUN
                                        && (monAbility == ABILITY_DRIZZLE
                                            || monAbility == ABILITY_SAND_STREAM)
                                    )
                                        switchInScore += 7;

                                    if (gCurrentMove == MOVE_THUNDER
                                        && gBattleWeather & B_WEATHER_RAIN
                                        && monAbility == ABILITY_DROUGHT
                                    )
                                        switchInScore += 7;
                                }
                            else
                                {
                                    //If the opponent has Leech Seed, and the candidate pokemon punishes it, +7 score
                                    if (gCurrentMove == MOVE_LEECH_SEED
                                        && (monAbility == ABILITY_LIQUID_OOZE
                                            || monType1 == TYPE_GRASS
                                            || monType2 == TYPE_GRASS
                                            || hasRapidSpin)
                                    )
                                        switchInScore += 7;

                                    if (!(statusImmune))
                                        {
                                            //If the opponent has Toxic
                                            if (gCurrentMove == MOVE_TOXIC
                                                && !(monAbility == ABILITY_IMMUNITY
                                                    || monType1 == TYPE_POISON
                                                    || monType2 == TYPE_POISON
                                                    || monType1 == TYPE_STEEL
                                                    || monType2 == TYPE_STEEL)
                                            )
                                                switchInScore -= 2;

                                            //If the opponent has Glare
                                            if (gCurrentMove == MOVE_GLARE
                                                && !(monAbility == ABILITY_LIMBER
                                                    || monType1 == TYPE_GHOST
                                                    || monType2 == TYPE_GHOST)
                                            )
                                                switchInScore -= 3;

                                            //If the opponent has Thunder Wave
                                            if (gCurrentMove == MOVE_THUNDER_WAVE
                                                && !(monAbility == ABILITY_LIMBER
                                                    || monType1 == TYPE_GROUND
                                                    || monType2 == TYPE_GROUND)
                                            )
                                                switchInScore -= 3;

                                            //If the opponent has Stun Spore
                                            if (gCurrentMove == MOVE_STUN_SPORE
                                                && !(monAbility == ABILITY_LIMBER)
                                            )
                                                switchInScore -= 3;

                                            //If the opponent has Will-o-Wisp
                                            if (gCurrentMove == MOVE_WILL_O_WISP
                                                && !(monAbility == ABILITY_WATER_VEIL
                                                    || monType1 == TYPE_FIRE
                                                    || monType2 == TYPE_FIRE)
                                            )
                                                {
                                                    switchInScore -= 2;

                                                    if (hasPhysicalAttack)
                                                        switchInScore -= 3;
                                                }

                                            //If the opponent has a sleep move
                                            if (gBattleMoves[gCurrentMove].effect == EFFECT_SLEEP)
                                                {
                                                    if(monAbility == ABILITY_INSOMNIA
                                                        || monAbility == ABILITY_VITAL_SPIRIT
                                                        || monAbility == ABILITY_EARLY_BIRD
                                                        || hasSleepAtk)
                                                        {
                                                            switchInScore += 7;
                                                        }
                                                    else
                                                        {
                                                            switchInScore -= 3;
                                                        }
                                                }
                                        }
                                }
                        }
                }

            //If the candidate pokemon is Shedinja and it can't be KO'd by the target, then the AI should want to bring it in
            if (monAbility == ABILITY_WONDER_GUARD)
                {
                    if (targetCanKoShedinja)
                        switchInScore -= 5;
                    else
                        switchInScore += 12;
                }
            //Otherwise, check type matchup
            else
                {
                    if (targetSuperEffectiveFound)
                        {
                            switchInScore -= 5;
                        }
                    else
                        {
                            if (targetNeutralEffectiveFound)
                                {
                                    switchInScore -= 1;
                                }
                            else
                                {
                                    if (targetNotVeryEffectiveFound)
                                        {
                                            switchInScore += 7;
                                        }
                                    else
                                        {
                                            switchInScore += 15;
                                        }
                                }
                        }
                }

            //If the target is asleep, we want to check the moves the candidate has available to it
            if(targetAsleep)
                {
                    if(neutralEffectiveFound || superEffectiveFound)
                        {
                            switchInScore += 4;

                            if(superEffectiveFound)
                                switchInScore += 4;
                        }
                }

            //If the opponent has stat boosts, the AI should try and force them out
            if (targetStatsRaised)
                {
                    //If there is a phazing option available that works, then +6 score
                    if(hasHaze
                        || (hasPerish
                            && targetPartySize > 1 // This line is to avoid double-counting in next check
                            && gBattleMons[gBattlerTarget].ability != ABILITY_SOUNDPROOF)
                        || (hasWW
                            && targetHasIngrain == 0
                            && targetPartySize > 1
                            && gBattleMons[gBattlerTarget].ability != ABILITY_SUCTION_CUPS)
                        || (hasRoar
                            && targetHasIngrain == 0
                            && targetPartySize > 1
                            && gBattleMons[gBattlerTarget].ability != ABILITY_SOUNDPROOF
                            && gBattleMons[gBattlerTarget].ability != ABILITY_SUCTION_CUPS)
                    )
                        {
                            switchInScore += 6;

                            //Bonus score if the target is asleep
                            if(targetAsleep)
                                switchInScore += 1;
                        }
                }

            //If the opponent is down to their last mon and we have a pokemon with perish song, score +12
            if (targetPartySize == 1
                && hasPerish
                && gBattleMons[gBattlerTarget].ability != ABILITY_SOUNDPROOF
            )
                switchInScore += 6;
        }

        //If the opponent only has physical attacks, or is locked into a physical attack:
        if (monAbility == ABILITY_INTIMIDATE
            && targetHasPhysicalAttack
            && gBattleMons[gBattlerTarget].ability != ABILITY_CLEAR_BODY
            && gBattleMons[gBattlerTarget].ability != ABILITY_WHITE_SMOKE
            && gBattleMons[gBattlerTarget].ability != ABILITY_HYPER_CUTTER
        )
            switchInScore += 3;

        //If the candidate pokemon has rapid spin & spikes are active, score +3
        if (hasRapidSpin
            && gSideStatuses[GetBattlerSide(gActiveBattler)] & SIDE_STATUS_SPIKES
            && !(gBattleMons[gBattlerTarget].type1 == TYPE_GHOST
                || gBattleMons[gBattlerTarget].type2 == TYPE_GHOST
            )
        )
            switchInScore += 3;

        //If spikes are active on the opponent's side of the field, then 2 in 3 chance that the AI will try to spinblock
        if (targetHasRapidSpin
            && gSideStatuses[GetBattlerSide(gBattlerTarget)] & SIDE_STATUS_SPIKES
            && Random() % 3
            && (monType1 == TYPE_GHOST
                || monType2 == TYPE_GHOST
            )
        )
            switchInScore += 10;

        //Lower the score to bring it in range for use with thresholds. Anything below 23 is a bad score. The starting point is 19 plus the HP factor.
        if (switchInScore <= 23)
            switchInScore = 1;
        else
            switchInScore -= 22;

        //Initial score set
        DebugPrintf("switch-in final score = %d for pokemon %d",(signed char) switchInScore,i);

        //If this pokemon has a higher switch-in score, then set it to the chosen switch-in. Note that this is not perfectly random for teams of more than 3 pokemon.
        if (switchInScore > maxSwitchInScore
            || (switchInScore == maxSwitchInScore && Random() % 2)
        )
            {
                chosenSwitchIn = i;
                maxSwitchInScore = switchInScore;
            }
    }

    DebugPrintf("Chosen Switch-in: %d",(signed char) chosenSwitchIn);

    //Set chosen switch-in. If the AI doesn't decide to switch, but chooses baton pass, then we want it to make use of the same logic.
    AI_THINKING_STRUCT->chosenMonId = chosenSwitchIn;

    DebugPrintf("Max Score: %d, Threshold: %d, Max Switch-In Score: %d",(signed char) maxScore, (signed char) threshold, (signed char) maxSwitchInScore);

    //Final check to see if based on move score, threshold & quality of possible switch-ins, the AI should switch
    if (maxScore + (Random() % 2) < threshold + maxSwitchInScore
        && !(BatonPassChosen)
    )
        {
            DebugPrintf("Switching to %d",chosenSwitchIn);

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

    for (i = firstId; i < lastId; i++)
    {
        if (GetMonData(&gEnemyParty[i], MON_DATA_HP) == 0)
            continue;
        if (GetMonData(&gEnemyParty[i], MON_DATA_SPECIES_OR_EGG) == SPECIES_NONE)
            continue;
        if (GetMonData(&gEnemyParty[i], MON_DATA_SPECIES_OR_EGG) == SPECIES_EGG)
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
    if (ShouldSwitchIfPerishSong())
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
                        if (GetMonData(&gEnemyParty[monToSwitchId], MON_DATA_HP) == 0)
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
    struct Pokemon *party;
    s32 bestDmg;
    s32 i, j, k;
    u16 move;
    u8 moveFlags;
    u8 invalidMons;
    u8 opposingBattler;
    u8 activeMonHP;
    u8 battlerIn1, battlerIn2;
    u8 bestMonId, maxSwitchScore, switchScore;
    u8 hasHaze, hasPerish, hasPhysicalAttack, hasRapidSpin, hasRoar, hasSleepMove, hasWisp, hasWW;
    u8 neutralEffectiveFound, superEffectiveFound;
    u8 targetCanKoShedinja, targetPartySize, targetStatsRaised, targetStatusImmune;
    u8 targetHasIngrain, targetHasPhysicalAttack, targetHasSleepAtk, targetHasWisp;
    u8 targetNeutralEffectiveFound, targetNotVeryEffectiveFound, targetSuperEffectiveFound;
    u8 canKoShedinja, statusImmune;
    u8 monAbility, monSpecies;

    u8 shedinjaKOEffects[] = {EFFECT_CONFUSE, EFFECT_FLATTER, EFFECT_HAIL, EFFECT_LEECH_SEED, EFFECT_POISON, EFFECT_SANDSTORM, EFFECT_SWAGGER, EFFECT_TOXIC, EFFECT_WILL_O_WISP};

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

    activeMonHP = gBattleMons[gActiveBattler].hp;

    //If this is a hard switch, or baton pass is called, then go to the pre-selected pokemon. Otherwise, run bespoke logic.
    if (activeMonHP > 0)
        {
            bestMonId = gBattleResources->ai->chosenMonId;
            DebugPrintf("Chosen Switch-in: %d",(signed char) bestMonId);
        }
    else
        {
            //Initialise variables before loop
            maxSwitchScore = targetPartySize = 0;

            //Set targetPartySize variable
            for (i = 0; i < PARTY_SIZE; i++)
            {
                if (GetMonData(&gPlayerParty[i], MON_DATA_HP) == 0)
                    continue;
                if (GetMonData(&gPlayerParty[i], MON_DATA_SPECIES_OR_EGG) == SPECIES_NONE)
                    continue;
                if (GetMonData(&gPlayerParty[i], MON_DATA_SPECIES_OR_EGG) == SPECIES_EGG)
                    continue;
                if (i == gBattlerPartyIndexes[gBattlerTarget])
                    continue;
                if (i == *(gBattleStruct->monToSwitchIntoId + gBattlerTarget))
                    continue;

                targetPartySize++;
            }

            //Initialise variables based on the opponent
            targetCanKoShedinja = targetStatsRaised = targetStatusImmune = 0;
            targetHasPhysicalAttack = targetHasSleepAtk = targetHasWisp = 0;
            targetNeutralEffectiveFound = targetNotVeryEffectiveFound = targetSuperEffectiveFound = 0;

            //Check if opponent's stat levels are above the minimum
            for (i = 1; i < NUM_BATTLE_STATS; i++)
                {
                    if (gBattleMons[gBattlerTarget].statStages[i] > DEFAULT_STAT_STAGE)
                    {
                        targetStatsRaised = 1;
                        break;
                    }
                }

            //Check if the opponent has safeguard up, Natural Cure, or is already statused
            if (gSideStatuses[B_SIDE_PLAYER] & SIDE_STATUS_SAFEGUARD
                || gBattleMons[gBattlerTarget].ability == ABILITY_NATURAL_CURE
                || gBattleMons[gBattlerTarget].status1 & STATUS1_ANY
            )
                targetStatusImmune = 1;

            //Loop through the opponent's moves to set variables
            for (j = 0; j < MAX_MON_MOVES; j++)
                {
                    //Get the move ID
                    gCurrentMove = gBattleMons[gBattlerTarget].moves[j];

                    //Check for specific moves
                    if (gCurrentMove == MOVE_INGRAIN)
                        targetHasIngrain = 1;

                    if (gCurrentMove == MOVE_WILL_O_WISP)
                        targetHasWisp = 1;

                    if (gCurrentMove == MOVE_SLEEP_TALK
                        || gCurrentMove == MOVE_SNORE
                    )
                        targetHasSleepAtk = 1;

                    if (gCurrentMove == MOVE_REST
                        || gCurrentMove == MOVE_REFRESH
                    )
                        targetStatusImmune = 1;

                    //Pull the flags
                    moveFlags = AI_TypeCalc(gCurrentMove, monSpecies, monAbility);

                    //If the candidate Pokemon is Shedinja, set the targetCanKoShedinja flag if the target can KO Shedinja
                    if (monAbility == ABILITY_WONDER_GUARD)
                        {
                            // If the target an attacking move that can KO shedinja
                            if (gBattleMoves[gCurrentMove].power > 0
                                && moveFlags & MOVE_RESULT_SUPER_EFFECTIVE
                            )
                                targetCanKoShedinja = 1;

                            //Check each effect that can KO shedinja
                            for (k = 0; k < ARRAY_COUNT(shedinjaKOEffects); k++)
                                {
                                    if (gBattleMoves[gCurrentMove].effect == shedinjaKOEffects[k])
                                        targetCanKoShedinja = 1;
                                }
                        }
                    else
                        {
                            //If the move does damage
                            if (gBattleMoves[gCurrentMove].power > 0)
                                {
                                    //Set flags for super effective, neutral, and not very effective moves, and adjust the score accordingly after the loop
                                    if (moveFlags & MOVE_RESULT_SUPER_EFFECTIVE)
                                        targetSuperEffectiveFound= 1;

                                    if (!(moveFlags & MOVE_RESULT_SUPER_EFFECTIVE)
                                        && !(moveFlags & MOVE_RESULT_NOT_VERY_EFFECTIVE)
                                        && !(moveFlags & MOVE_RESULT_DOESNT_AFFECT_FOE)
                                    )
                                        targetNeutralEffectiveFound = 1;

                                    if (moveFlags & MOVE_RESULT_NOT_VERY_EFFECTIVE)
                                        targetNotVeryEffectiveFound = 1;

                                    //Set a flag if the attack has a physical attack which is not fixed damage or unaffected by Wisp
                                    if(IS_TYPE_PHYSICAL(gBattleMoves[gCurrentMove].type)
                                        && gBattleMoves[gCurrentMove].effect != EFFECT_HIDDEN_POWER
                                        && gBattleMoves[gCurrentMove].effect != EFFECT_LEVEL_DAMAGE
                                        && gBattleMoves[gCurrentMove].effect != EFFECT_RAPID_SPIN
                                        && gBattleMoves[gCurrentMove].effect != EFFECT_SNORE
                                        && gBattleMoves[gCurrentMove].effect != EFFECT_SONICBOOM
                                        && gBattleMoves[gCurrentMove].effect != EFFECT_SUPER_FANG
                                        && gBattleMoves[gCurrentMove].effect != EFFECT_THIEF
                                        && gBattleMoves[gCurrentMove].effect != EFFECT_TRAP
                                    )
                                        targetHasPhysicalAttack = 1;
                                }
                        }
                }

            // Find the best pokemon
            for (i = 0; i < PARTY_SIZE; i++)
                {
                    if ((u16)(GetMonData(&gEnemyParty[i], MON_DATA_SPECIES)) == SPECIES_NONE)
                        continue;
                    if (GetMonData(&gEnemyParty[i], MON_DATA_HP) == 0)
                        continue;
                    if (gBattlerPartyIndexes[battlerIn1] == i)
                        continue;
                    if (gBattlerPartyIndexes[battlerIn2] == i)
                        continue;
                    if (i == *(gBattleStruct->monToSwitchIntoId + battlerIn1))
                        continue;
                    if (i == *(gBattleStruct->monToSwitchIntoId + battlerIn2))
                        continue;

                    //Initialise choice-specific variables
                    switchScore = 1;
                    hasHaze = hasPerish = hasRoar = hasWW = 0;
                    hasPhysicalAttack = hasRapidSpin =  hasSleepMove = hasWisp = 0;
                    canKoShedinja = statusImmune = 0;
                    neutralEffectiveFound = superEffectiveFound = 0;

                    monSpecies = GetMonData(&gEnemyParty[i], MON_DATA_SPECIES);
                    monAbility = GetAbilityBySpecies(monSpecies, GetMonData(&gEnemyParty[i], MON_DATA_ABILITY_NUM));

                    //If the candidate Pokemon has trace, then use the target's ability in logic
                    if (monAbility == ABILITY_TRACE)
                        monAbility = gBattleMons[gBattlerTarget].ability;

                    //Check if safeguard is up, the candidate Pokemon has Natural Cure, or is already statused
                    if (gSideStatuses[B_SIDE_OPPONENT] & SIDE_STATUS_SAFEGUARD
                        || monAbility == ABILITY_NATURAL_CURE
                        || GetMonData(&gEnemyParty[i], MON_DATA_STATUS) & STATUS1_ANY
                    )
                        statusImmune = 1;

                    //Loop through the moves of the candidate pokemon and set variables used to determine the score
                    for (j = 0; j < MAX_MON_MOVES; j++)
                        {
                            //Get the move ID
                            gCurrentMove = GetMonData(&gEnemyParty[i], MON_DATA_MOVE1 + j);

                            //if refresh or rest
                            if (gCurrentMove == MOVE_REST
                                || gCurrentMove == MOVE_REFRESH
                            )
                                statusImmune = 1;

                            //Check whether the mon has a physical attack which is affected meaningfully by burn
                            if (gBattleMoves[gCurrentMove].power > 0
                                && IS_TYPE_PHYSICAL(gBattleMoves[gCurrentMove].type)
                                && gBattleMoves[gCurrentMove].effect != EFFECT_HIDDEN_POWER
                                && gBattleMoves[gCurrentMove].effect != EFFECT_LEVEL_DAMAGE
                                && gBattleMoves[gCurrentMove].effect != EFFECT_RAPID_SPIN
                                && gBattleMoves[gCurrentMove].effect != EFFECT_SNORE
                                && gBattleMoves[gCurrentMove].effect != EFFECT_SONICBOOM
                                && gBattleMoves[gCurrentMove].effect != EFFECT_SUPER_FANG
                                && gBattleMoves[gCurrentMove].effect != EFFECT_THIEF
                                && gBattleMoves[gCurrentMove].effect != EFFECT_TRAP
                            )
                                hasPhysicalAttack = 1;

                            if (gBattleMoves[gCurrentMove].effect == EFFECT_RAPID_SPIN)
                                hasRapidSpin = 1;

                            //If the opponent is shedinja, check if there is a move can KO it.
                            if (gBattleMons[gBattlerTarget].ability == ABILITY_WONDER_GUARD
                                && gCurrentMove != MOVE_NONE
                                && gCurrentMove != MOVE_UNAVAILABLE
                            )
                                {
                                    moveFlags = AI_TypeCalc(gCurrentMove, gBattlerTarget, ABILITY_WONDER_GUARD);

                                    // If the player an attacking move that can KO shedinja
                                    if (gBattleMoves[gBattleMons[gActiveBattler].moves[i]].power > 0
                                        && moveFlags & MOVE_RESULT_SUPER_EFFECTIVE
                                    )
                                        canKoShedinja = 1;

                                    //Check each effect that can KO shedinja
                                    for (j = 0; j < ARRAY_COUNT(shedinjaKOEffects); j++)
                                        {
                                            if (gBattleMoves[gBattleMons[gActiveBattler].moves[i]].effect == shedinjaKOEffects[j])
                                            canKoShedinja = 1;
                                        }
                                }
                            //Otherwise, look at how useful the move is
                            else
                                {
                                    //If the move does damage
                                    if (gBattleMoves[gCurrentMove].power > 0)
                                        {
                                            moveFlags = AI_TypeCalc(gCurrentMove, gBattlerTarget, gBattleMons[gBattlerTarget].ability);

                                            //Set flags for super effective & neutral moves being found
                                            if (moveFlags & MOVE_RESULT_SUPER_EFFECTIVE)
                                                superEffectiveFound = 1;

                                            if (!(moveFlags & MOVE_RESULT_SUPER_EFFECTIVE)
                                                && !(moveFlags & MOVE_RESULT_NOT_VERY_EFFECTIVE)
                                                && !(moveFlags & MOVE_RESULT_DOESNT_AFFECT_FOE)
                                            )
                                                neutralEffectiveFound = 1;
                                        }
                                }

                            //If the candidate pokemon has a sleep move
                            if (gBattleMoves[gCurrentMove].effect == EFFECT_SLEEP)
                                hasSleepMove = 1;

                            if (gCurrentMove == MOVE_HAZE)
                                hasHaze = 1;

                            if (gCurrentMove == MOVE_PERISH_SONG)
                                hasPerish = 1;

                            if (gCurrentMove == MOVE_ROAR)
                                hasRoar = 1;

                            if (gCurrentMove == MOVE_WHIRLWIND)
                                hasWW = 1;

                            if (gCurrentMove == MOVE_WILL_O_WISP)
                                hasWisp = 1;
                        }

                    //Update score based on candidate's moves

                    //If the candidate pokemon is Shedinja
                    if (gBattleMons[gBattlerTarget].ability == ABILITY_WONDER_GUARD)
                        {
                            if (canKoShedinja)
                                switchScore += 10;
                        }
                    //If it is not Shedinja
                    else
                        {
                            //If the candidate can hit the opponent super-effectively, or neutrally effectively, those are preferable.
                            if(superEffectiveFound)
                                switchScore += 10;
                            else
                                {
                                    if (neutralEffectiveFound)
                                        switchScore += 5;
                                }
                        }

                    //If the target can't hit the candidate with certain effectiveness, that also boosts its score
                    if (!(targetSuperEffectiveFound))
                        {
                            switchScore += 2;

                            if (!(targetNeutralEffectiveFound))
                                {
                                    switchScore += 5;

                                    if (!(targetNotVeryEffectiveFound))
                                        switchScore += 5;
                                }
                        }

                    //If the opponent has stat boosts, the AI should try and force them out
                    if (targetStatsRaised)
                        {
                            //If there is a phazing option available that works, then +2 score
                            if(hasHaze
                                || (hasPerish
                                    && gBattleMons[gBattlerTarget].ability != ABILITY_SOUNDPROOF)
                                || (hasWW
                                    && targetHasIngrain == 0
                                    && targetPartySize > 1
                                    && gBattleMons[gBattlerTarget].ability != ABILITY_SUCTION_CUPS)
                                || (hasRoar
                                    && targetHasIngrain == 0
                                    && targetPartySize > 1
                                    && gBattleMons[gBattlerTarget].ability != ABILITY_SOUNDPROOF
                                    && gBattleMons[gBattlerTarget].ability != ABILITY_SUCTION_CUPS)
                            )
                                switchScore += 2;
                        }

                    //If the opponent is down to their last mon and we have a pokemon with perish song, score +20
                    if (targetPartySize == 1
                        && hasPerish
                        && gBattleMons[gBattlerTarget].ability != ABILITY_SOUNDPROOF
                    )
                        switchScore += 20;

                    //if the candidate has a sleep move and the opponent isn't immune
                    if (hasSleepMove
                        && !(gBattleMons[gBattlerTarget].ability == ABILITY_EARLY_BIRD
                            || gBattleMons[gBattlerTarget].ability == ABILITY_INSOMNIA
                            || gBattleMons[gBattlerTarget].ability == ABILITY_VITAL_SPIRIT
                            || targetStatusImmune
                            || targetHasSleepAtk)
                    )
                        switchScore += 3;

                    //If there are spikes up on the AI's side, and they can be spun:
                    if (hasRapidSpin
                        && gSideStatuses[GetBattlerSide(gActiveBattler)] & SIDE_STATUS_SPIKES
                        && !(gBattleMons[gBattlerTarget].type1 != TYPE_GHOST
                            || gBattleMons[gBattlerTarget].type2 != TYPE_GHOST)
                    )
                        switchScore += 2;

                    //If there are spikes up on the target's side, the target has rapid spin, and the candidate Pokemon is a ghost type
                    if (hasRapidSpin
                        && gSideStatuses[GetBattlerSide(gBattlerTarget)] & SIDE_STATUS_SPIKES
                        && (gSpeciesInfo[monSpecies].types[0] == TYPE_GHOST
                            || gSpeciesInfo[monSpecies].types[1] == TYPE_GHOST)
                    )
                        switchScore += 5;

                    //If the candidate pokemon has wisp and the target has physical attacks and isn't status immune
                    if (hasWisp
                        && targetHasPhysicalAttack
                        && !(targetStatusImmune)
                        && gBattleMons[gBattlerTarget].type1 != TYPE_FIRE
                        && gBattleMons[gBattlerTarget].type2 != TYPE_FIRE
                        && gBattleMons[gBattlerTarget].ability != ABILITY_WATER_VEIL
                    )
                        switchScore += 3;

                    //If the target pokemon has wisp and the candidate doesn't have physical attacks, or is status immune
                    if (targetHasWisp
                        && (!(hasPhysicalAttack)
                            || statusImmune
                            || gSpeciesInfo[monSpecies].types[0] == TYPE_FIRE
                            || gSpeciesInfo[monSpecies].types[1] == TYPE_FIRE
                            || monAbility == ABILITY_WATER_VEIL)
                    )
                        switchScore += 2;

                    if (monAbility == ABILITY_INTIMIDATE
                        && targetHasPhysicalAttack
                        && gBattleMons[gBattlerTarget].ability != ABILITY_CLEAR_BODY
                        && gBattleMons[gBattlerTarget].ability != ABILITY_WHITE_SMOKE
                        && gBattleMons[gBattlerTarget].ability != ABILITY_HYPER_CUTTER
                    )
                        switchScore += 3;

                    //If the chosen pokemon has a better score than a previous choice, then select it and update the max score
                    if (switchScore > maxSwitchScore
                        || (Random() % 2
                            && switchScore == maxSwitchScore)
                    )
                        {
                            bestMonId = i;
                            maxSwitchScore = switchScore;
                        }
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
        if (GetMonData(&gEnemyParty[i], MON_DATA_HP) != 0
            && GetMonData(&gEnemyParty[i], MON_DATA_SPECIES_OR_EGG) != SPECIES_NONE
            && GetMonData(&gEnemyParty[i], MON_DATA_SPECIES_OR_EGG) != SPECIES_EGG)
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
