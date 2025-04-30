package odinboy

import "core:fmt"
import "core:log"

Instruction :: struct {
	disassembly: string,
	length:      byte, // number of operand bytes
	cycles:      byte,
	jump_cycles: byte, // number of cycles if jump/call is taken
	function:    proc(^Instruction, ^Gameboy),
	reg:		 Reg,
}

Reg :: enum {
	None,
	A,
	B,
	C,
	D,
	E,
	H,
	L,
	AF,
	BC,
	DE,
	HL,
	SP,
}

instructions: [256]Instruction = {
	{"NOP", 1, 1, 0, nop, .None},				// 0x00
	{"LD BC, Ox%04x", 3, 3, 0, ld_reg_d16, .BC},
	{"LD (BC), A", 1, 2, 0, ld_mem_a, .BC},
	{"INC BC", 1, 2, 0, inc, .BC},
	{"INC B", 1, 1, 0, inc, .B},
	{"DEC B", 1, 1, 0, dec, .B},
	{"LD B, %02x", 2, 2, 0, ld_reg_d8, .B},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"DEC BC", 1, 2, 0, dec, .BC},
	{"INC C", 1, 1, 0, inc, .C},
	{"DEC C", 1, 1, 0, dec, .C},
	{"LD C, %02x", 2, 2, 0, ld_reg_d8, .C},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},					// 0x10
	{"LD DE, %04x", 3, 3, 0, ld_reg_d16, .DE},
	{"", 0, 0, 0, nil, .None},
	{"INC DE", 1, 2, 0, inc, .DE},
	{"INC D", 1, 1, 0, inc, .D},
	{"DEC D", 1, 1, 0, dec, .D},
	{"LD D, %02x", 2, 2, 0, ld_reg_d8, .D},
	{"RLA", 1, 1, 0, rl, .A},
	{"JR %02x", 2, 3, 0, jr_r8, .None},
	{"", 0, 0, 0, nil, .None},
	{"LD A, (DE)", 1, 2, 0, ld_a_mem, .DE},
	{"", 0, 0, 0, nil, .None},
	{"INC E", 1, 1, 0, inc, .E},
	{"DEC E", 1, 1, 0, dec, .E},
	{"LD E, %02x", 2, 2, 0, ld_reg_d8, .E},
	{"", 0, 0, 0, nil, .None},
	{"JR NZ, %02x", 2, 2, 3, jr_nz_r8, .None},	// 0x20
	{"LD HL, %04x", 3, 3, 0, ld_reg_d16, .HL},
	{"LD (HL+), A", 1, 2, 0, ld_hl_inc, .None},
	{"INC HL", 1, 2, 0, inc, .HL},
	{"INC H", 1, 1, 0, inc, .H},
	{"DEC H", 1, 1, 0, dec, .H},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"JR Z, %02x", 2, 2, 3, jr_z_r8, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"INC L", 1, 1, 0, nil, .L},
	{"DEC L", 1, 1, 0, nil, .L},
	{"LD L, %02x", 2, 2, 0, ld_reg_d8, .L},
	{"", 0, 0, 0, nil, .None},
	{"JR NC, %02x", 2, 2, 3, nil, .None},					// 0x30
	{"LD SP, %04x", 3, 3, 0, ld_reg_d16, .SP},
	{"LD (HL-), A", 1, 2, 0, ld_hl_dec, .None},
	{"INC SP", 1, 1, 0, inc, .SP},
	{"INC (HL)", 1, 3, 0, nil, .None},
	{"DEC (HL)", 1, 3, 0, nil, .None},
	{"LD (HL), %02x", 2, 3, 0, ld_mem_d8, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"DEC A", 1, 1, 0, dec, .A},
	{"LD A, %02x", 2, 2, 0, ld_reg_d8, .A},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},		// 0x40
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"LD B, A", 1, 1, 0, ld_reg_a, .B},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"LD C, A", 1, 1, 0, ld_reg_a, .C},
	{"", 0, 0, 0, nil, .None},		// 0x50
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"LD D, A", 1, 1, 0, ld_reg_a, .D},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},		// 0x60
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"LD H, A", 1, 1, 0, ld_reg_a, .H},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},		// 0x70
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"LD (HL), A", 1, 2, 0, ld_mem, .A},
	{"LD A, B", 1, 1, 0, ld_reg_b, .A},
	{"LD A, C", 1, 1, 0, ld_reg_c, .A},
	{"LD A, D", 1, 1, 0, ld_reg_d, .A},
	{"LD A, E", 1, 1, 0, ld_reg_e, .A},
	{"LD A, H", 1, 1, 0, ld_reg_h, .A},
	{"LD A, L", 1, 1, 0, ld_reg_l, .A},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},		// 0x80
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"ADD A, (HL)", 1, 2, 0, add_mem, .None},
	{"ADD A, A", 1, 1, 0, add, .A},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"SUB A, B", 1, 1, 0, sub, .B},		// 0x90
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},		// 0xa0
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"AND A, A", 1, 1, 0, and, .A},
	{"XOR A, B", 1, 1, 0, xor, .B},
	{"XOR A, C", 1, 1, 0, xor, .C},
	{"XOR A, D", 1, 1, 0, xor, .D},
	{"XOR A, E", 1, 1, 0, xor, .E},
	{"XOR A, H", 1, 1, 0, xor, .H},
	{"XOR A, L", 1, 1, 0, xor, .L},
	{"", 0, 0, 0, nil, .None},
	{"XOR A", 1, 1, 0, xor, .A},
	{"", 0, 0, 0, nil, .None},		// 0xb0
	{"OR A, C", 1, 1, 0, or, .C},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"CP A, (HL)", 1, 2, 0, cp_mem, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},		// 0xc0
	{"POP BC", 1, 3, 0, pop, .BC},
	{"", 0, 0, 0, nil, .None},
	{"JP %04x", 3, 4, 0, jp, .None},
	{"", 0, 0, 0, nil, .None},
	{"PUSH BC", 1, 4, 0, push, .BC},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"RET", 1, 4, 0, ret, .None},
	{"", 0, 0, 0, nil, .None},
	{"CB", 1, 1, 0, cb, .None},
	{"", 0, 0, 0, nil, .None},
	{"Call %04x", 3, 6, 0, call, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},		// 0xd0
	{"POP DE", 1, 3, 0, pop, .DE},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"PUSH DE", 1, 4, 0, push, .DE},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"LD (FF00+%02x), A", 2, 3, 0, ld_ff_d8_a, .None},		// 0xe0
	{"POP HL", 1, 3, 0, pop, .HL},
	{"LD (FF00+C), A", 1, 2, 0, ld_ff_c_a, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"PUSH HL", 1, 4, 0, push, .HL},
	{"AND A, %02x", 2, 2, 0, and_d8, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"LD (%04x), A", 3, 4, 0, ld_d16_a, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"LD A, (FF00+%02x)", 2, 3, 0, ld_a_ff_d8, .None},		// 0xf0
	{"POP AF", 1, 3, 0, pop, .AF},
	{"", 0, 0, 0, nil, .None},
	{"DI", 1, 1, 0, di, .None},
	{"", 0, 0, 0, nil, .None},
	{"PUSH AF", 1, 4, 0, push, .AF},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"EI", 1, 1, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"", 0, 0, 0, nil, .None},
	{"CP A, %02x", 2, 2, 0, cp_d8, .None},
	{"", 0, 0, 0, nil, .None},
}

