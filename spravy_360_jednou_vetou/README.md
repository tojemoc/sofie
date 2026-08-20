# Spravy 360 - Jednou Vetou CasparCG Template

CasparCG HTML template generated from Figma node `613:1216`.

## Files

- `index.html` - CasparCG HTML template
- `screenshot.jpg` - test render screenshot

The live template has no linked image assets. All graphics are rendered directly with HTML/CSS.

## Variable Fields

- `kicker` - small upper label, default `SPRÁVY JEDNOU VETOU`
- `headline` - main headline

Aliases:

- `rubrika`, `label`, or `f0` for `kicker`
- `title`, `titulok`, or `f1` for `headline`

## AMCP Examples

Load and play with JSON data:

```text
CG 1 ADD 21 spravy_360_jednou_vetou/index 1 "{\"kicker\":\"SPRÁVY JEDNOU VETOU\",\"headline\":\"Kamenický o konsolidácií Slovenska\"}"
```

Update while on-air:

```text
CG 1 UPDATE 21 "{\"headline\":\"Nový titulok ide sem\"}"
```

Stop:

```text
CG 1 STOP 21
```

## Install

Copy the whole `spravy_360_jednou_vetou` folder into your CasparCG `template` folder.

Expected path:

```text
CasparCG Server/template/spravy_360_jednou_vetou/index.html
```

## Fonts

The Figma design uses `Bauplan Heavy` and `Diform Bold`. Install those fonts on the CasparCG machine for a 1:1 font match. Otherwise Chromium will use the configured fallbacks.
