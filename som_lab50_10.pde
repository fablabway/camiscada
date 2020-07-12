/*
	fablabway.com
	file: som_lab50_10.pde
	project: lab50 - SCADA with Processing
	description: SCADA for Processing. Multi-net 
	author: Mauro Rossolato
	licence: Creative Commons BY-NC-ND
 when 		who 	what
 -----------------------------------
 16.04.2019 mr 		creates
 24.04.2019 mr 		implements ini file
 24.04.2019 mr 		rect() for label (for mousePressed)
 24.04.2019 mr 		try/catch for serial
 19.05.2019 mr 		green label for pump, valve and valveq
 23.05.2019 mr 		mvalve+mvalveq, subst variable "size"
 23.04.2019 mr 		nella versione 05 di questo, eliminare mloadcfg_old
 23.05.2019 mr 		added msetcolor function
 23.05.2019 mr 		moved functions show and info from setup to draw
 23.05.2019 mr 		setup(): increase array objects
 23.05.2019 mr 		substitution attributes for color to msetcolor
 23.05.2019 mr 		new global var for textsize (now is 18)
 06.06.2019 mr 		added connector on top of tank
 23.05.2019 mr 		added filler to mpipe (modified color) 
 08.08.2019 mr 		savelog dual mode: % and elapsed
 13.08.2019 ft 		library  
 14.08.2019 mr 		add wheaterndx and wcoolerndx
*/

/*
HOW TO ADD A NEW OBJECT
1. 		create new class (copy from mtank e.g.)
1.1 	create global var, e.g. int w[pump]ndx =0;
1.2		add declaration // objects , e.g. MTANK[] mtank;
1.3		add constructor into void setup(), e.g. mvalve =new MVALVE[20];
1.4		add into draw() paragraph like  for (int i = 0; i < wvalvendx; i++) {
1.5 	add into mloadcfg
1.6		add into mgetobjidx



*/ 
 
/*
todo list
 08.07.2019 MR p1b1d1m1c1;CAP=30, dimensioni di riempimento. appare solo una linea.
 funzioni mfiller() convergono su mshow()
 23.05.2019 mr completare mtimer con lancetta che gira su sfondo verde. quando termina diventa rosso
 23.05.2019 mr abilitare lettura seriale (?)
 6.6.2019 mr lettura/scrittura dati da rete
 23.05.2019 mr creare funzione per aggiornamento attributi da valori seriale (?)
  7.6.2019 mr immagine di punto esclamativo per allarme/eccezione ricevuta da plc
 10.6.2019 mr legge/scrive da rs-485 modbus
 
 https://github.com/processing/processing/wiki/Library-Guidelines
 */



// import
import processing.serial.*;
import processing.net.*; 
//import java.io.FileWriter;

import java.io.BufferedWriter;
import java.io.FileWriter;


import java.io.IOException;
// import java.io.PrintWriter;



// global vars
short wportndx = 0;
String wstrser="";
int wlinefeed = 10;
int wusbavail = 1;
int wtankndx = 0;                  // objects counter
int wpipendx = 0;                  // objects counter
int wvalvendx = 0;                  // objects counter
int wheaterndx = 0;                  // objects counter
int wcoolerndx = 0;                  // objects counter
int wextrundx = 0;					// objects counter
int wlogndx = 0;                	// not implemented yet
int wpumpndx =0;                    // objects counter
int wvalvqndx = 0;                  // objects counter
int wsizetxt = 16;                  // text size
float wsqrtwo = 1.414213562373095;  // sqrt(2)
int wlogcnt = 200;                  // logfile mxsize (rows)
int wmaxdelaylog = 60000;


// objects
MRUNDEMO mrundemo;
Serial wport;
MTANK[] mtank;
MPIPE[] mpipe;
MVALVE[] mvalve;
MVALVQ[] mvalvq;
MPUMP[] mpump;
MCOOLER[] mcooler;
MHEATER[] mheater;
MEXTRUDER[] mextruder;
MTARGA mtarga;
Server mserv; 
Client mclie;
PImage photo;
FileWriter output = null;
MBUFLOG mbuflog;
Server mserver;        // used by IP()


//-----------------------------------------------------
// EXTRUDER - begin
//-----------------------------------------------------
class MEXTRUDER {
  float wpx, wpy;
  float wsizex = 42;
  float wsizey = 20;
  String wname, wdvcid;
  int wstatus;
  MEXTRUDER (String pdvcid, float ppx, float ppy, String pname) {
    wdvcid = pdvcid;
    wpx = ppx;
    wpy = ppy;
    wname = pname;
  }
  void mshow() {
    stroke(127);
    fill(200);
    rect(wpx, wpy, wsizex, wsizey);
    fill(0);
    fill(0x19BC0E);
    if (wstatus==1) fill(msetcolor("ROSSO"));
    else fill(msetcolor("NERO"));        
    triangle(wpx, wpy+wsizey, wpx+(7*1), wpy, wpx+(7*1),wpy+wsizey);
    triangle(wpx+(7*1),wpy+wsizey, wpx+(7*2),wpy,  wpx+(7*1), wpy );
    triangle(wpx+(7*2), wpy+wsizey, wpx+(7*3), wpy, wpx+(7*3),wpy+wsizey);
    triangle(wpx+(7*3),wpy+wsizey, wpx+(7*4),wpy,  wpx+(7*3), wpy );
    triangle(wpx+(7*4), wpy+wsizey, wpx+(7*5), wpy, wpx+(7*5),wpy+wsizey);
    triangle(wpx+(7*5),wpy+wsizey, wpx+(7*6),wpy,  wpx+(7*5), wpy );
  }

