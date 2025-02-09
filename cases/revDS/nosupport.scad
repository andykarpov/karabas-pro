

$fn = 100;

pcb = "KarabasDS_pcb.stl";

if (false)
{
  translate([0, 0, 0.6]) 
  {
    rotate([0,0,0]) color("lightgray") import(pcb);
  }
}

difference() {

    union() {
        rotate([90, 0, 90])
            import("KarabasDS_FDD_case_bottom_v1.0.stl");

        translate([151.564, 15, -2.507])
            rotate([0, 90, 90])
                cube([3.75, 2.5, 14], true);
    }

    translate([146, -17, -1.05])
        rotate([0, 90, 90])
            cube([4.55, 20, 40], true);

    translate([146, -16, -6.507])
        rotate([0, 90, 90])
            cube([3.75, 20, 25], true);

    translate([150.02, 9.4, -2])
        rotate([0, 90, 0])
            cylinder(3.6, 0.5, 0.5);

    translate([150.02, 12.2, -2])
        rotate([0, 90, 0])
            cylinder(3.6, 0.5, 0.5);

    translate([150.02, 15, -2])
        rotate([0, 90, 0])
            cylinder(3.6, 0.5, 0.5);

    translate([150.02, 17.8, -2])
        rotate([0, 90, 0])
            cylinder(3.6, 0.5, 0.5);

    translate([150.02, 20.6, -2])
        rotate([0, 90, 0])
            cylinder(3.6, 0.5, 0.5);
}
