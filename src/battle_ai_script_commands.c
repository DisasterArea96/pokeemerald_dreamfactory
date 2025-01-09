#include "global.h"
#include "battle.h"
#include "battle_anim.h"
#include "battle_ai_script_commands.h"
#include "battle_factory.h"
#include "battle_setup.h"
#include "data.h"
#include "item.h"
#include "pokemon.h"
#include "random.h"
#include "recorded_battle.h"
#include "util.h"
#include "constants/abilities.h"
#include "constants/battle_ai.h"
#include "constants/battle_move_effects.h"
#include "constants/items.h"
#include "constants/moves.h"

#define AI_ACTION_DONE          (1 << 0)
#define AI_ACTION_FLEE          (1 << 1)
#define AI_ACTION_WATCH         (1 << 2)
#define AI_ACTION_DO_NOT_ATTACK (1 << 3)

#define AI_THINKING_STRUCT ((struct AI_ThinkingStruct *)(gBattleResources->ai))
#define BATTLE_HISTORY ((struct BattleHistory *)(gBattleResources->battleHistory))

// AI states
enum
{
    AIState_SettingUp,
    AIState_Processing,
    AIState_FinishedProcessing,
    AIState_DoNotProcess
};

/*
gAIScriptPtr is a pointer to the next battle AI cmd command to read.
when a command finishes processing, gAIScriptPtr is incremented by
the number of bytes that the current command had reserved for arguments
in order to read the next command correctly. refer to battle_ai_scripts.s for the
AI scripts.
*/

extern const u8 *const gBattleAI_ScriptsTable[];

static u8 ChooseMoveOrAction_Singles(void);
static u8 ChooseMoveOrAction_Doubles(void);
static void RecordLastUsedMoveByTarget(void);
static void BattleAI_DoAIProcessing(void);
static void AIStackPushVar(const u8 *);
static bool8 AIStackPop(void);

static void Cmd_if_random_less_than(void);
static void Cmd_if_random_greater_than(void);
static void Cmd_if_waking(void);
static void Cmd_if_badly_poisoned_for_turns(void);
static void Cmd_score(void);
static void Cmd_if_hp_less_than(void);
static void Cmd_if_hp_more_than(void);
static void Cmd_if_hp_equal(void);
static void Cmd_if_hp_not_equal(void);
static void Cmd_if_status(void);
static void Cmd_if_not_status(void);
static void Cmd_if_status2(void);
static void Cmd_if_not_status2(void);
static void Cmd_if_status3(void);
static void Cmd_if_can_use_substitute(void);
static void Cmd_if_side_affecting(void);
static void Cmd_if_not_side_affecting(void);
static void Cmd_if_less_than(void);
static void Cmd_if_more_than(void);
static void Cmd_if_equal(void);
static void Cmd_if_not_equal(void);
static void Cmd_if_less_than_ptr(void);
static void Cmd_if_more_than_ptr(void);
static void Cmd_if_has_attack_of_type(void);
static void Cmd_if_has_attack_of_category(void);
static void Cmd_if_move(void);
static void Cmd_if_not_move(void);
static void Cmd_if_in_bytes(void);
static void Cmd_if_not_in_bytes(void);
static void Cmd_if_in_hwords(void);
static void Cmd_check_curr_move_has_stab(void);
static void Cmd_if_user_has_attacking_move(void);
static void Cmd_if_user_has_no_attacking_moves(void);
static void Cmd_get_turn_count(void);
static void Cmd_get_type(void);
static void Cmd_get_considered_move_power(void);
static void Cmd_get_how_powerful_move_is(void);
static void Cmd_get_last_used_battler_move(void);
static void Cmd_get_target_previous_move_pp(void);
static void Cmd_if_shares_move_with_user(void);
static void Cmd_if_user_goes(void);
static void Cmd_if_user_doesnt_go(void);
static void Cmd_get_considered_move_second_eff_chance(void);
static void Cmd_get_considered_move_accuracy(void);
static void Cmd_count_usable_party_mons(void);
static void Cmd_get_considered_move(void);
static void Cmd_get_considered_move_effect(void);
static void Cmd_get_ability(void);
static void Cmd_get_highest_type_effectiveness(void);
static void Cmd_if_type_effectiveness(void);
static void Cmd_if_target(void);
static void Cmd_if_type_effectiveness_with_modifiers(void);
static void Cmd_if_status_in_party(void);
static void Cmd_if_status_not_in_party(void);
static void Cmd_get_weather(void);
static void Cmd_if_effect(void);
static void Cmd_if_not_effect(void);
static void Cmd_if_stat_level_less_than(void);
static void Cmd_if_stat_level_more_than(void);
static void Cmd_if_stat_level_equal(void);
static void Cmd_if_stat_level_not_equal(void);
static void Cmd_if_can_faint(void);
static void Cmd_consider_imitated_move(void);
static void Cmd_if_has_move(void);
static void Cmd_if_doesnt_have_move(void);
static void Cmd_if_has_move_with_effect(void);
static void Cmd_if_doesnt_have_move_with_effect(void);
static void Cmd_if_any_move_disabled_or_encored(void);
static void Cmd_if_curr_move_disabled_or_encored(void);
static void Cmd_flee(void);
static void Cmd_if_random_safari_flee(void);
static void Cmd_watch(void);
static void Cmd_get_hold_effect(void);
static void Cmd_get_gender(void);
static void Cmd_is_first_turn_for(void);
static void Cmd_get_stockpile_count(void);
static void Cmd_is_double_battle(void);
static void Cmd_get_used_held_item(void);
static void Cmd_get_move_type_from_result(void);
static void Cmd_get_move_power_from_result(void);
static void Cmd_get_move_effect_from_result(void);
static void Cmd_get_protect_count(void);
static void Cmd_get_move_target_from_result(void);
static void Cmd_get_type_effectiveness_from_result(void);
static void Cmd_get_considered_move_second_eff_chance_from_result(void);
static void Cmd_get_spikes_layers_target(void);
static void Cmd_if_ai_can_faint(void);
static void Cmd_get_highest_type_effectiveness_from_target(void);
static void Cmd_call(void);
static void Cmd_goto(void);
static void Cmd_end(void);
static void Cmd_if_level_cond(void);
static void Cmd_if_target_taunted(void);
static void Cmd_if_target_not_taunted(void);
static void Cmd_check_ability(void);
static void Cmd_used_considered_move_last_turn(void);
static void Cmd_if_target_is_ally(void);
static void Cmd_if_flash_fired(void);
static void Cmd_if_holds_item(void);

// ewram
EWRAM_DATA const u8 *gAIScriptPtr = NULL;
EWRAM_DATA static u8 sBattler_AI = 0;

// const rom data
typedef void (*BattleAICmdFunc)(void);

static const BattleAICmdFunc sBattleAICmdTable[] =
{
    Cmd_if_random_less_than,                        // 0x0
    Cmd_if_random_greater_than,                     // 0x1
    Cmd_if_waking,                                  // 0x2
    Cmd_if_badly_poisoned_for_turns,                // 0x3
    Cmd_score,                                      // 0x4
    Cmd_if_hp_less_than,                            // 0x5
    Cmd_if_hp_more_than,                            // 0x6
    Cmd_if_hp_equal,                                // 0x7
    Cmd_if_hp_not_equal,                            // 0x8
    Cmd_if_status,                                  // 0x9
    Cmd_if_not_status,                              // 0xA
    Cmd_if_status2,                                 // 0xB
    Cmd_if_not_status2,                             // 0xC
    Cmd_if_status3,                                 // 0xD
    Cmd_if_can_use_substitute,                      // 0xE
    Cmd_if_side_affecting,                          // 0xF
    Cmd_if_not_side_affecting,                      // 0x10
    Cmd_if_less_than,                               // 0x11
    Cmd_if_more_than,                               // 0x12
    Cmd_if_equal,                                   // 0x13
    Cmd_if_not_equal,                               // 0x14
    Cmd_if_less_than_ptr,                           // 0x15
    Cmd_if_more_than_ptr,                           // 0x16
    Cmd_if_has_attack_of_type,                      // 0x17
    Cmd_if_has_attack_of_category,                  // 0x18
    Cmd_if_move,                                    // 0x19
    Cmd_if_not_move,                                // 0x1A
    Cmd_if_in_bytes,                                // 0x1B
    Cmd_if_not_in_bytes,                            // 0x1C
    Cmd_if_in_hwords,                               // 0x1D
    Cmd_check_curr_move_has_stab,                   // 0x1E
    Cmd_if_user_has_attacking_move,                 // 0x1F
    Cmd_if_user_has_no_attacking_moves,             // 0x20
    Cmd_get_turn_count,                             // 0x21
    Cmd_get_type,                                   // 0x22
    Cmd_get_considered_move_power,                  // 0x23
    Cmd_get_how_powerful_move_is,                   // 0x24
    Cmd_get_last_used_battler_move,                 // 0x25
    Cmd_get_target_previous_move_pp,                // 0x26
    Cmd_if_shares_move_with_user,                   // 0x27
    Cmd_if_user_goes,                               // 0x28
    Cmd_if_user_doesnt_go,                          // 0x29
    Cmd_get_considered_move_second_eff_chance,      // 0x2A
    Cmd_get_considered_move_accuracy,               // 0x2B
    Cmd_count_usable_party_mons,                    // 0x2C
    Cmd_get_considered_move,                        // 0x2D
    Cmd_get_considered_move_effect,                 // 0x2E
    Cmd_get_ability,                                // 0x2F
    Cmd_get_highest_type_effectiveness,             // 0x30
    Cmd_if_type_effectiveness,                      // 0x31
    Cmd_if_target,                                  // 0x32
    Cmd_if_type_effectiveness_with_modifiers,       // 0x33
    Cmd_if_status_in_party,                         // 0x34
    Cmd_if_status_not_in_party,                     // 0x35
    Cmd_get_weather,                                // 0x36
    Cmd_if_effect,                                  // 0x37
    Cmd_if_not_effect,                              // 0x38
    Cmd_if_stat_level_less_than,                    // 0x39
    Cmd_if_stat_level_more_than,                    // 0x3A
    Cmd_if_stat_level_equal,                        // 0x3B
    Cmd_if_stat_level_not_equal,                    // 0x3C
    Cmd_if_can_faint,                               // 0x3D
    Cmd_consider_imitated_move,                     // 0x3E
    Cmd_if_has_move,                                // 0x3F
    Cmd_if_doesnt_have_move,                        // 0x40
    Cmd_if_has_move_with_effect,                    // 0x41
    Cmd_if_doesnt_have_move_with_effect,            // 0x42
    Cmd_if_any_move_disabled_or_encored,            // 0x43
    Cmd_if_curr_move_disabled_or_encored,           // 0x44
    Cmd_flee,                                       // 0x45
    Cmd_if_random_safari_flee,                      // 0x46
    Cmd_watch,                                      // 0x47
    Cmd_get_hold_effect,                            // 0x48
    Cmd_get_gender,                                 // 0x49
    Cmd_is_first_turn_for,                          // 0x4A
    Cmd_get_stockpile_count,                        // 0x4B
    Cmd_is_double_battle,                           // 0x4C
    Cmd_get_used_held_item,                         // 0x4D
    Cmd_get_move_type_from_result,                  // 0x4E
    Cmd_get_move_power_from_result,                 // 0x4F
    Cmd_get_move_effect_from_result,                // 0x50
    Cmd_get_protect_count,                          // 0x51
    Cmd_get_move_target_from_result,                // 0x52
    Cmd_get_type_effectiveness_from_result,          // 0x53
    Cmd_get_considered_move_second_eff_chance_from_result, // 0x54
    Cmd_get_spikes_layers_target,                   // 0x55
    Cmd_if_ai_can_faint,                            // 0x56
    Cmd_get_highest_type_effectiveness_from_target, // 0x57
    Cmd_call,                                       // 0x58
    Cmd_goto,                                       // 0x59
    Cmd_end,                                        // 0x5A
    Cmd_if_level_cond,                              // 0x5B
    Cmd_if_target_taunted,                          // 0x5C
    Cmd_if_target_not_taunted,                      // 0x5D
    Cmd_if_target_is_ally,                          // 0x5E
    Cmd_used_considered_move_last_turn,             // 0x5F
    Cmd_check_ability,                              // 0x60
    Cmd_if_flash_fired,                             // 0x61
    Cmd_if_holds_item,                              // 0x62
};

// For the purposes of determining the most powerful move in a moveset, these
// moves are treated the same as having a power of 0 or 1
#define IGNORED_MOVES_END 0xFFFF
static const u16 sIgnoredPowerfulMoveEffects[] =
{
    EFFECT_EXPLOSION,
    EFFECT_DREAM_EATER,
    EFFECT_RAZOR_WIND,
    EFFECT_SKY_ATTACK,
    EFFECT_RECHARGE,
    EFFECT_SKULL_BASH,
    EFFECT_SOLAR_BEAM,
    EFFECT_SPIT_UP,
    EFFECT_FOCUS_PUNCH,
    EFFECT_SUPERPOWER,
    EFFECT_ERUPTION,
    EFFECT_OVERHEAT,
    IGNORED_MOVES_END
};

