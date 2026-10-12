#!/usr/bin/env python3
"""Gera um script Luau que recria no Roblox Studio as pastas gerenciadas a partir de src/.

Convenções:
  pasta            -> Folder
  Nome.server.lua  -> Script
  Nome.client.lua  -> LocalScript
  Nome.lua         -> ModuleScript

Pastas gerenciadas (apagadas e recriadas a cada sincronização):
  ReplicatedStorage/Shared
  ServerScriptService/Server
  StarterPlayer/StarterPlayerScripts/Client
  ServerStorage/WorldGen

Uso: python3 tools/build_sync.py [--only Servico/Pasta ...] > saida.luau
"""
import os
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "src")

MANAGED = [
    ("ReplicatedStorage", ["Shared"]),
    ("ServerScriptService", ["Server"]),
    ("StarterPlayer", ["StarterPlayerScripts", "Client"]),
    ("ServerStorage", ["WorldGen"]),
]


def long_string(text: str) -> str:
    level = 0
    while ("]" + "=" * level + "]") in text:
        level += 1
    eq = "=" * level
    return "[" + eq + "[\n" + text + "]" + eq + "]"


def classify(name: str):
    if name.endswith(".server.lua"):
        return "Script", name[: -len(".server.lua")]
    if name.endswith(".client.lua"):
        return "LocalScript", name[: -len(".client.lua")]
    if name.endswith(".lua"):
        return "ModuleScript", name[: -len(".lua")]
    return None, None


def emit_dir(path: str, parent_var: str, out: list, counter: list):
    for entry in sorted(os.listdir(path)):
        full = os.path.join(path, entry)
        counter[0] += 1
        var = f"i{counter[0]}"
        if os.path.isdir(full):
            out.append(f'local {var} = Instance.new("Folder"); {var}.Name = "{entry}"')
            emit_dir(full, var, out, counter)
            out.append(f"{var}.Parent = {parent_var}")
        else:
            cls, name = classify(entry)
            if not cls:
                continue
            with open(full, encoding="utf-8") as f:
                src = f.read()
            out.append(f'local {var} = Instance.new("{cls}"); {var}.Name = "{name}"')
            out.append(f"{var}.Source = {long_string(src)}")
            out.append(f"{var}.Parent = {parent_var}")


def main():
    out = [
        "-- Gerado por tools/build_sync.py. Não editar à mão.",
        'local CHS = game:GetService("ChangeHistoryService")',
        'local rec = CHS:TryBeginRecording("Sincronizar código do repositório")',
        "local created = 0",
    ]
    counter = [0]
    only = sys.argv[sys.argv.index("--only") + 1:] if "--only" in sys.argv else None
    for service, chain in MANAGED:
        if only and "/".join([service] + chain) not in only:
            continue
        base = os.path.join(ROOT, service, *chain)
        if not os.path.isdir(base):
            continue
        out.append("do")
        out.append(f'  local parent = game:GetService("{service}")')
        for mid in chain[:-1]:
            out.append(f'  parent = parent:WaitForChild("{mid}")')
        leaf = chain[-1]
        out.append(f'  local old = parent:FindFirstChild("{leaf}")')
        out.append("  if old then old:Destroy() end")
        out.append(f'  local root = Instance.new("Folder"); root.Name = "{leaf}"')
        body = []
        emit_dir(base, "root", body, counter)
        out.extend("  " + line for line in body)
        out.append("  root.Parent = parent")
        out.append("  created += #root:GetDescendants()")
        out.append("end")
    out.append("if rec then CHS:FinishRecording(rec, Enum.FinishRecordingOperation.Commit) end")
    out.append('return "Sincronizado: " .. created .. " objetos"')
    sys.stdout.write("\n".join(out) + "\n")


if __name__ == "__main__":
    main()
