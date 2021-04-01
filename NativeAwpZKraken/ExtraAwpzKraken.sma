#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <biohazard>

#pragma compress 				1

#define PLUGIN 					"[ZP] Extra: CSO Weapon Awp Zombie Gun"
#define VERSION 				"1.1"
#define AUTHOR 					"KORD_12.7"

#pragma ctrlchar '\'

//**********************************************
//* Weapon Settings.                           *
//**********************************************

// Main
#define WEAPON_KEY				10248996
#define WEAPON_NAME 				"weapon_zgun"

#define WEAPON_REFERANCE			"weapon_awp"
#define WEAPON_MAX_CLIP				10
#define WEAPON_DEFAULT_AMMO			30

#define WEAPON_TIME_NEXT_IDLE 			5.0
#define WEAPON_TIME_NEXT_ATTACK 		1.1
#define WEAPON_TIME_NEXT_ATTACK_B 		4.0
#define WEAPON_TIME_DELAY_DEPLOY 		1.0
#define WEAPON_TIME_DELAY_RELOAD 		3.0

#define WEAPON_DAMAGE  	  			1.1

//Grenade
#define WEAPON_DAMAGE_BALL_EXP			random_float(400.0, 500.0)
#define WEAPONN_KRAKEN_DAMAGE			random_float(500.0, 700.0)
#define WEAPON_BALL_RADIUS_EXP			200.0
#define WEAPON_BALL_SPEED			1000.0
#define WEAPON_KRAKEN_KNOCKBACK			400.0

#define ZP_ITEM_NAME				"AwpZ" 
#define ZP_ITEM_COST				0

// Models
#define MODEL_WORLD				"models/w_zgun.mdl"
#define MODEL_VIEW				"models/v_zgun.mdl"
#define MODEL_PLAYER				"models/p_zgun.mdl"
#define MODEL_GRENADE				"models/ef_fireball2.mdl"
#define MODEL_KRAKEN				"models/ef_kraken.mdl"

// Sounds
#define SOUND_FIRE				"weapons/zgun-1.wav"

#define SOUND_EXPLODE				"weapons/kraken_exp.wav"
#define SOUND_EXPLODE2				"weapons/kraken_up.wav"

// Sprites
#define WEAPON_HUD_TXT				"sprites/weapon_zgun.txt"
#define WEAPON_HUD_SPR_1			"sprites/640hud90_1.spr"
#define WEAPON_HUD_SPR_2			"sprites/640hud7.spr"

#define SPRITE_EXP				"sprites/ef_kraken_exp.spr"
#define SPRITE_SMOKE				"sprites/ef_kraken_fire.spr"

// Animation
#define ANIM_EXTENSION				"rifle"

#define GRENADE_CLASSNAME			"GrenadeAwp"
#define KRAKEN_CLASSNAME			"KrakeClass"

// Animation sequences
enum
{	
	ANIM_IDLE,
	ANIM_SHOOT1,
	ANIM_SHOOT2,
	ANIM_SHOOT3,
	ANIM_RELOAD,
	ANIM_DRAW
};
//**********************************************
//* Some macroses.                             *
//**********************************************

#define MDLL_Spawn(%0)			dllfunc(DLLFunc_Spawn, %0)
#define MDLL_Touch(%0,%1)		dllfunc(DLLFunc_Touch, %0, %1)
#define MDLL_USE(%0,%1)			dllfunc(DLLFunc_Use, %0, %1)

#define SET_MODEL(%0,%1)		engfunc(EngFunc_SetModel, %0, %1)
#define SET_ORIGIN(%0,%1)		engfunc(EngFunc_SetOrigin, %0, %1)

#define PRECACHE_MODEL(%0)		engfunc(EngFunc_PrecacheModel, %0)
#define PRECACHE_SOUND(%0)		engfunc(EngFunc_PrecacheSound, %0)
#define PRECACHE_GENERIC(%0)		engfunc(EngFunc_PrecacheGeneric, %0)

#define MESSAGE_BEGIN(%0,%1,%2,%3)	engfunc(EngFunc_MessageBegin, %0, %1, %2, %3)
#define MESSAGE_END()			message_end()

#define WRITE_ANGLE(%0)			engfunc(EngFunc_WriteAngle, %0)
#define WRITE_BYTE(%0)			write_byte(%0)
#define WRITE_COORD(%0)			engfunc(EngFunc_WriteCoord, %0)
#define WRITE_STRING(%0)		write_string(%0)
#define WRITE_SHORT(%0)			write_short(%0)

#define BitSet(%0,%1) 			(%0 |= (1 << (%1 - 1)))
#define BitClear(%0,%1)			(%0 &= ~(1 << (%1 - 1)))
#define BitCheck(%0,%1) 		(%0 & (1 << (%1 - 1)))

//**********************************************
//* PvData Offsets.                            *
//**********************************************

// Linux extra offsets
#define extra_offset_weapon		4
#define extra_offset_player		5

new g_bitIsConnected;

#define m_rgpPlayerItems_CWeaponBox	34

// CBasePlayerItem
#define m_pPlayer			41
#define m_pNext				42
#define m_iId                        	43

// CBasePlayerWeapon
#define m_fInSuperBullets		30
#define m_fFireOnEmpty 			45
#define m_flNextPrimaryAttack		46
#define m_flNextSecondaryAttack		47
#define m_flTimeWeaponIdle		48
#define m_iPrimaryAmmoType		49
#define m_iClip				51
#define m_fInReload			54
#define m_flAccuracy 			62
#define m_iLastZoom 			109

// CBaseMonster
#define m_flNextAttack			83

// CBasePlayer
#define m_flVelocityModifier 		108 
#define m_fResumeZoom       		110
#define m_iFOV				363
#define m_rgpPlayerItems_CBasePlayer	367
#define m_pActiveItem			373
#define m_rgAmmo_CBasePlayer		376
#define m_szAnimExtention		492

