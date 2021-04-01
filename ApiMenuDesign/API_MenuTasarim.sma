/* Sublime AMXX Editor v3.2 */

#include <amxmodx>
#include <nvault>
new const ADMIN_YETKI = ADMIN_IMMUNITY
#define MAX_LEN 48
new const sG_Tags[][] = {
	//Uzun Tag - Kısa Tag
	"WebAilesi","wA"
}
new const sG_Design[][][] = {
	{"\d[ \r- \w{TAG} \r- \d] \d-\w","\d[ \r- \w{TAG} \r- \d] \d-\w","Theme 1"},
	{"\y( \d~ \r{TAG} \d~ \y) \d~\w","\y( \d~ \r{TAG} \d~ \y) \d~\w","Theme 2"},
	{"\w(\d{TAG}\w) \d//\w","\w(\d{TAG}\w) \d//\w","Theme 3"},
	{"\r| \y* \w{TAG} \y* \r| \d`\w","\r| \y* \w{TAG} \y* \r| \d`\w","Theme 4"},
	{"\w<\r#\w> \y{TAG} \w<\r#\w>  \d|\w ","\r#\w> \y{TAG} \w<\r# \d|\w","Theme 5"},
	{"\r[ \w,' \y{TAG} \w', \r] \d>\w","\r[ \w,'\y {TAG} \w', \r] \d>\w","Theme 6"}
};
new iG_Vault,iL_MenuTag[MAX_LEN],iL_MenuKisaTag[MAX_LEN],iL_MenuID;
public plugin_init() {
	register_plugin(
	"Herhangi Bir Plugin",
	"1.0b",
	"PawNod'")

	register_clcmd("amx_design","pMenuDesign");
}
public plugin_natives() {
	register_native("API_MenuTag","NTV_MenuTag");
	register_native("API_MenuKisaTag","NTV_MenuKisaTag");
}
public NTV_MenuTag() {
	new iL_Len = get_param(2),iL_Duzelt[MAX_LEN]; 
	formatex(iL_Duzelt,charsmax(iL_Duzelt),sG_Design[iL_MenuID][1][0]);
	replace(iL_Duzelt,charsmax(iL_Duzelt),"{TAG}",sG_Tags[0][0]);
	set_string(1, iL_Duzelt , iL_Len);
}
public NTV_MenuKisaTag() {
	new iL_Len = get_param(2), iL_Duzelt[MAX_LEN]; 
	formatex(iL_Duzelt,charsmax(iL_Duzelt),sG_Design[iL_MenuID][0][0]);
	replace(iL_Duzelt,charsmax(iL_Duzelt),"{TAG}",sG_Tags[1][0]);
	set_string(1, iL_Duzelt , iL_Len);
}
public plugin_cfg() { iG_Vault = nvault_open("menuDesign"); }
public pMenuDesign(iP_ID) {
	if(get_user_flags(iP_ID) & ADMIN_YETKI) {
		static Item[128],NTS[6],pShowing[MAX_LEN];
		formatex(Item, charsmax(Item),"Menu Tasarimi Degistirme^nAPI By: \dPawNod'");new Menu = menu_create(Item, "pMenuDesign_");
		for(new i = 0; i < sizeof(sG_Design); i++) {
			formatex(pShowing,charsmax(pShowing),sG_Design[i][1][0]);
			replace(pShowing,charsmax(pShowing),"{TAG}",sG_Tags[1][0]);
			num_to_str(i, NTS, 5);
			formatex(Item, charsmax(Item), "%s %s",pShowing ,sG_Design[i][2]);menu_additem(Menu, Item, NTS);
		}		
		formatex(Item, charsmax(Item), "\wKapat");
		menu_setprop(Menu ,MPROP_EXITNAME,Item);menu_display(iP_ID, Menu);
	}
	return PLUGIN_HANDLED;
}
public pMenuDesign_(iP_ID, menu, item) {
	if( item == MENU_EXIT ) { menu_destroy(menu);return PLUGIN_HANDLED;}
	new data[6], iName[64], access, callback;
	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback);
	new key = str_to_num(data);
	pLastChange(iP_ID,key);
	pMenuDesign(iP_ID);
	menu_destroy(menu);return PLUGIN_HANDLED;
}
public pLastChange(iP_ID,iL_ID) {
	new Name[33]; get_user_name(iP_ID,Name,32);
	iL_MenuID = iL_ID;
	formatex(iL_MenuTag,charsmax(iL_MenuTag),sG_Design[iL_ID][1][0]);
	formatex(iL_MenuKisaTag,charsmax(iL_MenuKisaTag),sG_Design[iL_ID][0][0]);
	replace(iL_MenuTag,charsmax(iL_MenuTag),"{TAG}",sG_Tags[0][0]);
	replace(iL_MenuKisaTag,charsmax(iL_MenuKisaTag),"{TAG}",sG_Tags[1][0]);
	pSaveD();
	client_print(0,print_chat,"Menu Tasarimi %s Olarak Degistirildi!",sG_Design[iL_ID][2]);
	log_amx("%s Adli Admin Menu Tasarimini %s Olarak Degistirdi!",Name,sG_Design[iL_ID][2]);
}
stock pThemeChange(iP_ID,ThemeID) {
	formatex(iL_MenuTag,charsmax(iL_MenuTag),sG_Design[ThemeID][1]);
	formatex(iL_MenuKisaTag,charsmax(iL_MenuKisaTag),sG_Design[ThemeID][0]);
	pSaveD();pDesignMenu(id);
	client_print(0,print_chat,"Menu Tasarimi %s Olarak Degistirildi!",sG_Design[ThemeID][2]);
	log_amx("%s Adli Kisi Menu Tasarimini %s Olarak Degistirdi!",Name,sG_Design[ThemeID][2]);
}
public pSaveD(){
	new pKey[64], pData[256];
	formatex(pKey, charsmax(pKey), "menuDesign");
	formatex(pData, charsmax(pData), "%d#",iL_MenuID); nvault_set(iG_Vault, pKey, pData);
}
public pLoadD(){ 
	new pKey[64], pData[256],pA[32];
	formatex(pKey, charsmax(pKey), "menuDesign");
	formatex(pData, charsmax(pData), "%d#",iL_MenuID);nvault_get(iG_Vault, pKey, pData, 255);
	replace_all(pData, 255, "#", " "); parse(pData, pA, 31);iL_MenuID = str_to_num(pA);
}