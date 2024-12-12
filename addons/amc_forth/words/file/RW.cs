using Godot;

namespace Forth.File
{
[GlobalClass]
	public partial class RW : Forth.Words
	{

		public RW(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "R/W";
			Description = "Return the read-write file access method.";
			StackEffect = "( - fam )";
		}

		public override void Call()
		{
			Forth.Push((int) FileAccess.ModeFlags.ReadWrite);
		}
	}
}