import { execFileSync } from "child_process";

const program = process.env.PROGRAM || "zjev_demo";
execFileSync(process.execPath, ["--expose-gc", `output/${program}.prog.mjs`], { stdio: "inherit" });
