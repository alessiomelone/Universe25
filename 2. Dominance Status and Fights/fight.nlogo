;; Universe 25 Simulation Model
;; Models the behavior of mice in a confined space with food dispensers.

globals [
  fight-count     ;; Tracks the total number of fights that have occurred.
  fight-deaths    ;; Tracks the number of mice that have died as a result of fights.
  mating-interval ;; Time interval between mating attempts for male mice.
  meal-interval   ;; Time interval between meals for mice.
  energy-threshold ;; Energy level below which mice seek food.
]

turtles-own [
  sex                  ;; The sex of the mouse ("M" for male, "F" for female).
  energy               ;; The current energy level of the mouse.
  age                  ;; The age of the mouse.
  ticks-without-eating ;; Counts the ticks since the mouse last ate.
  social-status        ;; For males: a value between 0 and 1 indicating dominance.
  last-mated           ;; For males: counts the ticks since the mouse last mated.
  fertile              ;; For females: whether the female is fertile.
  pregnant             ;; For females: whether the female is pregnant.
  pregnancy-timer      ;; For females: counts the ticks since pregnancy began.
  behavior             ;; The behavior of the mouse ("normal" or "beautiful").
  my-dispenser         ;; The dispenser the dominant male considers as "his."
]

patches-own [
  is-food-dispenser   ;; Indicates whether the patch is a food dispenser.
]

;; Setup procedure initializes the simulation.
to setup
  random-seed 12345
  clear-all                  ;; Clears the world.
  reset-ticks                ;; Resets the tick counter.
  setup-patches              ;; Calls the procedure to set up patches.
  setup-turtles              ;; Calls the procedure to create mice.
  set fight-count 0          ;; Initializes fight count.
  set fight-deaths 0         ;; Initializes fight death count.
  set meal-interval max-age * 0.1   ;; Sets meal interval based on max age.
  set mating-interval max-age * 0.2 ;; Sets mating interval based on max age.
  set energy-threshold max-age * 0.3 ;; Sets energy threshold based on max age.
end

;; Sets up the patches, particularly the food dispensers.
to setup-patches
  ask patches [ set is-food-dispenser false ] ;; Initialize all patches.

  ;; Calculate the coordinates for placing food dispensers away from the edges.
  let max-x max-pxcor - 2
  let min-x min-pxcor + 2
  let max-y max-pycor - 2
  let min-y min-pycor + 2

  ;; Set specific patches as food dispensers.
  ask patch min-x min-y [ set is-food-dispenser true ]
  ask patch min-x max-y [ set is-food-dispenser true ]
  ask patch max-x min-y [ set is-food-dispenser true ]
  ask patch max-x max-y [ set is-food-dispenser true ]

  ;; Color the food dispensers green.
  ask patches with [ is-food-dispenser ] [
    set pcolor green
  ]
end

;; Creates the initial population of mice.
to setup-turtles
  create-turtles initial-population [
    setxy random-xcor random-ycor  ;; Place mice at random positions.
    set sex one-of ["M" "F"]       ;; Assign random sex.
    set energy random max-energy   ;; Assign random energy level.
    set age random max-age         ;; Assign random age.

    ifelse sex = "M" [
      ;; Male-specific setup.
      set social-status random-float 1 ;; Random social status between 0 and 1.
      set color blue
      set last-mated 0
      set my-dispenser nobody         ;; No dispenser claimed initially.
    ] [
      ;; Female-specific setup.
      set color pink
      set fertile false
      set pregnant false
      set pregnancy-timer 0
    ]
    set behavior "normal"                         ;; Initial behavior is normal.
    set ticks-without-eating random meal-interval ;; Random time since last meal.
    set size 1.5
  ]
end

;; Main simulation loop.
to go
  if not any? turtles [
    report-fight-stats     ;; Report fight statistics if no mice are left.
    stop
  ]

  ask turtles [
    update-age-and-fertility-and-eating-timer  ;; Update age, fertility, and hunger.
    update-behavior
    move                ;; Decide on movement.
    eat                 ;; Attempt to eat if conditions are met.
    if sex = "M" [ fight ] ;; Males may engage in fights.
    if sex = "F" [ handle-pregnancy ] ;; Females handle pregnancy progression.
    if sex = "F" and not pregnant and fertile [ try-to-reproduce ] ;; Attempt reproduction.
    lose-energy         ;; Decrease energy due to metabolism.
    check-death         ;; Check if the mouse dies due to energy or age.

    ;; Visual updates and counters.
    if sex = "M" [
      set size 1.5 + (social-status) ;; Size represents dominance.
      if social-status > dominance-threshold [set color red]
      set last-mated last-mated + 1    ;; Increment time since last mating.
    ]
    if sex = "F" [ set size 1.5 ]      ;; Female size remains constant.
  ]

  if ticks mod 100 = 0 [
    report-fight-stats   ;; Periodically report fight statistics.
  ]

  tick  ;; Advance the simulation clock.
