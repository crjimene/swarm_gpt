;; VoidsGPT: Modelling Bird flocking with Generative AI

;; Author: Cristian Jimenez Romero - CY Cergy Paris University - 2025
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

extensions [ py ]

globals
[
  is-stopped?          ; flag to specify if the model is stopped
  food_collected
  step_added_distance
  step_added_heading
  overall_distances
  overall_headings
  activate_llm
]

breed [birds bird]

birds-own [
  flockmates         ;; agentset of nearby turtles
  nearest-neighbor   ;; closest one of our flockmates
  neighbors-text
  myheading
  flockmates-list
  bird-id
  action-new_heading
  action-status-ok
  action-status-code
  recovered_heading
]

to setup_birds
  clear-all
  set activate_llm true
  random-seed read-from-string used_seed

  set step_added_distance 0
  set step_added_heading 0
  set overall_distances 0
  set overall_headings 0
  create-birds 50
  [
    set bird-id who
    set size 2;
    set color yellow - 2 + random 7  ;; random shades look nice
    setxy random-xcor random-ycor
    set flockmates no-turtles
    set neighbors-text "no neighbors in vision radius"
    set myheading heading
    set shape "hawk"
 ]
  reset-ticks
end

to go_birds  ;; forever button
  let max-separate-turn-text (word "max_separate_turn_text = '" precision (max-separate-turn) 2 "'")
  py:run max-separate-turn-text
  let max-align-turn-text (word "max_align_turn_text = '" precision (max-align-turn) 2 "'")
  py:run max-align-turn-text
  let max-cohere-turn-text (word "max_cohere_turn_text = '" precision (max-cohere-turn) 2 "'")
  py:run max-cohere-turn-text
  let minimum-separation-text (word "minimum_separation_text = '" precision (minimum-separation) 2 "'")
  py:run minimum-separation-text

  let step_text ( word "step: " ticks )
  print step_text
  ask birds
  [
    ifelse bird-id < num_gpt_birds [
      set color red
      sense-world
      ifelse activate_llm [ run_llm ][ set heading recovered_heading ]

    ]
    [
       flock
    ]

  ]
  repeat 5 [ ask turtles [ fd 0.2 ] display ]
  print "end step"
  with-local-randomness [ calculate-differences ]
  tick
end

to flock
  find-flockmates
  if any? flockmates
    [ find-nearest-neighbor
      ifelse distance nearest-neighbor < minimum-separation
        [ separate ]
        [ align
          cohere ] ]
end

;;; SEPARATE

to separate  ;; turtle procedure
  turn-away ([heading] of nearest-neighbor) max-separate-turn

end

;;; ALIGN

to align  ;; turtle procedure
  if bird-id <= 0 [
    print ( word "Align: " average-flockmate-heading )
  ]
  turn-towards average-flockmate-heading max-align-turn
end

to-report average-flockmate-heading  ;; turtle procedure
  ;; We can't just average the heading variables here.
  ;; For example, the average of 1 and 359 should be 0,
  ;; not 180.  So we have to use trigonometry.
  let x-component sum [dx] of flockmates
  let y-component sum [dy] of flockmates
  ifelse x-component = 0 and y-component = 0
    [ report heading ]
    [ report atan x-component y-component ]
end

;;; COHERE

to cohere
  turn-towards average-heading-towards-flockmates max-cohere-turn
end

to-report average-heading-towards-flockmates  ;; turtle procedure
  ;; "towards myself" gives us the heading from the other turtle
  ;; to me, but we want the heading from me to the other turtle,
  ;; so we add 180
  let x-component mean [sin (towards myself + 180)] of flockmates
  let y-component mean [cos (towards myself + 180)] of flockmates
  ifelse x-component = 0 and y-component = 0
    [ report heading ]
    [ report atan x-component y-component ]
end

;;; HELPER PROCEDURES

to turn-towards [new-heading max-turn]  ;; turtle procedure
  turn-at-most (subtract-headings new-heading heading) max-turn
end

to turn-away [new-heading max-turn]  ;; turtle procedure
  turn-at-most (subtract-headings heading new-heading) max-turn
end

