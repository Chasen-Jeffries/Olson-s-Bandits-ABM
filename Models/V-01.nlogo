; Agent-Based Model to simulate Olson's Roaming vs Stationary Bandits Theory


globals [
  wealth
  Stationary_Wealth_Avg ; average wealth outcome for a group
  Stationary_Wealth_Outcome ; average wealth increase each turn
  Roaming_Wealth_Avg    ; average wealth outcome for roaming bandits
  Roaming_Wealth_Outcome ; average wealth increase each turn
  fight-counter         ; number of fights each turn
  total-fights
]
bandits-own [
  obs-range          ; Observation range - how far bandits can see
  strength           ; Strength of the bandit
  win-threshold      ; Probability threshold for winning fights
  tax-rate           ; Taxation rate applied to patches
  invest-patch-rate  ; Rate of investment in a patch
  investment         ;
  investment-output  ; Output of investment
  investment-output-value
  time-to-bloom
  z a b1 b2 b3       ; Coefficients for decision-making (need further elaboration)
  Winner?            ; Flag indicating if the bandit won the last encounter
  best-dest          ; Best destination patch based on wealth
  best-alternative   ; Second-best destination patch
  pref-best          ; Preference for moving to the best patch
  wealth             ; Wealth of the bandit
  bandit-invest-time ; Time spent on investment in a patch
  invest-in-patch?   ; Flag indicating if the bandit is currently investing in a patch
  counter1           ; Counter used for various purposes (e.g., investment tracking)
  taxes              ; Tax gain
]

patches-own [
  growth-rate  ; Growth rate of patch wealth
  security     ; Security level of the patch
  wealth0      ; Wealth of the patch in the previous tick
  wealth1      ; Current wealth of the patch
  patch-invest-time ; time spend on investment in itself
  patch-investment-rate
  patch-investment-amount
  patch-investment-output
  p-invested?
  p-investment-bloomed?
  b-invested?
  counter0
]

breed[bandits bandit]

; Setup procedure: initializes the environment and bandits
to setup
 clear-all
 reset-ticks

 ; Initialize patch wealth and color
 ask patches[
   set wealth1 abs(round random-normal patch-wealth-m Patch-wealth-sd)
   let max_pwealth Max [wealth1] of patches
   set pcolor scale-color green wealth1 max_pwealth 0
   set patch-investment-rate abs(random-normal patch-invest-rate-m patch-invest-rate-sd)      ;; Setting up investment-rate
   if patch-investment-rate > 1 [set patch-investment-rate 0.99]                                    ;; Set Max invest-patch-rate
   if patch-investment-rate < 0 [set patch-investment-rate 0.01]                                    ;; Set Min Invest-patch-rate
   set patch-invest-time round(abs(random-normal patch-invest-time-m patch-invest-time-sd))     ; set Invest-time based on M and SD
   if patch-invest-time < 1 [set patch-invest-time 1]                                                   ; set Min invest-time
   set p-invested? False
   set b-invested? False
 ]

 ; Create bandits with initial properties
 create-bandits initial-bandits [
    setxy random-xcor random-ycor
    set shape "circle"
 ]

 ask bandits [
   set wealth abs(round random-normal bandit-wealth-m bandit-wealth-sd)                     ; Setting Wealth based on M and SD sliders
   set obs-range abs(round random-normal obs-range-m obs-range-sd)                          ; Set Observation range based on M and SD
   if obs-range < 1 [set obs-range 1]                                                       ; Set Min Observation Range to 1
   set win-threshold abs(random-normal win-threshold-m win-threshold-sd)                    ; set Win-threshold range based on M and SD
   if win-threshold < 0 [set win-threshold 0.01]                                            ; Set min Win-Threshold
   if win-threshold > 1 [set win-threshold 0.99]                                            ; Set max win-threshold
   set strength abs(round random-normal bandit-strength-m bandit-strength-sd)               ; Set Strength based on M and SD
   if strength < 1 [set strength 1]                                                         ; Set Min Strength
   set tax-rate abs(random-normal bandit-tax-rate-m bandit-tax-rate-sd)                     ; Set Tax Rate based on M and SD
   if tax-rate > 1 [set tax-rate 1]                                                         ; set Max tax-rate
   if tax-rate < 0 [set tax-rate 0.01]                                                      ; set Min Tax-rate
   set bandit-invest-time round(abs(random-normal bandit-invest-time-m bandit-invest-time-sd))     ; set Invest-time based on M and SD
   if bandit-invest-time < 1 [set bandit-invest-time 1]                                                   ; set Min invest-time
   set pref-best True                                                                       ; Set Pref-Best option True
   set a 0.5                                                                                ; Set A 0.5
   set b1 0.5                                                                               ; Set B1 0.5
   set b2 0.5                                                                               ; Set B2 0.5
   set b3 0.5                                                                               ; Set B3 0.5

   let MaxWealth max [wealth] of turtles
   let MinWealth min [wealth] of turtles
   let MaxMinWealth MaxWealth - MinWealth
   if MaxMinWealth = 0 [set MaxMinWealth 1]
   set size 1 + ((Wealth - MinWealth) / (MaxMinWealth))

    ; set size of agents based on wealth-scale
   set Winner? true                                                                         ; Assume You are the Winner
   set invest-in-patch? False                                                               ; setup invest-in-patch to False
   set investment-output 0 ; Output of investment
  ]
  setup-roaming-bandit                                                                      ; Run Setup Roaming Bandits Function
  setup-stationary-bandit                                                                   ; Run Setup Stationary bandits function

  set fight-counter 0
  set total-fights 0
