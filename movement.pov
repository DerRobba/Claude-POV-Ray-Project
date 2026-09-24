// ============================================================================
//  movement.pov  -  "Sunday Drive through POV-Ray Valley"
// ----------------------------------------------------------------------------
//  Started from the "car drives past the forest" task we got in class and
//  pushed it a lot further:
//
//    * the car is now an actual car (side profile built with a prism,
//      wheel arches cut out, glass, headlights, tail lights, license plate,
//      mirrors, rally stripes) instead of a grey box on four donuts
//    * the wheels ROLL - the rotation is calculated from the distance driven,
//      so they never slide over the road
//    * a real road: asphalt, centre dashes, edge lines, guide posts
//    * a randomly generated forest (loops + rand) instead of 34 copy-pasted
//      lines, with pine AND leafy trees
//    * mountains all around made from a height_field + noise function
//    * golden hour sun, drifting clouds, ground haze, a flock of birds,
//      a wooden fence and a sign for the valley
//    * a chase camera that swings around the car while it drives
//
//  Everything moving depends on "clock" (0 -> 1), so this is an animation.
//  Render it with the [Movement ...] entries I added to quickres.ini, or with
//  movement.ini that sits next to this file.
//
//  A single still (no animation) just uses clock = 0.
//
//  Units: 1 POV unit = 1 metre. The road runs along the x-axis and the car
//  drives in +x direction on the right lane (which is the -z side).
// ============================================================================

#version 3.7;

// ----------------------------------------------------------------------------
//  QUALITY SWITCHES
//  Every switch uses #ifndef, so you can also override it from the command
//  line / ini file, e.g.   Declare=Soft_Shadows=0
//  If the school PC is too slow, turn stuff off here first.
// ----------------------------------------------------------------------------
#ifndef (Soft_Shadows)  #declare Soft_Shadows  = 1; #end  // area light sun -> soft shadow edges (costs ~2x time)
#ifndef (Use_Radiosity) #declare Use_Radiosity = 0; #end  // real bounce light, pretty but SLOW and can flicker in animations
#ifndef (Focal_Blur)    #declare Focal_Blur    = 0; #end  // depth of field, looks filmic, very slow
#ifndef (Tree_Count)    #declare Tree_Count    = 900; #end // how many trees get planted
#ifndef (Cam_Select)    #declare Cam_Select    = 3; #end  // 1 = side view, 2 = bird's eye, 3 = chase cam (animated)


global_settings {
    assumed_gamma 1.0                    // linear light maths, like the original file
    max_trace_level 10                   // enough bounces for glass + chrome
    #if (Use_Radiosity)
        radiosity {
            pretrace_start 0.08
            pretrace_end   0.01
            count 120
            nearest_count 8
            error_bound 0.8
            recursion_limit 1
            low_error_factor 0.5
            brightness 1.0
        }
    #end
}

// Without radiosity there is no bounced light, so shadows would turn pitch black.
// A bit of ambient fakes the light that comes from the sky. With radiosity on
// we don't need the cheat anymore.
#if (Use_Radiosity)
    #default { finish { ambient 0 diffuse 0.85 } }
#else
    #default { finish { ambient 0.06 diffuse 0.85 } }
#end


//-----------INCLUDES---------------------------------------------------------
#include "colors.inc"
#include "textures.inc"
#include "functions.inc"        // needed for the noise function of the mountains


//-----------TIME / MOTION-----------------------------------------------------
// This is the heart of the animation. Everything else just reads these values.

#declare T = clock;                                     // 0 at the first frame, 1 at the last

#declare Car_Start  = -60;                              // where the car is at T = 0 (x)
#declare Car_End    =  90;                              // where it is at T = 1
#declare Car_Lane_Z = -1.75;                            // middle of the right lane
#declare Car_X      = Car_Start + (Car_End - Car_Start) * T;   // constant speed: 150 m in 10 s = 54 km/h

#declare Wheel_R    = 0.34;                             // tyre radius in metres

// How far did the wheel turn? distance / circumference = number of turns.
// Times 360 gives degrees. That way the tyres never "slip" on the road.
#declare Wheel_Spin = (Car_X - Car_Start) / (2 * pi * Wheel_R) * 360;

