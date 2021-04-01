/* Sublime AMXX Editor v3.2 */

#include <amxmodx>
#include <reapi>
new const iKillSounds[][] = {
	"","killsound/prepare.wav","killsound/multikill.wav","killsound/megakill.wav","killsound/ultrakill.wav","killsound/holyshit.wav",
	"killsound/killingspree.wav","killsound/ludacrisskill.wav","killsound/rampage.wav","killsound/wickedsick.wav","killsound/godlike.wav"
}
new const iKnifeSound[] = "killsound/humiliation.wav";
new const iHeadShotSound[] = "killsound/headshot.wav";
new iTopla[MAX_PLAYERS+1];
public plugin_preacache() {
	for(new i=1; i < sizeof(iKillSounds);i++ )
		precache_sound(iKillSounds[i]);
	precache_sound(iKnifeSound);
	precache_sound(iHeadShotSound);
}
public plugin_init() {
	register_plugin("Kill Sounds", "1.0", "PawNod'")

	RegisterHookChain(RG_CBasePlayer_Killed, "@pKilled", .post = true);
	RegisterHookChain(RG_CBasePlayer_Spawn, "@pSpawn", .post = true);
}
public client_disconnected(iPlayer) iTopla[iPlayer] = 0;
@pSpawn(const iPlayer) 
	iTopla[iPlayer] = 0;
@pKilled(const pVictim,const pAttacker, const iGib) {
	new bool:blHeadShot = bool:(get_member(pVictim, m_LastHitGroup) == HIT_HEAD);
	iTopla[pAttacker]++;
	iTopla[pVictim] = 0;
	if(iTopla[pAttacker] > 0){
		if(get_user_weapon(pAttacker) == CSW_KNIFE) {
			rg_send_audio(pAttacker,iKnifeSound);
			return;
		}
		blHeadShot ? rg_send_audio(pAttacker,iHeadShotSound):rg_send_audio(pAttacker,
		iTopla[pAttacker] <= sizeof(iKillSounds)-1 ? iKillSounds[iTopla[pAttacker]]:iKillSounds[sizeof(iKillSounds)-1]);
	}
}