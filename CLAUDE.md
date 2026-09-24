# TouchCursor fork: Punto Switcher compatibility

Fork of martin-stone/touchcursor (source = v1.7.1.10, same as the official 1.7.1 Rev 10 installer).
Only purpose: make TouchCursor coexist with Punto Switcher (auto keyboard-layout corrector).

## The problem and the fix
- TouchCursor = global low-level keyboard hook (`touchcursordll/dllmain.cpp`, `LowLevelKeyboardProc`).
  Holding Space turns I/J/K/L/U/O/H/N/Y/M/P into navigation keys; Space itself is held back until release.
- Punto corrects a word by *injecting* Backspaces + retyped letters (SendInput), usually while Space is down.
- Original code skipped only its own injected events (`dwExtraInfo == 'TCUR'`), so Punto's keys went through
  the state machine -> caret jumps (L -> Right, O -> End...) and stray letters/spaces.
- Fix: `injectedBySoftware()` skips *every* event with `LLKHF_INJECTED`. Modifier tracking
  (`logModifierState`) intentionally still sees injected events.
- Side effect (accepted): TouchCursor no longer remaps keys sent by other software
  (on-screen keyboard, AutoHotkey, remote-control tools).

## Gotchas
- `dllmain.cpp` is CRLF + Latin-1 (not UTF-8). Edit byte-exactly; never let an editor re-encode it.
  Upload via GitHub's "Upload files" page, not the web editor.
- Hook order is not fixed: `ReHook()` re-installs the hook every 500 ms of keyboard idle
  (moves TouchCursor to the front of the hook chain). Relevant for any interaction with other hooks.
- Settings: `%APPDATA%\TouchCursor\settings.cfg` (Boost text archive, class version 6).
- `L#EVENT` / `L#STATE` macros in the state-machine coverage code are MSVC-only (GCC rejects them).

## Tests
- Debug builds run a self-test from a static initializer in the DLL (`namespace test`, `Tester`):
  `CHECK((key, flag, expected output...))`. Loading the Debug DLL runs it; failures -> `exit(count)`.
  Flags: `dn`, `up`, `edn`, and `inj`/`injup` for injected events.
- Local run without Windows (Linux): mingw-w64 i686 + Wine. Compile dllmain.cpp (with the L# macros
  replaced), tclib/*.cpp and Boost.Serialization sources into an exe with an empty main(), run under wine.
  Negative control done: with the fix reverted, the new tests fail (84 failures).
- Real-world behavior (Punto + physical keys) can only be tested by a human: synthesized keys are
  exactly what the fix ignores.

## Build
- Official: VS 2022 x86, wxWidgets 3.2.11 static and Boost 1.86 at the paths in `touchcursor.props`.
- CI: `.github/workflows/build.yml` + `ci/*.ps1` (deps cached, keyed on `ci/deps.ps1` hash);
  artifact = Release binaries + app-local x86 C++ runtime + INSTALL.txt.
