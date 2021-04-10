/* Sublime AMXX Editor v3.2 */

#include <amxmodx>
native remove_entity(iIndex);
native find_ent_by_model(iIndex, const szClass[], const szModel[]);
public plugin_init() {
	register_plugin("Yeni Eklenti", "1.0", "PawNod'");

	new sMapName[32];
	get_mapname(sMapName,charsmax(sMapName));
	if(!equali(sMapName,"de_inferno")) return;
	@RemoveLadder();
}
@RemoveLadder(){
	remove_entity(find_ent_by_model(-1, "func_wall","*15"));
	remove_entity(find_ent_by_model(-1, "func_ladder","*142"));
}