void BattleAI_HandleItemUseBeforeAISetup(u8 defaultScoreMoves)
{
    s32 i;
    u8 *data = (u8 *)BATTLE_HISTORY;

    DebugPrintf("Running BattleAI_HandleItemUseBeforeAISetup");

    for (i = 0; i < sizeof(struct BattleHistory); i++)
        data[i] = 0;

    // Items are allowed to use in ONLY trainer battles.
    if ((gBattleTypeFlags & BATTLE_TYPE_TRAINER)
        && !(gBattleTypeFlags & (BATTLE_TYPE_LINK | BATTLE_TYPE_SAFARI | BATTLE_TYPE_BATTLE_TOWER
                               | BATTLE_TYPE_EREADER_TRAINER | BATTLE_TYPE_SECRET_BASE | BATTLE_TYPE_FRONTIER
                               | BATTLE_TYPE_INGAME_PARTNER | BATTLE_TYPE_RECORDED_LINK)
            )
       )
    {
        for (i = 0; i < MAX_TRAINER_ITEMS; i++)
        {
            if (gTrainers[gTrainerBattleOpponent_A].items[i] != ITEM_NONE)
            {
                BATTLE_HISTORY->trainerItems[BATTLE_HISTORY->itemsNo] = gTrainers[gTrainerBattleOpponent_A].items[i];
                BATTLE_HISTORY->itemsNo++;
            }
        }
    }

    BattleAI_SetupAIData(defaultScoreMoves);
}

void BattleAI_SetupAIData(u8 defaultScoreMoves)
{
    s32 i;
    u8 *data = (u8 *)AI_THINKING_STRUCT;
    u8 moveLimitations;

    DebugPrintf("Setting up AI data for %d.",gBattleMons[gActiveBattler].species);

    // Clear AI data.
    for (i = 0; i < sizeof(struct AI_ThinkingStruct); i++)
        data[i] = 0;

    // Conditional score reset, unlike Ruby.
    for (i = 0; i < MAX_MON_MOVES; i++)
    {
        if (defaultScoreMoves & 1)
            AI_THINKING_STRUCT->score[i] = 100;
        else
            AI_THINKING_STRUCT->score[i] = 0;

        defaultScoreMoves >>= 1;
    }

    moveLimitations = CheckMoveLimitations(gActiveBattler, 0, MOVE_LIMITATIONS_ALL);

    // Ignore moves that aren't possible to use.
    for (i = 0; i < MAX_MON_MOVES; i++)
    {
        if (gBitTable[i] & moveLimitations)
            AI_THINKING_STRUCT->score[i] = 0;

        AI_THINKING_STRUCT->simulatedRNG[i] = 100 - (Random() % 16);
    }

    gBattleResources->AI_ScriptsStack->size = 0;
    sBattler_AI = gActiveBattler;

    // Decide a random target battlerId in doubles.
    if (gBattleTypeFlags & BATTLE_TYPE_DOUBLE)
    {
        gBattlerTarget = (Random() & BIT_FLANK) + BATTLE_OPPOSITE(GetBattlerSide(gActiveBattler));
        if (gAbsentBattlerFlags & gBitTable[gBattlerTarget])
            gBattlerTarget ^= BIT_FLANK;
    }
    // There's only one choice in single battles.
    else
    {
        gBattlerTarget = BATTLE_OPPOSITE(sBattler_AI);
    }

    // Choose proper trainer ai scripts.
    if (gBattleTypeFlags & BATTLE_TYPE_RECORDED)
        AI_THINKING_STRUCT->aiFlags = GetAiScriptsInRecordedBattle();
    else if (gBattleTypeFlags & BATTLE_TYPE_SAFARI)
        AI_THINKING_STRUCT->aiFlags = AI_SCRIPT_SAFARI;
    else if (gBattleTypeFlags & BATTLE_TYPE_ROAMER)
        AI_THINKING_STRUCT->aiFlags = AI_SCRIPT_ROAMING;
    else if (gBattleTypeFlags & BATTLE_TYPE_FIRST_BATTLE)
        AI_THINKING_STRUCT->aiFlags = AI_SCRIPT_FIRST_BATTLE;
    else if (gBattleTypeFlags & BATTLE_TYPE_FACTORY)
        AI_THINKING_STRUCT->aiFlags = GetAiScriptsInBattleFactory();
    else if (gBattleTypeFlags & (BATTLE_TYPE_FRONTIER | BATTLE_TYPE_EREADER_TRAINER | BATTLE_TYPE_TRAINER_HILL | BATTLE_TYPE_SECRET_BASE))
        AI_THINKING_STRUCT->aiFlags = AI_SCRIPT_CHECK_BAD_MOVE | AI_SCRIPT_CHECK_VIABILITY | AI_SCRIPT_TRY_TO_FAINT;
    else if (gBattleTypeFlags & BATTLE_TYPE_TWO_OPPONENTS)
        AI_THINKING_STRUCT->aiFlags = gTrainers[gTrainerBattleOpponent_A].aiFlags | gTrainers[gTrainerBattleOpponent_B].aiFlags;
    else
       AI_THINKING_STRUCT->aiFlags = gTrainers[gTrainerBattleOpponent_A].aiFlags;

    if (gBattleTypeFlags & BATTLE_TYPE_DOUBLE)
        AI_THINKING_STRUCT->aiFlags |= AI_SCRIPT_DOUBLE_BATTLE; // act smart in doubles and don't attack your partner
}

void BattleAI_ChooseMoveOrAction(void)
{
    u16 savedCurrentMove = gCurrentMove;
    u8 ret;

    DebugPrintf("Choosing move or action for %d.",gBattleMons[gActiveBattler].species);

    if (!(gBattleTypeFlags & BATTLE_TYPE_DOUBLE))
        ret = ChooseMoveOrAction_Singles();
    else
        ret = ChooseMoveOrAction_Doubles();

    DebugPrintf("Move or action chosen for %d. Chosen move: %d.",gBattleMons[gActiveBattler].species,savedCurrentMove);

    gCurrentMove = savedCurrentMove;
    AI_THINKING_STRUCT->chosenMoveId = ret;
    return ret;
}

static u8 ChooseMoveOrAction_Singles(void)
{
    u8 currentMoveArray[MAX_MON_MOVES];
    u8 consideredMoveArray[MAX_MON_MOVES];
    u8 numOfBestMoves;
    s32 i;

    DebugPrintf("Running ChooseMoveOrAction_Singles.");

    RecordLastUsedMoveByTarget();

    while (AI_THINKING_STRUCT->aiFlags != 0)
    {
        if (AI_THINKING_STRUCT->aiFlags & 1)
        {
            AI_THINKING_STRUCT->aiState = AIState_SettingUp;
            BattleAI_DoAIProcessing();
        }
        AI_THINKING_STRUCT->aiFlags >>= 1;
        AI_THINKING_STRUCT->aiLogicId++;
        AI_THINKING_STRUCT->movesetIndex = 0;
    }

    // Check special AI actions.
    if (AI_THINKING_STRUCT->aiAction & AI_ACTION_FLEE)
        return AI_CHOICE_FLEE;
    if (AI_THINKING_STRUCT->aiAction & AI_ACTION_WATCH)
        return AI_CHOICE_WATCH;

    numOfBestMoves = 1;
    currentMoveArray[0] = AI_THINKING_STRUCT->score[0];
    consideredMoveArray[0] = 0;

    DebugPrintf("Looping through move list for %d.",gBattleMons[gActiveBattler].species);

    for (i = 1; i < MAX_MON_MOVES; i++)
    {
        if (gBattleMons[sBattler_AI].moves[i] != MOVE_NONE)
        {
            // In ruby, the order of these if statements is reversed.
            if (currentMoveArray[0] == AI_THINKING_STRUCT->score[i])
            {
                currentMoveArray[numOfBestMoves] = AI_THINKING_STRUCT->score[i];
                consideredMoveArray[numOfBestMoves++] = i;
            }
            if (currentMoveArray[0] < AI_THINKING_STRUCT->score[i])
            {
                numOfBestMoves = 1;
                currentMoveArray[0] = AI_THINKING_STRUCT->score[i];
                consideredMoveArray[0] = i;
            }
        }
    }

    DebugPrintf("Equally good moves found: %d",numOfBestMoves);

    return consideredMoveArray[Random() % numOfBestMoves];
}

static u8 ChooseMoveOrAction_Doubles(void)
{
    s32 i;
    s32 j;
    s32 scriptsToRun;
    // the value assigned to this is a u32 (aiFlags)
    // this becomes relevant because aiFlags can have bit 31 set
    // and scriptsToRun is shifted
    // this never happens in the vanilla game because bit 31 is
    // only set when it's the first battle
    s16 bestMovePointsForTarget[MAX_BATTLERS_COUNT];
    s8 mostViableTargetsArray[MAX_BATTLERS_COUNT];
    u8 actionOrMoveIndex[MAX_BATTLERS_COUNT];
    u8 mostViableMovesScores[MAX_MON_MOVES];
    u8 mostViableMovesIndices[MAX_MON_MOVES];
    s32 mostViableTargetsNo;
    s32 mostViableMovesNo;
    s16 mostMovePoints;

    DebugPrintf("Running ChooseMoveOrAction_Doubles");

    for (i = 0; i < MAX_BATTLERS_COUNT; i++)
    {
        if (i == sBattler_AI || gBattleMons[i].hp == 0)
        {
            actionOrMoveIndex[i] = 0xFF;
            bestMovePointsForTarget[i] = -1;
        }
        else
        {
            if (gBattleTypeFlags & BATTLE_TYPE_PALACE)
                BattleAI_SetupAIData(gBattleStruct->palaceFlags >> MAX_BATTLERS_COUNT);
            else
                BattleAI_SetupAIData(ALL_MOVES_MASK);

            gBattlerTarget = i;

            if ((i & BIT_SIDE) != (sBattler_AI & BIT_SIDE))
                RecordLastUsedMoveByTarget();

            AI_THINKING_STRUCT->aiLogicId = 0;
            AI_THINKING_STRUCT->movesetIndex = 0;
            scriptsToRun = AI_THINKING_STRUCT->aiFlags;
            while (scriptsToRun != 0)
            {
                if (scriptsToRun & 1)
                {
                    AI_THINKING_STRUCT->aiState = AIState_SettingUp;
                    BattleAI_DoAIProcessing();
                }
                scriptsToRun >>= 1;
                AI_THINKING_STRUCT->aiLogicId++;
                AI_THINKING_STRUCT->movesetIndex = 0;
            }

            if (AI_THINKING_STRUCT->aiAction & AI_ACTION_FLEE)
            {
                actionOrMoveIndex[i] = AI_CHOICE_FLEE;
            }
            else if (AI_THINKING_STRUCT->aiAction & AI_ACTION_WATCH)
            {
                actionOrMoveIndex[i] = AI_CHOICE_WATCH;
            }
            else
            {
                mostViableMovesScores[0] = AI_THINKING_STRUCT->score[0];
                mostViableMovesIndices[0] = 0;
                mostViableMovesNo = 1;
                for (j = 1; j < MAX_MON_MOVES; j++)
                {
                    if (gBattleMons[sBattler_AI].moves[j] != 0)
                    {
                        if (mostViableMovesScores[0] == AI_THINKING_STRUCT->score[j])
                        {
                            mostViableMovesScores[mostViableMovesNo] = AI_THINKING_STRUCT->score[j];
                            mostViableMovesIndices[mostViableMovesNo] = j;
                            mostViableMovesNo++;
                        }
                        if (mostViableMovesScores[0] < AI_THINKING_STRUCT->score[j])
                        {
                            mostViableMovesScores[0] = AI_THINKING_STRUCT->score[j];
                            mostViableMovesIndices[0] = j;
                            mostViableMovesNo = 1;
                        }
                    }
                }
                actionOrMoveIndex[i] = mostViableMovesIndices[Random() % mostViableMovesNo];
                bestMovePointsForTarget[i] = mostViableMovesScores[0];

                // Don't use a move against ally if it has less than 100 points.
                if (i == BATTLE_PARTNER(sBattler_AI) && bestMovePointsForTarget[i] < 100)
                {
                    bestMovePointsForTarget[i] = -1;
                    mostViableMovesScores[0] = mostViableMovesScores[0]; // Needed to match.
                }
            }
        }
    }

    mostMovePoints = bestMovePointsForTarget[0];
    mostViableTargetsArray[0] = 0;
    mostViableTargetsNo = 1;

    for (i = 1; i < MAX_BATTLERS_COUNT; i++)
    {
        if (mostMovePoints == bestMovePointsForTarget[i])
        {
            mostViableTargetsArray[mostViableTargetsNo] = i;
            mostViableTargetsNo++;
        }
        if (mostMovePoints < bestMovePointsForTarget[i])
        {
            mostMovePoints = bestMovePointsForTarget[i];
            mostViableTargetsArray[0] = i;
            mostViableTargetsNo = 1;
        }
    }

    gBattlerTarget = mostViableTargetsArray[Random() % mostViableTargetsNo];
    return actionOrMoveIndex[gBattlerTarget];
}