cb_instructions := [256]Instruction {
	{"", 2, 2, 0, nil, .None}, // 0x00
	{"", 2, 2, 0, nil, .None},
	{"", 2, 2, 0, nil, .None},
	{"", 2, 2, 0, nil, .None},
	{"", 2, 2, 0, nil, .None},
	{"", 2, 2, 0, nil, .None},
	{"", 2, 2, 0, nil, .None},
	{"", 2, 2, 0, nil, .None},
	{"", 2, 2, 0, nil, .None},
	{"", 2, 2, 0, nil, .None},
	{"", 2, 2, 0, nil, .None},
	{"", 2, 2, 0, nil, .None},
	{"", 2, 2, 0, nil, .None},
	{"", 2, 2, 0, nil, .None},
	{"", 2, 2, 0, nil, .None},
	{"", 2, 2, 0, nil, .None},
	{"RL B", 2, 2, 0, rl, .B}, // 0x10
	{"RL C", 2, 2, 0, rl, .C},
	{"RL D", 2, 2, 0, rl, .D},
	{"RL E", 2, 2, 0, rl, .E},
	{"RL H", 2, 2, 0, rl, .H},
	{"RL L", 2, 2, 0, rl, .L},
	{"RL (HL)", 2, 4, 0, nil, .None},
	{"RL A", 2, 0, 0, rl, .A},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None}, // 0x20
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None}, // 0x30
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None}, // 0x40
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None}, // 0x50
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None}, // 0x60
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None}, // 0x70
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"BIT 7,H", 2, 2, 0, bit_7, .H},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None}, // 0x80
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"RES 0, A", 2, 2, 0, res_0, .A},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None}, // 0x90
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None}, // 0xa0
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None}, // 0xb0
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None}, // 0xc0
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None}, // 0xd0
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None}, // 0xe0
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None}, // 0xf0
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
	{"", 2, 0, 0, nil, .None},
}

