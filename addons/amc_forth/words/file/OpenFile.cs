using Godot;

namespace Forth.File
{
[GlobalClass]
	public partial class OpenFile : Forth.Words
	{

		public OpenFile(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "OPEN-FILE";
			Description = 
				"Open the file whose name is given by c-addr of length u, using file "+
				"access method fam. On success, return ior of zero and a fileid, otherwise "+
				"return non-zero ior and undefined fileid. Check user:// first, then res://.";
			StackEffect = "(c-addr u fam - fileid ior )";
		}

		public override void Call()
		{
			var ior =  - 1;
			var fam = Forth.Pop();
			var u = Forth.Pop();
			var fileid = 0;
			var fname = Forth.Util.StrFromAddrN(Forth.Pop(), u);
			var file = FileAccess.Open("user://" + fname, (FileAccess.ModeFlags) fam);
			file ??= FileAccess.Open("res://" + fname, (FileAccess.ModeFlags) fam);
			if(file != null)
			{
				fileid = Forth.AssignFileId(file, fam);
				if(fileid != 0)
				{
					ior = 0;
				}
				else
				{
					Forth.Util.RprintTerm("File buffers exhausted");	// failed to allocate a buffer
				}
			}
			Forth.Push(fileid);
			Forth.Push(ior);
		}
	}
}