static void BattleAI_DoAIProcessing(void)
{
    DebugPrintf("Running BattleAI_DoAIProcessing");

    while (AI_THINKING_STRUCT->aiState != AIState_FinishedProcessing)
    {
        switch (AI_THINKING_STRUCT->aiState)
        {
            case AIState_DoNotProcess: // Needed to match.
                break;
            case AIState_SettingUp:
                gAIScriptPtr = gBattleAI_ScriptsTable[AI_THINKING_STRUCT->aiLogicId]; // set AI ptr to logic ID.
                if (gBattleMons[sBattler_AI].pp[AI_THINKING_STRUCT->movesetIndex] == 0)
                {
                    AI_THINKING_STRUCT->moveConsidered = 0;
                }
                else
                {
                    AI_THINKING_STRUCT->moveConsidered = gBattleMons[sBattler_AI].moves[AI_THINKING_STRUCT->movesetIndex];
                }
                AI_THINKING_STRUCT->aiState++;
                break;
            case AIState_Processing:
                if (AI_THINKING_STRUCT->moveConsidered != 0)
                {
                    sBattleAICmdTable[*gAIScriptPtr](); // Run AI command.
                }
                else
                {
                    AI_THINKING_STRUCT->score[AI_THINKING_STRUCT->movesetIndex] = 0;
                    AI_THINKING_STRUCT->aiAction |= AI_ACTION_DONE;
                }
                if (AI_THINKING_STRUCT->aiAction & AI_ACTION_DONE)
                {
                   AI_THINKING_STRUCT->movesetIndex++;

                    if (AI_THINKING_STRUCT->movesetIndex < MAX_MON_MOVES && !(AI_THINKING_STRUCT->aiAction & AI_ACTION_DO_NOT_ATTACK))
                        AI_THINKING_STRUCT->aiState = AIState_SettingUp;
                    else
                        AI_THINKING_STRUCT->aiState++;

                    AI_THINKING_STRUCT->aiAction &= ~(AI_ACTION_DONE);
                }
                break;
        }
    }
}

static void RecordLastUsedMoveByTarget(void)
{
    s32 i;

    DebugPrintf("Running RecordLastUsedMoveByTarget");

    for (i = 0; i < MAX_MON_MOVES; i++)
    {
        if (BATTLE_HISTORY->usedMoves[gBattlerTarget].moves[i] == gLastMoves[gBattlerTarget])
            break;

        if (BATTLE_HISTORY->usedMoves[gBattlerTarget].moves[i] == MOVE_NONE)
        {
            BATTLE_HISTORY->usedMoves[gBattlerTarget].moves[i] = gLastMoves[gBattlerTarget];
            break;
        }
    }
}

void ClearBattlerMoveHistory(u8 battlerId)
{
    s32 i;

    DebugPrintf("Running ClearBattlerMoveHistory");

    for (i = 0; i < MAX_MON_MOVES; i++)
        BATTLE_HISTORY->usedMoves[battlerId].moves[i] = MOVE_NONE;
}

void RecordAbilityBattle(u8 battlerId, u8 abilityId)
{
    DebugPrintf("Running RecordAbilityBattle");
    BATTLE_HISTORY->abilities[battlerId] = abilityId;
}

void ClearBattlerAbilityHistory(u8 battlerId)
{
    DebugPrintf("Running ClearBattlerAbilityHistory");
    BATTLE_HISTORY->abilities[battlerId] = ABILITY_NONE;
}

void RecordItemEffectBattle(u8 battlerId, u8 itemEffect)
{
    DebugPrintf("Running RecordItemEffectBattle");
    BATTLE_HISTORY->itemEffects[battlerId] = itemEffect;
}

void ClearBattlerItemEffectHistory(u8 battlerId)
{
    DebugPrintf("Running ClearBattlerItemEffectHistory");
    BATTLE_HISTORY->itemEffects[battlerId] = 0;
}

static void Cmd_if_random_less_than(void)
{
    u16 random = Random();

    DebugPrintf("Running if_random_less_than");

    if (random % 256 < gAIScriptPtr[1])
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 2);
    else
        gAIScriptPtr += 6;
}

static void Cmd_if_random_greater_than(void)
{
    u16 random = Random();

    DebugPrintf("Running if_random_greater_than");

    if (random % 256 > gAIScriptPtr[1])
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 2);
    else
        gAIScriptPtr += 6;
}

static void Cmd_if_waking(void)
{
    u8 battlerId;

    DebugPrintf("if_waking checked for %d.",gBattleMons[gActiveBattler].species);

    if (gAIScriptPtr[1] == AI_USER)
        battlerId = sBattler_AI;
    else
        battlerId = gBattlerTarget;

    if ((gBattleMons[battlerId].status1 & STATUS1_SLEEP) > STATUS1_SLEEP_TURN(1))
        gAIScriptPtr += 6;
    else
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 2);
}

static void Cmd_if_badly_poisoned_for_turns(void)
{
    u8 battlerId;

    DebugPrintf("Cmd_if_badly_poisoned_for_turns checked for %d.",gBattleMons[gActiveBattler].species);

    if (gAIScriptPtr[1] == AI_USER)
        battlerId = sBattler_AI;
    else
        battlerId = gBattlerTarget;

    if ((gBattleMons[battlerId].status1 & STATUS1_TOXIC_COUNTER) >= STATUS1_TOXIC_TURN(gAIScriptPtr[2]))
    {
        DebugPrintf("Target badly poisoned for enough turns.");
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 3);
    }
    else
    {
        DebugPrintf("Target not badly poisoned for enough turns.");
        gAIScriptPtr += 7;
    }
}

static void Cmd_score(void)
{
    DebugPrintf("Score incremented by %d.",(signed char) gAIScriptPtr[1]);

    AI_THINKING_STRUCT->score[AI_THINKING_STRUCT->movesetIndex] += gAIScriptPtr[1]; // Add the result to the array of the move consider's score.

    if (AI_THINKING_STRUCT->score[AI_THINKING_STRUCT->movesetIndex] < 0) // If the score is negative, flatten it to 0.
        AI_THINKING_STRUCT->score[AI_THINKING_STRUCT->movesetIndex] = 0;

    gAIScriptPtr += 2; // AI return.
}

static void Cmd_if_hp_less_than(void)
{
    u16 battlerId;

    DebugPrintf("Running if_hp_less_than");

    if (gAIScriptPtr[1] == AI_USER)
        battlerId = sBattler_AI;
    else
        battlerId = gBattlerTarget;

    if ((u32)(100 * gBattleMons[battlerId].hp / gBattleMons[battlerId].maxHP) < gAIScriptPtr[2])
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 3);
    else
        gAIScriptPtr += 7;
}

static void Cmd_if_hp_more_than(void)
{
    u16 battlerId;

    DebugPrintf("Running if_hp_more_than");

    if (gAIScriptPtr[1] == AI_USER)
        battlerId = sBattler_AI;
    else
        battlerId = gBattlerTarget;

    if ((u32)(100 * gBattleMons[battlerId].hp / gBattleMons[battlerId].maxHP) > gAIScriptPtr[2])
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 3);
    else
        gAIScriptPtr += 7;
}

static void Cmd_if_hp_equal(void)
{
    u16 battlerId;

    DebugPrintf("Running if_hp_equal");

    if (gAIScriptPtr[1] == AI_USER)
        battlerId = sBattler_AI;
    else
        battlerId = gBattlerTarget;

    if ((u32)(100 * gBattleMons[battlerId].hp / gBattleMons[battlerId].maxHP) == gAIScriptPtr[2])
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 3);
    else
        gAIScriptPtr += 7;
}

static void Cmd_if_hp_not_equal(void)
{
    u16 battlerId;

    DebugPrintf("Running if_hp_not_equal");

    if (gAIScriptPtr[1] == AI_USER)
        battlerId = sBattler_AI;
    else
        battlerId = gBattlerTarget;

    if ((u32)(100 * gBattleMons[battlerId].hp / gBattleMons[battlerId].maxHP) != gAIScriptPtr[2])
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 3);
    else
        gAIScriptPtr += 7;
}

static void Cmd_if_status(void)
{
    u16 battlerId;
    u32 status;

    DebugPrintf("Running if_status");

    if (gAIScriptPtr[1] == AI_USER)
        battlerId = sBattler_AI;
    else
        battlerId = gBattlerTarget;

    status = T1_READ_32(gAIScriptPtr + 2);

    if (gBattleMons[battlerId].status1 & status)
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 6);
    else
        gAIScriptPtr += 10;
}

static void Cmd_if_not_status(void)
{
    u16 battlerId;
    u32 status;

    DebugPrintf("Running if_not_status");

    if (gAIScriptPtr[1] == AI_USER)
        battlerId = sBattler_AI;
    else
        battlerId = gBattlerTarget;

    status = T1_READ_32(gAIScriptPtr + 2);

    if (!(gBattleMons[battlerId].status1 & status))
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 6);
    else
        gAIScriptPtr += 10;
}

static void Cmd_if_status2(void)
{
    u16 battlerId;
    u32 status;

    DebugPrintf("Running if_status2");

    if (gAIScriptPtr[1] == AI_USER)
        battlerId = sBattler_AI;
    else
        battlerId = gBattlerTarget;

    status = T1_READ_32(gAIScriptPtr + 2);

    if ((gBattleMons[battlerId].status2 & status))
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 6);
    else
        gAIScriptPtr += 10;
}

static void Cmd_if_not_status2(void)
{
    u16 battlerId;
    u32 status;

    DebugPrintf("Running if_not_status2");

    if (gAIScriptPtr[1] == AI_USER)
        battlerId = sBattler_AI;
    else
        battlerId = gBattlerTarget;

    status = T1_READ_32(gAIScriptPtr + 2);

    if (!(gBattleMons[battlerId].status2 & status))
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 6);
    else
        gAIScriptPtr += 10;
}

static void Cmd_if_status3(void)
{
    u16 battlerId;
    u32 status;

    DebugPrintf("Running if_status3");

    if (gAIScriptPtr[1] == AI_USER)
        battlerId = sBattler_AI;
    else
        battlerId = gBattlerTarget;

    status = T1_READ_32(gAIScriptPtr + 2);

    if (gStatuses3[battlerId] & status)
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 6);
    else
        gAIScriptPtr += 10;
}

static void Cmd_if_can_use_substitute(void)
{
    u16 battlerId;

    DebugPrintf("Running if_can_use_substitute");

    if (gAIScriptPtr[1] == AI_USER)
        battlerId = sBattler_AI;
    else
        battlerId = gBattlerTarget;

    if ((u32)(4 * gBattleMons[battlerId].hp) <= gBattleMons[battlerId].maxHP)
        gAIScriptPtr += 6;
    else
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 2);
}

static void Cmd_if_side_affecting(void)
{
    u16 battlerId;
    u32 side, status;

    DebugPrintf("Running if_side_affecting");

    if (gAIScriptPtr[1] == AI_USER)
        battlerId = sBattler_AI;
    else
        battlerId = gBattlerTarget;

    side = GET_BATTLER_SIDE(battlerId);
    status = T1_READ_32(gAIScriptPtr + 2);

    if (gSideStatuses[side] & status)
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 6);
    else
        gAIScriptPtr += 10;
}

static void Cmd_if_not_side_affecting(void)
{
    u16 battlerId;
    u32 side, status;

    DebugPrintf("Running if_not_side_affecting");

    if (gAIScriptPtr[1] == AI_USER)
        battlerId = sBattler_AI;
    else
        battlerId = gBattlerTarget;

    side = GET_BATTLER_SIDE(battlerId);
    status = T1_READ_32(gAIScriptPtr + 2);

    if (!(gSideStatuses[side] & status))
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 6);
    else
        gAIScriptPtr += 10;
}

static void Cmd_if_less_than(void)
{
    DebugPrintf("Running if_less_than");

    if (AI_THINKING_STRUCT->funcResult < gAIScriptPtr[1])
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 2);
    else
        gAIScriptPtr += 6;
}

static void Cmd_if_more_than(void)
{
    DebugPrintf("Running if_more_than");

    if (AI_THINKING_STRUCT->funcResult > gAIScriptPtr[1])
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 2);
    else
        gAIScriptPtr += 6;
}

static void Cmd_if_equal(void)
{
    DebugPrintf("Running if_equal");

    if (AI_THINKING_STRUCT->funcResult == gAIScriptPtr[1])
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 2);
    else
        gAIScriptPtr += 6;
}

static void Cmd_if_not_equal(void)
{
    DebugPrintf("Running if_not_equal");

    if (AI_THINKING_STRUCT->funcResult != gAIScriptPtr[1])
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 2);
    else
        gAIScriptPtr += 6;
}

static void Cmd_if_less_than_ptr(void)
{
    const u8 *value = T1_READ_PTR(gAIScriptPtr + 1);

    DebugPrintf("Running if_less_than_ptr");

    if (AI_THINKING_STRUCT->funcResult < *value)
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 5);
    else
        gAIScriptPtr += 9;
}

static void Cmd_if_more_than_ptr(void)
{
    const u8 *value = T1_READ_PTR(gAIScriptPtr + 1);

    DebugPrintf("Running if_more_than_ptr");

    if (AI_THINKING_STRUCT->funcResult > *value)
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 5);
    else
        gAIScriptPtr += 9;
}

static void Cmd_if_has_attack_of_type(void)
{
    u8 battlerId, moveFound;
    s32 i;

    DebugPrintf("Running if_has_attack_of_type");

    if (gAIScriptPtr[1] == AI_USER)
        battlerId = sBattler_AI;
    else
        battlerId = gBattlerTarget;

    moveFound = FALSE;

    for (i = 0; i < MAX_MON_MOVES; i++)
        {
            if(gBattleMoves[gBattleMons[battlerId].moves[i]].type == gAIScriptPtr[2] && gBattleMoves[gBattleMons[battlerId].moves[i]].power > 0)
                moveFound = TRUE;
        }

    DebugPrintf("Result: %d",moveFound);

    if (moveFound == TRUE)
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 3);
    else
        gAIScriptPtr += 7;
}

