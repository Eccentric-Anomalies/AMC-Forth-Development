using Godot;

namespace Forth.Facility
{
[GlobalClass]
	public partial class Page : Forth.Words
	{

		public Page(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "PAGE";
			Description = "On a CRT, clear the screen and reset cursor position to the upper left corner.";
			StackEffect = "( - )";
		}

		public override void Call()
		{
			Forth.Util.PrintTerm(Terminal.CLRSCR);
			Forth.Push(1);
			Forth.CoreWords.Dup.Call();
			Forth.FacilityWords.AtXY.Call();
		}
	}
}