end

;; Updates the mouse's age, fertility status, and hunger timer.
to update-age-and-fertility-and-eating-timer
  set age age + 1  ;; Increase age by one unit.

  ;; Determine fertility based on age.
  set fertile (age >= max-age / 6 and age <= max-age / 1.5)

  set ticks-without-eating ticks-without-eating + 1 ;; Increment hunger timer.
end

;; Updates the behavior of mice based on overcrowding.
to update-behavior
  if behavior = "normal" [
    if overcrowded? and sex = "M" [
      ;; Male mice may become "beautiful ones" under overcrowding.
      if random-float 1 < behavior-change-probability [
        set behavior "beautiful"
        set color grey  ;; Change color to represent behavior change.
      ]
    ]
  ]
end

;; Reports the number of mice.
to-report num-mice
  report count turtles
end

;; Reports the average age of mice.
to-report average-age
  ifelse any? turtles [
    report mean [age] of turtles
  ] [
    report 0  ;; Return 0 if no mice are present.
  ]
end

to-report average-dominance
  ifelse any? turtles [
    report mean [social-status] of turtles with [sex = "M" and age > 0.6 * max-age]
  ] [
    report 0  ;; Return 0 if no mice are present.
  ]
end

;; Determines if the mouse is dominated by any nearby dominant male.
to-report dominated?
  report any? turtles in-radius 5 with [
    sex = "M" and
    social-status > [social-status] of myself
  ]
end

;; Determines if the area is overcrowded.
to-report overcrowded?
  report (count turtles in-radius 5) > overcrowding-threshold
end

;; Reports the number of juvenile mice.
to-report juveniles
  report count turtles with [ age <= 1 ]
end

;; Reports the proportion of females in the population.
to-report females
  let fems count turtles with [ sex = "F" ]
  let mice count turtles
  report fems / mice
end

;; Reports fight statistics.
to report-fight-stats
  show (word "Total Fights: " fight-count)
  show (word "Deaths in Fights: " fight-deaths)
end

;; Movement logic for mice.
to move
  (ifelse behavior = "beautiful" [
    ;; 'Beautiful ones' do not move much, focus on self-grooming.
    rt random-float 10 - 5
    fd 0.25
  ] ticks-without-eating >= meal-interval or energy < energy-threshold [
    ;; Mice seek food when hungry.
    seek-food
  ] sex = "M" and last-mated >= mating-interval [
    ;; Male mice seek females for mating.
    seek-mate
  ] [
    ;; Default movement is random.
    move-randomly
  ])
end

;; Procedure for seeking food.
to seek-food
  (ifelse sex = "M" and social-status >= dominance-threshold [
    ;; Dominant males consider the nearest dispenser as their own.
    if my-dispenser = nobody [
      ;; Assign the nearest dispenser as "my-dispenser."
      let dispensers patches with [is-food-dispenser]
      if any? dispensers [
        set my-dispenser min-one-of dispensers [distance myself]
      ]
    ]
    ;; Move towards "my-dispenser" and hover around it.
    ifelse my-dispenser != nobody [
      ifelse distance my-dispenser > 3 [
        face my-dispenser
        if can-move? 1 [
          fd 1
        ]
      ] [
        ;; Hover around the dispenser.
        rt random 360
        if can-move? 1 [
          fd 0.5
        ]
      ]
    ] [
      ;; If no dispenser found, move randomly.
      move-randomly
    ]
  ] sex = "F" [
    ;; Females always go to the nearest food dispenser.
    let nearest-dispenser min-one-of patches with [is-food-dispenser] [distance myself]
    face nearest-dispenser
    if can-move? 1 [
      fd 1
    ]
  ] [
    ;; Non-dominant males prefer dispensers without dominant males nearby.
    let safe-dispensers patches with [
      is-food-dispenser and not any? turtles with [
        sex = "M" and social-status >= dominance-threshold and distance myself <= 5
      ]
    ]
    ifelse any? safe-dispensers [
      let nearest-dispenser min-one-of safe-dispensers [distance myself]
      face nearest-dispenser
      if can-move? 1 [
        fd 1
      ]
    ] [
      ;; If no safe dispensers, go to the nearest one.
      let nearest-dispenser min-one-of patches with [is-food-dispenser] [distance myself]
      face nearest-dispenser
      if can-move? 1 [
        fd 1
      ]
    ]
  ])