static void Cmd_if_has_attack_of_category(void)
{
    u8 battlerId, moveFound;
    s32 i;

    DebugPrintf("Running Cmd_if_has_attack_of_category");

    if (gAIScriptPtr[1] == AI_USER)
        battlerId = sBattler_AI;
    else
        battlerId = gBattlerTarget;

    moveFound = FALSE;

    if (gAIScriptPtr[2] == TYPE_PHYSICAL)
    {
        DebugPrintf("Checking for a physical move");

        for (i = 0; i < MAX_MON_MOVES; i++)
            {
                if(IS_TYPE_PHYSICAL(gBattleMoves[gBattleMons[battlerId].moves[i]].type) && gBattleMoves[gBattleMons[battlerId].moves[i]].effect != EFFECT_HIDDEN_POWER)
                    {
                        moveFound = TRUE;
                        break;
                    }
            }
    }
    else
    {
        DebugPrintf("Checking for a special move");

        for (i = 0; i < MAX_MON_MOVES; i++)
            {
                if(IS_TYPE_SPECIAL(gBattleMoves[gBattleMons[battlerId].moves[i]].type) && gBattleMoves[gBattleMons[battlerId].moves[i]].effect != EFFECT_HIDDEN_POWER)
                    {
                        moveFound = TRUE;
                        break;
                    }
            }
    }

    DebugPrintf("Result: %d",moveFound);

    if (moveFound == TRUE)
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 3);
    else
        gAIScriptPtr += 7;
}

static void Cmd_if_move(void)
{
    u16 move = T1_READ_16(gAIScriptPtr + 1);

    // DebugPrintf("Running if_move");

    if (AI_THINKING_STRUCT->moveConsidered == move)
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 3);
    else
        gAIScriptPtr += 7;
}

static void Cmd_if_not_move(void)
{
    u16 move = T1_READ_16(gAIScriptPtr + 1);

    DebugPrintf("Running if_not_move");

    if (AI_THINKING_STRUCT->moveConsidered != move)
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 3);
    else
        gAIScriptPtr += 7;
}

static void Cmd_if_in_bytes(void)
{
    const u8 *ptr = T1_READ_PTR(gAIScriptPtr + 1);

    // DebugPrintf("Running if_in_bytes");

    while (*ptr != 0xFF)
    {
        if (AI_THINKING_STRUCT->funcResult == *ptr)
        {
            gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 5);
            return;
        }
        ptr++;
    }
    gAIScriptPtr += 9;
}

static void Cmd_if_not_in_bytes(void)
{
    const u8 *ptr = T1_READ_PTR(gAIScriptPtr + 1);

    DebugPrintf("Running if_not_in_bytes");

    while (*ptr != 0xFF)
    {
        if (AI_THINKING_STRUCT->funcResult == *ptr)
        {
            gAIScriptPtr += 9;
            return;
        }
        ptr++;
    }
    gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 5);
}

static void Cmd_if_in_hwords(void)
{
    const u16 *ptr = (const u16 *)T1_READ_PTR(gAIScriptPtr + 1);

    DebugPrintf("Running if_in_hwords");

    while (*ptr != 0xFFFF)
    {
        if (AI_THINKING_STRUCT->funcResult == *ptr)
        {
            gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 5);
            return;
        }
        ptr++;
    }
    gAIScriptPtr += 9;
}

static void Cmd_check_curr_move_has_stab(void)
{
    DebugPrintf("Running check_curr_move_has_stab");

    if (gBattleMons[sBattler_AI].type1 == AI_THINKING_STRUCT->moveConsidered
        || gBattleMons[sBattler_AI].type2 == AI_THINKING_STRUCT->moveConsidered)
        AI_THINKING_STRUCT->funcResult = TRUE;
    else
        AI_THINKING_STRUCT->funcResult = FALSE;

    DebugPrintf("Result: %d",AI_THINKING_STRUCT->funcResult);

    gAIScriptPtr += 1;
}

static void Cmd_if_user_has_attacking_move(void)
{
    s32 i;

    DebugPrintf("Running if_user_has_attacking_move");

    for (i = 0; i < MAX_MON_MOVES; i++)
    {
        if (gBattleMons[sBattler_AI].moves[i] != 0
            && gBattleMoves[gBattleMons[sBattler_AI].moves[i]].power != 0)
            break;
    }

    DebugPrintf("Result: %d",i);

    if (i == MAX_MON_MOVES)
        gAIScriptPtr += 5;
    else
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 1);
}

static void Cmd_if_user_has_no_attacking_moves(void)
{
    s32 i;

    DebugPrintf("Running if_user_has_no_attacking_moves");

    for (i = 0; i < MAX_MON_MOVES; i++)
    {
        if (gBattleMons[sBattler_AI].moves[i] != 0
         && gBattleMoves[gBattleMons[sBattler_AI].moves[i]].power != 0)
            break;
    }

    if (i != MAX_MON_MOVES)
        gAIScriptPtr += 5;
    else
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 1);
}

static void Cmd_get_turn_count(void)
{
    DebugPrintf("Turn count called.");

    AI_THINKING_STRUCT->funcResult = gBattleResults.battleTurnCounter;
    gAIScriptPtr += 1;
}

static void Cmd_get_type(void)
{
    u8 typeVar = gAIScriptPtr[1];

    DebugPrintf("Running get_type");

    switch (typeVar)
    {
    case AI_TYPE1_USER: // AI user primary type
        AI_THINKING_STRUCT->funcResult = gBattleMons[sBattler_AI].type1;
        break;
    case AI_TYPE1_TARGET: // target primary type
        AI_THINKING_STRUCT->funcResult = gBattleMons[gBattlerTarget].type1;
        break;
    case AI_TYPE2_USER: // AI user secondary type
        AI_THINKING_STRUCT->funcResult = gBattleMons[sBattler_AI].type2;
        break;
    case AI_TYPE2_TARGET: // target secondary type
        AI_THINKING_STRUCT->funcResult = gBattleMons[gBattlerTarget].type2;
        break;
    case AI_TYPE_MOVE: // type of move being pointed to
        AI_THINKING_STRUCT->funcResult = gBattleMoves[AI_THINKING_STRUCT->moveConsidered].type;
        break;
    case AI_TYPE1_USER_PARTNER: // AI partner primary type
        AI_THINKING_STRUCT->funcResult = gBattleMons[BATTLE_PARTNER(sBattler_AI)].type1;
        break;
    case AI_TYPE1_TARGET_PARTNER: // target partner primary type
        AI_THINKING_STRUCT->funcResult = gBattleMons[BATTLE_PARTNER(gBattlerTarget)].type1;
        break;
    case AI_TYPE2_USER_PARTNER: // AI partner secondary type
        AI_THINKING_STRUCT->funcResult = gBattleMons[BATTLE_PARTNER(sBattler_AI)].type2;
        break;
    case AI_TYPE2_TARGET_PARTNER: // target partner secondary type
        AI_THINKING_STRUCT->funcResult = gBattleMons[BATTLE_PARTNER(gBattlerTarget)].type2;
        break;
    }

    gAIScriptPtr += 2;
}

static u8 BattleAI_GetWantedBattler(u8 wantedBattler)
{
    DebugPrintf("Running BattleAI_GetWantedBattler");

    switch (wantedBattler)
    {
    case AI_USER:
        return sBattler_AI;
    case AI_TARGET:
    default:
        return gBattlerTarget;
    case AI_USER_PARTNER:
        return BATTLE_PARTNER(sBattler_AI);
    case AI_TARGET_PARTNER:
        return BATTLE_PARTNER(gBattlerTarget);
    }
}

static void Cmd_used_considered_move_last_turn(void)
{
    DebugPrintf("Running used_considered_move_last_turn");

    if (gLastMoves[sBattler_AI] == AI_THINKING_STRUCT->moveConsidered)
        AI_THINKING_STRUCT->funcResult = TRUE;
    else
        AI_THINKING_STRUCT->funcResult = FALSE;

    gAIScriptPtr += 1;
}

static void Cmd_get_considered_move_power(void)
{
    DebugPrintf("Running get_considered_move_power");
    AI_THINKING_STRUCT->funcResult = gBattleMoves[AI_THINKING_STRUCT->moveConsidered].power;
    gAIScriptPtr += 1;
}

static void Cmd_get_how_powerful_move_is(void)
{
    s32 i, checkedMove;
    s32 moveDmgs[MAX_MON_MOVES];

    DebugPrintf("Running get_how_powerful_move_is");

    for (i = 0; sIgnoredPowerfulMoveEffects[i] != IGNORED_MOVES_END; i++)
    {
        if (gBattleMoves[AI_THINKING_STRUCT->moveConsidered].effect == sIgnoredPowerfulMoveEffects[i])
            break;
    }

    if (gBattleMoves[AI_THINKING_STRUCT->moveConsidered].power > 1
        && sIgnoredPowerfulMoveEffects[i] == IGNORED_MOVES_END)
    {
        gDynamicBasePower = 0;
        *(&gBattleStruct->dynamicMoveType) = 0;
        gBattleScripting.dmgMultiplier = 1;
        gMoveResultFlags = 0;
        gCritMultiplier = 1;

        // Considered move has power and is not in sIgnoredPowerfulMoveEffects
        // Check all other moves and calculate their power
        for (checkedMove = 0; checkedMove < MAX_MON_MOVES; checkedMove++)
        {
            for (i = 0; sIgnoredPowerfulMoveEffects[i] != IGNORED_MOVES_END; i++)
            {
                if (gBattleMoves[gBattleMons[sBattler_AI].moves[checkedMove]].effect == sIgnoredPowerfulMoveEffects[i])
                    break;
            }

            if (gBattleMons[sBattler_AI].moves[checkedMove] != MOVE_NONE
                && sIgnoredPowerfulMoveEffects[i] == IGNORED_MOVES_END
                && gBattleMoves[gBattleMons[sBattler_AI].moves[checkedMove]].power > 1)
            {
                gCurrentMove = gBattleMons[sBattler_AI].moves[checkedMove];
                AI_CalcDmg(sBattler_AI, gBattlerTarget);
                TypeCalc(gCurrentMove, sBattler_AI, gBattlerTarget);
                moveDmgs[checkedMove] = gBattleMoveDamage * AI_THINKING_STRUCT->simulatedRNG[checkedMove] / 100;
                if (moveDmgs[checkedMove] == 0)
                    moveDmgs[checkedMove] = 1;
            }
            else
            {
                moveDmgs[checkedMove] = 0;
            }
        }

        // Is the considered move the most powerful move available?
        for (checkedMove = 0; checkedMove < MAX_MON_MOVES; checkedMove++)
        {
            if (moveDmgs[checkedMove] > moveDmgs[AI_THINKING_STRUCT->movesetIndex])
                break;
        }

        if (checkedMove == MAX_MON_MOVES)
            AI_THINKING_STRUCT->funcResult = MOVE_MOST_POWERFUL;
        else
            AI_THINKING_STRUCT->funcResult = MOVE_NOT_MOST_POWERFUL;
    }
    else
    {
        // Move has a power of 0/1, or is in the group sIgnoredPowerfulMoveEffects
        AI_THINKING_STRUCT->funcResult = MOVE_POWER_OTHER;
    }

    gAIScriptPtr++;
}

static void Cmd_get_last_used_battler_move(void)
{
    DebugPrintf("Running get_last_used_battler_move");

    if (gAIScriptPtr[1] == AI_USER)
        AI_THINKING_STRUCT->funcResult = gLastMoves[sBattler_AI];
    else
        AI_THINKING_STRUCT->funcResult = gLastMoves[gBattlerTarget];

    gAIScriptPtr += 2;
}

static void Cmd_get_target_previous_move_pp(void)
{
    s32 i;

    DebugPrintf("Running get_target_previous_move_pp");

    AI_THINKING_STRUCT->funcResult = 0;

    for (i = 0; i < MAX_MON_MOVES; i++)
    {
        if (gBattleMons[sBattler_AI].moves[i] == gLastMoves[gBattlerTarget])
        {
            AI_THINKING_STRUCT->funcResult = gBattleMons[gBattlerTarget].pp[i];
        }
    }

    gAIScriptPtr += 1;
}

static void Cmd_if_shares_move_with_user(void)
{
    u8 moveFound;
    s32 i,j;

    DebugPrintf("Running Cmd_if_shares_move_with_user");

    moveFound = FALSE;

    for (i = 0; i < MAX_MON_MOVES; i++)
        {
            if (gBattleMons[sBattler_AI].moves[i] != 0 && moveFound == FALSE)
                {
                    for (j = 0; j < MAX_MON_MOVES; j++)
                        {
                            if (gBattleMons[sBattler_AI].moves[i] == gBattleMons[gBattlerTarget].moves[j])
                                {
                                    moveFound = TRUE;
                                    break;
                                }
                        }
                }
        }

    DebugPrintf("Result: %d",moveFound);

    if (moveFound == TRUE)
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 1);
    else
        gAIScriptPtr += 5;
}

static void Cmd_if_user_goes(void)
{
    DebugPrintf("Running if_user_goes");

    if (GetWhoStrikesFirst(sBattler_AI, gBattlerTarget, TRUE) == gAIScriptPtr[1])
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 2);
    else
        gAIScriptPtr += 6;
}