end

to setup-roaming-bandit                                                                     ;; Setup roaming bandits
  ask bandits [
   set color blue                                                                           ;; Changing bandit color to differentiate them
   set invest-patch-rate 0                                                                  ;; Set invest-rate 0
  ]
end

to setup-stationary-bandit
  let num-stationary percent-stationary * initial-bandits                                   ;; set number of stationary bandits in model the percent stationary * all bandits

  ask n-of num-stationary bandits [                                                         ;; Setup stationary bandits
   set color red                                                                            ;; Changing bandit color to differentiate them
   set invest-patch-rate abs(random-normal bandit-invest-rate-m bandit-invest-rate-sd)      ;; Setting up investment-rate
   if invest-patch-rate > 1 [set invest-patch-rate 0.99]                                    ;; Set Max invest-patch-rate
   if invest-patch-rate < 0 [set invest-patch-rate 0.01]                                    ;; Set Min Invest-patch-rate
   set strength strength + defensive-bonus
  ]
end

; Main simulation loop
to go
  if not any? turtles [stop]
  bandit-action                                               ;; Run the Initial Bandit Action
  fight?                                                      ;; If necessary, Bandits Fight Action
  patch-action                                                ;; Run the Patch Action
  Outcome                                                     ;; Update Values based on outcomes
  Reproduce                                                   ;; Reproduce
  Update-DM                                                   ;; Updated Decision Making Values
  Update-Visuals                                              ;; Update Visuals
  tick
end

to bandit-action
  Roam?
  Tax-Patch
  Invest-in-patch
end


to Roam?
  ask bandits with [color = blue] [
     let target-patches patches in-radius obs-range                                  ;; Create agent-set of patches in local environment
     let best-patches max-n-of 2 target-patches [Wealth1]                            ;; ID best 2 patches
     set best-dest max-one-of best-patches [Wealth1]                                 ;; ID best-dest as the patch with the highest wealth
     let best-dest-wealth [Wealth1] of best-dest                                     ;;

     set best-alternative min-one-of best-patches [Wealth1]                          ;; ID 2nd best-dest as the patch with the 2nd highest wealth
     let wealth-here [wealth1] of patch-here                                         ;; Setup wealth-here based on patch value
     if wealth-here < best-dest-wealth [                                             ;; If here is best option
       if pref-best = True [                                                         ;; If you don't prefer best option
        let steps distance best-dest                                                 ;; let the steps the distance from current position to best-dest
        move-to best-dest                                                            ;; Move to best-destination
        set wealth wealth - (steps * move-cost)                                      ;; Update Wealth based on move cost and steps

      ]
      if pref-best = False[                                                          ;; If pref best-alternative
        let steps distance best-alternative                                          ;; calcualte steps
        move-to best-alternative                                                     ;; Move to best-alternative
        set wealth wealth - (steps * move-cost)                                      ;; Update Wealth
      ]
     ]
   ]
end

to Tax-Patch
  ask bandits[
    let wealth-here [wealth1] of patch-here                                      ;; ID wealth on current patch
    set taxes wealth-here * tax-rate                                             ;; Calculate Tax Revenue
    set wealth wealth + taxes                                                    ;; Update Wealth
    set wealth-here wealth-here - taxes                                          ;; Update Wealth here
    ask patch-here [set wealth1 wealth-here]                                     ;; Update Patches wealth
   ]
