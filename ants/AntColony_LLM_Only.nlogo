;; AntGPT Colony - LLM agents only
;; Author: Cristian Jimenez Romero - 2025

extensions [ py ]

patches-own [
  chemical             ;; amount of chemical on this patch
  food                 ;; amount of food on this patch (0, 1, or 2)
  nest?                ;; true on nest patches, false elsewhere
  nest-scent           ;; number that is higher closer to the nest
  food-source-number   ;; number (1, 2, or 3) to identify the food sources
]

globals
[
  is-stopped?          ; flag to specify if the model is stopped
  food_collected
  all-food-amounts
]

breed [ants ant]

ants-own [
  ant-id
  action-move_forward             ;; amount of chemical on this patch
  action-rotate                ;; amount of food on this patch (0, 1, or 2)
  action-pick_up_food                ;; true on nest patches, false elsewhere
  action-drop_pheromone           ;; number that is higher closer to the nest
  action-drop_food   ;; number (1, 2, or 3) to identify the food sources
  action-status-ok
  action-status-code
  sense-pheromone-left
  sense-pheromone-front
  sense-pheromone-right
  sense-on-nest
  sense-nest-left
  sense-nest-front
  sense-nest-right
  sense-food-quantity
  sense-carrying-food
]

to setup-patches
  ask patches
  [ setup-nest
    setup-food
    recolor-patch ]
end

to setup-nest  ;; patch procedure
  ;; set nest? variable to true inside the nest, false elsewhere
  set nest? (distancexy 0 0) < 5
  ;; spread a nest-scent over the whole world -- stronger near the nest
  set nest-scent 200 - distancexy 0 0
end

to setup-food  ;; patch procedure
  ;; setup food source one on the right
  if (distancexy (0.6 * max-pxcor) 0) < 5
  [ set food-source-number 1 ]
  ;; setup food source two on the lower-left
  if (distancexy (-0.6 * max-pxcor) (-0.6 * max-pycor)) < 5
  [ set food-source-number 2 ]
  ;; setup food source three on the upper-left
  if (distancexy (-0.8 * max-pxcor) (0.8 * max-pycor)) < 5
  [ set food-source-number 3 ]
  ;; set "food" at sources to either 1 or 2, randomly
  if food-source-number > 0
  [ set food one-of [1 2] ]
end

to recolor-patch  ;; patch procedure
  ;; give color to nest and food sources
  ifelse nest?
  [ set pcolor violet ]
  [ ifelse food > 0
    [ if food-source-number = 1 [ set pcolor cyan ]
      if food-source-number = 2 [ set pcolor sky  ]
      if food-source-number = 3 [ set pcolor blue ] ]
    ;; scale color to show chemical concentration
    [ set pcolor scale-color green chemical 0.1 5 ] ]
end

to setup_ants
  clear-all
  random-seed read-from-string used_seed  ;21504; 6890;351973;19562;47822
  set-default-shape turtles "bug"
  create-ants 10
  [ set ant-id who
    set sense-carrying-food "False"
    set size 2
    set color red
    setxy 0 0
  ]
  setup-patches
  set all-food-amounts []
  reset-ticks
end

to export-food-collected-to-csv [filename]
  ; Open the file for writing. The file will be saved in the current directory.
  file-open filename

  ; Write header row to the CSV file
  file-print "step_number,food_amount"
  ; Iterate over each step in all-distances
  let step-count length all-food-amounts
  let step-number 0
  repeat step-count [
    let step-data item step-number all-food-amounts
    file-print (word step-number "," step-data)
    set step-number step-number + 1
  ]
  ; Close the file after writing is done
  file-close
end

