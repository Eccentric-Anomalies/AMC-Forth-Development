using System;
using Godot;

namespace Forth.Core
{
[GlobalClass]
	public partial class Emit : Forth.Words
	{

		public Emit(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "EMIT";
			Description = "Output one character from the LS byte of the top item on stack.";
			StackEffect = "( b - )";
		}

		public override void Call()
		{
			byte[] c = {Convert.ToByte(Forth.Pop() & 0x0ff)};
			Forth.Util.PrintTerm(System.Text.Encoding.ASCII.GetString(c));
		}
	}
}