nop :: proc(instr: ^Instruction, gb: ^Gameboy) {
	gb.cpu.registers.pc += u16(instr.length)
	gb.cpu.cycles += uint(instr.cycles)
}

ld_reg_d16 :: proc(instr: ^Instruction, gb: ^Gameboy) {
	addr := gb.cpu.registers.pc + 1
	data := read_word(gb, addr)
	write_reg16(gb, instr.reg, data)
	gb.cpu.registers.pc += u16(instr.length)
	gb.cpu.cycles += uint(instr.cycles)
}

ld_a_mem :: proc(instr: ^Instruction, gb: ^Gameboy) {
	addr := read_reg16(gb, instr.reg)
	data := read_byte(gb, addr)
	gb.cpu.registers.a = data
	gb.cpu.registers.pc += u16(instr.length)
	gb.cpu.cycles += uint(instr.cycles)
}

rl :: proc(instr: ^Instruction, gb: ^Gameboy) {
	data := read_reg8(gb, instr.reg)
	c := data & 0x80 != 0
	data = data << 1
	if .C in gb.cpu.registers.flags { data += 1 }
	write_reg8(gb, instr.reg, data)
	if data == 0 { gb.cpu.registers.flags += { .Z } }
	gb.cpu.registers.flags -= { .N, .H }
	if c {
		gb.cpu.registers.flags += { .C }
	} else {
		gb.cpu.registers.flags -= { .C }
	}
	gb.cpu.registers.pc += u16(instr.length)
	gb.cpu.cycles += uint(instr.cycles)
}

ld_mem_a :: proc(instr: ^Instruction, gb: ^Gameboy) {
	addr := read_reg16(gb, instr.reg)
	data := read_reg8(gb, .A)
	write_byte(gb, addr, data)
	gb.cpu.registers.pc += u16(instr.length)
	gb.cpu.cycles += uint(instr.cycles)
}

ld_d16_a :: proc(instr: ^Instruction, gb: ^Gameboy) {
	addr := read_word(gb, gb.cpu.registers.pc + 1)
	data := read_reg8(gb, .A)
	write_byte(gb, addr, data)
	gb.cpu.registers.pc += u16(instr.length)
	gb.cpu.cycles += uint(instr.cycles)
}

ld_mem :: proc(instr: ^Instruction, gb: ^Gameboy) {
	addr := gb.cpu.registers.hl
	data := read_reg8(gb, instr.reg)
	write_byte(gb, addr, data)
	gb.cpu.registers.pc += u16(instr.length)
	gb.cpu.cycles += uint(instr.cycles)
}

