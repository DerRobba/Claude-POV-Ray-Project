// movement.pov - Männchen joggt 4 s nach Hause ~ Malte

#version 3.7; // Sagt POV-Ray welche Version

// Hier sind so Schalter
#ifndef (Weiche_Schatten) #declare Weiche_Schatten = 1; #end   // Wenn die Variablen noch nicht in einer INI etc. definiert wurden, werden die Variablen hier gesetzt.
#ifndef (Kamera_Wahl)     #declare Kamera_Wahl     = 1; #end   // 1 = die normale Kamera die mitfährt
#ifndef (Baum_Anzahl)     #declare Baum_Anzahl     = 260; #end // Wie viele Bäume zufällig rumgepflanzt werden


global_settings {
    assumed_gamma 1.0 // Hier gibt es eine gesetzte Helligkeit, Herr Berners das auch so machte. ~ Definitiv nicht Claude (Nein, ernsthaft nicht.)
    max_trace_level 8 // Begrenzt wie oft ein einzelner Lichtstrahl verfolgt wird
}

// Es werde Licht damit die Schatten nicht zu schattig sind oder so
// In echt kommt da Licht vom blauen Himmel an, das faked Claude hiermit
#default { finish { ambient 0.06 diffuse 0.85 } }


//-----------INCLUDES---------------------------------------------------------
#include "colors.inc"
#include "textures.inc"
#include "functions.inc"        // fuer die Rausch-Funktion der Berge ; Malte hier, die Berge haben eine Rausch-Funktion? Naja, finden wir bald raus.



// Ah, das ist was Claude mit Zeit wird in Sekunden umgerechnet 
#declare Dauer    = 4;                       // Länge der Animation in Sekunden
#declare Sekunden = clock * Dauer; // Hier wird das ganze dann in Sekunden umgerechnet. Wieso genau schauen wir dann unten.


// Die ganze Geschichte ist basically Anti-Aliasing aber für Schatten.
#declare Weich = function(Wert, A, B) {
    select(Wert - A, 0,
        select(Wert - B,
            ((Wert - A) / (B - A)) * ((Wert - A) / (B - A)) * (3 - 2 * (Wert - A) / (B - A)),
        1))
}


//-----------DER WEG----------------------------------------------------------
// Und hier ist das "wieso": Spline = bei Sekunde X ist sie da, POV-Ray macht die Kurve dazwischen
#declare Weg = spline {
    natural_spline
    -0.5, <-6.40, 0, 0.90>
     0.0, <-5.20, 0, 1.60>      // Start
     0.5, <-3.96, 0, 2.31>
     1.0, <-2.89, 0, 3.26>
     1.5, <-2.00, 0, 4.38>
     2.0, <-1.27, 0, 5.62>
     2.5, <-0.71, 0, 6.93>
     3.0, <-0.32, 0, 8.31>
     3.5, <-0.08, 0, 9.72>
     4.0, < 0.00, 0, 11.15>     // Ende
     4.5, < 0.00, 0, 12.60>
}

#declare Figur_Pos = Weg(Sekunden); // Wo sie gerade ist

// Wohin guckt sie? Man nimmt einen Punkt kurz vorher und kurz nachher auf dem
#declare Richtung   = Weg(Sekunden + 0.05) - Weg(Sekunden - 0.05);
#declare Figur_Dreh = degrees(atan2(Richtung.x, Richtung.z));

// Laufen
#declare Tempo      = 2.865;                        // m/s
#declare Schrittlaenge = 1.0;                       // 1 m pro Schritt
#declare Phase      = Sekunden * Tempo / (2 * Schrittlaenge) * 360;

#declare Bein_Schwung = 30;                         // So weit gehen die Beine vor und zurück
#declare Arm_Schwung  = 35;                         // Und die Arme

// Wenn das Bein schräg ist
#declare Bein_Winkel = Bein_Schwung * sin(radians(Phase));
#declare Wippen      = 0.92 * (cos(radians(Bein_Winkel)) - 1)
                     + 0.035 * abs(sin(radians(Phase)));


