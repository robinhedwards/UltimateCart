/* Ultimate Cart shell
   (c) R.Edwards 2017
*/

ridge_width = 0.5;
cart_length=80;
cart_width=65 - (ridge_width*2);
cart_height=11.5;
screw_sep = 49.5;
front_thickness = 1.6;
sides_thickness = 1.6 - 0.05;
support_thickness = 1.2 - 0.05;
support_height = 10.5;
rim_height=1;

difference() {
    union() {
        difference() {
            // main shell
            union() {
                cube([cart_length, cart_width, cart_height-rim_height]);
                // rim
                translate([0, sides_thickness/2, cart_height-rim_height])
                    cube([cart_length-sides_thickness/2, sides_thickness/2, rim_height]);
                translate([0, cart_width-sides_thickness, cart_height-rim_height])
                    cube([cart_length-sides_thickness/2, sides_thickness/2, rim_height]);
                translate([cart_length-sides_thickness, sides_thickness/2, cart_height-rim_height])
                    cube([sides_thickness/2, cart_width-sides_thickness, rim_height]);
            }
            // make hollow
            translate([0, sides_thickness, front_thickness])
                cube([cart_length-sides_thickness,
                    cart_width-sides_thickness*2,
                    cart_height-front_thickness]);
            // cutout reset button slot
            translate([cart_length-sides_thickness, 22, cart_height-8])
                cube([sides_thickness, 7.5, 8]);
            // cutout programming header
            translate([56, 4, front_thickness/2])
                cube([22.5, 13, front_thickness]);
        }    
        // end
        cube([sides_thickness, cart_width, 4]);
        // pcb supports
        difference() {
            translate([17, sides_thickness, 0])
                cube([support_thickness, cart_width-sides_thickness*2, cart_height]);
            translate([17, (cart_width-55)/2, support_height])
                cube([support_thickness, 55, cart_height-support_height]);
        }
        translate([53, 0, 0])
            cube([support_thickness, 7, support_height]);
        translate([53, cart_width-7, 0])
            cube([support_thickness, 7, support_height]);
        // screw holes
        difference() {
            translate([29.5, (cart_width-screw_sep)/2, 0])
                difference() {
                    cylinder(h = support_height, r1 = 4, r2 = 3,  $fs = 1);
                    cylinder(h = support_height, r1 = 1.8, r2 = 1.8,  $fs = 1);
                }
            translate([29.5+1, (cart_width-screw_sep)/2-5, support_height-2])
                cube([10, 10, 2]);
        }
        translate([29.5, cart_width-(cart_width-screw_sep)/2, 0])
            difference() {
                cylinder(h = support_height, r1 = 4, r2 = 3,  $fs = 1);
                cylinder(h = support_height, r1 = 1.8, r2 = 1.8,  $fs = 1);
            }
        // ridges
        for (i = [15: 5: cart_length-5])
            union() {
                translate([i, -ridge_width, 0])
                    cube([3, ridge_width, cart_height-rim_height]);
                translate([i, cart_width, 0])
                    cube([3, ridge_width, cart_height-rim_height]);
            }
    }
    // screw head
    translate([29.5, (cart_width-screw_sep)/2, 0])
        cylinder(h = 0.6, r1 = 3.5, r2 = 3.5,  $fs = 1);
    translate([29.5, (cart_width-screw_sep)/2, 0.6])
        cylinder(h = front_thickness-0.6, r1 = 3.5, r2 = 1.8,  $fs = 1);

    translate([29.5, cart_width-(cart_width-screw_sep)/2, 0])
        cylinder(h = 0.6, r1 = 3.5, r2 = 3.5,  $fs = 1);
    translate([29.5, cart_width-(cart_width-screw_sep)/2, 0.6])
        cylinder(h = front_thickness-0.6, r1 = 3.5, r2 = 1.8,  $fs = 1);
}