ld_mem_d8 :: proc(instr: ^Instruction, gb: ^Gameboy) {
	addr := gb.cpu.registers.hl
	data := read_byte(gb, gb.cpu.registers.pc + 1)
	write_byte(gb, addr, data)
	gb.cpu.registers.pc += u16(instr.length)
	gb.cpu.cycles += uint(instr.cycles)
}

push :: proc(instr: ^Instruction, gb: ^Gameboy) {
	data := read_reg16(gb, instr.reg)
	write_stack_word(gb, data)
	gb.cpu.registers.pc += u16(instr.length)
	gb.cpu.cycles += uint(instr.cycles)
}

pop :: proc(instr: ^Instruction, gb: ^Gameboy) {
	data := read_stack_word(gb)
	write_reg16(gb, instr.reg, data)
	gb.cpu.registers.pc += u16(instr.length)
	gb.cpu.cycles += uint(instr.cycles)
}

call :: proc(instr: ^Instruction, gb: ^Gameboy) {
	addr := read_word(gb, gb.cpu.registers.pc + 1)
	gb.cpu.registers.pc += u16(instr.length)
	write_stack_word(gb, gb.cpu.registers.pc)
	gb.cpu.registers.pc = addr
	gb.cpu.cycles += uint(instr.cycles)
}

ret :: proc(instr: ^Instruction, gb: ^Gameboy) {
	addr := read_stack_word(gb)
	gb.cpu.registers.pc = addr
	gb.cpu.cycles += uint(instr.cycles)
}

read_stack_word :: proc(gb: ^Gameboy) -> u16 {
	data := read_word(gb, gb.cpu.registers.sp+1)
	gb.cpu.registers.sp += 2
	return data
}

write_stack_byte :: proc(gb: ^Gameboy, data: u8) {
	write_byte(gb, gb.cpu.registers.sp, data)
	gb.cpu.registers.sp -= 1
}

write_stack_word :: proc(gb: ^Gameboy, data: u16) {
	write_stack_byte(gb, u8(data >> 8))
	write_stack_byte(gb, u8(data & 0xff))
}

and_d8 :: proc(instr: ^Instruction, gb: ^Gameboy) {
	data := read_byte(gb, gb.cpu.registers.pc + 1)
	gb.cpu.registers.a &= data
	gb.cpu.registers.flags = { .H }
	if gb.cpu.registers.a == 0 { gb.cpu.registers.flags += { .Z } }
	gb.cpu.registers.pc += u16(instr.length)
	gb.cpu.cycles += uint(instr.cycles)
}

and :: proc(instr: ^Instruction, gb: ^Gameboy) {
	data := read_reg8(gb, instr.reg)
	gb.cpu.registers.a &= data
	gb.cpu.registers.flags = { .H }
	if gb.cpu.registers.a == 0 { gb.cpu.registers.flags += { .Z } }
	gb.cpu.registers.pc += u16(instr.length)
	gb.cpu.cycles += uint(instr.cycles)
}

or :: proc(instr: ^Instruction, gb: ^Gameboy) {
	data := read_reg8(gb, instr.reg)
	gb.cpu.registers.a |= data
	gb.cpu.registers.flags = gb.cpu.registers.a == 0 ? { .Z } : {}
	gb.cpu.registers.pc += u16(instr.length)
	gb.cpu.cycles += uint(instr.cycles)
}

xor :: proc(instr: ^Instruction, gb: ^Gameboy) {
	data := read_reg8(gb, instr.reg)
	gb.cpu.registers.a ~= data
	gb.cpu.registers.flags = gb.cpu.registers.a == 0 ? { .Z } : {}
	gb.cpu.registers.pc += u16(instr.length)
	gb.cpu.cycles += uint(instr.cycles)
}