end



to Invest-in-patch
  ;; Can invest in the patch, which will increase the patch output next tick.
  ask bandits with [color = red][                                      ;; If stationary
    set investment invest-patch-rate * wealth
    if not invest-in-patch? and wealth >= (investment * 2)  [                                          ;; if not currently investing
      set invest-in-patch? True                                        ;; set invest-in-patch? True
      set counter1 0                                                   ;; set counter 0
      set investment-output 0                                          ;; set investment-output 0
      set wealth wealth - investment
      ask patch-here[set b-invested? True]
    ]
    if invest-in-patch? [
      set counter1 counter1 + 1                                        ;; Update counter
      if counter1 = bandit-invest-time [                                      ;; If counter equals invest-time
        set investment invest-patch-rate * wealth
        interest-formula-output
        set investment-output-value abs(random-normal investment-output (sqrt(abs(investment-output))))
        let wealth-here [wealth1] of patch-here                        ;; Set wealth-here the wealth of current patch
        set wealth-here wealth-here + investment-output-value          ;; Add investment-output to the wealth-here
        ask patch-here [
          set wealth1 wealth-here
          set b-invested? False
        ]                       ;; Update Patch wealth
        set invest-in-patch? False                                     ;; Update Invest-in-patch?
      ]
    ]
  ]
end

to interest-formula-output
   if invest-formula = "Simple" [set investment-output (investment * (1 + interest-rate))]                                            ;; Simple Interest Formula
   if invest-formula = "Compound" [set investment-output (investment * (1 + interest-rate) ^ bandit-invest-time)]                                ;; Compound Interest Formula
   if invest-formula = "Exponential" [set investment-output (investment * e ^ (interest-rate * bandit-invest-time))]                                ;; Exponential
end

to fight?
  ask bandits [
   set fight-counter 0
   if any? other bandits-here [
    let others-on-patch other bandits-here                                                    ; ID other bandits on patch
                                                                                              ; Compare with the strength of other bandits on the same patch
    if strength <= max [strength] of others-on-patch [                                            ; If strength is less than the other bandits
       set Winner? false                                                                     ; Set Winner False
       set fight-counter fight-counter + 1
     ]
    if strength > max [strength] of others-on-patch [
       set Winner? True
       set fight-counter fight-counter + 1
    ]

    if Winner? [
                                                                                              ;; Should there be a wealth transfer or cost?
    ]

    if not Winner? [
      set heading random 360                                                                  ;; Run a random direction.
      forward 3                                                                               ;; Run 3 steps
    ]
  ]
 ]

end

to patch-action
  ask patches [
    let Wealth0A Wealth0
    if Wealth0A = 0 [set Wealth0A 1]
    let D-Wealth ((wealth1 - Wealth0A) / Wealth0A)                        ;;
    if D-Wealth > 0[
     if not p-invested? [                                                   ;;
      patch-investment
      set p-invested? True
      set p-investment-bloomed? False
    ]
     if p-invested? and counter0 = patch-invest-time [
      set wealth1 wealth1 + patch-investment-output
      set p-invested? False
      set p-investment-bloomed? True
    ]
      if p-invested? and counter0 != patch-invest-time[set counter0 counter0 + 1]
   ]
  ]
end

to patch-investment
  set patch-investment-amount wealth1 * patch-investment-rate
  set counter0 0
  if invest-formula = "Simple" [
    set patch-investment-output (patch-investment-amount * (1 + interest-rate))
    set patch-investment-output abs(random-normal patch-investment-output (sqrt(abs(patch-investment-output))))
  ]                                            ;; Simple Interest Formula
  if invest-formula = "Compound" [
    set patch-investment-output (patch-investment-amount * (1 + interest-rate) ^ patch-invest-time)
    set patch-investment-output abs(random-normal patch-investment-output (sqrt(abs(patch-investment-output))))
  ]                                ;; Compound Interest Formula
  if invest-formula = "Exponential" [
    set patch-investment-output (patch-investment-amount * e ^ (interest-rate * patch-invest-time))
    set patch-investment-output abs(random-normal patch-investment-output (sqrt(abs(patch-investment-output))))
  ]                                ;; Exponential Growth (Continuous Compounding) Formula
end


