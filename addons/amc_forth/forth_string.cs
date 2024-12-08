using Godot;
using Godot.Collections;


//# @WORDSET String


//#
//# Initialize (executed automatically by ForthString.new())
//#
//# (1) All functions with "## @WORD <word>" comment will become
//# the default implementation for the built-in word.
//# (2) All functions with "## @WORDX <word>" comment will become
//# the *compiled* implementation for the built-in word.
//# (3) Define an IMMEDIATE function with "## @WORD <word> IMMEDIATE"
//# (4) UP TO four comments beginning with "##" before function
//# (5) Final comment must be "## @STACK" followed by stack def.
[GlobalClass]
public partial class ForthString : ForthImplementationBase
{
	public override void Initialize(AMCForth _forth)
	{
		Super(_forth);


	//# @WORD CMOVE
		//# Copy u characters from addr1 to addr2. The copy proceeds from
		//# LOWER to HIGHER addresses.

	}//# @STACK ( addr1 addr2 u - )
	public void CMove()
	{
		var u = Forth.Pop();
		var a2 = Forth.Pop();
		var a1 = Forth.Pop();
		var i = 0;

		// move in ascending order a1 -> a2, fast, then slow
		while(i < u)
		{
			if(u - i >= ForthRAM.DCellSize)
			{
				Forth.Ram.SetDword(a2 + i, Forth.Ram.GetDword(a1 + i));
				i += ForthRAM.DCellSize;
			}
			else
			{
				Forth.Ram.SetByte(a2 + i, Forth.Ram.GetByte(a1 + i));
				i += 1;


	//# @WORD CMOVE>
				//# Copy u characters from addr1 to addr2. The copy proceeds from
				//# HIGHER to LOWER addresses.

			}
		}
	}//# @STACK ( addr1 addr2 u - )
	public void CMoveUp()
	{
		var u = Forth.Pop();
		var a2 = Forth.Pop();
		var a1 = Forth.Pop();
		var i = u;

		// move in descending order a1 -> a2, fast, then slow
		while(i > 0)
		{
			if(i >= ForthRAM.DCellSize)
			{
				i -= ForthRAM.DCellSize;
				Forth.Ram.SetDword(a2 + i, Forth.Ram.GetDword(a1 + i));
			}
			else
			{
				i -= 1;
				Forth.Ram.SetByte(a2 + i, Forth.Ram.GetByte(a1 + i));


	//# @WORD COMPARE
				//# Compare string to string (see details in Forth docs).

			}
		}
	}//# @STACK ( c-addr1 u1 c-addr2 u2 - n )
	public void Compare()
	{
		var n2 = Forth.Pop();
		var a2 = Forth.Pop();
		var n1 = Forth.Pop();
		var a1 = Forth.Pop();
		var s2 = Forth.Util.StrFromAddrN(a2, n2);
		var s1 = Forth.Util.StrFromAddrN(a1, n1);
		var ret = 0;
		if(s1 == s2)
		{
			Forth.Push(ret);
		}
		else if(s1 < s2)
		{
			Forth.Push( - 1);
		}
		else
		{
			Forth.Push(1);
		}
	}


}
