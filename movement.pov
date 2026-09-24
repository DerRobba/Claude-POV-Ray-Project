// ============================================================================
//  movement.pov  -  "Feierabend"  (Abgabe Animation)
// ----------------------------------------------------------------------------
//  Aufgabe:
//    - ein Maennchen, das mit MERGE zusammengesetzt ist
//    - es bewegt sich GENAU 4 Sekunden lang sichtbar durch eine Landschaft
//      mit Baeumen
//    - am Ende betritt es ein Haus mit Dach
//    - eine Lichtquelle am Himmel, damit Schatten entstehen
//
//  Meine Idee: Sie joggt nach Feierabend ueber einen Trampelpfad durch die
//  Wiese nach Hause. Kurz bevor sie ankommt, geht die Haustuer auf (drinnen
//  wartet schon jemand, deshalb brennt auch Licht), und genau bei 4,0 s
//  steht sie in der Tuer und geht rein.
//
//  Timing:
//    clock laeuft von 0 bis 1 und wird unten in Sekunden umgerechnet
//    (clock * 4). Gerendert wird mit 100 Bildern bei 25 fps = genau 4 s.
//    -> Einstellungen stehen in quickres.ini (Eintraege "Movement ...")
//       bzw. in movement.ini.
//
//  Einheiten: 1 POV-Einheit = 1 Meter. y zeigt nach oben.
//  Das Haus steht hinten bei z = 11..17, die Tuer zeigt nach -z (zur Kamera).
//
//  (Umlaute schreibe ich als ae/oe/ue, weil der POV-Ray-Editor unter Windows
//   sonst manchmal Zeichensalat daraus macht.)
// ============================================================================

#version 3.7;

// ----------------------------------------------------------------------------
//  SCHALTER FUER DIE QUALITAET
//  Mit #ifndef kann man die Werte auch von aussen setzen, z.B. in der ini:
//  Declare=Weiche_Schatten=0
// ----------------------------------------------------------------------------
#ifndef (Weiche_Schatten) #declare Weiche_Schatten = 1; #end   // weiche Schattenkanten (area_light), ca. doppelte Renderzeit
#ifndef (Kamera_Wahl)     #declare Kamera_Wahl     = 1; #end   // 1 = Hauptkamera (animiert), 2 = Uebersicht von oben, 3 = Nahaufnahme von der Seite
#ifndef (Baum_Anzahl)     #declare Baum_Anzahl     = 260; #end // wie viele Baeume zufaellig gepflanzt werden


global_settings {
    assumed_gamma 1.0                    // lineare Helligkeit wie in der Vorlage
    max_trace_level 8                    // genug fuer Fensterglas + Spiegelungen
}

// Etwas Grundhelligkeit, damit Schatten nicht komplett schwarz werden.
// In echt kommt da Licht vom blauen Himmel an, das faken wir hiermit.
#default { finish { ambient 0.06 diffuse 0.85 } }


//-----------INCLUDES---------------------------------------------------------
#include "colors.inc"
#include "textures.inc"
#include "functions.inc"        // fuer die Rausch-Funktion der Berge


//============================================================================
//  ZEIT
//============================================================================
// Alles, was sich bewegt, haengt NUR von dieser Variable ab.
// clock = 0 -> 0 s, clock = 1 -> 4 s.
#declare Dauer    = 4;                       // Laenge der Animation in Sekunden
#declare Sekunden = clock * Dauer;

// Hilfsfunktion fuer "weiche" Uebergaenge (langsam anfangen, langsam aufhoeren).
// Gibt 0 zurueck vor A, 1 nach B und dazwischen eine S-Kurve.
#declare Weich = function(Wert, A, B) {
    select(Wert - A, 0,
        select(Wert - B,
            ((Wert - A) / (B - A)) * ((Wert - A) / (B - A)) * (3 - 2 * (Wert - A) / (B - A)),
        1))
}


//============================================================================
//  DER WEG DES MAENNCHENS
//============================================================================
// Der Weg ist ein Spline: Ich gebe zu bestimmten Zeitpunkten (in Sekunden)
// an, wo sie sein soll, und POV-Ray rechnet eine glatte Kurve dazwischen.
// Die Punkte habe ich so ausgerechnet, dass zwischen je zwei Punkten
// ungefaehr gleich viel Strecke liegt (ca. 1,43 m pro halbe Sekunde).
// Dadurch laeuft sie gleichmaessig schnell und wird nicht ploetzlich
// langsamer oder schneller. -> ca. 11,5 m in 4 s = 2,9 m/s = lockeres Joggen.
// Die Punkte bei -0.5 s und 4.5 s sind nur da, damit die Kurve am Anfang
// und am Ende sauber weiterlaeuft.
#declare Weg = spline {
    natural_spline
    -0.5, <-6.40, 0, 0.90>
     0.0, <-5.20, 0, 1.60>      // Start: sie ist schon voll im Bild
     0.5, <-3.96, 0, 2.31>
     1.0, <-2.89, 0, 3.26>
     1.5, <-2.00, 0, 4.38>
     2.0, <-1.27, 0, 5.62>
     2.5, <-0.71, 0, 6.93>
     3.0, <-0.32, 0, 8.31>
     3.5, <-0.08, 0, 9.72>
     4.0, < 0.00, 0, 11.15>     // Ende: genau in der Haustuer
     4.5, < 0.00, 0, 12.60>
}