to outcome

 ask bandits [
    ; let base-attrition sqrt(abs(wealth))
    set wealth (wealth - flat-attrition - (wealth * attrition-rate))                                     ; attrition is a base amount plus some relative amount

    if wealth <= 0 [die]
    let wealth-scale log wealth 10                                                           ; Creating wealth-scale based on log 10 of wealth
    set size wealth-scale
  ]

  ask patches [
   if Wealth1 = 0 [set Wealth1 abs(round random-normal patch-wealth-m Patch-wealth-sd)] ;; If Wealth is 0, set it based on M and SD

   let max_pwealth Max [wealth1] of patches
   set pcolor scale-color green wealth1 max_pwealth 0


  ]
end

to Reproduce
  let total-bandits count bandits
  if Reproduce? and total-bandits < 75 [
    ask bandits with [Wealth > 100][
     set Wealth Wealth - 100
     if random-float 100 < spawn-rate [
      hatch 1  [
        setxy random-xcor random-ycor]
     ]
    ]
  ]
end


to Update-DM
  ask bandits[
   if tax-rate > 1 [set tax-rate 0.99]
   if tax-rate < 0 [set tax-rate 0.01]

  ;; Total Fights:
  set total-fights total-fights + fight-counter

  let MaxWealth max [wealth] of turtles
  let MinWealth min [wealth] of turtles
  let MaxMinWealth MaxWealth - MinWealth
  if MaxMinWealth = 0 [set MaxMinWealth 1]
  set size 1 + ((Wealth - MinWealth) / (MaxMinWealth))                                                       ;; Normalize the Res value to a scale of 0 to 1
  ]
end


to Update-Visuals
 ask turtles[
  ;; Update Stationary Variable Values
  ifelse any? turtles with [color = red][set Stationary_Wealth_Avg Mean [Wealth] of turtles with [color = red]][set Stationary_Wealth_Avg 0]                                              ;; Calculate the mean wealth for stationary bandits
  ifelse any? turtles with [color = red][set Stationary_Wealth_Outcome Mean [Investment-output + Taxes] of turtles with [color = red]][set Stationary_Wealth_Outcome 0]                                              ;; Calculate the mean wealth for stationary bandits

  ;; Update Roaming Variable Values
  ifelse any? turtles with [color = blue][set Roaming_Wealth_Avg Mean [Wealth] of turtles with [color = blue]][set Roaming_Wealth_Avg 0]                                              ;; Calculate the mean wealth for stationary bandits
  ifelse any? turtles with [color = blue][set Roaming_Wealth_Outcome Mean [Investment-output + Taxes] of turtles with [color = blue]][set Roaming_Wealth_Outcome 0]                                              ;; Calculate the mean wealth for stationary bandits


    if any? turtles with [color = red and counter1 != 0][set time-to-bloom bandit-invest-time - counter1]
 ]


end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
647
448
-1
-1
13.0
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

BUTTON
7
10
71
43
NIL
Setup
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
71
10
134
43
NIL
Go
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
134
10
197
43
NIL
Go
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
212
495
384
528
Patch-wealth-sd
Patch-wealth-sd
0
50
5.0
1
1
NIL
HORIZONTAL

SLIDER
212
464
384
497
patch-wealth-m
patch-wealth-m
0
100
15.0
1
1
NIL
HORIZONTAL

SLIDER
3
87
175
120
initial-bandits
initial-bandits
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
6
499
178
532
bandit-wealth-m
bandit-wealth-m
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
6
532
178
565
bandit-wealth-sd
bandit-wealth-sd
0
50
25.0
1
1
NIL
HORIZONTAL

SLIDER
3
154
175
187
obs-range-m
obs-range-m
0
5
2.0
1
1
NIL
HORIZONTAL

SLIDER
4
187
176
220
obs-range-sd
obs-range-sd
0
5
1.0
0.25
1
NIL
HORIZONTAL

SLIDER
6
566
178
599
bandit-strength-m
bandit-strength-m
0
10
5.0
0.25
1
NIL
HORIZONTAL

SLIDER
6
598
178
631
bandit-strength-sd
bandit-strength-sd
0
5
2.5
0.25
1
NIL
HORIZONTAL

SLIDER
7
630
179
663
bandit-tax-rate-m
bandit-tax-rate-m
0
1
0.65
0.05
1
NIL
HORIZONTAL

SLIDER
7
664
179
697
bandit-tax-rate-sd
bandit-tax-rate-sd
0
1
0.25
0.05
1
NIL
HORIZONTAL