// Tiny suspension wobble so the car doesn't look glued onto the road.
// It depends on the position, so it looks like small bumps in the asphalt.
#declare Body_Bob   = 0.012 * sin(Car_X * 2.3) + 0.006 * sin(Car_X * 5.1);
#declare Body_Pitch = 0.25  * sin(Car_X * 1.7);         // degrees, nose dipping a little

#declare Car_Pos    = <Car_X, 0.02, Car_Lane_Z>;         // 0.02 = the road surface height


//-----------CAMERA-----------------------------------------------------------
// I kept the idea of the original three cameras, but they got updated for the
// new scene. Switch them with Cam_Select up at the top.

// Cam1: standing on the side of the road, like a speed camera. The car drives past.
#declare Cam1 = camera { location <15, 1.3, -9>
                         look_at  <15, 1.0,  0>
                         angle 65
                         right x*image_width/image_height
                       }

// Cam2: drone shot high above the road, fixed. Nice to check the layout of the forest.
#declare Cam2 = camera { location <-40, 45, -60>
                         look_at  < 15,  0,  10>
                         angle 60
                         right x*image_width/image_height
                       }

// Cam3: the chase cam. It flies around the car on a circle while following it.
// At the start it's in front of the car, at the end it's behind it.
//   vrotate(<-dist,0,0>, y*angle) spins the offset vector around the car.
//   -150 deg = in front and to the left of the car, -30 deg = behind it.
#declare Cam_Angle  = -150 + 120 * (T*T*(3 - 2*T));      // smoothstep -> the swing starts and ends softly
#declare Cam_Dist   = 10.5 - 2.0 * sin(pi * T);          // comes a bit closer in the middle
#declare Cam_Height = 1.3 + 0.9 * sin(pi * T);          // and rises a bit for a better view over the car
#declare Cam_Pos    = Car_Pos + vrotate(<-Cam_Dist, 0, 0>, y * Cam_Angle) + <0, Cam_Height, 0>;
#declare Cam_Target = Car_Pos + <0.2, 0.75, 0>;

#declare Cam3 = camera { location Cam_Pos
                         look_at  Cam_Target
                         angle 48
                         right x*image_width/image_height
                         #if (Focal_Blur)
                             aperture 0.25
                             blur_samples 40
                             focal_point Cam_Target
                             confidence 0.95
                             variance 1/2000
                         #end
                       }

#switch (Cam_Select)
    #case (1) camera { Cam1 } #break
    #case (2) camera { Cam2 } #break
    #else     camera { Cam3 }
#end


//------------LIGHTING--------------------------------------------------------
// The sun. Low and warm = golden hour, that gives long shadows and makes
// everything look way more realistic than a white light straight above.
// It comes from the left behind the camera, so the side of the car we see is lit.
#declare Sun_Dir   = vnormalize(<-1.1, 0.55, -1.0>);
#declare Sun_Color = rgb <1.00, 0.86, 0.66>;

light_source {
    Sun_Dir * 100000
    color Sun_Color * 1.45
    #if (Soft_Shadows)
        // A real sun is not a point, so its shadows have soft edges.
        // area_light spreads the light over a small disc.
        area_light <1500, 0, 0>, <0, 0, 1500>, 5, 5
        adaptive 1
        jitter
        circular
        orient
    #end
}

// Fake sky light: a weak, bluish, shadowless light from above.
// Simulates the blue sky lighting up everything that's in the shadow.
// (That's why shadows outside always look a bit blue.)
#if (!Use_Radiosity)
    light_source {
        <0, 10000, 0>
        color rgb <0.45, 0.55, 0.75> * 0.35
        shadowless
    }
#end


//------------SKY-------------------------------------------------------------
// sky_sphere is the background at infinity. Pale and warm at the horizon,
// deep blue at the top.
sky_sphere {
    pigment {
        gradient y
        color_map {
            [0.00 rgb <0.95, 0.80, 0.62>]   // warm haze at the horizon
            [0.08 rgb <0.72, 0.78, 0.86>]
            [0.35 rgb <0.30, 0.47, 0.78>]
            [1.00 rgb <0.10, 0.22, 0.55>]   // deep blue straight up
        }
    }
}

