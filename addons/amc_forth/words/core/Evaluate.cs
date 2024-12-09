using Godot;

namespace Forth.Core
{
[GlobalClass]
	public partial class Evaluate : Forth.Words
	{

		public Evaluate(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "EVALUATE";
			Description = "Use c-addr, u as the buffer start and interpret as Forth source.";
			StackEffect = "( i*x c-addr u - j*x )";
		}

		public override void Call()
		{
			// we can discard the buffer location, since we use the source_id
			// to identify the buffer
			Forth.Pop();
			Forth.Pop();

			// buffer pointer is based on source-id
			Forth.ResetBuffToIn();
			while(true)
			{
				Forth.CoreExtWords.ParseName.Call();
				var len = Forth.Pop(); // length of word
				var caddr = Forth.Pop(); // start of word
				if(len == 0)	// out of tokens?
				{
					break;
				}
				var t = Forth.Util.StrFromAddrN(caddr, len);
				// t should be the next token, try to get an execution token from it
				var xt_immediate = Forth.FindInDict(t);
				if((xt_immediate.Addr == 0) && HasName(t.ToUpper()))
				{
					xt_immediate = new AMCForth.DictResult(FromName(t).Xt, false);
				}
				if(xt_immediate.Addr != 0) // an execution token exists
				{
					Forth.Push(xt_immediate.Addr);
					// check if it is a built-in immediate or dictionary immediate before storing
					if(Forth.State && !(FromName(t).Immediate || xt_immediate.IsImmediate))
					{
						// Compiling
						Forth.CoreWords.Comma.Call();
					}
					// store at the top of the current : definition
					else
					{
						// Not Compiling or immediate - just execute
						Forth.CoreWords.Execute.Call();
					}
				}
				else	// no valid token, so maybe valid numeric value (double first)
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
				}

			}
		}
	}
}