SLIDER
7
696
179
729
bandit-invest-rate-m
bandit-invest-rate-m
0
1
0.25
0.05
1
NIL
HORIZONTAL

SLIDER
7
729
179
762
bandit-invest-rate-sd
bandit-invest-rate-sd
0
1
0.1
0.05
1
NIL
HORIZONTAL

SLIDER
3
120
175
153
percent-stationary
percent-stationary
0
1
0.5
0.05
1
NIL
HORIZONTAL

SLIDER
4
220
176
253
move-cost
move-cost
0
10
4.0
1
1
NIL
HORIZONTAL

SLIDER
4
253
176
286
win-threshold-m
win-threshold-m
0
1
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
4
285
176
318
win-threshold-sd
win-threshold-sd
0
5
1.25
0.25
1
NIL
HORIZONTAL

SLIDER
5
319
177
352
interest-rate
interest-rate
0
1
0.05
0.01
1
NIL
HORIZONTAL

MONITOR
708
197
788
242
Pref-best-rate
((count turtles with [pref-best = True]) / (count turtles))
2
1
11

SLIDER
7
763
179
796
bandit-invest-time-m
bandit-invest-time-m
0
25
5.0
1
1
NIL
HORIZONTAL

SLIDER
7
796
179
829
bandit-invest-time-sd
bandit-invest-time-sd
0
10
2.0
1
1
NIL
HORIZONTAL

MONITOR
650
151
708
196
Winners
count turtles with [winner? = True]
1
1
11

MONITOR
708
151
758
196
Losers
count turtles with [winner? = False]
17
1
11

PLOT
822
12
1022
162
Roaming vs Stationary Outcome
Time
Wealth
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Roam" 1.0 0 -13791810 true "" "plot Roaming_Wealth_Avg"
"Stat" 1.0 0 -5298144 true "" "plot Stationary_Wealth_Avg"

CHOOSER
526
495
649
540
invest-formula
invest-formula
"Simple" "Compound" "Exponential"
2

SLIDER
6
385
178
418
attrition-rate
attrition-rate
0
1
0.25
0.01
1
NIL
HORIZONTAL

MONITOR
651
15
708
60
Bandits
count turtles
0
1
11

MONITOR
651
60
708
105
Roaming
count turtles with [color = blue]
17
1
11

MONITOR
709
60
780
105
Stationary
count turtles with [color = red]
17
1
11

MONITOR
652
106
709
151
fights
fight-counter
17
1
11

PLOT
822
161
1022
311
Roaming vs Stationary Bandits Phase Portraits
Stationary Wealth
Roaming Wealth
0.0
10.0
0.0
10.0
true
false
"set-plot-x-range 0.00 1.00\nset-plot-y-range 0.00 1.00" ""
PENS
"default" 1.0 2 -16777216 true "" "plotxy (Stationary_Wealth_Avg) (Roaming_Wealth_Avg)"

SWITCH
526
462
649
495
Reproduce?
Reproduce?
0
1
-1000

SLIDER
5
352
177
385
spawn-rate
spawn-rate
0
100
5.0
1
1
NIL
HORIZONTAL

SLIDER
212
528
384
561
patch-invest-time-m
patch-invest-time-m
0
25
4.0
1
1
NIL
HORIZONTAL

SLIDER
212
563
384
596
patch-invest-time-sd
patch-invest-time-sd
0
10
2.0
1
1
NIL
HORIZONTAL

SLIDER
213
596
385
629
patch-invest-rate-m
patch-invest-rate-m
0
1
0.1
0.01
1
NIL
HORIZONTAL

SLIDER
212
632
384
665
patch-invest-rate-sd
patch-invest-rate-sd
0
1
0.05
0.01
1
NIL
HORIZONTAL

PLOT
1023
312
1223
462
Bandits Wealth
Wealth
Frequency
0.0
10.0
0.0
10.0
true
false
"" "set-plot-y-range 0 5\nset-plot-x-range 0 100"
PENS
"default" 1.0 1 -16777216 true "" "histogram [wealth] of turtles"

PLOT
822
493
1022
643
Patch Wealth
Wealth
Frequency
0.0
10.0
0.0
10.0
true
false
"" "set-plot-y-range 0 25\nset-plot-x-range 0 250\n\n"
PENS
"default" 1.0 1 -16777216 true "" "histogram [wealth1] of patches"

