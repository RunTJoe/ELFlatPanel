$fn=150;
  
Tubusradius = 74;

module TubeRing(mutter = 0) {
  difference() {
    union() {
      cylinder(h=20, r=Tubusradius+15, center=false);
      translate([-15,Tubusradius,0]) cube([15,40,20]);
      translate([-15,-1*(Tubusradius+40),0]) cube([15,40,20]);
    }
    cylinder(h=20, r=Tubusradius+0.5, center=false);
    translate([-2, -1*((Tubusradius+15+40)), 0]) cube([(Tubusradius+15)+10,2*(Tubusradius+15+40),20]);   
    
    translate([-7.5,Tubusradius+15+12.5+2,10]) rotate([0,90,0]) cylinder(h=15, r=3.3, center=true);
    translate([-7.5,-1*(Tubusradius+40-12.5+2),10]) rotate([0,90,0]) cylinder(h=15, r=3.3, center=true);
    
    if (mutter) {
      translate([-15,Tubusradius+15+12.5+2,10]) rotate([0,90,0]) cylinder(h=5, r=5.9, $fn=6); 
      translate([-15,-1*(Tubusradius+40-12.5+2),10]) rotate([0,90,0]) cylinder(h=5, r=5.9, $fn=6); 
    }
  }   
}


translate([0,0,20]) rotate([0,180,0]) TubeRing(1);

difference() {
    union() {
      TubeRing();        
        translate([-1*((Tubusradius+15)+15),-22.2,0]) cube([25,44.4,35]);
        translate([-1*((Tubusradius+15)+14),-22.2,0]) cube([40,44.4,30]);
    }
  
    translate([-1*((Tubusradius+15+6)),-10,0]) cube([10,20,35]);
    translate([-1*((Tubusradius+15+6+5)),5,30]) rotate([0,90,0]) cylinder(h=10, r=1.55, center=true);
    translate([-1*((Tubusradius+15+6+5)),5,20]) rotate([0,90,0]) cylinder(h=10, r=1.55, center=true);
    translate([-1*((Tubusradius+15+6+5)),-5,30]) rotate([0,90,0]) cylinder(h=10, r=1.55, center=true);
    translate([-1*((Tubusradius+15+6+5)),-5,20]) rotate([0,90,0]) cylinder(h=10, r=1.55, center=true);    
    
    cylinder(h=30, r=Tubusradius+0.5, center=false);

}
