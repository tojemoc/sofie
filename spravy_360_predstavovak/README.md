# Spravy 360 - Predstavovak CasparCG Template

CasparCG HTML template generated from Figma node `613:1344`.

## Files

- `index.html` - CasparCG HTML template

The live template has no linked image assets. The panel and blue dot are rendered directly with HTML/CSS.

## Variable Fields

- `name` - main name line
- `title` - subtitle line

The template also accepts aliases:

- `meno` or `f0` for `name`
- `titulok` or `f1` for `title`

## AMCP Examples

Load and play with JSON data:

```text
CG 1 ADD 20 spravy_360_predstavovak/index 1 "{\"name\":\"Peter Pellegrini\",\"title\":\"Prezident Slovenskej republiky\"}"
```

Update while on-air:

```text
CG 1 UPDATE 20 "{\"name\":\"Meno Priezvisko\",\"title\":\"Funkcia alebo popis\"}"
```

Stop:

```text
CG 1 STOP 20
```

## Install

Copy the whole `spravy_360_predstavovak` folder into your CasparCG `template` folder.

Expected path:

```text
CasparCG Server/template/spravy_360_predstavovak/index.html
```

## Fonts

The Figma design uses `Bauplan Heavy` and `Diform Regular`. If those fonts are installed on the CasparCG machine, Chromium should use them. If not, the template falls back to standard system fonts.
