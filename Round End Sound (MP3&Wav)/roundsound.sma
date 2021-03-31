#include <amxmodx>
#define check_wav(%1)  equali( %1[strlen( %1 ) - 4 ], ".wav" )
new const pMuzikler[][][] = {
    {"sound/te_win2.mp3","T"},
    {"sound/te_win1.mp3","T"},
    {"sound/twinnar3.wav","T"},
    {"sound/twinnar2.wav","T"},
    {"sound/ct_win5.mp3","CT"},
    {"sound/ctwinnar.wav","CT"},
    {"sound/ctwinnar2.wav","CT"}
};
public plugin_precache() {
    for(new i; i < sizeof(pMuzikler);i++) 
        pPrecacheFiles(pMuzikler[i][0][0]);
}
public plugin_init() {
    register_plugin("El Sonu Muzik MP3&Waw","1.0","PawNod'")
    register_event("SendAudio","pT_Win","a","2&%!MRAD_terwin");
    register_event("SendAudio","pCT_Win","a","2&%!MRAD_ctwin");
}
public pT_Win() {pPlaySound("T");}
public pCT_Win() {pPlaySound("CT");}
stock pPlaySound(const pTeam[]){
    new pSes = random_num(0,sizeof(pMuzikler)-1)
    while(!equali(pTeam,pMuzikler[pSes][1][0])){
        pSes = random_num(0,sizeof(pMuzikler)-1)
    }
    new pMax[128];
    formatex(pMax,charsmax(pMax),"%s",pMuzikler[pSes][0][0])
    check_wav(pMax) ? formatex(pMax,charsmax(pMax),"spk %s",pMuzikler[pSes][0][6]):
    formatex(pMax,charsmax(pMax),"mp3 play %s",pMuzikler[pSes][0][0]);
    client_cmd(0,"%s",pMax);
}
stock pPrecacheFiles(const sound[]) {
    check_wav(sound) ? 
    precache_sound(sound[6]):
    precache_generic(sound);
}