  void minfo() {
    fill(255);
    textSize(wsizetxt);
    text(wname, wpx, wpy);
    textSize(wsizetxt);
  }
  float[] mgethole (String phole) {
    float wcoohole[] = {0, 0};
    if (phole == "SX") {
      wcoohole[0] = wpx;
      wcoohole[1]= wpy + (wsizey/2);
    }
    if (phole == "DX") {
      wcoohole[0] = wpx+wsizey;
      wcoohole[1]= wpy + (wsizey/2);
    }
    if (phole == "UP") {
      wcoohole[0] = wpx + (wsizex/2);
      wcoohole[1]= wpy ;
    }
    if (phole == "DN") {
      wcoohole[0] = wpx + (wsizex/2);
      wcoohole[1]= wpy + wsizey;
    }
    return wcoohole;
  }

  void maction (int pstatus) { // 0=chiusa
    wstatus = pstatus;
    println("extruder maction: " ,wstatus );
  }
}
//-----------------------------------------------------
// EXTRUDER - end
//-----------------------------------------------------


//-----------------------------------------------------
// HEATER - begin
//-----------------------------------------------------
class MHEATER {
  float wpx, wpy;
  float wsize = 30;
  String wname, wdvcid;
  int wstatus;
  MHEATER (String pdvcid, float ppx, float ppy, String pname) {
    wdvcid = pdvcid;
    wpx = ppx;
    wpy = ppy;
    wname = pname;
  }
  void mshow() {
    stroke(127);
    fill(200);
    rect(wpx, wpy, wsize, wsize);
    fill(0);
    fill(0x19BC0E);
    rect(wpx+(wsize*0.2), wpy+((wsize/6)*1), wsize*0.8,(wsize/6)*1);
    rect(wpx+(wsize*0.2), wpy+((wsize/6)*3), wsize*0.8,(wsize/6)*1);
    rect(wpx+(wsize*0.2), wpy+((wsize/6)*5), wsize*0.8,(wsize/6)*1);    
    if (wstatus==1) fill(msetcolor("ROSSO"));
    else fill(msetcolor("NERO"));
    rect(wpx+(wsize*0.2), wpy+((wsize/6)*1), wsize*0.8,(wsize/6)*1);
    rect(wpx+(wsize*0.2), wpy+((wsize/6)*3), wsize*0.8,(wsize/6)*1);
    rect(wpx+(wsize*0.2), wpy+((wsize/6)*5), wsize*0.8,(wsize/6)*1);    

  }

  void minfo() {
    fill(255);
    textSize(wsizetxt);
    text(wname, wpx, wpy);
    textSize(wsizetxt);
  }
  float[] mgethole (String phole) {
    float wcoohole[] = {0, 0};
    if (phole == "SX") {
      wcoohole[0] = wpx;
      wcoohole[1]= wpy + (wsize/2);
    }
    if (phole == "DX") {
      wcoohole[0] = wpx+wsize;
      wcoohole[1]= wpy + (wsize/2);
    }
    if (phole == "UP") {
      wcoohole[0] = wpx + (wsize/2);
      wcoohole[1]= wpy ;
    }
    if (phole == "DN") {
      wcoohole[0] = wpx + (wsize/2);
      wcoohole[1]= wpy + wsize;
    }

    return wcoohole;
  }

  void maction (int pstatus) { // 0=chiusa
    wstatus = pstatus;
  }
}
//-----------------------------------------------------
// HEATER - end
//-----------------------------------------------------

//-----------------------------------------------------
// COOLER - begin
//-----------------------------------------------------
class MCOOLER {
  float wpx, wpy;
  float wsize = 30;
  String wname, wdvcid;
  int wstatus=0;
  MCOOLER (String pdvcid, float ppx, float ppy, String pname) {
    wdvcid = pdvcid;
    wpx = ppx;
    wpy = ppy;
    wname = pname;
  }
  void mshow() {
    stroke(127);
    fill(200);
    rect(wpx, wpy, wsize, wsize);
    fill(0);
    fill(0x19BC0E);
    rect(wpx+(wsize*0.2), wpy+((wsize/6)*1), wsize*0.8,(wsize/6)*1);
    rect(wpx+(wsize*0.2), wpy+((wsize/6)*3), wsize*0.8,(wsize/6)*1);
    rect(wpx+(wsize*0.2), wpy+((wsize/6)*5), wsize*0.8,(wsize/6)*1);    
    if (wstatus==1) fill(msetcolor("BLU"));
    else fill(msetcolor("NERO"));
    rect(wpx+(wsize*0.2), wpy+((wsize/6)*1), wsize*0.8,(wsize/6)*1);
    rect(wpx+(wsize*0.2), wpy+((wsize/6)*3), wsize*0.8,(wsize/6)*1);
    rect(wpx+(wsize*0.2), wpy+((wsize/6)*5), wsize*0.8,(wsize/6)*1);    
  }

  void minfo() {
    fill(255);
    textSize(wsizetxt);
    text(wname, wpx, wpy);
    textSize(wsizetxt);
  }
  float[] mgethole (String phole) {
    float wcoohole[] = {0, 0};
    if (phole == "SX") {
      wcoohole[0] = wpx;
      wcoohole[1]= wpy + (wsize/2);
    }
    if (phole == "DX") {
      wcoohole[0] = wpx+wsize;
      wcoohole[1]= wpy + (wsize/2);
    }
    if (phole == "UP") {
      wcoohole[0] = wpx + (wsize/2);
      wcoohole[1]= wpy ;
    }
    if (phole == "DN") {
      wcoohole[0] = wpx + (wsize/2);
      wcoohole[1]= wpy + wsize;
    }

    return wcoohole;
  }

  void maction (int pstatus) { // 0=chiusa
    wstatus = pstatus;
  }
}
//-----------------------------------------------------
// COOLER - end
//-----------------------------------------------------


