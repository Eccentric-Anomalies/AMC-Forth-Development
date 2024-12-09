using Godot;

namespace Forth.Core
{
[GlobalClass]
	public partial class Execute : Forth.Words
	{

		public Execute(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "EXECUTE";
			Description = "Remove execution token xt from the stack and perform the execution behavior it identifies.";
			StackEffect = "( xt - )";
		}

		public override void Call()
		{
			var xt = Forth.Pop();
			if(IsBuiltInXt(xt))
			{
				// this xt identifies a built-in function
				CallXt(xt);
			}
			else if(xt >= AMCForth.DictStart && xt < AMCForth.DictTop)
			{
				// this xt (probably) identifies an address in the dictionary
				// save the current ip
				Forth.PushIp();
				// this is a physical address of an xt
				Forth.DictIp = xt;
				// push the xt
				Forth.Push(Forth.Ram.GetInt(xt));
				// recurse down a layer
				Call();
				// restore our ip
				Forth.PopIp();
			}
			else
			{
				Forth.Util.RprintTerm(" Invalid execution token (EXECUTE)");
			}
		}
	}
}