#define IsValidPev(%0) 			(pev_valid(%0) == 2)

#define INSTANCE(%0)			((%0 == -1) ? 0 : %0)

#define IsCustomItem(%0) 		(pev(%0, pev_impulse) == WEAPON_KEY)

//**********************************************
//* Let's code our weapon.                     *
//**********************************************

new iBlood[5];
new Float:iTimeSkill[33];
new iUseSkill[33];

Weapon_OnPrecache()
{
	PRECACHE_MODEL(MODEL_WORLD);
	PRECACHE_MODEL(MODEL_VIEW);
	PRECACHE_SOUNDS_FROM_MODEL(MODEL_VIEW);
	PRECACHE_MODEL(MODEL_PLAYER);
	PRECACHE_MODEL(MODEL_GRENADE);
	PRECACHE_MODEL(MODEL_KRAKEN);
	
	PRECACHE_SOUND(SOUND_FIRE);
	PRECACHE_SOUND(SOUND_EXPLODE);
	PRECACHE_SOUND(SOUND_EXPLODE2);
	
	PRECACHE_GENERIC(WEAPON_HUD_TXT);
	PRECACHE_GENERIC(WEAPON_HUD_SPR_1);
	PRECACHE_GENERIC(WEAPON_HUD_SPR_2);
	
	iBlood[0] = PRECACHE_MODEL("sprites/bloodspray.spr");
	iBlood[1] = PRECACHE_MODEL("sprites/blood.spr");
	iBlood[2] = PRECACHE_MODEL(SPRITE_EXP);
	iBlood[3] = PRECACHE_MODEL(SPRITE_SMOKE);
	iBlood[4] = PRECACHE_MODEL("sprites/smoke.spr");
}

Weapon_OnSpawn(const iItem)
{
	// Setting world model.
	SET_MODEL(iItem, MODEL_WORLD);
}

Weapon_OnDeploy(const iItem, const iPlayer, const iClip, const iAmmoPrimary)
{
	#pragma unused iClip, iAmmoPrimary
		
	static iszViewModel;
	if (iszViewModel || (iszViewModel = engfunc(EngFunc_AllocString, MODEL_VIEW)))
	{
		set_pev_string(iPlayer, pev_viewmodel2, iszViewModel);
	}
	
	static iszPlayerModel;
	if (iszPlayerModel || (iszPlayerModel = engfunc(EngFunc_AllocString, MODEL_PLAYER)))
	{
		set_pev_string(iPlayer, pev_weaponmodel2, iszPlayerModel);
	}

	set_pdata_int(iItem, m_fInReload, 0, extra_offset_weapon);

	set_pdata_string(iPlayer, m_szAnimExtention * 4, ANIM_EXTENSION, -1, extra_offset_player * 4);
	
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_TIME_DELAY_DEPLOY, extra_offset_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_TIME_DELAY_DEPLOY, extra_offset_player);

	Weapon_DefaultDeploy(iPlayer, MODEL_VIEW, MODEL_PLAYER, ANIM_DRAW, ANIM_EXTENSION);
}

Weapon_OnHolster(const iItem, const iPlayer, const iClip, const iAmmoPrimary)
{
	#pragma unused iPlayer, iClip, iAmmoPrimary
	
	set_pdata_int(iItem, m_fInReload, 0, extra_offset_weapon);
}

Weapon_OnIdle(const iItem, const iPlayer, const iClip, const iAmmoPrimary)
{
	#pragma unused iClip, iAmmoPrimary

	ExecuteHamB(Ham_Weapon_ResetEmptySound, iItem);
	
	if (get_pdata_float(iItem, m_flTimeWeaponIdle, extra_offset_weapon) > 0.0)
	{
		return;
	}
	
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_TIME_NEXT_IDLE, extra_offset_weapon);
	
	Weapon_SendAnim(iPlayer, ANIM_IDLE);
}

Weapon_OnReload(const iItem, const iPlayer, const iClip, const iAmmoPrimary)
{
	#pragma unused iAmmoPrimary
	
	if (min(WEAPON_MAX_CLIP - iClip, iAmmoPrimary) <= 0)
	{
		return;
	}
	
	set_pdata_int(iItem, m_iClip, 0, extra_offset_weapon);
	
	ExecuteHam(Ham_Weapon_Reload, iItem);
	
	set_pdata_int(iItem, m_iClip, iClip, extra_offset_weapon);
	
	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_TIME_DELAY_RELOAD, extra_offset_player);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_TIME_DELAY_RELOAD, extra_offset_weapon);
	
	Weapon_SendAnim(iPlayer, ANIM_RELOAD);
}

Weapon_OnPrimaryAttack(const iItem, const iPlayer, const iClip, const iAmmoPrimary)
{
	#pragma unused iAmmoPrimary
	
	CallOrigFireBullets3(iItem, iPlayer);
	
	if (iClip <= 0)
	{
		if (get_pdata_int(iItem, m_fFireOnEmpty, extra_offset_player))
		{
			ExecuteHamB(Ham_Weapon_PlayEmptySound, iItem);
			set_pdata_float(iItem, m_flNextPrimaryAttack, 0.2, extra_offset_weapon);
		}
		return;
	}
	
	static iFlags, iAnimDesired; 
	static szAnimation[64];iFlags = pev(iPlayer, pev_flags);

	Punchangle(iPlayer, .iVecx = -1.5, .iVecy = random_float(-0.8,0.8), .iVecz = 0.0);
	
	Weapon_SendAnim(iPlayer, random_num(ANIM_SHOOT1, ANIM_SHOOT2));
				
	formatex(szAnimation, charsmax(szAnimation), iFlags & FL_DUCKING ? "crouch_shoot_%s" : "ref_shoot_%s", ANIM_EXTENSION);
								
	if ((iAnimDesired = lookup_sequence(iPlayer, szAnimation)) == -1)
	{
		iAnimDesired = 0;
	}
					
	set_pev(iPlayer, pev_sequence, iAnimDesired);

	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_TIME_NEXT_ATTACK, extra_offset_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_TIME_NEXT_ATTACK, extra_offset_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_TIME_NEXT_ATTACK + 0.6, extra_offset_weapon);
	
	engfunc(EngFunc_EmitSound, iPlayer, CHAN_WEAPON, SOUND_FIRE, 0.9, ATTN_NORM, 0, PITCH_NORM);
}

