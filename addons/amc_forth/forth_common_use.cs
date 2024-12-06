using Godot;
using Godot.Collections;

// @WORDSET Common Use
//
// These words are not in the Forth Standard (forth-standard.org)
// but are in "common use" as described in "Forth Programmer's Handbook"

// by Conklin and Rather


// Initialize (executed automatically by ForthCommonUse.new())
//
// (1) All functions with "## @WORD <word>" comment will become
// the default implementation for the built-in word.
// (2) All functions with "## @WORDX <word>" comment will become
// the *compiled* implementation for the built-in word.
// (3) Define an IMMEDIATE function with "## @WORD <word> IMMEDIATE"
// (4) UP TO four comments beginning with "##" before function
// (5) Final comment must be "## @STACK" followed by stack def.
[GlobalClass]
public partial class ForthCommonUse : ForthImplementationBase
{
	public override void Initialize(AMCForth _forth)
	{
		Super(_forth);
	}

	// @WORD 2+
	// Add two to n1, leaving n2.
	// @STACK ( n1 - n2 )
	public void TwoPlus()
	{
		Forth.Push(2);
		Forth.Core.Plus();
	}

	// @WORD 2-
	// Subtract two from n1, leaving n2.
	// @STACK ( n1 - n2 )
	public void TwoMinus()
	{
		Forth.Push(2);
		Forth.Core.Minus();
	}

	// @WORD M-
	// Subtract n from d1 leaving the difference d2.
	// @STACK ( d1 n - d2 )
	public void MMinus()
	{
		var n = Forth.Pop();
		Forth.PushDint(Forth.PopDint() - n);
	}

	// @WORD M/
	// Divide d by n1 leaving the single precision quotient n2.
	// @STACK ( d n1 - n2 )
	public void MSlash()
	{
		var n = Forth.Pop();
		Forth.Push(Forth.PopDint() / n);
	}

	// @WORD NOT
	// Identical to 0=, used for program clarity to reverse logical result.
	// @STACK ( x - flag )
	public void FNot()
	{
		Forth.Core.ZeroEqual();
	}

	// @WORD NUMBER?
	// Attempt to convert a string at c-addr of length u into digits using
	// BASE as radis. If a decimal point is found, return a double, ootherwise
	// return a single, with a flag: 0 = failure, 1 = single, 2 = double.
	// @STACK ( c-addr u - 0 | n 1 | d 2 )
	public void NumberQuestion()
	{
		var radix = Forth.Ram.GetInt(Forth.BASE);
		var len = Forth.Pop();
		// length of word
		var caddr = Forth.Pop();
		// start of word
		var t = Forth.Util.StrFromAddrN(caddr, len);
		if(t.Contains(".") && Forth.IsValidInt(t.Replace(".", ""), radix))
		{
			var t_strip = t.Replace(".", "");
			var temp = Forth.ToInt(t_strip, radix);
			Forth.PushDword(temp);
			Forth.Push(2);
		}
		else if(Forth.IsValidInt(t, radix))
		{
			var temp = Forth.ToInt(t, radix);

			// single-precision
			Forth.Push(temp);
			Forth.Push(1);
		}

	// nothing we recognize
		else
		{
			Forth.Push(0);
		}
	}


}