#declare Figur_Pos = Weg(Sekunden);

// In welche Richtung schaut sie? Ich nehme einen Punkt kurz davor und kurz
// danach auf dem Weg, die Differenz ist die Laufrichtung.
// atan2(dx, dz) gibt den Winkel um die y-Achse (Figur ist nach +z gebaut).
#declare Richtung   = Weg(Sekunden + 0.05) - Weg(Sekunden - 0.05);
#declare Figur_Dreh = degrees(atan2(Richtung.x, Richtung.z));

// Laufzyklus: Pro Schritt legt sie ca. 1 m zurueck, ein kompletter Zyklus
// (links + rechts) sind also 2 m. Die Phase ist ein Winkel, der mit der
// gelaufenen Strecke mitwaechst -> Beine und Arme schwingen mit sin(Phase).
#declare Tempo      = 2.865;                        // m/s (siehe oben)
#declare Schrittlaenge = 1.0;
#declare Phase      = Sekunden * Tempo / (2 * Schrittlaenge) * 360;

#declare Bein_Schwung = 30;                         // max. Winkel der Beine in Grad
#declare Arm_Schwung  = 35;                         // Arme schwingen gegengleich

// Wenn ein Bein schraeg steht, ist die Huefte tiefer als bei geradem Bein.
// Deshalb senke ich den Koerper um genau diesen Betrag (Kosinus), damit die
// Fuesse nicht in der Luft haengen oder im Boden verschwinden.
// Dazu ein kleiner Huepfer, weil man beim Joggen kurz "fliegt".
#declare Bein_Winkel = Bein_Schwung * sin(radians(Phase));
#declare Wippen      = 0.92 * (cos(radians(Bein_Winkel)) - 1)
                     + 0.035 * abs(sin(radians(Phase)));


//============================================================================
//  KAMERA
//============================================================================
// Kamera 1 faehrt langsam mit und schwenkt dabei vom Maennchen immer mehr
// zum Haus rueber, damit man am Ende gut sieht, wie sie reingeht.
#declare Kamera_Pos = <-1.6, 1.55, -4.2> + <4.2, 0.9, 4.4> * Weich(Sekunden, 0, 4);

// Blickpunkt: am Anfang die Figur (Brusthoehe), am Ende eine Mischung aus
// Figur und Hausmitte, damit das Dach mit ins Bild kommt.
#declare Blick_Mix  = 0.55 * Weich(Sekunden, 1.0, 4.0);
#declare Kamera_Ziel = (Figur_Pos + <0, 1.1, 0>) * (1 - Blick_Mix) + <0, 2.6, 13> * Blick_Mix;

#declare Kamera1 = camera {
    location Kamera_Pos
    look_at  Kamera_Ziel
    angle 55
    right x * image_width / image_height
}

// Kamera 2: Uebersicht von schraeg oben, fest. Gut zum Kontrollieren,
// ob der Weg zwischen den Baeumen durchgeht.
#declare Kamera2 = camera {
    location <-18, 22, -14>
    look_at  <-1, 0, 6>
    angle 60
    right x * image_width / image_height
}

// Kamera 3: Nahaufnahme von der Seite, faehrt neben ihr her. Damit habe
// ich kontrolliert, ob Arme und Beine richtig schwingen.
#declare Kamera3 = camera {
    location Figur_Pos + vrotate(<3.2, 1.0, 0>, y * Figur_Dreh)
    look_at  Figur_Pos + <0, 0.9, 0>
    angle 40
    right x * image_width / image_height
}

#if (Kamera_Wahl = 2)
    camera { Kamera2 }
#elseif (Kamera_Wahl = 3)
    camera { Kamera3 }
#else
    camera { Kamera1 }
#end


//============================================================================
//  LICHT
//============================================================================
// Die Sonne - die Lichtquelle am Himmel. Sie steht weit weg, links hinter
// der Kamera und ziemlich hoch (ca. 40 Grad ueber dem Horizont).
// Deshalb wirft alles lange, schraege Schatten nach rechts hinten.
// Warmes Licht, weil Feierabend = spaeter Nachmittag.
#declare Sonne_Pos = <-4000, 4300, -3200>;