// The clouds. Same idea as the bozo "horizon" plane of the original file, but
// now with see-through parts (the 't' in rgbt) so the blue sky shows between
// them. The whole layer drifts slowly with the clock.
plane { <0, 1, 0>, 1 hollow
    texture {
        pigment {
            bozo
            turbulence 0.85
            octaves 6
            lambda 2.5
            color_map {
                [0.00 rgbt <1, 1, 1, 1>]          // nothing
                [0.50 rgbt <1, 1, 1, 1>]
                [0.62 rgbt <1.0, 0.95, 0.88, 0.4>] // thin, lit by the sun
                [0.80 rgbt <1.0, 0.93, 0.85, 0.0>] // fluffy
                [1.00 rgbt <0.62, 0.62, 0.70, 0.0>] // shaded belly of the cloud
            }
            scale <1, 1, 1.6> * 0.9
            translate <T * 0.35, 0, T * 0.1>      // wind!
        }
        finish { ambient 0 emission 0.95 diffuse 0 }
    }
    scale 900
    no_shadow                                     // otherwise the clouds block the sun
}


//------------HAZE / FOG------------------------------------------------------
// Ground fog like in the original, but thinner and much bigger. It makes far
// away things fade into the sky colour (aerial perspective) - that's the main
// reason why the mountains look far away and not like a painted backdrop.
fog {
    fog_type   2                     // "ground fog": thick at the bottom, thinner higher up
    distance   1600
    color      rgb <0.80, 0.80, 0.84>
    fog_offset 0
    fog_alt    140
    turbulence 0.4
}


//------------GROUND----------------------------------------------------------
// Grass. Two layers of noise mixed together so it's not one flat green:
// big patches (sunny / dry / lush) plus the tiny bumps from the original.
plane { <0, 1, 0>, 0
    texture {
        pigment {
            bozo
            turbulence 0.6
            color_map {
                [0.0 rgb <0.10, 0.24, 0.03>]
                [0.4 rgb <0.17, 0.33, 0.05>]
                [0.7 rgb <0.26, 0.38, 0.08>]
                [1.0 rgb <0.36, 0.40, 0.14>]   // dry spots
            }
            scale 6
        }
        normal { bumps 0.25 scale 0.05 }
        finish { specular 0.05 roughness 0.1 }
    }
}


//------------MOUNTAINS-------------------------------------------------------
// A height_field is a grid where every point gets a height between 0 and 1.
// Instead of a picture I give it a function:
//   - f_ridged_mf is a noise that makes sharp ridges like real mountains
//   - Mountain_Ring makes a ring around the middle, so the valley itself
//     stays flat and the mountains surround us in every direction.
// x and y in here go from 0 to 1 over the whole grid.
#declare F_Ridges = function { f_ridged_mf(x*7, y*7, 0, 0.8, 2.1, 7, 0.9, 2.0, 2) }
#declare F_Dist   = function { sqrt(pow(x - 0.5, 2) + pow(y - 0.5, 2)) }
#declare Mountain_Ring = function { max(0, 1 - pow((F_Dist(x, y, 0) - 0.40) / 0.11, 2)) }

height_field {
    function 900, 900 { min(1, F_Ridges(x, y, 0) * 0.55 * Mountain_Ring(x, y, 0)) }
    smooth
    translate <-0.5, 0, -0.5>           // centre it on the origin
    scale <7000, 520, 7000>             // 7 km wide, peaks up to ~500 m
    translate <0, -2, 0>                // flat part sinks below the grass
    texture {
        // colour by height: forest -> rock -> snow
        pigment {
            gradient y
            turbulence 0.12
            color_map {
                [0.00 rgb <0.10, 0.20, 0.06>]
                [0.30 rgb <0.14, 0.22, 0.08>]
                [0.42 rgb <0.33, 0.30, 0.25>]
                [0.62 rgb <0.45, 0.42, 0.38>]
                [0.70 rgb <0.95, 0.96, 1.00>]   // snow line
                [1.00 rgb <1.00, 1.00, 1.00>]
            }
            scale 520
            translate -2*y
        }
        normal { granite 0.3 scale 40 }
        finish { diffuse 0.8 }
    }
}