PLOT
1280
12
1480
162
Roaming Tax-Rate
Tax-Rate
Frequency
0.0
1.0
0.0
10.0
true
false
"" "set-plot-y-range 0 5\nset-plot-x-range 0 1\nset-histogram-num-bars 25\n"
PENS
"default" 1.0 1 -16777216 true "" "Histogram [tax-rate] of turtles with [color = blue]"

PLOT
1280
160
1480
310
Stationary Tax-Rate
Tax-Rate
Frequency
0.0
1.0
0.0
10.0
true
false
"" "set-plot-y-range 0 5\nset-plot-x-range 0 1\nset-histogram-num-bars 25"
PENS
"default" 1.0 1 -16777216 true "" "Histogram [tax-rate] of turtles with [color = red]"

MONITOR
1480
210
1534
255
Avg Tax
mean [Tax-Rate] of turtles with [color = red]
2
1
11

MONITOR
1479
256
1535
301
Med Tax
median [Tax-Rate] of turtles with [color = red]
2
1
11

MONITOR
1480
57
1535
102
Avg Tax
mean [Tax-Rate] of turtles with [color = blue]
2
1
11

MONITOR
1480
102
1535
147
Med Tax
median [Tax-Rate] of turtles with [color = blue]
2
1
11

PLOT
1280
310
1480
460
Taxes Captured
Frequency
Tax-Rate
0.0
10.0
0.0
10.0
true
false
"" "set-plot-y-range 0 5\nset-plot-x-range 0 250\nset-histogram-num-bars 25\n"
PENS
"default" 1.0 1 -16777216 true "" "Histogram [taxes] of turtles"

PLOT
1535
13
1735
163
Roaming Invest-Rate
Invest-Rate
Frequency
0.0
1.0
0.0
10.0
true
false
"" "set-plot-y-range 0 5\nset-plot-x-range 0 1\nset-histogram-num-bars 10"
PENS
"default" 1.0 1 -16777216 true "" "Histogram [invest-patch-rate] of turtles with [color = blue]"

PLOT
1535
163
1735
313
Stationary Invest-Rate
Investment-Rate
Frequency
0.0
10.0
0.0
10.0
true
false
"" "set-plot-y-range 0 5\nset-plot-x-range 0 1\nset-histogram-num-bars 25"
PENS
"default" 1.0 1 -16777216 true "" "Histogram [invest-patch-rate] of turtles with [color = red]"

MONITOR
1735
165
1792
210
Avg Inv
mean [invest-patch-rate] of turtles with [color = red]
2
1
11

MONITOR
1735
210
1792
255
Med Inv
median [invest-patch-rate] of turtles with [color = red]
2
1
11

MONITOR
1735
14
1803
59
Max Inv
max [invest-patch-rate] of turtles with [color = blue]
2
1
11

MONITOR
1735
59
1803
104
Med Inv
median [invest-patch-rate] of turtles with [color = blue]
2
1
11

PLOT
2103
12
2303
162
Investment-Time
Investment-Time
Frequency
0.0
10.0
0.0
10.0
true
false
"" "set-plot-y-range 0 5\nset-plot-x-range 0 30\n\n\n"
PENS
"default" 1.0 1 -16777216 true "" "Histogram [bandit-invest-time] of turtles"

MONITOR
2303
60
2399
105
Avg Invest-Time
mean [bandit-invest-time] of turtles
2
1
11

MONITOR
2303
105
2399
150
Med Invest-Time
median [bandit-invest-time] of turtles
2
1
11

MONITOR
1735
104
1803
149
Active Inv
count turtles with [invest-in-patch? = True and Color = Blue]
0
1
11

MONITOR
1630
314
1742
359
Bandit Not Invested
count turtles with [invest-in-patch? = False]
0
1
11

MONITOR
651
197
708
242
Pref-Best
count turtles with [pref-best = True]
17
1
11

MONITOR
1735
256
1792
301
Med ROI
median [investment-output-value] of turtles with [Color = Red]
1
1
11

PLOT
2103
162
2303
312
Time until Investment Blooms
Time
Frequency
0.0
10.0
0.0
10.0
true
false
"" "set-plot-y-range 0 5\nset-plot-x-range 0 15\n\n\n"
PENS
"default" 1.0 1 -16777216 true "" "Histogram [time-to-bloom] of turtles with [Color = Red]"

