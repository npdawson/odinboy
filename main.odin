package odinboy

import "core:fmt"
import "core:log"
import "core:os"

import sdl "vendor:sdl3"

Registers :: struct {
	using _: struct #raw_union {
		using _: struct {
			using _: struct #raw_union {
				f: u8,
				flags: Flags,
			},
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
}

Flags :: distinct bit_set[Flag; u8]
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

IFlags :: bit_set[IFlag; u8]
IFlag :: enum {
	VBlank,
	LCDStat,
	Timer,
	Serial,
	Joypad,
}

MBC :: enum u8 {
	ROM,
	MBC1,
	MBC1RAM,
	MBC1RAMBAT,
	MBC2,
	MBC2BAT,
	// TODO finish this
}

Cartridge :: struct {
	mbc: MBC,
	rom_bank: u8,
	ram_bank: u8,
	ram_enable: bool,
	adv_bank_mode: bool,
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

Audio :: struct {
	// chan1_sweep: u8,
	// chan1_length_pattern: u8,
	// chan1_volume_envelope: u8,
	// chan1_freq_lo: u8,
	// chan1_freq_hi: u8,
	//
	// chan2_length_pattern: u8,
	// chan2_volume_envelope: u8,
	// chan2_freq_lo: u8,
	// chan2_freq_hi: u8,
	regs: [64]u8, // TODO: implement audio
	stream: ^sdl.AudioStream,
	on: bool,
}

Serial :: struct {
	data: u8,
	control: u8,
}

Timer :: struct {
	divider: u8,
	counter: u8,
	modulo: u8,
	control: u8,
}

PPU :: struct {
	regs: [48]u8, // TODO: implement PPU/LCD
}

CPU :: struct {
	registers: Registers,
	cycles: uint,
	interrupt_flags: IFlags,
	interrupts_enable: bool,
}

Gameboy :: struct {
	cpu: CPU,
	ppu: PPU,
	memory: Memory,
	cart: Cartridge,

	serial: Serial,
	timer: Timer,
	audio: Audio,
	boot_rom_enabled: bool,
}

main :: proc() {
	log_file: os.Handle
	err: os.Error
	log_file, err = os.open("odinboy.log", os.O_CREATE | os.O_WRONLY | os.O_TRUNC, 0o644)
	if err != nil {
		fmt.eprintln(err)
		panic("couldn't open log file")
	}
	context.logger = log.create_file_logger(log_file)

	if len(os.args) != 3 {
		fmt.eprintln("Please specify the boot and game roms")
		fmt.eprintln(os.args)
		os.exit(1)
	}

	boot_rom, game_rom: []byte
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
	gb.cart.mbc = cast(MBC)gb.memory.game_rom[0x147]

	if !sdl.Init({.AUDIO, .VIDEO}) {
		fmt.eprintln("SDL error:", sdl.GetError())
		panic("Error initializing SDL")
	}
	// 800x720 is 160x144 x 5
	window := sdl.CreateWindow("Odinboy", 800, 720, nil)
	if window == nil {
		fmt.eprintln("SDL error:", sdl.GetError())
		panic("Error creating window")
	}
	defer sdl.DestroyWindow(window)
	renderer := sdl.CreateRenderer(window, nil)
	if renderer == nil {
		fmt.eprintln("SDL error:", sdl.GetError())
		panic("Error creating renderer")
	}
	defer sdl.DestroyRenderer(renderer)
	audio_spec := sdl.AudioSpec {
		format = .F32,
		channels = 2,
		freq = 48000,
	}
	gb.audio.stream = sdl.OpenAudioDeviceStream(
		sdl.AUDIO_DEVICE_DEFAULT_PLAYBACK,
		&audio_spec,
		nil, // callback
		nil) // user data
	if gb.audio.stream == nil {
		fmt.eprintln("SDL error:", sdl.GetError())
		panic("Error opening audio stream")
	}
	defer sdl.DestroyAudioStream(gb.audio.stream)

	sdl.PauseAudioStreamDevice(gb.audio.stream)
	current_sine_sample: int

	sdl.SetRenderDrawColor(renderer, 0, 55, 75, 255)
	sdl.RenderClear(renderer)
	sdl.RenderPresent(renderer)

	event: sdl.Event
	running := true

	for running {
		for sdl.PollEvent(&event) {
			#partial switch event.type {
			case .QUIT:
				running = false
			}
		}
		addr := gb.cpu.registers.pc
		opcode := read_byte(&gb, addr)
		operand: u16
		instr := instructions[opcode]

		start_log: u16 = 0x100

		if opcode == 0xcb {
			opcode = read_byte(&gb, gb.cpu.registers.pc + 1)
			instr = cb_instructions[opcode]
		}
		if instr.function == nil {
			fmt.eprintfln("Opcode: 0x%02x", opcode)
			panic("Instruction not yet implemented!")
		}
		if addr >= start_log {
			log.debugf("%04x: ", addr)
			switch instr.length {
			case 0, 1:
				log.debug(instr.disassembly)
			case 2:
				operand = u16(read_byte(&gb, addr+1))
				log.debugf(instr.disassembly, operand)
			case 3:
				operand = read_word(&gb, addr+1)
				log.debugf(instr.disassembly, operand)
			}
		}
		instr.function(&instr, &gb)
		// check for PPU line update, 114 m-cycles per scanline
		if gb.cpu.cycles >= 114 {
			gb.cpu.cycles %= 114
			ly := read_io_reg(&gb, 0xff44)
			ly += 1
			if ly == 144 {
				sdl.RenderClear(renderer)
				sdl.RenderPresent(renderer)
			}
			ly %= 154 // 153 scanlines including v-blank
			gb.ppu.regs[0x4] = ly
			// if ly == 0 { fmt.println("frame!") }
		}
		if addr >= start_log {
			log.debugf("A: %02x B: %02x C: %02x D: %02x E: %02x HL: %04x SP: %04x",
			gb.cpu.registers.a, gb.cpu.registers.b, gb.cpu.registers.c,
			gb.cpu.registers.d, gb.cpu.registers.e, gb.cpu.registers.hl, gb.cpu.registers.sp)
			z := .Z in gb.cpu.registers.flags ? "Z" : ""
			n := .N in gb.cpu.registers.flags ? "N" : ""
			h := .H in gb.cpu.registers.flags ? "H" : ""
			c := .C in gb.cpu.registers.flags ? "C" : ""
			log.debugf(" Flags: %v %v %v %v", z, n, h, c)
		}

		// min_samples: i32 = 48000 * size_of(f32) / 2
		// if sdl.GetAudioStreamQueued(gb.audio.stream) < min_samples {
		// 	samples: [512]f32
		// 	for &s in samples {
		// 		freq := 440
		// 		phase := f32(current_sine_sample) * f32(freq) / 48000
		// 		s = sdl.sinf(phase * 2 * 3.1415926)
		// 		current_sine_sample += 1
		// 	}
		// 	current_sine_sample %= 48000
		// 	sdl.PutAudioStreamData(gb.audio.stream, &samples, len(samples))
		// }
	}
}

