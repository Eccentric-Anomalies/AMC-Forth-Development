using Godot;

namespace Forth.Core
{
[GlobalClass]
	public partial class XXXX : Forth.Words
	{

		public XXXX(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "XXXX";
			Description = "XXXX";
			StackEffect = "( - )";
		}

		public override void Call()
		{
		}
	}
}