MONITOR
2303
162
2399
207
Max Bloom-Time
max [time-to-bloom] of turtles
17
1
11

MONITOR
2303
252
2399
297
Med Bloom-Time
median [time-to-bloom] of turtles
0
1
11

MONITOR
2303
207
2399
252
Avg Bloom-Time
Mean [time-to-bloom] of turtles
2
1
11

MONITOR
1536
314
1631
359
Bandits Invested
count turtles with [invest-in-patch? = True]
17
1
11

SLIDER
7
418
178
451
flat-attrition
flat-attrition
0
100
1.0
1
1
NIL
HORIZONTAL

MONITOR
1776
644
1866
689
Patch-Bloomed
Count patches with [p-investment-bloomed? = True]
1
1
11

MONITOR
1023
494
1096
539
Max Wealth
Max [wealth1] of patches
1
1
11

MONITOR
1023
538
1096
583
Avg Wealth
Mean [wealth1] of patches
1
1
11

MONITOR
1023
583
1096
628
Med Wealth
median [wealth1] of patches
1
1
11

TEXTBOX
691
468
841
488
Patches:
16
0.0
1

MONITOR
1096
644
1192
689
Max Invest-Time
max [patch-invest-time] of turtles
1
1
11

MONITOR
1096
689
1192
734
Avg Invest-Time
mean [patch-invest-time] of turtles
1
1
11

MONITOR
1192
689
1288
734
Med Invest-Time
median [patch-invest-time] of turtles
17
1
11

MONITOR
651
497
719
542
Patches
count patches
0
1
11

PLOT
1295
493
1495
643
Patch Investment-Rate
Time
Frequency
0.0
10.0
0.0
10.0
true
false
"" "set-plot-y-range 0 100\nset-plot-x-range 0 1\nset-histogram-num-bars 20"
PENS
"default" 1.0 1 -16777216 true "" "histogram [patch-investment-rate] of patches"

MONITOR
1297
644
1389
689
Max Invest-Rate
max [patch-investment-rate] of turtles
2
1
11

MONITOR
1298
689
1389
734
Avg Invest-Rate
mean [patch-investment-rate] of turtles
2
1
11

MONITOR
1389
689
1484
734
Med Invest-Rate
median [patch-investment-rate] of turtles
2
1
11

PLOT
1023
13
1223
163
Roaming Bandit Wealth
Wealth
Frequency
0.0
10.0
0.0
10.0
true
false
"" "set-plot-y-range 0 5\nset-plot-x-range 0 100"
PENS
"default" 1.0 1 -16777216 true "" "histogram [wealth] of turtles with [color = blue]"

MONITOR
1223
13
1281
58
Max W
max [wealth] of turtles with [color = blue]
1
1
11

MONITOR
1223
58
1281
103
Avg W
mean [wealth] of turtles with [color = blue]
1
1
11

MONITOR
1223
103
1281
148
Med W
median [wealth] of turtles with [color = blue]
1
1
11

MONITOR
1480
13
1535
58
Max Tax
max [Tax-Rate] of turtles with [color = blue]
2
1
11

MONITOR
1480
165
1535
210
Max Tax
max [Tax-Rate] of turtles with [color = red]
2
1
11

PLOT
1023
162
1223
312
Stationary Bandit Wealth
Wealth
Frequency
0.0
10.0
0.0
10.0
true
false
"" "set-plot-y-range 0 5\nset-plot-x-range 0 100"
PENS
"default" 1.0 1 -16777216 true "" "histogram [wealth] of turtles with [color = red]"

MONITOR
1223
165
1281
210
Max W
max [wealth] of turtles with [color = red]
1
1
11

MONITOR
1223
210
1281
255
Avg W
mean [wealth] of turtles with [color = red]
1
1
11

MONITOR
1223
255
1281
300
Med W
median [wealth] of turtles with [color = red]
1
1
11

MONITOR
1223
315
1281
360
Max W
max [wealth] of turtles
1
1
11

MONITOR
1223
359
1281
404
Avg W
mean [wealth] of turtles
1
1
11

MONITOR
1223
404
1281
449
Med W
median [wealth] of turtles
1
1
11

MONITOR
2303
15
2399
60
Max Invest-Time
max [bandit-invest-time] of turtles
1
1
11

PLOT
1803
162
2003
312
Investment Outputs
Wealth
Frequency
0.0
10.0
0.0
10.0
true
false
"" "set-plot-y-range 0 5\nset-plot-x-range 0 100\n"
PENS
"default" 1.0 1 -16777216 true "" "Histogram [investment-output-value] of turtles with [Color = Red]"

