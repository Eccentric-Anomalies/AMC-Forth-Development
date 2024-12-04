VARIABLE ACTUAL-DEPTH \ stack record
CREATE ACTUAL-RESULTS 20 CELLS ALLOT
VARIABLE START-DEPTH
VARIABLE XCURSOR \ for ...}T
VARIABLE ERROR-XT

: ERROR ERROR-XT @ EXECUTE ; \ for vectoring of error reporting

' TYPE ERROR-XT !

: T{ \ ( -- ) record the pre-test depth.
   DEPTH START-DEPTH ! 0 XCURSOR ! ;

: -> \ ( ... -- ) record depth and contents of stack.
   DEPTH DUP ACTUAL-DEPTH ! \ record depth
   START-DEPTH @ > IF       \ if there is something on the stack
     DEPTH START-DEPTH @ - 0 DO \ save them
       ACTUAL-RESULTS I CELLS + !
     LOOP
   THEN ;

: }T \ ( ... -- ) compare stack (expected) contents with saved
   \ (actual) contents.
   DEPTH ACTUAL-DEPTH @ = IF           \ if depths match
     DEPTH START-DEPTH @ > IF          \ if something on the stack
       DEPTH START-DEPTH @ - 0 DO      \ for each stack item
         ACTUAL-RESULTS I CELLS + @    \ compare actual with expected
         <> IF S" INCORRECT RESULT: " ERROR LEAVE THEN
       LOOP
     THEN
   ELSE                                    \ depth mismatch
     S" WRONG NUMBER OF RESULTS: " ERROR
   THEN ;

\ T{ 1 2 3 SWAP -> 1 3 2 }T
\ T{ 1 2 3 SWAP -> 1 2 3 }T
\ T{ 1 2 SWAP -> 1 }T

0 INVERT CONSTANT MAX-UINT
0 INVERT 1 RSHIFT CONSTANT MAX-INT
0 INVERT 1 RSHIFT INVERT   CONSTANT MIN-INT
0 INVERT 1 RSHIFT CONSTANT MID-UINT
0 INVERT 1 RSHIFT INVERT   CONSTANT MID-UINT+1

T{        0  5 + ->          5 }T
T{        5  0 + ->          5 }T
T{        0 -5 + ->         -5 }T
T{       -5  0 + ->         -5 }T
T{        1  2 + ->          3 }T
T{        1 -2 + ->         -1 }T
T{       -1  2 + ->          1 }T
T{       -1 -2 + ->         -3 }T
T{       -1  1 + ->          0 }T
T{ MID-UINT  1 + -> MID-UINT+1 }T