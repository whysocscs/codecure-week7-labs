#!/usr/bin/env python3
"""Bounded, local-only classroom fuzzer; no coverage feedback is used."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import random
import resource
import subprocess
import tempfile


def no_core_dump():
    resource.setrlimit(resource.RLIMIT_CORE, (0, 0))


def mutate(seed, rng):
    data = bytearray(seed)
    operation = rng.choice(("flip", "delete", "insert", "repeat", "boundary"))
    if operation == "flip" and data:
        data[rng.randrange(len(data))] ^= 1 << rng.randrange(8)
    elif operation == "delete" and data:
        del data[rng.randrange(len(data))]
    elif operation == "insert":
        at = rng.randrange(len(data) + 1)
        data[at:at] = bytes(rng.randrange(256) for _ in range(rng.randint(1, 8)))
    elif operation == "repeat" and data:
        at = rng.randrange(len(data))
        data[at:at] = data[at:at + 1] * rng.randint(1, 32)
    elif operation == "boundary":
        data.extend(b"A" * rng.choice((0, 1, 15, 16, 17, 31, 32, 64)))
    return bytes(data[:256])


def classify(result):
    if b"ERROR: AddressSanitizer:" in result.stderr:
        return "sanitizer"
    if result.returncode < 0:
        return "signal"
    if result.returncode == 0:
        return "accepted"
    if result.returncode == 2:
        return "rejected"
    return "unexpected_exit"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--mode", required=True, choices=("blind", "mutate"))
    parser.add_argument("--target", required=True)
    parser.add_argument("--seed")
    parser.add_argument("--runs", type=int, default=100)
    parser.add_argument("--rng-seed", type=int, default=7)
    parser.add_argument("--timeout", type=float, default=1.0)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()
    if not 1 <= args.runs <= 10000:
        parser.error("--runs must be between 1 and 10000")
    if not 0.05 <= args.timeout <= 5:
        parser.error("--timeout must be between 0.05 and 5 seconds")
    if args.mode == "mutate" and not args.seed:
        parser.error("mutation mode requires --seed")
    target = Path(args.target).resolve(strict=True)
    seed = Path(args.seed).read_bytes() if args.seed else b""
    if args.mode == "mutate" and not 1 <= len(seed) <= 256:
        parser.error("seed must contain 1 to 256 bytes")
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=False)
    rng = random.Random(args.rng_seed)
    counts = dict.fromkeys(("accepted", "rejected", "sanitizer", "signal", "timeout", "unexpected_exit"), 0)
    first_finding = None
    env = os.environ.copy()
    env["ASAN_OPTIONS"] = "detect_leaks=0:abort_on_error=1:symbolize=1"
    with tempfile.TemporaryDirectory(prefix="fuzz-lab-") as temporary:
        case = Path(temporary) / "input.bin"
        for index in range(1, args.runs + 1):
            data = (bytes(rng.randrange(256) for _ in range(rng.randrange(65)))
                    if args.mode == "blind" else mutate(seed, rng))
            case.write_bytes(data)
            try:
                result = subprocess.run([str(target), str(case)], capture_output=True,
                                        timeout=args.timeout, env=env, preexec_fn=no_core_dump)
                outcome = classify(result)
                stderr = result.stderr
            except subprocess.TimeoutExpired:
                outcome, stderr = "timeout", b"timeout\n"
            counts[outcome] += 1
            if outcome in ("sanitizer", "signal", "timeout") and first_finding is None:
                first_finding = index
                (out / "first_finding.bin").write_bytes(data)
                (out / "first_finding.stderr.txt").write_bytes(stderr)
                print(f"finding at test {index}: {outcome}, {len(data)} bytes")
    report = {"mode": args.mode, "target": target.name, "runs": args.runs,
              "rng_seed": args.rng_seed, "first_finding_test": first_finding,
              "seed_sha256": hashlib.sha256(seed).hexdigest() if seed else None,
              "counts": counts,
              "note": "Counts are test outcomes, not distinct vulnerabilities. No coverage feedback."}
    (out / "report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