MONITOR
2003
163
2103
208
Max Inv Output
max [investment-output-value] of turtles
1
1
11

MONITOR
2003
207
2103
252
Avg Inv Output
mean [investment-output-value] of turtles
1
1
11

MONITOR
2003
253
2103
298
Med Inv Output
median [investment-output-value] of turtles
1
1
11

SLIDER
7
452
180
485
defensive-bonus
defensive-bonus
0
10
2.0
1
1
NIL
HORIZONTAL

PLOT
1095
493
1295
643
Patch-Investment-Time
Time
Frequency
0.0
10.0
0.0
10.0
true
false
"" "set-plot-y-range 0 10\nset-plot-x-range 0 20\nset-histogram-num-bars 20"
PENS
"default" 1.0 1 -16777216 true "" "histogram [patch-invest-time] of patches"

MONITOR
709
106
788
151
Total Fights
total-fights
0
1
11

PLOT
823
312
1023
462
Bandits Population
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
"Roam" 1.0 0 -13791810 true "" "plot count turtles with [color = blue]"
"Stat" 1.0 0 -2674135 true "" "plot count turtles with [color = red]"

PLOT
1495
493
1695
643
Patch Investment Amount
Investment
Frequency
0.0
10.0
0.0
10.0
true
false
"" "set-plot-y-range 0 10\nset-plot-x-range 0 100\nset-histogram-num-bars 20"
PENS
"default" 1.0 1 -16777216 true "" "histogram [patch-investment-amount] of patches"

MONITOR
1496
644
1590
689
Max Investment
Max [patch-investment-amount] of patches
1
1
11

MONITOR
1496
689
1590
734
Avg Investment
mean [patch-investment-amount] of patches
1
1
11

MONITOR
1589
689
1683
734
Med Investment
Median [patch-investment-amount] of patches
1
1
11

PLOT
1695
493
1895
643
Patch Investment Output
Investment Payout
Frequency
0.0
10.0
0.0
10.0
true
false
"" "set-plot-y-range 0 10\nset-plot-x-range 0 100\nset-histogram-num-bars 20"
PENS
"default" 1.0 1 -16777216 true "" "histogram [patch-investment-output] of patches"

MONITOR
1696
644
1776
689
Max Output
Max [patch-investment-output] of patches
1
1
11

MONITOR
1696
689
1776
734
Avg Output
mean [patch-investment-amount] of patches
1
1
11

MONITOR
1776
689
1856
734
Med Output
Median [patch-investment-amount] of patches
1
1
11

PLOT
1803
12
2003
162
Investment Amount
Wealth
Frequency
0.0
10.0
0.0
10.0
true
false
"" "set-plot-y-range 0 5\nset-plot-x-range 0 100\n"
PENS
"default" 1.0 1 -16777216 true "" "Histogram [investment] of turtles with [Color = Red]"

MONITOR
2003
13
2103
58
Max Investment
max [investment] of turtles
1
1
11

MONITOR
2003
58
2103
103
Avg Investment
mean [investment] of turtles
1
1
11

MONITOR
2003
104
2103
149
Med Investment
median [investment] of turtles
1
1
11

MONITOR
1480
314
1536
359
Max Tax
max [Taxes] of turtles
1
1
11

MONITOR
1480
359
1537
404
Avg Tax
mean [Taxes] of turtles
1
1
11

PLOT
823
644
1023
794
Patch Wealth Line-Graph
Time
Wealth
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Mean" 1.0 0 -13840069 true "" "plot mean [wealth1] of patches"
"Max" 1.0 0 -955883 true "" "plot max [wealth1] of patches"
"Median" 1.0 0 -5825686 true "" "plot median [wealth1] of patches"

PLOT
824
794
1024
944
Stationary Patches
Time
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Mean" 1.0 0 -13840069 true "" "if any? turtles with [color = red][plot mean [wealth1] of patches with [any? turtles-here with [color = red]]]"
"Max" 1.0 0 -955883 true "" "if any? turtles with [color = red][plot max [wealth1] of patches with [any? turtles-here with [color = red]]]"
"Median" 1.0 0 -5825686 true "" "if any? turtles with [color = red][plot median [wealth1] of patches with [any? turtles-here with [color = red]]]"

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
NetLogo 6.3.0
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
