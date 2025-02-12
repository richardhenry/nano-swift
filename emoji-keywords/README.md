# emoji-keywords

This is a script to scrape the HTML table of emoji keywords provided for each Unicode version at [unicode.org](https://www.unicode.org/emoji/charts-14.0/emoji-list.html), and produce a JSON file that allows an application to implement emoji search.

The output format is a single JSON object keyed on categories, where each emoji is represented by an array containing 3 elements:

* The emoji character
* An array of skintone variations of the character
* An array of keywords for the emoji

Here's an example:

```python
["✌️", ["✌🏻", "✌🏼", "✌🏽", "✌🏾", "✌🏿"], ["v", "hand", "fingers", "victory"]]
```

The category mapping is defined by `EMOJI_CATEGORY_MAP` in `fetch_emoji.py`.

## Updating the Included Emoji JSON

This repo includes a prefetched JSON file with Unicode 15.0 emoji.

To refetch the `data/emoji.json` file included in this repo, you can execute `fetch_emoji.py` like this:

```bash
./fetch_emoji.py --fe0f data/fe0f.csv --extra-keywords data/extra_keywords.csv --exclude data/exclude.csv --out data/emoji.json
```

The `data/emoji-min.json` file does not include newlines or indentation, and can be generated using the `--no-indent` flag.