static void Cmd_if_user_doesnt_go(void)
{
    DebugPrintf("Running if_user_doesnt_go");

    if (GetWhoStrikesFirst(sBattler_AI, gBattlerTarget, TRUE) != gAIScriptPtr[1])
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 2);
    else
        gAIScriptPtr += 6;
}

static void Cmd_get_considered_move_second_eff_chance(void)
{
    DebugPrintf("Running get_considered_move_second_eff_chance");
    AI_THINKING_STRUCT->funcResult = gBattleMoves[AI_THINKING_STRUCT->moveConsidered].secondaryEffectChance;
    gAIScriptPtr += 1;
}

static void Cmd_get_considered_move_accuracy(void)
{
    DebugPrintf("Running get_considered_move_accuracy");

    if (gBattleMoves[AI_THINKING_STRUCT->moveConsidered].effect == EFFECT_ALWAYS_HIT)
        AI_THINKING_STRUCT->funcResult = 100;
    else
        AI_THINKING_STRUCT->funcResult = gBattleMoves[AI_THINKING_STRUCT->moveConsidered].accuracy;

    gAIScriptPtr += 1;
}

static void Cmd_count_usable_party_mons(void)
{
    u8 battlerId;
    u8 battlerOnField1, battlerOnField2;
    struct Pokemon *party;
    s32 i;

    DebugPrintf("Running count_usable_party_mons");

    AI_THINKING_STRUCT->funcResult = 0;

    if (gAIScriptPtr[1] == AI_USER)
        battlerId = sBattler_AI;
    else
        battlerId = gBattlerTarget;

    if (GetBattlerSide(battlerId) == B_SIDE_PLAYER)
        party = gPlayerParty;
    else
        party = gEnemyParty;

    if (gBattleTypeFlags & BATTLE_TYPE_DOUBLE)
    {
        u32 position;
        battlerOnField1 = gBattlerPartyIndexes[battlerId];
        position = BATTLE_PARTNER(GetBattlerPosition(battlerId));
        battlerOnField2 = gBattlerPartyIndexes[GetBattlerAtPosition(position)];
    }
    else // In singles there's only one battlerId by side.
    {
        battlerOnField1 = gBattlerPartyIndexes[battlerId];
        battlerOnField2 = gBattlerPartyIndexes[battlerId];
    }

    for (i = 0; i < PARTY_SIZE; i++)
    {
        if (i != battlerOnField1 && i != battlerOnField2
         && GetMonData(&party[i], MON_DATA_HP) != 0
         && GetMonData(&party[i], MON_DATA_SPECIES_OR_EGG) != SPECIES_NONE
         && GetMonData(&party[i], MON_DATA_SPECIES_OR_EGG) != SPECIES_EGG)
        {
            AI_THINKING_STRUCT->funcResult++;
        }
    }

    gAIScriptPtr += 2;
}

static void Cmd_get_considered_move(void)
{
    DebugPrintf("Running get_considered_move");
    AI_THINKING_STRUCT->funcResult = AI_THINKING_STRUCT->moveConsidered;
    gAIScriptPtr += 1;
}

static void Cmd_get_considered_move_effect(void)
{
    DebugPrintf("Running get_considered_move_effect");
    AI_THINKING_STRUCT->funcResult = gBattleMoves[AI_THINKING_STRUCT->moveConsidered].effect;
    gAIScriptPtr += 1;
}

static void Cmd_get_ability(void)
{
    u8 battlerId;

    DebugPrintf("Running get_ability");

    if (gAIScriptPtr[1] == AI_USER)
        battlerId = sBattler_AI;
    else
        battlerId = gBattlerTarget;

    AI_THINKING_STRUCT->funcResult = gBattleMons[battlerId].ability;
    gAIScriptPtr += 2;
}

static void Cmd_check_ability(void)
{
    u32 battlerId = BattleAI_GetWantedBattler(gAIScriptPtr[1]);
    u32 ability = gAIScriptPtr[2];

    DebugPrintf("This command is not used.");

    if (gAIScriptPtr[1] == AI_TARGET || gAIScriptPtr[1] == AI_TARGET_PARTNER)
    {
        if (BATTLE_HISTORY->abilities[battlerId] != ABILITY_NONE)
        {
            ability = BATTLE_HISTORY->abilities[battlerId];
            AI_THINKING_STRUCT->funcResult = ability;
        }
        // Abilities that prevent fleeing.
        else if (gBattleMons[battlerId].ability == ABILITY_SHADOW_TAG
        || gBattleMons[battlerId].ability == ABILITY_MAGNET_PULL
        || gBattleMons[battlerId].ability == ABILITY_ARENA_TRAP)
        {
            ability = gBattleMons[battlerId].ability;
        }
        else if (gSpeciesInfo[gBattleMons[battlerId].species].abilities[0] != ABILITY_NONE)
        {
            if (gSpeciesInfo[gBattleMons[battlerId].species].abilities[1] != ABILITY_NONE)
            {
                u8 abilityDummyVariable = ability; // Needed to match.
                if (gSpeciesInfo[gBattleMons[battlerId].species].abilities[0] != abilityDummyVariable
                && gSpeciesInfo[gBattleMons[battlerId].species].abilities[1] != abilityDummyVariable)
                {
                    ability = gSpeciesInfo[gBattleMons[battlerId].species].abilities[0];
                }
                else
                {
                    ability = ABILITY_NONE;
                }
            }
            else
            {
                ability = gSpeciesInfo[gBattleMons[battlerId].species].abilities[0];
            }
        }
        else
        {
            ability = gSpeciesInfo[gBattleMons[battlerId].species].abilities[1]; // AI can't actually reach this part since no pokemon has ability 2 and no ability 1.
        }
    }
    else
    {
        // The AI knows its own or partner's ability.
        ability = gBattleMons[battlerId].ability;
    }

    if (ability == 0)
        AI_THINKING_STRUCT->funcResult = 2; // Unable to answer.
    else if (ability == gAIScriptPtr[2])
        AI_THINKING_STRUCT->funcResult = 1; // Pokemon has the ability we wanted to check.
    else
        AI_THINKING_STRUCT->funcResult = 0; // Pokemon doesn't have the ability we wanted to check.

    gAIScriptPtr += 3;
}

static void Cmd_get_highest_type_effectiveness(void)
{
    s32 i;
    u8 *dynamicMoveType;

    DebugPrintf("Looked for highest type effectiveness against  %d.",gBattleMons[gActiveBattler].species);

    gDynamicBasePower = 0;
    dynamicMoveType = &gBattleStruct->dynamicMoveType;
    *dynamicMoveType = 0;
    gBattleScripting.dmgMultiplier = 1;
    gMoveResultFlags = 0;
    gCritMultiplier = 1;
    AI_THINKING_STRUCT->funcResult = 0;

    for (i = 0; i < MAX_MON_MOVES; i++)
    {
        gBattleMoveDamage = 40;
        gCurrentMove = gBattleMons[sBattler_AI].moves[i];

        if (gCurrentMove != MOVE_NONE)
        {
            // TypeCalc does not assign to gMoveResultFlags, Cmd_typecalc does
            // This makes the check for gMoveResultFlags below always fail
            // in the original game. But this is fixed here.
            gMoveResultFlags = TypeCalc(gCurrentMove, sBattler_AI, gBattlerTarget);

            if (gBattleMoveDamage == 120) // Super effective STAB.
                gBattleMoveDamage = AI_EFFECTIVENESS_x2;
            if (gBattleMoveDamage == 240)
                gBattleMoveDamage = AI_EFFECTIVENESS_x4;
            if (gBattleMoveDamage == 30) // Not very effective STAB.
                gBattleMoveDamage = AI_EFFECTIVENESS_x0_5;
            if (gBattleMoveDamage == 15)
                gBattleMoveDamage = AI_EFFECTIVENESS_x0_25;

            if (gMoveResultFlags & MOVE_RESULT_DOESNT_AFFECT_FOE)
                gBattleMoveDamage = AI_EFFECTIVENESS_x0;

            if (AI_THINKING_STRUCT->funcResult < gBattleMoveDamage)
                AI_THINKING_STRUCT->funcResult = gBattleMoveDamage;
        }
    }

    DebugPrintf("Damage recorded: %d.",gBattleMoveDamage);

    gAIScriptPtr += 1;
}

static void Cmd_if_type_effectiveness(void)
{
    u8 damageVar;

    DebugPrintf("Running if_type_effectiveness");

    gDynamicBasePower = 0;
    gBattleStruct->dynamicMoveType = 0;
    gBattleScripting.dmgMultiplier = 1;
    gMoveResultFlags = 0;
    gCritMultiplier = 1;

    gBattleMoveDamage = AI_EFFECTIVENESS_x1;
    gCurrentMove = AI_THINKING_STRUCT->moveConsidered;

    // TypeCalc does not assign to gMoveResultFlags, Cmd_typecalc does
    // This makes the check for gMoveResultFlags below always fail
    // This is how you get the "dual non-immunity" glitch, where AI 
    // will use ineffective moves on immune pokémon if the second type
    // has a non-neutral, non-immune effectiveness
    // This bug is fixed in this mod
    gMoveResultFlags = TypeCalc(gCurrentMove, sBattler_AI, gBattlerTarget);

    if (gBattleMoveDamage >= 180)
        gBattleMoveDamage = AI_EFFECTIVENESS_x4;
    if (gBattleMoveDamage <= 15)
        gBattleMoveDamage = AI_EFFECTIVENESS_x0_25;
    if (gBattleMoveDamage >= 90)
        gBattleMoveDamage = AI_EFFECTIVENESS_x2;
    if (gBattleMoveDamage <= 30)
        gBattleMoveDamage = AI_EFFECTIVENESS_x0_5;

    if (gMoveResultFlags & MOVE_RESULT_DOESNT_AFFECT_FOE)
        gBattleMoveDamage = AI_EFFECTIVENESS_x0;

    // Store gBattleMoveDamage in a u8 variable because gAIScriptPtr[1] is a u8.
    damageVar = gBattleMoveDamage;

    if (damageVar == gAIScriptPtr[1])
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 2);
    else
        gAIScriptPtr += 6;
}

static void Cmd_if_target(void)
{
    DebugPrintf("Running if_target");

    if (gBattleMoves[AI_THINKING_STRUCT->moveConsidered].target == gAIScriptPtr[1])
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 2);
    else
        gAIScriptPtr += 6;
}

