// Flatpanel Version 3

  $fn=120;
  
  Tubusradius = 74;
  Panelradius = 84.5;
  Rand = 7.5;
  DickePanelFolie = 1.5;
  ServoBrakPan_d = 10;  // Dicke Block Servo-Bracket Panelanschluss
  ServoBrakPan_h = 14;  // Höhe Servo-Bracket Panelanschluss

  DickeDeckelZyl = 4;    // Dicke des Deckel-Zylinders
  BreiteAnschlBlock = 20;
  
  DickePanelRing = DickeDeckelZyl;
  
  OffsBohrServoBlock = 14.7;
  ServBlockMutterAusschnX = 20;
  ServBlockMutterAusschnY = 10;
  

module ELPanel() {
   union() {
      cylinder(h=DickePanelFolie, r=Panelradius,center=true);
      translate([Panelradius-2,-7.5,-1.8]) cube([17.2,15,3.6], center=false);
      translate([Panelradius+15.2,-7.5,-1.8]) cube([21,15,3.6], center=false);
      //translate([Panelradius-5,-6.75,-0.25]) cube([15.2,13.5,0.5], center=false);
   }
}


module AnschlBlock() {  // Halber Block fuer Panel-Anschluss
   cube([30,BreiteAnschlBlock,DickeDeckelZyl]);
}

module EinzelBohrungServoBlock() {
    rotate([0,90,0]) cylinder(h=10, r=1.8);
}

module BohrungenServoBlock() {
  translate([0,OffsBohrServoBlock,0]) EinzelBohrungServoBlock();
  translate([0,-1*OffsBohrServoBlock,0]) EinzelBohrungServoBlock();
  //translate([0,OffsBohrServoBlock,10]) EinzelBohrungServoBlock();
  //translate([0,-1*OffsBohrServoBlock,10]) EinzelBohrungServoBlock();
}

module MountPadSingle () {
    difference() {
    union() {
      translate([0,0,0]) 
         cylinder(h=DickeDeckelZyl, r=10);
      translate([-10,0,0]) 
         cube([20,10,DickeDeckelZyl]);
    }
      cylinder(h=DickeDeckelZyl, r=1.8);
    }
}

module MountPads() {
    rotate([0,0,45])
    union() {
      translate([0,Panelradius+Rand+2.5+1.55,0]) rotate([0,0,180])
         MountPadSingle();
      translate([0,-1*(Panelradius+Rand+2.5+1.55),0]) 
         MountPadSingle();
      translate([-1*(Panelradius+Rand+2.5+1.55),0,0]) rotate([0,0,-90])
         MountPadSingle();    
      translate([(Panelradius+Rand+2.5+1.55),0,0])  rotate([0,0,90]) 
         MountPadSingle();
    }    
}


// Oberteil 
union() {
  difference () {
    union () {      
        union () {
          difference () {
            union () {
              resize(newsize=[2*(Panelradius+Rand),2*(Panelradius+Rand),10]) 
                sphere(r=Panelradius+Rand);
              translate([Panelradius+Rand-(ServoBrakPan_d/2),0,(ServoBrakPan_h/2)-DickeDeckelZyl]) 
                  cube([ServoBrakPan_d,55.6,ServoBrakPan_h],true); 
            }
            translate([0,0,-1*DickeDeckelZyl]) 
              cube([2*(Panelradius+Rand)+50,2*(Panelradius+Rand),2*DickeDeckelZyl],true); // Alles mit z<0 abschneiden
          }   
          translate([0,0,-1*DickeDeckelZyl]) 
            cylinder(h=DickeDeckelZyl, r=Panelradius+Rand);
       // }
      }
      rotate([0,0,-30]) translate([Panelradius,-1*(BreiteAnschlBlock/2),-DickeDeckelZyl]) 
        AnschlBlock();
    }
    translate([Panelradius+Rand-ServBlockMutterAusschnX-ServoBrakPan_d,OffsBohrServoBlock-(ServBlockMutterAusschnY/2),0]) 
      cube([ServBlockMutterAusschnX,ServBlockMutterAusschnY,25]);
    translate([Panelradius+Rand-ServBlockMutterAusschnX-ServoBrakPan_d,-1*(OffsBohrServoBlock+(ServBlockMutterAusschnY/2)),0]) 
      cube([ServBlockMutterAusschnX,ServBlockMutterAusschnY,25]);
    translate([Panelradius+Rand-ServoBrakPan_d,0,DickeDeckelZyl]) BohrungenServoBlock();
    translate([0,0,-5.251]) rotate([0,0,-30]) ELPanel();
  
    difference () {
      translate([0,0,-1*DickeDeckelZyl]) 
        cylinder(h=DickeDeckelZyl, r=Tubusradius+5);
      translate([0,0,-0.5*DickeDeckelZyl])
        cube([15,2*(Tubusradius+5),DickeDeckelZyl],true);
      rotate([0,0,90]) translate([0,0,-0.5*DickeDeckelZyl])
        cube([15,2*(Tubusradius+5),DickeDeckelZyl],true);
    }
  }
  translate([Panelradius+Rand-ServBlockMutterAusschnX-ServoBrakPan_d-5,-27.8,-1*DickeDeckelZyl]) 
    cube([ServBlockMutterAusschnX+5,55.6,DickeDeckelZyl]);
  translate([0,0,-DickePanelRing]) MountPads();
}
  

// Unterteil
union() {  
  difference() {
    union() {
      translate([0,0,-55])
        cylinder(h=DickePanelRing, r=Panelradius+Rand, center=false);
      translate([0,0,-55])
      rotate([0,0,-30]) translate([Panelradius,-1*(BreiteAnschlBlock/2),0]) 
        AnschlBlock();  
    }
    translate([0,0,-55])
      cylinder(h=DickePanelRing, r=Tubusradius+5, center=false);
    translate([0,0,-55-(DickePanelFolie/2)+DickeDeckelZyl]) rotate([0,0,-30]) ELPanel();
  }
  translate([0,0,-55]) MountPads();
}
