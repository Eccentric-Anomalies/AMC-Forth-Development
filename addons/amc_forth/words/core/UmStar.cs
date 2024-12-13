using Godot;

namespace Forth.Core
{
[GlobalClass]
	public partial class UmStar : Forth.Words
	{

		public UmStar(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "UM*";
			Description = 
				"Multiply u1 by u2, leaving the double-precision result ud.";
			StackEffect = "( u1 u2 - ud )";
		}

		public override void Call()
		{
			Forth.PushDword((ulong) Forth.Pop() * (ulong) Forth.Pop());
		}
	}
}