to setup
  setup_ants
  py:setup py:python
  py:run "import math"
  py:run "import sys"
  py:run "import json"
  py:run "from openai import OpenAI"
  py:run "client = OpenAI(api_key='Insert your API key here')"
  py:run "elements_list = []"
  (py:run
    "def parse_response(response):"
    "    text = response"
    "    text = text.lower()"
    "    text = text.strip()"
    "    text = text.replace(chr(39), chr(34))"
    "    text = text.replace('_', '-')"
    "    parse_ok = 'True'"
    "    error_code = 'None'"
    "    try:"
    "        index = text.find('{')"
    "        text = text[index:]"
    "        index = text.find('}')"
    "        text = text[:index + 1]"
    "        print ('pre-processed-text: *****', text, '*****')"
    "        text = json.loads(text)"
    "        move_forward = text['move-forward']"
    "        move_forward = str(move_forward)"
    "        rotate = text['rotate']"
    "        rotate = str(rotate)"
    "        pick_up_food = text['pick-up-food']"
    "        pick_up_food = str(pick_up_food)"
    "        drop_pheromone = text['drop-pheromone']"
    "        drop_pheromone = str(drop_pheromone)"
    "        drop_food = text['drop-food']"
    "        drop_food = str(drop_food)"
    "        elements_list.append(parse_ok)"
    "        elements_list.append(error_code)"
    "        elements_list.append(move_forward.lower())"
    "        elements_list.append(rotate.lower())"
    "        elements_list.append(pick_up_food.lower())"
    "        elements_list.append(drop_pheromone.lower())"
    "        elements_list.append(drop_food.lower())"
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
    "def create_prompt(sense_pheromone_left, sense_pheromone_front, sense_pheromone_right, sense_on_nest, sense_nest_left, sense_nest_front, sense_nest_right, sense_food_quantity, sense_carrying_food):"
    "    sense_pheromone_left = float(sense_pheromone_left)"
    "    sense_pheromone_front = float(sense_pheromone_front)"
    "    sense_pheromone_right = float(sense_pheromone_right)"
    "    sense_nest_left = float(sense_nest_left)"
    "    sense_nest_front = float(sense_nest_front)"
    "    sense_nest_right = float(sense_nest_right)"
    "    if sense_on_nest.lower() == 'false':"
    "       on_nest_text = '**False** (You are not currently at the nest)'"
    "    else:"
    "       on_nest_text = '**True** (You are currently at the nest)'"
    "    if sense_carrying_food.lower() == 'false':"
    "       carrying_food_text = '**False** (You are not currently carrying food)'"
    "    else:"
    "       carrying_food_text = '**True** (You are currently carrying food)'"
    "    if sense_pheromone_left > sense_pheromone_front and sense_pheromone_left > sense_pheromone_right:"
    "       pheromone_text = 'Left'"
    "    elif sense_pheromone_right > sense_pheromone_front and sense_pheromone_right > sense_pheromone_left:"
    "       pheromone_text = 'Right'"
    "    elif sense_pheromone_front > 0 and (sense_pheromone_front >= sense_pheromone_right or sense_pheromone_front >= sense_pheromone_left):"
    "       pheromone_text = 'Front'"
    "    else:"
    "       pheromone_text = 'None'"
    "    if sense_nest_left > sense_nest_front and sense_nest_left > sense_nest_right:"
    "       nest_text = 'Left'"
    "    elif sense_nest_right > sense_nest_front and sense_nest_right > sense_nest_left:"
    "       nest_text = 'Right'"
    "    else:"
    "       nest_text = 'Front'"
    "    system_text = 'You are an ant in a 2D simulation. Your task is to pick up food and release it at the nest. Release pheromone on food source and while you are carrying food. Use nest scent to navigate back to the nest only when carrying food, prioritizing nest scent over pheromones. Use highest pheromone scent to navigate to food when not carrying any. Move away from nest and rotate randomly if you are not carrying any food and you are not sensing any pheromone. Format your actions as a Python dictionary with these keys and options: ' + chr(34) + 'move-forward' + chr(34) + ' (options: True, False), ' + chr(34) + 'rotate' + chr(34) + ' (options: ' + chr(34) + 'left'+ chr(34) + ', '+ chr(34) + 'right' + chr(34)+ ', ' + chr(34) + 'none' + chr(34) + ', ' + chr(34) + 'random' + chr(34) + ' ), ' + chr(34) + 'pick-up-food' + chr(34) + ' (options: True, False), ' + chr(34) + 'drop-pheromone' + chr(34) + ' (options: True, False), ' + chr(34) + 'drop-food' + chr(34) + ' (options: True, False). You will be provided with environment information. Keep your response concise, under 45 tokens.'"
    "    prompt_text = 'This is your current environment: -Highest Pheromone Concentration: ' + pheromone_text + ', -Nest Presence: ' + on_nest_text + ', -Stronger Nest Scent: ' + nest_text + ', -Food Concentration at your location: ' + sense_food_quantity + ', -Carrying Food Status ' + carrying_food_text "
    "    return prompt_text, system_text"
    "def process_step(file_name, step):"
    "    # Open the text file"
    "    with open(file_name, 'r') as file:"
    "        lines = file.readlines()"
    "    # Initialize variables"
    "    in_step_section = False"
    "    in_ant_section = False"
    "    actions_list = []"
    "    ant_info = {}"
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
    "        # If we are in the correct step section, look for ant sections"
    "        if in_step_section:"
    "            if line.startswith('Start-AntID:'):"
    "                in_ant_section = True"
    "                ant_id = line.split(':')[1].strip()"
    "                # Initialize variables for the new ant"
    "                ant_info = {"
    "                    'AntID': ant_id,"
    "                    'move': False,"
    "                    'rotate_right': False,"
    "                    'rotate_left': False,"
    "                    'rotate_random_l': False,"
    "                    'rotate_random_r': False,"
    "                    'pick_up_food': False,"
    "                    'drop_pheromone': False,"
    "                    'drop_food': False,"
    "                    'action_ok': False"
    "                }"
    "                continue"
    "            if line.startswith('End-AntID:'):"
    "                end_ant_id = line.split(':')[1].strip()"
    "                if in_ant_section and end_ant_id == ant_info['AntID']:"
    "                    in_ant_section = False"
    "                    # Add the ant_info to actions_list as a list of its values"
    "                    actions_list.append(["
    "                        ant_info['AntID'],"
    "                        ant_info['action_ok'],"
    "                        ant_info['move'],"
    "                        ant_info['rotate_right'],"
    "                        ant_info['rotate_left'],"
    "                        ant_info['rotate_random_l'],"
    "                        ant_info['rotate_random_r'],"
    "                        ant_info['pick_up_food'],"
    "                        ant_info['drop_pheromone'],"
    "                        ant_info['drop_food']"
    "                    ])"
    "                continue"
    "            # If we are in the correct ant section, check for the required texts"
    "            if in_ant_section:"
    "                if 'Parser ok' in line:"
    "                    ant_info['action_ok'] = True"
    "                if '--- action move' in line:"
    "                    ant_info['move'] = True"
    "                if '--- action rotate-right' in line:"
    "                    ant_info['rotate_right'] = True"
    "                if '--- action rotate-left' in line:"
    "                    ant_info['rotate_left'] = True"
    "                if '--- action rotate-random-l' in line:"
    "                    ant_info['rotate_random_l'] = True"
    "                if '--- action rotate-random-r' in line:"
    "                    ant_info['rotate_random_r'] = True"
    "                if '--- action pick-up-food' in line:"
    "                    ant_info['pick_up_food'] = True"
    "                if '--- action drop-pheromone' in line:"
    "                    ant_info['drop_pheromone'] = True"
    "                if '--- action drop-food' in line:"
    "                    ant_info['drop_food'] = True"
    "    # Return the actions list"
    "    return actions_list    "
   )