//------------ROAD------------------------------------------------------------
#declare Road_Half = 3.5;                      // 7 m wide, two lanes
#declare Road_X0   = -400;
#declare Road_X1   =  600;

// Asphalt: dark grey with granite noise, slightly shiny because it's worn smooth.
#declare T_Asphalt = texture {
    pigment {
        granite
        color_map {
            [0.0 rgb 0.035]
            [0.6 rgb 0.055]
            [1.0 rgb 0.09]
        }
        scale 0.05
    }
    normal { granite 0.25 scale 0.03 }
    finish { specular 0.15 roughness 0.02 diffuse 0.8 }
}
#declare T_Paint_Line = texture {
    pigment { rgb 0.85 }
    finish  { specular 0.3 roughness 0.02 }
}

box { <Road_X0, -0.1, -Road_Half>, <Road_X1, 0.02, Road_Half> texture { T_Asphalt } }

// Gravel shoulder next to the road so it doesn't just end in the grass.
#declare T_Gravel = texture {
    pigment { granite color_map { [0 rgb <0.20, 0.18, 0.15>] [1 rgb <0.42, 0.39, 0.33>] } scale 0.1 }
    normal  { bumps 0.8 scale 0.03 }
}
box { <Road_X0, -0.1, -Road_Half - 0.8>, <Road_X1, 0.012, -Road_Half> texture { T_Gravel } }
box { <Road_X0, -0.1,  Road_Half>, <Road_X1, 0.012,  Road_Half + 0.8> texture { T_Gravel } }

// Markings. They're 1 mm above the asphalt, otherwise both surfaces are at the
// same height and POV-Ray flickers between them ("coincident surfaces").
union {
    // solid edge lines left and right
    box { <Road_X0, 0.02, -Road_Half + 0.15>, <Road_X1, 0.021, -Road_Half + 0.30> }
    box { <Road_X0, 0.02,  Road_Half - 0.30>, <Road_X1, 0.021,  Road_Half - 0.15> }

    // dashed centre line: 6 m line, 12 m gap (that's the real German rule)
    #declare DX = Road_X0;
    #while (DX < Road_X1)
        box { <DX, 0.02, -0.06>, <DX + 6, 0.021, 0.06> }
        #declare DX = DX + 18;
    #end
    texture { T_Paint_Line }
}

// Guide posts ("Leitpfosten") every 50 m on both sides, like on every German
// country road: white post, black band, reflector.
#declare Guide_Post = union {
    box { <-0.06, 0, -0.06>, <0.06, 1.0, 0.06> pigment { rgb 0.9 } }
    box { <-0.061, 0.72, -0.061>, <0.061, 0.94, 0.061> pigment { rgb 0.02 } }
    box { <-0.062, 0.80, -0.062>, <0.062, 0.86, 0.062>
          pigment { rgb <1.0, 0.45, 0.05> }
          finish { emission 0.3 specular 0.8 } }       // orange reflector
}
#declare GX = Road_X0;
#while (GX < Road_X1)
    object { Guide_Post translate <GX,      0, -Road_Half - 0.6> }
    object { Guide_Post translate <GX + 25, 0,  Road_Half + 0.6> }
    #declare GX = GX + 50;
#end


//------------FENCE-----------------------------------------------------------
// Old wooden fence on the forest side of the road. Posts every 2.5 m and two
// rails. Each post is tilted a tiny random bit, a perfectly straight fence
// looks fake.
#declare R_Fence = seed(42);
#declare T_Wood = texture {
    pigment {
        wood
        turbulence 0.1
        color_map { [0 rgb <0.30, 0.20, 0.12>] [0.5 rgb <0.42, 0.30, 0.19>] [1 rgb <0.26, 0.17, 0.10>] }
        scale 0.04
        rotate x*90
    }
    normal { wood 0.3 scale 0.04 rotate x*90 }
}
union {
    #declare FX = -150;
    #while (FX < 250)
        cylinder { <0, -0.2, 0>, <0, 1.15, 0>, 0.06
                   rotate <(rand(R_Fence) - 0.5) * 6, rand(R_Fence) * 90, (rand(R_Fence) - 0.5) * 6>
                   translate <FX, 0, 5.8> }
        #declare FX = FX + 2.5;
    #end
    cylinder { <-150, 0.55, 5.75>, <250, 0.55, 5.75>, 0.035 }
    cylinder { <-150, 0.95, 5.75>, <250, 0.95, 5.75>, 0.035 }
    texture { T_Wood }
}