//-----------KAMERA-----------------------------------------------------------
// Kamera 1 fährt langsam mit und dreht sich dabei immer mehr zum Haus,
#declare Kamera_Pos = <-1.6, 1.55, -4.2> + <4.2, 0.9, 4.4> * Weich(Sekunden, 0, 4);

// Wo die Kamera hinguckt
#declare Blick_Mix  = 0.55 * Weich(Sekunden, 1.0, 4.0);
#declare Kamera_Ziel = (Figur_Pos + <0, 1.1, 0>) * (1 - Blick_Mix) + <0, 2.6, 13> * Blick_Mix;

#declare Kamera1 = camera {
    location Kamera_Pos
    look_at  Kamera_Ziel
    angle 55                                   // Wie viel man sieht
    right x * image_width / image_height       // Damit nichts gestaucht ist bei 16:9
}

// Kamera 2
#declare Kamera2 = camera {
    location <-18, 22, -14>
    look_at  <-1, 0, 6>
    angle 60
    right x * image_width / image_height
}

// Kamera 3
#declare Kamera3 = camera {
    location Figur_Pos + vrotate(<3.2, 1.0, 0>, y * Figur_Dreh)
    look_at  Figur_Pos + <0, 0.9, 0>
    angle 40
    right x * image_width / image_height
}

// Hier wird dann die Kamera genommen die oben bei Kamera_Wahl steht
#if (Kamera_Wahl = 2)
    camera { Kamera2 }
#elseif (Kamera_Wahl = 3)
    camera { Kamera3 }
#else
    camera { Kamera1 }
#end


//-----------LICHT------------------------------------------------------------
// Die Sonne! Also die Lichtquelle am Himmel aus der Aufgabe.
#declare Sonne_Pos = <-4000, 4300, -3200>;

light_source {
    Sonne_Pos
    color rgb <1.00, 0.90, 0.74> * 1.4
    #if (Weiche_Schatten)
        // Die echte Sonne ist ja kein Punkt sondern eine Scheibe
        area_light <120, 0, 0>, <0, 0, 120>, 5, 5
        adaptive 1
        jitter
        circular
        orient
    #end
    // looks_like
    looks_like { sphere { 0, 90 pigment { rgb <1, 0.95, 0.8> } finish { emission 1 diffuse 0 } } }
}

// Schwaches blaues Licht von oben ohne Schatten
light_source {
    <0, 10000, 0>
    color rgb <0.45, 0.55, 0.75> * 0.3
    shadowless
}

// Licht im Haus
light_source {
    <0, 2.4, 14.5>
    color rgb <1.0, 0.72, 0.42> * 2.2
    fade_distance 2
    fade_power 2
}


//-----------HIMMEL-----------------------------------------------------------
// Himmelskugel
sky_sphere {
    pigment {
        gradient y
        color_map {
            [0.00 rgb <0.95, 0.82, 0.66>]   // Horizont
            [0.10 rgb <0.70, 0.78, 0.88>]
            [0.35 rgb <0.30, 0.48, 0.80>]
            [1.00 rgb <0.10, 0.22, 0.55>]   // ganz oben
        }
    }
}

// Wolken
plane { <0, 1, 0>, 1 hollow
    texture {
        pigment {
            bozo
            turbulence 0.85
            octaves 6
            lambda 2.5
            color_map {
                [0.00 rgbt <1, 1, 1, 1>]              // komplett durchsichtig = keine Wolke
                [0.50 rgbt <1, 1, 1, 1>]
                [0.62 rgbt <1.0, 0.96, 0.90, 0.4>]    // bisschen Wolke
                [0.80 rgbt <1.0, 0.94, 0.86, 0.0>]    // richtige Wolke
                [1.00 rgbt <0.62, 0.62, 0.70, 0.0>]   // dunkler Wolkenbauch
            }
            scale <1, 1, 1.6> * 0.9
            translate <Sekunden * 0.02, 0, 0>          // Wind
        }
        finish { ambient 0 emission 0.95 diffuse 0 }
    }
    scale 900
    no_shadow            // Sonst blockieren die Wolken die Sonne und alles ist Schatten
}

// Nebel wie in der Vorlage
fog {
    fog_type   2         // Bodennebel
    distance   1400
    color      rgb <0.80, 0.81, 0.85>
    fog_offset 0
    fog_alt    120
    turbulence 0.4
}