light_source {
    Sonne_Pos
    color rgb <1.00, 0.90, 0.74> * 1.4
    #if (Weiche_Schatten)
        // Die echte Sonne ist eine Scheibe und kein Punkt, deshalb sind
        // Schatten an den Kanten leicht unscharf. area_light verteilt das
        // Licht auf eine Flaeche von 5x5 Lampen.
        area_light <120, 0, 0>, <0, 0, 120>, 5, 5
        adaptive 1
        jitter
        circular
        orient
    #end
    // looks_like: so sieht man die Sonne auch, wenn sie im Bild ist
    // (z.B. mit Kamera 2). Wirft selbst keinen Schatten.
    looks_like { sphere { 0, 90 pigment { rgb <1, 0.95, 0.8> } finish { emission 1 diffuse 0 } } }
}

// Schwaches, blaeuliches Licht von oben ohne Schatten = Himmelslicht.
// Dadurch sind die Schatten leicht blau, wie draussen in echt.
light_source {
    <0, 10000, 0>
    color rgb <0.45, 0.55, 0.75> * 0.3
    shadowless
}

// Licht im Haus. Warm wie eine Gluehbirne. fade_distance/fade_power sorgen
// dafuer, dass es wie eine echte Lampe mit der Entfernung schwaecher wird.
// Man sieht es durch die Fenster und die offene Tuer.
light_source {
    <0, 2.4, 14.5>
    color rgb <1.0, 0.72, 0.42> * 2.2
    fade_distance 2
    fade_power 2
}


//============================================================================
//  HIMMEL, WOLKEN, DUNST
//============================================================================
// Himmelskugel: am Horizont hell und warm, oben tiefblau.
sky_sphere {
    pigment {
        gradient y
        color_map {
            [0.00 rgb <0.95, 0.82, 0.66>]
            [0.10 rgb <0.70, 0.78, 0.88>]
            [0.35 rgb <0.30, 0.48, 0.80>]
            [1.00 rgb <0.10, 0.22, 0.55>]
        }
    }
}

// Wolken: eine Ebene hoch oben mit bozo-Muster (wie der Horizont in der
// Vorlage), aber mit Transparenz (rgbt), damit der Himmel durchschaut.
// Sie ziehen mit der Zeit ein bisschen weiter.
plane { <0, 1, 0>, 1 hollow
    texture {
        pigment {
            bozo
            turbulence 0.85
            octaves 6
            lambda 2.5
            color_map {
                [0.00 rgbt <1, 1, 1, 1>]
                [0.50 rgbt <1, 1, 1, 1>]
                [0.62 rgbt <1.0, 0.96, 0.90, 0.4>]
                [0.80 rgbt <1.0, 0.94, 0.86, 0.0>]
                [1.00 rgbt <0.62, 0.62, 0.70, 0.0>]
            }
            scale <1, 1, 1.6> * 0.9
            translate <Sekunden * 0.02, 0, 0>          // Wind
        }
        finish { ambient 0 emission 0.95 diffuse 0 }
    }
    scale 900
    no_shadow            // sonst verdecken die Wolken die Sonne
}

// Bodennebel / Dunst. Macht weit entfernte Sachen (Berge, hintere Baeume)
// blasser - so wirkt die Landschaft viel tiefer.
fog {
    fog_type   2
    distance   1400
    color      rgb <0.80, 0.81, 0.85>
    fog_offset 0
    fog_alt    120
    turbulence 0.4
}


//============================================================================
//  BODEN
//============================================================================
// Wiese: zwei Muster uebereinander. Grosse Flecken (mal saftiger, mal
// trockener) und kleine Beulen fuer die Struktur.
plane { <0, 1, 0>, 0
    texture {
        pigment {
            bozo
            turbulence 0.6
            color_map {
                [0.0 rgb <0.10, 0.24, 0.03>]
                [0.4 rgb <0.17, 0.33, 0.05>]
                [0.7 rgb <0.26, 0.38, 0.08>]
                [1.0 rgb <0.36, 0.40, 0.14>]
            }
            scale 4
        }
        normal { bumps 0.3 scale 0.04 }
        finish { specular 0.05 roughness 0.1 }
    }
}

// Trampelpfad: Ganz viele flache Scheiben (Zylinder), die entlang des
// Splines hintereinander gelegt werden. Zusammen sehen sie aus wie ein
// ausgetretener Erdweg. Er liegt 3 mm ueber dem Gras, sonst flackern
// die zwei Flaechen gegeneinander.
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
        // Breite schwankt etwas, ein Trampelpfad ist nie ganz gleich breit
        cylinder { P, P + <0, 0.003, 0>, 0.55 + 0.1 * sin(Zeit * 7) }
        #declare Zeit = Zeit + 0.04;
    #end
    texture { Pfad_Textur }
}

