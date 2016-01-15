# KaRouter
Modular VHDL Routing/Switching solution

This projects goal is to write a modular router tool-kit in VHDL2008. Submodules like queues, classifiers and schedulers communicate using a small internal protocol making them more autonomous and easy to reason about.
The classifier is currently most advanced and supports range, ternary-value and normal CAMs. Simple factory functions for generating the generics are provided.

Currently very much VIP. The classifier components already work very well and have unit tests.