//-----------BODEN------------------------------------------------------------
// Wiese
plane { <0, 1, 0>, 0
    texture {
        pigment {
            bozo
            turbulence 0.6
            color_map {
                [0.0 rgb <0.10, 0.24, 0.03>]
                [0.4 rgb <0.17, 0.33, 0.05>]
                [0.7 rgb <0.26, 0.38, 0.08>]
                [1.0 rgb <0.36, 0.40, 0.14>]   // trockene Stellen
            }
            scale 4
        }
        normal { bumps 0.3 scale 0.04 }
        finish { specular 0.05 roughness 0.1 }
    }
}

// Der Trampelpfad
#declare Pfad_Textur = texture {
    pigment {
        granite
        color_map {
            [0.0 rgb <0.22, 0.16, 0.10>]
            [0.5 rgb <0.33, 0.25, 0.16>]
            [1.0 rgb <0.42, 0.34, 0.24>]
        }
        scale 0.3
    }
    normal { bumps 0.5 scale 0.05 }
}
union {
    #declare Zeit = -3;
    #while (Zeit < 3.95)
        #declare P = Weg(Zeit);
        // Breite ändert sich bisschen
        cylinder { P, P + <0, 0.003, 0>, 0.55 + 0.1 * sin(Zeit * 7) }
        #declare Zeit = Zeit + 0.04;
    #end
    texture { Pfad_Textur }
}

// Blumen
#declare Z_Blumen = seed(7);
#declare Blumen_Farben = array[4] { rgb <0.9, 0.85, 0.2>, rgb <0.95, 0.95, 0.95>, rgb <0.7, 0.2, 0.6>, rgb <0.9, 0.3, 0.1> } // gelb
union {
    #declare i = 0;
    #while (i < 700)
        #declare BX = -14 + rand(Z_Blumen) * 24;
        #declare BZ = -4  + rand(Z_Blumen) * 16;
        #declare Farbe = Blumen_Farben[floor(rand(Z_Blumen) * 3.999)];
        // Grob gucken wie weit die Blume vom Weg weg ist
        #if (abs(BX - Weg(min(4, max(0, (BZ - 1.6) / 9.55 * 4))).x) > 0.9)
            sphere { <BX, 0.05, BZ>, 0.018 pigment { Farbe } }
        #end
        #declare i = i + 1;
    #end
    no_shadow
}


//-----------BERGE------------------------------------------------------------
// So
#declare F_Grate    = function { f_ridged_mf(x*7, y*7, 0, 0.8, 2.1, 7, 0.9, 2.0, 2) }
#declare F_Abstand  = function { sqrt(pow(x - 0.5, 2) + pow(y - 0.5, 2)) }       // Abstand zur Mitte
#declare Berg_Ring  = function { max(0, 1 - pow((F_Abstand(x, y, 0) - 0.40) / 0.11, 2)) }

height_field {
    function 700, 700 { min(1, F_Grate(x, y, 0) * 0.55 * Berg_Ring(x, y, 0)) }
    smooth
    translate <-0.5, 0, -0.5>            // In die Mitte schieben
    scale <6000, 480, 6000>              // 6 km breit
    translate <0, -2, 0>                 // Der flache Teil geht unter die Wiese
    texture {
        pigment {                        // Farbe nach Höhe: Wald
            gradient y
            turbulence 0.12
            color_map {
                [0.00 rgb <0.10, 0.20, 0.06>]
                [0.30 rgb <0.14, 0.22, 0.08>]
                [0.42 rgb <0.33, 0.30, 0.25>]
                [0.62 rgb <0.45, 0.42, 0.38>]
                [0.70 rgb <0.95, 0.96, 1.00>]   // ab hier Schnee
                [1.00 rgb <1.00, 1.00, 1.00>]
            }
            scale 480
            translate -2 * y
        }
        normal { granite 0.3 scale 40 }
    }
}