read_byte :: proc(gb: ^Gameboy, addr: u16) -> u8 {
	boot := gb.boot_rom_enabled
	switch addr {
	case 0x00..=0xff:
		return boot ? gb.memory.boot_rom[addr] : read_rom(gb, addr)
	case 0x100..=0x7fff:
		return read_rom(gb, addr)
	case 0x8000..=0x9FFF:
		return gb.memory.video_ram[addr-0x8000]
	case 0xA000..=0xBFFF:
		return gb.memory.extern_ram[addr-0xA000]
	case 0xC000..=0xDFFF:
		return gb.memory.work_ram[addr-0xC000]
	case 0xFF00..=0xFF7F:
		return read_io_reg(gb, addr)
	case 0xFF80..=0xFFFE:
		return gb.memory.high_ram[addr-0xFF80]
	case 0xffff:
		return gb.memory.interrupt_enable_register
	case:
		fmt.eprintfln("Tried reading byte from addr: %04x", addr)
		panic("Outside current memory map implementation!")
	}
}

read_word :: proc(gb: ^Gameboy, addr: u16) -> u16 {
	low_byte := read_byte(gb, addr)
	high_byte := read_byte(gb, addr+1)
	word := u16(low_byte) + u16(high_byte) << 8
	return word
}

write_byte :: proc(gb: ^Gameboy, addr: u16, data: byte) {
	switch addr {
	case 0x0000..=0x7fff:
		write_mbc(gb, addr, data)
	case 0x8000..=0x9FFF:
		gb.memory.video_ram[addr-0x8000] = data
	case 0xA000..=0xBFFF:
		gb.memory.extern_ram[addr-0xA000] = data
	case 0xC000..=0xDFFF:
		gb.memory.work_ram[addr-0xC000] = data
	case 0xFF00..=0xFF7F:
		write_io_reg(gb, addr, data)
	case 0xFF80..=0xFFFE:
		gb.memory.high_ram[addr-0xFF80] = data
	case 0xffff:
		gb.memory.interrupt_enable_register = data
	case:
		fmt.eprintfln("Tried writing byte to addr: %04x", addr)
		panic("Outside current writing memory map implementation!")
	}
}