//-----------------------------------------------------
// PUMP - begin
//-----------------------------------------------------
class MPUMP {
  float wpx, wpy;
  float wsize = 20;
  String wname, wdvcid;
  int wstatus;
  MPUMP (String pdvcid, float ppx, float ppy, String pname) {
    wdvcid = pdvcid;
    wpx = ppx;
    wpy = ppy;
    wname = pname;
  }
  void mshow() {
    stroke(127);
    fill(200);
    rect(wpx, wpy, wsize, wsize);
    fill(0);
    fill(0x19BC0E);
    circle(wpx+(wsize/2), wpy+(wsize/2), wsize);
    if (wstatus==1) fill(msetcolor("VERDE"));
    else fill(msetcolor("ROSSO"));
    circle(wpx+(wsize/2), wpy+(wsize/2), wsize);
  }

  void minfo() {
    fill(255);
    textSize(wsizetxt);
    text(wname, wpx, wpy);
    textSize(wsizetxt);
  }
  float[] mgethole (String phole) {
    float wcoohole[] = {0, 0};
    if (phole == "SX") {
      wcoohole[0] = wpx;
      wcoohole[1]= wpy + (wsize/2);
    }
    if (phole == "DX") {
      wcoohole[0] = wpx+wsize;
      wcoohole[1]= wpy + (wsize/2);
    }
    if (phole == "UP") {
      wcoohole[0] = wpx + (wsize/2);
      wcoohole[1]= wpy ;
    }
    if (phole == "DN") {
      wcoohole[0] = wpx + (wsize/2);
      wcoohole[1]= wpy + wsize;
    }

    return wcoohole;
  }

  void maction (int pstatus) { // 0=chiusa
    wstatus = pstatus;
  }
}
//-----------------------------------------------------
// PUMP - end
//-----------------------------------------------------

//-----------------------------------------------------
// VALVE - begin
//-----------------------------------------------------
class MVALVE {
  float wpx, wpy;
  float wsize = 20;
  String wname, wdvcid;
  int wstatus;
  MVALVE (String pdvcid, float ppx, float ppy, String pname) {
    wdvcid = pdvcid;
    wpx = ppx;
    wpy = ppy;
    wname = pname;
  }
  void mshow() {
    stroke(127);
    fill(200);
    rect(wpx, wpy, ((wsize/1.41)*2), wsize);
    fill(0);
    fill(0x19BC0E);
    triangle(wpx, wpy, wpx+(wsize/1.41), wpy+(wsize/2), wpx, wpy+wsize);
    triangle( wpx+(wsize/1.41), wpy+(wsize/2), 
      wpx+((wsize/1.41)*2), wpy, 
      wpx+((wsize/1.41)*2), wpy+wsize);

    if (wstatus==1) fill(msetcolor("VERDE"));
    else fill(msetcolor("ROSSO"));
    triangle(wpx, wpy, wpx+(wsize/1.41), wpy+(wsize/2), wpx, wpy+wsize);
    triangle( wpx+(wsize/1.41), wpy+(wsize/2), 
      wpx+((wsize/1.41)*2), wpy, 
      wpx+((wsize/1.41)*2), wpy+wsize);
  }

  void minfo() {
    fill(255);
    textSize(wsizetxt);
    text(wname, wpx, wpy);
    textSize(wsizetxt);
  }
  float[] mgethole (String phole) {
    float wcoohole[] = {0, 0};
    if (phole == "SX") {
      wcoohole[0] = wpx;
      wcoohole[1]= wpy + (wsize/2);
    }
    if (phole == "DX") {
      wcoohole[0] = wpx+((wsize/1.41)*2);
      wcoohole[1]= wpy + (wsize/2);
    }
    return wcoohole;
  }

  void maction (int pstatus) { // 0=chiusa
    wstatus = pstatus;
  }
}
//-----------------------------------------------------
// VALVE - end
//-----------------------------------------------------

//-----------------------------------------------------
// TANK - begin
//-----------------------------------------------------
class MTANK {
  float wpx, wpy;
  float wsizex = 80;
  float wsizey = 160;
  float wlargtxt = 80;
  float wfiller;          // per CAP
  float wtempc;            // per TEM
  float wpress;            // per BAR

  public String wname, wdvcid;
  //-----------------------------------------------------
  MTANK(String pdvcid, float ppx, float ppy, String pname) {
    wpx = ppx;
    wpy = ppy;
    wdvcid = pdvcid;
    wname = pname;
  }
  void mshow() {
    stroke(128);
    fill(msetcolor("NERO"));
    rect(wpx, wpy+wsizetxt, wsizex, wsizey);
    //      mfiller(wfiller);

    fill(msetcolortemp(wtempc));
    float wfilly = (wsizey*(1-(wfiller/100)));
    rect(wpx, wpy+wfilly+wsizetxt, wsizex, wsizey-wfilly);
  }
  //-----------------------------------------------------
  void minfo() {
    // 14.06.2019 portare in mshow(), questa servbirà per mousepressed()    
    fill(msetcolor("VERDE"));
    //    rect(wpx, wpy-wsizetxt, wlargtxt, wsizetxt);
    rect(wpx, wpy, wlargtxt, wsizetxt);
    fill(msetcolor("BIANCO"));
    textSize(wsizetxt);
    text(wname, wpx, wpy);
  }
  //-----------------------------------------------------
  // diventerà obsoleta:
  void mfiller(float pfiller) {
    wfiller=pfiller;
  }
  // attualmente implementa CAP, TEM,BAR  
  void maction(String paction) {
    String[] wparm = split(paction, '=');
    if ( match(wparm[0], "CAP") != null  ) {
      this.wfiller=float(wparm[1]);
    }
    if ( match(wparm[0], "TEM") != null  ) {
      this.wtempc=float(wparm[1]);
    }
    if ( match(wparm[0], "BAR") != null  ) {
      this.wpress=float(wparm[1]);
    }
  }
  //-----------------------------------------------------
  float[] mgethole (String phole) {
    float wcoohole[] = {0, 0};
    if (phole == "DX") {
      wcoohole[0] = wpx+ wsizex;
      wcoohole[1]= wpy + (wsizey/2);
    }
    if (phole == "SX") {
      wcoohole[0] = wpx;
      wcoohole[1]= wpy + (wsizey/2);
    }
    if (phole == "DN") {
      wcoohole[0] = wpx+ wsizex/2;
      wcoohole[1]= wpy + (wsizey/1)+wsizetxt;
    }
    if (match(phole, "UP")!=null) {
      wcoohole[0] = wpx+ wsizex/2;
      wcoohole[1]= wpy;  // + (wsizey/1)+wsizetxt;
    }
    return wcoohole;
  }
}
//-----------------------------------------------------
// TANK - begin
//-----------------------------------------------------


