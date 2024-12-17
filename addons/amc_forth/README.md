# AMC Forth

#### A C# based implementation of Chuck Moore's Forth computer language running inside the [Godot game engine](https://godotengine.org/).

AMC Forth is a C#-based implementation of Chuck Moore's Forth computer language, running inside the [Godot game engine](https://godotengine.org/). It was created to be the in-flight computer for the AMC SkyDart, a fictional spacecraft featured in [Tungsten Moon](https://store.steampowered.com/app/3104900/Tungsten_Moon/). Spun off into its own project on [Github](https://github.com/Eccentric-Anomalies/AMC-Forth), AMC Forth is available for public use under the generous [MIT License](https://github.com/Eccentric-Anomalies/AMC-Forth/blob/main/LICENSE).

## How to Use AMC Forth

AMC Forth is suited to inclusion in your Godot project using two Godot add-on paths: `addons/amc_forth`  for the Forth engine C# class, and `addons/amc_forth_terminal` which has a local DEC VT-100 subset script, `forth_term_local.gd`, and a simple telnet script, `forth_term_telnet.gd`. The local terminal implementation can be used together with a 2D canvas shader, `terminal_canvas.gdshader`, or a 3D shader, `terminal_3d.gdshader`, to reproduce the appearance of a VT-100 terminal screen. Example 2D and 3D terminal+Forth scenes are available at the root of the [Github repository for AMC Forth](https://github.com/Eccentric-Anomalies/AMC-Forth). Please refer to those examples when trying to use AMC Forth in your own 2D or 3D Godot project!

## AMCForth Word List

AMCForth currently implements an extensive set of [built-in words](./docs/builtins.md). Each word links to a page with a short description of what it does how it uses the Forth data stack. For debugging purposes, there is also a link to the C# class that implement's the word's functionality, as well as the values of its execution tokens for both interpreted and compiled contexts.

## AMCForth Test Suite

This repository also includes a [Forth test suite](./tests.fth) that can be [INCLUDE](./docs/Include.md)-ed to validate the correctness of the implementation. When executed, a successful run produces NO output to the terminal (i.e. prints "ok").

## The AMCForth Class (C#)

Steps to use the AMC Forth engine in your project:

Copy or import the `addons/amc_forth` and `addons/amc_forth_terminal` directories into your C# Godot project. You may use gdscript or C# with AMC Forth.

In your scene file, instantiate and initialize the AMCForth class from within _init() or equivalent:

```gdscript
var forth = AMCForth.new()
forth.Initialize(self)
```

Output from AMC Forth is handled through a signal named `TerminalOut`. Your code would include something like:

```gdscript
forth.TerminalOut.connect(_on_forth_output)
```

to connect the output withal to your own code, where `_on_forth_output` looks like:

```gdscript
func _on_forth_output(_text: String) -> void:
```

To send terminal commands to the Forth engine, call the `TerminalIn` method:
```gdsript
forth.TerminalIn(<your input string here>)
```

## AMCForth Input and Output

The AMC Forth engine mimics an abstract microcomputer, with memory-mapped I/O. By default, there are 128 32-bit input ports and 128 32-bit output ports. To use this, define your own input and output signals, e.g.:

```gdscript
signal my_output_signal(value: int)
signal my_input_signal(value: int)
```

### Configuring AMCForth Inputs

Before sending data to an AMCForth input port, connect the port to your signal:

```gdscript
# connect my_input_signal to input port 100
forth.AddInputSignal(100, my_input_signal)
```

Then when you have data to send to AMCForth, emit the signal:

```gdscript
my_input_signal.emit(<32-bit integer>)
```

In your Forth code, you can register input ports and route them to custom handlers using the custom AMC Forth word: [LISTEN](docs/Listen.md)

```forth
: PRINTEVENT . ;  ( define PRINTEVENT to just print an integer on the terminal.)
100 LISTEN PRINTEVENT   ( values sent to input #100 will print to the terminal.)
```

With this, every time you send an integer on `my_input_signal`, the value will be displayed on the AMC Forth terminal.

### Configuring AMCForth Outputs

Receiving data from AMCForth works in a similar fashion. First connect your signal to the output port:

```gdscript
# connect my_output_signal to output port 99
forth.AddOutputSignal(99, my_output_signal)
# and connect the signal to a gdscript handler function
my_output_signal.connect(my_signal_handler)
```

where `my_signal_handler` looks like this:

```gdscript
func my_signal_handler(value: int):
	print(value)   # something more interesting, perhaps?
```

Then when AMCForth code sends an integer to output port 99, the value is printed to the Godot console.

In your Forth code, you can send data to an output port using the custom AMC Forth word: [OUT](docs/Out.md) 

```forth
123 99 OUT  ( Sends the value 123 to port 99)
```

With this, every time you `OUT` a value to port 99 from inside AMCForth, it will print to the Godot console.

### Timers

AMCForth also includes custom words for creating and stopping periodic timers. For example, [P-TIMER](docs/PTimer.md) creates a periodic timer and associates it with a built-in or custom word:

```forth
: TICK S" tick" TYPE ;   ( a word that displays 'tick' to the Forth terminal.)
5 1000 P-TIMER TICK   ( Create timer with ID=5, that prints 'tick' once per second.)
```

To cancel a timer, use the custom word: [P-STOP](docs/PStop.md)

```forth
5 P-STOP  ( stops the timer with ID=5)
```

## Forth Terminals

### Local Terminal

The script `forth_term_local.gd` implements a local implementation of a VT-100 command subset, to use inside a Godot scene (see the example 2D and 3D scenes at the root of the [AMC Forth Github Repository](https://github.com/Eccentric-Anomalies/AMC-Forth)).

### Telnet Terminal

The script `forth_term_telnet.gd` implements a simple telnet server that should work seamlessly with the PuTTY telnet client.

Telnet and local terminals may be used by themselves, or together at the same time.