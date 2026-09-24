global_settings{assumed_gamma 1.0}                   //defaults for direct/indirect lighting
#default{ finish{ ambient 0.1 diffuse 0.9 }}


//-----------INCLUDES-------------------------------
#include "colors.inc"
#include "textures.inc"


//-----------CAMERA-----------------------
#declare Cam1 = camera { location<-6,1,0.25>
                         look_at <0,1,0.25>
                        }

#declare Cam2 = camera { 
                         ultra_wide_angle angle 180 
                         location<2,4,-2>
                         look_at <0,1,0>      
                         }

#declare Cam3 = camera { location<0,0.5,-1.5>
                         look_at <0.5,0,0.1875>
                         sky <1,1,1>
                        }

camera{Cam3}                                        // To quickly change cameras just exchange 1 for 2 here


//------------LIGHTING-------------------------
#declare Light1 = light_source {    <1500,3000,-2500> 
                                    color White 
                               }

#declare Light2 = light_source {    <0,2,-1> 
                                    color White 
                                }


#declare Light3 = light_source {    <0,2,-1> 
                                    color White
                                    shadowless
                                }

#declare Light4 = light_source  {<0,2,1> 
                                    color White*0.7
                                        looks_like{
                                            sphere{ <0,0,0>,0.5
                                                texture{
                                                    pigment{color White}
                                                    finish {ambient 0.9
                                                    diffuse 0.1
                                                    phong 1}
                                                } // end texture
                                            } // end of sphere
                                        } //end of looks_like
                                } //end of light_source


light_source{Light3}


//------------HORIZON-------------------------
plane{ <0,1,0>,1 hollow
       texture{
         pigment{ bozo turbulence 0.92
           color_map{
                 [0.00 rgb<0.05,0.15,0.45>]
                 [0.50 rgb<0.05,0.15,0.45>]
                 [0.70 rgb<1,1,1>        ]
                 [0.85 rgb<0.2,0.2,0.2>  ]
                 [1.00 rgb<0.5,0.5,0.5>  ]
                       } //
           scale<1,1,1.5>*2.5
           translate<0,0,0>
           } // end of pigment
         finish {ambient 1 diffuse 0}
        } // end of texture
       scale 10000}


//--------------FOG---------------------
fog { fog_type   2                                  //fog on the ground
      distance   50
      color      rgb<1,1,1>*0.8
      fog_offset 0.5
      fog_alt    1.5
      turbulence 1.8
    } //
//------------GROUND----------------------
plane{ <0,1,0>, 0
       texture{
          pigment{ color rgb<0.22,0.45,0>}
          normal { bumps 0.75 scale 0.015 }
          finish { phong 0.1 }
       } // end of texture
     } // end of plane 
     
//------------------------------------------
// objectclasses ------------------------

#declare sphere1 = sphere{ <0.5,0,0>, 0.75
                            texture{
                                pigment{ color rgb<0.9,0.55,0>}
                                finish { phong 1 }
                            } // end of texture
                    } // end of sphere
      
#declare cone1  =   cone {
                        <-2, 0, 2>, 1
                        <-2, 2, 2>, 0
                        pigment {color ForestGreen}
                        }
              
              
#declare tree  =   merge {                                  //I combined the cone form three times to form a tree. The upper levels are scaled down.The position was adjusted using translate.

                        cone{cone1}

                        cone{cone1
                            translate <-0.45, 0.8 ,0.4>
                            scale 0.8}

                        cone{cone1
                        translate <-1.05, 1.8 ,1.1>
                        scale 0.64}
                          }


#declare torus1 = torus {1, 0.25
                             pigment {color Black}
                             translate <0.85,2,0>
                             rotate <90,0,90>
                             scale 0.1
                             }

#declare box1 =   box {
                        <0, 0, 0>
                        <1, 1, 1>
                        pigment {color Gray}
                        } 
 
// ----objects in the scene ------------------------
      
//sphere{sphere1   translate <0.85*clock, 1.1,0> }

torus {torus1    translate <1*clock, 0, -0.5>}                 //Here I create a car using the torus template as wheels                             

torus {torus1       translate <1,0,0>
                    translate <1*clock, 0,-0.5>}                              


torus {torus1       translate <0,0,0.375>
                    translate <1*clock, 0,-0.5>}                              

torus {torus1       translate <1,0,0.375>
                    translate <1*clock, 0,-0.5>} 


box {box1                                                   //This is my car's body
                translate       <-0.05,1,0.25>
                scale           <1,0.2,0.5>
                pigment         {color Orange}
                translate <1*clock, 0,-0.5>                
     }

box {box1       scale          <30,0.01,1>                  //This is my road
                translate      <-6,0,-0.6>
    }

object {tree translate <2,0,0>}                             //Here I create a whole forest
object {tree translate <4,0,0>}
object {tree translate <6,0,0>}
object {tree translate <8,0,0>}
object {tree translate <10,0,0>}
object {tree translate <12,0,0>}
object {tree translate <14,0,0>}
object {tree translate <16,0,0>}

object {tree translate <1,0,2>}
object {tree translate <3,0,2>}
object {tree translate <5,0,2>}
object {tree translate <7,0,2>}
object {tree translate <9,0,2>}
object {tree translate <11,0,2>}
object {tree translate <13,0,2>}
object {tree translate <15,0,2>}
object {tree translate <17,0,2>}

object {tree translate <2,0,-6>}                          
object {tree translate <4,0,-6>}
object {tree translate <6,0,-6>}
object {tree translate <8,0,-6>}
object {tree translate <10,0,-6>}
object {tree translate <12,0,-6>}
object {tree translate <14,0,-6>}
object {tree translate <16,0,-6>}

object {tree translate <1,0,-4>}
object {tree translate <3,0,-4>}
object {tree translate <5,0,-4>}
object {tree translate <7,0,-4>}
object {tree translate <9,0,-4>}
object {tree translate <11,0,-4>}
object {tree translate <13,0,-4>}
object {tree translate <15,0,-4>}
object {tree translate <17,0,-4>}









      
//------------------------------------- end