static void Cmd_if_type_effectiveness_with_modifiers(void)
{
    u8 damageVar, moveType, hpThreshhold, hpThreshholdHit, attackStage, defenseStage;
    u16 multiplier, divisor;
    u32 side, targetAbility;

    DebugPrintf("Checking type effectiveness with modifiers for %d.",gBattleMons[gActiveBattler].species);

    gDynamicBasePower = 0;
    gBattleStruct->dynamicMoveType = 0;
    gBattleScripting.dmgMultiplier = 1;
    gMoveResultFlags = 0;
    gCritMultiplier = 1;

    damageVar = AI_EFFECTIVENESS_x1;
    gBattleMoveDamage = 40;
    gCurrentMove = AI_THINKING_STRUCT->moveConsidered;
    side = GET_BATTLER_SIDE(gBattlerTarget);

    // TypeCalc does not assign to gMoveResultFlags, Cmd_typecalc does
    // This makes the check for gMoveResultFlags below always fail
    // This is how you get the "dual non-immunity" glitch, where AI
    // will use ineffective moves on immune pokémon if the second type
    // has a non-neutral, non-immune effectiveness
    // This bug is fixed in this mod
    gMoveResultFlags = TypeCalc(gCurrentMove, sBattler_AI, gBattlerTarget);

    // Get the move type to perform extra checks
    moveType = gBattleMoves[gCurrentMove].type;

    // Determine if Swarm, Torrent, etc. will activate for the AI User
    hpThreshhold = gBattleMons[sBattler_AI].maxHP * 4 / 3;

    if (gBattleMons[sBattler_AI].hp <= hpThreshhold)
        hpThreshholdHit = TRUE;
    else
        hpThreshholdHit = FALSE;

    // Get the target's ability to perform extra checks
    targetAbility = gBattleMons[gBattlerTarget].ability;

    if (targetAbility == ABILITY_WONDER_GUARD)
    {
        if (gBattleMoveDamage >= 120)
            gBattleMoveDamage = AI_EFFECTIVENESS_x2;
        else
            gBattleMoveDamage = AI_EFFECTIVENESS_x0;
    }
    else
    {
        // type-specific modifiers
        switch (moveType)
        {
            case TYPE_BUG:
                if (gBattleMons[sBattler_AI].ability == ABILITY_SWARM && hpThreshholdHit == TRUE)
                    gBattleMoveDamage = gBattleMoveDamage * 4 / 3;
                break;
            case TYPE_GRASS:
                if (gBattleMons[sBattler_AI].ability == ABILITY_OVERGROW && hpThreshholdHit == TRUE)
                    gBattleMoveDamage = gBattleMoveDamage * 4 / 3;
                break;
            case TYPE_GROUND:
                if (targetAbility == ABILITY_LEVITATE)
                    gBattleMoveDamage = 0;
                break;
            case TYPE_ICE:
                if (targetAbility == ABILITY_THICK_FAT)
                    gBattleMoveDamage = gBattleMoveDamage / 2;
                break;
            case TYPE_ELECTRIC:
                if (targetAbility == ABILITY_VOLT_ABSORB)
                    gBattleMoveDamage = 0;

                if (gStatuses3[sBattler_AI] & STATUS3_CHARGED_UP)
                    gBattleMoveDamage = gBattleMoveDamage * 2;

                if (gStatuses3[gBattlerTarget] & STATUS3_MUDSPORT)
                    gBattleMoveDamage = gBattleMoveDamage / 2;
                break;
            case TYPE_WATER:
                if (targetAbility == ABILITY_WATER_ABSORB)
                    gBattleMoveDamage = 0;

                if (gBattleWeather & B_WEATHER_RAIN)
                    gBattleMoveDamage = gBattleMoveDamage * 2;

                if (gBattleMons[sBattler_AI].ability == ABILITY_TORRENT && hpThreshholdHit == TRUE)
                    gBattleMoveDamage = gBattleMoveDamage * 4 / 3;

                if (gBattleWeather & B_WEATHER_SUN)
                    gBattleMoveDamage = gBattleMoveDamage / 2;
                break;
            case TYPE_FIRE:
                if (targetAbility == ABILITY_FLASH_FIRE)
                    gBattleMoveDamage = 0;

                if (gBattleWeather & B_WEATHER_SUN)
                    gBattleMoveDamage = gBattleMoveDamage * 2;

                if (gBattleMons[sBattler_AI].ability == ABILITY_BLAZE && hpThreshholdHit == TRUE)
                    gBattleMoveDamage = gBattleMoveDamage * 4 / 3;

                if (gBattleWeather & B_WEATHER_RAIN)
                    gBattleMoveDamage = gBattleMoveDamage / 2;

                if (targetAbility == ABILITY_THICK_FAT)
                    gBattleMoveDamage = gBattleMoveDamage / 2;

                if (gStatuses3[gBattlerTarget] & STATUS3_WATERSPORT)
                    gBattleMoveDamage = gBattleMoveDamage / 2;

                break;
            default:
                break;
        }

        // physical/special modifiers, and getting stat stages
        switch (moveType)
        {
            case TYPE_BUG:
            case TYPE_FIGHTING:
            case TYPE_FLYING:
            case TYPE_GHOST:
            case TYPE_GROUND:
            case TYPE_NORMAL:
            case TYPE_POISON:
            case TYPE_ROCK:
            case TYPE_STEEL:
                attackStage = gBattleMons[sBattler_AI].statStages[STAT_ATK];
                defenseStage = gBattleMons[gBattlerTarget].statStages[STAT_DEF];

                if (gSideStatuses[side] & SIDE_STATUS_REFLECT)
                    gBattleMoveDamage = gBattleMoveDamage / 2;
                break;
            case TYPE_DARK:
            case TYPE_DRAGON:
            case TYPE_ELECTRIC:
            case TYPE_FIRE:
            case TYPE_GRASS:
            case TYPE_ICE:
            case TYPE_PSYCHIC:
            case TYPE_WATER:
                attackStage = gBattleMons[sBattler_AI].statStages[STAT_SPATK];
                defenseStage = gBattleMons[gBattlerTarget].statStages[STAT_SPDEF];

                if (gSideStatuses[side] & SIDE_STATUS_LIGHTSCREEN)
                    gBattleMoveDamage = gBattleMoveDamage / 2;
                break;
            default:
                break;
        }

        switch (attackStage)
        {
            case 0:
                multiplier = 33;
                break;
            case 1:
                multiplier = 36;
                break;
            case 2:
                multiplier = 43;
                break;
            case 3:
                multiplier = 50;
                break;
            case 4:
                multiplier = 60;
                break;
            case 5:
                multiplier = 75;
                break;
            case 6:
                multiplier = 100;
                break;
            case 7:
                multiplier = 133;
                break;
            case 8:
                multiplier = 166;
                break;
            case 9:
                multiplier = 200;
                break;
            case 10:
                multiplier = 250;
                break;
            case 11:
                multiplier = 266;
                break;
            case 12:
                multiplier = 300;
                break;
            default:
                multiplier = 100;
                break;
        }

        switch (defenseStage)
        {
            case 0:
                divisor = 33;
                break;
            case 1:
                divisor = 36;
                break;
            case 2:
                divisor = 43;
                break;
            case 3:
                divisor = 50;
                break;
            case 4:
                divisor = 60;
                break;
            case 5:
                divisor = 75;
                break;
            case 6:
                divisor = 100;
                break;
            case 7:
                divisor = 133;
                break;
            case 8:
                divisor = 166;
                break;
            case 9:
                divisor = 200;
                break;
            case 10:
                divisor = 250;
                break;
            case 11:
                divisor = 266;
                break;
            case 12:
                divisor = 300;
                break;
            default:
                divisor = 100;
                break;
        }

        // Applying stat stage adjustments
        gBattleMoveDamage = gBattleMoveDamage * multiplier / divisor;

        if (gBattleMoveDamage == 0)
            damageVar = AI_EFFECTIVENESS_x0;
        if (gBattleMoveDamage >= 160)
            damageVar = AI_EFFECTIVENESS_x4;
        if (gBattleMoveDamage <= 15)
            damageVar = AI_EFFECTIVENESS_x0_25;
        if (gBattleMoveDamage >= 80)
            damageVar = AI_EFFECTIVENESS_x2;
        if (gBattleMoveDamage <= 30)
            damageVar = AI_EFFECTIVENESS_x0_5;
    }

    if (gMoveResultFlags & MOVE_RESULT_DOESNT_AFFECT_FOE)
        damageVar = AI_EFFECTIVENESS_x0;

    DebugPrintf("damageVar: %d, gBattleMoveDamage: %d, multiplier: %d, divisor: %d, targetAbility: %d.",damageVar, gBattleMoveDamage, multiplier, divisor);

    if (damageVar == gAIScriptPtr[1])
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 2);
    else
        gAIScriptPtr += 6;
}

static void Cmd_if_status_in_party(void)
{
    struct Pokemon *party;
    s32 i;
    u32 statusToCompareTo;
    u8 battlerId;

    DebugPrintf("Running if_status_in_party");

    switch (gAIScriptPtr[1])
    {
    case AI_USER:
        battlerId = sBattler_AI;
        break;
    default:
        battlerId = gBattlerTarget;
        break;
    }

    party = (GetBattlerSide(battlerId) == B_SIDE_PLAYER) ? gPlayerParty : gEnemyParty;

    statusToCompareTo = T1_READ_32(gAIScriptPtr + 2);

    for (i = 0; i < PARTY_SIZE; i++)
    {
        u16 species = GetMonData(&party[i], MON_DATA_SPECIES);
        u16 hp = GetMonData(&party[i], MON_DATA_HP);
        u32 status = GetMonData(&party[i], MON_DATA_STATUS);

        if (species != SPECIES_NONE && species != SPECIES_EGG && hp != 0 && status == statusToCompareTo)
        {
            gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 6);
            return;
        }
    }

    gAIScriptPtr += 10;
}

static void Cmd_if_status_not_in_party(void)
{
    struct Pokemon *party;
    s32 i;
    u32 statusToCompareTo;
    u8 battlerId;

    DebugPrintf("Running if_status_not_in_party");

    switch(gAIScriptPtr[1])
    {
    case 1:
        battlerId = sBattler_AI;
        break;
    default:
        battlerId = gBattlerTarget;
        break;
    }

    party = (GetBattlerSide(battlerId) == B_SIDE_PLAYER) ? gPlayerParty : gEnemyParty;

    statusToCompareTo = T1_READ_32(gAIScriptPtr + 2);

    for (i = 0; i < PARTY_SIZE; i++)
    {
        u16 species = GetMonData(&party[i], MON_DATA_SPECIES);
        u16 hp = GetMonData(&party[i], MON_DATA_HP);
        u32 status = GetMonData(&party[i], MON_DATA_STATUS);

        if (species != SPECIES_NONE && species != SPECIES_EGG && hp != 0 && status == statusToCompareTo)
        {
            gAIScriptPtr += 10;
            return;
        }
    }

    gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 6);
}

static void Cmd_get_weather(void)
{
    DebugPrintf("Running get_weather");

    if (gBattleWeather & B_WEATHER_RAIN)
        AI_THINKING_STRUCT->funcResult = AI_WEATHER_RAIN;
    if (gBattleWeather & B_WEATHER_SANDSTORM)
        AI_THINKING_STRUCT->funcResult = AI_WEATHER_SANDSTORM;
    if (gBattleWeather & B_WEATHER_SUN)
        AI_THINKING_STRUCT->funcResult = AI_WEATHER_SUN;
    if (gBattleWeather & B_WEATHER_HAIL)
        AI_THINKING_STRUCT->funcResult = AI_WEATHER_HAIL;

    gAIScriptPtr += 1;
}

static void Cmd_if_effect(void)
{
    // DebugPrintf("Running if_effect");

    if (gBattleMoves[AI_THINKING_STRUCT->moveConsidered].effect == gAIScriptPtr[1])
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 2);
    else
        gAIScriptPtr += 6;
}

static void Cmd_if_not_effect(void)
{
    DebugPrintf("Running if_not_effect");

    if (gBattleMoves[AI_THINKING_STRUCT->moveConsidered].effect != gAIScriptPtr[1])
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 2);
    else
        gAIScriptPtr += 6;
}

static void Cmd_if_stat_level_less_than(void)
{
    u32 battlerId;

    DebugPrintf("Running if_stat_level_less_than");

    if (gAIScriptPtr[1] == AI_USER)
        battlerId = sBattler_AI;
    else
        battlerId = gBattlerTarget;

    if (gBattleMons[battlerId].statStages[gAIScriptPtr[2]] < gAIScriptPtr[3])
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 4);
    else
        gAIScriptPtr += 8;
}

static void Cmd_if_stat_level_more_than(void)
{
    u32 battlerId;

    DebugPrintf("Running if_stat_level_more_than");

    if (gAIScriptPtr[1] == AI_USER)
        battlerId = sBattler_AI;
    else
        battlerId = gBattlerTarget;

    if (gBattleMons[battlerId].statStages[gAIScriptPtr[2]] > gAIScriptPtr[3])
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 4);
    else
        gAIScriptPtr += 8;
}

static void Cmd_if_stat_level_equal(void)
{
    u32 battlerId;

    DebugPrintf("Running if_stat_level_equal");

    if (gAIScriptPtr[1] == AI_USER)
        battlerId = sBattler_AI;
    else
        battlerId = gBattlerTarget;

    if (gBattleMons[battlerId].statStages[gAIScriptPtr[2]] == gAIScriptPtr[3])
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 4);
    else
        gAIScriptPtr += 8;
}

static void Cmd_if_stat_level_not_equal(void)
{
    u32 battlerId;

    DebugPrintf("Running if_stat_level_not_equal");

    if (gAIScriptPtr[1] == AI_USER)
        battlerId = sBattler_AI;
    else
        battlerId = gBattlerTarget;

    if (gBattleMons[battlerId].statStages[gAIScriptPtr[2]] != gAIScriptPtr[3])
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 4);
    else
        gAIScriptPtr += 8;
}

static void Cmd_if_can_faint(void)
{
    DebugPrintf("Checking if target can faint.");

    if (gBattleMoves[AI_THINKING_STRUCT->moveConsidered].power < 2)
    {
        gAIScriptPtr += 5;
        return;
    }

    gDynamicBasePower = 0;
    gBattleStruct->dynamicMoveType = 0;
    gBattleScripting.dmgMultiplier = 1;
    gMoveResultFlags = 0;
    gCritMultiplier = 1;
    gCurrentMove = AI_THINKING_STRUCT->moveConsidered;
    AI_CalcDmg(sBattler_AI, gBattlerTarget);
    TypeCalc(gCurrentMove, sBattler_AI, gBattlerTarget);

    // Apply a higher likely damage roll
    gBattleMoveDamage = gBattleMoveDamage * 95 / 100;

    // Moves always do at least 1 damage.
    if (gBattleMoveDamage == 0)
        gBattleMoveDamage = 1;

    DebugPrintf("Damage: %d. HP: %d",gBattleMoveDamage,gBattleMons[gBattlerTarget].hp);

    if (gBattleMons[gBattlerTarget].hp <= gBattleMoveDamage)
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 1);
    else
        gAIScriptPtr += 5;
}

static void Cmd_consider_imitated_move(void)
{
    DebugPrintf("Considering imitated move.");
    AI_THINKING_STRUCT->moveConsidered = gLastMoves[gBattlerTarget];
    gAIScriptPtr += 1;
}

static void Cmd_if_has_move(void)
{
    s32 i;
    const u16 *movePtr = (u16 *)(gAIScriptPtr + 2);

    DebugPrintf("Running if_has_move");

    switch (gAIScriptPtr[1])
    {
    case AI_USER:
        for (i = 0; i < MAX_MON_MOVES; i++)
        {
            if (gBattleMons[sBattler_AI].moves[i] == *movePtr)
                break;
        }
        if (i == MAX_MON_MOVES)
            gAIScriptPtr += 8;
        else
            gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 4);
        break;
    case AI_USER_PARTNER:
        if (gBattleMons[BATTLE_PARTNER(sBattler_AI)].hp == 0)
        {
            gAIScriptPtr += 8;
            break;
        }
        else
        {
            for (i = 0; i < MAX_MON_MOVES; i++)
            {
                if (gBattleMons[BATTLE_PARTNER(sBattler_AI)].moves[i] == *movePtr)
                    break;
            }
        }
        if (i == MAX_MON_MOVES)
            gAIScriptPtr += 8;
        else
            gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 4);
        break;
    case AI_TARGET:
    case AI_TARGET_PARTNER:
        for (i = 0; i < MAX_MON_MOVES; i++)
        {
            if (gBattleMons[gBattlerTarget].moves[i] == *movePtr)
                break;
        }
        if (i == MAX_MON_MOVES)
            gAIScriptPtr += 8;
        else
            gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 4);
        break;
    }
}