//-----------------------------------------------------
// PIPE - begin
//-----------------------------------------------------
class MPIPE {
  float wpxi, wpyi, wpxe, wpye;
  String wname, wdvcid;
  int wfilled;
  //-----------------------------------------------------
  MPIPE(String pdvcid, float ppxi, float ppyi, float ppxe, float ppye, String pname) {
    wpxi = ppxi;
    wpyi = ppyi;
    wpxe = ppxe;
    wpye = ppye;
    wdvcid = pdvcid;
    wname = pname;
  }
  void mshow() {
    stroke(128);
    if (wfilled == 0) fill(msetcolor("NERO"));
    else fill(msetcolor("BLU"));
    strokeWeight(3);
    line( wpxi, wpyi, wpxe, wpye);
  }
  //-----------------------------------------------------
  void mfiller(float pfiller) {
    if (pfiller == 0) wfilled = 0;
    else wfilled = 1;
    mshow();
  }
  //-----------------------------------------------------
}
//-----------------------------------------------------
// PIPE - end
//-----------------------------------------------------

//-----------------------------------------------------
// VALVEQ - begin
//-----------------------------------------------------
class MVALVQ {
  float wpx, wpy;
  float wsize = 20;
  String wname, wdvcid;
  int wstatus1, wstatus2, wstatus3;
  MVALVQ (String pdvcid, float ppx, float ppy, String pname) {
    wdvcid = pdvcid;
    wpx = ppx;
    wpy = ppy;
    wname = pname;
    wstatus1 = 0;
    wstatus2 = 0;
    wstatus3 = 0;
  }
    void minfo() {
    fill(255);
    textSize(wsizetxt);
    text(wname, wpx, wpy);
    textSize(wsizetxt);
  }

  void mshow() {
    stroke(127);
    fill(200);
    rect(wpx, wpy, ((wsize/1.41)*2)*3, wsize);
    fill(0);
    fill(0x19BC0E);

    textSize(18);
    text(wname, wpx, wpy);
    if (wstatus1 == 1) {
      fill(msetcolor("VERDE"));
      println("fl1=verde");
    } else fill(msetcolor("ROSSO"));
    triangle(wpx, wpy, wpx+(wsize/1.41), wpy+(wsize/2), wpx, wpy+wsize);
    triangle( wpx+(wsize/1.41), wpy+(wsize/2), wpx+((wsize/1.41)*2), wpy, wpx+((wsize/1.41)*2), wpy+wsize);

    if (wstatus2 == 1) fill(msetcolor("VERDE")); 
    else fill(msetcolor("ROSSO"));
    triangle(wpx+((wsize/1.41)*2), wpy, wpx+((wsize/1.41)*3), wpy+(wsize/2), wpx+((wsize/1.41)*2), wpy+wsize);
    triangle(wpx+((wsize/1.41)*3), wpy+(wsize/2), wpx+((wsize/1.41)*4), wpy, wpx+((wsize/1.41)*4), wpy+wsize);

    if (wstatus3 == 1) fill(msetcolor("VERDE")); 
    else fill(msetcolor("ROSSO"));
    triangle(wpx+((wsize/1.41)*4), wpy, wpx+((wsize/1.41)*5), wpy+(wsize/2), wpx+((wsize/1.41)*4), wpy+wsize);
    triangle(wpx+((wsize/1.41)*5), wpy+(wsize/2), wpx+((wsize/1.41)*6), wpy, wpx+((wsize/1.41)*6), wpy+wsize);
  }

  float[] mgethole (String phole) {
    float wcoohole[] = {0, 0};
    if (match(phole, "UP") !=null) {
      wcoohole[0] = wpx+((wsize/1.41)*3);
      wcoohole[1]= wpy;
    }
    if (match(phole, "D3") !=null) {
      wcoohole[0] = wpx+((wsize/1.41));
      wcoohole[1]= wpy + (wsize);
    }
    if (match(phole, "D2")!=null) {
      wcoohole[0] = wpx+((wsize/1.41)*3);
      wcoohole[1]= wpy + (wsize);
    }
    if (match(phole, "D1")!=null) {
      wcoohole[0] = wpx+((wsize/1.41)*5);
      wcoohole[1]= wpy + (wsize);
    }
    return wcoohole;
  }
  void maction (String paction) { // 0=chiusa
    String[] wparm = split(paction, '=');
    println(paction);
    if ( match(wparm[0], "FL1") != null  ) {
      if ( match(wparm[1], "1") != null ) wstatus1=1;
      else wstatus1=0;
    }
    if ( match(paction, "FL2") != null  ) {
      if ( match(wparm[1], "1") != null ) wstatus2=1;
      else wstatus2=0;
    }
    if ( match(paction, "FL3") != null  ) {
      if ( match(wparm[1], "1") != null ) wstatus2=1;
      else wstatus2=0;
    }
  }
}
//-----------------------------------------------------
// VALVEQ - begin
//-----------------------------------------------------




