// Auto Strafer
// Original strafe algorithms from HLStrafe: https://github.com/HLTAS/hlstrafe/
// Original vectorial strafe algorithm from SourcePauseTool: https://github.com/YaLTeR/SourcePauseTool/
// Credits: YaLTeR, Matherunner, Jukspa

#include <sourcemod>
#include <sdktools>

#define MAXSPEED 450.0

ConVar g_hAirAccelerate, g_hForwardSpeed, g_hSideSpeed;
ConVar g_hCvarAllow, g_hCvarTargetYaw, g_hCvarVectorialIncrement, g_hCvarVectorialSnap, g_hCvarVectorialOffset, g_hCvarYawMultiplier;
float g_flAirAccelerate, g_flCvarTargetYaw, g_flCvarVectorialIncrement, g_flCvarVectorialSnap, g_flCvarVectorialOffset, g_flYawMultiplier;
bool g_bCvarAllow;

bool g_bAutoStrafer[ MAXPLAYERS + 1 ];
bool g_bVectorialStrafer[ MAXPLAYERS + 1 ];

float FORWARDSPEED = 450.0;
float SIDESPEED = 450.0;

float frametime = 0.033333333333;

public Plugin myinfo =
{
	name = "Auto Strafer",
	author = "Sw1ft",
	description = "Strafing Tools",
	version = "1.0",
	url = "http://steamcommunity.com/profiles/76561198397776991"
}

public void OnPluginStart()
{
	EngineVersion version = GetEngineVersion();

	if ( version == Engine_Left4Dead || version == Engine_Left4Dead2 )
	{
		g_hForwardSpeed = FindConVar( "z_forwardspeed" );
		g_hSideSpeed = FindConVar( "z_sidespeed" );
	}
	else
	{
		g_hForwardSpeed = FindConVar( "cl_forwardspeed" );
		g_hSideSpeed = FindConVar( "cl_sidespeed" );

		PrintToChatAll( "[Auto Strafer] WARNING: the plugin was tested only on the Left 4 Dead 1/2 engines" );
	}

	g_hAirAccelerate = FindConVar( "sv_airaccelerate" );

	g_hCvarAllow = CreateConVar( "strafe", "1", "0 = Plugin off, 1 = Plugin on.", FCVAR_NOTIFY );
	g_hCvarTargetYaw = CreateConVar( "strafe_target_yaw", "", "Yaw to strafe, leave empty argument to disable." );
	g_hCvarVectorialIncrement = CreateConVar( "strafe_vectorial_increment", "2.5", "Determines how fast the player yaw angle moves towards the target yaw angle." );
	g_hCvarVectorialSnap = CreateConVar( "strafe_vectorial_snap", "170", "Determines when the yaw angle snaps to the target yaw." );
	g_hCvarVectorialOffset = CreateConVar( "strafe_vectorial_offset", "0", "Determines the target view angle offset from strafe_target_yaw." );
	g_hCvarYawMultiplier = CreateConVar( "strafe_yaw_multiplier", "1.0", "Multiplier for the determined yaw." );

	g_hAirAccelerate.AddChangeHook( OnConVarChanged );
	g_hCvarAllow.AddChangeHook( OnConVarChanged );
	g_hCvarTargetYaw.AddChangeHook( OnConVarChanged );
	g_hCvarVectorialIncrement.AddChangeHook( OnConVarChanged );
	g_hCvarVectorialSnap.AddChangeHook( OnConVarChanged );
	g_hCvarVectorialOffset.AddChangeHook( OnConVarChanged );
	g_hCvarYawMultiplier.AddChangeHook( OnConVarChanged );

	RegConsoleCmd( "sm_vectorstrafer", ToggleVectorialStrafer );
	RegConsoleCmd( "sm_autostrafer", ToggleAutoStrafer );

	InitCvarValues();

	frametime = 1.0 / 30.0;
}

public void OnConVarChanged( Handle hCvar, const char[] oldValue, const char[] newValue )
{
	if ( hCvar == g_hCvarAllow )
	{
		g_bCvarAllow = g_hCvarAllow.BoolValue;
	}
	else if ( hCvar == g_hCvarTargetYaw )
	{
		g_flCvarTargetYaw = g_hCvarTargetYaw.FloatValue;
	}
	else if ( hCvar == g_hCvarVectorialIncrement )
	{
		g_flCvarVectorialIncrement = g_hCvarVectorialIncrement.FloatValue;
	}
	else if ( hCvar == g_hCvarVectorialSnap )
	{
		g_flCvarVectorialSnap = g_hCvarVectorialSnap.FloatValue;
	}
	else if ( hCvar == g_hCvarVectorialOffset )
	{
		g_flCvarVectorialOffset = g_hCvarVectorialOffset.FloatValue;
	}
	else if ( hCvar == g_hCvarYawMultiplier )
	{
		g_flYawMultiplier = g_hCvarYawMultiplier.FloatValue;
	}
	else if ( hCvar == g_hAirAccelerate )
	{
		g_flAirAccelerate = g_hAirAccelerate.FloatValue;
	}
}