//*********************************************************************
//*           Don't modify the code below this line unless            *
//*          	 you know _exactly_ what you are doing!!!             *
//*********************************************************************

#define MSGID_WEAPONLIST 78

new g_iItemID;
new iMaxPlayers;

public plugin_precache()
{
	Weapon_OnPrecache();

	register_clcmd(WEAPON_NAME, "Cmd_WeaponSelect");
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_forward(FM_UpdateClientData,				"FakeMeta_UpdateClientData_Post",	true);
	register_forward(FM_PlaybackEvent,				"FakeMeta_PlaybackEvent",	 	false);
	register_forward(FM_SetModel,					"FakeMeta_SetModel",			false);
	register_forward(FM_PlayerPreThink, 				"FakeMeta_PlayerPreThink", 		false);
	register_forward(FM_Think, 					"FakeMeta_Think",			false);
	register_forward(FM_Touch, 					"FakeMeta_Touch",		 	false);
	
	RegisterHam(Ham_Spawn, 			"weaponbox", 		"HamHook_Weaponbox_Spawn_Post", true);

	RegisterHam(Ham_TraceAttack,		"func_breakable",	"HamHook_Entity_TraceAttack", 	false);
	RegisterHam(Ham_TraceAttack,		"info_target", 		"HamHook_Entity_TraceAttack", 	false);
	RegisterHam(Ham_TraceAttack,		"player", 		"HamHook_Entity_TraceAttack", 	false);

	RegisterHam(Ham_Item_Deploy,		WEAPON_REFERANCE, 	"HamHook_Item_Deploy_Post",	true);
	RegisterHam(Ham_Item_Holster,		WEAPON_REFERANCE, 	"HamHook_Item_Holster",		false);
	RegisterHam(Ham_Item_AddToPlayer,	WEAPON_REFERANCE, 	"HamHook_Item_AddToPlayer",	false);
	RegisterHam(Ham_Item_PostFrame,		WEAPON_REFERANCE, 	"HamHook_Item_PostFrame",	false);
	
	RegisterHam(Ham_Weapon_Reload,		WEAPON_REFERANCE, 	"HamHook_Item_Reload",		false);
	RegisterHam(Ham_Weapon_WeaponIdle,	WEAPON_REFERANCE, 	"HamHook_Item_WeaponIdle",	false);
	RegisterHam(Ham_Weapon_PrimaryAttack,	WEAPON_REFERANCE, 	"HamHook_Item_PrimaryAttack",	false);
	
	
	iMaxPlayers = get_maxplayers();
}
	
public zp_extra_item_selected(id, itemid)
{
	if (itemid == g_iItemID)
	{
		Weapon_Give(id);
	}
}

public plugin_natives()
{ 
	register_native("nExtraAwpZKraken", "NativeGiveWeapon", true); 
}

public NativeGiveWeapon(iPlayer)
{
	Weapon_Give(iPlayer);
}

public event_infect(iPlayer, iInfector) 
{
	iTimeSkill[iPlayer] = 0.0;
	iUseSkill[iPlayer] = false;
}

public zp_round_ended()
{
	for (new i = 1; i <= iMaxPlayers; i++)
	{
		if (!is_user_connected(i))
		{
			continue;
		}
		iTimeSkill[i] = 0.0;
		iUseSkill[i] = false;
	}
}

public FakeMeta_PlayerPreThink(const iPlayer)
{
	if (!is_user_alive(iPlayer)) 
	{
		return FMRES_IGNORED;
	}

	new Float:iTime = get_gametime();

	if (iTimeSkill[iPlayer] <= iTime)
	{
		iUseSkill[iPlayer] = false;
	}
	
	new iButton = pev(iPlayer, pev_button);
	
	if((iButton & IN_USE))
	{
		HamHook_Player_ObjectCaps(iPlayer);
	}
	
	return FMRES_IGNORED;
}

public HamHook_Player_ObjectCaps(iPlayer)
{
	new Float:iTime;iTime = get_gametime();
	
	if (!is_user_alive(iPlayer))
	{
		return FMRES_IGNORED;
	}
	
	new iItem;iItem = get_pdata_cbase(iPlayer, m_pActiveItem, extra_offset_player);
	
	if (!IsValidPev(iItem) || !IsCustomItem(iItem))
	{
		return FMRES_IGNORED;
	}
	
	if (iUseSkill[iPlayer])
	{
		client_print(iPlayer, print_center, "Skill Reload");
		return FMRES_IGNORED;
	}
	
	if (iTimeSkill[iPlayer] <= iTime)
	{
		iUseSkill[iPlayer] = true;
		iTimeSkill[iPlayer] = iTime + WEAPON_TIME_NEXT_ATTACK_B;
			
		new pEntity;
		new Float:vStart[3],Float:vEnd[3];
		new iszAllocStringCached;
			
		fm_get_aim_origin(iPlayer, vEnd);
		GetPosition(iPlayer, 15.0, 0.0, -5.0, vStart);
			
		if (iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, "info_target")))
		{
			pEntity = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached);
		}
			
		if (pev_valid(pEntity))
		{
			set_pev(pEntity, pev_movetype, MOVETYPE_TOSS);
			set_pev(pEntity, pev_owner, iPlayer);
				
			SET_MODEL(pEntity, MODEL_GRENADE)
			SET_ORIGIN(pEntity, vStart)
		
			set_pev(pEntity, pev_classname, GRENADE_CLASSNAME);
			set_pev(pEntity, pev_gravity, 0.2);
			set_pev(pEntity, pev_solid, SOLID_BBOX);
		
			static Float:iVelocity[3];GetSpeedVector(vStart, vEnd, WEAPON_BALL_SPEED, iVelocity);
			set_pev(pEntity, pev_velocity, iVelocity);
				
			MESSAGE_BEGIN(MSG_BROADCAST, SVC_TEMPENTITY, {0.0,0.0,0.0}, 0);
			WRITE_BYTE(TE_BEAMFOLLOW);
			WRITE_SHORT(pEntity);
			WRITE_SHORT(iBlood[4]);
			WRITE_BYTE(10)  
			WRITE_BYTE(4)  
			WRITE_BYTE(0) 
			WRITE_BYTE(200); 
			WRITE_BYTE(0);  
			WRITE_BYTE(200); 
			MESSAGE_END();
		}
	}
	return FMRES_IGNORED;
}