//-----------BÄUME------------------------------------------------------------
// Rinde
#declare Rinde = texture {
    pigment { bozo color_map { [0 rgb <0.16, 0.10, 0.06>] [1 rgb <0.27, 0.19, 0.12>] } scale <0.05, 0.4, 0.05> }
    normal  { bumps 0.9 scale <0.03, 0.2, 0.03> }
}

// Tanne
#macro Tanne(Farbe)
    union {
        cylinder { 0, y * 3, 0.16 texture { Rinde } }
        #local Stufe = 0;
        #while (Stufe < 5)
            cone { <0, 1.0 + Stufe * 1.2, 0>, 2.0 * (1 - Stufe * 0.16), <0, 4.0 + Stufe * 1.2, 0>, 0.05
                   texture {
                       pigment { wrinkles color_map { [0 Farbe * 0.45] [0.6 Farbe] [1 Farbe * 1.3] } scale 0.35 }
                       normal  { wrinkles 1.2 scale 0.25 }
                   }
                   rotate y * Stufe * 37 }       // Jede Stufe bisschen gedreht
            #local Stufe = Stufe + 1;
        #end
    }
#end

// Laubbaum
#macro Laubbaum(Farbe, Startwert)
    #local Z = seed(Startwert);
    union {
        cone { 0, 0.28, y * 4.5, 0.12 texture { Rinde } }
        blob {
            threshold 0.5
            #local k = 0;
            #while (k < 9)
                sphere { <(rand(Z) - 0.5) * 3.2, 4.8 + rand(Z) * 2.6, (rand(Z) - 0.5) * 3.2>, 2.2, 1 }
                #local k = k + 1;
            #end
            texture {
                pigment { granite turbulence 0.3 color_map { [0 Farbe * 0.5] [0.5 Farbe] [1 Farbe * 1.4] } scale 0.8 }
                normal  { granite 1.4 scale 0.25 }
            }
        }
    }
#end

// Jede Sorte wird nur EINMAL gebaut und dann kopiert
#declare Tanne1 = Tanne(rgb <0.05, 0.18, 0.06>)
#declare Tanne2 = Tanne(rgb <0.07, 0.22, 0.08>)
#declare Laub1  = Laubbaum(rgb <0.16, 0.30, 0.06>, 11)
#declare Laub2  = Laubbaum(rgb <0.24, 0.33, 0.07>, 22)
#declare Laub3  = Laubbaum(rgb <0.40, 0.30, 0.08>, 33)   // Der wird schon herbstlich

// Die hier stehen per Hand direkt am Weg
object { Laub1  scale 0.9  rotate y * 30  translate <-7.5, 0,  5.0> }
object { Tanne1 scale 1.0  rotate y * 10  translate <-4.6, 0,  7.2> }
object { Laub2  scale 0.8  rotate y * 200 translate < 3.2, 0,  4.8> }
object { Tanne2 scale 0.85 rotate y * 80  translate < 4.2, 0,  1.0> }
object { Laub3  scale 0.75 rotate y * 120 translate <-9.5, 0, -2.0> }
object { Tanne1 scale 1.2  rotate y * 60  translate < 7.5, 0, 10.5> }
object { Tanne2 scale 1.1  rotate y * 150 translate <-7.0, 0, 12.5> }
object { Laub1  scale 1.0  rotate y * 300 translate < 6.5, 0, 17.0> }
object { Laub2  scale 1.1  rotate y * 20  translate <-5.5, 0, 19.0> }

// Der Rest wird zufällig verteilt
#declare Z_Baeume = seed(2026);
#declare i = 0;
#while (i < Baum_Anzahl)
    #declare BX = -80 + rand(Z_Baeume) * 160;       // x-Position
    #declare BZ = -30 + rand(Z_Baeume) * 130;       // z-Position
    #declare Sorte = rand(Z_Baeume);                // welcher Baum
    #declare Gr    = 0.75 + rand(Z_Baeume) * 0.6;   // wie groß
    #declare Dr    = rand(Z_Baeume) * 360;          // wie gedreht

    // Freie Zone vorm Haus
    #declare Frei = (BX > -12 & BX < 11 & BZ > -12 & BZ < 22);
    #if (!Frei)
        object {
            #if     (Sorte < 0.30) Tanne1
            #elseif (Sorte < 0.55) Tanne2
            #elseif (Sorte < 0.75) Laub1
            #elseif (Sorte < 0.92) Laub2
            #else                  Laub3
            #end
            scale Gr
            rotate y * Dr
            translate <BX, 0, BZ>
        }
    #end
    #declare i = i + 1;