ld_hl_inc :: proc(instr: ^Instruction, gb: ^Gameboy) {
	addr := gb.cpu.registers.hl
	gb.cpu.registers.hl += 1
	write_byte(gb, addr, gb.cpu.registers.a)
	gb.cpu.registers.pc += u16(instr.length)
	gb.cpu.cycles += uint(instr.cycles)
}

ld_hl_dec :: proc(instr: ^Instruction, gb: ^Gameboy) {
	addr := gb.cpu.registers.hl
	gb.cpu.registers.hl -= 1
	write_byte(gb, addr, gb.cpu.registers.a)
	gb.cpu.registers.pc += u16(instr.length)
	gb.cpu.cycles += uint(instr.cycles)
}

cb :: proc(instr: ^Instruction, gb: ^Gameboy) {
}

bit_7 :: proc(instr: ^Instruction, gb: ^Gameboy) {
	data := read_reg8(gb, instr.reg)
	z := data & 0x80 == 0
	c := .C in gb.cpu.registers.flags
	flags: Flags = { .H }
	if z { flags += { .Z } }
	if c { flags += { .C } }
	gb.cpu.registers.flags = flags
	gb.cpu.registers.pc += u16(instr.length)
	gb.cpu.cycles += uint(instr.cycles)
}

inc :: proc(instr: ^Instruction, gb: ^Gameboy) {
	data: u16
	h: bool
	switch instr.reg {
	case .A, .B, .C, .D, .E, .H, .L:
		data = u16(read_reg8(gb, instr.reg))
		nibble := data & 0xf0
		data += 1
		h = data & 0xf0 != nibble
		write_reg8(gb, instr.reg, u8(data))
	case .BC, .DE, .HL, .SP:
		data = read_reg16(gb, instr.reg)
		nibble := data & 0xf000
		data += 1
		h = data & 0xf000 != nibble
		write_reg16(gb, instr.reg, data)
	case .AF:
		panic("tried to inc AF, no such instruction")
	case .None:
		panic("tried incrementing without a register")
	}
	z := data == 0
	c := .C in gb.cpu.registers.flags
	flags := Flags { }
	if z { flags += { .Z } }
	if h { flags += { .H } }
	if c { flags += { .C } }
	gb.cpu.registers.flags = flags
	gb.cpu.registers.pc += u16(instr.length)
	gb.cpu.cycles += uint(instr.cycles)
}

dec :: proc(instr: ^Instruction, gb: ^Gameboy) {
	data: u16
	h: bool
	switch instr.reg {
	case .A, .B, .C, .D, .E, .H, .L:
		data = u16(read_reg8(gb, instr.reg))
		nibble := data & 0xf0
		data -= 1
		h = data & 0xf0 == nibble
		write_reg8(gb, instr.reg, u8(data))
	case .BC, .DE, .HL, .SP:
		data = read_reg16(gb, instr.reg)
		nibble := data & 0xf000
		data -= 1
		h = data & 0xf000 == nibble
		write_reg16(gb, instr.reg, data)
	case .AF:
		panic("tried to dec AF, no such instruction")
	case .None:
		panic("tried incrementing without a register")
	}
	z := data == 0
	c := .C in gb.cpu.registers.flags
	flags := Flags { .N }
	if z { flags += { .Z } }
	if h { flags += { .H } }
	if c { flags += { .C } }
	gb.cpu.registers.flags = flags
	gb.cpu.cycles += uint(instr.cycles)
	gb.cpu.registers.pc += u16(instr.length)
}

add :: proc(instr: ^Instruction, gb: ^Gameboy) {
	a := u16(read_reg8(gb, .A))
	b := u16(read_reg8(gb, instr.reg))
	nibble := a & 0xf0
	a += b
	write_reg8(gb, .A, u8(a))
	flags := Flags { }
	if u8(a) == 0 { flags += { .Z } }
	if a & 0xf0 != nibble { flags += { .H } }
	if a & 0x100 != 0 { flags += { .C } }
	gb.cpu.registers.flags = flags
	gb.cpu.cycles += uint(instr.cycles)
	gb.cpu.registers.pc += u16(instr.length)
}