class MBUFLOG {
  String[] wline = {""};
  String wfname;
int wprevlog;                       
  MBUFLOG(  ) {
    mlogname();
    println(">>>filename " + wfname);
  }

  String mlogname() {
    String wprefix = "camiscada_";
    wfname = (wprefix + mgetdatario("fileansi"));
    wfname = (wfname + ".log");
    return wfname;
  }

  void msavelog() {
    this.mlogname();
    println("saving log " + wfname);
    saveStrings(wfname, wline);
    wline = expand(wline, 0);
    this.wprevlog = millis();
  }
  void maddrow(String pmsg) {
    if (match(pmsg, "null") == null) {    // "null" string NOT received  
      if (wline.length < wlogcnt) wline = append(wline, pmsg );
      else {
        this.mlogname(); 
        mbuflog.msavelog();
        wline = append(wline, pmsg );
      }
    }
    if ((millis() - wprevlog) > wmaxdelaylog)
      if (wline.length > 0)
        this.msavelog();
  }
}

//=====================================================

class MRUNDEMO {
  String[] wdemo = new String[500]; 
  int wlinecnt, wcmdcnt;
  String wline;
  int wmode =0;            // 0=no_demo, normal
  MRUNDEMO(  ) {
    wcmdcnt = 0;
  }
  void maddrow(  ) {
    BufferedReader wfiledemo;
    boolean fileExists ;
    String wline;
    wlinecnt = 0;
    wcmdcnt = 0;
    fileExists = false;
    wfiledemo = createReader("camiscada.dat");
    try {
      while ((wline = wfiledemo.readLine()) != null) {
        if ((matchAll(wline, "^#") == null) && (wline.length() >0)) wdemo[wlinecnt++]=wline;
        println("demo: ",wline);
      }
      wfiledemo.close();
    } 
      catch (IOException e) {
      this.msetmode(0);
    }
    println("rk loaded: ", wlinecnt);
  }    
  String mgetcmd( int pmode) {    // 0=rewind 1=next
    String wnowexec;
    if (wcmdcnt< (wlinecnt+1)) {
      wnowexec = this.wdemo[wcmdcnt];
      println("running step: ", wcmdcnt, "/", wlinecnt, " command: ", wnowexec);
      wcmdcnt++;
  
      return  wnowexec;
    } else {
      println("demo end");
      return null;
    }
  }
  void msetmode(int pmode) {
    this.wmode = pmode;
  }
}



//=====================================================
class MTARGA {
  float wpx, wpy;
  float wsizex = 400;
  float wsizey = 120;
  float wsizetxts= 10; //small
  float wlargtxt = 80;
  float wfiller;
  String wdatircv;
  //-----------------------------------------------------
  MTARGA( float ppx, float ppy) {
    wpx = ppx;
    wpy = ppy;
  }
  void mshow() {
    stroke(128);
    fill(msetcolor("NERO"));
    rect(wpx, wpy, wsizex, wsizey);
  }
  //-----------------------------------------------------

  void minfo() {
    fill(msetcolor("NERO"));
    rect(wpx, wpy, wsizex, wsizey);
    fill(msetcolor("BIANCO"));
    textSize(wsizetxt);
    text("CamiSCADA, 2019 v.1.0", wpx+10, wpy+20);
    text("Gevino", wpx+10, wpy+20+(wsizetxt*1));
    text("wnetid " + Server.ip(), wpx+10, wpy+20+(wsizetxt*2));
    text("logfile: " + mbuflog.wfname, wpx+10, wpy+20+(wsizetxt*3));
    fill(msetcolor("BIANCO"));              // verificare fill...
    textSize(wsizetxts);
    text(mgetdatario("orologio"), wpx+wsizex-120, wpy+wsizey-(wsizetxts*1)); //wsizey-(wsizetxts*6));
    //    text("testo ricevuto", wpx+10, wpy+20+(wsizetxt*2));
    text ("testo ricevuto: " + this.wdatircv, wpx+10, wpy+20+(wsizetxt*4));
    if (mrundemo.wmode ==1) text ("* D E M O   M O D E*", wpx+10, wpy+20+(wsizetxt*5));
  }
  void mdatircv (String pdati ) {
    wdatircv = pdati;
  }
}
//=====================================================


//--------------------------------------------------
void setup() {
  size(1366, 768);
//    size(680, 400);
  surface.setResizable(true);
  mtank =new MTANK[20];
  mvalve =new MVALVE[20];
  mvalvq =new MVALVQ[20];
  mpump =new MPUMP[20];
  mcooler =new MCOOLER[20];
  mheater =new MHEATER[20];  
  mextruder =new MEXTRUDER[20];
  mtarga =new MTARGA(1366-400, 700-120);
  mpipe =new MPIPE[200];
  mrundemo = new MRUNDEMO();
  mbuflog = new MBUFLOG();
  mserver = new Server(this, 10911); 
  photo = loadImage("pericolo.png");
  /* prova 16.08 */
  String[] lines = loadStrings("camiscada.dat");
  if (lines == null) { 
  mrundemo.msetmode(0);
  println("NO demo");
  }
  else {
    mrundemo.msetmode(1);
      println("si demo");
  }
  if (mrundemo.wmode ==1) {
    mrundemo.maddrow();
     println("carico demo");
  }
/*  */
  mloadcfg();
  dumpcfg();
// imposta run mode per demo:

}


