# CHKPNT

> Customizable Checkpoints and _"save"_ them for later.

## Table of Contents

- [Install](#install)
- [Getting Started](#getting-started)
- [Customization](#customization)
- [Relevant Notes](#relevant-notes)

## Install

[Download this repository](https://github.com/Rizulix/CHKPNT/releases/download/v1.0.0/chkpnt.zip) and extract its contents inside `Steam\steamapps\common\Sven Co-op\svencoop_addon\scripts\maps`.

## Getting Started

- Preparing your own mapscript for your map:

	1. In `Steam\steamapps\common\Sven Co-op\svencoop_addon\scripts\maps`:

		- Create a new file called `my_map.as`.

		- Open it and add the following lines and save:

			```angelscript
			#include "chkpnt/register"

			void MapInit()
			{
				// This will register point_checkpoint and auto_checkpoint
				// will also create an auto_checkpoint if one does not exist on the map
				CHKPNT::Register();
			}
			```

	2. Now in `Steam\steamapps\common\Sven Co-op\svencoop_addon\maps` or `wherever your map is`:

		- Create a new file called `my_map.cfg`.

		- Open it and add the following line and save:

			```cfg
			map_script my_map
			```

	3. Finally, run it and enjoy!

- If you are looking for a quick test you can use one of the mapscripts already prepared for some campaigns (Half-Life, They Hunger, Poke646, Poke646: Vendetta, Afraid of Monsters: Director's Cut), but due to my laziness I warn you that there will be maps with some kind of softblock:

	1. Download and install the chosen campaign from [scmapdb](http://scmapdb.com/) (except for Half-Life and They Hunger those are included in the game).

	2. Rename the original mapscript or make a backup of it.

	3. Remove the prefix of the prepared mapscript (the one starting with `as_`).

	4. Start a new game of the chosen campaign and enjoy!

## Customization

Sometimes you may want to change the appearance, sounds and/or effects, now you can do it without directly editing the entity files.

- [Basic](#basic)
	- [Checkpoint](#checkpoint)
		- [Properties](#properties)
		- [Audiovisuals](#audiovisuals)
		- [Messages](#messages)
		- [Spawnflags](#spawnflags)
	- [Auto-Checkpoint](#auto-checkpoint)
		- [Messages](#messages-1)
- [Advanced](#advanced)
	- [Checkpoint](#checkpoint-1)
		- [Events & Effects](#events--effects)
	- [Auto-Checkpoint](#auto-checkpoint-1)
		- [Effect](#effect)

### Basic

The basic customization can be applied globally (Global) or per entity (Local).

- **Global:**

	Open your mapscript and in a new line bellow `CHKPNT::Register();` add the code according to the customization option(s) you want to use.

- **Local:**

	Inside your map create/edit the entity called "point_checkpoint" and add the attributes according to the option(s) you want to use.

	⚠️ You can modify the values during the game using `trigger_changevalue`, remember to put a `targetname` to the entity to modify its values (the default `targetname` of the `auto_checkpoint` is `as:auto_checkpoint`)

#### Checkpoint

##### Properties

| Attribute | Description | Name (Global) | Name (Local) | Default Value |
| --- | --- | --- | --- | --- |
| Spawn Effect | Show spawn effect? Survival active require! | g_fSpawnEffect | m_fSpawnEffect | false |
| Min Hullsize | Minimum size. Relative to the entity's origin | g_vecMins | minhullsize | -8 -8 -16 |
| Max Hullsize | Maximun size. Relative to the entity's origin | g_vecMaxs | maxhullsize | 8 8 16 |
| Respawn Point | Use this coordinates instead Checkpoint's origin for player respawn (0 0 0 isn't used) | N/A | m_vecRespawnPoint | 0 0 0 |
| Delay Before Start | How much time between being triggered and starting the revival of dead players | g_flDelayBeforeStart | m_flDelayBeforeStart | 3.0 |
| Delay Between Revive | Time between player revive | g_flDelayBetweenRevive | m_flDelayBetweenRevive | 1.0 |
| Delay Before Reactivation | How much time before this Checkpoint becomes active again, SF_CHECKPOINT_REUSABLE required! | g_flDelayBeforeReactivation | m_flDelayBeforeReactivation | 60.0 |
| On Spawn: Use Type | Use type at spawn. Survival active require! | g_useOnSpawn | m_useOnSpawn | USE_TOGGLE (3) |
| On Activate: Use Type | Use type at ativate | g_useOnActivate | m_useOnActivate | USE_TOGGLE (3) |
| On Activate: Use Value | Use state value, only used when useOnActivate is USE_SET (2)! | g_flActivateValue | m_flActivateValue | 0.0 |

- Example

	[![](https://i.imgur.com/2ymDjx1.png)](https://i.imgur.com/2ymDjx1.png)
	_Global Customization_

	[![](https://i.imgur.com/h7qExSD.png)](https://i.imgur.com/h7qExSD.png)
	_Local Customization_

##### Audiovisuals

- **Global** only.

- Make sure that all the files you want to use exist and that they are in the correct path otherwise you may break the script.

- To mute the sounds and/or not show the models/sprites use `common/null.wav` and `sprites/null.spr` respectively.

| Attribute | Description | Name | Default Value |
| --- | --- | --- | --- |
| Entity Model | Checkpoint model | g_szEntityModel | models/common/lambda.mdl |
| Portal Sprite | Sprite to use as a portal before starting to revive players | g_szPortalSprite | sprites/exit1.spr |
| Activation Sound | Sound played this Checkpoint is used | g_szActivationSound | ../media/valve.mp3 |
| Player Respawn Sound | Sound played when player is respawned | g_szPlayerRespawnSound | debris/beamstart4.wav |
| Portal Creation Sound | Sound played when the portal is created | g_szPortalCreationSound | debris/beamstart7.wav |
| Portal Shutdown Sound | Sound played when the portal is closed | g_szPortalShutdownSound | ambience/port_suckout1.wav |

- Example

	[![](https://i.imgur.com/7rofJTh.png)](https://i.imgur.com/7rofJTh.png)

##### Messages

- **Global** only.

| Attribute | Description | Name | Default Value |
| --- | --- | --- | --- |
| Entity Name | Checkpoint name to be used in the messages  | g_szEntityName | Respawn-Point |
| Save Message | Message to be displayed when this Checkpoint is reached/saved | g_szSaveMessage | !player has reached a !checkpoint, saved: !amount. |
| Activation Message | Message to be displayed when this Checkpoint is activated | g_szActivationMessage | !player just activated a !checkpoint. |
| Auto Activation Message | Message to be displayed when this Checkpoint is auto-activated | g_szAutoActivationMessage | Auto-activating a !checkpoint, remaining: !amount. |
| Vote Activation Message | Message to be displayed when activated through the Auto-Checkpoint vote | g_szVoteActivationMessage | Activating a !checkpoint, remaining: !amount. |
| Force Activation Message | Message to be displayed when activated through Auto-Checkpoint admin command | g_szForceActivationMessage | !player has forced the activation of a !checkpoint, remaining: !amount. |

| Keyword | Replaced with | Available in |
| --- | --- | --- |
| `!player` | **Player Name** | **Save Message**, **Activation Message**, **Force Activation Message** |
| `!amount` | **Number of Checkpoints Saved** | **Save Message**, **Auto Activation Message**, **Vote Activation Message**, **Force Activation Message** |
| `!checkpoint` | **Checkpoint Name** | **All Messages** |

- Example

	[![](https://i.imgur.com/enmECtc.png)](https://i.imgur.com/enmECtc.png)

##### Spawnflags

- **Local** only.

| Attribute | Description | Name | Value |
| --- | --- | --- | --- |
| Reusable | Make this Checkpoint reusable | SF_CHECKPOINT_REUSABLE | 1 |
| USE Only | Player must use the "+use" key to trigger this Checkpoint | SF_CHECKPOINT_USE_ONLY | 2 |
| Ignore Auto-Checkpoint | Ignore Auto-Checkpoint | SF_CHECKPOINT_NO_AUTO | 4 |

- Example

	[![](https://i.imgur.com/V1MPHD1.png)](https://i.imgur.com/V1MPHD1.png)

	[![](https://i.imgur.com/Mlnn8dX.png)](https://i.imgur.com/Mlnn8dX.png)

#### Auto-Checkpoint

##### Messages

| Attribute | Description | Name | Default Value |
| --- | --- | --- | --- |
| Update Respawn Points | Update Respawn Points of saved Checkpoints on each new save Checkpoint | g_fUpdateRespawnPoints | true |
| No Checkpoint Message | Message to be displayed when no Checkpoints are available | g_szNoCheckpoints | No !checkpoint available. |
| No Survival Message | Message to be displayed when Survival mode is not activated | g_szNoSurvival | Survival mode is not activated. |
| All Alive Message | Message to be displayed when at the end of the vote to activate all players are alive | g_szAllAlive | All players are alive, omitting results... |
| Wait For Vote Message | Message to be displayed when there is a time-out for a new vote | g_szWaitForVote | Wait !delay sec. |
| Vote In Progress Message | Message to be displayed when a vote is in progress | g_szVoteInProgress | Vote in progress! |
| No Vote To Cancel Message | Message to be displayed when there is no vote to cancel | g_szNoVoteToCancel | There's nothing to cancel! |
| Vote Canceled Message | Message to be displayed when a vote is cancelled | g_szVoteCanceled | Vote to activate a !checkpoint has been cancelled! |
| Admin Cancels Vote Message | Message to be displayed when admin cancels a vote | g_szAdminCancelsVote | Vote to activate a !checkpoint has been cancelled by !player! |
| Vote Started Message | Message to be displayed when vote to activate starts | g_szVoteStarted | Activate a !checkpoint? Say "!yes" to use it or "!no" to not use it. |
| Vote Failed Message | Message to be displayed when vote to activate fails | g_szVoteFailed | Vote failed. |
| Vote Success Message | Message to be displayed when vote to activate is successful | g_szVoteSuccess | Vote successful. |
| No One Voted Message | Message to be displayed when no one has voted | g_szNoOneVoted | !result No one voted. |
| Vote Result Message | Message to be displayed at the end of the vote | g_szVoteResult | !result Got "!infavor" needed "!required". |
| Voted For Message | Message to be displayed when a player votes in favor | g_szVotedFor | !player voted for. |
| Voted Against Message | Message to be displayed when a player votes against | g_szVotedAgainst | !player voted against. |

| Keyword | Replaced with | Available in |
| --- | --- | --- |
| `!delay` | **Vote Cooldown in Seconds** | **Wait For Vote Message** |
| `!player` | **Player Name** | **Admin Cancels Vote Message**, **Voted For Message**, **Voted Against Message** |
| `!result` | **Vote Result** (Vote Failed/Success Message) | **Vote Result Message**, **No One Voted Message** |
| `!infavor` | **Votes In Favor** | **Vote Result Message** |
| `!required` | **Votes Required to pass the Vote** | **Vote Result Message** |
| `!checkpoint` | **Checkpoint Name** | **All Messages** |

⚠️ **Update Respawn Points** is also available for **Local** as `m_fUpdateRespawnPoints`.

- Example

	[![](https://i.imgur.com/2yQrTz6.png)](https://i.imgur.com/2yQrTz6.png)

### Advanced

This type of customization can only be done globally.

And require some scripting knowledge...

1. In `Steam\steamapps\common\Sven Co-op\svencoop_addon\scripts\maps\chkpnt\callbacks\maps`:

	- Create a new file called `my_map.as`.

	- Open it and add the following lines:

		```angelscript
		#include "../structure/main"

		CallbackHandler@ g_pMyMapCallbacks = CallbackHandler(
			// Map name prefix finder, for multiple series type "my_map;my_map2"
			map: "my_map" // Applies only to: my_map, my_map_1a, my_map_2a
		);
		```

2. In the same directory open the `_.as` file and follow the example shown there.

#### Checkpoint

##### Events & Effects

- Function must return a boolean.

- Returning `true` will terminate the effects loop (except for Spawn Effect wich is one-call function).

| Event | Description | Name | Default Value |
| --- | --- | --- | --- |
| Spawn | Called at Checkpoint Spawn method | onSpawn | [null](./callbacks/structure/default.as#L30) |
| Idle | Called while Checkpoint is Idling | onIdle | [null](./callbacks/structure/default.as#L32) |
| Save | Called at Checkpoint Save method | onSave | [DefaultCallbacks::OnSave](./callbacks/structure/default.as#L34-L39) |
| Activate | Called at Checkpoint Activate method | onActivate | [DefaultCallbacks::OnActivate](./callbacks/structure/default.as#L54-L59) |
| Respawn Start | Called at Checkpoint Respawn Start method | onRespawnStart | [null](./callbacks/structure/default.as#L80) |
| Respawn | Called in every player respawn and last player to respawn | onRespawn | [null](./callbacks/structure/default.as#L85-L98) |
| Reenable | Called at Checkpoint Reenable method | onReenable | [null](./callbacks/structure/default.as#L101) |

| Effect | Description | Name | Default Value |
| --- | --- | --- | --- |
| Spawn | Called at Checkpoint Spawn method, `fSpawnEffect = true` required! | spawnFX | [DefaultCallbacks::SpawnEffect](./callbacks/structure/default.as#L4-L28) |
| Save | Called at Checkpoint Save method | saveFX | [DefaultCallbacks::SaveEffect](./callbacks/structure/default.as#L41-L52) |
| Activate | Called at Checkpoint Activate method | activateFX | [DefaultCallbacks::ActivateEffect](./callbacks/structure/default.as#L61-L78) |
| Reset | Called at Checkpoint Reset method | resetFX | [DefaultCallbacks::ResetEffect](./callbacks/structure/default.as#L103-L114) |

- Examples

	- [AoM/AoM:DC Callbacks](./callbacks/maps/aom.as)

	- [They Hunger Callbacks](./callbacks/maps/hunger.as)

	- [Wanted Callbacks](./callbacks/maps/wanted.as)

#### Auto-Checkpoint

##### Effect

- Hold Timers must return a boolean.

- Hold Effect must return a 2D array float (`array<array<float>>`).

| Function | Description | Name | Default Value |
| --- | --- | --- | --- |
| Hold Timers | `Hold Effect` timers | holdTimers | [DefaultCallbacks::HoldTimers](./callbacks/structure/default.as#L116-L124) |
| Hold Effect | Effect to be displayed in the last saved Checkpoint | holdFX | [DefaultCallbacks::HoldEffect](./callbacks/structure/default.as#L126-L149) |

## Relevant Notes

- You can precache models, sprites, sounds, etc. in [On Spawn](#events--effects) Event.

- [On Player Respawn](#events--effects): Changed `Touch` to `Use` in `game_player_equip` entity suggested by [Outerbeast](https://discord.com/channels/170051548284583937/800717524056408104/930250128936280094).

- There are another suggestion implementation see [here](./callbacks/structure/default.as#L86-99).

- There are a few entvars/keyvalues that are used by the entity itself like:

	- **Checkpoint:**

		| Key | Used in |
		| --- | --- |
		| netname | [On Spawn](#events--effects): Activate the entity with this name (Survival active require!) |
		| message | Player respawn sound |
		| fuser1 | Share possible time to finish respawning all players |
		| vuser1 | Min Hullsize |
		| vuser2 | Max Hullsize |
		| vuser3 | Respawn point |
		| health, frags, speed, dmg | Entity status (reached, active, etc) |

	- **Auto-Checkpoint:**

		| Key | Used in |
		| --- | --- |
		| iuser1 | Share the amount of Checkpoint saved |

- [**On Activate**, **On Save** and **On Idle**](#events--effects) are the only events that allow nextthink overwriting.

## Credits

- SC TEAM: For the original Checkpoint entity

- [JulianR0's SurvivalDX](https://github.com/JulianR0/SurvivalDX): Original idea of Custom Respawn Point and Sound customization

- Outerbeast: Discord suggestion for trigger fix for `game_player_equip` on player respawn.
