using Godot;
using Godot.Collections;

//# Base class and utilities for Forth word definition collections

//#


[GlobalClass]
public partial class ForthImplementationBase : Godot.RefCounted
{
	public AMCForth Forth;


	// Initialize 
	public virtual void Initialize(AMCForth _forth)
	{
		Forth = _forth;
		_ScanDefinitions();
	}


// Scan source code for Forth word definitions
	protected void _ScanDefinitions()
	{
		var src = GetScript().SourceCode;
		var regex = RegEx.New();

		// Identify the word set for this file
		var wordset = "N/A";
		regex.Compile("//\\s+@WORDSET\\s+(.+)\\n?\\r?");
		var res = regex.SearchAll(src);
		if(res.Size())
		{
			wordset = res[0].Strings[1];
		}

		// make an empty list of words for this wordset
		Forth.WordsetWords[wordset] = new Array{};

		// Compile built-in WORD functions
		regex.Compile("[^\"]//\\s+@WORD\\s+([^\\s]+)\\s*(IMMEDIATE)?\\s*\\n?\\r?(//[^\\r\\n]*)?\\n?\\r?(##[^\\r\\n]*)?\\n?\\r?(//[^\\r\\n]*)?\\n?\\r?//\\s+@STACK\\s+([^\\r\\n]*)?\\n?\\r?func\\s+([^\\s(]+)");
		res = regex.SearchAll(src);
		GD.Print(res.Size(), " words found in ", wordset);
		foreach(Variant item in res)
		{
			var word = item.Strings[1];

			// associate word with executable


			Forth.BuiltInNames.Append(new Array{word, new Callable(this, item.Strings[7]), });

			// identify immediate words
			if(item.Strings[2] == "IMMEDIATE")
			{
				Forth.ImmediateNames.Append(item.Strings[1]);
			}

		// associate words with their description
			var descr = "";
			foreach(Variant i in new Array{3, 4, 5, })
			{
				var item_str = item.Strings[i];
				item_str = item_str.Replace("##", "").Lstrip(" ").Rstrip(" ") + " ";
				descr = descr + item_str;
			}
			descr = descr.Rstrip(" ");
			Forth.WordDescription[word] = descr;

			// associate words with their word set
			Forth.WordWordset[word] = wordset;

			// associate words their stack definitions
			Forth.WordStackdef[word] = item.Strings[6].Replace("##", "").Lstrip(" ").Rstrip(" ");

			// associate wordset with this word
			Forth.WordsetWords[wordset].Append(word);
		}

	// sort the wordset list
		Forth.WordsetWords[wordset].Sort();

		// Compile built-in WORDX run-time execution functions
		regex.Compile("[^\"]//\\s+@WORDX\\s+([^\\s]+).*\\n?\\r?func\\s+([^\\s(]+)");
		res = regex.SearchAll(src);
		foreach(Variant item in res)
		{
			Forth.BuiltInExecFunctions.Append(new Array{item.Strings[1], new Callable(this, item.Strings[2]), });
		}
	}

}