//=====================================================
void draw() {
  String wcmdsched="";
//   
  for (int i = 0; i < wtankndx; i++) {
    mtank[i].mshow();
    mtank[i].minfo();
  }
  for (int i = 0; i < wpipendx; i++) {
    mpipe[i].mshow();
  }

  for (int i = 0; i < wvalvendx; i++) {
    mvalve[i].mshow();
    mvalve[i].minfo();    
  }

  for (int i = 0; i < wvalvqndx; i++) {
    mvalvq[i].mshow();
        mvalvq[i].minfo(); 
  }
  for (int i = 0; i < wpumpndx; i++) {
    mpump[i].mshow();
         mpump[i].minfo();    
  }
  for (int i = 0; i < wcoolerndx; i++) {
    mcooler[i].mshow();
     mcooler[i].minfo();  
  }

for (int i = 0; i < wheaterndx; i++) {
    mheater[i].mshow();
     mheater[i].minfo();  
    
  } 
  for (int i = 0; i < wextrundx; i++) {
    mextruder[i].mshow();
     mextruder[i].minfo();  
    
  }  

/*  if (((millis()/1000) - wprevlog) > (60*5)) {
   wprevlog = millis()/1000;
    mbuflog.msavelog();
   }
   */
   if (mrundemo.wmode ==1) wcmdsched = mrundemo.mgetcmd(1);
  //  if ((wcmdsched !=null) || wcmdsched.length()==0 ) { 
//        println("wcmdsched ",wcmdsched);
//  if ((wcmdsched !=null) || (wcmdsched.length()==0)) {
if (wcmdsched != null) {
  if (wcmdsched.length()>0) {
    mtarga.mdatircv(wcmdsched);

    mobjchanger(wcmdsched);
    //    mwrtlog(wcmdsched);
  }
}
  mtarga.minfo();
// legge da usb
// legge da eth
// legge da modbus
  mbuflog.maddrow(mgetdatario("orologio") + ";" + wcmdsched);
  delay(1000);
}



//=====================================================
int mloadcfg() {
  BufferedReader wfileini;
  String wline;
  float[] wholebeg, wholeend;
  wfileini = createReader("camiscada.ini");
  try {
    while ((wline = wfileini.readLine()) != null) {
      // inserire discrimine per commento
      if (matchAll(wline, "^#") == null) {
        String[] wobjparm = split(wline, ";");
        if ( match(wobjparm[0], "TANK") != null) {
          //          print(mgetdatario("orologio")+" oggetto trovato " + wobjparm[0]+" - "+wobjparm[1]+"\n");
          mtank[wtankndx++] = new MTANK(wobjparm[1], int(wobjparm[2]), int(wobjparm[3]), wobjparm[4]);
        } 
        if ( match(wobjparm[0], "PIPE") != null) {
          //PIPE;p1b1d1m1c1;"TANK";p1b1d1m1c1;DX;"PUMP";p1b1d1m1c1;SX;miopipe
          //PIPE;p1b1d1m1c1;p1b1d1m1c1;DX;p1b1d1m1c2;SX;miopipe
          //   0          1    2       3      4       5     6     
          wholebeg = mgetholebyobj ( wobjparm[2], wobjparm[3]);
          wholeend = mgetholebyobj ( wobjparm[4], wobjparm[5]);          
          mpipe[wpipendx++] = new MPIPE(wobjparm[1], 
            wholebeg[0], wholebeg[1], 
            wholeend[0], wholeend[1], 
            wobjparm[6]);
        } 
        // valve
        if ( match(wobjparm[0], "VALVE") != null) {
          mvalve[wvalvendx++] = new MVALVE(wobjparm[1], int(wobjparm[2]), int(wobjparm[3]), wobjparm[4]);
        } 
        // valvq
        if ( match(wobjparm[0], "VALVQ") != null) {
          mvalvq[wvalvqndx++] = new MVALVQ(wobjparm[1], int(wobjparm[2]), int(wobjparm[3]), wobjparm[4]);
        }
        if ( match(wobjparm[0], "COOLER") != null) {
          mcooler[wcoolerndx++] = new MCOOLER(wobjparm[1], int(wobjparm[2]), int(wobjparm[3]), wobjparm[4]);
        }
        if ( match(wobjparm[0], "HEATER") != null) {
          mheater[wheaterndx++] = new MHEATER(wobjparm[1], int(wobjparm[2]), int(wobjparm[3]), wobjparm[4]);
        }
        if ( match(wobjparm[0], "EXTRUDER") != null) {
          mextruder[wextrundx++] = new MEXTRUDER(wobjparm[1], int(wobjparm[2]), int(wobjparm[3]), wobjparm[4]);
        }
        if ( match(wobjparm[0], "PUMP") != null) {
          mpump[wpumpndx++] = new MPUMP(wobjparm[1], int(wobjparm[2]), int(wobjparm[3]), wobjparm[4]);
        }
      } else {            // something wrong?
        println(wline);
      }
    }
    wfileini.close();
  } 
  catch (IOException e) {
    e.printStackTrace();
  }
  return 0;
  // }
}
//=====================================================


void dumpcfg(  ) {
  for (int i=0; i<wtankndx; i++) {
    println("dump ", i, " ", mtank[i].wdvcid, " ", mtank[i].mgethole("DX")[0], mtank[i].mgethole("SX")[0]);
  }
}