// Blumen auf der Wiese: kleine bunte Kugeln, zufaellig verteilt.
// Neben dem Pfad lasse ich sie weg (sonst wuerde sie drueber joggen).
#declare Z_Blumen = seed(7);
#declare Blumen_Farben = array[4] { rgb <0.9, 0.85, 0.2>, rgb <0.95, 0.95, 0.95>, rgb <0.7, 0.2, 0.6>, rgb <0.9, 0.3, 0.1> }
union {
    #declare i = 0;
    #while (i < 700)
        #declare BX = -14 + rand(Z_Blumen) * 24;
        #declare BZ = -4  + rand(Z_Blumen) * 16;
        #declare Farbe = Blumen_Farben[floor(rand(Z_Blumen) * 3.999)];
        // Abstand zum Pfad grob pruefen: x-Abstand zum Weg auf gleicher Hoehe
        #if (abs(BX - Weg(min(4, max(0, (BZ - 1.6) / 9.55 * 4))).x) > 0.9)
            sphere { <BX, 0.05, BZ>, 0.018 pigment { Farbe } }
        #end
        #declare i = i + 1;
    #end
    no_shadow
}


//============================================================================
//  BERGE IM HINTERGRUND
//============================================================================
// height_field = ein Gitter, jeder Punkt bekommt eine Hoehe zwischen 0 und 1.
// Statt eines Bildes nehme ich eine Funktion:
//   f_ridged_mf = Rauschen mit scharfen Graten (sieht aus wie Gebirge)
//   Berg_Ring   = nur in einem Ring aussen herum, die Mitte bleibt flach
#declare F_Grate    = function { f_ridged_mf(x*7, y*7, 0, 0.8, 2.1, 7, 0.9, 2.0, 2) }
#declare F_Abstand  = function { sqrt(pow(x - 0.5, 2) + pow(y - 0.5, 2)) }
#declare Berg_Ring  = function { max(0, 1 - pow((F_Abstand(x, y, 0) - 0.40) / 0.11, 2)) }

height_field {
    function 700, 700 { min(1, F_Grate(x, y, 0) * 0.55 * Berg_Ring(x, y, 0)) }
    smooth
    translate <-0.5, 0, -0.5>
    scale <6000, 480, 6000>
    translate <0, -2, 0>                 // flacher Teil verschwindet unter der Wiese
    texture {
        pigment {                        // Farbe nach Hoehe: Wald -> Fels -> Schnee
            gradient y
            turbulence 0.12
            color_map {
                [0.00 rgb <0.10, 0.20, 0.06>]
                [0.30 rgb <0.14, 0.22, 0.08>]
                [0.42 rgb <0.33, 0.30, 0.25>]
                [0.62 rgb <0.45, 0.42, 0.38>]
                [0.70 rgb <0.95, 0.96, 1.00>]
                [1.00 rgb <1.00, 1.00, 1.00>]
            }
            scale 480
            translate -2 * y
        }
        normal { granite 0.3 scale 40 }
    }
}


//============================================================================
//  BAEUME
//============================================================================
// Rinde: braun mit laenglichen Flecken und Beulen.
#declare Rinde = texture {
    pigment { bozo color_map { [0 rgb <0.16, 0.10, 0.06>] [1 rgb <0.27, 0.19, 0.12>] } scale <0.05, 0.4, 0.05> }
    normal  { bumps 0.9 scale <0.03, 0.2, 0.03> }
}

// Nadelbaum: Stamm + 5 Kegel uebereinander. Jeder Kegel ist kleiner und
// sitzt hoeher (gleiche Idee wie mein 3-Kegel-Baum aus der Vorlage,
// nur mit mehr Stufen).
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
                   rotate y * Stufe * 37 }       // jede Stufe verdreht, damit das Muster nicht gleich aussieht
            #local Stufe = Stufe + 1;
        #end
    }
#end

// Laubbaum: Stamm + Krone aus einem "blob". Ein blob verschmilzt mehrere
// Kugeln zu einer weichen Form -> sieht eher nach Baumkrone aus.
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

// Ein paar Sorten nur EINMAL bauen und dann oft kopieren - das spart
// Rechenzeit beim Parsen.
#declare Tanne1 = Tanne(rgb <0.05, 0.18, 0.06>)
#declare Tanne2 = Tanne(rgb <0.07, 0.22, 0.08>)
#declare Laub1  = Laubbaum(rgb <0.16, 0.30, 0.06>, 11)
#declare Laub2  = Laubbaum(rgb <0.24, 0.33, 0.07>, 22)
#declare Laub3  = Laubbaum(rgb <0.40, 0.30, 0.08>, 33)   // faengt schon an, herbstlich zu werden

// Diese Baeume setze ich per Hand direkt an den Pfad, damit sie auf jeden
// Fall im Bild sind und sie wirklich "zwischen Baeumen durch" laeuft.
object { Laub1  scale 0.9  rotate y * 30  translate <-7.5, 0,  5.0> }
object { Tanne1 scale 1.0  rotate y * 10  translate <-4.6, 0,  7.2> }
object { Laub2  scale 0.8  rotate y * 200 translate < 3.2, 0,  4.8> }
object { Tanne2 scale 0.85 rotate y * 80  translate < 4.2, 0,  1.0> }
object { Laub3  scale 0.75 rotate y * 120 translate <-9.5, 0, -2.0> }
object { Tanne1 scale 1.2  rotate y * 60  translate < 7.5, 0, 10.5> }
object { Tanne2 scale 1.1  rotate y * 150 translate <-7.0, 0, 12.5> }
object { Laub1  scale 1.0  rotate y * 300 translate < 6.5, 0, 17.0> }
object { Laub2  scale 1.1  rotate y * 20  translate <-5.5, 0, 19.0> }

