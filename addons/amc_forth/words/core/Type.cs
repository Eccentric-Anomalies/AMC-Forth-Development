using Godot;

namespace Forth.Core
{
[GlobalClass]
	public partial class Type : Forth.Words
	{

		public Type(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "TYPE";
			Description = "Output the character string at c-addr, length u.";
			StackEffect = "( c-addr u - )";
		}

		public override void Call()
		{
			var l = Forth.Pop();
			var s = Forth.Pop();
			for (int i = 0; i < l; i++)
			{
				Forth.Push(Forth.Ram.GetByte(s + i));
				Forth.CoreWords.Emit.Call();
			}
		}
	}
}