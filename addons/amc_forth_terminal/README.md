# AMC Forth Terminals

This sub-project includes ready-to-use scripts for attaching a local or telnet terminal to your AMCForth instance.

## Local Terminal

The script `forth_term_local.gd` implements a local implementation of a VT-100 command subset, to use inside a Godot scene (see the example 2D and 3D scenes at the root of the [AMC Forth Github Repository](https://github.com/Eccentric-Anomalies/AMC-Forth)).

## Telnet Terminal

The script `forth_term_telnet.gd` implements a simple telnet server that should work seamlessly with the PuTTY telnet client.

Telnet and local terminals may be used by themselves, or together at the same time.