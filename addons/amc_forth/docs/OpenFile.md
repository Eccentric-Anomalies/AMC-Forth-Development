# OPEN-FILE &emsp; (OpenFile)
Open the file whose name is given by c-addr of length u, using file access method fam. On success, return ior of zero and a fileid, otherwise return non-zero ior and undefined fileid. Check user:// first, then res://.
* (c-addr u fam - fileid ior )
* [Source Code](../words/file/OpenFile.cs)
* Execution Tokens: 1372627748 (interpreted) and 835756836 (compiled)


[BACK](builtins.md#OpenFile)
