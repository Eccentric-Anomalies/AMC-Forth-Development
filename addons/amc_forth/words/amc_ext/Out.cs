using Godot;

namespace Forth.AMCExt
{
[GlobalClass]
	public partial class Out : Forth.Words
	{

		public Out(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "OUT";
			Description = "Save value x to I/O port p, possibly triggering Godot signal.";
			StackEffect = "( x p - )";
		}

		public override void Call()
		{
			Forth.CoreWords.Dup.Call();
			var port = Forth.Pop();
			Forth.CoreWords.Cells.Call();
			// offset in bytes
			Forth.Push(AMCForth.IoOutStart);
			// address of output block
			Forth.CoreWords.Plus.Call();
			// output address
			Forth.CoreWords.Over.Call();
			// copy value
			var value = Forth.Pop();
			Forth.CoreWords.Store.Call();
			if(Forth.OutputPortMap.ContainsKey(port))
			{
				var sig = Forth.OutputPortMap[port];
				CallDeferred("OutputEmitter", port, value);
			}
		}

		public void OutputEmitter(int port, int value)
		{
			EmitSignal(Forth.OutputPortMap[port], value);
		}
	}
}