//------------SIGN------------------------------------------------------------
// Custom touch: a sign welcoming you to the valley.
#declare Valley_Sign = union {
    // two posts
    cylinder { <-1.1, 0, 0>, <-1.1, 2.6, 0>, 0.05 texture { Chrome_Metal } }
    cylinder { < 1.1, 0, 0>, < 1.1, 2.6, 0>, 0.05 texture { Chrome_Metal } }
    // the green board with white border
    box { <-1.45, 1.4, -0.03>, <1.45, 2.7, 0.0>  pigment { rgb 0.9 } }
    box { <-1.38, 1.47, -0.035>, <1.38, 2.63, -0.029> pigment { rgb <0.0, 0.32, 0.16> } }
    // the text (fonts come with POV-Ray, so this works on the school PC too)
    text { ttf "cyrvetic.ttf" "POV-Ray Valley" 0.01, 0
           scale 0.36 translate <-1.23, 2.17, -0.04> pigment { rgb 0.95 } }
    text { ttf "cyrvetic.ttf" "drive safe :)" 0.01, 0
           scale 0.26 translate <-0.8, 1.68, -0.04> pigment { rgb 0.95 } }
    finish { specular 0.2 }
}
object { Valley_Sign rotate y*-15 translate <38, 0, Road_Half + 1.4> }


//------------TREES-----------------------------------------------------------
// In the original I built a tree from three cones and then placed 34 of them
// by hand. Now there are two kinds of trees and a loop plants them randomly.

#declare T_Bark = texture {
    pigment { bozo color_map { [0 rgb <0.16, 0.10, 0.06>] [1 rgb <0.27, 0.19, 0.12>] } scale <0.05, 0.4, 0.05> }
    normal  { bumps 0.9 scale <0.03, 0.2, 0.03> }
}

// Needle texture. Wrinkles make it look like there are branches in the cone.
#macro T_Needles(Col)
    texture {
        pigment { wrinkles color_map { [0 Col * 0.45] [0.6 Col] [1 Col * 1.3] } scale 0.35 }
        normal  { wrinkles 1.2 scale 0.25 }
        finish  { diffuse 0.75 specular 0.02 }
    }
#end

// Pine tree: trunk + 5 cones. Each cone is smaller and higher (same idea
// as my 3-cone tree, just more layers, so it looks way less like a traffic cone).
#macro Pine(Col)
    union {
        cylinder { 0, y * 3, 0.16 texture { T_Bark } }
        #local L = 0;
        #while (L < 5)
            #local H0 = 1.0 + L * 1.2;                  // bottom of this layer
            #local Rd = 2.0 * (1 - L * 0.16);           // width of this layer
            cone { <0, H0, 0>, Rd, <0, H0 + 3.0, 0>, 0.05
                   T_Needles(Col)
                   rotate y * L * 37 }                  // rotate each layer so the texture doesn't line up
            #local L = L + 1;
        #end
    }
#end

// Leafy tree: trunk + a "blob" of spheres for the crown. A blob melts
// spheres together into one soft shape, looks much more like a crown than
// a single sphere.
#macro Leafy(Col, S)
    #local R = seed(S);
    union {
        cone { 0, 0.28, y * 4.5, 0.12 texture { T_Bark } }
        blob {
            threshold 0.5
            #local k = 0;
            #while (k < 9)
                sphere { <(rand(R) - 0.5) * 3.2, 4.8 + rand(R) * 2.6, (rand(R) - 0.5) * 3.2>, 2.2, 1 }
                #local k = k + 1;
            #end
            texture {
                pigment { granite turbulence 0.3 color_map { [0 Col * 0.5] [0.5 Col] [1 Col * 1.4] } scale 0.8 }
                normal  { granite 1.4 scale 0.25 }
                finish  { diffuse 0.8 }
            }
        }
    }
