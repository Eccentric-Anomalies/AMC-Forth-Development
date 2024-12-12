using Godot;

namespace Forth.Double
{
[GlobalClass]
	public partial class DNegate : Forth.Words
	{

		public DNegate(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "DNEGATE";
			Description = "Change the sign of the top stack value.";
			StackEffect = "( d - -d )";
		}

		public override void Call()
		{
			Forth.SetDint(0,  - Forth.GetDint(0));
		}
	}
}