// Der Rest wird zufaellig gepflanzt. Gleicher Startwert (seed) = in jedem
// Bild derselbe Wald. Baeume, die auf dem Pfad, im Haus oder vor der
// Kamera landen wuerden, werden einfach uebersprungen.
#declare Z_Baeume = seed(2026);
#declare i = 0;
#while (i < Baum_Anzahl)
    #declare BX = -80 + rand(Z_Baeume) * 160;
    #declare BZ = -30 + rand(Z_Baeume) * 130;
    #declare Sorte = rand(Z_Baeume);
    #declare Gr    = 0.75 + rand(Z_Baeume) * 0.6;
    #declare Dr    = rand(Z_Baeume) * 360;

    // Freie Zone: der ganze Bereich vor dem Haus, in dem Pfad, Kamera und
    // Haus sind. Ausserhalb davon darf ein Baum stehen.
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


//============================================================================
//  DAS HAUS
//============================================================================
// Grundriss 8 m x 6 m, Waende 3 m hoch, Satteldach.
// Vorderwand (mit Tuer) bei z = 11, Rueckwand bei z = 17.
#declare Wand_Dicke = 0.2;
#declare Tuer_Breite = 1.1;
#declare Tuer_Hoehe  = 2.1;

#declare Putz = texture {                        // heller Hausputz, leicht fleckig
    pigment { granite color_map { [0 rgb <0.88, 0.84, 0.76>] [1 rgb <0.95, 0.92, 0.86>] } scale 0.5 }
    normal  { granite 0.15 scale 0.02 }
}
#declare Holz = texture {                        // dunkles Holz fuer Tuer, Rahmen, Balken
    pigment {
        wood turbulence 0.1
        color_map { [0 rgb <0.25, 0.13, 0.06>] [0.6 rgb <0.35, 0.19, 0.09>] [1 rgb <0.22, 0.11, 0.05>] }
        scale 0.05 rotate x * 90
    }
    normal { wood 0.3 scale 0.05 rotate x * 90 }
    finish { specular 0.2 roughness 0.05 }
}
#declare Dachziegel = texture {                  // rote Ziegel: gradient gibt die Ziegelreihen
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
#declare Glas = texture {                         // Fensterglas: fast durchsichtig, spiegelt etwas
    pigment { rgbf <0.85, 0.9, 0.9, 0.85> }
    finish  { ambient 0 diffuse 0.1 specular 1 roughness 0.001 reflection 0.15 }
}

// Fenster-Loch + Glas + Rahmen mit Fensterkreuz. Wird vorne und an der
// Seite benutzt. Mitte bei (0,0), Groesse 1,0 x 1,2 m.
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

// Blumenkasten mit roten Geranien unter dem Fenster - einfach, weil's schoen ist.
#declare Blumenkasten = union {
    box { <-0.5, -0.12, -0.1>, <0.5, 0.05, 0.1> texture { Holz } }
    #local Z_Geranie = seed(3);
    #local j = 0;
    #while (j < 14)
        sphere { <-0.42 + j * 0.065, 0.08 + rand(Z_Geranie) * 0.06, (rand(Z_Geranie) - 0.5) * 0.12>, 0.05
                 pigment { rgb <0.8, 0.05, 0.08> } }
        sphere { <-0.42 + j * 0.065, 0.04, (rand(Z_Geranie) - 0.5) * 0.14>, 0.05
                 pigment { rgb <0.1, 0.3, 0.05> } }
        #local j = j + 1;
    #end
}

// --- Waende: aussen ein grosser Kasten, innen einer abziehen -> hohl.
//     Dann Tuer und Fenster rausschneiden.
difference {
    box { <-4, 0, 11>, <4, 3, 17> }
    box { <-4 + Wand_Dicke, 0.01, 11 + Wand_Dicke>, <4 - Wand_Dicke, 3.1, 17 - Wand_Dicke> }
    box { <-Tuer_Breite / 2, 0.02, 10.9>, <Tuer_Breite / 2, Tuer_Hoehe, 11.5> }     // Tuer
    object { Fenster_Loch translate <-2.3, 1.6, 11> }                                // Fenster vorne links
    object { Fenster_Loch translate < 2.3, 1.6, 11> }                                // Fenster vorne rechts
    object { Fenster_Loch rotate y * 90 translate <-4, 1.6, 14> }                    // Fenster Seite
    texture { Putz }
}

