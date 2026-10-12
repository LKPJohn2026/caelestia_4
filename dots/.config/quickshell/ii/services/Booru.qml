pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.services
import Quickshell;
import QtQuick;

/**
 * A service for interacting with various booru APIs.
 */
Singleton {
    id: root
    property Component booruResponseDataComponent: BooruResponseData {}

    signal tagSuggestion(string query, var suggestions)
    signal responseFinished()

    property string failMessage: Translation.tr("That didn't work. Tips:\n- Check your tags and NSFW settings\n- If you don't have a tag in mind, type a page number")
    property var responses: []
    property int runningRequests: 0
    property var defaultUserAgent: Config.options?.networking?.userAgent || "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36"
    // caelestia4: Wallhaven API key from the keyring (KeyringStorage apiKeys.wallhaven; /wallhavenkey in the Anime tab)
    readonly property string wallhavenApiKey: KeyringStorage.keyringData?.apiKeys?.wallhaven ?? ""
    // caelestia4: Gelbooru's API needs an API key + user ID (gelbooru.com > My Account > Options); /gelboorukey
    readonly property var gelbooruCredentials: KeyringStorage.keyringData?.apiKeys?.gelbooru ?? null
    function setGelbooruApiKey(apiKey, userId) {
        KeyringStorage.setNestedField(["apiKeys", "gelbooru"], apiKey ? { "apiKey": apiKey.trim(), "userId": (userId ?? "").trim() } : null);
    }
    // caelestia4: honest app User-Agent. danbooru's Cloudflare challenges fake browser UAs (403 "Just a moment"),
    // and zerochan asks API clients to identify themselves.
    readonly property string appUserAgent: "caelestia4-booru/1.0 (Quickshell; +https://github.com/end-4/dots-hyprland)"

    // caelestia4: zerochan's API currently answers HTTP 500 with a stray "{" before the JSON and page HTML after
    // it. Return the first complete, parseable JSON object in the text.
    function parseFirstJsonObject(text) {
        for (let start = text.indexOf("{"); start !== -1; start = text.indexOf("{", start + 1)) {
            let depth = 0, inString = false, escaped = false;
            for (let i = start; i < text.length; i++) {
                const c = text[i];
                if (inString) {
                    if (escaped) escaped = false;
                    else if (c === "\\") escaped = true;
                    else if (c === '"') inString = false;
                    continue;
                }
                if (c === '"') inString = true;
                else if (c === "{") depth++;
                else if (c === "}" && --depth === 0) {
                    try { return JSON.parse(text.substring(start, i + 1)); } catch (e) { break; }
                }
            }
        }
        throw new Error("no JSON object in response");
    }

    // caelestia4: say what went wrong instead of the generic tip
    readonly property string gelbooruKeyMessage: Translation.tr("Gelbooru now needs an API key. Get it at gelbooru.com > My Account > Options (API Access Credentials), then type: /gelboorukey <api_key> <user_id>")
    function errorMessageFor(status) {
        const site = providers[currentProvider]?.name ?? currentProvider;
        if (currentProvider === "gelbooru" && status === 401) return root.gelbooruKeyMessage;
        if (status === 0) return Translation.tr("Can't reach %1. Check your connection or try again later.").arg(site);
        if (status === 401 || status === 403) return Translation.tr("%1 refused the request (%2). It may need an API key or be blocking this app for now.").arg(site).arg(status);
        if (status === 404) return Translation.tr("Nothing found on %1 for that search.").arg(site);
        if (status === 429) return Translation.tr("%1 is rate-limiting requests. Wait a minute and try again.").arg(site);
        if (status >= 500) return Translation.tr("%1 is having server problems (%2). Try again later or switch provider.").arg(site).arg(status);
        return root.failMessage;
    }
    function setWallhavenApiKey(key) {
        KeyringStorage.setNestedField(["apiKeys", "wallhaven"], key.trim());
    }
    onCurrentProviderChanged: {
        if (["wallhaven", "gelbooru"].includes(currentProvider) && !KeyringStorage.loaded) KeyringStorage.fetchKeyringData(); // caelestia4
    }
    Component.onCompleted: {
        if (["wallhaven", "gelbooru"].includes(currentProvider) && !KeyringStorage.loaded) KeyringStorage.fetchKeyringData(); // caelestia4
    }

    property var providerList: Object.keys(providers).filter(provider => provider !== "system" && providers[provider].api)
    property var providers: {
        "system": { "name": Translation.tr("System") },
        "yandere": {
            "name": "yande.re",
            "url": "https://yande.re",
            "api": "https://yande.re/post.json",
            "description": Translation.tr("All-rounder | Good quality, decent quantity"),
            "mapFunc": (response) => {
                return response.map(item => {
                    return {
                        "id": item.id,
                        "width": item.width,
                        "height": item.height,
                        "aspect_ratio": item.width / item.height,
                        "tags": item.tags,
                        "rating": item.rating,
                        "is_nsfw": (item.rating != 's'),
                        "md5": item.md5,
                        "preview_url": item.preview_url,
                        "sample_url": item.sample_url ?? item.file_url,
                        "file_url": item.file_url,
                        "file_ext": item.file_ext,
                        "source": getWorkingImageSource(item.source) ?? item.file_url,
                    }
                })
            },
            "tagSearchTemplate": "https://yande.re/tag.json?order=count&limit=10&name={{query}}*",
            "tagMapFunc": (response) => {
                return response.map(item => {
                    return {
                        "name": item.name,
                        "count": item.count
                    }
                })
            }
        },
        "konachan": {
            "name": "Konachan",
            "url": "https://konachan.net",
            "api": "https://konachan.net/post.json",
            "description": Translation.tr("For desktop wallpapers | Good quality"),
            "mapFunc": (response) => {
                return response.map(item => {
                    return {
                        "id": item.id,
                        "width": item.width,
                        "height": item.height,
                        "aspect_ratio": item.width / item.height,
                        "tags": item.tags,
                        "rating": item.rating,
                        "is_nsfw": (item.rating != 's'),
                        "md5": item.md5,
                        "preview_url": item.preview_url,
                        "sample_url": item.sample_url ?? item.file_url,
                        "file_url": item.file_url,
                        "file_ext": item.file_ext,
                        "source": getWorkingImageSource(item.source) ?? item.file_url,
                    }
                })
            },
            "tagSearchTemplate": "https://konachan.net/tag.json?order=count&limit=10&name={{query}}*",
            "tagMapFunc": (response) => {
                return response.map(item => {
                    return {
                        "name": item.name,
                        "count": item.count
                    }
                })
            }
        },
        "zerochan": {
            "name": "Zerochan",
            "url": "https://www.zerochan.net",
            "api": "https://www.zerochan.net/?json",
            "description": Translation.tr("Clean stuff | Excellent quality, no NSFW"),
            "lenientJson": true, // caelestia4: see parseFirstJsonObject
            "acceptStatus": [500], // caelestia4: zerochan returns 500 together with valid data
            "mapFunc": (response) => {
                response = response.items
                return response.map(item => {
                    return {
                        "id": item.id,
                        "width": item.width,
                        "height": item.height,
                        "aspect_ratio": item.width / item.height,
                        "tags": item.tags.join(" "),
                        "rating": "safe", // Zerochan doesn't have nsfw
                        "is_nsfw": false,
                        "md5": item.md5,
                        "preview_url": item.thumbnail,
                        "sample_url": item.thumbnail,
                        "file_url": item.thumbnail,
                        "file_ext": "avif",
                        "source": getWorkingImageSource(item.source) ?? item.thumbnail,
                        "character": item.tag
                    }
                })
            }
        },
        "danbooru": {
            "name": "Danbooru",
            "url": "https://danbooru.donmai.us",
            "api": "https://danbooru.donmai.us/posts.json",
            "description": Translation.tr("The popular one | Best quantity, but quality can vary wildly"),
            "mapFunc": (response) => {
                return response.map(item => {
                    return {
                        "id": item.id,
                        "width": item.image_width,
                        "height": item.image_height,
                        "aspect_ratio": item.image_width / item.image_height,
                        "tags": item.tag_string,
                        "rating": item.rating,
                        "is_nsfw": (item.rating != 's'),
                        "md5": item.md5,
                        "preview_url": item.preview_file_url,
                        "sample_url": item.file_url ?? item.large_file_url,
                        "file_url": item.large_file_url,
                        "file_ext": item.file_ext,
                        "source": getWorkingImageSource(item.source) ?? item.file_url,
                    }
                })
            },
            "tagSearchTemplate": "https://danbooru.donmai.us/tags.json?limit=10&search[name_matches]={{query}}*",
            "tagMapFunc": (response) => {
                return response.map(item => {
                    return {
                        "name": item.name,
                        "count": item.post_count
                    }
                })
            }
        },
        "gelbooru": {
            "name": "Gelbooru",
            "url": "https://gelbooru.com",
            "api": "https://gelbooru.com/index.php?page=dapi&s=post&q=index&json=1",
            "description": Translation.tr("The hentai one | Great quantity, a lot of NSFW, quality varies wildly"),
            "mapFunc": (response) => {
                response = response.post
                return response.map(item => {
                    return {
                        "id": item.id,
                        "width": item.width,
                        "height": item.height,
                        "aspect_ratio": item.width / item.height,
                        "tags": item.tags,
                        "rating": item.rating.replace('general', 's').charAt(0),
                        "is_nsfw": (item.rating != 's'),
                        "md5": item.md5,
                        "preview_url": item.preview_url,
                        "sample_url": item.sample_url ?? item.file_url,
                        "file_url": item.file_url,
                        "file_ext": item.file_url.split('.').pop(),
                        "source": getWorkingImageSource(item.source) ?? item.file_url,
                    }
                })
            },
            "tagSearchTemplate": "https://gelbooru.com/index.php?page=dapi&s=tag&q=index&json=1&orderby=count&limit=10&name_pattern={{query}}%",
            "tagMapFunc": (response) => {
                return response.tag.map(item => {
                    return {
                        "name": item.name,
                        "count": item.count
                    }
                })
            }
        },
        // caelestia4: Wallhaven (wallpapers). API: https://wallhaven.cc/help/api . Anime category by default
        // (sidebar.booru.wallhaven.categories). The API key (keyring apiKeys.wallhaven, set with /wallhavenkey) unlocks
        // NSFW results and your account's settings; without it only SFW/sketchy content is returned.
        "wallhaven": {
            "name": "Wallhaven",
            "url": "https://wallhaven.cc",
            "api": "https://wallhaven.cc/api/v1/search",
            "description": Translation.tr("Wallpapers | Huge high-resolution library (anime category by default). NSFW needs an API key: /wallhavenkey"),
            "mapFunc": (response) => {
                return response.data.map(item => {
                    return {
                        "id": item.id,
                        "width": item.dimension_x,
                        "height": item.dimension_y,
                        "aspect_ratio": item.dimension_x / item.dimension_y,
                        "tags": [item.category, item.resolution, ...(item.colors ?? [])].join(" "),
                        "rating": item.purity === "sfw" ? "s" : item.purity === "sketchy" ? "q" : "e",
                        "is_nsfw": item.purity !== "sfw",
                        "md5": item.id,
                        "preview_url": item.thumbs.large,
                        "sample_url": item.thumbs.original,
                        "file_url": item.path,
                        "file_ext": (item.file_type ?? "image/jpeg").split("/")[1],
                        "source": item.url,
                    }
                })
            },
        },
        "waifu.im": {
            "name": "waifu.im",
            "url": "https://waifu.im",
            "api": "https://api.waifu.im/images",
            "description": Translation.tr("Waifus only | Excellent quality, limited quantity"),
            "mapFunc": (response) => {
                response = response.items
                return response.map(item => {
                    return {
                        "id": item.id,
                        "width": item.width,
                        "height": item.height,
                        "aspect_ratio": item.width / item.height,
                        "tags": item.tags.map(tag => {return tag.name}).join(" "),
                        "rating": item.isNsfw ? "e" : "s",
                        "is_nsfw": item.isNsfw,
                        "md5": item.md5,
                        "preview_url": item.sample_url ?? item.url, // preview_url just says access denied (maybe i fucked up and sent too many requests idk)
                        "sample_url": item.url,
                        "file_url": item.url,
                        "file_ext": item.extension,
                        "source": getWorkingImageSource(item.source) ?? item.url,
                    }
                })
            },
            "tagSearchTemplate": "https://api.waifu.im/tags?Name={{query}}",
            "tagMapFunc": (response) => {
                return response.items.map(item => {return {"name": item.name}})
            }
        },
        "t.alcy.cc": {
            "name": "Alcy",
            "url": "https://t.alcy.cc",
            "api": "https://t.alcy.cc/",
            "description": Translation.tr("Large images | God tier quality, no NSFW."),
            "fixedTags": [
                {
                    "name": "ycy",
                    "count": "General"
                },
                {
                    "name": "moez",
                    "count": "Moe"
                },
                {
                    "name": "ysz",
                    "count": "Genshin Impact"
                },
                {
                    "name": "fj",
                    "count": "Landscape"
                },
                {
                    "name": "bd",
                    "count": "Girl on white background"
                },
                {
                    "name": "xhl",
                    "count": "Shiggy"
                },
            ],
            "manualParseFunc": (responseText) => {
                // Alcy just returns image links, each on a new line
                // caelestia4: unknown categories answer "404 page not found"; keep only image URLs
                const lines = responseText.trim().split('\n').map(l => l.trim()).filter(l => /^https?:\/\/\S+\.(webp|jpe?g|png|gif|avif)$/i.test(l));
                return lines.map(line => {
                    return {
                        "id": Qt.md5(line),
                        // Alcy doesn't provide dimensions and images are often of god resolution
                        "width": 1000,
                        "height": 1000,
                        "aspect_ratio": 1,
                        "tags": "[no tags]",
                        "rating": "s",
                        "is_nsfw": false,
                        "md5": Qt.md5(line),
                        "preview_url": line,
                        "sample_url": line,
                        "file_url": line,
                        "file_ext": line.split('.').pop(),
                        "source": "",
                    }
                });
            },
        }
    }
    property var currentProvider: Persistent.states.booru.provider

    function getWorkingImageSource(url) {
        if (url?.includes('pximg.net')) {
            return `https://www.pixiv.net/en/artworks/${url.substring(url.lastIndexOf('/') + 1).replace(/_p\d+\.(png|jpg|jpeg|gif)$/, '')}`;
        }
        return url;
    }
    
    // caelestia4: forgiving provider lookup for /mode. Matches the key or the display name, ignoring case and
    // punctuation ("yande.re" -> yandere, "Waifu.im", "t.alcy.cc"), or a unique prefix ("wall" -> wallhaven).
    // Returns { key } or { matches: [...] } when ambiguous / nothing matched.
    function resolveProvider(query) {
        const norm = str => `${str ?? ""}`.toLowerCase().replace(/[^a-z0-9]/g, "");
        const q = norm(query);
        if (q.length === 0)
            return { matches: [] };
        const exact = providerList.find(k => norm(k) === q || norm(providers[k].name) === q);
        if (exact)
            return { key: exact };
        const prefix = providerList.filter(k => norm(k).startsWith(q) || norm(providers[k].name).startsWith(q));
        return prefix.length === 1 ? { key: prefix[0] } : { matches: prefix };
    }

    function providerChoices() {
        return providerList.map(k => `- ${k}${providers[k].name.toLowerCase() !== k ? ` (${providers[k].name})` : ""}`).join("\n");
    }

    function setProvider(provider) {
        const query = `${provider ?? ""}`.trim();
        if (query.length === 0) { // caelestia4: "/mode" alone shows the current provider instead of an error
            root.addSystemMessage(Translation.tr("Current provider: %1. Switch with /mode <name>:").arg(providers[currentProvider]?.name ?? currentProvider) + "\n" + root.providerChoices());
            return;
        }
        const found = root.resolveProvider(query);
        if (found.key) {
            provider = found.key
            Persistent.states.booru.provider = provider
            root.addSystemMessage(Translation.tr("Provider set to ") + providers[provider].name
                + (provider == "zerochan" ? Translation.tr(". Notes for Zerochan:\n- You must enter a color\n- Set your zerochan username in `sidebar.booru.zerochan.username` config option. You [might be banned for not doing so](https://www.zerochan.net/api#:~:text=The%20request%20may%20still%20be%20completed%20successfully%20without%20this%20custom%20header%2C%20but%20your%20project%20may%20be%20banned%20for%20being%20anonymous.)!") : ""))
        } else if (found.matches.length > 1) {
            root.addSystemMessage(Translation.tr("\"%1\" matches several providers: %2").arg(query).arg(found.matches.join(", ")))
        } else {
            root.addSystemMessage(Translation.tr("No provider called \"%1\". Choose one of:").arg(query) + "\n" + root.providerChoices())
        }
    }

    function clearResponses() {
        responses = []
    }

    function addSystemMessage(message) {
        responses = [...responses, root.booruResponseDataComponent.createObject(null, {
            "provider": "system",
            "tags": [],
            "page": -1,
            "images": [],
            "message": `${message}`
        })]
    }

    function constructRequestUrl(tags, nsfw=true, limit=20, page=1) {
        var provider = providers[currentProvider]
        var baseUrl = provider.api
        var url = baseUrl
        var tagString = tags.join(" ")
        if (!nsfw && !(["zerochan", "waifu.im", "t.alcy.cc", "wallhaven"].includes(currentProvider))) {
            if (currentProvider == "gelbooru") 
                tagString += " rating:general";
            else 
                tagString += " rating:safe";
        }
        var params = []
        // Tags & limit
        if (currentProvider === "zerochan") {
            if (tagString.trim().length > 0) // caelestia4: an empty "c=" makes zerochan answer with an error page
                params.push("c=" + tagString) // zerochan doesn't have search in api, so we use color
            params.push("l=" + limit)
            params.push("s=" + "fav")
            params.push("t=" + 1)
            params.push("p=" + page)
        }
        else if (currentProvider === "waifu.im") {
            var tagsArray = tagString.split(" ").filter(t => t.length > 0); // caelestia4: empty IncludedTags= -> 400
            tagsArray.forEach(tag => {
                params.push("IncludedTags=" + encodeURIComponent(tag.toLowerCase()));
            });
            params.push("PageSize=" + Math.min(limit, 30)) // Only admin can do > 30
            params.push("IsNsfw=" + (nsfw ? "All" : "False")) // null is random
        }
        else if (currentProvider === "wallhaven") { // caelestia4
            const wh = Config.options?.sidebar?.booru?.wallhaven
            const hasKey = (root.wallhavenApiKey ?? "").length > 0
            if (tagString.trim().length > 0) params.push("q=" + encodeURIComponent(tagString.trim()))
            params.push("categories=" + (wh?.categories ?? "010"))
            // purity bits: sfw, sketchy, nsfw. nsfw only works with an API key
            params.push("purity=" + (nsfw ? (hasKey ? "111" : "110") : "100"))
            params.push("sorting=" + (tagString.trim().length > 0 ? (wh?.sorting ?? "relevance") : "toplist"))
            params.push("page=" + page)
        }
        else if (currentProvider === "t.alcy.cc") {
            url += tagString.trim() || "pc" // caelestia4: needs a category; "pc" = landscape anime wallpapers
            params.push("json")
            params.push("quantity=" + limit)
        }
        else {
            params.push("tags=" + encodeURIComponent(tagString))
            params.push("limit=" + limit)
            if (currentProvider == "gelbooru") {
                params.push("pid=" + page)
                if (root.gelbooruCredentials?.apiKey) { // caelestia4: required since Gelbooru's API went key-only
                    params.push("api_key=" + encodeURIComponent(root.gelbooruCredentials.apiKey))
                    params.push("user_id=" + encodeURIComponent(root.gelbooruCredentials.userId))
                }
            }
            else {
                params.push("page=" + page)
            }
        }
        if (baseUrl.indexOf("?") === -1) {
            url += "?" + params.join("&")
        } else {
            url += "&" + params.join("&")
        }
        return url
    }

    function makeRequest(tags, nsfw=false, limit=20, page=1) {
        // caelestia4: Gelbooru answers 401 to every request without an API key; explain instead of failing
        if (currentProvider === "gelbooru" && KeyringStorage.loaded && !root.gelbooruCredentials?.apiKey) {
            root.addSystemMessage(root.gelbooruKeyMessage);
            return;
        }
        var url = constructRequestUrl(tags, nsfw, limit, page)
        console.log("[Booru] Making request to " + url)

        const newResponse = root.booruResponseDataComponent.createObject(null, {
            "provider": currentProvider,
            "tags": tags,
            "page": page,
            "images": [],
            "message": ""
        })

        var xhr = new XMLHttpRequest()
        xhr.open("GET", url)
        xhr.onreadystatechange = function() {
            const acceptedStatus = xhr.status === 200 || (providers[currentProvider]?.acceptStatus ?? []).includes(xhr.status) // caelestia4
            if (xhr.readyState === XMLHttpRequest.DONE && acceptedStatus) {
                try {
                    // console.log("[Booru] Raw response: " + xhr.responseText)
                    const provider = providers[currentProvider]
                    let response;
                    if (provider.manualParseFunc) {
                        response = provider.manualParseFunc(xhr.responseText)
                    } else {
                        response = provider.lenientJson ? root.parseFirstJsonObject(xhr.responseText) : JSON.parse(xhr.responseText) // caelestia4
                        response = provider.mapFunc(response)
                    }
                    // console.log("[Booru] Mapped response: " + JSON.stringify(response))
                    newResponse.images = response
                    newResponse.message = response.length > 0 ? "" : root.failMessage
                    
                } catch (e) {
                    console.log("[Booru] Failed to parse response: " + e)
                    newResponse.message = root.failMessage
                } finally {
                    root.runningRequests--;
                    root.responses = [...root.responses, newResponse]
                }
            }
            else if (xhr.readyState === XMLHttpRequest.DONE) {
                console.log("[Booru] Request failed with status: " + xhr.status)
                newResponse.message = root.errorMessageFor(xhr.status) // caelestia4
                root.runningRequests--;
                root.responses = [...root.responses, newResponse]
            }
            root.responseFinished()
        }

        try {
            // Required for danbooru and konachan
            if (currentProvider === "danbooru") { // caelestia4: app UA (Cloudflare blocks fake browser UAs)
                xhr.setRequestHeader("User-Agent", root.appUserAgent)
            }
            else if (currentProvider === "konachan") {
                xhr.setRequestHeader("User-Agent", defaultUserAgent)
            }
            else if (currentProvider == "wallhaven" && (root.wallhavenApiKey ?? "").length > 0) { // caelestia4
                xhr.setRequestHeader("X-API-Key", root.wallhavenApiKey)
            }
            else if (currentProvider == "zerochan") {
                const userAgent = Config.options?.sidebar?.booru?.zerochan?.username ? `Desktop sidebar booru viewer - username: ${Config.options.sidebar.booru.zerochan.username}` : root.appUserAgent // caelestia4: app UA
                xhr.setRequestHeader("User-Agent", userAgent)
            }
            root.runningRequests++;
            xhr.send()
        } catch (error) {
            console.log("Could not set User-Agent:", error)
        } 
    }

    property var currentTagRequest: null
    function triggerTagSearch(query) {
        if (currentTagRequest) {
            currentTagRequest.abort();
        }

        var provider = providers[currentProvider]
        if (provider.fixedTags) {
            root.tagSuggestion(query, provider.fixedTags)
            return provider.fixedTags;
        } else if (!provider.tagSearchTemplate) {
            return
        }
        var url = provider.tagSearchTemplate.replace("{{query}}", encodeURIComponent(query))

        var xhr = new XMLHttpRequest()
        currentTagRequest = xhr
        xhr.open("GET", url)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                currentTagRequest = null
                try {
                    // console.log("[Booru] Raw response: " + xhr.responseText)
                    var response = JSON.parse(xhr.responseText)
                    response = provider.tagMapFunc(response)
                    // console.log("[Booru] Mapped response: " + JSON.stringify(response))
                    root.tagSuggestion(query, response)
                } catch (e) {
                    console.log("[Booru] Failed to parse response: " + e)
                }
            }
            else if (xhr.readyState === XMLHttpRequest.DONE) {
                console.log("[Booru] Request failed with status: " + xhr.status)
            }
        }

        try {
            // Required for danbooru and konachan
            if (["danbooru", "konachan"].includes(currentProvider)) {
                xhr.setRequestHeader("User-Agent", defaultUserAgent)
            }
            xhr.send()
        } catch (error) {
            console.log("Could not set User-Agent:", error)
        } 
    }
}

