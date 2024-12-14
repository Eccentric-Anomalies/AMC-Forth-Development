using Godot;

namespace Forth.File
{
    [GlobalClass]
    public partial class IncludeFile : Forth.Words
    {
        public IncludeFile(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "INCLUDE-FILE";
            Description =
                "Read and interpret the given file. Save the current input "
                + "source specification, store the fileid in SOURCE-ID and "
                + "make this file the input source. Read and interpret lines until EOF.";
            StackEffect = "( fileid - )";
        }

        public override void Call()
        {
            var flag = AMCForth.True;
            var u2 = 0;
            var ior = 0;
            var fileid = Forth.Pop();
            Forth.SourceIdStack.Push(Forth.SourceId); // save the current source
            Forth.SourceId = fileid; // new source id
            var buff_data = fileid + AMCForth.FileBuffDataOffset; // address of data buffer
            var buff_size = AMCForth.FileBuffDataSize;
            while ((ior == 0) && (flag == AMCForth.True))
            {
                Forth.Ram.SetInt(fileid + AMCForth.FileBuffPtrOffset, 0); // clear the buffer pointer
                Forth.Push(buff_data);
                Forth.Push(buff_size);
                Forth.Push(fileid);
                Forth.FileWords.ReadLine.Call();
                ior = Forth.Pop();
                flag = Forth.Pop();
                u2 = Forth.Pop();
                if (u2 != 0) // process the line read, if any
                {
                    Forth.Push(buff_data);
                    Forth.Push(u2);
                    Forth.CoreWords.Evaluate.Call();
                }
            }
            Forth.SourceId = Forth.SourceIdStack.Pop(); // restore the previous source
            Forth.Push(fileid); // close the file
            Forth.FileWords.CloseFile.Call();
            Forth.Pop();
        }
    }
}