end

to-report get_llm_data
   let llm_data py:runresult "elements_list"
   report llm_data
end

to-report populate_ant_with_llm_data [ llm_data ]
  let parse_ok item 0 llm_data
  let return_ok true
  ifelse parse_ok = "True" [
    print "Parser ok"
    set action-move_forward item 2 llm_data
    set action-rotate item 3 llm_data
    set action-pick_up_food item 4 llm_data
    set action-drop_pheromone item 5 llm_data
    set action-drop_food item 6 llm_data
    set action-status-ok true
    set action-status-code 0

    if action-pick_up_food = "true" [
      print "--- action pick-up-food"
      if food > 0 and sense-carrying-food != "True" [
        set food food - 1
        set sense-carrying-food "True"
        set color green
      ]
    ]

    if action-move_forward = "true" [
      print "--- action move"
      ifelse not can-move? ant_speed [ rt 180 ][fd ant_speed]
    ]

    ifelse action-rotate != "none" [
      ifelse action-rotate = "right" [
        rt rotation-ang
        print "--- action rotate-right"
      ]
      [
        ifelse action-rotate = "left" [
          rt -1 * rotation-ang
          print "--- action rotate-left"
        ]
        [
          ifelse action-rotate = "180deg" [
            rt -180
            print "--- action rotate-180deg"
          ]
          [
             ifelse ( random 10 ) > 4 [ rt rotation-ang / 2 fd 0 print "--- action rotate-random-r" ][ rt -1 * rotation-ang / 2 fd 0 print "--- action rotate-random-l" ]
          ]
        ]
      ]
    ]
    [
      print "--- action rotate-none"
    ]

    if action-drop_pheromone = "true" [
      print "--- action drop-pheromone"
      set chemical chemical + 60
    ]

    if action-drop_food = "true" [
      print "--- action drop-food"
      if sense-carrying-food = "True" and nest? [
        set sense-carrying-food "False"
        set food_collected food_collected + 1
        set color red
      ]
    ]
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
  print (word "Start-AntID: " ant-id)
  let populate_prompt (word "prepared_prompt, system_prompt = create_prompt('" sense-pheromone-left "', '" sense-pheromone-front "','" sense-pheromone-right "','" sense-on-nest "','" sense-nest-left "','" sense-nest-front "','" sense-nest-right "','" sense-food-quantity "','" sense-carrying-food "')" )
  py:run populate_prompt
  py:run "elements_list = []"
  py:run "print('User prompt: ' + prepared_prompt)"
  py:run "print('Complete prompt: ' + system_prompt + prepared_prompt)"
  py:run "response = client.chat.completions.create(model= 'gpt-4o-2024-08-06', timeout=15, max_tokens=500, messages=[ {'role': 'system', 'content': system_prompt}, {'role': 'user', 'content': prepared_prompt}], temperature=0.1)"
  py:run "response = response.choices[0].message.content"
  py:run "parse_response(response)"
  print "--------------- llm data: ----------------"
  let llm_data get_llm_data
  let populate_ok populate_ant_with_llm_data llm_data
  print (word "End-AntID: " ant-id)
end

to-report nest-scent-at-angle [angle]
  let p patch-right-and-ahead angle 2
  if p = nobody [ report 0 ]
  report [nest-scent] of p
end

to wiggle
  rt random 40
  lt random 40
  if not can-move? 1 [ rt 180 ]
end

to-report chemical-scent-at-angle [angle]
  let p patch-right-and-ahead angle 1 ;1
  if p = nobody [ report 0 ]
  let pchem [chemical] of p
  if pchem > 5.0 [ set pchem 5.0 ]
  report pchem
end

to-report food-in-front
  let p patch-ahead 1
  if p = nobody [ report 0 ]
  report [food] of p
end

to sense-world

  ifelse nest? [
  set sense-on-nest "True"
  ][ set sense-on-nest "False" ]

  set sense-pheromone-front ( word precision (chemical-scent-at-angle   0) 2 )
  set sense-pheromone-right ( word precision (chemical-scent-at-angle  45) 2 )
  set sense-pheromone-left  ( word precision (chemical-scent-at-angle -45) 2 )

  set sense-nest-front ( word precision (nest-scent-at-angle   0) 2 )
  set sense-nest-right ( word precision (nest-scent-at-angle  45) 2 )
  set sense-nest-left  ( word precision (nest-scent-at-angle -45) 2 )

  set sense-food-quantity (word food)
end

to go_ants  ;; forever button
  let step_text ( word "step: " ticks )
  print step_text
  ask ants
  [ sense-world run_llm ]
  diffuse chemical (diffusion-rate / 100)
  ask patches
  [ set chemical chemical * (100 - evaporation-rate) / 100  ;; slowly evaporate chemical
    recolor-patch ]
  print "end step"
  set all-food-amounts lput food_collected all-food-amounts
  tick
  if ticks >= 1 [ ask patches with [ chemical < 0.001 ][ set chemical 0.0 ]]
end




@#$#@#$#@
GRAPHICS-WINDOW
220
10
796
587
-1
-1
8.0
1
10
1
1
1
0
0
0
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
15
255
185
288
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
15
375
185
408
Run from LLM
go_ants
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
20
10
192
43
diffusion-rate
diffusion-rate
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
20
50
192
83
evaporation-rate
evaporation-rate
0
20
2.0
1
1
NIL
HORIZONTAL

SLIDER
20
90
192
123
ant_speed
ant_speed
0.5
10
1.0
0.5
1
NIL
HORIZONTAL

MONITOR
40
485
142
530
food_collected
food_collected
0
1
11

BUTTON
15
330
182
363
Run from log file
let step_num 0\nlet step_text \"\"\nlet filename ( word \"antgpt_openai_seed_\" used_seed \".txt\")\n\nrepeat 1000 [\n\nset step_text ( word \"process_step('\" filename \"',\" step_num \")\" )\nlet step_data py:runresult step_text\nprint step_num\n\nlet index 0\nrepeat (length step_data) [ ; Iterate through each ant\n  let current_ant item index step_data ; Load next ant\n  let ant_data_id read-from-string( item 0 current_ant )\n  let ant_data_ok item 1 current_ant\n  if ant_data_ok = true [ ; Continue parsing if data integrity is ok\n    let ant_data_move item 2 current_ant\n    let ant_data_rotate_r item 3 current_ant\n    let ant_data_rotate_l item 4 current_ant\n    let ant_data_random_l item 5 current_ant\n    let ant_data_random_r item 6 current_ant\n    let ant_data_pick_up_food item 7 current_ant\n    let ant_data_drop_pheromone item 8 current_ant\n    let ant_data_drop_food item 9 current_ant\n    \n    ask ant ant_data_id [\n    \n       if ant_data_pick_up_food = true [\n         if food > 0 and sense-carrying-food != \"True\" [\n           set food food - 1\n           set sense-carrying-food \"True\"\n           set color green\n         ]\n       ]     \n    \n       if ant_data_move = true [\n          ifelse not can-move? ant_speed [ rt 180 ][fd ant_speed]\n       ]\n       if ant_data_rotate_r = true [\n          rt rotation-ang\n       ]\n       if ant_data_rotate_l = true [\n          rt -1 * rotation-ang\n       ]  \n       if ant_data_random_l = true [\n          rt -1 * rotation-ang / 2 ; fd 2\n       ]                    \n       if ant_data_random_r = true [\n          rt rotation-ang / 2 ; fd 2\n       ]  \n\n       if ant_data_drop_pheromone = true [\n          set chemical chemical + 60\n       ] \n       if ant_data_drop_food = true [\n         if sense-carrying-food = \"True\" and nest? [\n           set sense-carrying-food \"False\"\n           ;set food food + 1\n           set food_collected food_collected + 1\n           set color red\n         ]          \n       ]              \n                    \n    ]\n  ]\n  \n  \n  set index index + 1\n]\n\n;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;\n  diffuse chemical (diffusion-rate / 100)\n  ask patches\n  [ set chemical chemical * (100 - evaporation-rate) / 100  ;; slowly evaporate chemical\n    recolor-patch ]\n  print \"end step\"\n  set all-food-amounts lput food_collected all-food-amounts\n  tick\n  if ticks >= 1 [ ask patches with [ chemical < 0.001 ][ set chemical 0.0 ]] ;876\n\n;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;\n\n  set step_num step_num + 1\n]
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
20
130
190
163
rotation-ang
rotation-ang
1
90
40.0
1
1
NIL
HORIZONTAL

BUTTON
355
600
577
633
Export data food-collected
let filename ( word \"food_collected_llm_seed_\" used_seed \".csv\" )\nexport-food-collected-to-csv filename
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
15
185
180
230
used_seed
used_seed
"21504" "6890" "351973" "19562" "47822"
1

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
