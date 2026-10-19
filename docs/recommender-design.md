# In Vogue Stylist: the outfit recommender, v2

Design, October 19, 2026. **The catalog is built and live on `in-vogue-dev`; the app doesn't read it yet.**

On October 19 the owner set the architecture: an LLM (Claude) curates the catalog outside the app and stores it in Firestore; the app never decides what weather, occasion or skin colour suits a piece. It **filters** stored outfits by the person's colour season and the day's weather, then **ranks** them by the actual forecast, what the person likes, their wardrobe and what they wore recently. This document records what was built and how the phone side should work. It replaces the earlier proposal of the same day (on-phone outfit generation), whose research and evidence are kept where they still apply.

**Contents**

1. [Summary](#1-summary)
2. [What runs today](#2-what-runs-today)
3. [What goes wrong, with evidence](#3-what-goes-wrong-with-evidence)
4. [How v2 works](#4-how-v2-works)
5. [The curated catalog](#5-the-curated-catalog)
6. [The catalog in Firebase](#6-the-catalog-in-firebase)
7. [The recommender on the phone](#7-the-recommender-on-the-phone)
8. [Learning what a person likes](#8-learning-what-a-person-likes)
9. [Onboarding, Home and the wardrobe](#9-onboarding-home-and-the-wardrobe)
10. [Data in the account](#10-data-in-the-account)
11. [Code layout and integration points](#11-code-layout-and-integration-points)
12. [How we know it works](#12-how-we-know-it-works)
13. [Delivery plan](#13-delivery-plan)
14. [Risks](#14-risks)
15. [Decisions](#15-decisions)
- Appendices: [A. Piece fields](#appendix-a-piece-fields) · [B. How colours got their seasons](#appendix-b-how-colours-got-their-seasons) · [C. The outfit checks](#appendix-c-the-outfit-checks) · [D. Taste features](#appendix-d-taste-features) · [E. Research notes](#appendix-e-research-notes) · [F. Reproducing the evidence](#appendix-f-reproducing-the-evidence) · [G. References](#appendix-g-references)

---

## 1. Summary

### Why today's outfits go wrong

Today a Python script types each product with regular expressions on its title, composes outfits for 96 weather-and-occasion "cells" keyed by the day's **coldest** feels-like hour, and the phone picks from the cell's list. So a 13 → 31 °C day in Denver gets cashmere and corduroy, −22 °C in Chicago gets an unlined viscose trench, `puff` turns two cotton summer dresses into puffer coats, and the skin analysis never reaches an outfit. The evidence is in [§3](#3-what-goes-wrong-with-evidence).

### What v2 is

- **A curated catalog of 500 outfits.** Claude labelled every piece of the shop (623 styles, 1,234 colourways) with the owner's twelve fields, gave each of the 258 colour names its family, pattern and the colour seasons it suits, and put together 500 outfits, each copying the look in its main piece's model photo. Every outfit carries the weathers, occasions and colour seasons it suits, checked by rules ([Appendix C](#appendix-c-the-outfit-checks)).
- **Stored in Firestore** as one document per outfit, with its picture in Storage. A sample of 40 is readable before sign-in for onboarding; the whole catalog is readable once signed in. Nobody writes from the app.
- **On the phone, filter then rank.** One query fetches the outfits that suit the person's colour season in the coldest part of the day. The phone drops those that don't fit the occasion, the day's warm hours or the rain, scores the rest on how well they fit the day, what the person likes, freshness and rest, and picks with the owner's rule (never-suggested first). No model runs on the phone and nothing is trained.
- **Learning without training.** Onboarding picks, favourites and Buy taps update a small Bayesian taste model (about 45 numbers) that raises the weight of similar outfits without making them the only ones.

### What changes for the person

| Today | v2 |
| --- | --- |
| Cashmere and corduroy on a 31 °C afternoon because 07:00 was 13 °C | The outfit must suit the coldest hours with its layer on and the warmest with the layer off |
| The same outfits at 7 °C and at −22 °C | Cold (0–8 °C) and Freezing (below 0 °C) are separate weathers; Freezing outfits all have a warm coat |
| A cotton gauze dress tried on as a coat, a shirt as shorts | Every piece was looked at and labelled by hand, with its photos checked where the shop's text was unclear |
| The skin analysis shown on Mirror only | Outfits are filtered by the person's colour season: the top or dress suits it, and so do the skirt or trousers when they aren't a neutral colour |
| Loved pieces nudge the rank a little | Liked outfits and outfits like them weigh more; variety stays |
| 43% of the collection ever appears | The 500 outfits use 59% of colourways and 71% of styles; every outfit can be chosen |

### Cost

- **Firestore:** one query per made day of about 15–120 small documents (3 KB each), cached per catalog version, plus 40 reads at onboarding and 20 per Home page.
- **Storage:** 500 pictures, 36 MB in all (about 75 KB each).
- **YouCam:** unchanged at 2 units a pass. Outfits take 1 pass (108 dresses), 2 (250) or 3 (142, with a layer). Nothing caps or counts units.

---

## 2. What runs today

```
BUILD TIME (resources/, Python)
  Shopify Global Catalog pull ─► pull_catalog.py  regex on title + specs → kind, category, warmth bands, occasions
                              ─► build_outfits.py  96 cells × ≤100 outfits, hand-tuned scores (styling.v1.json)
                              ─► scripts/export_catalog.py, export_outfits.py
                              ─► assets/catalog/everlane_women.json (560 KB), assets/outfits/outfits.json (3.6 MB)

PHONE (lib/, Dart)
  Open-Meteo, 7 hourly fields, 3 days
   ─► DayWeatherRules.classify   band of the window's COLDEST feels-like; dry | wet | snow; calm | windy
   ─► WeatherClass.cell(occasion) e.g. "cool|dry|windy|work"
   ─► OutfitRepository.outfitsFor(cell)          the knowledge base's order
   ─► ChooseOutfit.from   0.8 × (1 − rank/n) + 0.2 × share of loved pieces; refused pieces out;
                          never-suggested first, else suggested longest ago
   ─► MakeOutfit          claim the Day (Firestore transaction), try on 1–3 passes, keep the picture
```

| Step | Where | Fact |
| --- | --- | --- |
| Garment kind | `resources/tools/catalog/pull_catalog.py:302` | First match of 16 regexes over the lower-cased title; `puff` is the puffer pattern (`:303`) |
| Warmth bands | `pull_catalog.py:418` | Rules per kind; "warm" = any of 21 keywords in title + tech specs + top features (`:324`) |
| Outfit cells | `resources/tools/kb/build_outfits.py:132` | `fits_weather` checks one band; `weather.v1.json` is loaded (`:22`) but never read |
| Hourly fields | [weather_remote_data_source.dart:21](../lib/features/weather/data/data_sources/weather_remote_data_source.dart#L21) | temperature, apparent temperature, precipitation probability and amount, snowfall, weather code, gusts |
| Windows | [day_weather_rules.dart:17](../lib/features/weather/domain/services/day_weather_rules.dart#L17) | Work 07–19, casual and staying in 09–20, going out 18–23 |
| Cell band | [day_weather_rules.dart:71](../lib/features/weather/domain/services/day_weather_rules.dart#L71) | `WarmthBand.forFeelsLike(coldest)`; `warmest` is computed (`:75`) and never reaches the cell |
| Default occasion | [occasion.dart:9](../lib/core/domain/entities/occasion.dart#L9) | Mon–Fri work, Sat–Sun casual; the person can Change it on Home |
| Choice | [choose_outfit.dart:17](../lib/features/outfits/domain/services/choose_outfit.dart#L17) | Rank 0.8, loved share 0.2; never-suggested first |
| Claim | [make_outfit.dart:344](../lib/features/outfits/domain/services/make_outfit.dart#L344) | Reads the cell's list (`:363`), the suggestion ledger, refused pieces and picks, then `ChooseOutfit.from` (`:374`) |
| Try-on passes | `build_outfits.py:240` | Dress (full_body), then bottom (lower_body), then top (upper_body), then one layer (outer); reference = the piece's worn photo |
| Skin analysis | [season_rules.dart:58](../lib/features/colours/domain/services/season_rules.dart#L58) | One of 12 seasons with a palette of 12 + 6 neutrals + 4 to avoid (`:134`); read by Mirror only |
| Wardrobe | [wardrobe_outfit.dart:31](../lib/features/wardrobe/domain/entities/wardrobe_outfit.dart#L31) | Name, colours, bands, rain, occasions; read by Mirror only |
| Wishlist | `users/{uid}/wishlist/{colourwayId}` | Loved pieces, by colourway id |

---

## 3. What goes wrong, with evidence

Measured on the shipped assets, the catalog build and Open-Meteo's hourly history ([Appendix F](#appendix-f-reproducing-the-evidence)).

| # | Defect | Evidence | How v2 answers it |
| --- | --- | --- | --- |
| D1 | **A day is its coldest hour** | Across 500 city-days (8 cities, Aug 17 – Oct 18, 2026) the work window's coldest and warmest feels-like fall in different bands on **85%** of days, ≥2 bands apart on **37%**. Denver, Sep 3: 13.1 → 31.4 °C → cashmere cardigan + corduroy trouser + tailor-twill blazer. | The outfit must suit the cold band with its layers and the warm band without them ([§7.3](#73-candidates)) |
| D2 | **Open-ended extremes** | Chicago, Jan 20, 2026, −22 °C → cardigan + corduroy + unlined viscose trench. Shanghai, Aug 5, 41 °C → "Cozy Rib Button-Up". | Six weathers with Freezing below 0 °C; Freezing outfits need a warm coat; Hot outfits only light pieces |
| D3 | **Garment type by keyword** | Two puff-sleeve cotton dresses typed puffer and tried on as coats; "The Way-Short Shirt" typed shorts (17 outfits); a denim shirt and tunic typed jeans | Every piece labelled by hand; the photo checked when the text was unclear |
| D4 | **Warmth by marketing words** | "brushed twill fabric" made a viscose trench a cold-weather coat; cashmere tanks banded hot | Weather from fabric, weight, length and layering, by hand |
| D5 | **Staying in ignores the weather** | Linen trousers in `cold\|*\|staying_in` | Staying-in outfits are lounge pieces labelled for the indoor day |
| D6 | **Wind and rain barely matter** | 38 of 48 calm/windy top-10 pairs identical | Every piece has rain (good / fine / avoid) and wind (fine / avoid); outfits carry both |
| D7 | **No dresses when it's hot** | 0 dress outfits in the hot casual and going-out top 10s | 108 dress outfits, 81 of them for Hot |
| D8 | **Most of the collection never shows** | 43% of colourways in any outfit | 59% of colourways, 71% of styles, every outfit selectable |
| D9 | **Skin analysis and wardrobe unused** | Mirror only | Season filter; wardrobe as a candidate and a taste signal |
| D10 | **Loved pieces barely matter** | At most a quarter of the list | A learned taste term ([§8](#8-learning-what-a-person-likes)) |
| D11 | **A made day never changes** | `ready` kept whatever the forecast does | Unchanged by this design: a new outfit after a forecast change is offered, never made automatically ([§15](#15-decisions)) |
| D12 | **Generic, sometimes false reasons** | "for a cool, windy workday" on a 31 °C afternoon | Reasons from the day's facts and the outfit's fields ([§7.7](#77-saying-why)) |
| D13 | **Forecast licence** | Open-Meteo's free endpoint is non-commercial | Their API-key plan before production |

---

## 4. How v2 works

```
OFFLINE (resources/, Claude + Python; reruns when the catalog changes)
  shop pull ─► Claude labels every piece (styles.v2.tsv) and colour (colours.v2.tsv)
            ─► Claude puts together 500 outfits from the model photos (outfits.v2.tsv)
            ─► curate_*.py check every row against the rules as it is added
            ─► build_outfit_catalog.py: re-check, join with the shop data → outfits.v2.json
            ─► upload_outfit_catalog.py (development admin key): pictures → Storage, documents → Firestore

FIREBASE (in-vogue-dev)
  outfits/{id}         one document per outfit; the 40 with sample = true readable signed out
  catalog/outfits      version, count, the onboarding sample's ids
  Storage catalog/v2/  sample/ pictures public; outfits/ pictures for signed-in people

PHONE
  onboarding  ─► the weather, then the 40 sample outfits (the same for everyone) ─► picks → wishlist + taste
  Home        ─► the whole catalog, paged by `order`, the weather chips as filters ─► favourites → wishlist + taste
  today / tomorrow:
    forecast + occasion ─► the day's cold and warm bands, rain, wind
    colour reading      ─► season
    one query: outfits where fits contains "season|cold band"
    ─► hard filters (occasion, warm hours, rain, refused pieces)
    ─► score (weather fit, protection, dressiness, taste, rest, freshness)
    ─► choose (never-suggested first above a quality floor; seeded exploration)
    ─► claim the Day ─► try-on passes ─► picture
  wardrobe outfits: filtered and scored the same way, shown in their own place
```

---

## 5. The curated catalog

### 5.1 Who decides what

| Decision | Made by | Where it lives |
| --- | --- | --- |
| What a piece is, how it's worn, its weathers, warmth, rain, wind, occasions, dressiness, style, fit, shape, fabric | Claude, piece by piece, checking photos when the shop's text was unclear | `resources/catalog/curation/styles.v2.tsv` |
| A colour's family, neutral or not, pattern, and the colour seasons it suits | Claude, per colour name, cross-checked against the app's season palettes | `colours.v2.tsv` |
| Which pieces make an outfit, its weathers and occasions | Claude, from each main piece's model photo | `outfits.v2.tsv` |
| An outfit's colour seasons | The curation rule in `curate_outfits.py` ([§5.4](#54-outfits)), stored with the outfit | `outfits.v2.tsv`, then Firestore |
| The onboarding sample | Claude, for variety, from outfits whose picture shows exactly the outfit | `onboarding.v2.txt` |
| What the person wears today | The phone, from the stored fields: it filters and ranks, never re-labels | — |

Garment categories are internal only (owner, October 19): nothing on screen names them.

### 5.2 Pieces

All 623 styles are labelled with the owner's field list of October 19 ([Appendix A](#appendix-a-piece-fields)). Confidence is high for 506, medium for 115 (mostly material not given), low for 2. Conventions applied throughout:

- **Weathers** are Hot (≥26 °C feels-like), Warm (20–26), Mild (14–20), Cool (8–14), Cold (0–8), Freezing (below 0). A piece lists **every** weather it can be worn in, layered if needed: a plain tee goes from Hot to Freezing because it can sit under a coat.
- **Bare legs only** for skirts, dresses and shorts (owner): they reach Mild at most, Cool only for maxis that cover the legs. Sweater dresses are therefore Mild-only.
- **Fabric sets the range of full-length trousers:** linen and crinkle viscose Hot–Mild; lyocell and light crepe Hot–Cold; cotton twill, denim and ponte Warm–Freezing; wool, corduroy and fleece Mild–Freezing.
- **Outerwear:** blazers reach Cold and Freezing only under a coat; trenches and macs Mild–Cool; wool coats Cool–Cold (Freezing when long and heavy); puffers Cool–Freezing.
- **Occasions** are ticked: Work, Casual, Going out, Event, Staying in, Active. Event needs dressy 4 or 5.
- **Fixes of today's typing**, among others: the puff-sleeve dresses are dresses, the Way-Short Shirt a long-sleeved cropped shirt, the denim shirt and tunic shirts, the Drapey Twill Trench Mild–Cool, the cashmere and merino tanks lose Hot.

### 5.3 Colours

Each of the 258 colour names has a family (black, white, cream, grey, beige, brown, navy, blue, green, olive, yellow, orange, red, pink, purple), a second family for stripes, checks and prints, neutral or not (184 are neutral), a pattern (214 plain, 36 striped, 6 checked, 5 printed) and the colour seasons it suits. Three colourways carry their own row because their colour differs from what their name usually means (a periwinkle sweater named "Blue", a plain henley named like a stripe, a striped polo named "Snow").

Seasons were judged by each colour's character (how light, how warm, how clear) and then cross-checked against the app's own season palettes with CIEDE2000, adding a season where the palette holds a near-identical colour and removing one where the colour sits next to that season's "avoid" list ([Appendix B](#appendix-b-how-colours-got-their-seasons)). The photos settled colours the shop's measurements got wrong:

- **71 colourways had no measured colour**; the current exporter fills them with a family average (Heather Wine shows as grey, Heathered Pine as grey-green). The catalog build gives them their name's typical measured colour, or one read off the photos.
- **Blues measured from flat-lays read far too dark**: Klein Blue and Estate Blue are vivid royal blues when worn.

### 5.4 Outfits

500 outfits: 108 dresses or jumpsuits, 249 tops with bottoms, 143 with a layer (108 of them a coat or jacket). Each outfit's **picture is its main piece's model photo** and its other pieces **copy what the model wears** when the shop sells them (owner). Where the outfit departs from the photo, its note says how:

- **365 outfits match their photo exactly.**
- **A colour swap** on 16 outfits: a close colour for the photo's, e.g. an oat tee for the white one under a brown puffer. The picture still reads true.
- **A coat added for cold days** on 50 knit looks (the owner kept them), so they can be worn on Cold and Freezing days. The picture shows the knit look; the try-on includes the coat.
- **Leggings or bike shorts for Active** on the five racerback tanks, and a silk cami for three event looks whose photo shows a sweater.
- **A layer added under** blazers and coats worn closed on bare skin, since try-on needs a top.

Every outfit was checked as it was added ([Appendix C](#appendix-c-the-outfit-checks)). In short:

- **Weathers:** within every piece's weathers; Cold and Freezing need a coat or jacket (a warm one for Freezing) unless the outfit is only for staying in; Hot takes only light pieces.
- **Occasions:** Event, Active and Staying in need every piece made for them. Work and Going out need one piece made for them and no lounge- or sport-only piece; Work also needs the outfit to average dressy 2, so a blazer lifts a tee and jeans to work but a tee and jeans alone stay casual.
- **Colour seasons** (owner, October 19): an outfit suits a season when its top or dress suits it, and its skirt or trousers too when their colour isn't neutral. A coat, jacket or cardigan worn over the top doesn't count, so a coat outside the person's palette can be recommended to them. Outfits suit 1–8 seasons, most of them 3 or 4, and every season has at least 103 outfits.

### 5.5 The onboarding sample

40 outfits (owner: 30 to 50), not personalised, chosen for variety from the 365 whose picture shows exactly the outfit: 10 dresses, jumpsuits or overalls, 30 separates with and without layers; all 15 colour families; all six weathers and every occasion. Picking is optional; picks go to the wishlist and the taste model.

### 5.6 Coverage

Outfits per colour season, by weather and by the app's occasions (an outfit counts in every cell it suits):

| Season | Hot | Warm | Mild | Cool | Cold | Freezing | Work | Casual | Going out | Staying in |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Light Spring | 21 | 40 | 75 | 55 | 26 | 13 | 42 | 100 | 60 | 4 |
| True Spring | 25 | 53 | 95 | 58 | 25 | 14 | 57 | 115 | 65 | 6 |
| Bright Spring | 38 | 90 | 149 | 87 | 29 | 21 | 84 | 177 | 87 | 6 |
| Light Summer | 33 | 83 | 140 | 92 | 32 | 21 | 74 | 168 | 87 | 6 |
| True Summer | 32 | 83 | 146 | 85 | 28 | 22 | 92 | 165 | 77 | 8 |
| Soft Summer | 33 | 79 | 159 | 109 | 48 | 33 | 107 | 190 | 98 | 11 |
| Soft Autumn | 32 | 59 | 107 | 81 | 37 | 21 | 66 | 141 | 72 | 10 |
| True Autumn | 30 | 57 | 108 | 73 | 24 | 15 | 57 | 137 | 66 | 8 |
| Dark Autumn | 72 | 130 | 231 | 140 | 33 | 21 | 119 | 262 | 151 | 14 |
| Dark Winter | 70 | 142 | 255 | 148 | 31 | 23 | 137 | 275 | 155 | 9 |
| True Winter | 67 | 137 | 235 | 140 | 32 | 25 | 129 | 257 | 141 | 9 |
| Bright Winter | 66 | 134 | 197 | 103 | 22 | 15 | 96 | 211 | 119 | 8 |

No season-and-weather cell is empty. The thinnest are Freezing days: Light Spring has 13 outfits, True Spring 14, True Autumn and Bright Winter 15. Black dominates the shop (314 of 1,234 colourways), so winter seasons and Dark Autumn have the most outfits.

### 5.7 Files and tools

All in `resources/` (the workspace, not the app repository):

| File | What |
| --- | --- |
| `catalog/curation/styles.v2.tsv` | 623 styles × 18 fields |
| `catalog/curation/colours.v2.tsv` | 261 colour rows (258 names, 3 colourway overrides) |
| `catalog/curation/outfits.v2.tsv` | 500 outfits: main photo, pieces with roles, weathers, occasions, seasons, name, note |
| `catalog/curation/onboarding.v2.txt` | The 40 sample ids |
| `catalog/firestore/outfits.v2.json` | The built documents (1.5 MB) |
| `tools/catalog/curate_view.py` | Cards per batch, the colour list, `--find` over colourways |
| `tools/catalog/curate_add.py` | Check and add piece rows; `--colours` for colour rows |
| `tools/catalog/curate_outfits.py` | Check and add outfits (`add`), coverage tables (`report`) |
| `tools/catalog/build_outfit_catalog.py` | Re-check everything, join with the shop data, write the documents |
| `tools/catalog/upload_outfit_catalog.py` | Pictures to Storage, documents to Firestore; dry run unless `--apply`; development project only |

Changing the catalog: edit or add rows with the curation tools (they refuse anything that breaks a rule), rebuild, then upload with `--apply --prune`. Ids are stable; a picture whose source changes gets a new path, so phones never show a stale cached one.

---

## 6. The catalog in Firebase

### 6.1 Documents

`outfits/{id}`, one per outfit (about 3 KB):

| Field | Example | For |
| --- | --- | --- |
| `id`, `version` | `"o0181"`, `2` | — |
| `order` | `389` | Home's paging: a stable mixed order, 0 to 499 |
| `name` | `"Herringbone wool coat, mocha alpaca cardigan, brown corduroy trousers"` | Display |
| `sample` | `false` | Onboarding; rules |
| `image` | `{path: "catalog/v2/outfits/o0181-1f0c9d2e.jpg", source: <shop photo>, url: <download link>}` | Display: the app loads `url`, a Storage download link the upload script makes |
| `weathers` | `["cool","cold","freezing"]` | Filter |
| `baseWeathers` | `["mild","cool","cold","freezing"]` | The outfit with its layers off, for swing days |
| `seasons` | `["softSummer","softAutumn"]` | Filter |
| `occasions` | `["work","casual","out"]` | Filter |
| `fits` | `["softSummer\|cool", …]` | The one query: every season × weather pair |
| `families`, `styles`, `kinds` | `["beige","brown"]`, `["classic","minimal",…]`, `["cardigan","trousers","coat"]` | Taste |
| `dressy`, `warmth` | `3.0`, `10` | Occasion fit; warmth within a band |
| `rain`, `wind`, `coat` | `"fine"`, `"fine"`, `true` | Protection |
| `pieces` | `[{colourway, style, name, colour, hex, family, accent, pattern, neutral, role, kind, weathers, warmth, dressy, styles, fibre, shape, length, rain, wind, url, photo}]` | Display, Buy, try-on, refused pieces, taste |
| `passes` | `[{category: "lower_body", piece, reference}, …]` | Try-on, as `Outfit.passes` today |
| `retailer` | `"everlane"` | — |
| `updatedAt` | server time | — |

No prices anywhere (product rule). `catalog/outfits` holds `{version, count, sample: [ids in order], updatedAt}`.

### 6.2 Pictures

`catalog/v2/sample/{id}-{fingerprint}.jpg` for the 40 sample outfits, `catalog/v2/outfits/{id}-{fingerprint}.jpg` for the rest: the main photo resized to at most 1200 pixels wide, metadata stripped, cached for a year (the fingerprint changes when the picture does).

### 6.3 Rules

| Who | Can |
| --- | --- |
| Anyone | Read sample outfits, `catalog/outfits` and sample pictures |
| A signed-in person | Read every outfit and picture |
| Nobody, from the app | Write, change or delete any of it |

Firestore lets a signed-out query list outfits only when it asks for `sample == true`. Checked on the emulators (`scripts/check_firestore_rules.py`, 49 cases; `scripts/check_storage_rules.py`, 17 cases), deployed to `in-vogue-dev` on October 19, and checked again on the live project signed out: the sample outfits and pictures load, everything else is refused.

### 6.4 The app's reads

The app keeps a copy of the catalog on the phone (`catalog/outfits.json`) and reads Firestore only to refresh it:

| When | Read | Reads |
| --- | --- | --- |
| Once a run of the app | `catalog/outfits`, for its `version` | 1 |
| Before sign-in, when the copy is older or missing | `outfits.where('sample', isEqualTo: true)` (the rules allow a signed-out list only so) | 40 |
| After sign-in, when the copy is older or holds only the sample | `outfits` | 500 |

Everything else reads the copy: setup's 40 sample outfits in `order`; Home's catalog, 20 a page by `order`; the weather chips (`weathers` contains the chip; Rain: `rain == 'good'`); Your picks; and the recommender's candidates, which are the copy's outfits whose `fits` hold `season|coldBand` (or whose `weathers` hold `coldBand`, with no clear colour reading). So a day costs no reads, no composite index is needed, and offline the copy still answers. Pictures load from `image.url` and are cached on the phone.

---

## 7. The recommender on the phone

### 7.1 Inputs

| Input | Source | Use |
| --- | --- | --- |
| Hourly feels-like, rain, gusts | Open-Meteo (today's fields) | The day's bands, rain, wind |
| Occasion | Weekday default, Change on Home | Window, filter, dressiness target |
| Colour season | `ColourReading.season`, only when the reading is `clear` | The query; an unclear reading is ignored like a missing one (owner) |
| Taste | `users/{uid}/stylist/state` | Taste term |
| Wishlist | `users/{uid}/wishlist` | Taste signals |
| History | `users/{uid}/suggestions`, `days` | Freshness, rest |
| Refused pieces | The ledger, as today | Filter |
| Wardrobe | `users/{uid}/wardrobe` | Candidates in their own place; colour taste |

### 7.2 The day

For the occasion's window (work 07–19, casual 09–20, going out 18–23, as today), each hour's feels-like falls in a weather band. `DayWeatherRules.bands` gives them as `DayBands`.

- **Cold band** `c`: the band of the coldest hour. **Warm band** `w`: of the warmest.
- **Staying in:** one band from the mean feels-like over 09–20, held between Cool and Warm (homes are heated and cooled).
- **Rain:** any window hour with ≥ 0.5 mm at ≥ 50% probability, or a rain code. **Snow:** snowfall or a snow code. **Windy:** gusts ≥ 39 km/h.
- **Where the day sits in its band**, 0 (the band's cold end) to 1 (its warm end), for ranking by warmth.

Denver, September 3 (work, 13 → 31 °C): `c` = Cool, `w` = Hot. Chicago, January 20 (−22 °C): `c` = `w` = Freezing.

### 7.3 Candidates

1. **Query** `fits` for `season|c`: every outfit that suits the person's colours in the day's coldest hours, coat included.
2. **Occasion:** keep outfits whose `occasions` include the day's.
3. **Warm hours:** when `w` is warmer than `c`, keep outfits whose `weathers` or `baseWeathers` include `w`: they suit the warm hours as they are, or once the layer comes off.
4. **Rain:** on a rainy day drop `rain: avoid` (silk, suede); on a snowy day drop outfits with bare legs.
5. **Refused pieces** out, as today.
6. **Relaxation**, when nothing is left: drop step 3, then step 4, and say so in the reason ("Nothing in the catalog spans 13 to 31°: dress for the morning and carry the layer"). Step 1 never relaxes; with no reading, or an unclear one, the query uses weather alone.

Denver gets outfits like o0004 (black blazer, white shirt, light jeans): Cool with the blazer, and with it off the shirt and jeans suit Warm. Chicago gets Freezing outfits, every one with a warm coat.

### 7.4 Scoring

Each term is 0–1; `U = Σ wₖ·sₖ`. The weights live in `StylistWeights`. The weather term is 0.8 × the share of the day's bands covered plus 0.2 × the warmth placement (placement at 0.4 outweighed what the person likes); on a wet and windy day the protection term is the mean of its rain and wind parts.

| Term | Weight | Reads |
| --- | --- | --- |
| Weather fit | 3.0 | Share of the day's bands (from `c` to `w`) the outfit covers with `weathers` ∪ `baseWeathers`; plus warmth placement: on the band's cold end prefer the warmer candidates (the outfit's `warmth` percentile among candidates against 1 − the day's position) |
| Protection | 1.5 | Rainy: rain `good` 1, `fine` 0.5. Windy: wind `fine` 1, `avoid` 0.2. Otherwise 1 |
| Dressiness | 1.0 | `exp(−(dressy − target)²/2)`, targets: staying in 1, casual 2, work 3, going out 3 |
| Taste | 2.0 | The taste model's draw for this outfit ([§8](#8-learning-what-a-person-likes)), mapped to 0–1 |
| Rest | 1.0 | 1 − the largest recency of its pieces in the last 14 days of made days (4-day half-life; plain neutrals rest half as long) |
| Freshness | ordering | Not a score: the owner's rule in [§7.5](#75-choosing) |

Taste is a fifth of the weight at most, so a liked look wins only among outfits that already suit the day: "higher weight, not always these" (owner).

### 7.5 Choosing

1. **Acceptable set:** outfits scoring within 15% of the day's best (owner, October 19).
2. **The owner's rule:** take the acceptable outfit never suggested; if every one was, the one suggested longest ago (a time still being written counts as now). Ties break on `U`, then on `id`.
3. **Seeded exploration:** the taste draw uses a seed of account, date and occasion, so every phone picks the same outfit and the claim transaction rarely conflicts.
4. **Alternatives:** an MMR re-rank (λ = 0.7) keeps 3–5 different runners-up for "Other outfits" when the owner designs it.

### 7.6 Today and tomorrow

Each day uses its own forecast and occasion and claims its own Day document, as today. Tomorrow's outfit avoids today's pieces through the rest term.

### 7.7 Saying why

From facts the phone computed and fields the outfit carries, through templates in the three languages, e.g.:

- "13° at 7, 31° by 3: the blazer comes off by noon." (swing: `w` in `baseWeathers`)
- "Rain from 4 pm: a water-resistant anorak." (rain `good`)
- "Freezing all day: a warm coat over cashmere." (Freezing)
- "In your Soft Autumn colours." (the season filter)

The copy is the owner's to review.

---

## 8. Learning what a person likes

### 8.1 Signals

| Signal | Label, weight |
| --- | --- |
| Outfit picked at onboarding (goes to the wishlist) | +1, 1.0 |
| Favourite added on Home | +1, 0.8 |
| Favourite removed | −1, 0.4 |
| Buy tapped | +1, 0.5 |
| A made day kept (not replaced) | +1, 0.2 |
| "Another one" (when the owner adds it; spends units) | −1, 0.7 |
| Wardrobe outfit added | its colour families only, +1, 0.3 |

### 8.2 The model

A Bayesian linear model over about 45 outfit features ([Appendix D](#appendix-d-taste-features)): colour families, patterns, styles, shapes (dress, skirt, jeans, wide leg…), dressiness and a bias. With weight `ω` and label `y` for features `x`:

```
Prior:   Λ = I / 0.5²,  b = 0
Update:  Λ ← Λ + ω·x·xᵀ      b ← b + ω·y·x      μ = Λ⁻¹·b
Score:   θ·x, with θ ~ N(μ, Λ⁻¹) drawn from the day's seed (exploration), or θ = μ in tests
```

Outfits **similar** to a liked one share its features, so they score higher too: this is how onboarding picks shape the first outfits. The prior keeps every weight small until evidence builds, and the draw keeps exploring, so liked styles gain weight without crowding out the rest. Updates take microseconds; nothing is trained.

### 8.3 Where it lives

`users/{uid}/stylist/state` holds the signals themselves (`{version, signals: [{id, kind, at, outfit, families}]}`), not `Λ` and `b`: the phone rebuilds the model from them against the catalog it has, in microseconds, so a catalog change re-reads every signal, and two phones merge by union (`arrayUnion`; each signal has an id). The phone keeps its copy in Hive (`taste_signals`); a signal goes to the account at once when someone is signed in, and every account save takes along any that didn't. Sign-in adds the account's signals to the phone's. The existing rules give each person only their own `users/{uid}/**`. Log out clears only the phone's copy, so it comes back at the next sign-in; Delete account deletes the document with the account. The draw uses a seed of the account, the date and the occasion (FNV-1a, the same on every phone).

---

## 9. Onboarding, Home and the wardrobe

- **Onboarding, setup's picks step (before sign-in):** the weather stays at the top, as now. Below it, the grid shows the 40 sample outfits in `order`, the same for everyone and independent of the weather, because the picks record the person's general taste in clothes. The person may pick any number, or skip. Picks are kept on the phone and, at sign-in, written to the wishlist and the taste model, like today's setup picks.
- **Home, the Outfits tab (signed in):** the whole catalog, 20 a page by `order`. The weather chips stay as filters: Hot, Warm, Mild, Cool, Cold, Freezing and Rain (outfits good in rain). The tab opens on all outfits, and tapping a chip narrows the list to that weather; an outfit appears under every weather it suits. A heart toggles the outfit on the wishlist.
- **Tapping an outfit** (in setup or on the Outfits tab) opens the existing Shop screen for it, which lists each piece with its photo, colour name and swatch, material and a Buy link.
- **The wardrobe:** the person's own outfits carry their bands, rain and occasions. They are filtered by occasion and by `c` and `w` like catalog outfits, with no season filter (they are the person's own clothes, and the app judges no colours) and no try-on. Home shows one for today and one for tomorrow at the bottom of the Today and Tomorrow tabs (owner). Their colour families also feed the taste model lightly.

---

## 10. Data in the account

| Document | Change |
| --- | --- |
| `users/{uid}/wishlist/{id}` | Holds outfits: id `o0001…`, `{addedAt}`. |
| `users/{uid}/days/{date}_{occasion}` | Holds `outfitId` (the catalog id), `reason` facts and the day's `c`, `w`, rain and wind. |
| `users/{uid}/suggestions/{id}` | Keyed by the catalog outfit id. |
| `users/{uid}/stylist/state` | New ([§8.3](#83-where-it-lives)). |

The app is in development, so nothing is migrated (owner). The old system's records in `in-vogue-dev` are deleted with the admin key: the wishlist entries of single pieces, the days, suggestions and try-on records it made, and their pictures. Accounts, face and body photos, colour analyses and wardrobe outfits stay.

Log out clears only the phone's copy of the taste state, so it comes back at the next sign-in; Delete account deletes it from the account with everything else.

---

## 11. Code layout and integration points

The catalog lives in the existing `lib/features/catalog` (built October 19): `CatalogOutfit`, `OutfitCatalogRepository` with its phone copy, `GetSampleOutfits`, `GetCatalogPage`, `GetOutfits`, `GetOutfitShop`, and the picks. The recommender is a new feature, `lib/features/stylist`, in the house style:

```
lib/features/stylist/
  domain/
    entities/   day_bands.dart, taste_state.dart
    services/   day_band_rules.dart, candidate_rules.dart, outfit_scorer.dart, outfit_chooser.dart,
                reason_rules.dart, taste_model.dart
    repositories/ taste_repository.dart
    usecases/   recommend_outfit.dart, record_signal.dart
  data/
    data_sources/ taste_*_data_source.dart
    models/       taste_state_model.dart
    repositories/ taste_repository_impl.dart
  di/init.dart
```

| Place | Change |
| --- | --- |
| [make_outfit.dart:344](../lib/features/outfits/domain/services/make_outfit.dart#L344) `_claim` | `outfitsFor(cell)` and `ChooseOutfit.from` become `RecommendOutfit` |
| `Outfit` / `TryOnPass` | Built from `CatalogOutfit.passes`; the try-on is unchanged |
| [day_weather_rules.dart](../lib/features/weather/domain/services/day_weather_rules.dart) | Also gives the six-band `c`, `w`, rain, snow and wind per occasion window |
| `WarmthBand` | Five bands → six (Cold splits into Cold and Freezing at 0 °C), here and in the wardrobe's band picker |
| Setup | The picks step keeps the weather at the top and shows the 40 sample outfits below it instead of pieces |
| Home | The Outfits tab shows outfits instead of pieces, with the weather chips as filters (six weathers and Rain); tapping an outfit opens the Shop screen; the person's own outfit for the day sits at the bottom of the Today and Tomorrow tabs |
| `LogOut`, `DeleteAccount` | Log out clears the phone's copy of the taste state; Delete account deletes it from the account |
| `in-vogue-dev` | The old system's records are deleted once Home runs on the recommender ([§10](#10-data-in-the-account)) |
| Removed after the switch | `ChooseOutfit`, `OutfitAssetDataSource`, `OutfitsModel`, `assets/outfits/outfits.json`, `scripts/export_outfits.py`, `resources/tools/kb/build_outfits.py`, their tests and docs |

**Shadow mode (development builds):** a hidden panel shows, for today and tomorrow, today's choice next to v2's top three with their scores and reasons, and runs fixed days (Denver, Chicago, Shanghai). It spends no units.

---

## 12. How we know it works

1. **Rule tests (Dart):** seeded random days from −30 to 42 °C, with swings, rain, snow and wind, for every occasion and season: the chosen outfit always has the occasion, the cold band, the warm band (as is or without its layer), no `rain: avoid` in rain, and no bare legs in snow.
2. **Golden days:** Denver Sep 3, Berlin Sep 26, New York Aug 26, Chicago Jan 20 and Shanghai Aug 5, with expected outfits reviewed once by the owner.
3. **A year's simulation:** ten cities, a year of hourly weather, every season and occasion. Targets: no rule broken; no outfit repeated within 30 days per season, city and occasion where the cell holds ≥ 30 outfits; the most-used outfit ≤ 5% of a city-year; mean passes no higher than today's.
4. **The owner's look:** shadow mode on the phone, and the coverage report ([§5.6](#56-coverage)) after every catalog change.

Built October 19 (`test/features/stylist/`): the rule tests ran 400 seeded random days (−30 to 42 °C) for every occasion and the 12 seasons and none, 20,800 choices; the five real days come from Open-Meteo's archive; the year is October 2025 to September 2026 in Denver, Chicago, New York, Seattle, London, Berlin, Moscow, Dubai, Shanghai and Sydney (`test/fixtures/weather_year.json.gz`, from `scripts/fetch_weather_year.py`), on the real catalog (`test/fixtures/catalog_v2.json.gz`, from `scripts/export_catalog_fixture.py`). The year's results, over 189,800 choices (10 cities × 365 days × 4 occasions × 13 colour settings):

| Target | Result |
| --- | --- |
| No rule broken | Met: every day had an outfit, and none broke a rule |
| Rules given up only when nothing meets them | The warmest hours on 549 days, rain or snow on 176 (0.4% in all), each said in the reason |
| No repeat within 30 days where the cell holds ≥ 30 outfits | 431 repeats on the 62,117 days with 30 or more candidates (0.7%), each when fewer than 30 scored within 15% of the day's best (the owner's rule) |
| The most-used outfit ≤ 5% of a city-year | Not met in 212 of the 520 city, season and occasion runs: a day has 30.4 candidates on average (Work 24.3, Casual 55.0, Going out 36.3, Staying in 6.0), fewer than 30 on 67% of days, where outfits repeat within 30 days |
| Mean passes no higher than today's | 2.30 against 2.54 |

---

## 13. Delivery plan

Each phase gets its own branch with tests first, a clean analyze, the whole suite passing, then README, AGENTS.md and the skills it touches. Phases stack until the owner merges.

| Phase | Branch | What | Status |
| --- | --- | --- | --- |
| 1. Catalog | `resources/` (no repo) | Labels, colours, 500 outfits, sample, build | **Done** October 19 |
| 2. Firebase | `feat/outfit_catalog` | Rules, emulator checks, upload to `in-vogue-dev` | **Done** October 19 (not committed) |
| 3. Catalog in the app | `feat/catalog_v2` | `OutfitCatalogRepository` with its phone copy, onboarding sample, Home browser, favourites as outfits, Shop for an outfit, six weather bands | **Done** October 19 (not merged) |
| 4. Recommender | `feat/stylist_engine` | Day bands (six), candidates, scorer, chooser, reasons, simulation | **Done** October 19 (not merged) |
| 5. On Home | `feat/stylist_on_home` | `MakeOutfit` integration, Day v2 fields, the widget; then remove the knowledge-base path | **Done** October 19 (not merged) |
| 6. Learning | `feat/stylist_signals` | Taste model, signals, Buy logging | **Done** October 19 (not merged) |
| 7. Wardrobe | `feat/wardrobe_on_home` | [§9](#9-onboarding-home-and-the-wardrobe): the person's own outfit at the bottom of the Today and Tomorrow tabs (owner) | **Done** October 19 (not merged) |

---

## 14. Risks

| Risk | Mitigation |
| --- | --- |
| A label is wrong | The curation tools re-check every rule; the owner can ask for any row to change; a rebuild and upload take minutes |
| The shop changes (new pieces, sold out) | Curate new styles with the same tools; the build fails on an unknown colourway; Buy links carry stock |
| A picture shows a coat-free look for a cold outfit (50 outfits) | Noted per outfit; the try-on includes the coat; the owner kept them ([§15](#15-decisions)) |
| Thin cells (Light Spring in Freezing) | Reported by `curate_outfits.py report`; the owner kept the catalog at 500 |
| Black-heavy catalog favours winter seasons | Outfits were chosen to balance seasons; the coverage table shows the rest |
| A signed-out person reads more than the sample | Rules checked on the emulators and live: only the sample and its pictures |
| Production | The upload script refuses any project but `in-vogue-dev`; production is the owner's |
| Forecast licence | Open-Meteo's commercial plan before production |

---

## 15. Decisions

**Made by the owner on October 19, 2026:**

- Claude preprocesses the catalog outside the app; it is stored in Firestore. The recommender only filters by colour season and weather and ranks; it never decides suitability. (This reverses "the catalog stays bundled" from AGENTS.md's "Not building" list.)
- A catalog item is an outfit Claude puts together from shop pieces, each piece buyable and tried on piece by piece; up to 4 pieces; about 500 outfits; plain descriptive names; the picture is the main piece's model photo, copied to Firebase Storage; the other pieces copy what the model wears when the shop sells them.
- Skin colours are the 12 colour seasons Mirror shows. Garment categories stay hidden.
- Weathers: Hot ≥ 26 · Warm 20–26 · Mild 14–20 · Cool 8–14 · Cold 0–8 · Freezing < 0 °C feels-like. A piece lists every weather it can be worn in, layered if needed. Skirts, dresses and shorts: bare legs only.
- Occasions, ticked: Work, Casual, Going out, Event, Staying in, Active.
- The piece fields of [Appendix A](#appendix-a-piece-fields); per colour: family, neutral or not, pattern.
- Onboarding: a fixed sample of 30–50 outfits readable without sign-in, picking optional, picks to the wishlist and the taste model, weighting similar outfits without forcing them. Home after sign-in: the whole catalog, paged, with favourites; nothing on that tab is chosen by the day's weather (the weather chips stay as filters the person taps, as decided later the same day).
- From the earlier proposal, still standing: never-suggested first above a quality floor within 15% of the day's best; a new outfit after a forecast change is offered, never made automatically; national holidays default to casual; the weekday routine is learned; Open-Meteo's commercial plan before production.

**Made by the owner later on October 19, 2026:**

- Setup's picks step keeps the weather at the top. Only the grid below changes: it shows the same sample outfits to everyone, independent of the weather, because picks record general taste.
- Home's Outfits tab keeps the weather chips as filters, now with the catalog's weathers.
- Tapping an outfit shows its pieces, their colours and the Buy links (the existing Shop screen does all three).
- The person's own outfit for the day goes at the bottom of the Today and Tomorrow tabs.
- The app is in development: nothing is migrated, and the old Firestore records are deleted.
- The Event and Active labels stay in the catalog's data, but the app does not implement them. The app's occasions stay as they are: Work, Casual, Going out and Staying in.
- When the skin analysis is unclear (the face photo was turned or badly lit, or no colours came back), the recommender ignores it, as it does when there is no analysis.
- The 50 cold-day outfits that show a knit look in their picture, with a coat added for the try-on, stay.
- An outfit's colour seasons come from its top or dress, and from its skirt or trousers when they aren't a neutral colour. A coat, jacket or cardigan worn over the top doesn't count, so a coat outside the person's palette can be recommended.
- The catalog stays at 500 outfits: nothing is added for the thin Freezing cells.

---

## Appendix A. Piece fields

The owner's list of October 19, as stored in `styles.v2.tsv`:

| # | Field | Values |
| --- | --- | --- |
| 1 | What it is (hidden) | tee, tank, cami, top, blouse, shirt, polo, henley, bodysuit, sweatshirt, hoodie, sweater, cardigan, sweater vest, trousers, jeans, shorts, skirt, leggings, joggers, dress, jumpsuit, overalls, blazer, jacket, overshirt, coat, trench, puffer, vest, liner; plus sleeve and length |
| 2 | How it's worn | on top, on the bottom, whole body, over a top (more than one when it can be either) |
| 3 | Weather | every one of Hot, Warm, Mild, Cool, Cold, Freezing it can be worn in, with no gaps |
| 4 | How warm | light, medium, warm, very warm |
| 5 | Rain | good, fine, avoid |
| 6 | Wind | fine, avoid |
| 7 | Occasions | Work, Casual, Going out, Event, Staying in, Active |
| 8 | How dressy | 1–5 |
| 9 | Style | up to two of classic, minimal, relaxed, sporty, romantic, edgy, boho, preppy, utility |
| 10 | Fit and shape | fitted, regular, relaxed, oversized; fitted, A-line, shift, slip, shirt, wrap, trapeze, column, skinny, slim, straight, tapered, wide, flare, barrel, bootcut, pencil, pleated, boxy |
| 11 | Fabric | main fibres; light, medium or heavy |
| 12 | Per colour | family, neutral or not, plain / striped / checked / printed (in `colours.v2.tsv`) |

## Appendix B. How colours got their seasons

1. **Character.** Each colour was judged from its name, measured CIELAB value and photos on three axes: light or deep, warm or cool, clear or soft. The 12 seasons each lead with one axis (Light Spring and Light Summer: light; Bright Spring and Bright Winter: clear; Soft Summer and Soft Autumn: soft; Dark Autumn and Dark Winter: deep; True Spring and True Autumn: warm; True Summer and True Winter: cool). A colour suits the seasons whose leading axis it matches and whose second axis it doesn't contradict.
2. **Neutrals in groups.** Black suits the three winters and Dark Autumn; optic white the winters, Bright Spring, True Summer and Light Summer; soft whites (bone, ivory) the springs, autumns and soft and light summers; navy every season but Light Spring, Light Summer, Soft and True Autumn; denim by wash (dark like navy, mid and light the summers, Light Spring and the winters).
3. **The app's palettes.** Every measured colour was compared with each season's 18 colours (CIEDE2000). A season was added where the palette holds a near-identical colour (ΔE00 ≤ 5): taupes and camels gained Light Spring (the cocoon coat's Heather Taupe is 2.1 from a Light Spring neutral), mid greys Bright Spring, light greys Dark Winter. A season was removed where the colour sits next to that season's avoid list: greyed mid and light denims lost True Spring (slate grey is a True Spring avoid).

## Appendix C. The outfit checks

`curate_outfits.py` refuses an outfit unless:

- it has a dress, jumpsuit or overalls (overalls may take a top), or one top and one bottom, plus at most two layers, four pieces in all, each colourway once;
- its weathers are contiguous and within every piece's weathers;
- Hot: every top and layer light, a bottom or dress at most medium; Warm: no coat or puffer and an upper-body warmth of at most 4 (light 1, medium 2, warm 3, very warm 4); Cool: upper-body warmth ≥ 2; Cold: a coat or jacket and warmth ≥ 4; Freezing: a warm coat and warmth ≥ 5. Outfits only for staying in skip the coat and layer checks;
- its occasions pass the occasion rule of [§5.4](#54-outfits) (coats are worn to any occasion and don't count);
- its colours suit at least one season under the colour rule of [§5.4](#54-outfits);
- its name is plain and at most 70 characters, and no other outfit has the same pieces.

## Appendix D. Taste features

Outfit-level, standardised over the catalog, each group alike in weight (colours 1–15, pattern 16–20, style 21–29, shape 30–39, fabric 40–41, dressiness and warmth 42–43, lounge 44), the whole about unit length. Shape, length and fibre come from the pieces' `shape`, `length` and `fibre` (catalog version 3, October 19); 40 is silk, the fibre:

1–15. Share of pieces in each colour family (black, white, cream, grey, beige, brown, navy, blue, green, olive, yellow, orange, red, pink, purple)
16. Neutral only
17. Tonal (one family)
18–20. Striped, checked, printed present
21–29. The nine styles
30. Dress or jumpsuit
31. Skirt
32. Shorts
33. Jeans
34. Wide or barrel leg
35. Mini length
36. Cropped top
37. A layer worn
38. A coat
39. Knitwear
40. Silk or satin
41. Linen
42. Dressiness
43. Warmth
44. Lounge (staying in)
45. Bias

## Appendix E. Research notes

The approaches considered (October 19), and why v2 is what it is:

| Approach | Fits In Vogue? |
| --- | --- |
| Knowledge- and constraint-based (Felfernig & Burke) | **Yes, the core.** Domain knowledge is strong, data scarce. In v2 the knowledge is curated per outfit. |
| Contextual bandits (LinUCB; Thompson sampling) | **Yes,** for taste: a few dozen numbers updated per signal, exploration built in. |
| Diversity re-ranking (MMR) | **Yes,** for alternatives. |
| Pretrained fashion embeddings (Marqo-FashionSigLIP, Apache-2.0) | Not needed now: the hand labels carry the attributes the embeddings would have estimated. Kept as an option for taste similarity. |
| Collaborative filtering, sequence models, learned outfit compatibility (Polyvore-trained) | No: they need training data, servers, or research-only licences. |
| MobileCLIP / MobileCLIP2 | Excluded: research-only weights. |
| An LLM on the phone | No: slow, nondeterministic. The LLM works offline instead, where its judgement is reviewed and stored. |

Clothing science informed the labels: published garment insulation values (ASHRAE 55, ISO 9920) and the UTCI clothing model (Havenith et al. 2012) for which weathers a fabric and weight suit; CIEDE2000 for colour closeness.

## Appendix F. Reproducing the evidence

- **Mislabelled pieces (D3, D4):** list `resources/catalog/everlane.women.json` by `garment` with `warmthBands` and `materialDescription`.
- **Outfits per cell (D1–D8):** join `assets/outfits/outfits.json` with the products by `id`; count colourways used (528 of 1,234) and dresses per top 10.
- **Band swings (D1):** Open-Meteo forecast API with `past_days=92`, hourly `apparent_temperature`, `timezone=auto`; per day, the band of the minimum and maximum over 07–19.
- **v2 coverage:** `python3 tools/catalog/curate_outfits.py report` and `build_outfit_catalog.py` in `resources/`.

## Appendix G. References

- Havenith G. et al. (2012). The UTCI-clothing model. *Int J Biometeorol* 56:461–470. doi:10.1007/s00484-011-0451-4
- Schiavon S., Lee K.H. (2013). Dynamic predictive clothing insulation models. *Building and Environment* 59:250–260. doi:10.1016/j.buildenv.2012.08.024
- ASHRAE 55 garment values, via pythermalcomfort: https://pythermalcomfort.readthedocs.io/en/latest/documentation/clothing.html
- Sharma G., Wu W., Dalal E.N. (2005). The CIEDE2000 color-difference formula. *Color Res Appl* 30(1):21–30.
- Felfernig A., Burke R. (2008). Constraint-based recommender systems. ICEC.
- Li L. et al. (2010). A contextual-bandit approach to personalized news article recommendation. WWW.
- Agrawal S., Goyal N. (2013). Thompson sampling for contextual bandits with linear payoffs. ICML.
- Carbonell J., Goldstein J. (1998). The use of MMR, diversity-based reranking. SIGIR.
- Open-Meteo forecast API: https://open-meteo.com/en/docs
- Firestore queries and rules: https://firebase.google.com/docs/firestore/query-data/queries · https://firebase.google.com/docs/firestore/security/rules-query