#end


//-----------DAS HAUS---------------------------------------------------------
// 8 m x 6 m
#declare Wand_Dicke = 0.2;
#declare Tuer_Breite = 1.1;
#declare Tuer_Hoehe  = 2.1;

#declare Putz = texture {                        // Heller Putz
    pigment { granite color_map { [0 rgb <0.88, 0.84, 0.76>] [1 rgb <0.95, 0.92, 0.86>] } scale 0.5 }
    normal  { granite 0.15 scale 0.02 }
}
#declare Holz = texture {                        // Dunkles Holz für Tür
    pigment {
        wood turbulence 0.1
        color_map { [0 rgb <0.25, 0.13, 0.06>] [0.6 rgb <0.35, 0.19, 0.09>] [1 rgb <0.22, 0.11, 0.05>] }
        scale 0.05 rotate x * 90
    }
    normal { wood 0.3 scale 0.05 rotate x * 90 }
    finish { specular 0.2 roughness 0.05 }
}
#declare Dachziegel = texture {                  // Rote Ziegel
    pigment {
        gradient z
        color_map {
            [0.00 rgb <0.35, 0.08, 0.04>]
            [0.15 rgb <0.55, 0.16, 0.08>]
            [1.00 rgb <0.48, 0.13, 0.06>]
        }
        scale 0.3
    }
    normal { gradient z 0.8 scale 0.3 }
}
#declare Glas = texture {                         // Fensterglas
    pigment { rgbf <0.85, 0.9, 0.9, 0.85> }
    finish  { ambient 0 diffuse 0.1 specular 1 roughness 0.001 reflection 0.15 }
}

// Fenster
#declare Fenster_Loch = box { <-0.5, -0.6, -0.5>, <0.5, 0.6, 0.5> }
#declare Fenster = union {
    box { <-0.5, -0.6, -0.01>, <0.5, 0.6, 0.01> texture { Glas } }
    // Rahmen
    union {
        box { <-0.55, -0.65, -0.04>, <-0.47, 0.65, 0.04> }
        box { < 0.47, -0.65, -0.04>, < 0.55, 0.65, 0.04> }
        box { <-0.55,  0.57, -0.04>, < 0.55, 0.65, 0.04> }
        box { <-0.55, -0.65, -0.04>, < 0.55, -0.57, 0.04> }
        box { <-0.03, -0.6, -0.03>, <0.03, 0.6, 0.03> }        // Kreuz senkrecht
        box { <-0.5, 0.07, -0.03>, <0.5, 0.13, 0.03> }         // Kreuz waagrecht
        texture { pigment { rgb 0.95 } }
    }
    // Fensterbank
    box { <-0.62, -0.72, -0.18>, <0.62, -0.65, 0.02> texture { pigment { rgb 0.6 } } }
}

// Blumenkasten mit Geranien
#declare Blumenkasten = union {
    box { <-0.5, -0.12, -0.1>, <0.5, 0.05, 0.1> texture { Holz } }
    #local Z_Geranie = seed(3);
    #local j = 0;
    #while (j < 14)
        sphere { <-0.42 + j * 0.065, 0.08 + rand(Z_Geranie) * 0.06, (rand(Z_Geranie) - 0.5) * 0.12>, 0.05
                 pigment { rgb <0.8, 0.05, 0.08> } }    // rote Blüte
        sphere { <-0.42 + j * 0.065, 0.04, (rand(Z_Geranie) - 0.5) * 0.14>, 0.05
                 pigment { rgb <0.1, 0.3, 0.05> } }     // grüne Blätter
        #local j = j + 1;
    #end
}

