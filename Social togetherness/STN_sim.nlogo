; Implementation:

; 4 different rooms, UL, UR, LL, LR. Connection between UL-LL , UR-LR and LL-LR.

; 12 ticks form one day

; At each day, every agent (rat) is assigned a random feeding window (but with fixed size). At each tick of this window he will scan adjancent rooms
; in order to find one that fullfils it`s STN (social togetherness necessity). If found, he goes there and eats at that tick, if it is not found, he tries on the next tick of his window
; If it is the last tick of his window, instead, even if no appropiated room is found, he eats on the one that satisfies it at most.

; After eating, STN is adjusted with base on the rats that rat ate with.
; let x denote the number of rats that rat ate with:
; STN = STN + C*(x-STN) for x>=STN
; STN = STN + K*(STN-x) for x<STN

; Each "days-for-new-rats" we reset a set number of rats, as a new generation




extensions [table]


 ;custom type of turtle (list/element type)
breed [rats rat]

; attributes
rats-own [
  STN         ; social togetherness necessity
   has-eaten          ; boolean: has eaten today
  feeding-window-start
   feeding-window-end
   current-room            ; UR, UL, LR or LL
   has-decided-to-feed?   ;Rat decided to eat this tick
   rats-fed-with          ; number of rats this rat ate with
   feeding-this-tick?    ; is eating this tick

]

globals [

    day-count     ; 12 ticks = 1 day
    tick-in-day      ; 1-12
    rooms             ; UR, UL, LR or LL
    room-feed-counts     ; table of current feeding counts in each room
    total-UL
    total-UR
    total-LL
    total-LR
    max-room-percent-total
   max-room-percent-count  ; added percentages


]

;All Parameters:
;interface global variables
;initial-room-population
;days-for-new-rats            - number of days for population update
;new-rats                    - number of rats to remove and spawn
;feeding-window                 - feeding-window size (in ticks)
;C                           - STN adjustment factor when x > STN
;K                            - STN adjustment factor when x < STN
;base-STN                      - Initial STN value for new rats





to setup
  set total-UL 0
  set total-UR 0
  set total-LL 0
  set total-LR 0
  set max-room-percent-total 0
  set max-room-percent-count 0
  clear-all
  set day-count 1
  set tick-in-day 1
  setup-rooms
  setup-rats
  reset-ticks
end








to setup-rooms
  set rooms ["UL" "UR" "LL" "LR"]

  set room-feed-counts table:make
   foreach rooms [ elem -> table:put room-feed-counts elem 0 ] ; Hashmap

  ;patches
  ask patches [
    ifelse pxcor >= 0 and pycor >= 0 [
      set pcolor grey
      set plabel "UR"
      set plabel-color [0 0 0 0]  ; transparent, but stil keeps lable

     ] [

      ifelse pxcor < 0 and pycor >= 0  [
        set pcolor black
        set plabel "UL"
        set plabel-color [0 0 0 0]

    ] [

    ifelse pxcor < 0 and pycor < 0 [
      set pcolor red
      set plabel "LL"
      set plabel-color [0 0 0 0]

     ] [

      set pcolor orange
      set plabel "LR"
      set plabel-color [0 0 0 0]
     ]]]
  ]
end













to setup-rats
  foreach rooms [ element ->

   create-rats initial-room-population [

      set color white
      set size 1
       move-to one-of patches with [plabel = element]
       set current-room element
        set STN base-STN
       set has-eaten false
       set rats-fed-with 0
       set feeding-this-tick? false


      assign-feeding-window
    ]
  ]
end










; random feeding window with appropriate size nd format
to assign-feeding-window
   let max-start (13 - feeding-window)

  set feeding-window-start (random max-start) + 1
  set feeding-window-end (feeding-window-start + feeding-window - 1)

end



to plots-logic

    ;total rooms plot
    set-current-plot "Rats per Room"
   set total-UL total-UL + count rats with [current-room = "UL"]
   set total-UR total-UR + count rats with [current-room = "UR"]
   set total-LL total-LL + count rats with [current-room = "LL"]
   set total-LR total-LR + count rats with [current-room = "LR"]

    set-current-plot "Rats per Room"

    set-current-plot-pen "UL"
    plot total-UL

    set-current-plot-pen "UR"
    plot total-UR

    set-current-plot-pen "LL"
    plot total-LL

    set-current-plot-pen "LR"
    plot total-LR


  ;max room plot
  let room-populations map [a -> count rats with [current-room = a]] ["UL" "UR" "LL" "LR"]
  let max-room-population max room-populations

  let percent-max-room max-room-population / (initial-room-population * 4)
  set max-room-percent-total (max-room-percent-total + percent-max-room)
  set max-room-percent-count (max-room-percent-count + 1)

  ;Only update most populated average every 15 days (180 ticks)
    if ticks mod 180 = 0 [
   let average-max-room-percent (max-room-percent-total / max-room-percent-count)
    set-current-plot "Most Populated Room Average"
    plot average-max-room-percent
    set max-room-percent-total 0
    set max-room-percent-count 0

]

    ;Update STN each 30 days (360 ticks)
  if ticks mod 360 = 0 [
  set-current-plot "STN Distribution"
  histogram [STN] of rats

]



end






to go ;--------------

  plots-logic



  ; End of day check and logic, STN and population
  if tick-in-day > 12 [

    adjust-STN

    if (day-count mod days-for-new-rats) = 0 [
      update-population
    ]

    ; next day setup
    set tick-in-day 1
    set day-count day-count + 1



    ask rats [
      set has-eaten false
      set rats-fed-with 0
      assign-feeding-window
    ]
  ]



  ; New tick reset
  ask rats [
    set has-decided-to-feed? false
    set feeding-this-tick? false
  ]
  foreach rooms [ elem ->
    table:put room-feed-counts elem 0
  ]



  ; feeding stage
  ask rats [
    if (not has-eaten) and (feeding-window-start <= tick-in-day) and (feeding-window-end >= tick-in-day) [
      ifelse tick-in-day = feeding-window-end [
         ; final atempt
         make-final-attempt
      ] [
         ; normal atempt
        make-feeding-decision
      ]
     ]
  ]

   ; feeding counts
  ask rats with [has-decided-to-feed?] [
    table:put room-feed-counts current-room (table:get room-feed-counts current-room + 1) ; starts at zero for each tick
    set feeding-this-tick? true
  ]

  foreach rooms [ elem ->
     let feeders-in-room rats with [feeding-this-tick? and current-room = elem]


    let num-feeders count feeders-in-room
    ask feeders-in-room [
        set rats-fed-with num-feeders
    ]
  ]


    ask rats with [feeding-this-tick?] [
    set has-eaten true
  ]



  set tick-in-day tick-in-day + 1
  tick
end ;--------------












; sup method
to-report get-accessible-rooms [room-name]

  if room-name = "UL" [ report ["UL" "LL"] ]
if room-name = "LL" [ report ["LL" "UL" "LR"] ]
if room-name = "LR" [ report ["LR" "LL" "UR"] ]
if room-name = "UR" [ report ["UR" "LR"] ]
end





to make-feeding-decision
  let accessible-rooms get-accessible-rooms (current-room) ; list reachable rooms
   let room-options []
  let feeding-rats rats with [has-decided-to-feed?]




  ; copy room-feed-counts to projected-feed-counts to process
   let projected-feed-counts table:make
foreach table:keys room-feed-counts [CurrentKey ->
  table:put projected-feed-counts CurrentKey (table:get room-feed-counts CurrentKey)
]



  ask feeding-rats [
    table:put projected-feed-counts current-room (table:get projected-feed-counts current-room + 1)
  ]

   foreach accessible-rooms [ room ->
       let feeding-count table:get projected-feed-counts room
      if feeding-count >= STN [
      ;add possible room with Iput (it appends)
       set room-options lput room room-options
    ]
  ]
   if not empty? room-options [
    let chosen-room one-of room-options
     move-to-room-and-feed chosen-room
  ]
  end





; Even if no room sufices >= STN, it eats
 to make-final-attempt
  let accessible-rooms get-accessible-rooms current-room
   let feeding-rats rats with [has-decided-to-feed?]
    let projected-feed-counts table:make
  foreach table:keys room-feed-counts [key ->
  table:put projected-feed-counts key (table:get room-feed-counts key)
]


   ask feeding-rats [
    table:put projected-feed-counts current-room (table:get projected-feed-counts current-room + 1)
  ]


 let max-feeding max map [room ->
    table:get projected-feed-counts room] accessible-rooms



    let best-rooms []
     foreach accessible-rooms [ room ->
     if table:get projected-feed-counts room = max-feeding [
         set best-rooms lput room best-rooms
    ]
  ]


  let chosen-room one-of best-rooms
   move-to-room-and-feed chosen-room
end





to move-to-room-and-feed [room-name]
   set current-room room-name
  move-to one-of patches with [plabel = room-name] ; transparent label
  set has-decided-to-feed? true
end










; Let x denote number of rats that ate with eachother
; if STN > x, STN--
; if STN < x, STN++
to adjust-STN
  ask rats [
    if has-eaten [
   let x rats-fed-with
    ifelse x = STN [
    ] [
     ifelse x > STN [
      ; increases STN proportially to C
        set STN STN + C * (x - STN)
       ] [
     ; decreases STN proportially to K
        set STN STN + K * (x - STN)
       ]
       if STN < 0 [ set STN 0 ]

   ]
   ]
  ]
end






 to update-population
  ; Random rats to refresh (die and spawn)
  let rats-to-remove n-of new-rats rats

   let spawn-info []
  ask rats-to-remove [
   ;info to array
    set spawn-info lput current-room spawn-info
   die
  ]

  foreach spawn-info [ spawn-room ->
    create-rats 1 [
      set color white
     set size 1
      move-to one-of patches with [plabel = spawn-room]
       set current-room spawn-room
     set STN base-STN
     set has-eaten false
      assign-feeding-window
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
933
13
1290
371
-1
-1
10.6
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

SLIDER
26
234
198
267
initial-room-population
initial-room-population
1
60
18.0
1
1
NIL
HORIZONTAL

SLIDER
27
610
199
643
days-for-new-rats
days-for-new-rats
1
10
3.0
1
1
NIL
HORIZONTAL

SLIDER
28
562
200
595
new-rats
new-rats
1
30
6.0
1
1
NIL
HORIZONTAL

SLIDER
28
291
200
324
feeding-window
feeding-window
1
12
6.0
1
1
NIL
HORIZONTAL

SLIDER
34
432
206
465
C
C
0
1
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
32
484
204
517
K
K
0
1
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
28
349
200
382
base-STN
base-STN
0
50
0.0
1
1
NIL
HORIZONTAL

BUTTON
69
75
133
108
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
69
149
132
182
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
160
24
230
69
day-count
day-count
17
1
11

MONITOR
250
317
337
362
Average STN
mean [STN] of rats
2
1
11

PLOT
360
129
917
374
STN Distribution
STN
Frequency
0.0
30.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""

PLOT
927
382
1384
701
Rats per room
Time (in 1/12 of a day)
# of rats fed
0.0
100.0
0.0
100.0
true
true
"" ""
PENS
"UL" 1.0 0 -16777216 true "" ""
"UR" 1.0 0 -7500403 true "" ""
"LL" 1.0 0 -2674135 true "" ""
"LR" 1.0 0 -955883 true "" ""

PLOT
220
379
918
702
Most Populated Room Average
Time (in 15 days)
% of total population
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -5825686 true "" ""

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
