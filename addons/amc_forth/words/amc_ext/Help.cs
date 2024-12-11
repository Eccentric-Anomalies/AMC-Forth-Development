using System;
using Godot;

namespace Forth.AMCExt
{
[GlobalClass]
	public partial class Help : Forth.Words
	{

		public Help(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "HELP";
			Description = "Display the description for the following Forth built-in word.";
			StackEffect = "( 'name' - )";
		}

		public override void Call()
		{
			try {
				Forth.Util.PrintTerm(" " + FromName(NextWord()).Description);
			}
			catch (ArgumentOutOfRangeException e) {
				Forth.Util.PrintUnknownWord(e.ParamName);
			}
		}

		public string NextWord()
		{
			// retrieve the name token
			Forth.CoreExtWords.ParseName.Call();
			var len = Forth.Pop();
			// length
			var caddr = Forth.Pop();
			// start
			return Forth.Util.StrFromAddrN(caddr, len);
		}

	}
}