// Sockel unten aus Stein, damit das Haus nicht so "aufgestellt" aussieht
difference {
    box { <-4.05, 0, 10.95>, <4.05, 0.35, 17.05> }
    box { <-3.9, -0.1, 11.1>, <3.9, 0.5, 16.9> }
    box { <-Tuer_Breite / 2, 0.02, 10.8>, <Tuer_Breite / 2, 0.5, 11.5> }
    texture { pigment { granite color_map { [0 rgb 0.25] [1 rgb 0.45] } scale 0.2 } normal { granite 0.4 scale 0.1 } }
}

// Fussboden innen (Holzdielen) und eine Stufe vor der Tuer
box { <-3.8, 0, 11.2>, <3.8, 0.03, 16.8> texture { Holz } }
box { <-0.9, 0, 10.55>, <0.9, 0.12, 11.02> texture { pigment { rgb 0.5 } normal { granite 0.3 scale 0.1 } } }
// Fussmatte
box { <-0.45, 0.12, 10.6>, <0.45, 0.135, 10.98> texture { pigment { rgb <0.3, 0.22, 0.12> } normal { bumps 1 scale 0.01 } } }

// Fenster einsetzen
object { Fenster translate <-2.3, 1.6, 11.0> }
object { Fenster translate < 2.3, 1.6, 11.0> }
object { Fenster rotate y * 90 translate <-4.0, 1.6, 14.0> }
object { Blumenkasten translate <-2.3, 0.95, 10.82> }
object { Blumenkasten translate < 2.3, 0.95, 10.82> }

// Tuerrahmen
union {
    box { <-Tuer_Breite / 2 - 0.1, 0, 10.93>, <-Tuer_Breite / 2, Tuer_Hoehe + 0.1, 11.05> }
    box { < Tuer_Breite / 2, 0, 10.93>, < Tuer_Breite / 2 + 0.1, Tuer_Hoehe + 0.1, 11.05> }
    box { <-Tuer_Breite / 2 - 0.1, Tuer_Hoehe, 10.93>, <Tuer_Breite / 2 + 0.1, Tuer_Hoehe + 0.1, 11.05> }
    texture { Holz }
}

// --- Die Tuer. Sie haengt links an der Angel und geht nach innen auf.
// Zwischen 2,3 s und 3,2 s schwingt sie von 0 auf 100 Grad auf.
// Drehen um die y-Achse geht immer um den Ursprung -> Tuer so bauen, dass
// die Angel im Ursprung liegt, drehen, DANN an die richtige Stelle schieben.
#declare Tuer_Winkel = 100 * Weich(Sekunden, 2.3, 3.2);
union {
    box { <0, 0, 0>, <Tuer_Breite - 0.02, Tuer_Hoehe - 0.02, 0.06> texture { Holz } }
    // zwei Kassetten, damit sie nicht so flach aussieht
    box { <0.15, 0.25, -0.01>, <Tuer_Breite - 0.17, 0.95, 0.0> texture { Holz } }
    box { <0.15, 1.15, -0.01>, <Tuer_Breite - 0.17, 1.85, 0.0> texture { Holz } }
    // Tuerklinke aus Messing
    cylinder { <Tuer_Breite - 0.15, 1.0, -0.06>, <Tuer_Breite - 0.15, 1.0, 0.0>, 0.02 texture { Brass_Metal } }
    box { <Tuer_Breite - 0.3, 0.98, -0.07>, <Tuer_Breite - 0.15, 1.02, -0.05> texture { Brass_Metal } }
    rotate y * -Tuer_Winkel                          // minus = nach innen (+z)
    translate <-Tuer_Breite / 2 + 0.01, 0.02, 11.0>
}

// Hausnummer "4" - wegen der 4 Sekunden :)
text { ttf "cyrvetic.ttf" "4" 0.02, 0
       scale 0.4 translate <0.75, 1.75, 10.97>
       texture { pigment { rgb 0.05 } finish { specular 0.5 } } }

// Lampe neben der Tuer (leuchtet nur, beleuchtet aber nichts - reine Deko)
union {
    box { <-0.06, -0.12, 0>, <0.06, 0.12, -0.06> pigment { rgb 0.1 } }
    sphere { <0, 0, -0.14>, 0.08 pigment { rgb <1, 0.85, 0.6> } finish { emission 1 } }
    translate <-1.0, 2.35, 10.98>
}

// --- Dach
// Giebeldreiecke vorne und hinten: ein prism ist eine Flaeche, die in die
// Hoehe gezogen wird. Die Punkte sind (Hoehe, z), die Extrusion geht
// erst entlang y und wird dann mit rotate z*90 in die x-Richtung gekippt.
// Nach der Drehung zeigt die alte y-Achse nach -x, also -4..4 -> 4..-4.
#declare Dach_First = 5.0;                       // Hoehe des Dachfirsts
prism {
    linear_sweep
    -4, 4, 4
    <3.0, 11.0>, <Dach_First, 14.0>, <3.0, 17.0>, <3.0, 11.0>
    rotate z * 90
    texture { Putz }
}