add_mem :: proc(instr: ^Instruction, gb: ^Gameboy) {
	a := u16(read_reg8(gb, .A))
	b := u16(read_byte(gb, gb.cpu.registers.hl))
	nibble := a & 0xf0
	a += b
	write_reg8(gb, .A, u8(a))
	flags := Flags { }
	if u8(a) == 0 { flags += { .Z } }
	if a & 0xf0 != nibble { flags += { .H } }
	if a & 0x100 != 0 { flags += { .C } }
	gb.cpu.registers.flags = flags
	gb.cpu.cycles += uint(instr.cycles)
	gb.cpu.registers.pc += u16(instr.length)
}

sub :: proc(instr: ^Instruction, gb: ^Gameboy) {
	a := u16(read_reg8(gb, .A))
	b := u16(read_reg8(gb, instr.reg))
	nibble := a & 0xf0
	a -= b
	write_reg8(gb, .A, u8(a))
	flags := Flags { .N }
	if u8(a) == 0 { flags += { .Z } }
	if a & 0xf0 == nibble { flags += { .H } }
	if a & 0x100 == 0 { flags += { .C } }
	gb.cpu.registers.flags = flags
	gb.cpu.cycles += uint(instr.cycles)
	gb.cpu.registers.pc += u16(instr.length)
}

cp_d8 :: proc(instr: ^Instruction, gb: ^Gameboy) {
	a := u16(read_reg8(gb, .A))
	b := u16(read_byte(gb, gb.cpu.registers.pc + 1))
	nibble := a & 0xf0
	a -= b
	flags := Flags { .N }
	if u8(a) == 0 { flags += { .Z } }
	if a & 0xf0 == nibble { flags += { .H } }
	if a & 0x100 == 0 { flags += { .C } }
	gb.cpu.registers.flags = flags
	gb.cpu.cycles += uint(instr.cycles)
	gb.cpu.registers.pc += u16(instr.length)
}

cp_mem :: proc(instr: ^Instruction, gb: ^Gameboy) {
	a := u16(read_reg8(gb, .A))
	b := u16(read_byte(gb, gb.cpu.registers.hl))
	nibble := a & 0xf0
	a -= b
	flags := Flags { .N }
	if a == 0 { flags += { .Z } }
	if a & 0xf0 == nibble { flags += { .H } }
	if a & 0x100 == 0 { flags += { .C } }
	gb.cpu.registers.flags = flags
	gb.cpu.cycles += uint(instr.cycles)
	gb.cpu.registers.pc += u16(instr.length)
}

jr_nz_r8 :: proc(instr: ^Instruction, gb: ^Gameboy) {
	offset := i8(read_byte(gb, gb.cpu.registers.pc + 1))
	gb.cpu.registers.pc += u16(instr.length)
	if !(.Z in gb.cpu.registers.flags) {
		// log.debugf("Jumping %v bytes!", offset)
		addr := i16(gb.cpu.registers.pc) + i16(offset)
		gb.cpu.registers.pc = u16(addr)
		gb.cpu.cycles += uint(instr.jump_cycles)
	} else {
		gb.cpu.cycles += uint(instr.cycles)
	}
}

jr_z_r8 :: proc(instr: ^Instruction, gb: ^Gameboy) {
	offset := i8(read_byte(gb, gb.cpu.registers.pc + 1))
	gb.cpu.registers.pc += u16(instr.length)
	if (.Z in gb.cpu.registers.flags) {
		// log.debugf("Jumping %v bytes!", offset)
		addr := i16(gb.cpu.registers.pc) + i16(offset)
		gb.cpu.registers.pc = u16(addr)
		gb.cpu.cycles += uint(instr.jump_cycles)
	} else {
		gb.cpu.cycles += uint(instr.cycles)
	}
}

