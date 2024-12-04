\ Test tools for AMC Forth. Derived from the following:

\ (C) 1995 JOHNS HOPKINS UNIVERSITY / APPLIED PHYSICS LABORATORY
\ MAY BE DISTRIBUTED FREELY AS LONG AS THIS COPYRIGHT NOTICE REMAINS.
\ VERSION 1.1

\ Revision history and possibly newer versions can be found at
\ http://www.forth200x/tests/ttester.fs


VARIABLE ACTUAL-DEPTH \ stack record
CREATE ACTUAL-RESULTS 20 CELLS ALLOT
VARIABLE START-DEPTH
VARIABLE XCURSOR \ for ...}T
VARIABLE ERROR-XT

: ERROR ERROR-XT @ EXECUTE ; \ for vectoring of error reporting

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

\ NECESSARY DEFINITIONS

1 CONSTANT 1S

0 INVERT CONSTANT MAX-UINT
0 INVERT 1 RSHIFT CONSTANT MAX-INT
0 INVERT 1 RSHIFT INVERT   CONSTANT MIN-INT
0 INVERT 1 RSHIFT CONSTANT MID-UINT
0 INVERT 1 RSHIFT INVERT   CONSTANT MID-UINT+1

0 CONSTANT <FALSE>
-1 CONSTANT <TRUE> 

\ DIVISION
: IFFLOORED [ -3 2 / -2 = INVERT ] LITERAL IF POSTPONE \ THEN ;
: IFSYM      [ -3 2 / -1 = INVERT ] LITERAL IF POSTPONE \ THEN ; 

\ CORE TESTS

 T{ -> }T                      ( Start with a clean slate )
( Test if any bits are set; Answer in base 1 )
T{ : BITSSET? IF 0 0 ELSE 0 THEN ; -> }T
T{  0 BITSSET? -> 0 }T           ( Zero is all bits clear )
T{  1 BITSSET? -> 0 0 }T         ( Other numbers have at least one bit )
T{ -1 BITSSET? -> 0 0 }T 

\ CORE WORDS
\ PLUS
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

\ MINUS
T{          0  5 - ->       -5 }T
T{          5  0 - ->        5 }T
T{          0 -5 - ->        5 }T
T{         -5  0 - ->       -5 }T
T{          1  2 - ->       -1 }T
T{          1 -2 - ->        3 }T
T{         -1  2 - ->       -3 }T
T{         -1 -2 - ->        1 }T
T{          0  1 - ->       -1 }T
T{ MID-UINT+1  1 - -> MID-UINT }T

\ COMMA
HERE 1 ,
HERE 2 ,
CONSTANT 2ND
CONSTANT 1ST

T{       1ST 2ND U< -> <TRUE> }T \ HERE MUST GROW WITH ALLOT
T{       1ST CELL+  -> 2ND }T \ ... BY ONE CELL
T{   1ST 1 CELLS +  -> 2ND }T
T{     1ST @ 2ND @  -> 1 2 }T
T{         5 1ST !  ->     }T
T{     1ST @ 2ND @  -> 5 2 }T
T{         6 2ND !  ->     }T
T{     1ST @ 2ND @  -> 5 6 }T
T{           1ST 2@ -> 6 5 }T
T{       2 1 1ST 2! ->     }T
T{           1ST 2@ -> 2 1 }T
T{ 1S 1ST !  1ST @  -> 1S  }T    \ CAN STORE CELL-WIDE VALUE