// Die zwei Dachflaechen sind flache Kaesten, die schraeg gekippt werden.
// Neigung: 2 m Hoehe auf 3 m Breite -> atan(2/3) = ca. 33,7 Grad.
// Laenge 4 m (damit das Dach vorne und hinten uebersteht).
#declare Dach_Neigung = degrees(atan2(Dach_First - 3.0, 3.0));
#declare Dachflaeche = box { <-4.5, 0, 0>, <4.5, 0.15, 4.2> texture { Dachziegel } }
object { Dachflaeche scale <1, 1, -1> rotate x * -Dach_Neigung translate <0, Dach_First, 14> }   // vordere Haelfte
object { Dachflaeche rotate x *  Dach_Neigung translate <0, Dach_First, 14> }                  // hintere Haelfte
// Firstbalken oben drauf, damit keine Luecke zwischen den Flaechen bleibt
cylinder { <-4.5, Dach_First + 0.1, 14>, <4.5, Dach_First + 0.1, 14>, 0.12 texture { Dachziegel } }

// Schornstein auf der hinteren Dachhaelfte
union {
    box { <-0.35, 0, -0.35>, <0.35, 2.4, 0.35> }
    box { <-0.42, 2.4, -0.42>, <0.42, 2.55, 0.42> }
    texture {
        pigment { brick rgb 0.75, rgb <0.5, 0.18, 0.1> brick_size <0.25, 0.08, 0.12> mortar 0.01 }
        normal  { brick 0.4 brick_size <0.25, 0.08, 0.12> mortar 0.01 }
    }
    translate <2.2, 3.8, 15.2>
}

// Rauch aus dem Schornstein: 8 Wolken, die aufsteigen, groesser werden und
// dabei verblassen. Jede Wolke hat ein eigenes "Alter" (0..1), das mit der
// Zeit hochzaehlt und bei 1 wieder von vorne anfaengt (mod).
#declare w = 0;
#while (w < 8)
    #declare Alter = mod(Sekunden * 0.3 + w / 8, 1);
    sphere { 0, 1
        scale 0.25 + Alter * 0.9
        translate <2.2 + Alter * 1.8, 6.5 + Alter * 4.0, 15.2 + Alter * 0.6>   // der Wind treibt ihn nach rechts
        texture {
            pigment { rgbt <0.85, 0.85, 0.88, 0.55 + 0.45 * Alter> }
            finish  { ambient 0.3 diffuse 0.6 }
        }
        no_shadow
    }
    #declare w = w + 1;
#end

// Ein kleiner Tisch drinnen, damit man durch Tuer und Fenster was sieht
union {
    box { <-0.6, 0.72, -0.4>, <0.6, 0.77, 0.4> }
    cylinder { <-0.5, 0, -0.3>, <-0.5, 0.72, -0.3>, 0.03 }
    cylinder { < 0.5, 0, -0.3>, < 0.5, 0.72, -0.3>, 0.03 }
    cylinder { <-0.5, 0, 0.3>, <-0.5, 0.72, 0.3>, 0.03 }
    cylinder { < 0.5, 0, 0.3>, < 0.5, 0.72, 0.3>, 0.03 }
    texture { Holz }
    translate <1.5, 0, 14.8>
}


//============================================================================
//  DAS MAENNCHEN  (mit merge kombiniert!)
//============================================================================
// merge statt union: Bei merge werden die Teile zu EINEM Koerper
// verschmolzen, die inneren Flaechen, wo sich zwei Teile ueberschneiden,
// fallen weg. Bei undurchsichtigen Objekten sieht man keinen Unterschied,
// aber wenn man es mal durchsichtig macht, sieht man bei union alle
// Ueberschneidungen und bei merge nicht. (Kann man testen: bei der Haut
// z.B. rgbf <1,0.8,0.7,0.6> einsetzen.)
//
// Aufbau: Die Figur steht im Ursprung, die Fuesse bei y = 0, sie schaut
// nach +z. Groesse ca. 1,75 m.
// Beine und Arme sind eigene merges, die sich an Huefte/Schulter drehen.
// Der Unterschenkel dreht sich zusaetzlich am Knie, der Unterarm am
// Ellenbogen. Trick dabei: jedes Teil so bauen, dass das Gelenk im
// Ursprung liegt, dann drehen, dann an die richtige Stelle schieben.

#declare Haut   = texture { pigment { rgb <0.85, 0.62, 0.48> } finish { specular 0.1 roughness 0.05 } }
#declare Shirt  = texture { pigment { rgb <0.05, 0.55, 0.60> } normal { bumps 0.1 scale 0.01 } }   // tuerkis
#declare Hose   = texture { pigment { rgb <0.08, 0.10, 0.22> } normal { bumps 0.15 scale 0.005 } } // dunkle Jogginghose
#declare Schuh  = texture { pigment { rgb 0.92 } finish { specular 0.3 } }                          // weisse Sneaker
#declare Haare  = texture { pigment { rgb <0.30, 0.16, 0.07> } normal { wrinkles 0.4 scale 0.02 } finish { specular 0.3 roughness 0.02 } }