public Action ToggleVectorialStrafer( int client, int args )
{
	if ( client == 0 )
	{
		if ( !IsDedicatedServer() && IsClientInGame( 1 ) )
		{
			client = 1;
		}
		else
		{
			return Plugin_Handled;
		}
	}

	PrintToChat( client, g_bVectorialStrafer[ client ] ? "[SM] Vectorial Strafer is OFF" : "[SM] Vectorial Strafer is ON" );
	g_bVectorialStrafer[ client ] = !g_bVectorialStrafer[ client ];

	return Plugin_Handled;
}

public Action ToggleAutoStrafer( int client, int args )
{
	if ( client == 0 )
	{
		if ( !IsDedicatedServer() && IsClientInGame( 1 ) )
		{
			client = 1;
		}
		else
		{
			return Plugin_Handled;
		}
	}

	PrintToChat( client, g_bAutoStrafer[ client ] ? "[SM] Auto Strafer is OFF" : "[SM] Auto Strafer is ON" );
	g_bAutoStrafer[ client ] = !g_bAutoStrafer[ client ];

	return Plugin_Handled;
}

public Action OnPlayerRunCmd( int client, int &buttons, int &impulse, float move[ 3 ], float angles[ 3 ] )
{
	if ( g_bCvarAllow && ( g_bAutoStrafer[ client ] || g_bVectorialStrafer[ client ] ) && IsClientInGame( client ) && IsPlayerAlive( client ) )
		PerformStrafe( client, buttons, move, angles );

	return Plugin_Continue;
}

void PerformStrafe( int client, int &buttons, float move[ 3 ], float angles[ 3 ] )
{
	if ( GetEntPropEnt( client, Prop_Send, "m_hGroundEntity" ) != -1 || GetEntityMoveType( client ) != MOVETYPE_WALK || buttons & ( IN_FORWARD | IN_MOVELEFT | IN_BACK | IN_MOVERIGHT ) )
		return;
	
	FORWARDSPEED = GetConVarFloat( g_hForwardSpeed );
	SIDESPEED = GetConVarFloat( g_hSideSpeed );

	char szTargetYawBuffer[ 2 ];

	float flCurrentYaw = angles[ 1 ];
	float flDifference, flTargetYaw, flTheta, flYaw;
	float flForwardSpeed, flSideSpeed, flVelocity[ 3 ];

	bool bVectorialStrafe = g_bVectorialStrafer[ client ];

	g_hCvarTargetYaw.GetString( szTargetYawBuffer, 2 )

	if ( szTargetYawBuffer[ 0 ] == '\0' )
		flTargetYaw = flCurrentYaw;
	else
		flTargetYaw = g_flCvarTargetYaw;

	GetEntPropVector( client, Prop_Data, "m_vecVelocity", flVelocity );
	flVelocity[ 2 ] = 0.0;

	flTheta = Strafe( bVectorialStrafe, flTargetYaw, flCurrentYaw, flVelocity, flForwardSpeed, flSideSpeed ) * g_flYawMultiplier;

	if ( bVectorialStrafe )
	{
		if ( g_flCvarVectorialIncrement > 0.0 )
		{
			float adjustedTarget = NormalizeAngle( flTargetYaw + g_flCvarVectorialOffset );
			float normalizedDiff = NormalizeAngle( adjustedTarget - flCurrentYaw );
			float additionAbs = FloatMin( g_flCvarVectorialIncrement, FloatAbs( normalizedDiff ) );

			if ( FloatAbs( normalizedDiff ) > g_flCvarVectorialSnap )
				flYaw = adjustedTarget;
			else
				flYaw = flCurrentYaw + CopySign( additionAbs, normalizedDiff );
		}
		else
		{
			flYaw = flCurrentYaw;
		}

		flDifference = DegToRad( flYaw - flTheta );
		flForwardSpeed = Cosine( flDifference ) * FORWARDSPEED;
		flSideSpeed = Sine( flDifference ) * SIDESPEED;
	}
	else
	{
		angles[ 1 ] = flTheta;
	}

	move[ 0 ] = flForwardSpeed;
	move[ 1 ] = flSideSpeed;
}

float Strafe( bool bVectorialStrafe, float target_yaw, float vel_yaw, float move[ 3 ], float &flForwardSpeed, float &flSideSpeed )
{
	int usedButton = bVectorialStrafe ? -1 : 0;

	float flYaw = RadToDeg( YawStrafeMaxAccel( usedButton, DegToRad( vel_yaw ), DegToRad( target_yaw ), move ) );

	if ( !bVectorialStrafe )
	{
		if ( usedButton == 0 || usedButton == 1 || usedButton == 7 )
		{
			flForwardSpeed += FORWARDSPEED;
		}
		if ( usedButton == 4 || usedButton == 3 || usedButton == 5 )
		{
			flForwardSpeed -= FORWARDSPEED;
		}
		if ( usedButton == 6 || usedButton == 7 || usedButton == 5 )
		{
			flSideSpeed += SIDESPEED;
		}
		if ( usedButton == 2 || usedButton == 1 || usedButton == 3 )
		{
			flSideSpeed -= SIDESPEED;
		}
	}

	return flYaw;
}