public FakeMeta_Touch(const iEnt, const iOther)
{
	if(!pev_valid(iEnt))
	{
		return FMRES_IGNORED;
	}
	
	static iClassname[32];pev(iEnt, pev_classname, iClassname, sizeof(iClassname));
	static iAttacker; iAttacker = pev(iEnt, pev_owner);
	
	if (equal(iClassname, GRENADE_CLASSNAME))
	{
		static Float:Origin[3];pev(iEnt, pev_origin, Origin);
		static pevVictim; pevVictim = -1;
		static iEntity;
		static iszAllocStringCached2;
		
		if (engfunc(EngFunc_PointContents, Origin) == CONTENTS_SKY || engfunc(EngFunc_PointContents, Origin) == CONTENTS_WATER)
		{
			set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME);
			return FMRES_SUPERCEDE;
		}
		
		if (!is_user_connected(iAttacker))
		{
			set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME);
			return FMRES_SUPERCEDE;
		}
		
		MESSAGE_BEGIN(MSG_PVS, SVC_TEMPENTITY, Origin, 0);
		WRITE_BYTE(TE_EXPLOSION);
		WRITE_COORD(Origin[0]); 
		WRITE_COORD(Origin[1]);
		WRITE_COORD(Origin[2] + 10.0);
		WRITE_SHORT(iBlood[2]);
		WRITE_BYTE(14);
		WRITE_BYTE(8);
		WRITE_BYTE(TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOPARTICLES);
		MESSAGE_END();
		
		MESSAGE_BEGIN(MSG_PVS, SVC_TEMPENTITY, Origin, 0);
		WRITE_BYTE(TE_EXPLOSION);
		WRITE_COORD(Origin[0]); 
		WRITE_COORD(Origin[1]);
		WRITE_COORD(Origin[2] + 10.0);
		WRITE_SHORT(iBlood[3]);
		WRITE_BYTE(8);
		WRITE_BYTE(6);
		WRITE_BYTE(TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOPARTICLES);
		MESSAGE_END();
		
		engfunc(EngFunc_EmitSound, iEnt, CHAN_ITEM, SOUND_EXPLODE2, 0.9, ATTN_NORM, 0, PITCH_NORM);
			
		while((pevVictim = engfunc(EngFunc_FindEntityInSphere, pevVictim, Origin, WEAPON_BALL_RADIUS_EXP)) != 0 )
		{
			if (!is_user_alive(pevVictim))continue;
			if (!is_user_zombie(pevVictim))continue;	
			
			new Float:vOrigin[3];pev(pevVictim, pev_origin, vOrigin);
	
			MESSAGE_BEGIN(MSG_BROADCAST, SVC_TEMPENTITY, {0.0,0.0,0.0}, 0);
			WRITE_BYTE(TE_BLOODSPRITE);
			WRITE_COORD(vOrigin[0]);
			WRITE_COORD(vOrigin[1]);
			WRITE_COORD(vOrigin[2]);
			WRITE_SHORT(iBlood[0]);
			WRITE_SHORT(iBlood[1]);
			WRITE_BYTE(76);
			WRITE_BYTE(18);
			MESSAGE_END();
			
			MESSAGE_BEGIN(MSG_PVS, SVC_TEMPENTITY, Origin, 0);
			WRITE_BYTE(TE_EXPLOSION);
			WRITE_COORD(vOrigin[0]); 
			WRITE_COORD(vOrigin[1]);
			WRITE_COORD(vOrigin[2] + 10.0);
			WRITE_SHORT(iBlood[2]);
			WRITE_BYTE(15);
			WRITE_BYTE(8);
			WRITE_BYTE(TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOPARTICLES);
			MESSAGE_END();
		
			MESSAGE_BEGIN(MSG_PVS, SVC_TEMPENTITY, Origin, 0);
			WRITE_BYTE(TE_EXPLOSION);
			WRITE_COORD(vOrigin[0]); 
			WRITE_COORD(vOrigin[1]);
			WRITE_COORD(vOrigin[2] + 10.0);
			WRITE_SHORT(iBlood[3]);
			WRITE_BYTE(10);
			WRITE_BYTE(6);
			WRITE_BYTE(TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOPARTICLES);
			MESSAGE_END();
					
			ExecuteHamB(Ham_TakeDamage, pevVictim, iEnt, iAttacker, WEAPON_DAMAGE_BALL_EXP, DMG_SONIC);
			
			if (iszAllocStringCached2 || (iszAllocStringCached2 = engfunc(EngFunc_AllocString, "info_target")))
			{
				iEntity = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached2);
			}
			
			if (pev_valid(iEntity))
			{	
				SET_MODEL(iEntity, MODEL_KRAKEN);
				SET_ORIGIN(iEntity, vOrigin);
		
				set_pev(iEntity, pev_classname, KRAKEN_CLASSNAME);
				set_pev(iEntity, pev_movetype, MOVETYPE_TOSS);
				set_pev(iEntity, pev_solid, SOLID_TRIGGER);
				set_pev(iEntity, pev_mins, Float:{-1.0, -1.0, -1.0});
				set_pev(iEntity, pev_maxs, Float:{1.0, 1.0, 1.0});
				set_pev(iEntity, pev_owner, iAttacker);
				set_pev(iEntity, pev_framerate, 0.5);
				set_pev(iEntity, pev_sequence, 0);
				set_pev(iEntity, pev_animtime, get_gametime());
				set_pev(iEntity, pev_iuser1, 1);
				set_pev(iEntity, pev_nextthink, get_gametime() + 2.0);
			}
			
			engfunc(EngFunc_EmitSound, iEnt, CHAN_WEAPON, SOUND_EXPLODE, 0.9, ATTN_NORM, 0, PITCH_NORM);
		}
	
		set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME);
	}
	else if (equal(iClassname, KRAKEN_CLASSNAME))
	{
		if (is_user_alive(iOther) && is_user_zombie(iOther) && pev(iEnt, pev_iuser1))
		{
			static Float:iVelocity[3];iVelocity[2] = WEAPON_KRAKEN_KNOCKBACK;

			ExecuteHamB(Ham_TakeDamage, iOther, iEnt, iAttacker, WEAPONN_KRAKEN_DAMAGE, DMG_SONIC);
			
			set_pdata_float(iOther, m_flVelocityModifier, 1.0,  extra_offset_player);
			
			set_pev(iOther, pev_velocity, iVelocity);
			
			set_pev(iEnt, pev_iuser1, 0);
		}
	}
	
	return FMRES_IGNORED;
}

