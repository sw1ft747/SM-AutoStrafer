# Auto Strafer
A [SourceMod](https://github.com/alliedmodders/sourcemod "SourceMod") plugin with maximum acceleration speed for Source Engine based games. I made this plugin back in 2021 for my [Dead Air run](https://www.youtube.com/watch?v=5hWryGWsFUU "Dead Air run"), just posting it since there's no point in keeping it private LOL.

This is a partial port of strafing algorithms from [HLStrafe](https://github.com/HLTAS/hlstrafe/ "HLStrafe") and [SourcePauseTool](https://github.com/YaLTeR/SourcePauseTool/ "SourcePauseTool"). I only adopted them for SourcePawn, original authors are [YaLTeR](https://github.com/YaLTeR "YaLTeR"), [Matherunner](https://github.com/Matherunner "Matherunner") and [Jukspa](https://github.com/lipsanen "Jukspa").

Strafer works for every client and can be individually toggled, although ConVar's functionality affects everyone (i.e. `strafe_target_yaw`).

## Console Commands
Client Command | Description
--- | ---
sm_vectorstrafer | Toggle vectorial strafer.
sm_autostrafer | Toggle auto strafer. Supposed to change view angles visually, but there's no difference with `sm_vectorstrafer` since view angles of player are not transmitted back to the client.

# Console Variables
ConVar | Default Value | Type | Description
--- | --- | --- | ---
strafe | 1 | bool | Enable/disable auto strafer for everyone.
strafe_target_yaw | "" | float | Yaw to strafe, leave empty argument to disable (i.e. `strafe_target_yaw ""`).
strafe_vectorial_increment | 2.5 | float | Determines how fast the player yaw angle moves towards the target yaw angle.
strafe_vectorial_snap | 170 | float | Determines when the yaw angle snaps to the target yaw.
strafe_vectorial_offset | 0 | float | Determines the target view angle offset from strafe_target_yaw.
strafe_yaw_multiplier | 1 | float | Multiplier for the determined yaw.