import 'package:jaspr/dom.dart';

import 'css.dart';

/// Design tokens. Components only ever reference these through `var(--…)`,
/// so the lamp can switch themes by flipping `data-theme` on `<html>`.
const _light = {
  '--bg': '#F1F6FC',
  '--surface': '#FFFFFF',
  '--surface2': '#E8F0FA',
  '--ink': '#042B59',
  '--muted': '#4E6584',
  '--line': '#D3E0EF',
  '--accent': '#0468D7',
  '--accent-ink': '#FFFFFF',
  '--accent-soft': '#DCEBFF',
  '--pos': '#0468D7',
  '--warn': '#A86200',
  '--neg': '#C8382B',
  '--slow-bg': '#FBEFD9',
  '--slow-ink': '#8A560A',
  '--hot-bg': '#FFF1E0',
  '--hot-ink': '#C2410C',
  '--stable-bg': '#DDF3EF',
  '--stable-ink': '#0B6B60',
  '--neg-bg': '#FBE4E1',
  '--foot-bg': '#042B59',
  '--metro-1': '#0468D7',
  '--metro-2': '#0B7A6E',
  '--metro-3': '#6E4FE0',
  '--metro-4': '#B8541A',
  '--metro-ink': '#FFFFFF',
  '--logo-ring': '#042B59',
  '--select-arrow': '#4E6584',
};

const _dark = {
  '--bg': '#061A31',
  '--surface': '#0A2340',
  '--surface2': '#102E50',
  '--ink': '#E8F4FF',
  '--muted': '#9AB3CF',
  '--line': '#1C3B5E',
  '--accent': '#54C5F8',
  '--accent-ink': '#042B59',
  '--accent-soft': '#0F3A63',
  '--pos': '#54C5F8',
  '--warn': '#F2B84B',
  '--neg': '#FF8A7A',
  '--slow-bg': '#2E2616',
  '--slow-ink': '#D9A441',
  '--hot-bg': '#3A2410',
  '--hot-ink': '#FFB061',
  '--stable-bg': '#0D3734',
  '--stable-ink': '#5FE0CF',
  '--neg-bg': '#3B1A18',
  '--foot-bg': '#030F1E',
  '--metro-1': '#54C5F8',
  '--metro-2': '#3DD6C4',
  '--metro-3': '#A78BFA',
  '--metro-4': '#F59E57',
  '--metro-ink': '#042B59',
  '--logo-ring': '#E8F4FF',
  '--select-arrow': '#9AB3CF',
};

/// Sets `data-theme` before first paint (saved choice, else the OS setting)
/// and marks the intro as seen for this tab session.
const themeBootScript = '''
(function(){var d=document.documentElement;try{var t=localStorage.getItem('fv-theme');
if(t!=='light'&&t!=='dark'){t=matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light';}
d.dataset.theme=t;if(sessionStorage.getItem('fv-intro'))d.dataset.introSeen='1';}catch(e){d.dataset.theme='light';}})();''';

Styles _frames(Map<String, String> props) => Styles(raw: props);

final globalStyles = <StyleRule>[
  css.import(
    'https://fonts.googleapis.com/css2?family=Geist:wght@400;500;600;700&family=Geist+Mono:wght@400;500;600&display=swap',
  ),
  rule(':root', {..._light, 'color-scheme': 'light'}),
  rule(':root[data-theme="dark"]', {..._dark, 'color-scheme': 'dark'}),
  rule('html, body', {'margin': '0', 'background': 'var(--bg)', 'overflow-x': 'clip'}),
  rule('body', {
    'font-family': "'Geist',system-ui,sans-serif",
    '-webkit-font-smoothing': 'antialiased',
    'color': 'var(--ink)',
    'min-height': '100vh',
  }),
  rule('*', {'box-sizing': 'border-box'}),
  rule('a', {'color': 'inherit', 'text-decoration': 'none'}),
  rule('a:hover', {'color': 'var(--accent)'}),
  rule('select, input, button, textarea', {'font-family': 'inherit'}),
  rule('select', {
    '-webkit-appearance': 'none',
    'appearance': 'none',
    'background-image':
        "url(\"data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 12 12'%3E%3Cpath d='M2.5 4.5 6 8l3.5-3.5' fill='none' stroke='%234E6584' stroke-width='1.5'/%3E%3C/svg%3E\")",
    'background-repeat': 'no-repeat',
    'background-position': 'right 12px center',
    'padding-left': '12px !important',
    'padding-right': '36px !important',
    'cursor': 'pointer',
  }),
  rule('h1, h2, h3, p', {'margin': '0'}),
  rule('::view-transition-old(root), ::view-transition-new(root)', {'animation': 'none', 'mix-blend-mode': 'normal'}),
  rule('::-webkit-scrollbar', {'height': '6px', 'width': '8px'}),
  rule('::-webkit-scrollbar-thumb', {'background': 'var(--line)'}),
  rule('main.page', {'max-width': '1280px', 'margin': '0 auto', 'padding': '42px 28px 120px'}),
  below(640, [
    rule('main.page', {'padding': '32px 16px 96px'}),
  ]),
  ..._keyframes,
];

