/* Sublime AMXX Editor v2.2 */

#include <amxmodx>
native API_MenuTag(iL_Copy[],iL_Len);
native API_MenuKisaTag(iL_Copy[],iL_Len);
new MenuTag[48],MenuKisaTag[48];

public plugin_init() {
	register_plugin("PLUGIN", "VERSION", "AUTHOR")
	API_MenuTag(MenuTag,charsmax(MenuTag));
	API_MenuTag(MenuKisaTag,charsmax(MenuKisaTag));
}
public pMenuOrnegi(iP_ID) {
	static Item[128];
	formatex(Item, charsmax(Item),"Deneme Menusu");
	new Menu = menu_create(Item, "pMenuOrnegi_");
	formatex(Item, charsmax(Item), "%s %s",MenuTag,MenuKisaTag);
	menu_additem(Menu, Item, "1");	
	menu_setprop(Menu ,MPROP_EXITNAME,"\wKapat");
	menu_display(iP_ID, Menu);
}
public pMenuOrnegi_(iP_ID, menu, item) {
	if( item == MENU_EXIT ) { menu_destroy(menu);return PLUGIN_HANDLED;}
	new data[6], iName[64], access, callback;
	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback);
	menu_destroy(menu);return PLUGIN_HANDLED;
}