public FakeMeta_Think(const iEntity)
{
	if (!pev_valid(iEntity))
	{
		return FMRES_IGNORED;
	}
	
	static Classname[32];pev(iEntity, pev_classname, Classname, sizeof(Classname));

	if (!equal(Classname, KRAKEN_CLASSNAME))
	{
		return FMRES_IGNORED;
	}
	
	set_pev(iEntity, pev_flags, pev(iEntity, pev_flags) | FL_KILLME);
	
	return FMRES_IGNORED;
}

//**********************************************
//* Block client weapon.                       *
//**********************************************

public FakeMeta_UpdateClientData_Post(const iPlayer, const iSendWeapons, const CD_Handle)
{
	static iActiveItem;iActiveItem = get_pdata_cbase(iPlayer, m_pActiveItem, extra_offset_player);
	
	if (!IsValidPev(iActiveItem) || !IsCustomItem(iActiveItem))
	{
		return FMRES_IGNORED;
	}

	set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 0.001);
	return FMRES_IGNORED;
}

//**********************************************
//* Item (weapon) hooks.                       *
//**********************************************

	#define _call.%0(%1,%2) \
									\
	Weapon_On%0							\
	(								\
		%1, 							\
		%2,							\
									\
		get_pdata_int(%1, m_iClip, extra_offset_weapon),	\
		GetAmmoInventory(%2, PrimaryAmmoIndex(%1))		\
	) 

public HamHook_Item_Deploy_Post(const iItem)
{
	new iPlayer; 
	
	if (!CheckItem(iItem, iPlayer))
	{
		return HAM_IGNORED;
	}
	
	_call.Deploy(iItem, iPlayer);
	return HAM_IGNORED;
}

public HamHook_Item_Holster(const iItem)
{
	new iPlayer; 
	
	if (!CheckItem(iItem, iPlayer))
	{
		return HAM_IGNORED;
	}
	
	set_pev(iPlayer, pev_viewmodel, 0);
	set_pev(iPlayer, pev_weaponmodel, 0);
	
	_call.Holster(iItem, iPlayer);
	return HAM_SUPERCEDE;
}

public HamHook_Item_WeaponIdle(const iItem)
{
	static iPlayer; 
	
	if (!CheckItem(iItem, iPlayer))
	{
		return HAM_IGNORED;
	}

	_call.Idle(iItem, iPlayer);
	return HAM_SUPERCEDE;
}

public HamHook_Item_Reload(const iItem)
{
	static iPlayer; 
	
	if (!CheckItem(iItem, iPlayer))
	{
		return HAM_IGNORED;
	}
	
	_call.Reload(iItem, iPlayer);
	return HAM_SUPERCEDE;
}

public HamHook_Item_PrimaryAttack(const iItem)
{
	static iPlayer; 
	
	if (!CheckItem(iItem, iPlayer))
	{
		return HAM_IGNORED;
	}
	
	_call.PrimaryAttack(iItem, iPlayer);
	return HAM_SUPERCEDE;
}

public HamHook_Item_PostFrame(const iItem)
{
	static iPlayer;
	
	if (!CheckItem(iItem, iPlayer))
	{
		return HAM_IGNORED;
	}

	if (get_pdata_int(iItem, m_fInReload, extra_offset_weapon))
	{
		new iClip		= get_pdata_int(iItem, m_iClip, extra_offset_weapon); 
		new iPrimaryAmmoIndex	= PrimaryAmmoIndex(iItem);
		new iAmmoPrimary	= GetAmmoInventory(iPlayer, iPrimaryAmmoIndex);
		new iAmount		= min(WEAPON_MAX_CLIP - iClip, iAmmoPrimary);
		
		set_pdata_int(iItem, m_iClip, iClip + iAmount, extra_offset_weapon);
		set_pdata_int(iItem, m_fInReload, false, extra_offset_weapon);

		SetAmmoInventory(iPlayer, iPrimaryAmmoIndex, iAmmoPrimary - iAmount);
	}

	return HAM_IGNORED;
}	

//**********************************************
//* Fire Bullets.                              *
//**********************************************

