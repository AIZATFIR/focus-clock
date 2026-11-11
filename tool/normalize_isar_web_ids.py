"""Keep Isar's full 64-bit schema hashes while allowing Flutter Web builds.

Run after `dart run build_runner build --delete-conflicting-outputs`.
The native Isar core validates each schema ID against its full name hash.
Dart2JS rejects oversized integer literals, so split those values into a
constant arithmetic expression. Native Dart evaluates the exact integer; the
web build uses in-memory fallback storage and does not open native Isar.
"""

from pathlib import Path
import re

SAFE_INTEGER = 9_007_199_254_740_991
CHUNK_BASE = 1_000_000_000_000
ID_FIELD = re.compile(r"(\bid:\s*)(-?\d+)(\s*,)")


def keep_id_web_compatible(match: re.Match[str]) -> str:
    value = int(match.group(2))
    if abs(value) <= SAFE_INTEGER:
        return match.group(0)

    sign = "-" if value < 0 else ""
    high, low = divmod(abs(value), CHUNK_BASE)
    expression = f"{sign}({high} * {CHUNK_BASE} + {low})"
    return f"{match.group(1)}{expression}{match.group(3)}"


for generated in Path("lib/models").glob("*.g.dart"):
    source = generated.read_text()
    compatible = ID_FIELD.sub(keep_id_web_compatible, source)
    if compatible != source:
        generated.write_text(compatible)