static void Cmd_if_doesnt_have_move(void)
{
    s32 i;
    const u16 *movePtr = (u16 *)(gAIScriptPtr + 2);

    DebugPrintf("Running if_doesnt_have_move");

    switch(gAIScriptPtr[1])
    {
    case AI_USER:
    case AI_USER_PARTNER: // UB: no separate check for user partner.
        for (i = 0; i < MAX_MON_MOVES; i++)
        {
            if (gBattleMons[sBattler_AI].moves[i] == *movePtr)
                break;
        }
        if (i != MAX_MON_MOVES)
            gAIScriptPtr += 8;
        else
            gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 4);
        break;
    case AI_TARGET:
    case AI_TARGET_PARTNER:
        for (i = 0; i < MAX_MON_MOVES; i++)
        {
            if (gBattleMons[gBattlerTarget].moves[i] == *movePtr)
                break;
        }
        if (i != MAX_MON_MOVES)
            gAIScriptPtr += 8;
        else
            gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 4);
        break;
    }
}

static void Cmd_if_has_move_with_effect(void)
{
    s32 i;

    // DebugPrintf("Running if_has_move_with_effect");

    switch (gAIScriptPtr[1])
    {
    case AI_USER:
    case AI_USER_PARTNER:
        for (i = 0; i < MAX_MON_MOVES; i++)
        {
            if (gBattleMons[sBattler_AI].moves[i] != 0 && gBattleMoves[gBattleMons[sBattler_AI].moves[i]].effect == gAIScriptPtr[2])
                break;
        }
        if (i == MAX_MON_MOVES)
            gAIScriptPtr += 7;
        else
            gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 3);
        break;
    case AI_TARGET:
    case AI_TARGET_PARTNER:
        for (i = 0; i < MAX_MON_MOVES; i++)
        {
            if (gBattleMons[sBattler_AI].moves[i] != 0 && gBattleMoves[gBattleMons[gBattlerTarget].moves[i]].effect == gAIScriptPtr[2])
                break;
        }
        if (i == MAX_MON_MOVES)
            gAIScriptPtr += 7;
        else
            gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 3);
        break;
    }
}

static void Cmd_if_doesnt_have_move_with_effect(void)
{
    s32 i;

    DebugPrintf("Running if_doesnt_have_move_with_effect");

    switch (gAIScriptPtr[1])
    {
    case AI_USER:
    case AI_USER_PARTNER:
        for (i = 0; i < MAX_MON_MOVES; i++)
        {
            if(gBattleMons[sBattler_AI].moves[i] != 0 && gBattleMoves[gBattleMons[sBattler_AI].moves[i]].effect == gAIScriptPtr[2])
                break;
        }
        if (i != MAX_MON_MOVES)
            gAIScriptPtr += 7;
        else
            gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 3);
        break;
    case AI_TARGET:
    case AI_TARGET_PARTNER:
        for (i = 0; i < MAX_MON_MOVES; i++)
        {
            if (gBattleMons[gBattlerTarget].moves[i] && gBattleMoves[gBattleMons[gBattlerTarget].moves[i]].effect == gAIScriptPtr[2])
                break;
        }
        if (i != MAX_MON_MOVES)
            gAIScriptPtr += 7;
        else
            gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 3);
        break;
    }
}

static void Cmd_if_any_move_disabled_or_encored(void)
{
    u8 battlerId;

    DebugPrintf("Running if_any_move_disabled_or_encored");

    if (gAIScriptPtr[1] == AI_USER)
        battlerId = sBattler_AI;
    else
        battlerId = gBattlerTarget;

    if (gAIScriptPtr[2] == 0)
    {
        if (gDisableStructs[battlerId].disabledMove == MOVE_NONE)
            gAIScriptPtr += 7;
        else
            gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 3);
    }
    else if (gAIScriptPtr[2] != 1)
    {
        gAIScriptPtr += 7;
    }
    else
    {
        if (gDisableStructs[battlerId].encoredMove != MOVE_NONE)
            gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 3);
        else
            gAIScriptPtr += 7;
    }
}

static void Cmd_if_curr_move_disabled_or_encored(void)
{
    DebugPrintf("Running if_curr_move_disabled_or_encored");

    switch (gAIScriptPtr[1])
    {
    case 0:
        if (gDisableStructs[gActiveBattler].disabledMove == AI_THINKING_STRUCT->moveConsidered)
            gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 2);
        else
            gAIScriptPtr += 6;
        break;
    case 1:
        if (gDisableStructs[gActiveBattler].encoredMove == AI_THINKING_STRUCT->moveConsidered)
            gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 2);
        else
            gAIScriptPtr += 6;
        break;
    default:
        gAIScriptPtr += 6;
        break;
    }
}

static void Cmd_flee(void)
{
    DebugPrintf("Running flee");

    AI_THINKING_STRUCT->aiAction |= (AI_ACTION_DONE | AI_ACTION_FLEE | AI_ACTION_DO_NOT_ATTACK);
}

static void Cmd_if_random_safari_flee(void)
{
    u8 safariFleeRate = gBattleStruct->safariEscapeFactor * 5; // Safari flee rate, from 0-20.

    DebugPrintf("Running if_random_safari_flee");

    if ((u8)(Random() % 100) < safariFleeRate)
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 1);
    else
        gAIScriptPtr += 5;
}

static void Cmd_watch(void)
{
    DebugPrintf("Running watch");

    AI_THINKING_STRUCT->aiAction |= (AI_ACTION_DONE | AI_ACTION_WATCH | AI_ACTION_DO_NOT_ATTACK);
}

static void Cmd_get_hold_effect(void)
{
    u8 battlerId;

    DebugPrintf("Running get_hold_effect");

    if (gAIScriptPtr[1] == AI_USER)
        battlerId = sBattler_AI;
    else
        battlerId = gBattlerTarget;

    AI_THINKING_STRUCT->funcResult = ItemId_GetHoldEffect(gBattleMons[battlerId].item);

    gAIScriptPtr += 2;
}

static void Cmd_if_holds_item(void)
{
    u8 battlerId = BattleAI_GetWantedBattler(gAIScriptPtr[1]);
    u16 item;
    u8 itemLo, itemHi;

    DebugPrintf("Running if_holds_item");

    item = gBattleMons[battlerId].item;

    itemHi = gAIScriptPtr[2];
    itemLo = gAIScriptPtr[3];

    if (((itemHi << 8) | itemLo) == item)
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 4);
    else
        gAIScriptPtr += 8;
}

static void Cmd_get_gender(void)
{
    u8 battlerId;

    DebugPrintf("Running get_gender");

    if (gAIScriptPtr[1] == AI_USER)
        battlerId = sBattler_AI;
    else
        battlerId = gBattlerTarget;

    AI_THINKING_STRUCT->funcResult = GetGenderFromSpeciesAndPersonality(gBattleMons[battlerId].species, gBattleMons[battlerId].personality);

    gAIScriptPtr += 2;
}

static void Cmd_is_first_turn_for(void)
{
    u8 battlerId;

    DebugPrintf("Running is_first_turn_for");

    if (gAIScriptPtr[1] == AI_USER)
        battlerId = sBattler_AI;
    else
        battlerId = gBattlerTarget;

    AI_THINKING_STRUCT->funcResult = gDisableStructs[battlerId].isFirstTurn;

    gAIScriptPtr += 2;
}

static void Cmd_get_stockpile_count(void)
{
    u8 battlerId;

    DebugPrintf("Running get_stockpile_count");

    if (gAIScriptPtr[1] == AI_USER)
        battlerId = sBattler_AI;
    else
        battlerId = gBattlerTarget;

    AI_THINKING_STRUCT->funcResult = gDisableStructs[battlerId].stockpileCounter;

    gAIScriptPtr += 2;
}

static void Cmd_is_double_battle(void)
{
    DebugPrintf("Running is_double_battle");

    AI_THINKING_STRUCT->funcResult = gBattleTypeFlags & BATTLE_TYPE_DOUBLE;

    gAIScriptPtr += 1;
}

static void Cmd_get_used_held_item(void)
{
    u8 battlerId;

    DebugPrintf("Running get_used_held_item");

    if (gAIScriptPtr[1] == AI_USER)
        battlerId = sBattler_AI;
    else
        battlerId = gBattlerTarget;

    AI_THINKING_STRUCT->funcResult = *(u8 *)&gBattleStruct->usedHeldItems[battlerId];

    gAIScriptPtr += 2;
}

static void Cmd_get_move_type_from_result(void)
{
    DebugPrintf("Running get_move_type_from_result");
    AI_THINKING_STRUCT->funcResult = gBattleMoves[AI_THINKING_STRUCT->funcResult].type;
    gAIScriptPtr += 1;
}

static void Cmd_get_move_power_from_result(void)
{
    DebugPrintf("Running get_move_power_from_result");
    AI_THINKING_STRUCT->funcResult = gBattleMoves[AI_THINKING_STRUCT->funcResult].power;
    gAIScriptPtr += 1;
}

static void Cmd_get_move_effect_from_result(void)
{
    DebugPrintf("Running get_move_effect_from_result");
    AI_THINKING_STRUCT->funcResult = gBattleMoves[AI_THINKING_STRUCT->funcResult].effect;
    gAIScriptPtr += 1;
}

static void Cmd_get_protect_count(void)
{
    u8 battlerId;

    DebugPrintf("Running get_protect_count");

    if (gAIScriptPtr[1] == AI_USER)
        battlerId = sBattler_AI;
    else
        battlerId = gBattlerTarget;

    AI_THINKING_STRUCT->funcResult = gDisableStructs[battlerId].protectUses;

    gAIScriptPtr += 2;
}

static void Cmd_get_move_target_from_result(void)
{
    DebugPrintf("Running get_move_target_from_result");

    AI_THINKING_STRUCT->funcResult = gBattleMoves[AI_THINKING_STRUCT->funcResult].target;

    gAIScriptPtr += 1;
}

static void Cmd_get_type_effectiveness_from_result(void)
{
    u8 damageVar;

    DebugPrintf("Running get_type_effectiveness_from_result");

    gDynamicBasePower = 0;
    gBattleStruct->dynamicMoveType = 0;
    gBattleScripting.dmgMultiplier = 1;
    gMoveResultFlags = 0;
    gCritMultiplier = 1;

    gBattleMoveDamage = AI_EFFECTIVENESS_x1;
    gCurrentMove = AI_THINKING_STRUCT->funcResult;

    gMoveResultFlags = TypeCalc(gCurrentMove, sBattler_AI, gBattlerTarget);

    if (gBattleMoveDamage == 120) // Super effective STAB.
        gBattleMoveDamage = AI_EFFECTIVENESS_x2;
    if (gBattleMoveDamage == 240)
        gBattleMoveDamage = AI_EFFECTIVENESS_x4;
    if (gBattleMoveDamage == 30) // Not very effective STAB.
        gBattleMoveDamage = AI_EFFECTIVENESS_x0_5;
    if (gBattleMoveDamage == 15)
        gBattleMoveDamage = AI_EFFECTIVENESS_x0_25;

    if (gMoveResultFlags & MOVE_RESULT_DOESNT_AFFECT_FOE)
        gBattleMoveDamage = AI_EFFECTIVENESS_x0;

    AI_THINKING_STRUCT->funcResult = gBattleMoveDamage;

    DebugPrintf("Result: %d",gBattleMoveDamage);

    gAIScriptPtr += 1;
}

static void Cmd_get_considered_move_second_eff_chance_from_result(void)
{
    DebugPrintf("Running get_considered_move_second_eff_chance_from_result");
    AI_THINKING_STRUCT->funcResult = gBattleMoves[AI_THINKING_STRUCT->funcResult].secondaryEffectChance;
    gAIScriptPtr += 1;
}

static void Cmd_get_spikes_layers_target(void)
{
    DebugPrintf("Counting spikes layers. Result: %d",gSideTimers[GetBattlerSide(gBattlerTarget)].spikesAmount);

    AI_THINKING_STRUCT->funcResult = gSideTimers[GetBattlerSide(gBattlerTarget)].spikesAmount;
    gAIScriptPtr += 1;
}