end

;; Procedure for male mice to seek mates.
to seek-mate
  ;; Find potential female mates.
  let potential-mates turtles with [
    sex = "F" and
    fertile and
    not pregnant
  ]

  ifelse social-status >= dominance-threshold [
    ;; Dominant males check for stronger males nearby.
    let stronger-males turtles with [
      sex = "M" and
      social-status > [social-status] of myself and
      distance myself <= 5
    ]
    ifelse any? stronger-males [
      ;; Stronger dominant male nearby, do not seek mates.
      move-randomly
    ] [
      ;; No stronger dominant male, seek any fertile female.
      ifelse any? potential-mates [
        let nearest-female min-one-of potential-mates [distance myself]
        face nearest-female
        if can-move? 1 [
          fd 2
        ]
      ] [
        ;; If no females, move randomly.
        move-randomly
      ]
    ]
  ] [
    ;; Non-dominant males seek females not surrounded by dominant males.
    let safe-females potential-mates with [
      not any? turtles with [
        sex = "M" and
        social-status >= dominance-threshold and
        distance myself <= 5
      ]
    ]
    ifelse any? safe-females [
      let nearest-female min-one-of safe-females [distance myself]
      face nearest-female
      if can-move? 1 [
        fd 2
      ]
    ] [
      ;; If no safe females, move randomly.
      move-randomly
    ]
  ]
end

;; Procedure for random movement with a bias towards the center.
to move-randomly
  let center patch 0 0                  ;; Define the center of the environment.
  let angle-to-center towards center    ;; Calculate the angle toward the center.

  ;; Add a random component to the movement angle.
  rt (angle-to-center - heading) + random-normal -30 30

  if can-move? 1 [
    fd 1   ;; Move forward.
  ]
end

;; Procedure for mice to eat.
to eat
  if ticks-without-eating > meal-interval [
    if any? patches in-radius 1 with [is-food-dispenser] [
      ;; Mice can eat if within radius 1 of a dispenser.
      set energy max-energy
      set ticks-without-eating 0
    ]
  ]
end

;; Fighting behavior among male mice.
to fight
  let juvenile-age max-age * 0.2
  if behavior != "beautiful" and age >= juvenile-age [
    if overcrowded? [
      let num-mice-here count turtles in-radius 5
      ;; Calculate fight probability based on overcrowding.
      let fight-probability (num-mice-here - overcrowding-threshold) * fight-probability-factor
      ;; Ensure fight probability is between 0 and 1.
      set fight-probability max list 0 (min list fight-probability 1)
      if random-float 1 < fight-probability [
        ;; Increment fight count.
        set fight-count fight-count + 1

        ;; Proceed to fight.
        let opponents turtles in-radius 1 with [
          sex = "M" and
          self != myself and
          age >= juvenile-age and
          behavior != "beautiful"
        ]
        if any? opponents [
          let opponent one-of opponents

          ;; Calculate probabilities based on social status and energy.
          let ss-sum social-status + [social-status] of opponent
          let social-status-prob 0.5
          if ss-sum != 0 [
            set social-status-prob social-status / ss-sum
          ]

          let energy-sum energy + [energy] of opponent
          let energy-prob 0.5
          if energy-sum != 0 [
            set energy-prob energy / energy-sum
          ]

          ;; Calculate win probability.
          let win-probability (social-status-prob + energy-prob) / 2 + (random-float 0.2 - 0.1)
          set win-probability max list 0 (min list win-probability 1)

          ifelse random-float 1 < win-probability [
            ;; Current mouse wins.
            set social-status min list (social-status + 0.05) 1
            set energy energy - max-energy * 0.1
            ask opponent [
              set social-status max list (social-status - 0.05) 0
              set energy energy - max-energy * 0.2
              if energy <= 0 [
                set fight-deaths fight-deaths + 1
                die
              ]
            ]
          ] [
            ;; Opponent wins.
            set social-status max list (social-status - 0.05) 0
            set energy energy - max-energy * 0.2
            ask opponent [
              set social-status min list (social-status + 0.05) 1
              set energy energy - max-energy * 0.1
              if energy <= 0 [
                set fight-deaths fight-deaths + 1
                die
              ]
            ]
          ]
          ;; Ensure social-status remains between 0 and 1.
          set social-status min list (max list social-status 0) 1
        ]
      ]
    ]
  ]
end

