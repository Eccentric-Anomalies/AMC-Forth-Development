using Godot;
using Godot.Collections;
// gdlint:ignore = max-public-methods
//# @WORDSET Double

//#


//# Initialize (executed automatically by ForthDouble.new())
//#
//# (1) All functions with "## @WORD <word>" comment will become
//# the default implementation for the built-in word.
//# (2) All functions with "## @WORDX <word>" comment will become
//# the *compiled* implementation for the built-in word.
//# (3) Define an IMMEDIATE function with "## @WORD <word> IMMEDIATE"
//# (4) UP TO four comments beginning with "##" before function
//# (5) Final comment must be "## @STACK" followed by stack def.
[GlobalClass]
public partial class ForthDouble : ForthImplementationBase
{
	public override void Initialize(AMCForth _forth)
	{
		Super(_forth);


	//# @WORD 2CONSTANT
		//# Create a dictionary entry for name, associated with constant double d.

	}//# @STACK Compile: ( "name" d - ), Execute: ( - d )
	public void TwoConstant()
	{
		var init_val = Forth.PopDword();
		if(Forth.CreateDictEntryName())
		{

			// copy the execution token


			Forth.Ram.SetInt(Forth.DictTop, Forth.AddressFromBuiltInFunction[two_constant_exec]);

			// store the constant
			Forth.Ram.SetDword(Forth.DictTop + ForthRAM.CELL_SIZE, init_val);
			Forth.DictTop += ForthRAM.CELL_SIZE + ForthRAM.DCELL_SIZE;

			// preserve dictionary state
			Forth.SaveDictTop();
		}
	}


//# @WORDX 2CONSTANT
	public void TwoConstantExec()
	{

		// execution time functionality of _two_constant
		// return contents of double cell after execution token
		Forth.PushDword(Forth.Ram.GetDword(Forth.DictIp + ForthRAM.CELL_SIZE));


	//# @WORD 2LITERAL
		//# At compile time, remove the top two numbers from the stack and compile
		//# into the current definition.

	}//# @STACK Compile:  ( x x - ), Execute: ( - x x )
	public void TwoLiteral()
	{
		var literal_val1 = Forth.Pop();
		var literal_val2 = Forth.Pop();

		// copy the execution token


		Forth.Ram.SetInt(Forth.DictTop, Forth.AddressFromBuiltInFunction[two_literal_exec]);

		// store the value
		Forth.Ram.SetInt(Forth.DictTop + ForthRAM.CELL_SIZE, literal_val1);
		Forth.Ram.SetInt(Forth.DictTop + ForthRAM.DCELL_SIZE, literal_val2);
		Forth.DictTop += ForthRAM.CELL_SIZE * 3;
		// three cells up
		// preserve dictionary state
		Forth.SaveDictTop();
	}


//# @WORDX 2LITERAL
	public void TwoLiteralExec()
	{

		// execution time functionality of literal
		// return contents of cell after execution token
		Forth.Push(Forth.Ram.GetInt(Forth.DictIp + ForthRAM.DCELL_SIZE));
		Forth.Push(Forth.Ram.GetInt(Forth.DictIp + ForthRAM.CELL_SIZE));

		// advance the instruction pointer by one to skip over the data
		Forth.DictIp += ForthRAM.DCELL_SIZE;


	//# @WORD 2VARIABLE
		//# Create a dictionary entry for name associated with two cells of data.
		//# Executing <name> returns the address of the allocated cells.

	}//# @STACK Compile: ( "name" - ), Execute: ( - addr )
	public void TwoVariable()
	{
		Forth.Core.Create();

		// make room for one cell
		Forth.DictTop += ForthRAM.DCELL_SIZE;

		// preserve dictionary state
		Forth.SaveDictTop();


	//# @WORD D.
		//# Display the top cell pair on the stack as a signed double integer.

	}//# @STACK ( d - )
	public void DDot()
	{
		var fmt = ( Forth.Ram.GetInt(Forth.BASE) == 10 ? "%d" : "%x" );
		Forth.Util.PrintTerm(" " + fmt % Forth.PopDint());


	//# @WORD D-
		//# Subtract d2 from d1, leaving the difference d3.

	}//# @STACK ( d1 d2 - d3 )
	public void DMinus()
	{
		var t = Forth.PopDint();
		Forth.PushDint(Forth.PopDint() - t);


	//# @WORD D+
		//# Add d1 to d2, leaving the sum d3.

	}//# @STACK ( d1 d2 - d3 )
	public void DPlus()
	{
		Forth.PushDint(Forth.PopDint() + Forth.PopDint());


	//# @WORD D<
		//# Return true if and only if d1 is less than d2.

	}//# @STACK ( d1 d2 - flag )
	public void DLessThan()
	{
		var t = Forth.PopDint();
		if(Forth.PopDint() < t)
		{
			Forth.Push(Forth.TRUE);
		}
		else
		{
			Forth.Push(Forth.FALSE);


	//# @WORD D=
			//# Return true if and only if d1 is equal to d2.

		}
	}//# @STACK ( d1 d2 - flag )
	public void DEquals()
	{
		var t = Forth.PopDint();
		if(Forth.PopDint() == t)
		{
			Forth.Push(Forth.TRUE);
		}
		else
		{
			Forth.Push(Forth.FALSE);


	//# @WORD D0<
			//# Return true if and only if the double precision value d is less than zero.

		}
	}//# @STACK ( d - flag )
	public void DZeroLess()
	{
		if(Forth.PopDint() < 0)
		{
			Forth.Push(Forth.TRUE);
		}
		else
		{
			Forth.Push(Forth.FALSE);


	//# @WORD D0=
			//# Return true if and only if the double precision value d is equal to zero.

		}
	}//# @STACK ( d - flag )
	public void DZeroEqual()
	{
		if(Forth.PopDint() == 0)
		{
			Forth.Push(Forth.TRUE);
		}
		else
		{
			Forth.Push(Forth.FALSE);


	//# @WORD D2*
			//# Multiply d1 by 2, leaving the result d2.

		}
	}//# @STACK ( d1 - d2 )
	public void DTwoStar()
	{
		Forth.SetDint(0, Forth.GetDint(0) * 2);


	//# @WORD D2/
		//# Divide d1 by 2, leaving the result d2.

	}//# @STACK ( d1 - d2 )
	public void DTwoSlash()
	{
		Forth.SetDint(0, Forth.GetDint(0) / 2);


	//# @WORD D>S
		//# Convert double to single, discarding MS cell.

	}//# @STACK ( d - n )
	public void DToS()
	{

		// this assumes doubles are pushed in LS MS order
		Forth.Pop();


	//# @WORD DABS
		//# Replace the top stack double item with its absolute value.

	}//# @STACK ( d - +d )
	public void DAbs()
	{
		Forth.SetDint(0, Mathf.Abs(Forth.GetDint(0)));


	//# @WORD DMAX
		//# Return d3, the greater of d1 and d2.

	}//# @STACK ( d1 d2 - d3 )
	public void DMax()
	{
		var d2 = Forth.PopDint();
		if(d2 > Forth.GetDint(0))
		{
			Forth.SetDint(0, d2);


	//# @WORD DMIN
			//# Return d3, the lesser of d1 and d2.

		}
	}//# @STACK ( d1 d2 - d3 )
	public void DMin()
	{
		var d2 = Forth.PopDint();
		if(d2 < Forth.GetDint(0))
		{
			Forth.SetDint(0, d2);


	//# @WORD DNEGATE
			//# Change the sign of the top stack value.

		}
	}//# @STACK ( d - -d )
	public void DNegate()
	{
		Forth.SetDint(0,  - Forth.GetDint(0));


	//# @WORD M*/
		//# Multiply d1 by n1 producing a triple cell intermediate result t.
		//# Divide t by n2, giving quotient d2.

	}//# @STACK ( d1 n1 +n2 - d2 )
	public void MStarSlash()
	{

		// Following is an *approximate* implementation, using the double float
		var n2 = Forth.Pop();
		var n1 = Forth.Pop();
		var d1 = Forth.PopDint();
		Forth.PushDint(Int((Float(d1) / n2) * n1));


	//# @WORD M+
		//# Add n to d1 leaving the sum d2.

	}//# @STACK ( d1 n - d2 )
	public void MPlus()
	{
		var n = Forth.Pop();
		Forth.PushDint(Forth.PopDint() * n);
	}


}
