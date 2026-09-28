import { rmSync } from "fs";

// Removes the transpiler output directory before each build run.
rmSync("output", { recursive: true, force: true });