#end

// Build a few variants ONCE and then reuse them. Copies of a declared object
// are cheap, building a new one for every single tree would make parsing slow.
#declare Pine1  = Pine(rgb <0.05, 0.18, 0.06>)
#declare Pine2  = Pine(rgb <0.07, 0.22, 0.08>)
#declare Pine3  = Pine(rgb <0.06, 0.16, 0.10>)
#declare Leafy1 = Leafy(rgb <0.16, 0.30, 0.06>, 11)
#declare Leafy2 = Leafy(rgb <0.24, 0.33, 0.07>, 22)
#declare Leafy3 = Leafy(rgb <0.38, 0.30, 0.08>, 33)   // one is already turning autumn-ish

// Planting. The seed stays the same, so every frame gets the SAME forest.
// (With a different seed per frame all trees would jump around every frame.)
#declare R_Trees = seed(2026);
#declare i = 0;
#while (i < Tree_Count)
    #declare TX = -220 + rand(R_Trees) * 520;

    // 80 % of the trees go into the forest behind the fence (+z side),
    // the rest are scattered on the meadow on the far side (-z side),
    // far enough away that they don't end up in front of the camera.
    #if (rand(R_Trees) < 0.8)
        #declare TZ = 8 + pow(rand(R_Trees), 2.2) * 160;   // pow() pushes most trees close to the fence
    #else
        #declare TZ = -22 - rand(R_Trees) * 140;
    #end

    #declare Kind = rand(R_Trees);
    #declare Sc   = 0.75 + rand(R_Trees) * 0.7;           // 75 % to 145 % size
    #declare Rot  = rand(R_Trees) * 360;

    object {
        #if     (Kind < 0.22) Pine1
        #elseif (Kind < 0.44) Pine2
        #elseif (Kind < 0.62) Pine3
        #elseif (Kind < 0.78) Leafy1
        #elseif (Kind < 0.92) Leafy2
        #else                 Leafy3
        #end
        scale Sc
        rotate y * Rot
        translate <TX, 0, TZ>
    }
    #declare i = i + 1;
#end


//------------BIRDS-----------------------------------------------------------
// A small flock flying over the valley. Each bird is two thin triangles
// (the wings). The wing tips go up and down with a sine wave -> flapping.
#macro Bird(Flap)
    union {
        triangle { <0, 0, 0>, < 0.25, 0, 0>, <-0.05, Flap * 0.5, 0.9> }
        triangle { <0, 0, 0>, < 0.25, 0, 0>, <-0.05, Flap * 0.5, -0.9> }
        sphere   { <0.1, 0, 0>, 0.09 scale <2.2, 1, 1> }
        pigment { rgb 0.03 }
        no_shadow
    }
#end

#declare Flock_Pos = <-40 + 160 * T, 32 + 3 * sin(T * pi * 2), 55 - 20 * T>;
#declare b = 0;
#while (b < 7)
    // V formation: every bird sits a bit further back and to the side
    #declare Side = (mod(b, 2) = 0 ? 1 : -1) * ceil(b / 2);
    #declare Off  = <-abs(Side) * 2.2, sin(b * 1.7) * 0.4, Side * 2.0>;
    // everyone flaps at the same speed but with a different phase
    #declare Flap = sin(T * 2 * pi * 14 + b * 1.3);
    object { Bird(Flap) scale 0.9 rotate y * -8 translate Flock_Pos + Off }
    #declare b = b + 1;
#end


//------------------------------------------------------------------------------
// OBJECT CLASSES - THE CAR
//------------------------------------------------------------------------------
// The car is built at the origin, facing +x, with the tyres standing on y = 0.
// Later it's moved to Car_Pos as a whole.
//   length 4.3 m   width 1.8 m   height ~1.42 m