// Wände
difference {
    box { <-4, 0, 11>, <4, 3, 17> }
    box { <-4 + Wand_Dicke, 0.01, 11 + Wand_Dicke>, <4 - Wand_Dicke, 3.1, 17 - Wand_Dicke> }
    box { <-Tuer_Breite / 2, 0.02, 10.9>, <Tuer_Breite / 2, Tuer_Hoehe, 11.5> }     // Tür
    object { Fenster_Loch translate <-2.3, 1.6, 11> }                                // Fenster vorne links
    object { Fenster_Loch translate < 2.3, 1.6, 11> }                                // Fenster vorne rechts
    object { Fenster_Loch rotate y * 90 translate <-4, 1.6, 14> }                    // Fenster an der Seite
    texture { Putz }
}

// Sockel aus Stein unten rum
difference {
    box { <-4.05, 0, 10.95>, <4.05, 0.35, 17.05> }
    box { <-3.9, -0.1, 11.1>, <3.9, 0.5, 16.9> }
    box { <-Tuer_Breite / 2, 0.02, 10.8>, <Tuer_Breite / 2, 0.5, 11.5> }
    texture { pigment { granite color_map { [0 rgb 0.25] [1 rgb 0.45] } scale 0.2 } normal { granite 0.4 scale 0.1 } }
}

// Holzboden drinnen und eine Stufe vor der Tür
box { <-3.8, 0, 11.2>, <3.8, 0.03, 16.8> texture { Holz } }
box { <-0.9, 0, 10.55>, <0.9, 0.12, 11.02> texture { pigment { rgb 0.5 } normal { granite 0.3 scale 0.1 } } }
// Fußmatte (Schuhe abtreten!!)
box { <-0.45, 0.12, 10.6>, <0.45, 0.135, 10.98> texture { pigment { rgb <0.3, 0.22, 0.12> } normal { bumps 1 scale 0.01 } } }

// Fenster und Blumenkästen reinsetzen
object { Fenster translate <-2.3, 1.6, 11.0> }
object { Fenster translate < 2.3, 1.6, 11.0> }
object { Fenster rotate y * 90 translate <-4.0, 1.6, 14.0> }
object { Blumenkasten translate <-2.3, 0.95, 10.82> }
object { Blumenkasten translate < 2.3, 0.95, 10.82> }

// Türrahmen
union {
    box { <-Tuer_Breite / 2 - 0.1, 0, 10.93>, <-Tuer_Breite / 2, Tuer_Hoehe + 0.1, 11.05> }
    box { < Tuer_Breite / 2, 0, 10.93>, < Tuer_Breite / 2 + 0.1, Tuer_Hoehe + 0.1, 11.05> }
    box { <-Tuer_Breite / 2 - 0.1, Tuer_Hoehe, 10.93>, <Tuer_Breite / 2 + 0.1, Tuer_Hoehe + 0.1, 11.05> }
    texture { Holz }
}

// Die Tür
#declare Tuer_Winkel = 100 * Weich(Sekunden, 2.3, 3.2);
union {
    box { <0, 0, 0>, <Tuer_Breite - 0.02, Tuer_Hoehe - 0.02, 0.06> texture { Holz } }
    // Zwei Kassetten
    box { <0.15, 0.25, -0.01>, <Tuer_Breite - 0.17, 0.95, 0.0> texture { Holz } }
    box { <0.15, 1.15, -0.01>, <Tuer_Breite - 0.17, 1.85, 0.0> texture { Holz } }
    // Türklinke aus Messing
    cylinder { <Tuer_Breite - 0.15, 1.0, -0.06>, <Tuer_Breite - 0.15, 1.0, 0.0>, 0.02 texture { Brass_Metal } }
    box { <Tuer_Breite - 0.3, 0.98, -0.07>, <Tuer_Breite - 0.15, 1.02, -0.05> texture { Brass_Metal } }
    rotate y * -Tuer_Winkel                          // Minus = nach innen
    translate <-Tuer_Breite / 2 + 0.01, 0.02, 11.0>
}

// Hausnummer 4
text { ttf "cyrvetic.ttf" "4" 0.02, 0
       scale 0.4 translate <0.75, 1.75, 10.97>
       texture { pigment { rgb 0.05 } finish { specular 0.5 } } }

// Lampe neben der Tür
union {
    box { <-0.06, -0.12, 0>, <0.06, 0.12, -0.06> pigment { rgb 0.1 } }
    sphere { <0, 0, -0.14>, 0.08 pigment { rgb <1, 0.85, 0.6> } finish { emission 1 } }
    translate <-1.0, 2.35, 10.98>
}

