/* Sublime AMXX Editor v3.2 */

#include <amxmodx>
#include <reapi>
new const sTag[] = "GitHub";
new const sHats[][][] = { {"",""},
	{"Dede Sapkasi","models/hat/dede.mdl"},
	{"Suratsiz Sapkasi","models/hat/suratsiz.mdl"},
	{"Inek Sapkasi","models/hat/inek.mdl"},
	{"Palyaco Sapkasi","models/hat/palyanco.mdl"},
	{"Kedi Sapkasi","models/hat/Kedi.mdl"},
	{"Korku Sapkasi","models/hat/Korku.mdl"}
};
new iHatID[MAX_PLAYERS+1],iHatModels[sizeof(sHats)+1],iHatEnt[MAX_PLAYERS+1];
public plugin_precache() {
	for(new i=1; i < sizeof(sHats);i++) 
		iHatModels[i] = precache_model(sHats[i][1][0]);
}
public plugin_init() {
	register_plugin("Sapka Menü", "1.0", "PawNod'");

	register_clcmd("say /sapka","@OpenHatMenu");
	register_clcmd("say /hat","@OpenHatMenu");
}
@OpenHatMenu(const iPlayer) {
	new Menu = menu_create(fmt("\d( \r%s \d) \y~> Sapka Menüsü",sTag), "@OpenHatMenu_");
	menu_additem(Menu,fmt("\r[\y%s\r] \d~> \wSapkayi \rCikar^n",sTag),"333");
	for(new fMenu=1;fMenu<sizeof(sHats);fMenu++) 
		menu_additem(Menu,fmt("\r[\y%s\r] \d~> \w%s", sTag,sHats[fMenu][0][0]),fmt("%i",fMenu));
	menu_setprop(Menu, MPROP_BACKNAME,"Önceki Sayfa"),menu_setprop(Menu, MPROP_NEXTNAME,"Sonraki Sayfa"),menu_setprop(Menu, MPROP_EXITNAME,"\wKapat");
	menu_display(iPlayer, Menu);
}
@OpenHatMenu_(const iPlayer,const iMenu, const iItem) {
	if(iItem == MENU_EXIT) { menu_destroy(iMenu);return PLUGIN_HANDLED; }
	new iData[6], iKey;
	menu_item_getinfo(iMenu, iItem, _, iData, charsmax(iData));
	iKey = str_to_num(iData);
	if(iKey == 333) {
		@SetUserHat(iPlayer,0),iHatID[iPlayer] = 0;
		menu_destroy(iMenu);return PLUGIN_HANDLED;
	}
	@SetUserHat(iPlayer,0),iHatID[iPlayer] = iKey;@SetUserHat(iPlayer,iKey);
	menu_destroy(iMenu);return PLUGIN_HANDLED;
}
@SetUserHat(const iPlayer, const iHatNum) {
	switch(iHatNum) {
		case 0: {
			iHatEnt[iPlayer] > 0 ? rg_remove_entity(iHatEnt[iPlayer]):(iHatEnt[iPlayer] = 0);
		}
		default: {
			iHatEnt[iPlayer] = rg_create_entity("info_target");
			set_entvar(iHatEnt[iPlayer],var_movetype,MOVETYPE_FOLLOW);
			set_entvar(iHatEnt[iPlayer],var_aiment,iPlayer);
			set_entvar(iHatEnt[iPlayer],var_rendermode,kRenderNormal);
			set_entvar(iHatEnt[iPlayer],var_modelindex,iHatModels[iHatNum]);
		}
	}
}
rg_remove_entity(const iEnt){
	if(is_entity(iEnt))
		set_entvar(iEnt,var_flags,FL_KILLME);
}