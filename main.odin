package odinboy

import "core:fmt"
import "core:os"

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

Flags :: bit_set[Flag]
Flag :: enum {
	_, // Odin bit_sets start with the least significant bit
	_,
	_,
	_,
	C, // Carry flag
	H, // Half carry flag (nibble overflow)
	N, // uNderflow flag (subtraction)
	Z, // Zero flag
}

Memory :: struct {
	boot_rom: []byte,
	game_rom: []byte,
	video_ram: [8192]byte,
	extern_ram: [8192]byte,
	work_ram: [8192]byte, // TODO: 2 banks, one is switchable on the GB Color
	// sprite attrib table (OAM)
	// IO ports
	high_ram: [128]byte,
	interrupt_enable_register: byte,
}

CPU :: struct {
	registers: Registers,
}

Gameboy :: struct {
	cpu: CPU,
	memory: Memory,

	boot_rom_enabled: bool,
}

main :: proc() {
	if len(os.args) != 3 {
		fmt.eprintln("Please specify the boot and game roms")
		fmt.eprintln(os.args)
		os.exit(1)
	}

	boot_rom, game_rom: []byte
	err: os.Error
	if boot_rom, err = os.read_entire_file_or_err(os.args[1]); err != nil {
		fmt.eprintln("Error reading boot rom:", err)
		os.exit(1)
	}
	if game_rom, err = os.read_entire_file_or_err(os.args[2]); err != nil {
		fmt.eprintln("Error reading game rom:", err)
		os.exit(1)
	}

	gb: Gameboy
	gb.boot_rom_enabled = true
	gb.memory.boot_rom = boot_rom
	gb.memory.game_rom = game_rom

	for {
		addr := gb.cpu.registers.pc
		opcode := read_byte(addr, gb.memory, gb.boot_rom_enabled)
		operand: u16
		instr := instructions[opcode]

		// debug printing
		fmt.printf("%04x: ", addr)
		switch instr.length {
		case 0:
			fmt.println(instr.disassembly)
		case 1:
			operand = u16(read_byte(addr+1, gb.memory, gb.boot_rom_enabled))
			fmt.printfln(instr.disassembly, operand)
		case 2:
			operand = read_word(addr+1, gb.memory, gb.boot_rom_enabled)
			fmt.printfln(instr.disassembly, operand)
		}

		if instr.function == cb {
			opcode = read_byte(gb.cpu.registers.pc + 1, gb.memory, gb.boot_rom_enabled)
			instr = cb_instructions[opcode]
			fmt.println("\t", instr.disassembly)
		}
		if instr.function == nil {
			fmt.eprintfln("Addr: 0x%04x, Opcode: 0x%02x", addr, opcode)
			panic("Instruction not yet implemented!")
		}
		instr.function(&gb)
		fmt.printf("A: %02x B: %02x C: %02x D: %02x E: %02x HL: %02x",
			gb.cpu.registers.a, gb.cpu.registers.b, gb.cpu.registers.c,
			gb.cpu.registers.d, gb.cpu.registers.e, gb.cpu.registers.hl)
		fmt.printf(" SP: %04x", gb.cpu.registers.sp)
		z := .Z in gb.cpu.registers.flags ? "Z" : ""
		n := .N in gb.cpu.registers.flags ? "N" : ""
		h := .H in gb.cpu.registers.flags ? "H" : ""
		c := .C in gb.cpu.registers.flags ? "C" : ""
		fmt.printfln(" Flags: %v %v %v %v", z, n, h, c)

		gb.cpu.registers.pc += u16(instr.length + 1)
	}
}

read_byte :: proc(addr: u16, mem: Memory, boot: bool = false) -> byte {
	if boot && addr < 0x100 {
		return mem.boot_rom[addr]
	}

	panic("Outside current memory map implementation!")
}

read_word :: proc(addr: u16, mem: Memory, boot: bool = false) -> u16 {
	low_byte := read_byte(addr, mem, boot)
	high_byte := read_byte(addr+1, mem, boot)
	word := u16(low_byte) + u16(high_byte) << 8
	return word
}

write_byte :: proc(addr: u16, data: byte, mem: ^Memory) {
	switch addr {
	case 0x8000..=0x9FFF:
		mem.video_ram[addr-0x8000] = data
	case 0xA000..=0xBFFF:
		mem.extern_ram[addr-0xA000] = data
	case 0xC000..=0xDFFF:
		mem.work_ram[addr-0xC000] = data
	case 0xFF80..=0xFFFE:
		mem.high_ram[addr-0xFF80] = data
	case:
		panic("Outside current writing memory map implementation!")
	}
}
