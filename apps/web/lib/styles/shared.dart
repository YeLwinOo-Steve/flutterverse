import 'package:jaspr/dom.dart';

import 'css.dart';

/// Classes for patterns the design repeats across many components.
final sharedStyles = <StyleRule>[
  // Surfaces
  rule('.panel', {'border': '1px solid var(--line)', 'background': 'var(--surface)', 'border-radius': '2px'}),
  rule('.panel-head', {
    'display': 'flex',
    'align-items': 'center',
    'gap': '12px',
    'flex-wrap': 'wrap',
    'padding': '12px 16px',
    'border-bottom': '1px solid var(--line)',
  }),
  rule('.hover-row', {'cursor': 'pointer'}),
  rule('.hover-row:hover', {'background': 'var(--surface2)'}),
  rule('.hover-border', {'cursor': 'pointer'}),
  rule('.hover-border:hover', {'border-color': 'var(--ink)'}),
  // A grid of cells sharing hairline borders.
  rule('.cell-grid', {
    'display': 'grid',
    'border-top': '1px solid var(--line)',
    'border-left': '1px solid var(--line)',
  }),
  rule('.cell-grid > *', {
    'background': 'var(--surface)',
    'border-right': '1px solid var(--line)',
    'border-bottom': '1px solid var(--line)',
  }),

  // Type
  rule('.page-title', {
    'margin': '0',
    'font-size': '44px',
    'line-height': '1.05',
    'letter-spacing': '-0.03em',
    'font-weight': '600',
  }),
  rule('.section-title', {'margin': '0', 'font-size': '28px', 'font-weight': '600', 'letter-spacing': '-0.02em'}),
  rule('.lede', {
    'margin': '0',
    'font-size': '16px',
    'line-height': '1.5',
    'color': 'var(--muted)',
    'text-wrap': 'pretty',
  }),
  rule('.muted', {'color': 'var(--muted)'}),
  rule('.mono', {'font-family': "'Geist Mono',monospace"}),
  rule('.eyebrow', {
    'font': mono(11),
    'letter-spacing': '0.06em',
    'text-transform': 'uppercase',
    'color': 'var(--muted)',
  }),
  rule('.eyebrow.wide', {'letter-spacing': '0.08em'}),
  rule('.eyebrow.accent', {'color': 'var(--accent)'}),
  rule('.eyebrow.warn', {'color': 'var(--warn)'}),
  rule('.link-more', {'font-size': '14px', 'font-weight': '500', 'cursor': 'pointer'}),
  rule('.tabular', {'font-variant-numeric': 'tabular-nums'}),

  // Pills and badges
  rule('.pill', {
    'font': mono(12),
    'padding': '4px 8px',
    'border-radius': '999px',
    'background': 'var(--surface2)',
    'color': 'var(--ink)',
    'white-space': 'nowrap',
  }),
  rule('.pill.soft', {'background': 'var(--accent-soft)', 'color': 'var(--accent)'}),
  rule('.growth', {
    'font': mono(12),
    'padding': '2px 7px',
    'border-radius': '999px',
    'background': 'var(--accent-soft)',
    'color': 'var(--pos)',
    'white-space': 'nowrap',
    'width': 'fit-content',
  }),
  rule('.health', {
    'font': mono(12),
    'padding': '4px 8px',
    'border-radius': '999px',
    'white-space': 'nowrap',
    'width': 'fit-content',
    'background': 'var(--surface2)',
    'color': 'var(--muted)',
  }),
  rule('.health.active', {'background': 'var(--accent-soft)', 'color': 'var(--pos)'}),
  rule('.health.slowing', {'background': 'var(--slow-bg)', 'color': 'var(--slow-ink)'}),
  rule('.ff-badge', {
    'display': 'flex',
    'align-items': 'center',
    'gap': '5px',
    'font': mono(11),
    'padding': '3px 9px 3px 6px',
    'border-radius': '999px',
    'background': 'var(--accent)',
    'color': 'var(--accent-ink)',
    'white-space': 'nowrap',
  }),

  // Segmented control and chips
  rule('.seg', {
    'display': 'flex',
    'gap': '4px',
    'padding': '4px',
    'background': 'var(--bg)',
    'border': '1px solid var(--line)',
    'border-radius': '2px',
    'width': 'fit-content',
  }),
  rule('.seg > *', {
    'font': sans(13, weight: 500),
    'padding': '7px 12px',
    'border-radius': '2px',
    'cursor': 'pointer',
    'white-space': 'nowrap',
    'background': 'transparent',
    'color': 'var(--muted)',
    'border': '0',
  }),
  rule('.seg > .on', {'background': 'var(--surface)', 'color': 'var(--ink)', 'box-shadow': '0 0 0 1px var(--line)'}),
  rule('.chip', {
    'font': sans(14, weight: 500),
    'padding': '6px 12px',
    'border-radius': '2px',
    'cursor': 'pointer',
    'white-space': 'nowrap',
    'border': '1px solid var(--line)',
    'background': 'var(--surface)',
    'color': 'var(--ink)',
  }),
  rule('.chip.on', {'border-color': 'var(--ink)', 'background': 'var(--ink)', 'color': 'var(--bg)'}),

  // Buttons
  rule('.btn', {
    'height': '44px',
    'padding': '0 20px',
    'border': '1px solid var(--line)',
    'background': 'var(--surface)',
    'color': 'var(--ink)',
    'border-radius': '2px',
    'font-size': '15px',
    'font-weight': '500',
    'cursor': 'pointer',
    'display': 'flex',
    'align-items': 'center',
    'gap': '8px',
    'white-space': 'nowrap',
  }),
  rule('.btn:hover', {'border-color': 'var(--ink)', 'color': 'var(--ink)'}),
  rule('.btn.primary', {'border': '0', 'background': 'var(--accent)', 'color': 'var(--accent-ink)'}),
  rule('.btn.primary:hover', {'filter': 'brightness(0.92)', 'color': 'var(--accent-ink)'}),
  rule('.btn.ink', {'border': '0', 'background': 'var(--ink)', 'color': 'var(--bg)'}),
  rule('.btn.small', {'height': '38px', 'padding': '0 12px', 'font-size': '14px'}),

  // Form controls
  rule('.select', {
    'height': '38px',
    'border': '1px solid var(--line)',
    'background-color': 'var(--surface)',
    'color': 'var(--ink)',
    'border-radius': '2px',
    'font-size': '14px',
    'padding': '0 6px',
  }),

  // Empty states
  rule('.empty', {
    'border': '1px dashed var(--line)',
    'padding': '72px 28px',
    'text-align': 'center',
    'display': 'flex',
    'flex-direction': 'column',
    'gap': '8px',
    'align-items': 'center',
  }),
  rule('.empty b', {'font-size': '16px', 'font-weight': '600'}),
  rule('.empty span', {'font-size': '14px', 'color': 'var(--muted)'}),
];
