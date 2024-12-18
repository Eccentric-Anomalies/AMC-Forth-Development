# LISTEN &emsp; (Listen)
Add a lookup entry for the IO port p, to execute 'word'. Events to port p are enqueued with q mode (0, 1, 2), where q = enqueue: 0 - always, 1 - if new value, 2 - replace all prior. Note: An input port may have only one handler word.
* ( 'word' p q - )
* [Source Code](../words/amc_ext/Listen.cs)
* Execution Tokens: 1585382228 (interpreted) and 1048511316 (compiled)


[BACK](builtins.md#Listen)
