States of a turn :
- Compute next frame
  - If start frame == next frame : next state = save the frame
  - If player dies : next state = loss
  - If no apples left : next state = win
  - Otherwise : next_state = compute
- Save the frame
  - Next state = ask_input
- Ask for player input
  - If backtrack :
    - Load previous value
    - Next state = save the frame
  - Next state = move_player
- Move player
  - Next state = compute
- Win :
  - Stop the game
- Loss :
  - Stop the game
  - Allow reload (cf. ask-player-input)

How to compute a map :
- Iterate from down to up
  - Iterate from right to left
    - if it's an apple/wall/grass/empty
      - do nothing
    - if it's a boulder
      - if it's over emptiness : now it's falling_boulder
    - if it's a falling boulder :
      - if it's over the player : stop the computation, next_state is game over
      - if it's over emptiness : move it to y+1
      - if it's over a boulder :
        - if both left and down-left empty : move it to x-1, y+1
        - if both right and down-right empty : move it to x+1, y+1
        - otherwise, now it's boulder
      - otherwise
        - now it's boulder
      - in all cases, stop computation