static void Cmd_if_ai_can_faint(void)
{
    s32 i;
    u8 *dynamicMoveType;
    u8 damageVar;

    DebugPrintf("Running if_ai_can_faint!");

    damageVar = 0;
    gDynamicBasePower = 0;
    dynamicMoveType = &gBattleStruct->dynamicMoveType;
    *dynamicMoveType = 0;
    gBattleScripting.dmgMultiplier = 1;
    gMoveResultFlags = 0;
    gCritMultiplier = 1;
    AI_THINKING_STRUCT->funcResult = 0;

    for (i = 0; i < MAX_MON_MOVES; i++)
    {
        gCurrentMove = gBattleMons[gBattlerTarget].moves[i];

        if (gCurrentMove != MOVE_NONE)
        {
            AI_CalcDmg(gBattlerTarget, sBattler_AI);
            TypeCalc(gCurrentMove, gBattlerTarget, sBattler_AI);

            // Get the highest battle move damage
            if (damageVar < gBattleMoveDamage)
                damageVar = gBattleMoveDamage;
        }
    }

    // Apply a higher likely damage roll
    damageVar = damageVar * 95 / 100;

    DebugPrintf("damageVar: %d, HP: %d",damageVar,gBattleMons[sBattler_AI].hp);

    if (gBattleMons[sBattler_AI].hp <= damageVar)
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 1);
    else
        gAIScriptPtr += 5;
}

static void Cmd_get_highest_type_effectiveness_from_target(void)
{
    u8 damageVar, resultVar, moveType, hpThreshhold, hpThreshholdHit, attackStage, defenseStage;
    u8 *dynamicMoveType;
    u16 multiplier, divisor;
    u32 side, userAbility;
    s32 i;

    DebugPrintf("Running get_highest_type_effectiveness_from_target");

    gDynamicBasePower = 0;
    dynamicMoveType = &gBattleStruct->dynamicMoveType;
    *dynamicMoveType = 0;
    gBattleScripting.dmgMultiplier = 1;
    gMoveResultFlags = 0;
    gCritMultiplier = 1;
    AI_THINKING_STRUCT->funcResult = 0;
    resultVar = AI_EFFECTIVENESS_x1;
    damageVar = 0;
    side = GET_BATTLER_SIDE(sBattler_AI);
    userAbility = gBattleMons[sBattler_AI].ability;

    // Determine if Swarm, Torrent, etc. will activate for the AI Target
    hpThreshhold = gBattleMons[gBattlerTarget].maxHP * 4 / 3;

    if (gBattleMons[gBattlerTarget].hp <= hpThreshhold)
        hpThreshholdHit = TRUE;
    else
        hpThreshholdHit = FALSE;

    for (i = 0; i < MAX_MON_MOVES; i++)
    {
        gBattleMoveDamage = 40;
        gCurrentMove = gBattleMons[gBattlerTarget].moves[i];

        if (gCurrentMove != MOVE_NONE)
        {
            // TypeCalc does not assign to gMoveResultFlags, Cmd_typecalc does
            // This makes the check for gMoveResultFlags below always fail
            // This is how you get the "dual non-immunity" glitch, where AI
            // will use ineffective moves on immune pokémon if the second type
            // has a non-neutral, non-immune effectiveness
            // This bug is fixed in this mod
            gMoveResultFlags = TypeCalc(gCurrentMove, gBattlerTarget, sBattler_AI);

            // Get the move type to perform extra checks
            moveType = gBattleMoves[gCurrentMove].type;

            if (userAbility == ABILITY_WONDER_GUARD)
            {
                if (gBattleMoveDamage >= 120)
                    gBattleMoveDamage = AI_EFFECTIVENESS_x2;
                else
                    gBattleMoveDamage = AI_EFFECTIVENESS_x0;
            }
            else
            {
                // type-specific modifiers
                switch (moveType)
                {
                    case TYPE_BUG:
                        if (gBattleMons[gBattlerTarget].ability == ABILITY_SWARM && hpThreshholdHit == TRUE)
                            gBattleMoveDamage = gBattleMoveDamage * 4 / 3;
                        break;
                    case TYPE_GRASS:
                        if (gBattleMons[gBattlerTarget].ability == ABILITY_OVERGROW && hpThreshholdHit == TRUE)
                            gBattleMoveDamage = gBattleMoveDamage * 4 / 3;
                        break;
                    case TYPE_GROUND:
                        if (userAbility == ABILITY_LEVITATE)
                            gBattleMoveDamage = 0;
                        break;
                    case TYPE_ICE:
                        if (userAbility == ABILITY_THICK_FAT)
                            gBattleMoveDamage = gBattleMoveDamage / 2;
                        break;
                    case TYPE_ELECTRIC:
                        if (userAbility == ABILITY_VOLT_ABSORB)
                            gBattleMoveDamage = 0;

                        if (gStatuses3[gBattlerTarget] & STATUS3_CHARGED_UP)
                            gBattleMoveDamage = gBattleMoveDamage * 2;

                        if (gStatuses3[sBattler_AI] & STATUS3_MUDSPORT)
                            gBattleMoveDamage = gBattleMoveDamage / 2;
                        break;
                    case TYPE_WATER:
                        if (userAbility == ABILITY_WATER_ABSORB)
                            gBattleMoveDamage = 0;

                        if (gBattleWeather & B_WEATHER_RAIN)
                            gBattleMoveDamage = gBattleMoveDamage * 2;

                        if (gBattleMons[gBattlerTarget].ability == ABILITY_TORRENT && hpThreshholdHit == TRUE)
                            gBattleMoveDamage = gBattleMoveDamage * 4 / 3;

                        if (gBattleWeather & B_WEATHER_SUN)
                            gBattleMoveDamage = gBattleMoveDamage / 2;
                        break;
                    case TYPE_FIRE:
                        if (userAbility == ABILITY_FLASH_FIRE)
                            gBattleMoveDamage = 0;

                        if (gBattleWeather & B_WEATHER_SUN)
                            gBattleMoveDamage = gBattleMoveDamage * 2;

                        if (gBattleMons[gBattlerTarget].ability == ABILITY_BLAZE && hpThreshholdHit == TRUE)
                            gBattleMoveDamage = gBattleMoveDamage * 4 / 3;

                        if (gBattleWeather & B_WEATHER_RAIN)
                            gBattleMoveDamage = gBattleMoveDamage / 2;

                        if (userAbility == ABILITY_THICK_FAT)
                            gBattleMoveDamage = gBattleMoveDamage / 2;

                        if (gStatuses3[sBattler_AI] & STATUS3_WATERSPORT)
                            gBattleMoveDamage = gBattleMoveDamage / 2;

                        break;
                    default:
                        break;
                }

                // physical/special modifiers, and getting stat stages
                switch (moveType)
                {
                    case TYPE_BUG:
                    case TYPE_FIGHTING:
                    case TYPE_FLYING:
                    case TYPE_GHOST:
                    case TYPE_GROUND:
                    case TYPE_NORMAL:
                    case TYPE_POISON:
                    case TYPE_ROCK:
                    case TYPE_STEEL:
                        attackStage = gBattleMons[gBattlerTarget].statStages[STAT_ATK];
                        defenseStage = gBattleMons[sBattler_AI].statStages[STAT_DEF];

                        if (gSideStatuses[side] & SIDE_STATUS_REFLECT)
                            gBattleMoveDamage = gBattleMoveDamage / 2;
                        break;
                    case TYPE_DARK:
                    case TYPE_DRAGON:
                    case TYPE_ELECTRIC:
                    case TYPE_FIRE:
                    case TYPE_GRASS:
                    case TYPE_ICE:
                    case TYPE_PSYCHIC:
                    case TYPE_WATER:
                        attackStage = gBattleMons[gBattlerTarget].statStages[STAT_SPATK];
                        defenseStage = gBattleMons[sBattler_AI].statStages[STAT_SPDEF];

                        if (gSideStatuses[side] & SIDE_STATUS_LIGHTSCREEN)
                            gBattleMoveDamage = gBattleMoveDamage / 2;
                        break;
                    default:
                        break;
                }

                switch (attackStage)
                {
                    case 0:
                        multiplier = 33;
                        break;
                    case 1:
                        multiplier = 36;
                        break;
                    case 2:
                        multiplier = 43;
                        break;
                    case 3:
                        multiplier = 50;
                        break;
                    case 4:
                        multiplier = 60;
                        break;
                    case 5:
                        multiplier = 75;
                        break;
                    case 6:
                        multiplier = 100;
                        break;
                    case 7:
                        multiplier = 133;
                        break;
                    case 8:
                        multiplier = 166;
                        break;
                    case 9:
                        multiplier = 200;
                        break;
                    case 10:
                        multiplier = 250;
                        break;
                    case 11:
                        multiplier = 266;
                        break;
                    case 12:
                        multiplier = 300;
                        break;
                    default:
                        multiplier = 100;
                        break;
                }

                switch (defenseStage)
                {
                    case 0:
                        divisor = 33;
                        break;
                    case 1:
                        divisor = 36;
                        break;
                    case 2:
                        divisor = 43;
                        break;
                    case 3:
                        divisor = 50;
                        break;
                    case 4:
                        divisor = 60;
                        break;
                    case 5:
                        divisor = 75;
                        break;
                    case 6:
                        divisor = 100;
                        break;
                    case 7:
                        divisor = 133;
                        break;
                    case 8:
                        divisor = 166;
                        break;
                    case 9:
                        divisor = 200;
                        break;
                    case 10:
                        divisor = 250;
                        break;
                    case 11:
                        divisor = 266;
                        break;
                    case 12:
                        divisor = 300;
                        break;
                    default:
                        divisor = 100;
                        break;
                }

                // Applying stat stage adjustments
                gBattleMoveDamage = gBattleMoveDamage * multiplier / divisor;

                if (gMoveResultFlags & MOVE_RESULT_DOESNT_AFFECT_FOE)
                    gBattleMoveDamage = 0;

                if (damageVar < gBattleMoveDamage)
                    damageVar = gBattleMoveDamage;
            }
        }
    }

    if (damageVar == 0)
        resultVar = AI_EFFECTIVENESS_x0;
    if (damageVar >= 160)
        resultVar = AI_EFFECTIVENESS_x4;
    if (damageVar <= 15)
        resultVar = AI_EFFECTIVENESS_x0_25;
    if (damageVar >= 80)
        resultVar = AI_EFFECTIVENESS_x2;
    if (damageVar <= 30)
        resultVar = AI_EFFECTIVENESS_x0_5;

    DebugPrintf("resultVar: %d, damageVar: %d",resultVar,damageVar);

    AI_THINKING_STRUCT->funcResult = resultVar;

    gAIScriptPtr += 1;
}


static void Cmd_call(void)
{
    // DebugPrintf("Running call");
    AIStackPushVar(gAIScriptPtr + 5);
    gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 1);
}

static void Cmd_goto(void)
{
    // DebugPrintf("Running goto");
    gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 1);
}

static void Cmd_end(void)
{
    DebugPrintf("End looking at move.");

    if (AIStackPop() == 0)
        AI_THINKING_STRUCT->aiAction |= AI_ACTION_DONE;
}

static void Cmd_if_level_cond(void)
{
    DebugPrintf("Running if_level_cond");

    switch (gAIScriptPtr[1])
    {
    case 0: // greater than
        if (gBattleMons[sBattler_AI].level > gBattleMons[gBattlerTarget].level)
            gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 2);
        else
            gAIScriptPtr += 6;
        break;
    case 1: // less than
        if (gBattleMons[sBattler_AI].level < gBattleMons[gBattlerTarget].level)
            gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 2);
        else
            gAIScriptPtr += 6;
        break;
    case 2: // equal
        if (gBattleMons[sBattler_AI].level == gBattleMons[gBattlerTarget].level)
            gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 2);
        else
            gAIScriptPtr += 6;
        break;
    }
}

static void Cmd_if_target_taunted(void)
{
    DebugPrintf("Running if_target_taunted");

    if (gDisableStructs[gBattlerTarget].tauntTimer != 0)
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 1);
    else
        gAIScriptPtr += 5;
}

static void Cmd_if_target_not_taunted(void)
{
    DebugPrintf("Running if_target_not_taunted");

    if (gDisableStructs[gBattlerTarget].tauntTimer == 0)
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 1);
    else
        gAIScriptPtr += 5;
}

static void Cmd_if_target_is_ally(void)
{
    DebugPrintf("Running if_target_is_ally");

    if ((sBattler_AI & BIT_SIDE) == (gBattlerTarget & BIT_SIDE))
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 1);
    else
        gAIScriptPtr += 5;
}

static void Cmd_if_flash_fired(void)
{
    u8 battlerId = BattleAI_GetWantedBattler(gAIScriptPtr[1]);

    DebugPrintf("Running if_flash_fired");

    if (gBattleResources->flags->flags[battlerId] & RESOURCE_FLAG_FLASH_FIRE)
        gAIScriptPtr = T1_READ_PTR(gAIScriptPtr + 2);
    else
        gAIScriptPtr += 6;
}

static void AIStackPushVar(const u8 *var)
{
    DebugPrintf("Running AIStackPushVar");
    gBattleResources->AI_ScriptsStack->ptr[gBattleResources->AI_ScriptsStack->size++] = var;
}

static void UNUSED AIStackPushVar_cursor(void)
{
    gBattleResources->AI_ScriptsStack->ptr[gBattleResources->AI_ScriptsStack->size++] = gAIScriptPtr;
}

static bool8 AIStackPop(void)
{
    // DebugPrintf("Running AIStackPop");

    if (gBattleResources->AI_ScriptsStack->size != 0)
    {
        --gBattleResources->AI_ScriptsStack->size;
        gAIScriptPtr = gBattleResources->AI_ScriptsStack->ptr[gBattleResources->AI_ScriptsStack->size];
        // DebugPrintf("Returning TRUE");
        return TRUE;
    }
    else
    {
        // DebugPrintf("Returning FALSE");
        return FALSE;
    }
}