int mgetobjidx( String ptipobj, String pobjname) {
  int wretcode = -1;
  // gestire il tipo obj
  if (match(ptipobj, "tank") !=null) {
    for (int i=0; i<wtankndx; i++) {
//      println(mtank[i].wdvcid, " ",pobjname);
      if (match( mtank[i].wdvcid, pobjname) != null) {
		wretcode = i;
		return wretcode;
		}
    }
  }
  if (match(ptipobj, "valve") !=null) {    
    for (int i=0; i<wvalvendx; i++ ) {
      if (match( mvalve[i].wdvcid, pobjname) != null) {
		wretcode = i;
		return wretcode;
		}
    }
  }
  if (match(ptipobj, "valvq") !=null) {    
    for (int i=0; i<wvalvqndx; i++) {
      if (match( mvalvq[i].wdvcid, pobjname) != null) {
		wretcode = i;
		return wretcode;
		}
    }
  }

  if (match(ptipobj, "pump") !=null) {    
    for (int i=0; i<wpumpndx; i++) {
      if (match( mpump[i].wdvcid, pobjname) != null) {
		wretcode = i;
		return wretcode;
		}
    }
  }
  if (match(ptipobj, "cooler") !=null) {    
    for (int i=0; i<wcoolerndx; i++) {
      if (match( mcooler[i].wdvcid, pobjname) != null) {
		wretcode = i;
		return wretcode;
		}
    }
  }
  if (match(ptipobj, "heater") !=null) {    
    for (int i=0; i<wheaterndx; i++) {
      if (match( mheater[i].wdvcid, pobjname) != null) {
		wretcode = i;
		return wretcode;
		}
    }
  }
  if (match(ptipobj, "extruder") !=null) {    
    for (int i=0; i<wextrundx; i++) {
      if (match( mextruder[i].wdvcid, pobjname) != null) {
		wretcode = i;
		return wretcode;
		}
    }
  }
  return wretcode;
}


float[] mgetholebyobj (
  String pdvcid, String phole) {
  float wcoohole[] = {0, 0};
  int wobjidx = -1;
  int i;
  for ( i=0; i<wtankndx; i++) {
    if (match( mtank[i].wdvcid, pdvcid) != null) {
      if (match(phole, "SX") != null) wcoohole=mtank[i].mgethole("SX");
      if (match(phole, "DX") != null) wcoohole=mtank[i].mgethole("DX");      
      if (match(phole, "DN") != null) wcoohole=mtank[i].mgethole("DN");
      if (match(phole, "UP") != null) wcoohole=mtank[i].mgethole("UP");      
      return wcoohole;
    }
  }
  for ( i=0; i<wvalvendx; i++) {
    if (match( mvalve[i].wdvcid, pdvcid) != null) {
      if (match(phole, "SX") != null) wcoohole=mvalve[i].mgethole("SX");
      else wcoohole=mvalve[i].mgethole("DX");
      return wcoohole;
    }
  } 

  for ( i=0; i<wvalvqndx; i++) {
    if (match( mvalvq[i].wdvcid, pdvcid) != null) {
      if (match(phole, "D1") != null) wcoohole=mvalvq[i].mgethole("D1");
      if (match(phole, "D2") != null) wcoohole=mvalvq[i].mgethole("D2");      
      if (match(phole, "D3") != null) wcoohole=mvalvq[i].mgethole("D3");      
      if (match(phole, "UP") != null) wcoohole=mvalvq[i].mgethole("UP");      
      return wcoohole;
    }
  } 

  for ( i=0; i<wpumpndx; i++) {
    if (match( mpump[i].wdvcid, pdvcid) != null) {
      if (match(phole, "SX") != null) wcoohole=mpump[i].mgethole("SX");
      if (match(phole, "DX") != null) wcoohole=mpump[i].mgethole("DX");      
      if (match(phole, "DN") != null) wcoohole=mpump[i].mgethole("DN");      
      if (match(phole, "UP") != null) wcoohole=mpump[i].mgethole("UP");      
      return wcoohole;
    }
  } 

  for ( i=0; i<wextrundx; i++) {
    if (match( mextruder[i].wdvcid, pdvcid) != null) {
      if (match(phole, "SX") != null) wcoohole=mextruder[i].mgethole("SX");
      if (match(phole, "DX") != null) wcoohole=mextruder[i].mgethole("DX");      
      if (match(phole, "DN") != null) wcoohole=mextruder[i].mgethole("DN");      
      if (match(phole, "UP") != null) wcoohole=mextruder[i].mgethole("UP");      
      return wcoohole;
    }
  } 


  for ( i=0; i<wcoolerndx; i++) {
    if (match( mcooler[i].wdvcid, pdvcid) != null) {
      if (match(phole, "SX") != null) wcoohole=mcooler[i].mgethole("SX");
      if (match(phole, "DX") != null) wcoohole=mcooler[i].mgethole("DX");      
      if (match(phole, "DN") != null) wcoohole=mcooler[i].mgethole("DN");      
      if (match(phole, "UP") != null) wcoohole=mcooler[i].mgethole("UP");      
      return wcoohole;
    }
  } 

  for ( i=0; i<wheaterndx; i++) {
    if (match( mheater[i].wdvcid, pdvcid) != null) {
      if (match(phole, "SX") != null) wcoohole=mheater[i].mgethole("SX");
      if (match(phole, "DX") != null) wcoohole=mheater[i].mgethole("DX");      
      if (match(phole, "DN") != null) wcoohole=mheater[i].mgethole("DN");      
      if (match(phole, "UP") != null) wcoohole=mheater[i].mgethole("UP");      
      return wcoohole;
    }
  } 

  return wcoohole;
}

//=====================================================
String mgetdatario( String pmode ) {
  String wdatario = "";
  String wday = String.valueOf(day());
  if (wday.length()==1) wday = "0"+wday;
  String wmonth = String.valueOf(month());
  if (wmonth.length()==1) wmonth = "0"+wmonth;
  String wyear = String.valueOf(year());
  String whour = String.valueOf(hour());
  if (whour.length()==1) whour = "0"+whour;
  String wminute = String.valueOf(minute());
  if (wminute.length()==1) wminute = "0"+wminute;
  String wsecond = String.valueOf(second());
  if (wsecond.length()==1) wsecond = "0"+wsecond;
  if ( match(pmode, "orologio") != null)
    wdatario = wday+"."+wmonth+"."+wyear+" " +whour+":"+wminute+":"+wsecond;
  if ( match(pmode, "fileansi") != null)
    wdatario = wyear+wmonth+wday+"_"+whour+wminute+wsecond;
  return wdatario;
}
//=====================================================