float SideStrafeGeneral( int &usedButton, float tangent_yaw, float vel_yaw, float theta, bool right, bool isZero )
{
	float phi = 0.0;

	if ( usedButton != -1 )
	{
		if ( theta < FLOAT_PI / 8 )
			usedButton = 0;
		else if ( theta < 3 * FLOAT_PI / 8 )
			usedButton = right ? 7 : 1;
		else if ( theta < 5 * FLOAT_PI / 8 )
			usedButton = right ? 6 : 2;
		else if ( theta < 7 * FLOAT_PI / 8 )
			usedButton = right ? 5 : 3;
		else
			usedButton = 4;

		switch ( usedButton )
		{
		case 0:	phi = 0.0; // FORWARD
		case 1:	phi = FLOAT_PI / 4; // FORWARD_LEFT
		case 2: phi = FLOAT_PI / 2; // LEFT
		case 3: phi = 3 * FLOAT_PI / 4; // BACK_LEFT
		case 4: phi = -FLOAT_PI; // BACK
		case 5: phi = -3 * FLOAT_PI / 4; // BACK_RIGHT
		case 6: phi = -FLOAT_PI / 2; // RIGHT
		case 7: phi = -FLOAT_PI / 4; // FORWARD_RIGHT
		default: phi = 0.0;
		}
	}

	theta = right ? -theta : theta;

	if ( !isZero )
		vel_yaw = tangent_yaw;

	return NormalizeRadians( vel_yaw - phi + theta );
}

float YawStrafeMaxAccel( int &usedButton, float vel_yaw, float yaw, float move[ 3 ] )
{
	// MaxAccelIntoYawTheta. begin
	float theta;
	float tangent_yaw = 0.0;
	bool isZero = ( move[ 0 ] == 0.0 && move[ 1 ] == 0.0 );

	if ( !isZero )
		vel_yaw = tangent_yaw = ArcTangent2( move[ 1 ], move[ 0 ] );

	// MaxAccelTheta. begin
	float accelspeed = FloatMax( FORWARDSPEED, SIDESPEED ) * g_flAirAccelerate * frametime; // GetEntPropFloat(client, Prop_Send, "m_flFriction")

	if ( accelspeed > 0.0 )
	{
		if ( isZero )
		{
			theta = 0.0;
		}
		else
		{
			float wishspeed_capped = 30.0;
			float tmp = wishspeed_capped - accelspeed;

			if ( tmp <= 0.0 )
			{
				theta = FLOAT_PI / 2.0;
			}
			else
			{
				float speed = GetVectorLength( move, false );
				theta = ( tmp < speed ) ? ArcCosine( tmp / speed ) : 0.0;
			}
		}
	}
	else
	{
		theta = FLOAT_PI;
	}

	// MaxAccelTheta. end

	if ( theta == 0.0 || theta == FLOAT_PI )
		theta = NormalizeRadians( yaw - vel_yaw + theta );
	else
		theta = CopySign( theta, NormalizeRadians( yaw - vel_yaw ) );

	// MaxAccelIntoYawTheta. end

	return SideStrafeGeneral( usedButton, tangent_yaw, vel_yaw, FloatAbs( theta ), theta < 0, isZero );
}

void InitCvarValues()
{
	g_flAirAccelerate = g_hAirAccelerate.FloatValue;
	g_bCvarAllow = g_hCvarAllow.BoolValue;
	g_flCvarTargetYaw = g_hCvarTargetYaw.FloatValue;
	g_flCvarVectorialIncrement = g_hCvarVectorialIncrement.FloatValue;
	g_flCvarVectorialSnap = g_hCvarVectorialSnap.FloatValue;
	g_flCvarVectorialOffset = g_hCvarVectorialOffset.FloatValue;
	g_flYawMultiplier = g_hCvarYawMultiplier.FloatValue;
}

float NormalizeAngle( float flAngle )
{
	while ( flAngle > 180.0 )
		flAngle -= 360.0;

	while ( flAngle < 180.0 )
		flAngle += 360.0;

	return flAngle;
}

float NormalizeRadians( float flAngle )
{
	while ( flAngle > FLOAT_PI )
		flAngle -= 2 * FLOAT_PI;

	while ( flAngle < -FLOAT_PI )
		flAngle += 2 * FLOAT_PI;

	return flAngle;
}

float FloatMax( float a, float b )
{
	return a > b ? a : b;
}

float FloatMin( float a, float b )
{
	return a < b ? a : b;
}

float CopySign( float dest, float src )
{
	return ( src < 0 && dest > 0 || src > 0 && dest < 0 ) ? -dest : dest;
}