// Dach!
#declare Dach_First = 5.0;                       // Wie hoch die Dachspitze ist
prism {
    linear_sweep
    -4, 4, 4
    <3.0, 11.0>, <Dach_First, 14.0>, <3.0, 17.0>, <3.0, 11.0>
    rotate z * 90
    texture { Putz }
}

// Die zwei Dachflächen sind flache Kästen die schräg gekippt werden.
#declare Dach_Neigung = degrees(atan2(Dach_First - 3.0, 3.0));
#declare Dachflaeche = box { <-4.5, 0, 0>, <4.5, 0.15, 4.2> texture { Dachziegel } }
object { Dachflaeche scale <1, 1, -1> rotate x * -Dach_Neigung translate <0, Dach_First, 14> }   // vordere Hälfte
object { Dachflaeche rotate x *  Dach_Neigung translate <0, Dach_First, 14> }                  // hintere Hälfte
// Balken oben auf der Spitze
cylinder { <-4.5, Dach_First + 0.1, 14>, <4.5, Dach_First + 0.1, 14>, 0.12 texture { Dachziegel } }

// Schornstein hinten aufm Dach
union {
    box { <-0.35, 0, -0.35>, <0.35, 2.4, 0.35> }
    box { <-0.42, 2.4, -0.42>, <0.42, 2.55, 0.42> }
    texture {
        pigment { brick rgb 0.75, rgb <0.5, 0.18, 0.1> brick_size <0.25, 0.08, 0.12> mortar 0.01 }
        normal  { brick 0.4 brick_size <0.25, 0.08, 0.12> mortar 0.01 }
    }
    translate <2.2, 3.8, 15.2>
}

// Rauch aus dem Schornstein (jemand kocht wohl schon)
#declare w = 0;
#while (w < 8)
    #declare Alter = mod(Sekunden * 0.3 + w / 8, 1);
    sphere { 0, 1
        scale 0.25 + Alter * 0.9                    // wird größer je älter
        translate <2.2 + Alter * 1.8, 6.5 + Alter * 4.0, 15.2 + Alter * 0.6>   // Wind pustet ihn nach rechts
        texture {
            pigment { rgbt <0.85, 0.85, 0.88, 0.55 + 0.45 * Alter> }         // und durchsichtiger
            finish  { ambient 0.3 diffuse 0.6 }
        }
        no_shadow
    }
    #declare w = w + 1;
#end

// Kleiner Tisch drinnen
union {
    box { <-0.6, 0.72, -0.4>, <0.6, 0.77, 0.4> }                 // Platte
    cylinder { <-0.5, 0, -0.3>, <-0.5, 0.72, -0.3>, 0.03 }       // 4 Beine
    cylinder { < 0.5, 0, -0.3>, < 0.5, 0.72, -0.3>, 0.03 }
    cylinder { <-0.5, 0, 0.3>, <-0.5, 0.72, 0.3>, 0.03 }
    cylinder { < 0.5, 0, 0.3>, < 0.5, 0.72, 0.3>, 0.03 }
    texture { Holz }
    translate <1.5, 0, 14.8>
}


//-----------DAS MÄNNCHEN (mit merge!)-----------------------------------------
// Warum merge und nicht union

#declare Haut   = texture { pigment { rgb <0.85, 0.62, 0.48> } finish { specular 0.1 roughness 0.05 } }
#declare Shirt  = texture { pigment { rgb <0.05, 0.55, 0.60> } normal { bumps 0.1 scale 0.01 } }   // türkis
#declare Hose   = texture { pigment { rgb <0.08, 0.10, 0.22> } normal { bumps 0.15 scale 0.005 } } // dunkle Jogginghose
#declare Schuh  = texture { pigment { rgb 0.92 } finish { specular 0.3 } }                          // weiße Sneaker
#declare Haare  = texture { pigment { rgb <0.30, 0.16, 0.07> } normal { wrinkles 0.4 scale 0.02 } finish { specular 0.3 roughness 0.02 } } // braun