// Bein: Huefte im Ursprung, haengt nach unten.
//   Huefte = Winkel am Hueftgelenk (negativ = Bein nach vorne)
//   Knie   = Beugung im Knie (positiv = Unterschenkel nach hinten)
#macro Bein(Huefte, Knie)
    merge {
        cylinder { <0, 0, 0>, <0, -0.44, 0>, 0.075 texture { Hose } }      // Oberschenkel
        sphere   { <0, -0.44, 0>, 0.068 texture { Hose } }                 // Knie
        merge {                                                            // Unterschenkel + Fuss
            cylinder { <0, 0, 0>, <0, -0.42, 0>, 0.062 texture { Hose } }
            box { <-0.055, -0.475, -0.06>, <0.055, -0.40, 0.18> texture { Schuh } }  // Schuh zeigt nach vorne (+z)
            rotate x * Knie
            translate <0, -0.44, 0>
        }
        rotate x * Huefte
    }
#end

// Arm: Schulter im Ursprung.
//   Schulter  = Schwung nach vorne/hinten
//   Ellenbogen = Beugung (negativ = Unterarm nach vorne, beim Joggen ~70 Grad)
#macro Arm(Schulter, Ellenbogen)
    merge {
        cylinder { <0, 0, 0>, <0, -0.29, 0>, 0.05 texture { Shirt } }      // Oberarm (T-Shirt)
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
    // P = Phase in Grad. Linkes und rechtes Bein sind um 180 Grad versetzt.
    #local S  = sin(radians(P));
    #local C  = cos(radians(P));
    // Knie beugt sich stark, wenn das Bein nach vorne schwingt (C > 0),
    // und ist fast gerade, wenn das Bein hinten auf dem Boden steht.
    #local Knie_L = 8 + 55 * max(0,  C);
    #local Knie_R = 8 + 55 * max(0, -C);
    merge {
        // --- Beine (Hueften 10 cm links/rechts der Mitte, 0,92 m hoch)
        object { Bein(-Bein_Schwung * S, Knie_L) translate <-0.10, 0.92, 0> }
        object { Bein( Bein_Schwung * S, Knie_R) translate < 0.10, 0.92, 0> }

        // --- Becken und Oberkoerper (gestauchte Kugeln = Ellipsoide)
        sphere { 0, 1 scale <0.18, 0.12, 0.11> translate y * 0.95 texture { Hose } }
        sphere { 0, 1 scale <0.20, 0.30, 0.12> translate y * 1.22 texture { Shirt } }

        // --- Arme: gegengleich zu den Beinen (linker Arm vorne, wenn rechtes Bein vorne)
        object { Arm( Arm_Schwung * S, -75) translate <-0.23, 1.43, 0> }
        object { Arm(-Arm_Schwung * S, -75) translate < 0.23, 1.43, 0> }

        // --- Hals und Kopf
        cylinder { <0, 1.45, 0>, <0, 1.56, 0>, 0.05 texture { Haut } }
        merge {
            sphere { 0, 0.115 scale <1, 1.12, 1> texture { Haut } }                  // Kopf
            sphere { <0, 0.025, -0.018>, 0.118 scale <1, 1.12, 1> texture { Haare } } // Haare: gleiche Kugel, nach hinten-oben verschoben
            // Pferdeschwanz: 3 Kugeln, die beim Laufen hin und her wippen
            merge {
                sphere { <0, 0,     -0.06>, 0.045 }
                sphere { <0, -0.07, -0.08>, 0.040 }
                sphere { <0, -0.14, -0.08>, 0.030 }
                texture { Haare }
                rotate x * (15 + 10 * sin(radians(P * 2)))       // wippt doppelt so schnell wie die Schritte
                rotate z * (12 * S)                              // und schlenkert seitlich
                translate <0, 0.06, -0.08>
            }
            sphere { <-0.04, 0.02, 0.105>, 0.013 pigment { rgb 0.02 } }    // Augen
            sphere { < 0.04, 0.02, 0.105>, 0.013 pigment { rgb 0.02 } }
            sphere { <0, -0.01, 0.115>, 0.018 texture { Haut } }           // Nase
            translate y * 1.66
        }

        // Beim Joggen lehnt man sich leicht nach vorne
        rotate x * 6
    }
#end

// --- Maennchen in die Szene setzen:
// erst wippen, dann in Laufrichtung drehen, dann an die Position auf dem Weg.
object {
    Maennchen(Phase)
    translate y * Wippen
    rotate y * Figur_Dreh
    translate Figur_Pos
}

//------------------------------------- Ende
