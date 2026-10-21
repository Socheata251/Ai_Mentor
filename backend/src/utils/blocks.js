/** Turn text into the message "blocks" the Flutter app renders. */
const FENCE = /```(\w*)\n([\s\S]*?)```/g;

/** User text: pasted ```code``` becomes code blocks. */
export function userTextToBlocks(text) {
  const blocks = [];
  let last = 0;
  for (const m of text.matchAll(FENCE)) {
    const before = text.slice(last, m.index).trim();
    if (before) blocks.push({ type: 'text', text: before });
    blocks.push({ type: 'code', code: m[2].trimEnd(), ...(m[1] ? { language: m[1] } : {}) });
    last = m.index + m[0].length;
  }
  const rest = text.slice(last).trim();
  if (rest || blocks.length === 0) blocks.push({ type: 'text', text: rest });
  return blocks;
}

/** AI text: code fences -> code blocks, paragraphs starting "Tip:" -> tip blocks. */
export function aiTextToBlocks(text) {
  const out = [];
  for (const b of userTextToBlocks(text)) {
    if (b.type !== 'text') { out.push(b); continue; }
    for (const para of b.text.split(/\n{2,}/)) {
      const p = para.trim();
      if (!p) continue;
      const tip = /^(tip|គន្លឹះ)\s*[:：]\s*/i.exec(p);
      out.push(tip ? { type: 'tip', text: p.slice(tip[0].length) } : { type: 'text', text: p });
    }
  }
  return out.length ? out : [{ type: 'text', text: '' }];
}

/** Flatten blocks back to plain text (used when sending history to the AI). */
export function blocksToText(blocks) {
  return blocks
    .map((b) => (b.type === 'code' ? '```' + (b.language ?? '') + '\n' + b.code + '\n```' : b.text ?? b.question ?? ''))
    .join('\n\n');
}