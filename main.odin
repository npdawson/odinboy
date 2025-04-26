package odinboy

import "core:fmt"

Registers :: struct {
	using _: struct #raw_union {
		using _: struct {
			f: u8,
			a: u8,
		},
		af: u16,
	},
	using _: struct #raw_union {
		using _: struct {
			c: u8,
			b: u8,
		},
		bc: u16,
	},
	using _: struct #raw_union {
		using _: struct {
			e: u8,
			d: u8,
		},
		de: u16,
	},
	using _: struct #raw_union {
		using _: struct {
			l: u8,
			h: u8,
		},
		hl: u16,
	},
	sp: u16,
	pc: u16,
	flags: Flags
}

Flag :: enum {
	_,
	_,
	_,
	_,
	C,
	H,
	N,
	Z,
}

Flags :: bit_set[Flag]

main :: proc() {
	regs: Registers
	regs.af = 0xabcd
	fmt.printfln("A: %02x, F: %02x", regs.a, regs.f)
}
