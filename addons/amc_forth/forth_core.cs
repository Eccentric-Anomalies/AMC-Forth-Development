using Godot;
using Godot.Collections;
// gdlint:ignore = max-public-methods
// @WORDSET Core

//


[GlobalClass]
public partial class ForthCore : ForthImplementationBase
{
	protected int _SmudgeAddress = 0;


	// Initialize (executed automatically by ForthCore.new())
	//
	// (1) All functions with "## @WORD <word>" comment will become
	// the default implementation for the built-in word.
	// (2) All functions with "## @WORDX <word>" comment will become
	// the *compiled* implementation for the built-in word.
	// (3) Define an IMMEDIATE function with "## @WORD <word> IMMEDIATE"
	// (4) UP TO four comments beginning with "##" before function
	// (5) Final comment must be "## @STACK" followed by stack def.
	public override void Initialize(AMCForth _forth)
	{
		Super(_forth);
	}


// Utility function for parsing comments
	public void StartParenthesis()
	{
		Forth.Push(")".ToAsciiBuffer()[0]);
		Forth.CoreExt.Parse();
	}

	// @WORD ( IMMEDIATE
	// Begin parsing a comment, terminated by ')' character.
	// @STACK ( - )
	public void LeftParenthesis()
	{
		StartParenthesis();
		Forth.Core.TwoDrop();


	// @WORD +
		// Add n1 to n2 leaving the sum n3.

	}// @STACK ( n1 n2 - n3 )
	public void Plus()
	{
		Forth.Push(Forth.Ram.TruncateToCell(Forth.Pop() + Forth.Pop()));


	// @WORD -
		// Subtract n2 from n1, leaving the difference n3.

	}// @STACK ( n1 n2 - n3 )
	public void Minus()
	{
		var n = Forth.Pop();
		Forth.Push(Forth.Ram.TruncateToCell(Forth.Pop() - n));


	// @WORD ,
		// Reserve one cell of data space and store x in it.

	}// @STACK ( x - )
	public void Comma()
	{
		Forth.Ram.SetInt(Forth.DictTopP, Forth.Pop());
		Forth.DictTopP += ForthRAM.CellSize;

		// preserve dictionary state
		Forth.SaveDictTop();


	// @WORD .
		// Display the value, x, on the top of the stack.

	}// @STACK ( x - )
	public void Dot()
	{
		var fmt = ( Forth.Ram.GetInt(Forth.Base) == 10 ? "%d" : "%x" );
		Forth.Util.PrintTerm(" " + fmt % Forth.Pop());


	// @WORD ." IMMEDIATE
		// Type the string when the containing word is executed.

	}// @STACK ( "string" - c-addr u )
	public void DotQuote()
	{

		// compilation behavior
		if(Forth.State)
		{
			StartString();

			// copy the execution token


			Forth.Ram.SetInt(Forth.DictTopP, Forth.AddressFromBuiltInFunction[dot_quote_exec]);

			// store the value
			var l = Forth.Pop();
			// length of the string
			var src = Forth.Pop();
			// first byte address
			Forth.DictTopP += ForthRAM.CellSize;
			Forth.Ram.SetByte(Forth.DictTopP, l);
			// store the length
			// compile the string into the dictionary
			foreach(int i in l)
			{
				Forth.DictTopP += 1;
				Forth.Ram.SetByte(Forth.DictTopP, Forth.Ram.GetByte(src + i));
			}

		// this will align the dict top and save it
			Align();
		}
	}


// @WORDX ."
	public void DotQuoteExec()
	{
		var l = Forth.Ram.GetByte(Forth.DictIp + ForthRAM.CellSize);
		Forth.Push(Forth.DictIp + ForthRAM.CellSize + 1);
		// address of the string start
		Forth.Push(l);
		// length of the string
		// send to the terminal
		Type();

		// moves to string cell for l in 0..3, then one cell past for l in 4..7, etc.
		Forth.DictIp += ((l / ForthRAM.CellSize) + 1) * ForthRAM.CellSize;


	// @WORD 1+
		// Add one to n1, leaving n2.

	}// @STACK ( n1 - n2 )
	public void OnePlus()
	{
		Forth.Push(1);
		Plus();


	// @WORD 1-
		// Subtract one from n1, leaving n2.

	}// @STACK ( n1 - n2 )
	public void OneMinus()
	{
		Forth.Push(1);
		Minus();


	// @WORD '
		// Search the dictionary for <name> and leave its execution token
		// on the stack. Abort if name cannot be found.
		// Usage: ' <name>

	}// @STACK ( "name" - xt )
	public void Tick()
	{

		// retrieve the name token
		Forth.CoreExt.ParseName();
		var len = Forth.Pop();
		// length
		var caddr = Forth.Pop();
		// start
		var word = Forth.Util.StrFromAddrN(caddr, len);

		// look the name up
		var token_addr_immediate = Forth.FindInDict(word);

		// either in user dictionary, a built-in xt, or neither
		if(token_addr_immediate[0])
		{
			Forth.Push(token_addr_immediate[0]);
		}
		else
		{
			var token_addr = Forth.XtFromWord(word);
			if(Forth.BuiltInFunctionFromAddress.Contains(token_addr))
			{
				Forth.Push(token_addr);
			}
			else
			{
				Forth.Util.PrintUnknownWord(word);


	// @WORD !
				// Store x in the cell at a-addr.

			}
		}
	}// @STACK ( x a-addr - )
	public void Store()
	{
		var addr = Forth.Pop();
		Forth.Ram.SetInt(addr, Forth.Pop());


	// @WORD *
		// Multiply n1 by n2 leaving the product n3.

	}// @STACK ( n1 n2 - n3 )
	public void Star()
	{
		Forth.Push(Forth.Ram.TruncateToCell(Forth.Pop() * Forth.Pop()));


	// @WORD */
		// Multiply n1 by n2 producing a double-cell result d.
		// Divide d by n3, giving the single-cell quotient n4.

	}// @STACK ( n1 n2 n3 - n4 )
	public void StarSlash()
	{
		var d = Forth.Pop();
		Forth.Push(Forth.Ram.TruncateToCell(Forth.Pop() * Forth.Pop() / d));


	// @WORD */MOD
		// Multiply n1 by n2 producing a double-cell result d.
		// Divide d by n3, giving the single-cell remainder n4
		// and a single-cell quotient n5.

	}// @STACK ( n1 n2 n3 - n4 n5 )
	public void StarSlashMod()
	{
		var d = Forth.Pop();
		var p = Forth.Pop() * Forth.Pop();
		Forth.Push(p % d);
		Forth.Push(p / d);


	// @WORD /
		// Divide n1 by n2, leaving the quotient n3.

	}// @STACK ( n1 n2 - n3 )
	public void Slash()
	{
		var d = Forth.Pop();
		Forth.Push(Forth.Pop() / d);


	// @WORD /MOD
		// Divide n1 by n2, leaving the remainder n3 and quotient n4.

	}// @STACK ( n1 n2 - n3 n4 )
	public void SlashMod()
	{
		var div = Forth.Pop();
		var d = Forth.Pop();
		Forth.Push(d % div);
		Forth.Push(d / div);


	// @WORD :
		// Create a definition for <name> and enter compilation state.

	}// @STACK ( "name" - )
	public void Colon()
	{
		_SmudgeAddress = Forth.CreateDictEntryName(true);
		if(_SmudgeAddress)
		{

			// enter compile state
			Forth.State = true;


			Forth.Ram.SetInt(Forth.DictTopP, Forth.AddressFromBuiltInFunction[colon_exec]);
			Forth.DictTopP += ForthRAM.CellSize;

			// preserve dictionary state
			Forth.SaveDictTop();
		}
	}


// @WORDX :
	public void ColonExec()
	{

		// Execution behavior of colon
		// save the current stack level
		while(!Forth.ExitFlag)
		{

			// Step to the next item
			Forth.DictIp += ForthRAM.CellSize;

			// get the next execution token
			Forth.Push(Forth.Ram.GetInt(Forth.DictIp));

			// and do what it says to do!
			Execute();
		}

	// we are exiting. reset the flag.
		Forth.ExitFlag = false;


	// @WORD ; IMMEDIATE
		// Leave compilation state.

	}// @STACK ( - )
	public void SemiColon()
	{

		// remove the smudge bit


		Forth.Ram.SetByte(_SmudgeAddress, Forth.Ram.GetByte(_SmudgeAddress) & ~ Forth.SmudgeBitMask);

		// clear compile state
		Forth.State = false;

		// insert the XT for the semi-colon


		Forth.Ram.SetInt(Forth.DictTopP, Forth.AddressFromBuiltInFunction[semi_colon_exec]);
		Forth.DictTopP += ForthRAM.CellSize;

		// preserve dictionary state
		Forth.SaveDictTop();

		// check for control flow stack integrity
		if(!Forth.CfStackIsEmpty())
		{
			Forth.Util.RprintTerm("Unbalanced control structure");
			Forth.UnwindCompile();
		}
	}


// @WORDX ;
	public void SemiColonExec()
	{

		// Execution behavior of semi-colon
		Exit();


	// @WORD ?DO IMMEDIATE
		// Like DO, but check for the end condition before entering the loop body.
		// If satisfied, continue execution following nearest LOOP or LOOP+.

	}// @STACK ( n1 n2 - )
	public void QuestionDo()
	{

		// copy the execution token


		Forth.Ram.SetInt(Forth.DictTopP, Forth.AddressFromBuiltInFunction[question_do_exec]);

		// mark PREV cell as a destination for a backward branch
		Forth.CfPushDest(Forth.DictTopP - ForthRAM.CellSize);

		// leave link address on the control stack
		Forth.CfPushOrig(Forth.DictTopP + ForthRAM.CellSize);

		// move up to finish
		Forth.DictTopP += ForthRAM.DCellSize;
		// two cells up
		// preserve dictionary state
		Forth.SaveDictTop();
	}


// @WORDX ?DO
	public void QuestionDoExec()
	{

		// make a copy of the parameters
		TwoDup();

		// same?
		Equal();
		if(Forth.Pop() == Forth.True)
		{

			// already satisfied. remove the saved parameters
			TwoDrop();

			// Skip ahead to the address in the next cell
			Forth.DictIp = Forth.Ram.GetInt(Forth.DictIp + ForthRAM.CellSize);
		}
		else
		{

			// move limit and count to return stack
			Forth.CoreExt.TwoToR();

			// SKip over the forward reference
			Forth.DictIp += ForthRAM.CellSize;


	// @WORD ?DUP
			// Conditionally duplicate the top item on the stack if its value is
			// non-zero.

		}
	}// @STACK ( x - x | x x )
	public void QuestionDup()
	{

		// ( x - 0 | x x )
		var n = Forth.DataStack[Forth.DsP];
		if(n != 0)
		{
			Forth.Push(n);


	// @WORD +!
			// Add n to the contents of the cell at a-addr and store the result in the
			// cell at a-addr, removing both from the stack.

		}
	}// @STACK ( n a-addr - )
	public void PlusStore()
	{
		var addr = Forth.Pop();
		var a = Forth.Ram.GetInt(addr);
		Forth.Ram.SetInt(addr, a + Forth.Pop());


	// @WORD +LOOP IMMEDIATE
		// Like LOOP but increment the index by the specified signed value n. After
		// incrementing, if the index crossed the boundary between the limit - 1
		// and the limit, the loop is terminated.

	}// @STACK ( dest orig n - )
	public void PlusLoop()
	{

		// copy the execution token


		Forth.Ram.SetInt(Forth.DictTopP, Forth.AddressFromBuiltInFunction[plus_loop_exec]);

		// Check for any orig links
		while(!Forth.LcfIsEmpty())
		{

			// destination is on top of the back link
			Forth.Ram.SetInt(Forth.LcfPop(), Forth.DictTopP + ForthRAM.CellSize);
		}

	// The link back
		Forth.Ram.SetInt(Forth.DictTopP + ForthRAM.CellSize, Forth.CfPopDest());
		Forth.DictTopP += ForthRAM.DCellSize;
		// two cells up and done
		// preserve dictionary state
		Forth.SaveDictTop();
	}


// @WORDX +LOOP
	public void PlusLoopExec()
	{

		// ( n - )
		// pull out the increment
		var n = Forth.Pop();

		// Move to loop params to the data stack.
		Forth.CoreExt.TwoRFrom();
		var i = Forth.Pop();
		// current index
		var limit = Forth.Pop();
		// limit value
		var above_before = i >= limit;
		var next_i = i + n;
		var above_after = next_i >= limit;
		if(above_before != above_after)
		{

			// loop is satisfied
			Forth.DictIp += ForthRAM.CellSize;
		}
		else
		{

			// loop must continue
			Forth.Push(limit);
			// original limit
			Forth.Push(next_i);
			// new index
			// Branch back. The DO or ?DO exec will push the values
			// back on the return stack
			Forth.DictIp = Forth.Ram.GetInt(Forth.DictIp + ForthRAM.CellSize);


	// @WORD <
			// Return true if and only if n1 is less than n2.

		}
	}// @STACK ( n1 n2 - flag )
	public void LessThan()
	{
		var t = Forth.Pop();
		if(t > Forth.Pop())
		{
			Forth.Push(Forth.True);
		}
		else
		{
			Forth.Push(Forth.False);


	// @WORD =
			// Return true if and only if n1 is equal to n2.

		}
	}// @STACK ( n1 n2 - flag )
	public void Equal()
	{
		var t = Forth.Pop();
		if(t == Forth.Pop())
		{
			Forth.Push(Forth.True);
		}
		else
		{
			Forth.Push(Forth.False);


	// @WORD >
			// Return true if and only if n1 is greater than n2

		}
	}// @STACK ( n1 n2 - flag )
	public void GreaterThan()
	{
		var t = Forth.Pop();
		if(t < Forth.Pop())
		{
			Forth.Push(Forth.True);
		}
		else
		{
			Forth.Push(Forth.False);


	// @WORD >R
			// Remove the item on top of the data stack and put it on the return stack.

		}
	}// @STACK (S: x - ) (R: - x )
	public void ToR()
	{
		Forth.RPush(Forth.Pop());


	// @WORD R>
		// Remove the item on the top of the return stack and put it on the data stack.

	}// @STACK (S: - x ) (R: x - )
	public void RFrom()
	{
		Forth.Push(Forth.RPop());


	// @WORD 0<
		// Return true if and only if n is less than zero.

	}// @STACK ( n - flag )
	public void ZeroLessThan()
	{
		if(Forth.Pop() < 0)
		{
			Forth.Push(Forth.True);
		}
		else
		{
			Forth.Push(Forth.False);


	// @WORD 0=
			// Return true if and only if n is equal to zero.

		}
	}// @STACK ( n - flag )
	public void ZeroEqual()
	{
		if(Forth.Pop())
		{
			Forth.Push(Forth.False);
		}
		else
		{
			Forth.Push(Forth.True);


	// @WORD 2!
			// Store the cell pair x1 x2 in the two cells beginning at aaddr, removing
			// three cells from the stack. The order of the two cells is the same as
			// on the stack, meaning the one in the top stack is in lower memory.

		}
	}// @STACK ( x1 x2 a-addr - )
	public void TwoStore()
	{
		var a = Forth.Pop();
		Forth.Ram.SetInt(a, Forth.Pop());
		Forth.Ram.SetInt(a + ForthRAM.CellSize, Forth.Pop());


	// @WORD 2*
		// Return x2, result of shifting x1 one bit towards the MSB,
		// filling the LSB with zero.

	}// @STACK ( x1 - x2 )
	public void TwoStar()
	{
		Forth.Push(Forth.Ram.TruncateToCell(Forth.Pop() << 1));


	// @WORD 2/
		// Return x2, result of shifting x1 one bit towards LSB,
		// leaving the MSB unchanged.

	}// @STACK ( x1 - x2 )
	public void TwoSlash()
	{
		var msb = Forth.DataStack[Forth.DsP] & ForthRAM.CELL_MSB_MASK;
		var n = Forth.DataStack[Forth.DsP];

		// preserve msbit
		Forth.DataStack[Forth.DsP] = (n >> 1) | msb;


	// @WORD 2@
		// Push the cell pair x1 x2 at a-addr onto the top of the stack. The
		// combined action of 2! and 2@ will always preserve the stack order
		// of the cells.

	}// @STACK ( a-addr - x1 x2 )
	public void TwoFetch()
	{
		var a = Forth.Pop();
		Forth.Push(Forth.Ram.GetInt(a + ForthRAM.CellSize));
		Forth.Push(Forth.Ram.GetInt(a));


	// @WORD 2DROP
		// Remove the top pair of cells from the stack.

	}// @STACK ( x1 x2 - )
	public void TwoDrop()
	{
		Forth.Pop();
		Forth.Pop();


	// @WORD 2DUP
		// Duplicate the top cell pair.

	}// @STACK (x1 x2 - x1 x2 x1 x2 )
	public void TwoDup()
	{
		var x2 = Forth.DataStack[Forth.DsP];
		var x1 = Forth.DataStack[Forth.DsP + 1];
		Forth.Push(x1);
		Forth.Push(x2);


	// @WORD 2OVER
		// Copy a cell pair x1 x2 to the top of the stack.

	}// @STACK ( x1 x2 x3 x4 - x1 x2 x3 x4 x1 x2 )
	public void TwoOver()
	{
		var x2 = Forth.DataStack[Forth.DsP + 2];
		var x1 = Forth.DataStack[Forth.DsP + 3];
		Forth.Push(x1);
		Forth.Push(x2);


	// @WORD 2SWAP
		// Exchange the top two cell pairs.

	}// @STACK ( x1 x2 x3 x4 - x3 x4 x1 x2 )
	public void TwoSwap()
	{
		var x2 = Forth.DataStack[Forth.DsP + 2];
		var x1 = Forth.DataStack[Forth.DsP + 3];
		Forth.DataStack[Forth.DsP + 3] = Forth.DataStack[Forth.DsP + 1];
		Forth.DataStack[Forth.DsP + 2] = Forth.DataStack[Forth.DsP];
		Forth.DataStack[Forth.DsP + 1] = x1;
		Forth.DataStack[Forth.DsP] = x2;


	// @WORD >BODY
		// Given a word's execution token, return the address of the start
		// of that word's parameter field.

	}// @STACK ( xt - a-addr )
	public void ToBody()
	{

		// Note this has no meaning for built-in execution tokens, which
		// have no parameter field.
		var xt = Forth.Pop();
		if(xt >= Forth.DictStart && xt < Forth.DictTop)
		{
			Forth.Push(xt + ForthRAM.CellSize);
		}
		else
		{
			Forth.Util.RprintTerm(" Invalid execution token (>BODY)");


	// @WORD >IN
			// Return address of a cell containing the offset, in characters,
			// from the start of the input buffer to the start of the current
			// parse position.

		}
	}// @STACK ( - a-addr )
	public void ToIn()
	{

		// terminal pointer or...
		if(Forth.SourceId ==  - 1)
		{
			Forth.Push(Forth.BuffToIn);
		}

	// file buffer pointer
		else if(Forth.SourceId)
		{
			Forth.Push(Forth.SourceId + Forth.FileBuffPtrOffset);


	// @WORD @
			// Replace a-addr with the contents of the cell at a_addr.

		}
	}// @STACK ( a_addr - x )
	public void Fetch()
	{
		Forth.Push(Forth.Ram.GetInt(Forth.Pop()));


	// @WORD [ IMMEDIATE
		// Enter interpretation state.

	}// @STACK  ( - )
	public void LeftBracket()
	{
		Forth.State = false;


	// @WORD ]
		// Enter compilation state.

	}// @STACK ( - )
	public void RightBracket()
	{
		Forth.State = true;


	// @WORD ABS
		// Replace the top stack item with its absolute value.

	}// @STACK ( n - +n )
	public void FAbs()
	{
		Forth.DataStack[Forth.DsP] = Mathf.Abs(Forth.DataStack[Forth.DsP]);


	// @WORD ALIGN
		// If the data-space pointer is not aligned, reserve space to align it.

	}// @STACK ( - )
	public void Align()
	{
		Forth.Push(Forth.DictTopP);
		Aligned();
		Forth.DictTopP = Forth.Pop();

		// preserve dictionary state
		Forth.SaveDictTop();


	// @WORD ALIGNED
		// Return a-addr, the first aligned address greater than or equal to addr.

	}// @STACK ( addr - a-addr )
	public void Aligned()
	{
		var a = Forth.Pop();
		if(a % ForthRAM.CellSize)
		{
			a = (a / ForthRAM.CellSize + 1) * ForthRAM.CellSize;
		}
		Forth.Push(a);


	// @WORD ALLOT
		// Allocate u bytes of data space beginning at the next location.

	}// @STACK ( u - )
	public void Allot()
	{
		Forth.DictTopP += Forth.Pop();

		// preserve dictionary state
		Forth.SaveDictTop();


	// @WORD AND
		// Return x3, the bit-wise logical AND of x1 and x2.

	}// @STACK ( x1 x2 - x3)
	public void FAnd()
	{
		Forth.Push(Forth.Pop() & Forth.Pop());


	// @WORD BASE
		// Return a-addr, the address of a cell containing the current number
		// conversion radix, between 2 and 36 inclusive.

	}// @STACK ( - a-addr )
	public void Base()
	{
		Forth.Push(Forth.Base);


	// @WORD BEGIN IMMEDIATE
		// Mark the destination of a backward branch.

	}// @STACK ( - dest )
	public void Begin()
	{

		// backwards by one cell, so execution will advance it to the right point
		Forth.CfPushDest(Forth.DictTopP - ForthRAM.CellSize);


	// @WORD BL
		// Return char, the ASCII character value of a space.

	}// @STACK ( - char )
	public void BL()
	{
		Forth.Push(ForthTerminal.BL.ToAsciiBuffer()[0]);


	// @WORD CELL+
		// Add the size in bytes of a cell to a_addr1, returning a_addr2.

	}// @STACK ( a-addr1 - a-addr2 )
	public void CellPlus()
	{
		Forth.Push(ForthRAM.CellSize);
		Plus();


	// @WORD CELLS
		// Return n2, the size in bytes of n1 cells.

	}// @STACK ( n1 - n2 )
	public void Cells()
	{
		Forth.Push(ForthRAM.CellSize);
		Star();


	// @WORD C!
		// Store the low-order character of the second stack item at c-addr,
		// removing both from the stack.

	}// @STACK ( c c-addr - )
	public void CStore()
	{
		var addr = Forth.Pop();
		Forth.Ram.SetByte(addr, Forth.Pop());


	// @WORD C,
		// Reserve one byte of data space and store char in the byte.

	}// @STACK ( char - )
	public void CComma()
	{
		Forth.Ram.SetByte(Forth.DictTopP, Forth.Pop());
		Forth.DictTopP += 1;

		// preserve dictionary state
		Forth.SaveDictTop();


	// @WORD C@
		// Replace c-addr with the contents of the character at c-addr. The character
		// fetched is stored in the low-order character of the top stack item, with
		// the remaining bits set to zero.

	}// @STACK ( c-addr - c )
	public void CFetch()
	{
		Forth.Push(Forth.Ram.GetByte(Forth.Pop()));


	// @WORD CHAR+
		// Add the size in bytes of a character to c_addr1, giving c-addr2.

	}// @STACK ( c-addr1 - c-addr2 )
	public void CharPlus()
	{
		Forth.Push(1);
		Plus();


	// @WORD CHARS
		// Return n2, the size in bytes of n1 characters. May be a no-op.

	}// @STACK ( n1 - n2 )
	public void Chars()
	{


	// @WORD CONSTANT
		// Create a dictionary entry for <name>, associated with constant x.
		// Executing <name> places the value on the stack.
		// Usage: <x> CONSTANT <name>

	}// @STACK Compile: ( "name" x - ), Execute: ( - x )
	public void Constant()
	{
		var init_val = Forth.Pop();
		if(Forth.CreateDictEntryName())
		{

			// copy the execution token


			Forth.Ram.SetInt(Forth.DictTopP, Forth.AddressFromBuiltInFunction[constant_exec]);

			// store the constant
			Forth.Ram.SetInt(Forth.DictTopP + ForthRAM.CellSize, init_val);
			Forth.DictTopP += ForthRAM.DCellSize;
			// two cells up
			// preserve dictionary state
			Forth.SaveDictTop();
		}
	}


// @WORDX CONSTANT
	public void ConstantExec()
	{

		// execution time functionality of _constant
		// return contents of cell after execution token
		Forth.Push(Forth.Ram.GetInt(Forth.DictIp + ForthRAM.CellSize));


	// @WORD COUNT
		// Return the length u, and address of the text portion of a counted string.

	}// @STACK ( c_addr1 - c_addr2 u )
	public void Count()
	{
		var addr = Forth.Pop();
		Forth.Push(addr + 1);
		Forth.Push(Forth.Ram.GetByte(addr));


	// @WORD CR
		// Emit characters to generate a newline on the terminal.

	}// @STACK ( - )
	public void CR()
	{
		Forth.Util.PrintTerm(ForthTerminal.CRLF);


	// @WORD CREATE
		// Construct a dictionary entry for the next token <name> in the input stream.
		// Execution of <name> will return the address of its data space.

	}// @STACK Compile: ( "name" - ), Execute: ( - addr )
	public void Create()
	{
		if(Forth.CreateDictEntryName())
		{


			Forth.Ram.SetInt(Forth.DictTopP, Forth.AddressFromBuiltInFunction[create_exec]);
			Forth.DictTopP += ForthRAM.CellSize;

			// preserve dictionary state
			Forth.SaveDictTop();
		}
	}


// @WORDX CREATE
	public void CreateExec()
	{

		// execution time functionality of create
		// return address of cell after execution token
		Forth.Push(Forth.DictIp + ForthRAM.CellSize);


	// @WORD DECIMAL
		// Sets BASE to 10.

	}// @STACK ( - )
	public void Decimal()
	{
		Forth.Push(10);
		Base();
		Store();


	// @WORD DEPTH
		// Return the number of single-cell values on the stack before execution.

	}// @STACK ( - +n )
	public void Depth()
	{

		// ( - +n )
		Forth.Push(Forth.DataStackSize - Forth.DsP);


	// @WORD DO IMMEDIATE
		// Establish loop parameters, initial index n2 on the top of stack,
		// with the limit value n1 below it. These are transferred to the
		// return stack when DO is executed.

	}// @STACK ( n1 n2 - )
	public void Do()
	{

		// copy the execution token


		Forth.Ram.SetInt(Forth.DictTopP, Forth.AddressFromBuiltInFunction[do_exec]);

		// mark a destination for a backward branch
		Begin();

		// move up to finish
		Forth.DictTopP += ForthRAM.CellSize;
		// one cell up
		// preserve dictionary state
		Forth.SaveDictTop();
	}


// @WORDX DO
	public void DoExec()
	{

		// push limit, then count on return stack
		Forth.CoreExt.TwoToR();


	// @WORD DUP
		// Duplicate the top entry on the stack.

	}// @STACK ( x - x x )
	public void Dup()
	{
		Forth.Push(Forth.DataStack[Forth.DsP]);


	// @WORD DROP
		// Drop (remove) the top entry of the stack.

	}// @STACK ( x - )
	public void Drop()
	{
		Forth.Pop();


	// @WORD ELSE IMMEDIATE
		// At compile time, originate the TRUE branch and and resolve the FALSE.

	}// @STACK ( - )
	public void FElse()
	{
		Forth.ToolsExt.Ahead();
		Forth.CfStackRoll(1);
		FThen();


	// @WORD EMIT
		// Output one character from the LS byte of the top item on stack.

	}// @STACK ( b - )
	public void Emit()
	{
		var c = Forth.Pop();
		Forth.Util.PrintTerm(Char(c));


	// @WORD EVALUATE
		// Use c-addr, u as the buffer start and interpret as Forth source.

	}// @STACK ( i*x c-addr u - j*x )
	public void Evaluate()
	{
		// we can discard the buffer location, since we use the source_id
		// to identify the buffer
		Forth.Pop();
		Forth.Pop();

		// buffer pointer is based on source-id
		Forth.ResetBuffToIn();
		while(true)
		{

			// call the Forth WORD, setting blank as delimiter
			Forth.CoreExt.ParseName();
			var len = Forth.Pop();
			// length of word
			var caddr = Forth.Pop();
			// start of word
			// out of tokens?
			if(len == 0)
			{
				break;
			}
			var t = Forth.Util.StrFromAddrN(caddr, len);

			// t should be the next token, try to get an execution token from it
			var xt_immediate = Forth.FindInDict(t);
			if(!xt_immediate[0] && Forth.BuiltInFunction.Contains(t.ToUpper()))
			{
				xt_immediate = new Array{Forth.XtFromWord(t.ToUpper()), false, };
			}

		// an execution token exists
			if(xt_immediate[0] != 0)
			{
				Forth.Push(xt_immediate[0]);

				// check if it is a built-in immediate or dictionary immediate before storing
				if(Forth.State && !(Forth.IsImmediate(t) || xt_immediate[1]))
				{
					// Compiling
					Forth.Core.Comma();
				}
				// store at the top of the current : definition
				else
				{
					// Not Compiling or immediate - just execute
					Forth.Core.Execute();
				}
			}

	// no valid token, so maybe valid numeric value (double first)
			else
			{

				// check for a number
				Forth.Push(caddr);
				Forth.Push(len);
				Forth.CommonUse.NumberQuestion();
				var type = Forth.Pop();
				if(type == 2 && Forth.State)
				{
					Forth.Double.TwoLiteral();
				}
				else if(type == 1 && Forth.State)
				{
					Literal();
				}
				else if(type == 0)
				{
					Forth.Util.PrintUnknownWord(t);

					// do some clean up if we were compiling
					Forth.UnwindCompile();
					break;
					// not ok

				}
			}// check the stack at each step..
			if(Forth.DsP < 0)
			{
				Forth.Util.RprintTerm(" Data stack overflow");
				Forth.DsP = AMCForth.DataStackSize;
				break;
			}
			// not ok
			if(Forth.DsP > AMCForth.DataStackSize)
			{
				Forth.Util.RprintTerm(" Data stack underflow");
				Forth.DsP = AMCForth.DataStackSize;
				break;


				// not ok
				// @WORD EXECUTE
				// Remove execution token xt from the stack and perform
				// the execution behavior it identifies.

			}
		}
	}// @STACK ( xt - )
	public void Execute()
	{
		var xt = Forth.Pop();
		if(Forth.BuiltInFunctionFromAddress.Contains(xt))
		{

			// this xt identifies a gdscript function
			Forth.BuiltInFunctionFromAddress[xt].Call();
		}
		else if(xt >= Forth.DictStart && xt < Forth.DictTop)
		{

			// save the current ip
			Forth.PushIp();

			// this is a physical address of an xt
			Forth.DictIp = xt;

			// push the xt
			Forth.Push(Forth.Ram.GetInt(xt));

			// recurse down a layer
			Execute();

			// restore our ip
			Forth.PopIp();
		}
		else
		{
			Forth.Util.RprintTerm(" Invalid execution token (EXECUTE)");


	// @WORD EXIT
			// Return control to the calling definition in the ip-stack.

		}
	}// @STACK ( - )
	public void Exit()
	{

		// set a flag indicating exit has been called
		Forth.ExitFlag = true;


	// @WORD HERE
		// Return address of the next available location in data-space.

	}// @STACK ( - addr )
	public void Here()
	{
		Forth.Push(Forth.DictTopP);


	// @WORD I
		// Push a copy of the current DO-LOOP index value to the stack.

	}// @STACK ( - n )
	public void I()
	{
		RFetch();


	// @WORD IF IMMEDIATE
		// Place forward reference origin on the control flow stack.

	}// @STACK ( - orig )
	public void FIf()
	{

		// copy the execution token


		Forth.Ram.SetInt(Forth.DictTopP, Forth.AddressFromBuiltInFunction[f_if_exec]);

		// leave link address on the control stack
		Forth.CfPushOrig(Forth.DictTopP + ForthRAM.CellSize);

		// move up to finish
		Forth.DictTopP += ForthRAM.DCellSize;
		// two cells up
		// preserve dictionary state
		Forth.SaveDictTop();
	}


// @WORDX IF
	public void FIfExec()
	{

		// Branch to ELSE if top of stack not TRUE
		// ( x - )
		if(Forth.Pop() == 0)
		{
			Forth.DictIp = Forth.Ram.GetInt(Forth.DictIp + ForthRAM.CellSize);
		}
		else
		{

			// TRUE, so skip over the link and continue executing
			Forth.DictIp += ForthRAM.CellSize;


	// @WORD IMMEDIATE
			// Make the most recent definition (top of the dictionary) an IMMEDIATE word.

		}
	}// @STACK ( - )
	public void Immediate()
	{

		// Set the IMMEDIATE bit in the name length byte
		if(Forth.DictP != Forth.DictTopP)
		{

			// dictionary is not empty, get the length of the top entry name
			var length_byte_addr = Forth.DictP + ForthRAM.CellSize;

			// set the immediate bit in the length byte


			Forth.Ram.SetByte(length_byte_addr, Forth.Ram.GetByte(length_byte_addr) | Forth.ImmediateBitMask);


	// @WORD INVERT
			// Invert all bits of x1, giving its logical inverse, x2.

		}
	}// @STACK ( x1 - x2 )
	public void Invert()
	{
		Forth.DataStack[Forth.DsP] =  ~ Forth.DataStack[Forth.DsP];


	// @WORD J
		// Push a copy of the next-outer DO-LOOP index value to the stack.

	}// @STACK ( - n )
	public void J()
	{

		// reach up into the return stack for the value
		Forth.Push(Forth.ReturnStack[Forth.RsP + 2]);


	// @WORD LEAVE IMMEDIATE
		// Discard loop parameters and continue execution immediately following
		// the next LOOP or LOOP+ containing this LEAVE.

	}// @STACK ( - )
	public void Leave()
	{

		// copy the execution token


		Forth.Ram.SetInt(Forth.DictTopP, Forth.AddressFromBuiltInFunction[leave_exec]);

		// leave a special LEAVE link address on the leave control stack
		Forth.LcfPush(Forth.DictTopP + ForthRAM.CellSize);

		// move up to finish
		Forth.DictTopP += ForthRAM.DCellSize;
		// two cells up
		// preserve dictionary state
		Forth.SaveDictTop();
	}


// @WORDX LEAVE
	public void LeaveExec()
	{

		// Discard loop parameters
		Forth.RPop();
		Forth.RPop();

		// Skip ahead to the LOOP address in the next cell
		Forth.DictIp = Forth.Ram.GetInt(Forth.DictIp + ForthRAM.CellSize);


	// @WORD LITERAL IMMEDIATE
		// At execution time, remove the top number from the stack and compile
		// into the current definition. Upon executing <name>, place the
		// number on the top of the stack.

	}// @STACK Compile:  ( x - ), Execute: ( - x )
	public void Literal()
	{
		var literal_val = Forth.Pop();

		// copy the execution token


		Forth.Ram.SetInt(Forth.DictTopP, Forth.AddressFromBuiltInFunction[literal_exec]);

		// store the value
		Forth.Ram.SetInt(Forth.DictTopP + ForthRAM.CellSize, literal_val);
		Forth.DictTopP += ForthRAM.DCellSize;
		// two cells up
		// preserve dictionary state
		Forth.SaveDictTop();
	}


// @WORDX LITERAL
	public void LiteralExec()
	{

		// execution time functionality of literal
		// return contents of cell after execution token
		Forth.Push(Forth.Ram.GetInt(Forth.DictIp + ForthRAM.CellSize));

		// advance the instruction pointer by one to skip over the data
		Forth.DictIp += ForthRAM.CellSize;


	// @WORD LSHIFT
		// Perform a logical left shift of u places on x1, giving x2.
		// Fill the vacated LSB bits with zero.

	}// @STACK (x1 u - x2 )
	public void Lshift()
	{
		Swap();
		Forth.Push(Forth.Ram.TruncateToCell(Forth.Pop() << Forth.Pop()));


	// @WORD LOOP IMMEDIATE
		// Increment the index value by one and compare to the limit value.
		// If they are equal, continue with the next instruction, otherwise
		// return to the address of the preceding DO.

	}// @STACK ( dest orig - )
	public void Loop()
	{

		// copy the execution token


		Forth.Ram.SetInt(Forth.DictTopP, Forth.AddressFromBuiltInFunction[loop_exec]);

		// Check for any orig links
		while(!Forth.LcfIsEmpty())
		{

			// destination is on top of the back link
			Forth.Ram.SetInt(Forth.LcfPop(), Forth.DictTopP + ForthRAM.CellSize);
		}

	// The link back
		Forth.Ram.SetInt(Forth.DictTopP + ForthRAM.CellSize, Forth.CfPopDest());
		Forth.DictTopP += ForthRAM.DCellSize;
		// two cells up and done
		// preserve dictionary state
		Forth.SaveDictTop();
	}


// @WORDX LOOP
	public void LoopExec()
	{

		// Move to data stack.
		Forth.CoreExt.TwoRFrom();

		// Increment the count
		OnePlus();

		// Duplicate them
		TwoDup();

		// Check for equal
		Equal();
		if(Forth.Pop() == 0)
		{

			// not matched, branch back. The DO exec will push the values
			// back on the return stack.
			Forth.DictIp = Forth.Ram.GetInt(Forth.DictIp + ForthRAM.CellSize);
		}
		else
		{

			// spare pair of loop parameters is not needed.
			TwoDrop();

			// step ahead over the branch
			Forth.DictIp += ForthRAM.CellSize;


	// @WORD M*
			// Multiply n1 by n2, leaving the double result d.

		}
	}// @STACK ( n1 n2 - d )
	public void MStar()
	{
		Forth.PushDint(Forth.Pop() * Forth.Pop());


	// @WORD MAX
		// Return n3, the greater of n1 and n2.

	}// @STACK ( n1 n2 - n3 )
	public void Max()
	{
		var n2 = Forth.Pop();
		if(n2 > Forth.DataStack[Forth.DsP])
		{
			Forth.DataStack[Forth.DsP] = n2;


	// @WORD MIN
			// Return n3, the lesser of n1 and n2.

		}
	}// @STACK ( n1 n2 - n3 )
	public void Min()
	{
		var n2 = Forth.Pop();
		if(n2 < Forth.DataStack[Forth.DsP])
		{
			Forth.DataStack[Forth.DsP] = n2;


	// @WORD MOD
			// Divide n1 by n2, giving the remainder n3.

		}
	}// @STACK (n1 n2 - n3 )
	public void Mod()
	{
		var n2 = Forth.Pop();
		Forth.Push(Forth.Pop() % n2);


	// @WORD MOVE
		// Copy u byes from a source starting at addr1, to the destination
		// starting at addr2. This works even if the ranges overlap.

	}// @STACK ( addr1 addr2 u - )
	public void Move()
	{
		var a1 = Forth.DataStack[Forth.DsP + 2];
		var a2 = Forth.DataStack[Forth.DsP + 1];
		var u = Forth.DataStack[Forth.DsP];
		if(a1 == a2 || u == 0)
		{

			// string doesn't need to move. Clean the stack and return.
			Drop();
			Drop();
			Drop();
			return ;
		}
		if(a1 > a2)
		{

			// potentially overlapping, source above dest
			Forth.String.CMove();
		}
		else
		{

			// potentially overlapping, source below dest
			Forth.String.CMoveUp();


	// @WORD NEGATE
			// Change the sign of the top stack value.

		}
	}// @STACK ( n - -n )
	public void Negate()
	{
		Forth.DataStack[Forth.DsP] =  - Forth.DataStack[Forth.DsP];


	// @WORD OR
		// Return x3, the bit-wise inclusive or of x1 with x2.

	}// @STACK ( x1 x2 - x3 )
	public void FOr()
	{
		Forth.Push(Forth.Pop() | Forth.Pop());


	// @WORD OVER
		// Place a copy of x1 on top of the stack.

	}// @STACK ( x1 x2 - x1 x2 x1 )
	public void Over()
	{
		Forth.Push(Forth.DataStack[Forth.DsP + 1]);


	// @WORD POSTPONE IMMEDIATE
		// At compile time, add the compilation behavior of the following
		// name, rather than its execution behavior.

	}// @STACK ( "name" - )
	public void Postpone()
	{

		// parse for the next token
		Forth.CoreExt.ParseName();
		var len = Forth.Pop();
		// length
		var caddr = Forth.Pop();
		// start
		var word = Forth.Util.StrFromAddrN(caddr, len);

		// obtain and push the compiled xt for this word
		Forth.Push(Forth.XtxFromWord(word));

		// then store it in the current definition
		Comma();


	// @WORD R@
		// Place a copy of the item on top of the return stack onto the data stack.

	}// @STACK (S: - x ) (R: x - x )
	public void RFetch()
	{
		var t = Forth.RPop();
		Forth.Push(t);
		Forth.RPush(t);


	// @WORD REPEAT IMMEDIATE
		// At compile time, resolve two branches, usually set up by BEGIN and WHILE.
		// At run-time, execute the unconditional backward branch to the location
		// following BEGIN.

	}// @STACK ( - )
	public void Repeat()
	{
		Forth.CfStackRoll(1);
		Forth.CoreExt.Again();
		FThen();


	// @WORD ROT
		// Rotate the top three items on the stack.

	}// @STACK ( x1 x2 x3 - x2 x3 x1 )
	public void Rot()
	{
		var t = Forth.DataStack[Forth.DsP + 2];
		Forth.DataStack[Forth.DsP + 2] = Forth.DataStack[Forth.DsP + 1];
		Forth.DataStack[Forth.DsP + 1] = Forth.DataStack[Forth.DsP];
		Forth.DataStack[Forth.DsP] = t;


	// @WORD RSHIFT
		// Perform a logical right shift of u places on x1, giving x2.
		// Fill the vacated MSB bits with zeros.

	}// @STACK ( x1 u - x2 )
	public void Rshift()
	{
		var u = Forth.Pop();
		Forth.DataStack[Forth.DsP] = (int) (((uint) Forth.DataStack[Forth.DsP]) >> u);
	}


// Utility function for parsing strings
	public void StartString()
	{
		Forth.Push("\"".ToAsciiBuffer()[0]);
		Forth.CoreExt.Parse();


	// @WORD S" IMMEDIATE
		// Return the address and length of the following string, terminated by ",
		// which is in a temporary buffer.

	}// @STACK ( "string" - c-addr u )
	public void SQuote()
	{
		StartString();
		var l = Forth.Pop();
		// length of the string
		var src = Forth.Pop();
		// first byte address
		// different compilation behavior
		if(Forth.State)
		{

			// copy the execution token


			Forth.Ram.SetInt(Forth.DictTopP, Forth.AddressFromBuiltInFunction[s_quote_exec]);

			// store the value
			Forth.DictTopP += ForthRAM.CellSize;
			Forth.Ram.SetByte(Forth.DictTopP, l);
			// store the length
			// compile the string into the dictionary
			foreach(int i in l)
			{
				Forth.DictTopP += 1;
				Forth.Ram.SetByte(Forth.DictTopP, Forth.Ram.GetByte(src + i));
			}

		// this will align the dict top and save it
			Align();
		}
		else
		{

			// just copy it at the end of the dictionary as a temporary area
			foreach(int i in l)
			{
				Forth.Ram.SetByte(Forth.DictTopP + i, Forth.Ram.GetByte(src + i));
			}

		// push the return values back on
			Forth.Push(Forth.DictTopP);
			Forth.Push(l);
		}
	}


// @WORDX S"
	public void SQuoteExec()
	{
		var l = Forth.Ram.GetByte(Forth.DictIp + ForthRAM.CellSize);
		Forth.Push(Forth.DictIp + ForthRAM.CellSize + 1);
		// address of the string start
		Forth.Push(l);
		// length of the string
		// moves to string cell for l in 0..3, then one cell past for l in 4..7, etc.
		Forth.DictIp += ((l / ForthRAM.CellSize) + 1) * ForthRAM.CellSize;


	// @WORD S>D
		// Convert a single cell number n to its double equivalent d

	}// @STACK ( n - d )
	public void SToD()
	{
		Forth.PushDint(Forth.Pop());


	// @WORD SM/REM
		// Divide d by n1, using symmetric division, giving quotient n3 and
		// remainder n2. All arguments are signed.

	}// @STACK ( d n1 - n2 n3 )
	public void SmSlashRem()
	{
		var n1 = Forth.Pop();
		var d = Forth.PopDint();
		Forth.Push(d % n1);
		Forth.Push(d / n1);


	// @WORD SOURCE
		// Return the address and length of the input buffer.

	}// @STACK ( - c-addr u )
	public void Source()
	{
		if(Forth.SourceId ==  - 1)
		{
			Forth.Push(Forth.BuffSourceStart);
			Forth.Push(Forth.BuffSourceSize);
		}
		else if(Forth.SourceId)
		{
			Forth.Push(Forth.SourceId + Forth.FileBuffDataOffset);
			Forth.Push(Forth.FileBuffDataSize);


	// @WORD SPACE
			// Display one space on the current output device.

		}
	}// @STACK ( - )
	public void Space()
	{
		Forth.Util.PrintTerm(ForthTerminal.BL);


	// @WORD SPACES
		// Display u spaces on the current output device.

	}// @STACK ( u - )
	public void Spaces()
	{
		foreach(int i in Forth.Pop())
		{
			Forth.Util.PrintTerm(ForthTerminal.BL);


	// @WORD SWAP
			// Exchange the top two items on the stack.

		}
	}// @STACK ( x1 x2 - x2 x1 )
	public void Swap()
	{
		var x1 = Forth.DataStack[Forth.DsP + 1];
		Forth.DataStack[Forth.DsP + 1] = Forth.DataStack[Forth.DsP];
		Forth.DataStack[Forth.DsP] = x1;


	// @WORD THEN IMMEDIATE
		// Place a reference to the this address at the address on the cf stack.

	}// @STACK ( orig - )
	public void FThen()
	{

		// Note: this only places the forward reference to the position
		// just before this (the caller will step to the next location).
		// No f_then_exec function is needed.
		Forth.Ram.SetInt(Forth.CfPopOrig(), Forth.DictTopP - ForthRAM.CellSize);


	// @WORD U<
		// Return true if and only if u1 is less than u2.

	}// @STACK ( u1 u2 - flag )
	public void ULessThan()
	{
		var u2 = (uint) Forth.Pop();
		if((uint)Forth.Pop() < u2)
		{
			Forth.Push(AMCForth.True);
		}
		else
		{
			Forth.Push(AMCForth.False);


	// @WORD UNLOOP
			// Discard the loop parameters for the current nesting level.

		}
	}// @STACK ( - )
	public void Unloop()
	{
		Forth.RPopDint();


	// @WORD UNTIL IMMEDIATE
		// Conditionally branch back to the point immediately following
		// the nearest previous BEGIN.

	}// @STACK ( dest x - )
	public void Until()
	{

		// copy the execution token


		Forth.Ram.SetInt(Forth.DictTopP, Forth.AddressFromBuiltInFunction[until_exec]);

		// The link back
		Forth.Ram.SetInt(Forth.DictTopP + ForthRAM.CellSize, Forth.CfPopDest());
		Forth.DictTopP += ForthRAM.DCellSize;


		// two cells up and done

	}// @WORDX UNTIL
	public void UntilExec()
	{

		// ( x - )
		// Conditional branch
		if(Forth.Pop() == 0)
		{
			Forth.DictIp = Forth.Ram.GetInt(Forth.DictIp + ForthRAM.CellSize);
		}
		else
		{

			// TRUE, so skip over the link and continue executing
			Forth.DictIp += ForthRAM.CellSize;


	// @WORD WHILE IMMEDIATE
			// At compile time, place a new unresolved forward reference origin on the
			// control stack. At run-time, if x is zero, take the forward branch to the
			// destination supplied by REPEAT.

		}
	}// @STACK ( - )
	public void FWhile()
	{
		FIf();


	// @WORD WORD
		// Skip leading occurrences of the delimiter char. Parse text
		// delimited by char. Return the address of a temporary location
		// containing the passed text as a counted string.

	}// @STACK ( char - c-addr )
	public void Word()
	{
		Dup();
		var delim = Forth.Pop();
		Source();
		var source_size = Forth.Pop();
		var source_start = Forth.Pop();
		ToIn();
		var ptraddr = Forth.Pop();
		while(true)
		{


			var t = Forth.Ram.GetByte(source_start + Forth.Ram.GetInt(ptraddr));
			if(t == delim)
			{

				// increment the input pointer
				Forth.Ram.SetInt(ptraddr, Forth.Ram.GetInt(ptraddr) + 1);
			}
			else
			{
				break;
			}
		}
		Forth.CoreExt.Parse();
		var count = Forth.Pop();
		var straddr = Forth.Pop();
		var ret = straddr - 1;
		Forth.Ram.SetByte(ret, count);
		Forth.Push(ret);


	// @WORD TYPE
		// Output the character string at c-addr, length u.

	}// @STACK ( c-addr u - )
	public void Type()
	{
		var l = Forth.Pop();
		var s = Forth.Pop();
		foreach(int i in l)
		{
			Forth.Push(Forth.Ram.GetByte(s + i));
			Emit();
		}
	}

