using System.ComponentModel;
using Godot;

namespace Forth.Core
{
[GlobalClass]
	public partial class Align : Forth.WordBase
	{


		public Align(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "ALIGN";
			Description = "If the data-space pointer is not aligned, reserve space to align it.";
			StackEffect = "( - )";
		}

		public override void Execute()
		{
			Forth.Push(Forth.DictTop);
			Forth.FCore.Aligned.Execute();
			Forth.DictTop = Forth.Pop();

			// preserve dictionary state
			Forth.SaveDictTop();
		}
	}
}