jr_r8 :: proc(instr: ^Instruction, gb: ^Gameboy) {
	offset := i8(read_byte(gb, gb.cpu.registers.pc + 1))
	gb.cpu.registers.pc += u16(instr.length)
	// log.debugf("Jumping %v bytes!", offset)
	addr := i16(gb.cpu.registers.pc) + i16(offset)
	gb.cpu.registers.pc = u16(addr)
	gb.cpu.cycles += uint(instr.cycles)
}

jp :: proc(instr: ^Instruction, gb: ^Gameboy) {
	addr := read_word(gb, gb.cpu.registers.pc + 1)
	gb.cpu.registers.pc = addr
	gb.cpu.cycles += uint(instr.cycles)
}

ld_reg_d8 :: proc(instr: ^Instruction, gb: ^Gameboy) {
	addr := gb.cpu.registers.pc + 1
	data := read_byte(gb, addr)
	write_reg8(gb, instr.reg, data)
	gb.cpu.registers.pc += u16(instr.length)
	gb.cpu.cycles += uint(instr.cycles)
}

ld_reg_a :: proc(instr: ^Instruction, gb: ^Gameboy) {
	data := read_reg8(gb, .A)
	write_reg8(gb, instr.reg, data)
	gb.cpu.registers.pc += u16(instr.length)
	gb.cpu.cycles += uint(instr.cycles)
}

ld_reg_b :: proc(instr: ^Instruction, gb: ^Gameboy) {
	data := read_reg8(gb, .B)
	write_reg8(gb, instr.reg, data)
	gb.cpu.registers.pc += u16(instr.length)
	gb.cpu.cycles += uint(instr.cycles)
}

ld_reg_c :: proc(instr: ^Instruction, gb: ^Gameboy) {
	data := read_reg8(gb, .C)
	write_reg8(gb, instr.reg, data)
	gb.cpu.registers.pc += u16(instr.length)
	gb.cpu.cycles += uint(instr.cycles)
}

ld_reg_d :: proc(instr: ^Instruction, gb: ^Gameboy) {
	data := read_reg8(gb, .D)
	write_reg8(gb, instr.reg, data)
	gb.cpu.registers.pc += u16(instr.length)
	gb.cpu.cycles += uint(instr.cycles)
}

ld_reg_e :: proc(instr: ^Instruction, gb: ^Gameboy) {
	data := read_reg8(gb, .E)
	write_reg8(gb, instr.reg, data)
	gb.cpu.registers.pc += u16(instr.length)
	gb.cpu.cycles += uint(instr.cycles)
}

ld_reg_h :: proc(instr: ^Instruction, gb: ^Gameboy) {
	data := read_reg8(gb, .H)
	write_reg8(gb, instr.reg, data)
	gb.cpu.registers.pc += u16(instr.length)
	gb.cpu.cycles += uint(instr.cycles)
}

ld_reg_l :: proc(instr: ^Instruction, gb: ^Gameboy) {
	data := read_reg8(gb, .L)
	write_reg8(gb, instr.reg, data)
	gb.cpu.registers.pc += u16(instr.length)
	gb.cpu.cycles += uint(instr.cycles)
}

ld_ff_c_a :: proc(instr: ^Instruction, gb: ^Gameboy) {
	addr := 0xff00 + u16(gb.cpu.registers.c)
	data := gb.cpu.registers.a
	write_byte(gb, addr, data)
	gb.cpu.registers.pc += u16(instr.length)
	gb.cpu.cycles += uint(instr.cycles)
}

ld_ff_d8_a :: proc(instr: ^Instruction, gb: ^Gameboy) {
	addr := 0xff00 + u16(read_byte(gb, gb.cpu.registers.pc + 1))
	data := gb.cpu.registers.a
	write_byte(gb, addr, data)
	gb.cpu.registers.pc += u16(instr.length)
	gb.cpu.cycles += uint(instr.cycles)
}

ld_a_ff_d8 :: proc(instr: ^Instruction, gb: ^Gameboy) {
	addr := 0xff00 + u16(read_byte(gb, gb.cpu.registers.pc + 1))
	data := read_byte(gb, addr)
	gb.cpu.registers.a = data
	gb.cpu.registers.pc += u16(instr.length)
	gb.cpu.cycles += uint(instr.cycles)
}