	// @WORD UM*
	// Multiply u1 by u2, leaving the double-precision result ud
	// @STACK ( u1 u2 - ud )
	public void UmStar()
	{
		Forth.PushDword(
			(Forth.Pop() & ~ ForthRAM.CELL_MAX_NEGATIVE) * 
			(Forth.Pop() & ~ ForthRAM.CELL_MAX_NEGATIVE)
		);
	}

	// @WORD UM/MOD
	// Divide ud by n1, leaving quotient n3 and remainder n2.
	// All arguments and result are unsigned.
	// @STACK ( d u1 - u2 u3 )
	public void UmSlashMod()
	{
		var u1 = Forth.Pop() & ~ ForthRAM.CELL_MAX_NEGATIVE;

		// there is no gdscript way of treating this as unsigned
		var d = Forth.PopDword();
		Forth.Push(d % u1);
		Forth.Push(d / u1);
	}

	// @WORD VARIABLE
	// Create a dictionary entry for name associated with one cell of data.
	// Executing <name> returns the address of the allocated cell.
	// @STACK Compile: ( "name" - ), Execute: ( - addr )
	public void Variable()
	{
		Forth.Core.Create();

		// make room for one cell
		Forth.DictTopP += ForthRAM.CellSize;

		// preserve dictionary state
		Forth.SaveDictTop();
	}

	// @WORD XOR
	// Return x3, the bit-wise exclusive or of x1 with x2.
	// @STACK ( x1 x2 - x3 )
	public void Xor()
	{
		Forth.Push(Forth.Pop() ^ Forth.Pop());
	}
}
