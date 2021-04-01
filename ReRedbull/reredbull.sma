/* Sublime AMXX Editor v3.2 */

#include <amxmodx>
#include <reapi>
new const sTag[] = "Github";
enum _: CvarSet {
	RSpeed,
	RCost,
	REffect,
	RHealth,
	RUpHealth,
	Float:RGravity,
	RHak
}
new iCvars[CvarSet],bool:iStop[MAX_PLAYERS+1],iHakSay[MAX_PLAYERS+1];
public plugin_init() {
	register_plugin("ReRedbull", "1.3", "PawNod'");

	register_clcmd("say /redbull","@UseRedbull");
	register_clcmd("say .redbull","@UseRedbull");
	register_clcmd("say_team /redbull","@UseRedbull");
	register_clcmd("radio1", "@UseRedbull");

	bind_pcvar_num(create_cvar("Redbull_Fiyat","-1"), iCvars[RCost]);
	bind_pcvar_num(create_cvar("Redbull_Etki_Suresi","20"), iCvars[REffect]);
	bind_pcvar_num(create_cvar("Redbull_Can_Yenileme","1"), iCvars[RUpHealth]);
	bind_pcvar_num(create_cvar("Redbull_Maximum_Can","200"), iCvars[RHealth]);
	bind_pcvar_num(create_cvar("Redbull_Hiz","400"), iCvars[RSpeed]);
	bind_pcvar_num(create_cvar("Redbull_Kullanma_Hakki","0"), iCvars[RHak]);
	bind_pcvar_float(create_cvar("Redbull_Gravity","0.5"), iCvars[RGravity]);

	RegisterHookChain(RG_CSGameRules_RestartRound, "@RoundRestart", .post = false);
	RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed,"@ResetMaxSpeed",.post = false);
	RegisterHookChain(RG_CBasePlayer_Killed, "@PlayerKilled", .post = true);
}
public client_disconected(iPlayer) {
	iStop[iPlayer] = false;
	iHakSay[iPlayer] = false;
}
@PlayerKilled(const iVictm, const iAttacker) {
	if(iStop[iVictm]) @FinishRedbull(iVictm+888957);
	new iNumT;
	rg_initialize_player_counts(iNumT);
	if(iNumT <= 1) {
		for(new iOT = 1; iOT <= MaxClients; iOT++) {
			if(is_user_connected(iOT) && is_user_alive(iOT)) {
				@FinishRedbull(iOT+888957);
			}
		}
	}
}
@RoundRestart() {
	for(new iEl = 1; iEl <= MaxClients; iEl++){
		if(is_user_connected(iEl) && iStop[iEl]) {
			@FinishRedbull(iEl+888957);
			iHakSay[iEl] = 0;
		}
	}
}
@UseRedbull(const iPlayer) {
	if(IsCanUse(iPlayer)) {
		rg_add_account(iPlayer, get_member(iPlayer, m_iAccount) - iCvars[RCost], AS_SET);
		iStop[iPlayer] = true;
		set_task(1.0,"@AddHealth",iPlayer+888956);
		set_entvar(iPlayer, var_maxspeed, float(iCvars[RSpeed]));
		set_entvar(iPlayer, var_gravity, iCvars[RGravity]);
		set_task(float(iCvars[REffect]),"@FinishRedbull",iPlayer+888957);
		set_task(float(iCvars[REffect])/2,"@RememberRedbull",iPlayer+888958);
		client_print_color(iPlayer,iPlayer,"^1[ ^3- ^4%s ^3- ^1] ^1Basarili bir sekilde redbull ^4aldiniz^1. Etkisi ^4(%0.0f Saniye) ^1sonra bitecek",sTag,float(iCvars[REffect]));
		iHakSay[iPlayer]++;
		if(iCvars[RHak] > 0) {
			client_print_color(iPlayer,iPlayer,"^1[ ^3- ^4%s ^3- ^1] ^1Kalan redbull kullanma hakkiniz: ^4(%i)",sTag,iCvars[RHak]-iHakSay[iPlayer]);
		}
	}
	return PLUGIN_HANDLED;
}
@FinishRedbull(const iTaskID) {
	new iPlayer = iTaskID - 888957;
	if(is_user_connected(iPlayer)) {
		iStop[iPlayer] = false;
		rg_reset_maxspeed(iPlayer);
		set_entvar(iPlayer, var_gravity, 1.0);
		remove_task(iPlayer+888957);
		remove_task(iPlayer+888958);
		remove_task(iPlayer+888956);
		client_print_color(iPlayer,iPlayer,"^1[ ^3- ^4%s ^3- ^1] ^1Redbull'unuz bitti tekrar alabilirsiniz.",sTag);
	}
}
@RememberRedbull(const iTaskID) {
	new iPlayer = iTaskID - 888958;
	if(is_user_connected(iPlayer)) {
		client_print_color(iPlayer,iPlayer,"^1[ ^3- ^4%s ^3- ^1] ^1Redbull'un bitmesine ^4(%0.1f Saniye) ^1kaldi!",sTag,float(iCvars[REffect])/2);
	}
}
@AddHealth(const iTaskID) {
	new iPlayer = iTaskID - 888956;
	if(is_user_connected(iPlayer) && get_entvar(iPlayer, var_health) < float(iCvars[RHealth]) && iStop[iPlayer]) {
		set_entvar(iPlayer, var_health, Float:get_entvar(iPlayer, var_health) + float(iCvars[RUpHealth]));
		set_task(1.0,"@AddHealth",iPlayer+888956);
	}
}
@ResetMaxSpeed(const iPlayer) {
	if(iStop[iPlayer]) {
		set_entvar(iPlayer, var_maxspeed,Float:float(iCvars[RSpeed]));
		return HC_SUPERCEDE;
	}
	return HC_CONTINUE;
}
bool:IsCanUse(const iPlayer) {
	new iNumT;
	rg_initialize_player_counts(iNumT);
	if(iStop[iPlayer]) {
		client_print_color(iPlayer,iPlayer,"^1[ ^3- ^4%s ^3- ^1] ^1Zaten redbull kullaniyorsunuz!",sTag);
		return false;
	}
	if(iNumT <= 1) {
		client_print_color(iPlayer,iPlayer,"^1[ ^3- ^4%s ^3- ^1] ^1Tek mahkum varken redbull kullanilamaz!",sTag);
		return false;
	}
	if(!is_user_alive(iPlayer)) {
		client_print_color(iPlayer,iPlayer,"^1[ ^3- ^4%s ^3- ^1] ^1Oluler redbull kullanamaz!",sTag);
		return false;
	}
	if(get_member(iPlayer, m_iAccount) < iCvars[RCost]) {
		client_print_color(iPlayer,iPlayer,"^1[ ^3- ^4%s ^3- ^1] ^1Paraniz yetersiz. Gereken: ^4(%d TL)",sTag,iCvars[RCost]);
		return false;
	}
	if(iCvars[RHak] > 0 && iHakSay[iPlayer] >= iCvars[RHak]) {
		client_print_color(iPlayer,iPlayer,"^1[ ^3- ^4%s ^3- ^1] ^1Redbull kullanma hakkiniz kalmadi.",sTag);
		return false;
	}
	return true;
}