final _keyframes = <StyleRule>[
  css.keyframes('fvSpin', {
    'to': _frames({'transform': 'rotate(360deg)'}),
  }),
  css.keyframes('fvDraw', {
    'from': _frames({'stroke-dashoffset': '100'}),
    'to': _frames({'stroke-dashoffset': '0'}),
  }),
  css.keyframes('fvShard', {
    'from': _frames({'opacity': '0', 'transform': 'translate(var(--dx),var(--dy)) rotate(var(--r)) scale(.6)'}),
    'to': _frames({'opacity': '1', 'transform': 'none'}),
  }),
  css.keyframes('fvRise', {
    'from': _frames({'opacity': '0', 'transform': 'translateY(70%)'}),
    'to': _frames({'opacity': '1', 'transform': 'none'}),
  }),
  css.keyframes('fvBar', {
    'from': _frames({'transform': 'scaleX(0)'}),
    'to': _frames({'transform': 'scaleX(1)'}),
  }),
  css.keyframes('fvTick', {
    '0%,26%': _frames({'transform': 'translateY(0)'}),
    '33%,59%': _frames({'transform': 'translateY(-1.6em)'}),
    '66%,100%': _frames({'transform': 'translateY(-3.2em)'}),
  }),
  css.keyframes('fvTwinkle', {
    '0%,100%': _frames({'opacity': '.12'}),
    '50%': _frames({'opacity': '.7'}),
  }),
  // One lap of the splash's sun, starting and ending at its resting place
  // (-20.7° on the untilted orbit; see IntroLogo).
  css.keyframes('fvOrbit', {
    'from': _frames({'transform': 'rotate(-20.7deg)'}),
    'to': _frames({'transform': 'rotate(339.3deg)'}),
  }),
  css.keyframes('fvOrbitBack', {
    'from': _frames({'transform': 'rotate(20.7deg)'}),
    'to': _frames({'transform': 'rotate(-339.3deg)'}),
  }),
  css.keyframes('fvFloat', {
    '0%,100%': _frames({'transform': 'translateY(0)'}),
    '50%': _frames({'transform': 'translateY(-6px)'}),
  }),
  css.keyframes('fvOut', {
    'from': _frames({'clip-path': 'circle(150vmax at 50% 44%)'}),
    'to': _frames({'clip-path': 'circle(0px at 50% 44%)'}),
  }),
  css.keyframes('fvShrink', {
    'to': _frames({'transform': 'scale(.55)', 'opacity': '0'}),
  }),
  css.keyframes('fvFade', {
    'from': _frames({'opacity': '0'}),
    'to': _frames({'opacity': '1'}),
  }),
  css.keyframes('fvPop', {
    'from': _frames({'opacity': '0', 'transform': 'translateY(-10px) scale(.97)'}),
    'to': _frames({'opacity': '1', 'transform': 'none'}),
  }),
  css.keyframes('fvItem', {
    'from': _frames({'opacity': '0', 'transform': 'translateY(6px)'}),
    'to': _frames({'opacity': '1', 'transform': 'none'}),
  }),
];