// Metallic paint with rally stripes. gradient z makes stripes along the car
// (on the hood, roof and trunk); on the sides z is constant so they stay red.
#declare T_Car_Paint = texture {
    pigment {
        gradient z
        color_map {
            [0.000 rgb <0.55, 0.02, 0.02>]
            [0.425 rgb <0.55, 0.02, 0.02>]
            [0.425 rgb 0.92]
            [0.465 rgb 0.92]
            [0.465 rgb <0.55, 0.02, 0.02>]
            [0.535 rgb <0.55, 0.02, 0.02>]
            [0.535 rgb 0.92]
            [0.575 rgb 0.92]
            [0.575 rgb <0.55, 0.02, 0.02>]
            [1.000 rgb <0.55, 0.02, 0.02>]
        }
        scale 1.8
        translate -0.9 * z
    }
    finish {
        ambient 0.02
        diffuse 0.65
        specular 0.9 roughness 0.003     // tight highlight = clear coat
        reflection { 0.06, 0.35 }        // more reflective at flat angles, like real paint
        metallic 0.4
    }
}

#declare T_Car_Glass = texture {
    pigment { rgb <0.015, 0.02, 0.03> }            // dark tinted glass
    finish  { ambient 0 diffuse 0.1 specular 1 roughness 0.001 reflection { 0.12, 0.6 } }
}

#declare T_Black_Plastic = texture {
    pigment { rgb 0.02 }
    finish  { specular 0.2 roughness 0.05 }
}

#declare T_Rubber = texture {
    pigment { rgb 0.025 }
    normal  { bumps 0.2 scale 0.01 }
    finish  { specular 0.05 roughness 0.2 }
}

// Side profile of the lower body (x = length, second value = height).
// prism builds this outline in the x-z plane and extrudes it, then I rotate
// it upright. The first point is repeated at the end to close the shape.
#declare Body_Shape = prism {
    linear_sweep
    -0.9, 0.9, 12
    <-2.10, 0.30>,     // rear bottom
    < 2.02, 0.30>,     // front bottom
    < 2.15, 0.42>,
    < 2.18, 0.60>,     // front bumper
    < 2.10, 0.78>,     // top of the nose
    < 0.95, 0.96>,     // base of the windshield
    <-1.60, 0.99>,     // base of the rear window
    <-2.02, 0.95>,     // spoiler lip
    <-2.15, 0.80>,
    <-2.18, 0.55>,     // rear bumper
    <-2.15, 0.36>,
    <-2.10, 0.30>
    rotate -90 * x      // the prism's z-values become the heights
}

// Upper part (glasshouse): windshield, roof, rear window.
#declare Cabin_Shape = prism {
    linear_sweep
    -0.74, 0.74, 5
    < 1.00, 0.95>,     // windshield bottom
    < 0.02, 1.42>,     // windshield top / roof front
    <-0.95, 1.42>,     // roof back
    <-1.70, 0.97>,     // rear window bottom
    < 1.00, 0.95>
    rotate -90 * x
}

// Wheel: tyre (torus) + 5-spoke rim. It's built lying around the z-axis so it
// can spin with "rotate z".
#declare Wheel = union {
    torus { 0.24, 0.10 rotate x * 90 scale <1, 1, 1.15> texture { T_Rubber } }
    union {
        cylinder { <0, 0, -0.085>, <0, 0, 0.085>, 0.155 }             // rim barrel
        difference {                                                   // rim lip
            cylinder { <0, 0, -0.10>, <0, 0, 0.10>, 0.20 }
            cylinder { <0, 0, -0.11>, <0, 0, 0.11>, 0.17 }
        }
        #local s = 0;
        #while (s < 5)
            box { <-0.02, 0, -0.105>, <0.02, 0.18, 0.105> rotate z * s * 72 }   // spokes
            #local s = s + 1;
        #end
        cylinder { <0, 0, -0.11>, <0, 0, 0.11>, 0.045 }               // hub cap
        texture { Polished_Chrome }
    }
}

// Headlight: chrome bowl with a glowing lens.
#declare Headlight = union {
    sphere { 0, 0.1 scale <0.4, 0.75, 1.5> texture { Polished_Chrome } }
    sphere { 0, 0.09 scale <0.45, 0.7, 1.4> translate x * 0.02
             pigment { rgb <1, 0.97, 0.88> } finish { emission 1.2 } }
}

