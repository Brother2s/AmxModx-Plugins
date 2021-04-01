/* Sublime AMXX Editor v3.2 */

#include <amxmodx>
#include <reapi>
public plugin_init() {
	register_plugin("JailBreak Icin Oto Skor Sifirlayici", "1.0", "PawNod'")

	RegisterHookChain(RG_CBasePlayer_Spawn, "@pSpawn", .post = true);
}
@pSpawn(const iPlayer){
	set_entvar(iPlayer,var_frags,0.0);
	set_member(iPlayer,m_iDeaths,0);
	message_begin(MSG_ALL,85);
	write_byte(iPlayer);
	write_short(0);write_short(0);write_short(0);write_short(0);
	message_end();
	client_print_color(iPlayer,iPlayer, "^3Skorunuz ^4Otomatik ^3Sifirlanmistir.");
}