# STM32 Baremetal Template

A minimal bare-metal template for STM32 microcontrollers — no HAL, no CubeMX, just pure register-level programming.

---

## What's Inside

```
baremetal_template/
├── Core/Src/          # Your application source files
├── Drivers/CMSIS/     # CMSIS headers (replace with your MCU's files)
├── Makefile           # Build system
├── .gitignore
└── README.md
```

---

## Getting Started

### 1. Clone the template

```bash
git clone https://github.com/Vik-Prabhu/baremetal_template.git my_project
cd my_project
```

### 2. Replace CMSIS files

The `Drivers/CMSIS/` folder needs to match **your specific STM32 device**.

- Download the correct CMSIS pack from [ST's website](https://www.st.com) or from the [STM32 GitHub](https://github.com/STMicroelectronics)
- Replace the contents of `Drivers/CMSIS/` with your device's headers

> **Example:** For STM32F103, grab files from `STM32F1xx_HAL_Driver` / CMSIS pack for F1 series.  
> For STM32G0, use the G0 series pack — and so on.

The key files you'll need for your device:
- `stm32xxxx.h` — device-specific register definitions
- `system_stm32xxxx.h` — system clock setup
- `startup_stm32xxxx.s` — startup assembly file

### 3. Add Your Startup File

Every STM32 device needs a startup file that sets up the vector table and calls `main()`.

- Find the correct startup file for your MCU from ST's CMSIS pack or CubeMX output
  - It will be named something like `startup_stm32f103xb.s` or `startup_stm32g071xx.s`
- Place it in `Core/Src/` (or your preferred location)
- Make sure it is referenced in your `Makefile` under the sources list:

```makefile
ASM_SOURCES = startup_stm32f103xb.s   # change to match your device
```

> **Note:** Some devices use a `.c` startup file instead of `.s` — both work, just make sure the Makefile picks it up under `C_SOURCES` or `ASM_SOURCES` accordingly.

### 4. Add Your Linker Script

The linker script (`.ld` file) tells the compiler how much Flash and RAM your chip has and where to place code sections.

- Get the linker script for your specific MCU — CubeMX generates one automatically, or find it in ST's repo
  - It will be named something like `STM32F103C8TX_FLASH.ld`
- Place it in the root of your project
- Update the `Makefile` to point to it:

```makefile
LDSCRIPT = STM32F103C8TX_FLASH.ld    # change to your linker script name
```

> **Important:** Using the wrong linker script (e.g., wrong Flash/RAM size) will cause your firmware to behave incorrectly or not run at all. Always double-check it matches your exact MCU part number.

### 5. Update the Makefile

Open `Makefile` and change these variables to match your chip:

```makefile
# Example for STM32F103C8T6
MCU     = cortex-m3
DEVICE  = STM32F103xB
```

Also make sure the linker script (`.ld` file) matches your device's flash and RAM sizes.

### 6. Build

Make sure you have `arm-none-eabi-gcc` installed, then:

```bash
make
```

### 7. Flash

Use OpenOCD, ST-Link, or whatever programmer you have:

```bash
openocd -f interface/stlink.cfg -f target/stm32f1x.cfg -c "program build/output.elf verify reset exit"
```

---

## Requirements

- `arm-none-eabi-gcc` toolchain
- `make`
- ST-Link or any SWD/JTAG programmer
- OpenOCD (or STM32CubeProgrammer) for flashing

---

## Notes

- There is **no HAL dependency** — you write directly to registers
- The template is intentionally minimal; add only what you need
- Works with any STM32 series — just swap the CMSIS files and update the Makefile

---

## License

MIT — free to use and modify.
