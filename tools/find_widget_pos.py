#!/usr/bin/env python3
"""Find the on-screen position of a widget in a Flutter debugDumpRenderTree dump.

Usage: python find_widget_pos.py <dump.txt> "<target text>"

The render tree dump uses box-drawing characters. Each render object is a
"node line" matching `(child N:|─ child N:|╘═╦══ ...|Render...)`. We parse
lines of the form:
    └─child 2: RenderParagraph#abc relayoutBoundary=up1
and attribute each following property line (creator:, parentData:, size:)
to the most recent node line at the same indent.

We build the parent/child tree from indentation, then walk from the target
node up to the root, summing `parentData: offset=Offset(x, y)` values.
"""
import re
import sys

BOX = re.compile(r'[│├└─╎║╘╚╔═]')

def indent_of(line: str) -> int:
    """Count the visual column where content starts (after box-drawing prefix)."""
    i = 0
    while i < len(line) and line[i] in '│├└─╎║╘╚╔═ ':
        i += 1
    return i

def main() -> None:
    path = sys.argv[1]
    target = sys.argv[2]
    with open(path, encoding='utf-8') as f:
        lines = f.readlines()

    # 1. Identify node lines and their indent, plus the text blocks they own.
    # A node line starts a new "block"; property lines inside the block belong to it.
    nodes = []  # list of dicts: indent, line_no, id, text, parentData offset
    cur = None  # current node dict
    text_buffer = []
    text_lines = {}  # node_index -> list of text fragments found in its block

    node_re = re.compile(r'^(?P<indent>[│├└─╎║\s]*)(?:(?:├─|└─)child \d+:|(?:child \d+:))?\s*(?P<kind>Render\w+)#(?P<hash>[0-9a-f]+)')

    for idx, raw in enumerate(lines):
        line = raw.rstrip('\n')
        stripped = line.strip()
        if not stripped:
            continue
        ind = indent_of(line)
        m = node_re.match(line)
        is_node = bool(m) and 'creator:' not in line and 'parentData' not in line and 'constraints' not in line
        # A line is a node if it starts a Render object declaration:
        #   └─child 1: RenderFlex#9b654 relayoutBoundary=up20
        #   RenderView#...  (root)
        #   RenderParagraph#... (from "╘═╦══" style? no, those are inside text blocks)
        node_decl = re.match(
            r'^(?P<indent>[│├└─╎║\s]*)(?:(?:├─|└─)child(?:\s+\d+)?:|child(?:\s+\d+)?:)\s*_?Render(?P<kind>\w+)#(?P<hash>[0-9a-f]+)',
            line,
        ) or re.match(r'^(?P<indent>\s*)RenderView#(?P<hash>[0-9a-f]+)', line)

        if node_decl:
            # close previous block
            if cur is not None:
                cur['text'] = '\n'.join(text_buffer)
                text_buffer = []
            cur = {
                'indent': ind,
                'line': idx + 1,
                'id': f"Render{node_decl.group('kind')}#{node_decl.group('hash')}",
                'text': '',
                'offset': None,
            }
            nodes.append(cur)
            continue
        if cur is None:
            continue
        # Property lines inside the current block
        off = re.search(r'parentData: [^;]*offset=Offset\(([-0-9.]+), ([-0-9.]+)\)', line)
        if off:
            cur['offset'] = (float(off.group(1)), float(off.group(2)))
        # Also handle "offset: Offset(...)" on _RenderSingleChildViewport (scroll offset)
        off2 = re.search(r'^(\s*)offset: Offset\(([-0-9.]+), ([-0-9.]+)\)$', line)
        if off2 and cur['offset'] is None:
            cur['offset'] = (float(off2.group(2)), float(off2.group(3)))
        # Text content (from ║ lines or Text("...") lines)
        tm = re.search(r'[║│]\s*"(.*?)"', line)
        if tm:
            text_buffer.append(tm.group(1))
        tm2 = re.search(r'Text\("([^"]+)"', line)
        if tm2:
            text_buffer.append(tm2.group(1))
    if cur is not None:
        cur['text'] = '\n'.join(text_buffer)

    # 2. Build parent links: parent = nearest previous node with smaller indent.
    stack = []
    for i, n in enumerate(nodes):
        while stack and stack[-1]['indent'] >= n['indent']:
            stack.pop()
        n['parent'] = stack[-1] if stack else None
        stack.append(n)

    # 3. Find target node(s) by text
    matches = [n for n in nodes if target in n['text']]
    if not matches:
        print(f'TARGET NOT FOUND: {target}')
        sys.exit(1)

    for n in matches:
        # walk up accumulating offsets
        chain = []
        total = [0.0, 0.0]
        cur_node = n
        while cur_node is not None:
            off = cur_node.get('offset')
            chain.append((cur_node['id'], off, cur_node['line']))
            if off:
                total[0] += off[0]
                total[1] += off[1]
            cur_node = cur_node['parent']
        print(f"== {n['id']} (line {n['line']}) ==")
        print(f"  summed offset: ({total[0]:.1f}, {total[1]:.1f}) logical px from viewport origin")
        print("  chain (id, offset, line):")
        for cid, off, ln in chain[:12]:
            print(f"    {cid}  off={off}  line={ln}")

if __name__ == '__main__':
    main()
