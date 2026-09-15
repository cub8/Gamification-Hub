"""Scope a standalone page's CSS under a selector so it can't leak into the app.
The upload stress test was authored as its own page and redefines generic class
names (.sec, .grp, body...) that collide with the app's own styles."""
import re


def scope_css(css, prefix):
    out, i, n = [], 0, len(css)
    while i < n:
        # copy over @-blocks' headers, scope their contents recursively
        m = re.compile(r'@[\w-]+[^{;]*[{;]').match(css, i)
        if m:
            head = m.group(0)
            if head.endswith(';'):
                out.append(head); i = m.end(); continue
            depth, j = 1, m.end()
            while j < n and depth:
                if css[j] == '{': depth += 1
                elif css[j] == '}': depth -= 1
                j += 1
            out.append(head + scope_css(css[m.end():j - 1], prefix) + '}')
            i = j
            continue
        b = css.find('{', i)
        if b == -1:
            out.append(css[i:]); break
        e = css.find('}', b)
        sel, body = css[i:b], css[b + 1:e]
        lead = sel[:len(sel) - len(sel.lstrip())]
        parts = [s.strip() for s in sel.strip().split(',') if s.strip()]
        scoped = ', '.join(f'{prefix} {p}' for p in parts)
        out.append(f'{lead}{scoped}{{{body}}}')
        i = e + 1
    return ''.join(out)