read_io_reg :: proc(gb: ^Gameboy, addr: u16) -> u8 {
	data: u8
	switch addr {
	case 0xff10..=0xff3f:
		data = gb.audio.regs[addr - 0xff10]
		// log.debugf("\treading %02x from the audio register %04x", data, addr)
	case 0xff40..=0xff6f:
		data = gb.ppu.regs[addr - 0xff40]
		// log.debugf("\treading %02x from the PPU register %04x", data, addr)
	case:
		fmt.eprintfln("Tried writing to I/O register at %04x", addr)
		panic("writing to I/O register not yet implemented")
	}
	return data
}

write_io_reg :: proc(gb: ^Gameboy, addr: u16, data: u8) {
	switch addr {
	case 0xff01:
		gb.serial.data = data
	case 0xff02:
		gb.serial.control = data
	case 0xff06:
		gb.timer.modulo = data
	case 0xff07:
		gb.timer.control = data
	case 0xff26:
		if data & 0x80 == 0 {
			gb.audio.on = false
			sdl.PauseAudioStreamDevice(gb.audio.stream)
		} else {
			gb.audio.on = true
			sdl.ResumeAudioStreamDevice(gb.audio.stream)
		}
	case 0xff10..=0xff3f:
		log.debugf("\twriting %02x to audio register %04x", data, addr)
		gb.audio.regs[addr - 0xff10] = data
	case 0xff44:
		log.debugf("RESET PPU LY")
		gb.ppu.regs[addr - 0xff40] = 0
	case 0xff50:
		log.debugf("no more boot rom!")
		gb.boot_rom_enabled = false
	case 0xff40..=0xff6f:
		// log.debugf("\twriting %02x to PPU register %04x", data, addr)
		gb.ppu.regs[addr - 0xff40] = data
	case 0xff0f:
		write_iflags(gb, data)
	case:
		fmt.eprintfln("Tried writing to I/O register at %04x", addr)
		panic("writing to I/O register not yet implemented")
	}
}

write_iflags :: proc(gb: ^Gameboy, data: u8) {
	flags: IFlags
	if data & 0x1 != 0 { flags += { .VBlank } }
	if data & 0x2 != 0 { flags += { .LCDStat } }
	if data & 0x4 != 0 { flags += { .Timer } }
	if data & 0x8 != 0 { flags += { .Serial } }
	if data & 0x10 != 0 { flags += { .Joypad } }
	gb.cpu.interrupt_flags = flags
}

write_mbc :: proc(gb: ^Gameboy, addr: u16, data: u8) {
	switch addr {
	case 0x0000:
		gb.cart.ram_enable = (data & 0xf == 0xa ? true : false)
	case 0x2000:
		gb.cart.rom_bank = data
		fmt.println("Switching to bank:", data & 0x1f)
	case 0x4000:
		gb.cart.ram_bank = data
	case 0x6000:
		gb.cart.adv_bank_mode = (data > 0 ? true : false)
	}
}

read_rom :: proc(gb: ^Gameboy, addr: u16) -> byte {
	new_addr := addr
	// TODO: implement advanced banking mode
	if addr >= 0x4000 {
		new_addr += 0x4000 * u16(gb.cart.rom_bank - 1)
	}
	return gb.memory.game_rom[new_addr]
}