di :: proc(instr: ^Instruction, gb: ^Gameboy) {
	gb.cpu.interrupts_enable = false
	gb.cpu.registers.pc += u16(instr.length)
	gb.cpu.cycles += uint(instr.cycles)
}

ei :: proc(instr: ^Instruction, gb: ^Gameboy) {
	gb.cpu.interrupts_enable = true
	gb.cpu.registers.pc += u16(instr.length)
	gb.cpu.cycles += uint(instr.cycles)
}

read_reg8 :: proc(gb: ^Gameboy, reg: Reg) -> u8 {
	switch reg {
	case .A:
		return gb.cpu.registers.a
	case .B:
		return gb.cpu.registers.b
	case .C:
		return gb.cpu.registers.c
	case .D:
		return gb.cpu.registers.d
	case .E:
		return gb.cpu.registers.e
	case .H:
		return gb.cpu.registers.h
	case .L:
		return gb.cpu.registers.l
	case .AF, .BC, .DE, .HL, .SP, .None:
		panic("tried reading 8 bits from a 16-bit register")
	}
	return 0
}

read_reg16 :: proc(gb: ^Gameboy, reg: Reg) -> u16 {
	switch reg {
	case .AF:
		flags := gb.cpu.registers.flags
		a: u16 = gb.cpu.registers.af & 0xff00
		f: u16
		if .Z in flags { f += 0x80 }
		if .N in flags { f += 0x40 }
		if .H in flags { f += 0x20 }
		if .C in flags { f += 0x10 }
		fmt.printfln("read A: %02x, F: %02x", a, f)
		return a + f
	case .BC:
		return gb.cpu.registers.bc
	case .DE:
		return gb.cpu.registers.de
	case .HL:
		return gb.cpu.registers.hl
	case .SP:
		return gb.cpu.registers.sp
	case .A, .B, .C, .D, .E, .H, .L, .None:
		panic("tried reading 16 bits from an 8-bit register")
	}
	return 0
}

write_reg8 :: proc(gb: ^Gameboy, reg: Reg, data: u8) {
	switch reg {
	case .A:
		gb.cpu.registers.a = data
	case .B:
		gb.cpu.registers.b = data
	case .C:
		gb.cpu.registers.c = data
	case .D:
		gb.cpu.registers.d = data
	case .E:
		gb.cpu.registers.e = data
	case .H:
		gb.cpu.registers.h = data
	case .L:
		gb.cpu.registers.l = data
	case .AF, .BC, .DE, .HL, .SP, .None:
		panic("tried writing 16 bits to 8 bit register")
	}
}

write_reg16 :: proc(gb: ^Gameboy, reg: Reg, data: u16) {
	switch reg {
	case .AF:
		gb.cpu.registers.a = u8(data >> 8)
		flags: Flags
		if data & 0x80 != 0 { flags += { .Z } }
		if data & 0x40 != 0 { flags += { .N } }
		if data & 0x20 != 0 { flags += { .H } }
		if data & 0x10 != 0 { flags += { .C } }
		gb.cpu.registers.flags = flags
		fmt.printfln("wrote AF: %04x", data)
		fmt.println("Flags are now:", flags)
	case .BC:
		gb.cpu.registers.bc = data
	case .DE:
		gb.cpu.registers.de = data
	case .HL:
		gb.cpu.registers.hl = data
	case .SP:
		gb.cpu.registers.sp = data
	case .A, .B, .C, .D, .E, .H, .L, .None:
		panic("tried writing 16 bits to an 8-bit register")
	}
}

res_0 :: proc(instr: ^Instruction, gb: ^Gameboy) {
	data := read_reg8(gb, instr.reg)
	data &= 0xfe
	write_reg8(gb, instr.reg, data)
	gb.cpu.registers.pc += u16(instr.length)
	gb.cpu.cycles += uint(instr.cycles)
}