CallOrigFireBullets3(const iItem, const iPlayer)
{
	static fm_hooktrace;fm_hooktrace=register_forward(FM_TraceLine,"FakeMeta_TraceLine",true)
	
	state FireBullets: Enabled;
	static Float: vecPuncheAngle[3];
	pev(iPlayer, pev_punchangle, vecPuncheAngle);
	ExecuteHam(Ham_Weapon_PrimaryAttack, iItem);
	set_pev(iPlayer, pev_punchangle, vecPuncheAngle);
	state FireBullets: Disabled;
	
	unregister_forward(FM_TraceLine,fm_hooktrace,true)
}

public FakeMeta_PlaybackEvent() <FireBullets: Enabled>
{
	return FMRES_SUPERCEDE;
}

public FakeMeta_TraceLine(Float:vecStart[3], Float:VecEnd[3], iFlags, Ignore, iTrase)// Chrescoe1
{
	if (iFlags & IGNORE_MONSTERS)
	{
		return FMRES_IGNORED;
	}
	
	static iHit;
	static Decal;
	static glassdecal;
	static Float:vecPlaneNormal[3];
	static Float:vecEndPos[3];
	
	iHit=get_tr2(iTrase,TR_pHit);
	
	if (!glassdecal)
	{
		glassdecal=engfunc( EngFunc_DecalIndex, "{bproof1" );
	}
	
	if(iHit>0 && pev_valid(iHit))
		if(pev(iHit,pev_solid)!=SOLID_BSP)return FMRES_IGNORED;
		else if(pev(iHit,pev_rendermode)!=0)Decal=glassdecal;
		else Decal=random_num(41,45);
	else Decal=random_num(41,45);
	
	get_tr2(iTrase, TR_vecEndPos, vecEndPos);
	get_tr2(iTrase, TR_vecPlaneNormal, vecPlaneNormal);
	
	MESSAGE_BEGIN(MSG_PAS, SVC_TEMPENTITY, vecEndPos, 0);
	WRITE_BYTE(TE_GUNSHOTDECAL);
	WRITE_COORD(vecEndPos[0]);
	WRITE_COORD(vecEndPos[1]);
	WRITE_COORD(vecEndPos[2]);
	WRITE_SHORT(iHit > 0 ? iHit : 0);
	WRITE_BYTE(Decal);
	MESSAGE_END();
	
	MESSAGE_BEGIN(MSG_PVS, SVC_TEMPENTITY, vecEndPos, 0);
	WRITE_BYTE(TE_STREAK_SPLASH)
	WRITE_COORD(vecEndPos[0]);
	WRITE_COORD(vecEndPos[1]);
	WRITE_COORD(vecEndPos[2]);
	WRITE_COORD(vecPlaneNormal[0] * random_float(20.0,30.0));
	WRITE_COORD(vecPlaneNormal[1] * random_float(20.0,30.0));
	WRITE_COORD(vecPlaneNormal[2] * random_float(20.0,30.0));
	WRITE_BYTE(198);	//Colorid
	WRITE_SHORT(10);	//Count
	WRITE_SHORT(3);		//Speed
	WRITE_SHORT(60);	//Random speed
	MESSAGE_END();

	return FMRES_IGNORED;
}

public HamHook_Entity_TraceAttack(const iEntity, const iAttacker, const Float: flDamage) <FireBullets: Enabled>
{
	static iItem;

	if (!BitCheck(g_bitIsConnected, iAttacker) || !IsValidPev(iAttacker))
	{
		return;
	}
	
	iItem = get_pdata_cbase(iAttacker, m_pActiveItem, extra_offset_player);
	
	if (!IsValidPev(iItem))
	{
		return;
	}
	
	SetHamParamFloat(3, flDamage * WEAPON_DAMAGE);
}

public MsgHook_Death()			</* Empty statement */>		{ /* Fallback */ }
public MsgHook_Death()			<FireBullets: Disabled>		{ /* Do notning */ }

public FakeMeta_PlaybackEvent() 	</* Empty statement */>		{ return FMRES_IGNORED; }
public FakeMeta_PlaybackEvent() 	<FireBullets: Disabled>		{ return FMRES_IGNORED; }

public HamHook_Entity_TraceAttack() 	</* Empty statement */>		{ /* Fallback */ }
public HamHook_Entity_TraceAttack() 	<FireBullets: Disabled>		{ /* Do notning */ }

Weapon_Create(const Float: vecOrigin[3] = {0.0, 0.0, 0.0}, const Float: vecAngles[3] = {0.0, 0.0, 0.0})
{
	new iWeapon;

	static iszAllocStringCached;
	if (iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, WEAPON_REFERANCE)))
	{
		iWeapon = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached);
	}
	
	if (!IsValidPev(iWeapon))
	{
		return FM_NULLENT;
	}
	
	MDLL_Spawn(iWeapon);
	SET_ORIGIN(iWeapon, vecOrigin);
	
	set_pdata_int(iWeapon, m_iClip, WEAPON_MAX_CLIP, extra_offset_weapon);
		
	set_pev(iWeapon, pev_impulse, WEAPON_KEY);
	set_pev(iWeapon, pev_angles, vecAngles);
	
	Weapon_OnSpawn(iWeapon);
	
	return iWeapon;
}

Weapon_Give(const iPlayer)
{
	if (!IsValidPev(iPlayer))
	{
		return FM_NULLENT;
	}
	
	new iWeapon, Float: vecOrigin[3];
	pev(iPlayer, pev_origin, vecOrigin);
	
	if ((iWeapon = Weapon_Create(vecOrigin)) != FM_NULLENT)
	{
		Player_DropWeapons(iPlayer, ExecuteHamB(Ham_Item_ItemSlot, iWeapon));
		
		set_pev(iWeapon, pev_spawnflags, pev(iWeapon, pev_spawnflags) | SF_NORESPAWN);
		MDLL_Touch(iWeapon, iPlayer);
		
		iTimeSkill[iPlayer] = 0.0;
		iUseSkill[iPlayer] = false;
		
		SetAmmoInventory(iPlayer, PrimaryAmmoIndex(iWeapon), WEAPON_DEFAULT_AMMO);
		
		return iWeapon;
	}
	
	return FM_NULLENT;
}