//=====================================================
color msetcolor(String pcolor) {
  if ( match( pcolor, "BLU"  ) != null) return(color(15, 32, 188));
  if ( match( pcolor, "AZZURRO"  ) != null) return(color(135, 206, 250));
  if ( match( pcolor, "BIANCO"  ) != null) return(color(255, 255, 255));
  if ( match( pcolor, "ROSA"  ) != null) return(color(255, 105, 180));
  if ( match( pcolor, "NERO"  ) != null ) return(color(0, 0, 0));
  if ( match( pcolor, "VERDE"  ) != null) return(color(43, 182, 8));
  if ( match( pcolor, "ROSSO"  ) != null) return(color(238, 29, 15));
  if ( match( pcolor, "GIALLO"  ) != null) return(color(255, 255, 10));
  if ( match( pcolor, "ARANCIO"  ) != null) return(color(255, 69, 0));    
  if ( match( pcolor, "GRIGIO"  ) != null) return(color(#808080));
  return(color(255, 255, 255));
}
//=====================================================


color msetcolortemp(float ptemp) {
  if (ptemp < 10)                     return (color(10, 0, 255));
  if ((ptemp >= 10) && (ptemp < 20))  return (color(52, 0, 226));
  if ((ptemp >= 20) && (ptemp < 30))  return (color(81, 0, 197));
  if ((ptemp >= 30) && (ptemp < 40))  return (color(110, 0, 168));  
  if ((ptemp >= 40) && (ptemp < 50))  return (color(139, 0, 139));
  if ((ptemp >= 50) && (ptemp < 60))  return (color(168, 0, 110));
  if ((ptemp >= 60) && (ptemp < 70))  return (color(197, 0, 81));
  if ((ptemp >= 70) && (ptemp < 80))  return (color(226, 0, 51));
  if ((ptemp >= 80) && (ptemp <= 90)) return (color(255, 0, 10));  
  return(color(255, 255, 255));
}



void serialEvent(Serial p) {
  wstrser = p.readString();
  println(wstrser);
}


void mobjchanger (String pcmd) {
  int widtank, widtvalve, widtvalvq, widpump,widtcooler,widtheater,widextruder;
  String[] wparm = split(pcmd, ';');
  String wsensval;
  widtank = mgetobjidx( "tank", wparm[0]);
println(pcmd," widtank>>>>>>>>>>",widtank);  
  if (widtank > -1) {
    println(">>>>>>>>>>",wparm[0]);
    String[] wsensor = split(wparm[1], '=');
    wsensval = wsensor[1];
    if (match(wsensor[0], "TEM") !=null)  mtank[widtank].maction(wparm[1]);  
    if (match(wsensor[0], "CAP") !=null) mtank[widtank].mfiller(float(wsensor[1]));
    return;
  }
  widtvalve = mgetobjidx( "valve", wparm[0]);
  if (widtvalve > -1) {
    String[] wsensor = split(wparm[1], '=');
    if ( match(wsensor[0], "FLO") !=null ) {
      wsensval = wsensor[1];
      mvalve[widtvalve].maction(int(wsensval));
    } else {
      println( wparm[0], " sensor, undefined attribute: ", wparm[0]);
    }
    //tmp wtank1.mfiller(map(float(wparm[1]),0,1023,0,100));
    return;
  }
  
  widextruder = mgetobjidx( "extruder", wparm[0]);
  if (widextruder > -1) {
    String[] wsensor = split(wparm[1], '=');
    if ( match(wsensor[0], "FLO") !=null ) {
      wsensval = wsensor[1];
      mextruder[widextruder].maction(int(wsensval));
    } else {
      println( wparm[0], " sensor, undefined attribute: ", wparm[0]);
    }
    //tmp wtank1.mfiller(map(float(wparm[1]),0,1023,0,100));
    return;
  } 
  
  
  widtvalvq = mgetobjidx( "valvq", wparm[0]);
  if (widtvalvq > -1) {
    mvalvq[widtvalvq].maction(wparm[1]);
    return;
  }
  widtcooler = mgetobjidx( "cooler", wparm[0]);
  if (widtcooler > -1) {
    String[] wsensor = split(wparm[1], '=');
    if ( match(wsensor[0], "FLO") !=null ) {
      wsensval = wsensor[1];
      mcooler[widtcooler].maction(int(wsensval));
    } else {
      println( wparm[0], " sensor, undefined attribute: ", wparm[0]);
    }
    return;
  }
  widtheater = mgetobjidx( "heater", wparm[0]);
  if (widtheater > -1) {
    String[] wsensor = split(wparm[1], '=');
    if ( match(wsensor[0], "FLO") !=null ) {
      wsensval = wsensor[1];
      mheater[widtheater].maction(int(wsensval));
    } else {
      println( wparm[0], " sensor, undefined attribute: ", wparm[0]);
    }
    return;
  }

  widpump = mgetobjidx( "pump", wparm[0]);
  if (widpump > -1) {
    String[] wsensor = split(wparm[1], '=');
    if ( match(wsensor[0], "FLO") !=null ) {
      wsensval = wsensor[1];
      mpump[widpump].maction(int(wsensval));
    } else {
      println( wparm[0], " sensor, undefined attribute: ", wparm[0]);
    }
    //tmp wtank1.mfiller(map(float(wparm[1]),0,1023,0,100));
    return;
  }
}