\ DOT
\ DOT QUOTE
\ ONE PLUS
\ ONE MINUS
\ TICK 
T{ : GT1 123 ;   ->     }T
T{ ' GT1 EXECUTE -> 123 }T
\ STORE
\ STAR
T{  0  0 * ->  0 }T          \ TEST IDENTITIES
T{  0  1 * ->  0 }T
T{  1  0 * ->  0 }T
T{  1  2 * ->  2 }T
T{  2  1 * ->  2 }T
T{  3  3 * ->  9 }T
T{ -3  3 * -> -9 }T
T{  3 -3 * -> -9 }T
T{ -3 -3 * ->  9 }T

T{ MID-UINT+1 1 RSHIFT 2 *               -> MID-UINT+1 }T
T{ MID-UINT+1 2 RSHIFT 4 *               -> MID-UINT+1 }T
T{ MID-UINT+1 1 RSHIFT MID-UINT+1 OR 2 * -> MID-UINT+1 }T

\ STAR SLASH MOD
IFFLOORED    : T*/MOD >R M* R> FM/MOD ;
IFSYM        : T*/MOD >R M* R> SM/REM ;
T{       0 2       1 */MOD ->       0 2       1 T*/MOD }T
T{       1 2       1 */MOD ->       1 2       1 T*/MOD }T
T{       2 2       1 */MOD ->       2 2       1 T*/MOD }T
T{      -1 2       1 */MOD ->      -1 2       1 T*/MOD }T
T{      -2 2       1 */MOD ->      -2 2       1 T*/MOD }T
T{       0 2      -1 */MOD ->       0 2      -1 T*/MOD }T
T{       1 2      -1 */MOD ->       1 2      -1 T*/MOD }T
T{       2 2      -1 */MOD ->       2 2      -1 T*/MOD }T
T{      -1 2      -1 */MOD ->      -1 2      -1 T*/MOD }T
T{      -2 2      -1 */MOD ->      -2 2      -1 T*/MOD }T
T{       2 2       2 */MOD ->       2 2       2 T*/MOD }T
T{      -1 2      -1 */MOD ->      -1 2      -1 T*/MOD }T
T{      -2 2      -2 */MOD ->      -2 2      -2 T*/MOD }T
T{       7 2       3 */MOD ->       7 2       3 T*/MOD }T
T{       7 2      -3 */MOD ->       7 2      -3 T*/MOD }T
T{      -7 2       3 */MOD ->      -7 2       3 T*/MOD }T
T{      -7 2      -3 */MOD ->      -7 2      -3 T*/MOD }T
T{ MAX-INT 2 MAX-INT */MOD -> MAX-INT 2 MAX-INT T*/MOD }T
T{ MIN-INT 2 MIN-INT */MOD -> MIN-INT 2 MIN-INT T*/MOD }T 

\ STAR SLASH
IFFLOORED    : T*/ T*/MOD SWAP DROP ;
IFSYM        : T*/ T*/MOD SWAP DROP ;

T{       0 2       1 */ ->       0 2       1 T*/ }T
T{       1 2       1 */ ->       1 2       1 T*/ }T
T{       2 2       1 */ ->       2 2       1 T*/ }T
T{      -1 2       1 */ ->      -1 2       1 T*/ }T
T{      -2 2       1 */ ->      -2 2       1 T*/ }T
T{       0 2      -1 */ ->       0 2      -1 T*/ }T
T{       1 2      -1 */ ->       1 2      -1 T*/ }T
T{       2 2      -1 */ ->       2 2      -1 T*/ }T
T{      -1 2      -1 */ ->      -1 2      -1 T*/ }T
T{      -2 2      -1 */ ->      -2 2      -1 T*/ }T
T{       2 2       2 */ ->       2 2       2 T*/ }T
T{      -1 2      -1 */ ->      -1 2      -1 T*/ }T
T{      -2 2      -2 */ ->      -2 2      -2 T*/ }T
T{       7 2       3 */ ->       7 2       3 T*/ }T
T{       7 2      -3 */ ->       7 2      -3 T*/ }T
T{      -7 2       3 */ ->      -7 2       3 T*/ }T
T{      -7 2      -3 */ ->      -7 2      -3 T*/ }T
T{ MAX-INT 2 MAX-INT */ -> MAX-INT 2 MAX-INT T*/ }T
T{ MIN-INT 2 MIN-INT */ -> MIN-INT 2 MIN-INT T*/ }T 

\ SLASH MOD
IFFLOORED    : T/MOD >R S>D R> FM/MOD ;
IFSYM        : T/MOD >R S>D R> SM/REM ;

T{       0       1 /MOD ->       0       1 T/MOD }T
T{       1       1 /MOD ->       1       1 T/MOD }T
T{       2       1 /MOD ->       2       1 T/MOD }T
T{      -1       1 /MOD ->      -1       1 T/MOD }T
T{      -2       1 /MOD ->      -2       1 T/MOD }T
T{       0      -1 /MOD ->       0      -1 T/MOD }T
T{       1      -1 /MOD ->       1      -1 T/MOD }T
T{       2      -1 /MOD ->       2      -1 T/MOD }T
T{      -1      -1 /MOD ->      -1      -1 T/MOD }T
T{      -2      -1 /MOD ->      -2      -1 T/MOD }T
T{       2       2 /MOD ->       2       2 T/MOD }T
T{      -1      -1 /MOD ->      -1      -1 T/MOD }T
T{      -2      -2 /MOD ->      -2      -2 T/MOD }T
T{       7       3 /MOD ->       7       3 T/MOD }T
T{       7      -3 /MOD ->       7      -3 T/MOD }T
T{      -7       3 /MOD ->      -7       3 T/MOD }T
T{      -7      -3 /MOD ->      -7      -3 T/MOD }T
T{ MAX-INT       1 /MOD -> MAX-INT       1 T/MOD }T
T{ MIN-INT       1 /MOD -> MIN-INT       1 T/MOD }T
T{ MAX-INT MAX-INT /MOD -> MAX-INT MAX-INT T/MOD }T
T{ MIN-INT MIN-INT /MOD -> MIN-INT MIN-INT T/MOD }T 

\ SLASH
IFFLOORED    : T/ T/MOD SWAP DROP ;
IFSYM        : T/ T/MOD SWAP DROP ;

T{       0       1 / ->       0       1 T/ }T
T{       1       1 / ->       1       1 T/ }T
T{       2       1 / ->       2       1 T/ }T
T{      -1       1 / ->      -1       1 T/ }T
T{      -2       1 / ->      -2       1 T/ }T
T{       0      -1 / ->       0      -1 T/ }T
T{       1      -1 / ->       1      -1 T/ }T
T{       2      -1 / ->       2      -1 T/ }T
T{      -1      -1 / ->      -1      -1 T/ }T
T{      -2      -1 / ->      -2      -1 T/ }T
T{       2       2 / ->       2       2 T/ }T
T{      -1      -1 / ->      -1      -1 T/ }T
T{      -2      -2 / ->      -2      -2 T/ }T
T{       7       3 / ->       7       3 T/ }T
T{       7      -3 / ->       7      -3 T/ }T
T{      -7       3 / ->      -7       3 T/ }T
T{      -7      -3 / ->      -7      -3 T/ }T
T{ MAX-INT       1 / -> MAX-INT       1 T/ }T
T{ MIN-INT       1 / -> MIN-INT       1 T/ }T
T{ MAX-INT MAX-INT / -> MAX-INT MAX-INT T/ }T
T{ MIN-INT MIN-INT / -> MIN-INT MIN-INT T/ }T 

\ COLON
\ SEMI COLON
\ QUESTION DO
\ QUESTION DUP

\ PLUS STORE
T{  0 1ST !        ->   }T
T{  1 1ST +!       ->   }T
T{    1ST @        -> 1 }T
T{ -1 1ST +! 1ST @ -> 0 }T

\ PLUS LOOP
T{ : GD2 DO I -1 +LOOP ; -> }T
T{        1          4 GD2 -> 4 3 2  1 }T
T{       -1          2 GD2 -> 2 1 0 -1 }T
T{ MID-UINT MID-UINT+1 GD2 -> MID-UINT+1 MID-UINT }T

VARIABLE gditerations
VARIABLE gdincrement

: gd7 ( limit start increment -- )
   gdincrement !
   0 gditerations !
   DO
     1 gditerations +!
     I
     gditerations @ 6 = IF LEAVE THEN
     gdincrement @
   +LOOP gditerations @
;

T{    4  4  -1 gd7 ->  4                  1  }T
T{    1  4  -1 gd7 ->  4  3  2  1         4  }T
T{    4  1  -1 gd7 ->  1  0 -1 -2  -3  -4 6  }T
T{    4  1   0 gd7 ->  1  1  1  1   1   1 6  }T
T{    0  0   0 gd7 ->  0  0  0  0   0   0 6  }T
T{    1  4   0 gd7 ->  4  4  4  4   4   4 6  }T
T{    1  4   1 gd7 ->  4  5  6  7   8   9 6  }T
T{    4  1   1 gd7 ->  1  2  3            3  }T
T{    4  4   1 gd7 ->  4  5  6  7   8   9 6  }T
T{    2 -1  -1 gd7 -> -1 -2 -3 -4  -5  -6 6  }T
T{   -1  2  -1 gd7 ->  2  1  0 -1         4  }T
T{    2 -1   0 gd7 -> -1 -1 -1 -1  -1  -1 6  }T
T{   -1  2   0 gd7 ->  2  2  2  2   2   2 6  }T
T{   -1  2   1 gd7 ->  2  3  4  5   6   7 6  }T
T{    2 -1   1 gd7 -> -1 0 1              3  }T
T{  -20 30 -10 gd7 -> 30 20 10  0 -10 -20 6  }T
T{  -20 31 -10 gd7 -> 31 21 11  1  -9 -19 6  }T
T{  -20 29 -10 gd7 -> 29 19  9 -1 -11     5  }T

\ With large and small increments

MAX-UINT 8 RSHIFT 1+ CONSTANT ustep
ustep NEGATE CONSTANT -ustep
MAX-INT 7 RSHIFT 1+ CONSTANT step
step NEGATE CONSTANT -step

VARIABLE bump

T{  : gd8 bump ! DO 1+ bump @ +LOOP ; -> }T

T{  0 MAX-UINT 0 ustep gd8 -> 256 }T
T{  0 0 MAX-UINT -ustep gd8 -> 256 }T
T{  0 MAX-INT MIN-INT step gd8 -> 256 }T
T{  0 MIN-INT MAX-INT -step gd8 -> 256 }T

\ LESS THAN
\ EQUAL
\ GREATER THAN
\ ZERO LESS THAN
\ ZERO EQUAL
\ TWO STORE
\ TWO STAR
\ TWO SLASH
\ TWO FETCH
\ TWO DROP
\ TWO DUP
\ TWO OVER
\ TWO SWAP
\ TO IN
\ FETCH
\ ABS
\ ALIGN
\ ALIGNED
\ ALLOT
\ AND
\ BASE
\ BEGIN
\ BL
\ CELL PLUS
\ CELLS
\ C COMMA
\ CHAR PLUS
\ CHARS
\ CONSTANT
\ COUNT
\ CR
\ CREATE
\ DECIMAL
\ DEPTH
\ DO
\ DUP
\ DROP
\ ELSE
\ EMIT
\ EVALUATE
\ EXECUTE
\ EXIT
\ HERE
\ I
\ IF
\ IMMEDIATE
\ INVERT
\ J
\ LEAVE
\ LITERAL
\ LSHIFT
\ LOOP
\ M STAR
\ MAX
\ MIN
\ MOD
\ MOVE
\ NEGATE
\ OR
\ OVER
\ POSTPONE
\ R FETCH
\ ROT
\ R SHIFT
\ S QUOTE
\ S TO D
\ SM SLASH REM
\ SOURCE
\ SPACE
\ SPACES
\ SWAP
\ THEN
\ U LESS THAN
\ UNLOOP
\ UNTIL
\ WORD
\ TYPE
\ UM STAR
\ UM SLASH MOD
\ VARIABLE
\ XOR