#declare Taillight = box { <-0.02, -0.06, -0.22>, <0.02, 0.06, 0.22>
                           pigment { rgb <0.9, 0.02, 0.01> }
                           finish { emission 0.7 specular 0.8 roughness 0.01 } }

// License plate. Custom text!
#declare Plate = union {
    box { <-0.01, -0.06, -0.26>, <0.01, 0.06, 0.26> pigment { rgb 0.95 } }
    box { <-0.012, -0.06, 0.21>, <0.012, 0.06, 0.26> pigment { rgb <0.05, 0.15, 0.6> } }  // blue EU strip
    text { ttf "cyrvetic.ttf" "MOV 360" 0.01, 0
           scale 0.1 rotate y * 90 translate <-0.015, -0.035, 0.19> pigment { rgb 0.02 } }   // rotate +90, with -90 the text came out mirrored
}

#declare Mirror = union {
    box { <-0.05, -0.05, 0>, <0.08, 0.05, 0.16> texture { T_Car_Paint } }
    box { <-0.052, -0.04, 0.02>, <-0.05, 0.04, 0.15> texture { Polished_Chrome } }
    box { <0.0, -0.08, -0.18>, <0.06, -0.03, 0.01> texture { T_Black_Plastic } }   // arm to the door, otherwise it floats
}

#declare Car = union {
    // body with the wheel arches cut out
    difference {
        object { Body_Shape }
        cylinder { <1.35, Wheel_R, -1>, <1.35, Wheel_R, 1>, 0.42 }
        cylinder { <-1.35, Wheel_R, -1>, <-1.35, Wheel_R, 1>, 0.42 }
        texture { T_Car_Paint }
    }

    // glasshouse with a painted roof on top
    object { Cabin_Shape texture { T_Car_Glass } }
    intersection {
        object { Cabin_Shape scale <1.005, 1, 1.02> }
        plane { -y, -1.37 }                           // keep only everything above y = 1.37
        texture { T_Car_Paint }
    }
    // B-pillar (between front and back windows)
    box { <-0.42, 0.98, -0.745>, <-0.32, 1.40, 0.745> texture { T_Car_Paint } }

    // black plastic trim: side skirts and the grille
    box { <-1.0, 0.30, -0.905>, <0.95, 0.40, 0.905> texture { T_Black_Plastic } }
    box { < 2.12, 0.45, -0.45>, <2.19, 0.58, 0.45> texture { T_Black_Plastic } }

    // lights
    object { Headlight translate < 2.10, 0.68, -0.62> }
    object { Headlight translate < 2.10, 0.68,  0.62> }
    object { Taillight translate <-2.16, 0.82, -0.62> }
    object { Taillight translate <-2.16, 0.82,  0.62> }

    object { Plate translate <-2.19, 0.62, 0> }
    object { Plate rotate y * 180 translate <2.19, 0.40, 0> }

    object { Mirror translate <0.75, 1.02, 0.90> }
    object { Mirror scale <1, 1, -1> translate <0.75, 1.02, -0.90> }

    // exhaust pipe
    cylinder { <-2.0, 0.34, 0.5>, <-2.25, 0.34, 0.5>, 0.04 open texture { Polished_Chrome } }
}


// ----objects in the scene ----------------------------------------------------
// Put it all together: the body bobs and pitches a bit, the wheels spin by
// Wheel_Spin degrees, and the whole thing drives along the road.
union {
    object { Car rotate z * Body_Pitch translate y * Body_Bob }

    object { Wheel rotate z * -Wheel_Spin translate < 1.35, Wheel_R,  0.80> }
    object { Wheel rotate z * -Wheel_Spin translate < 1.35, Wheel_R, -0.80> }
    object { Wheel rotate z * -Wheel_Spin translate <-1.35, Wheel_R,  0.80> }
    object { Wheel rotate z * -Wheel_Spin translate <-1.35, Wheel_R, -0.80> }

    translate Car_Pos
}

//------------------------------------- end
