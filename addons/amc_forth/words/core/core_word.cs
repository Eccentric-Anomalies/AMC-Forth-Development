using Godot;

namespace Forth.Core
{
[GlobalClass]
	public partial class Word : Forth.WordBase
	{

		public Word(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "WORD";
			Description = 
				"Skip leading occurrences of the delimiter char. Parse text delimited by" +
				" char. Return the address of a temporary location containing the passed text as a" +
				" counted string.";
			StackEffect = "( char - c-addr )";
		}

		public override void Execute()
		{
			Dup();
			var delim = Forth.Pop();
			Source();
			var source_size = Forth.Pop();
			var source_start = Forth.Pop();
			ToIn();
			var ptraddr = Forth.Pop();
			while(true)
			{


				var t = Forth.Ram.GetByte(source_start + Forth.Ram.GetInt(ptraddr));
				if(t == delim)
				{

					// increment the input pointer
					Forth.Ram.SetInt(ptraddr, Forth.Ram.GetInt(ptraddr) + 1);
				}
				else
				{
					break;
				}
			}
			Forth.CoreExt.Parse();
			var count = Forth.Pop();
			var straddr = Forth.Pop();
			var ret = straddr - 1;
			Forth.Ram.SetByte(ret, count);
			Forth.Push(ret);
		}
	}
}