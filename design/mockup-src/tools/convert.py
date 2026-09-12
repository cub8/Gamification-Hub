"""Cut each t/*.html template down to a view module for the wired app:
drop the per-template chrome and boot code, keep views/dialogs/actions."""
import re, pathlib, sys

SRC = pathlib.Path('/home/claude/wip/parts')
OUT = pathlib.Path('/home/claude/gh/src/js')

DROP_NAMED = {'header', 'sidebar', 'tabbar', 'render', 'toast', 'layout', 'sync', 'hT'}
DROP_ANON = (
    "app.addEventListener('click'",
    "document.getElementById('tb-",
    "window.addEventListener('resize'",
    "window.mock",
    "layout();",
    "(()=>{",
    "})();",
)


def chunks(text):
    out, cur = [], []
    for line in text.split('\n'):
        if line and not line[0].isspace() and line[0] not in '})]' and cur:
            out.append('\n'.join(cur)); cur = [line]
        else:
            cur.append(line)
    if cur:
        out.append('\n'.join(cur))
    return out


def name_of(chunk):
    m = re.match(r'^(?:function\s+(\w+)|(?:const|let|var)\s+(\w+))', chunk)
    return (m.group(1) or m.group(2)) if m else None


def convert(mod, drop_extra=()):
    text = SRC.joinpath(mod + '.js').read_text()
    kept = []
    for c in chunks(text):
        n = name_of(c)
        s = c.lstrip()
        if n and (n in DROP_NAMED or n in drop_extra):
            continue
        if not n and any(s.startswith(p) for p in DROP_ANON):
            continue
        if not s.strip():
            continue
        kept.append(c)
    body = '\n'.join(kept)
    body = body.replace("app.addEventListener(", "ON(").replace("document.addEventListener(", "DON(")
    body = body.replace("S.theme", "G.theme").replace("S.frame", "G.frame")
    body = re.sub(r'^const app=document\.getElementById.*$\n?', '', body, flags=re.M)
    return body


if __name__ == '__main__':
    mod = sys.argv[1]
    print(convert(mod, tuple(sys.argv[2:])))
