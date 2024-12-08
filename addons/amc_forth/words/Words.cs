using System;
using System.Collections.Generic;
using Godot;
// Base class and utilities for Forth word definition

namespace Forth
{

	[GlobalClass]
	public partial class Words : Godot.RefCounted
	{
		public AMCForth Forth;
		public bool Immediate;
		public string Name
		{
			get => _name;
			set
			{
				_nameDict[value] = this;  // associate <Forth Word> to its C# instance
				_name = value;
				AssignXt();	// requires name to be set, sets Xt and XtX
				_xtDict[Xt] = this;		// associate Xt and XtX with their C# instance
				_xtDict[XtX] = this;
			}
		}
		public string Description;
		public string StackEffect;
		public string WordSet;
		public int Xt;	// built-in execution token
		public int XtX;	// built-in compiled execution token

		private string _name; 
		static Dictionary<string, Words> _nameDict = new();
		static Dictionary<int, Words> _xtDict = new();
        public Words(AMCForth forth, string wordset)
        {
            Forth = forth;
			Immediate = false;
			WordSet = wordset;
        }

        public virtual void Call()
		{
		}

		public virtual void CallExec()
		{
		}

		private void AssignXt()
		{
			Xt = (int) (AMCForth.BuiltInXtMask + (AMCForth.BuiltInMask & _name.Hash()));
			XtX = (int) (AMCForth.BuiltInXtXMask + (AMCForth.BuiltInMask & _name.Hash()));
			if (_xtDict.ContainsKey(Xt) || _xtDict.ContainsKey(XtX))
			{
				throw new InvalidOperationException("Duplicate Forth word was defined (hash collision): (" + _name + ")");
			}
		}

		public static Words FromName(string name)
		{
			if (_nameDict.ContainsKey(name))
			{
				return _nameDict[name];
			}
			else
			{
				throw new ArgumentOutOfRangeException(name, "Name is not recognized as a Forth built-in.");
			}
		}

		public static Words FromXt(int xt)
		{
			if (_xtDict.ContainsKey(xt))
			{
				return _xtDict[xt];
			}
			else
			{
				throw new ArgumentOutOfRangeException(xt.ToString(), "Unrecognized Built-In Execution Token");
			}
		}

		public static void CallXt(int xt)
		{
			var word = FromXt(xt);
			if ((xt & AMCForth.BuiltInXtMask) != 0)
			{
				word.Call();
			}
			else
			{
				word.CallExec();
			}
		}

	}
}