;; turn right by "turn" degrees (or left if "turn" is negative),
;; but never turn more than "max-turn" degrees
to turn-at-most [turn max-turn]  ;; turtle procedure
  ifelse abs turn > max-turn
    [ ifelse turn > 0
        [ rt max-turn ]
        [ lt max-turn ] ]
    [ rt turn ]
end

to find-flockmates  ;; turtle procedure
  set flockmates other turtles in-radius vision
end

to find-nearest-neighbor ;; turtle procedure
  set nearest-neighbor min-one-of flockmates [distance myself]
end

to find-flockmates-llm  ;; turtle procedure
  set flockmates other turtles in-radius vision
  set flockmates-list []
  let my-x xcor
  let my-y ycor
  if any? flockmates [
     ask flockmates [
      let relative-x (xcor - my-x)
      let relative-y (ycor - my-y)
      let flockmate-data (list heading relative-x relative-y)
      ask myself [ set flockmates-list lput flockmate-data flockmates-list ]
     ]
  ]
end

to find-flockmates-llm2  ;; turtle procedure
  set flockmates other turtles in-radius vision
  set flockmates-list []
  let my-x xcor
  let my-y ycor

  if any? flockmates [
    ; Create a list of flockmates with distance information
    let flockmates-with-distance []
    ask flockmates [
      let distance-to-me distance myself
      set flockmates-with-distance lput (list self distance-to-me) flockmates-with-distance
    ]

    ; Sort flockmates by distance (ascending)
    let sorted-flockmates flockmates-with-distance
    let num-flockmates length sorted-flockmates

    ; Perform bubble sort to sort the list by distance without using `?`
    let swapped true
    while [swapped] [
      set swapped false
      let i 0
      while [i < (num-flockmates - 1)] [
        let current-data item i sorted-flockmates
        let next-data item (i + 1) sorted-flockmates
        let current-distance item 1 current-data
        let next-distance item 1 next-data

        if (current-distance > next-distance) [
          ; Swap the current and next elements
          set sorted-flockmates replace-item i sorted-flockmates next-data
          set sorted-flockmates replace-item (i + 1) sorted-flockmates current-data
          set swapped true
        ]
        set i i + 1
      ]
    ]

    ; Select the closest 8 flockmates (or fewer if there aren't that many)
    let closest-flockmates n-of (min list 8 num-flockmates) sorted-flockmates

    ; Update the flockmates-list with relative positions of closest flockmates
    let closest-count length closest-flockmates
    let j 0
    repeat closest-count [
      let flockmate-data item j closest-flockmates
      let flockmate-agent item 0 flockmate-data
      let relative-x ([xcor] of flockmate-agent - my-x)
      let relative-y ([ycor] of flockmate-agent - my-y)
      let flockmate-info (list [heading] of flockmate-agent relative-x relative-y)
      set flockmates-list lput flockmate-info flockmates-list
      set j j + 1
    ]
  ]
end

to-report generate-neighbor-info
  let info-string ""
  let counter 1
  foreach flockmates-list [
    neighbor ->
    let nheading item 0 neighbor
    let nx item 1 neighbor
    let ny item 2 neighbor
    let neighbor-info (word "neighbor_" counter ": x: " precision (nx) 2 ", y: " precision (ny) 2 ", heading: " precision (nheading) 2 " deg")
    set info-string (word info-string neighbor-info "; ")
    set counter (counter + 1)
  ]
  if info-string = "" [ set info-string "no neighbors in vision radius" ]
  report info-string
end

to sense-world

  find-flockmates-llm
  set neighbors-text generate-neighbor-info
  set myheading ( word precision (heading) 2 )

end

to setup
  setup_birds
  set activate_llm true
  py:setup py:python
  py:run "import math"
  py:run "import sys"
  py:run "import ollama"
  py:run "import json"
  py:run "from openai import OpenAI"
  py:run "client = OpenAI(api_key='Insert you API-key here')"
  py:run "elements_list = []"
  py:run "max_separate_turn_text = 0.0"
  py:run "max_align_turn_text = 0.0"
  py:run "max_cohere_turn_text = 0.0"
  py:run "minimum_separation_text = 0.0"
  (py:run
    "def parse_response(response):"
    "    text = response #text = response['response']"
    "    print('Raw response: ', text)"
    "    text = text.lower()"
    "    text = text.strip()"
    "    text = text.replace(chr(39), chr(34))"
    "    text = text.replace('_', '-')"
    "    parse_ok = 'True'"
    "    error_code = 'None'"
    "    try:"
    "        index = text.find( chr(34) + 'new-heading' + chr(34) + ':' )"
    "        text = text[index + 14:]"
    "        index = text.find('}')"
    "        text = text[:index]"
    "        text = text.strip()"
    "        print ('pre-processed-text: *****', text, '*****')"
    "        new_heading = text"
    "        new_heading = str(new_heading)"
    "        elements_list.append(parse_ok)"
    "        elements_list.append(error_code)"
    "        elements_list.append(new_heading.lower())"
    "        print('Parsed ok: ', elements_list)"
    "    except json.JSONDecodeError as e:"
    "        error_code = str(e)"
    "        parse_ok = 'False'"
    "        elements_list.append(parse_ok)"
    "        elements_list.append(error_code)"
    "        print ('Error: ', error_code)"
    "    except Exception as e:"
    "        error_code = str(e)"
    "        parse_ok = 'False'"
    "        elements_list.append(parse_ok)"
    "        elements_list.append(error_code)"
    "        print ('Error: ', error_code)"
    "def create_prompt(bird_heading, bird_neighbors, max_separate_turn_text, max_align_turn_text, max_cohere_turn_text, minimum_separation_text):"
    "    system_text =  'You are an agent in a 2D simulation. Following the compass convention, your task is to determine your new heading based on the flocking principles of separation turn, alignment turn (average heading of neighbors), and coherence turn (average heading towards flockmates). The parameters for these principles are: maximum-separate-turn, maximum-align-turn, maximum-cohere-turn, minimum-separation-distance. The simulation provides the following information: Current heading, Neighbors in vision radius. When calculating the alignment turn, always choose the shortest path (clockwise or counterclockwise) to align with the average heading of neighbors. Provide your final new heading after applying these rules, expressed as an angle in degrees. The result should be in JSON format only, with the keys and values: ' + chr(34) + 'rationale' + chr(34) + ' (value: your explanation) and ' + chr(34) + 'new-heading' + chr(34) + ' (value: heading in degrees). '" ;
    "    prompt_text = 'These are the flocking parameters: -Maximum separate turn: ' + max_separate_turn_text + ', -Maximum align turn: ' + max_align_turn_text + ', -Maximum cohere turn: ' + max_cohere_turn_text + ', -Minimum separation: ' + minimum_separation_text + '; This is your current environment: -Current heading: ' + bird_heading + ' deg, -Neighbors in vision radius: ' + bird_neighbors"
    "    return prompt_text, system_text"
    "def process_step(file_name, step):"
    "    # Open the text file"
    "    with open(file_name, 'r') as file:"
    "        lines = file.readlines()"
    "    # Initialize variables"
    "    in_step_section = False"
    "    in_bird_section = False"
    "    actions_list = []"
    "    bird_info = {}"
    "    # Iterate through the lines"
    "    for line in lines:"
    "        # Check for the start of the step section"
    "        if line.strip() == f'step: {step}':"
    "            in_step_section = True"
    "            continue"
    "        # Check for the end of the step section"
    "        if line.strip() == 'end step':"
    "            if in_step_section:"
    "                break"
    "            else:"
    "                continue"
    "        # If we are in the correct step section, look for bird sections"
    "        if in_step_section:"
    "            if line.startswith('Start-BirdID:'):"
    "                in_bird_section = True"
    "                bird_id = line.split(':')[1].strip()"
    "                # Initialize variables for the new ant"
    "                bird_info = {"
    "                    'BirdID': bird_id,"
    "                    'heading': 0.0"
    "                }"
    "                print('Bird ID: ', bird_id)"
    "                continue"
    "            if line.startswith('End-BirdID:'):"
    "                end_bird_id = line.split(':')[1].strip()"
    "                if in_bird_section and end_bird_id == bird_info['BirdID']:"
    "                    in_bird_section = False"
    "                    # Add the bird_info to actions_list as a list of its values"
    "                    actions_list.append(["
    "                        bird_info['BirdID'],"
    "                        bird_info['action_ok'],"
    "                        bird_info['heading']"
    "                    ])"
    "                continue"
    "            # If we are in the correct bird section, check for the required texts"
    "            if in_bird_section:"
    "                if 'Parser ok' in line:"
    "                    bird_info['action_ok'] = True"
    "                if '--- action heading:' in line:"
    "                    bird_heading = line.split(':')[1].strip()"
    "                    bird_info['heading'] = bird_heading"
    "                    print('Bird heading: ', bird_heading)"
    "    # Return the actions list"
    "    return actions_list    "
   )
end

to-report get_llm_data
   let llm_data py:runresult "elements_list"
   report llm_data
end


to-report populate_bird_with_llm_data [ llm_data ]
  let parse_ok item 0 llm_data
  let return_ok true
  ifelse parse_ok = "True" [
    print "Parser ok"
    set action-new_heading item 2 llm_data
    set action-status-ok true
    set action-status-code 0

    set heading ( read-from-string action-new_heading )
    print ( word "--- action heading:" read-from-string action-new_heading )
  ]
  [
    print "Parser error"
    set action-status-ok false
    set action-status-code 1
    set return_ok false
  ]
  print "end parser"
  report return_ok
end


to run_llm
  print (word "Start-BirdID: " bird-id)
  let populate_prompt (word "prepared_prompt, system_prompt = create_prompt('" myheading "', '" neighbors-text "', max_separate_turn_text, max_align_turn_text, max_cohere_turn_text, minimum_separation_text)" )
  py:run populate_prompt
  py:run "elements_list = []"
  py:run "print('User prompt: ' + prepared_prompt)"
  py:run "print('Complete prompt: ' + system_prompt + prepared_prompt)"
  py:run "response = client.chat.completions.create(model= 'gpt-4o', max_tokens=800, timeout=30, messages=[ {'role': 'system', 'content': system_prompt}, {'role': 'user', 'content': prepared_prompt}], temperature=0.0)" ;gpt-4o-2024-05-13;
  py:run "response = response.choices[0].message.content"

  py:run "parse_response(response)"
  print "--------------- llm data: ----------------"
  carefully [
    let llm_data get_llm_data
    let populate_ok populate_bird_with_llm_data llm_data
  ]
  [
    print "Error: parsing failed!"
  ]
  print (word "End-BirdID: " bird-id)

end


to decode_action
  py:run "elements_list = []"
  py:run "test = True"
  py:run "test = str(test)"
  py:run "elements_list.append(test)"
  py:run "elements_list.append('second')"
  let result py:runresult "elements_list"
  let item1 item 0 result
  print(item1)
  if item1 = "True" [
    print "Correct!"
  ]

end

;; New procedure to calculate distances and heading differences between each pair of birds
to calculate-differences
  let distances [] ;; temporary list to store distances for current step
  let total-distance 0 ;; variable to store the sum of distances for the current step

  let heading-differences [] ;; temporary list to store heading differences for current step
  let total-heading-difference 0 ;; variable to store the sum of heading differences for the current step

  ;; Iterate over each turtle and calculate distances and heading differences to all other turtles
  ask turtles [
    let my-id who
    let my-heading heading
    ask other turtles [
      let other-id who
      let distance-to-other distance myself
      let heading-diff heading-difference my-heading [heading] of self
      ;print heading-diff

      ;; Store distance information
      set distances lput (list ticks my-id other-id distance-to-other) distances
      set total-distance total-distance + distance-to-other

      ;; Store heading difference information
      set heading-differences lput (list ticks my-id other-id heading-diff) heading-differences
      set total-heading-difference total-heading-difference + heading-diff
    ]
  ]
end

;; Helper function to calculate the shortest angular difference between two headings
to-report heading-difference [heading1 heading2]
  let diff (heading1 - heading2) mod 360
  if diff > 180 [
    set diff diff - 360
  ]
  report abs diff
end
@#$#@#$#@
GRAPHICS-WINDOW
310
10
886
587
-1
-1
8.0
1
7
1
1
1
0
1
1
1
-35
35
-35
35
0
0
1
ticks
30.0

BUTTON
65
400
240
433
Setup simulation
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
85
540
207
573
Run from LLM
go_birds\nif ticks = 800 [ stop ]
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
65
495
235
528
Run from log file
set activate_llm false\nlet step_num 0\nlet step_text \"\"\nlet filename ( word \"flockgpt_hybrid_seed_\" used_seed \".txt\")\n\nrepeat steps_to_load [ \nset step_text ( word \"process_step('\" filename \"',\" step_num \")\" )\nlet step_data py:runresult step_text \nprint ( word \"Number of steps: \" (length step_data) )\n\nlet index 0\nrepeat (length step_data) [ ; Iterate through each bird\n  let current_bird item index step_data ; Load next bird\n  let bird_data_id read-from-string( item 0 current_bird )\n  let bird_data_ok item 1 current_bird\n  print ( word \"NL BirdID: \" bird_data_id )\n  ifelse bird_data_ok = true [ ; Continue parsing if data integrity is ok\n    let bird_data_heading item 2 current_bird\n    ask bird bird_data_id [\n       carefully [\n         set recovered_heading read-from-string bird_data_heading\n       ]\n       [\n         print \"Error: parsing failed!\"\n       ]                                 \n    ]\n  ]\n  [\n    print \"ERROR WITH DATA INTEGRITY!\"\n    stop\n  ] \n  set index index + 1\n]\n  print \"end step\"\n  go_birds\n  set step_num step_num + 1\n]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
32
50
262
83
vision
vision
0.0
10.0
5.0
0.5
1
patches
HORIZONTAL

SLIDER
32
90
262
123
minimum-separation
minimum-separation
0.0
5.0
1.0
0.25
1
patches
HORIZONTAL

SLIDER
30
130
260
163
max-align-turn
max-align-turn
0.0
20.0
5.0
0.25
1
degrees
HORIZONTAL

SLIDER
30
170
260
203
max-cohere-turn
max-cohere-turn
0.0
20.0
3.0
0.25
1
degrees
HORIZONTAL

SLIDER
32
210
262
243
max-separate-turn
max-separate-turn
0.0
20.0
1.5
0.25
1
degrees
HORIZONTAL

SLIDER
30
10
265
43
population
population
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
30
275
260
308
num_gpt_birds
num_gpt_birds
1
10
5.0
1
1
NIL
HORIZONTAL

CHOOSER
30
330
260
375
used_seed
used_seed
"4891" "68295" "13420" "132500" "47822"
1

SLIDER
65
460
237
493
steps_to_load
steps_to_load
1
800
220.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## CREDITS AND REFERENCES

If you mention this model in a publication, we ask that you include these citations for the model itself and for the NetLogo software:


* Cristian Jimenez-Romero, Alper Yegenoglu, Christian Blum
Multi-Agent Systems Powered By Large Language Models: Applications In Swarm Intelligence. In ArXiv Pre-print, March 2025.


* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
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

hawk
true
0
Polygon -7500403 true true 151 170 136 170 123 229 143 244 156 244 179 229 166 170
Polygon -16777216 true false 152 154 137 154 125 213 140 229 159 229 179 214 167 154
Polygon -7500403 true true 151 140 136 140 126 202 139 214 159 214 176 200 166 140
Polygon -16777216 true false 151 125 134 124 128 188 140 198 161 197 174 188 166 125
Polygon -7500403 true true 152 86 227 72 286 97 272 101 294 117 276 118 287 131 270 131 278 141 264 138 267 145 228 150 153 147
Polygon -7500403 true true 160 74 159 61 149 54 130 53 139 62 133 81 127 113 129 149 134 177 150 206 168 179 172 147 169 111
Circle -16777216 true false 144 55 7
Polygon -16777216 true false 129 53 135 58 139 54
Polygon -7500403 true true 148 86 73 72 14 97 28 101 6 117 24 118 13 131 30 131 22 141 36 138 33 145 72 150 147 147

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
need-to-manually-make-preview-for-this-model
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
1
@#$#@#$#@
