#!/usr/bin/env python3
"""Generate FortuneData.swift from fortune_messages.txt."""

from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MESSAGES_FILE = Path(__file__).resolve().parent / "fortune_messages.txt"
OUTPUT_FILE = ROOT / "Shared" / "FortuneData.swift"


def escape_swift_string(text: str) -> str:
    return text.replace("\\", "\\\\").replace('"', '\\"')


def main() -> None:
    lines = MESSAGES_FILE.read_text(encoding="utf-8").splitlines()
    messages = [line.strip() for line in lines if line.strip()]

    swift_lines = [
        "import Foundation",
        "",
        "enum FortuneData {",
        f"    static let messages: [String] = [",
    ]

    for message in messages:
        swift_lines.append(f'        "{escape_swift_string(message)}",')

    swift_lines.extend(
        [
            "    ]",
            "",
            "    static func randomFortune(excluding used: Set<String> = []) -> String {",
            "        let available = messages.filter { !used.contains($0) }",
            "        return available.randomElement() ?? messages.randomElement() ?? \"오늘도 행운이 함께할 거예요.\"",
            "    }",
            "}",
            "",
        ]
    )

    OUTPUT_FILE.write_text("\n".join(swift_lines), encoding="utf-8")
    print(f"Generated {len(messages)} fortunes -> {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