// Ein Bein
#macro Bein(Huefte, Knie)
    merge {
        cylinder { <0, 0, 0>, <0, -0.44, 0>, 0.075 texture { Hose } }      // Oberschenkel
        sphere   { <0, -0.44, 0>, 0.068 texture { Hose } }                 // Knie
        merge {                                                            // Unterschenkel und Fuß
            cylinder { <0, 0, 0>, <0, -0.42, 0>, 0.062 texture { Hose } }
            box { <-0.055, -0.475, -0.06>, <0.055, -0.40, 0.18> texture { Schuh } }  // Schuh zeigt nach vorne
            rotate x * Knie              // erst am Knie drehen
            translate <0, -0.44, 0>      // dann ans Knie hinschieben
        }
        rotate x * Huefte                // und das ganze Bein an der Hüfte drehen
    }
#end

// Ein Arm
#macro Arm(Schulter, Ellenbogen)
    merge {
        cylinder { <0, 0, 0>, <0, -0.29, 0>, 0.05 texture { Shirt } }      // Oberarm
        sphere   { <0, -0.29, 0>, 0.045 texture { Haut } }                 // Ellenbogen
        merge {
            cylinder { <0, 0, 0>, <0, -0.25, 0>, 0.04 }                     // Unterarm
            sphere   { <0, -0.29, 0>, 0.05 scale <0.8, 1, 1> }              // Hand
            texture { Haut }
            rotate x * Ellenbogen
            translate <0, -0.29, 0>
        }
        rotate x * Schulter
    }
#end

#macro Maennchen(P)
    // P ist die Phase in Grad von oben
    #local S  = sin(radians(P));
    #local C  = cos(radians(P));
    // Das Knie knickt stark ein wenn das Bein nach vorne schwingt (C > 0),
    #local Knie_L = 8 + 55 * max(0,  C);
    #local Knie_R = 8 + 55 * max(0, -C);
    merge {
        // Beine
        object { Bein(-Bein_Schwung * S, Knie_L) translate <-0.10, 0.92, 0> }
        object { Bein( Bein_Schwung * S, Knie_R) translate < 0.10, 0.92, 0> }

        // Becken und Oberkörper
        sphere { 0, 1 scale <0.18, 0.12, 0.11> translate y * 0.95 texture { Hose } }
        sphere { 0, 1 scale <0.20, 0.30, 0.12> translate y * 1.22 texture { Shirt } }

        // Arme
        object { Arm( Arm_Schwung * S, -75) translate <-0.23, 1.43, 0> }
        object { Arm(-Arm_Schwung * S, -75) translate < 0.23, 1.43, 0> }

        // Hals und Kopf
        cylinder { <0, 1.45, 0>, <0, 1.56, 0>, 0.05 texture { Haut } }
        merge {
            sphere { 0, 0.115 scale <1, 1.12, 1> texture { Haut } }                  // Kopf
            sphere { <0, 0.025, -0.018>, 0.118 scale <1, 1.12, 1> texture { Haare } } // Haare = gleiche Kugel
            // Pferdeschwanz aus 3 Kugeln
            merge {
                sphere { <0, 0,     -0.06>, 0.045 }
                sphere { <0, -0.07, -0.08>, 0.040 }
                sphere { <0, -0.14, -0.08>, 0.030 }
                texture { Haare }
                rotate x * (15 + 10 * sin(radians(P * 2)))       // hoch und runter
                rotate z * (12 * S)                              // und zur Seite
                translate <0, 0.06, -0.08>
            }
            sphere { <-0.04, 0.02, 0.105>, 0.013 pigment { rgb 0.02 } }    // Augen
            sphere { < 0.04, 0.02, 0.105>, 0.013 pigment { rgb 0.02 } }
            sphere { <0, -0.01, 0.115>, 0.018 texture { Haut } }           // Nase
            translate y * 1.66
        }

        // Beim Joggen lehnt man sich bisschen nach vorne
        rotate x * 6
    }
#end

// Und jetzt kommt sie in die Szene
object {
    Maennchen(Phase)
    translate y * Wippen
    rotate y * Figur_Dreh
    translate Figur_Pos
}

//------------------------------------- Ende