;; Procedure for females attempting to reproduce.
to try-to-reproduce
  ;; Check if the female has enough energy.
  if energy >= (max-energy * 0.5) [
    ;; Calculate local overcrowding.
    let local-overcrowding count turtles in-radius 5

    if local-overcrowding = 0 [
      set local-overcrowding 1  ;; Avoid division by zero.
    ]

    ;; Calculate reproduction probability inversely proportional to overcrowding.
    let reproduction-probability min list 1 (overcrowding-threshold / local-overcrowding) ^ 2

    ;; Attempt to reproduce based on probability.
    if random-float 1 < reproduction-probability [
      let males turtles-here with [sex = "M" and fertile and behavior != "beautiful"]
      if any? males [
        set pregnant true
        set energy energy / 2
        set pregnancy-timer 0
        ask one-of males [
          set last-mated 0
        ]
      ]
    ]
  ]
end

;; Handles pregnancy progression for females.
to handle-pregnancy
  if pregnant [
    set pregnancy-timer pregnancy-timer + 1
    if pregnancy-timer >= pregnancy-duration [
      give-birth
    ]
  ]
end

;; Procedure for giving birth to offspring.
to give-birth
  let num-offspring random (max-offspring - min-offspring + 1) + min-offspring
  repeat num-offspring [
    hatch 1 [
      set sex one-of ["M" "F"]
      set energy max-energy
      set age 0
      ifelse sex = "M" [
        set social-status random-float dominance-threshold
        set color blue
        set last-mated 0
        set my-dispenser nobody
      ] [
        set color pink
        set fertile false
        set pregnant false
        set pregnancy-timer 0
      ]
      set behavior "normal"
      set ticks-without-eating random meal-interval
      set size 1.5
      rt random 360
      fd 1
    ]
  ]
  set pregnant false
  set pregnancy-timer 0
end

;; Decreases the mouse's energy due to metabolism.
to lose-energy
  set energy energy - energy-loss-rate
end

;; Checks if the mouse dies due to low energy or old age.
to check-death
  ifelse energy <= 0 [
    die
  ] [
    if age >= max-age [
      let death-probability (age - max-age) * death-probability-factor
      set death-probability min list death-probability 1
      if random-float 1 < death-probability [
        die
      ]
    ]
  ]
  ;; If a dominant male dies, reset its dispenser association.
  if sex = "M" and social-status >= dominance-threshold and my-dispenser != nobody [
    set my-dispenser nobody
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
0
25
494
520
-1
-1
10.8
1
10
1
1
1
0
0
0
1
-22
22
-22
22
0
0
1
ticks
30.0

BUTTON
504
51
570
84
NIL
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
505
88
568
121
NIL
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

SLIDER
525
197
697
230
initial-population
initial-population
0
100
64.0
1
1
NIL
HORIZONTAL

SLIDER
710
237
882
270
max-energy
max-energy
0
200
70.0
10
1
NIL
HORIZONTAL

SLIDER
523
237
695
270
energy-loss-rate
energy-loss-rate
1
5
3.0
1
1
NIL
HORIZONTAL

SLIDER
762
400
941
433
pregnancy-duration
pregnancy-duration
1
10
10.0
1
1
NIL
HORIZONTAL

SLIDER
763
440
935
473
min-offspring
min-offspring
0
10
0.0
1
1
NIL
HORIZONTAL

SLIDER
764
482
936
515
max-offspring
max-offspring
1
10
5.0
1
1
NIL
HORIZONTAL

SLIDER
602
285
807
318
overcrowding-threshold
overcrowding-threshold
1
40
15.0
1
1
NIL
HORIZONTAL

SLIDER
519
493
731
526
behavior-change-probability
behavior-change-probability
0
0.2
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
528
451
716
484
dominance-threshold
dominance-threshold
0
1
0.5
0.05
1
NIL
HORIZONTAL

SLIDER
605
325
810
358
death-probability-factor
death-probability-factor
0
0.1
0.1
0.01
1
NIL
HORIZONTAL

MONITOR
598
51
675
96
NIL
num-mice
17
1
11

SLIDER
709
200
881
233
max-age
max-age
50
250
135.0
5
1
NIL
HORIZONTAL

MONITOR
595
102
680
147
NIL
average-age
17
1
11

SLIDER
519
412
719
445
fight-probability-factor
fight-probability-factor
0
1
1.0
0.01
1
NIL
HORIZONTAL

PLOT
936
31
1362
363
Population over time
Time
Population
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles"

MONITOR
696
54
832
99
NIL
average-dominance
17
1
11

TEXTBOX
503
389
743
417
Fight & dominance dynamics parameters
11
0.0
1

TEXTBOX
786
378
936
396
Offspring parameters
11
0.0
1

TEXTBOX
652
172
954
190
General parameters
11
0.0
1

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