Player_DropWeapons(const iPlayer, const iSlot)
{
	new szWeaponName[32], iItem = get_pdata_cbase(iPlayer, m_rgpPlayerItems_CBasePlayer + iSlot, extra_offset_player);

	while (IsValidPev(iItem))
	{
		pev(iItem, pev_classname, szWeaponName, charsmax(szWeaponName));
		engclient_cmd(iPlayer, "drop", szWeaponName);

		iItem = get_pdata_cbase(iItem, m_pNext, extra_offset_weapon);
	}
}

Weapon_SendAnim(const iPlayer, const iAnim)
{
	set_pev(iPlayer, pev_weaponanim, iAnim);

	MESSAGE_BEGIN(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0.0, 0.0, 0.0}, iPlayer);
	WRITE_BYTE(iAnim);
	WRITE_BYTE(0);
	MESSAGE_END();
}

stock Sprite_SetTransparency(const iSprite, const iRendermode, const Float: vecColor[3], const Float: flAmt, const iFx = kRenderFxNone)
{
	set_pev(iSprite, pev_rendermode, iRendermode);
	set_pev(iSprite, pev_rendercolor, vecColor);
	set_pev(iSprite, pev_renderamt, flAmt);
	set_pev(iSprite, pev_renderfx, iFx);
}

stock Weapon_DefaultDeploy(const iPlayer, const szViewModel[], const szWeaponModel[], const iAnim, const szAnimExt[])
{
	set_pev(iPlayer, pev_viewmodel2, szViewModel);
	set_pev(iPlayer, pev_weaponmodel2, szWeaponModel);
	set_pev(iPlayer, pev_fov, 90.0);
	
	set_pdata_int(iPlayer, m_iFOV, 90, extra_offset_player);
	set_pdata_int(iPlayer, m_fResumeZoom, 0, extra_offset_player);
	set_pdata_int(iPlayer, m_iLastZoom, 90, extra_offset_player);
	
	set_pdata_string(iPlayer, m_szAnimExtention * 4, szAnimExt, -1, extra_offset_player * 4);
	
	Weapon_SendAnim(iPlayer, iAnim);
}

stock Punchangle(iPlayer, Float:iVecx = 0.0, Float:iVecy = 0.0, Float:iVecz = 0.0)
{
	static Float:iVec[3];pev(iPlayer, pev_punchangle,iVec);
	iVec[0] = iVecx;iVec[1] = iVecy;iVec[2] = iVecz
	set_pev(iPlayer, pev_punchangle, iVec);
}

stock GetWeaponPosition(const iPlayer, Float: forw, Float: right, Float: up, Float: vStart[])
{
	new Float: vOrigin[3], Float: vAngle[3], Float: vForward[3], Float: vRight[3], Float: vUp[3];
	
	pev(iPlayer, pev_origin, vOrigin);
	pev(iPlayer, pev_view_ofs, vUp);
	xs_vec_add(vOrigin, vUp, vOrigin);
	pev(iPlayer, pev_v_angle, vAngle);
	
	angle_vector(vAngle, ANGLEVECTOR_FORWARD, vForward);
	angle_vector(vAngle, ANGLEVECTOR_RIGHT, vRight);
	angle_vector(vAngle, ANGLEVECTOR_UP, vUp);
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up;
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up;
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up;
}

public client_putinserver(id)
{
	BitSet(g_bitIsConnected, id);
	
	iTimeSkill[id] = 0.0;
	iUseSkill[id] = false;
}

public client_disconnected(id)
{
	BitClear(g_bitIsConnected, id);
	
	iTimeSkill[id] = 0.0;
	iUseSkill[id] = false;
}

//**********************************************
//* Weapon list update.                        *
//**********************************************

public Cmd_WeaponSelect(const iPlayer)
{
	engclient_cmd(iPlayer, WEAPON_REFERANCE);
	return PLUGIN_HANDLED;
}

public HamHook_Item_AddToPlayer(const iItem, const iPlayer)
{
	switch(pev(iItem, pev_impulse))
	{
		case 0: 
		{
			MsgHook_WeaponList(iItem, iPlayer);
		}
		case WEAPON_KEY: 
		{
			MsgHook_WeaponList(iItem, iPlayer);
			SetAmmoInventory(iPlayer, PrimaryAmmoIndex(iItem), pev(iItem, pev_iuser2));
		}
	}
	
	return HAM_IGNORED;
}

public MsgHook_WeaponList(const iItem, const iPlayer)
{
	/*1   STRN  -  WeaponName
	2   BYTE  -  PrimaryAmmoID
	3   BYTE  -  PrimaryAmmoMaxAmount
	4   BYTE  -  SecondaryAmmoID
	5   BYTE  -  SecondaryAmmoMaxAmount
	6   BYTE  -  SlotID (0...N)
	7   BYTE  -  NumberInSlot (1...N)
	8   BYTE  -  WeaponID
	9   BYTE  -  Flags:   ITEM_FLAG_SELECTONEMPTY       1    (1<<0)
			ITEM_FLAG_NOAUTORELOAD        2    (1<<1)
			ITEM_FLAG_NOAUTOSWITCHEMPTY   4    (1<<2)
			ITEM_FLAG_LIMITINWORLD        8    (1<<3)
			ITEM_FLAG_EXHAUSTIBLE         16   (1<<4)   A player can totally exhaust their ammo supply and lose this weapon*/
	
	MESSAGE_BEGIN(MSG_ONE, get_user_msgid("WeaponList"), {0.0,0.0,0.0}, iPlayer);
	WRITE_STRING(IsCustomItem(iItem) ? WEAPON_NAME : WEAPON_REFERANCE);
	WRITE_BYTE(1);
	WRITE_BYTE(30);
	WRITE_BYTE(-1);
	WRITE_BYTE(-1);
	WRITE_BYTE(0);
	WRITE_BYTE(2);
	WRITE_BYTE(18);
	WRITE_BYTE(0);
	MESSAGE_END();
}

//**********************************************
//* Weaponbox world model.                     *
//**********************************************

public HamHook_Weaponbox_Spawn_Post(const iWeaponBox)
{
	if (IsValidPev(iWeaponBox))
	{
		state (IsValidPev(pev(iWeaponBox, pev_owner))) WeaponBox: Enabled;
	}
	
	return HAM_IGNORED;
}

public FakeMeta_SetModel(const iEntity) <WeaponBox: Enabled>
{
	state WeaponBox: Disabled;
	
	if (!IsValidPev(iEntity))
	{
		return FMRES_IGNORED;
	}
	
	#define MAX_ITEM_TYPES	6
	
	for (new i, iItem; i < MAX_ITEM_TYPES; i++)
	{
		iItem = get_pdata_cbase(iEntity, m_rgpPlayerItems_CWeaponBox + i, extra_offset_weapon);
		
		if (IsValidPev(iItem) && IsCustomItem(iItem))
		{
			SET_MODEL(iEntity, MODEL_WORLD);	
			set_pev(iItem, pev_iuser2, GetAmmoInventory(pev(iEntity,pev_owner), PrimaryAmmoIndex(iItem)))
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED;
}

public FakeMeta_SetModel()	</* Empty statement */>	{ /*  Fallback  */ return FMRES_IGNORED; }
public FakeMeta_SetModel() 	< WeaponBox: Disabled >	{ /* Do nothing */ return FMRES_IGNORED; }

//**********************************************
//* Ammo Inventory.                            *
//**********************************************

PrimaryAmmoIndex(const iItem)
{
	return get_pdata_int(iItem, m_iPrimaryAmmoType, extra_offset_weapon);
}

GetAmmoInventory(const iPlayer, const iAmmoIndex)
{
	if (iAmmoIndex == -1)
	{
		return -1;
	}

	return get_pdata_int(iPlayer, m_rgAmmo_CBasePlayer + iAmmoIndex, extra_offset_player);
}

SetAmmoInventory(const iPlayer, const iAmmoIndex, const iAmount)
{
	if (iAmmoIndex == -1)
	{
		return 0;
	}

	set_pdata_int(iPlayer, m_rgAmmo_CBasePlayer + iAmmoIndex, iAmount, extra_offset_player);
	return 1;
}

bool: CheckItem(const iItem, &iPlayer)
{
	if (!IsValidPev(iItem) || !IsCustomItem(iItem))
	{
		return false;
	}
	
	iPlayer = get_pdata_cbase(iItem, m_pPlayer, extra_offset_weapon);
	
	if (!IsValidPev(iPlayer) || !BitCheck(g_bitIsConnected, iPlayer))
	{
		return false;
	}
	
	return true;
}

stock bool: CheckItem2(const iPlayer, &iItem)
{
	if (!BitCheck(g_bitIsConnected, iPlayer) || !IsValidPev(iPlayer) || zp_get_user_zombie(iPlayer) || get_user_weapon(iPlayer) != CSW_KNIFE)
	{
		return false;
	}
	
	iItem = get_pdata_cbase(iPlayer, m_pActiveItem, extra_offset_player);
	
	if (!IsValidPev(iItem))
	{
		return false;
	}
	
	return true;
}

stock GetPosition(id,Float:forw, Float:right, Float:up, Float:vStart[]) 
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3];
	
	pev(id, pev_origin, vOrigin);
	pev(id, pev_view_ofs, vUp);
	
	xs_vec_add(vOrigin, vUp, vOrigin);
	
	pev(id, pev_v_angle, vAngle);
	
	angle_vector(vAngle, ANGLEVECTOR_FORWARD, vForward);
	angle_vector(vAngle, ANGLEVECTOR_RIGHT, vRight);
	angle_vector(vAngle, ANGLEVECTOR_UP, vUp);
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up;
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up;
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up;
}

stock GetSpeedVector(Float:origin1[3], Float:origin2[3], Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num
}

PRECACHE_SOUNDS_FROM_MODEL(const szModelPath[])
{
	new iFile;
	
	if ((iFile = fopen(szModelPath, "rt")))
	{
		new szSoundPath[64];
		
		new iNumSeq, iSeqIndex;
		new iEvent, iNumEvents, iEventIndex;
		
		fseek(iFile, 164, SEEK_SET);
		fread(iFile, iNumSeq, BLOCK_INT);
		fread(iFile, iSeqIndex, BLOCK_INT);
		
		for (new k, i = 0; i < iNumSeq; i++)
		{
			fseek(iFile, iSeqIndex + 48 + 176 * i, SEEK_SET);
			fread(iFile, iNumEvents, BLOCK_INT);
			fread(iFile, iEventIndex, BLOCK_INT);
			fseek(iFile, iEventIndex + 176 * i, SEEK_SET);

			for (k = 0; k < iNumEvents; k++)
			{
				fseek(iFile, iEventIndex + 4 + 76 * k, SEEK_SET);
				fread(iFile, iEvent, BLOCK_INT);
				fseek(iFile, 4, SEEK_CUR);
				
				if (iEvent != 5004)
				{
					continue;
				}

				fread_blocks(iFile, szSoundPath, 64, BLOCK_CHAR);
				
				if (strlen(szSoundPath))
				{
					strtolower(szSoundPath);
					PRECACHE_SOUND(szSoundPath);
				}
			}
		}
	}
	
	fclose(iFile);
}
