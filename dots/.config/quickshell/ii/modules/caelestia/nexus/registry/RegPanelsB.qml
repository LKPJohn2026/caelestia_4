import QtQuick
import Caelestia.Config
import Caelestia.I18n

// caelestia4: Nexus registry entries for the panels sub-pages other than the taskbar (dashboard, launcher, sidebar, utilities, session, osd, assistant, overview, cheatsheet) (merged by Registry.qml). See RegPanels.qml for the format.
// Owned by the panelsB group; filled in P5. The older entries of these pages stay in RegPanels.qml
QtObject {
    readonly property var entries: ({
            // Panels > Dashboard (pages/panels/DashboardPanel.qml)
            "c:paths.mediaGif": {
                route: "panels/dashboard",
                section: Tr.mark("Media card"),
                title: Tr.mark("Media GIF"),
                desc: Tr.mark("Animation next to the player on the dashboard. It moves while music plays"),
                keywords: [Tr.mark("dashboard"), Tr.mark("media"), Tr.mark("gif"), Tr.mark("animation"), Tr.mark("bongo cat"), Tr.mark("picture")],
                type: "path",
                pathMode: "file",
                filters: ["gif", "webp", "png", "apng"],
                requires: {
                    id: "c:dashboard.enabled",
                    value: true
                }
            },
            "c:general.mediaGifSpeedAdjustment": {
                route: "panels/dashboard",
                section: Tr.mark("Media card"),
                title: Tr.mark("Media GIF slowdown"),
                desc: Tr.mark("The GIF follows the music's beats per minute divided by this. Higher is slower"),
                keywords: [Tr.mark("dashboard"), Tr.mark("media"), Tr.mark("gif"), Tr.mark("speed"), Tr.mark("bpm"), Tr.mark("beat")],
                type: "real",
                min: 50,
                max: 1000,
                step: 10,
                requires: {
                    id: "c:dashboard.enabled",
                    value: true
                }
            },

            // Panels > Session menu (pages/panels/SessionPanel.qml)
            "c:paths.sessionGif": {
                route: "panels/session",
                section: Tr.mark("Look"),
                title: Tr.mark("Session menu GIF"),
                desc: Tr.mark("Animation between the buttons. Empty shows none"),
                keywords: [Tr.mark("session"), Tr.mark("gif"), Tr.mark("animation"), Tr.mark("picture"), Tr.mark("power menu")],
                type: "path",
                pathMode: "file",
                filters: ["gif", "webp", "png", "apng"],
                requires: {
                    id: "c:session.enabled",
                    value: true
                }
            },
            "c:general.sessionGifSpeed": {
                route: "panels/session",
                section: Tr.mark("Look"),
                title: Tr.mark("GIF speed"),
                desc: Tr.mark("How fast the session menu GIF plays. 100 % is normal speed"),
                keywords: [Tr.mark("session"), Tr.mark("gif"), Tr.mark("speed"), Tr.mark("animation")],
                type: "real",
                unit: "%",
                scale: 100,
                min: 0.1,
                max: 3,
                step: 0.05,
                requires: {
                    id: "c:session.enabled",
                    value: true
                }
            },
            "c:session.icons.logout": {
                route: "panels/session",
                section: Tr.mark("Button icons"),
                title: Tr.mark("Log out icon"),
                desc: Tr.mark("The picture on the log out button"),
                keywords: [Tr.mark("session"), Tr.mark("icon"), Tr.mark("logout"), Tr.mark("log out"), Tr.mark("button")],
                type: "string",
                validate: "^[a-z0-9_]+$",
                requires: {
                    id: "c:session.enabled",
                    value: true
                }
            },
            "c:session.icons.hibernate": {
                route: "panels/session",
                section: Tr.mark("Button icons"),
                title: Tr.mark("Hibernate icon"),
                desc: Tr.mark("The picture on the hibernate button"),
                keywords: [Tr.mark("session"), Tr.mark("icon"), Tr.mark("hibernate"), Tr.mark("button")],
                type: "string",
                validate: "^[a-z0-9_]+$",
                requires: {
                    id: "c:session.enabled",
                    value: true
                }
            },
            "c:session.icons.reboot": {
                route: "panels/session",
                section: Tr.mark("Button icons"),
                title: Tr.mark("Restart icon"),
                desc: Tr.mark("The picture on the restart button"),
                keywords: [Tr.mark("session"), Tr.mark("icon"), Tr.mark("reboot"), Tr.mark("restart"), Tr.mark("button")],
                type: "string",
                validate: "^[a-z0-9_]+$",
                requires: {
                    id: "c:session.enabled",
                    value: true
                }
            },
            "c:session.icons.shutdown": {
                route: "panels/session",
                section: Tr.mark("Button icons"),
                title: Tr.mark("Shut down icon"),
                desc: Tr.mark("The picture on the shut down button"),
                keywords: [Tr.mark("session"), Tr.mark("icon"), Tr.mark("shutdown"), Tr.mark("shut down"), Tr.mark("power"), Tr.mark("button")],
                type: "string",
                validate: "^[a-z0-9_]+$",
                requires: {
                    id: "c:session.enabled",
                    value: true
                }
            },
            "c:session.dragThreshold": {
                route: "panels/session",
                section: Tr.mark("General"),
                title: Tr.mark("Drag threshold"),
                desc: Tr.mark("How far to drag left from the right edge to open the session menu, or right to close it"),
                keywords: [Tr.mark("session"), Tr.mark("drag"), Tr.mark("swipe"), Tr.mark("threshold"), Tr.mark("edge")],
                type: "int",
                unit: "px",
                min: 0,
                max: 200,
                step: 5,
                requires: {
                    id: "c:session.enabled",
                    value: true
                }
            },

            // Panels > Launcher (pages/panels/LauncherPanel.qml)
            "e4:search.excludedSites": {
                route: "panels/launcher",
                section: Tr.mark("Search"),
                title: Tr.mark("Sites left out of web searches"),
                desc: Tr.mark("Web searches from the launcher and the Assistant skip these sites"),
                keywords: [Tr.mark("launcher"), Tr.mark("search"), Tr.mark("web"), Tr.mark("exclude"), Tr.mark("sites"), Tr.mark("block")],
                type: "list"
            },
            "e4:search.prefix.webSearch": {
                route: "panels/launcher",
                section: Tr.mark("Prefixes"),
                title: Tr.mark("Web search prefix"),
                desc: Tr.mark("Type this first to search the web"),
                keywords: [Tr.mark("launcher"), Tr.mark("search"), Tr.mark("prefix"), Tr.mark("web"), Tr.mark("google")],
                type: "string",
                validate: "\\S",
                advanced: true
            },
            "e4:search.prefix.action": {
                route: "panels/launcher",
                section: Tr.mark("Prefixes"),
                title: Tr.mark("Script action prefix"),
                desc: Tr.mark("Type this first to run built-in actions and your own scripts. Not the same as the action prefix above"),
                keywords: [Tr.mark("launcher"), Tr.mark("search"), Tr.mark("prefix"), Tr.mark("action"), Tr.mark("script"), Tr.mark("slash")],
                type: "string",
                validate: "\\S",
                advanced: true
            },
            "c:launcher.specialPrefix": {
                route: "panels/launcher",
                section: Tr.mark("Prefixes"),
                title: Tr.mark("App field search prefix"),
                desc: Tr.mark("Type this and a letter to search apps by one field, e.g. “@i ” for the app id, “@c ” for its category"),
                keywords: [Tr.mark("launcher"), Tr.mark("search"), Tr.mark("prefix"), Tr.mark("special"), Tr.mark("app id"), Tr.mark("category")],
                type: "string",
                validate: "^\\S+$",
                advanced: true,
                requires: {
                    id: "c:launcher.enabled",
                    value: true
                }
            },
            "e4:search.prefix.showDefaultActionsWithoutPrefix": {
                route: "panels/launcher",
                section: Tr.mark("Search"),
                title: Tr.mark("Offer command, maths and web search"),
                desc: Tr.mark("When no app matches, offer to run the text, calculate it or search the web for it"),
                keywords: [Tr.mark("launcher"), Tr.mark("search"), Tr.mark("fallback"), Tr.mark("command"), Tr.mark("math"), Tr.mark("web")],
                type: "bool"
            },
            "e4:search.sloppy": {
                route: "panels/launcher",
                section: Tr.mark("Search tuning"),
                title: Tr.mark("Loose matching for search results"),
                desc: Tr.mark("Score the extra results and clipboard history by spelling distance instead of fuzzy search. Often odd"),
                keywords: [Tr.mark("launcher"), Tr.mark("search"), Tr.mark("sloppy"), Tr.mark("levenshtein"), Tr.mark("clipboard"), Tr.mark("match")],
                type: "bool",
                advanced: true
            },
            "e4:search.nonAppResultDelay": {
                route: "panels/launcher",
                section: Tr.mark("Search tuning"),
                title: Tr.mark("Delay before extra results"),
                desc: Tr.mark("Wait this long after typing before showing maths, command and web results. Keeps typing smooth"),
                keywords: [Tr.mark("launcher"), Tr.mark("search"), Tr.mark("delay"), Tr.mark("lag"), Tr.mark("math"), Tr.mark("results")],
                type: "duration",
                unit: "ms",
                min: 0,
                max: 2000,
                step: 10,
                advanced: true
            },
            // caelestia4: an entry is a pattern only when it starts with ^ and ends with $ (utils/Strings.qml
            // testRegexList); anything else must be the exact app id
            "c:launcher.favouriteApps": {
                route: "panels/launcher",
                section: Tr.mark("Apps"),
                title: Tr.mark("Favourite apps"),
                desc: Tr.mark("Apps that come first in the launcher. To add one, open it in Apps and turn on “Favourite”"),
                keywords: [Tr.mark("launcher"), Tr.mark("favourite"), Tr.mark("favorite"), Tr.mark("pin"), Tr.mark("apps"), Tr.mark("regex")],
                type: "list"
            },
            "c:launcher.hiddenApps": {
                route: "panels/launcher",
                section: Tr.mark("Apps"),
                title: Tr.mark("Hidden apps"),
                desc: Tr.mark("Apps the launcher leaves out. To add one, open it in Apps and turn on “Hidden”"),
                keywords: [Tr.mark("launcher"), Tr.mark("hidden"), Tr.mark("hide"), Tr.mark("apps"), Tr.mark("regex")],
                type: "list"
            },
            // Row-less: launcher.actions is a list node whose `command` is a list, shown by x:launcher.actions as text.
            // caelestia4: `default` is the plugin's list with every LauncherAction key (Config/launcherconfig.hpp): its
            // items leave out `enabled` and most `dangerous`, which the list's nodes report, so an untouched list read
            // as changed
            "c:launcher.actions": {
                route: "panels/launcher",
                section: Tr.mark("Actions"),
                title: Tr.mark("Launcher actions"),
                desc: Tr.mark("What the action prefix lists: name, icon and the command each runs"),
                keywords: [Tr.mark("launcher"), Tr.mark("actions"), Tr.mark("commands"), Tr.mark("shortcuts")],
                type: "list",
                shownBy: "x:launcher.actions",
                default: Array.from(GlobalConfig.launcher.descriptorFor("actions").defaultValue ?? [], a => ({
                            enabled: a.enabled ?? true,
                            name: a.name ?? "",
                            icon: a.icon ?? "",
                            description: a.description ?? "",
                            command: Array.from(a.command ?? []),
                            dangerous: a.dangerous ?? false
                        }))
            },
            "x:launcher.actions": {
                route: "panels/launcher",
                section: Tr.mark("Actions"),
                title: Tr.mark("Launcher actions"),
                desc: Tr.mark("What the action prefix lists: name, icon and the command each runs (split on spaces, no shell)"),
                keywords: [Tr.mark("launcher"), Tr.mark("actions"), Tr.mark("commands"), Tr.mark("shortcuts")],
                type: "list",
                fields: [
                    {
                        key: "name",
                        title: Tr.mark("Name"),
                        type: "string"
                    },
                    {
                        key: "icon",
                        title: Tr.mark("Icon"),
                        type: "icon"
                    },
                    {
                        key: "description",
                        title: Tr.mark("Description"),
                        type: "string"
                    },
                    {
                        key: "command",
                        title: Tr.mark("Command"),
                        type: "string"
                    },
                    // caelestia4: "hidden" is the page's inverse of `enabled`, so an action added with "+" (its bools start
                    // off) shows in the launcher
                    {
                        key: "hidden",
                        title: Tr.mark("Hidden"),
                        type: "bool"
                    },
                    {
                        key: "dangerous",
                        title: Tr.mark("Dangerous"),
                        type: "bool"
                    }
                ]
            },

            // Panels > Sidebar (pages/panels/SidebarPanel.qml)
            "c:paths.noNotifsPic": {
                route: "panels/sidebar",
                section: Tr.mark("Look"),
                title: Tr.mark("No notifications picture"),
                desc: Tr.mark("Shown in the sidebar when there are no notifications"),
                keywords: [Tr.mark("sidebar"), Tr.mark("notifications"), Tr.mark("empty"), Tr.mark("picture"), Tr.mark("image"), Tr.mark("dino")],
                type: "path",
                pathMode: "file",
                filters: ["png", "svg", "jpg", "jpeg", "webp", "gif"],
                requires: {
                    id: "c:sidebar.enabled",
                    value: true
                }
            },
            "c:sidebar.minHoverThreshold": {
                route: "panels/sidebar",
                section: Tr.mark("General"),
                title: Tr.mark("Hover area height"),
                desc: Tr.mark("The top part of the right edge that opens the sidebar on hover is at least this tall"),
                keywords: [Tr.mark("sidebar"), Tr.mark("hover"), Tr.mark("edge"), Tr.mark("area"), Tr.mark("threshold")],
                type: "int",
                unit: "px",
                min: 0,
                max: 2000,
                step: 10,
                requires: {
                    id: "c:sidebar.showOnHover",
                    value: true
                }
            },

            // Panels > Assistant (pages/panels/AssistantPanel.qml)
            "e4:ai.extraModels": {
                route: "panels/assistant",
                section: Tr.mark("Prompt and models"),
                title: Tr.mark("Extra AI models"),
                desc: Tr.mark("Models added to the AI chat's model list, e.g. from OpenRouter"),
                keywords: [Tr.mark("ai"), Tr.mark("models"), Tr.mark("openrouter"), Tr.mark("llm"), Tr.mark("custom"), Tr.mark("endpoint")],
                type: "list",
                applies: "appRestart",
                advanced: true,
                fields: [
                    {
                        key: "name",
                        title: Tr.mark("Name"),
                        type: "string"
                    },
                    {
                        key: "model",
                        title: Tr.mark("Model id"),
                        type: "string"
                    },
                    {
                        key: "endpoint",
                        title: Tr.mark("Endpoint"),
                        type: "string"
                    },
                    {
                        key: "api_format",
                        title: Tr.mark("API format (openai, gemini, gemini-interactions, mistral)"),
                        type: "string"
                    },
                    {
                        key: "key_id",
                        title: Tr.mark("API key name"),
                        type: "string"
                    },
                    {
                        key: "requires_key",
                        title: Tr.mark("Needs an API key"),
                        type: "bool"
                    },
                    {
                        key: "description",
                        title: Tr.mark("Description"),
                        type: "string"
                    }
                ]
            },
            "e4:sidebar.ai.textFadeIn": {
                route: "panels/assistant",
                section: Tr.mark("Prompt and models"),
                title: Tr.mark("Fade in replies"),
                desc: Tr.mark("AI replies appear piece by piece with a fade"),
                keywords: [Tr.mark("ai"), Tr.mark("chat"), Tr.mark("fade"), Tr.mark("animation"), Tr.mark("text")],
                type: "bool",
                advanced: true
            },
            "e4:sidebar.translator.enable": {
                route: "panels/assistant",
                section: Tr.mark("Translator"),
                title: Tr.mark("Translator tab"),
                desc: Tr.mark("Show the Translator tab in the Assistant. Needs translate-shell"),
                keywords: [Tr.mark("translator"), Tr.mark("translate"), Tr.mark("tab"), Tr.mark("language")],
                type: "bool"
            },
            // caelestia4: "auto" (detect it / the system language) shows as an empty field with "Automatic": the page
            // provides x:assistant.translateFrom / translateTo over these, and an empty field saves "auto"
            "e4:language.translator.sourceLanguage": {
                route: "panels/assistant",
                section: Tr.mark("Translator"),
                title: Tr.mark("Translate from"),
                desc: Tr.mark("A language name or code, such as en or vi. Leave it empty to detect the language. Picking one in the tab changes this too"),
                keywords: [Tr.mark("translator"), Tr.mark("translate"), Tr.mark("source"), Tr.mark("language"), Tr.mark("from")],
                type: "string",
                shownBy: "x:assistant.translateFrom"
            },
            "x:assistant.translateFrom": {
                route: "panels/assistant",
                section: Tr.mark("Translator"),
                title: Tr.mark("Translate from"),
                desc: Tr.mark("A language name or code, such as en or vi. Leave it empty to detect the language. Picking one in the tab changes this too"),
                keywords: [Tr.mark("translator"), Tr.mark("translate"), Tr.mark("source"), Tr.mark("language"), Tr.mark("from")],
                type: "string",
                requires: {
                    id: "e4:sidebar.translator.enable",
                    value: true
                }
            },
            "e4:language.translator.targetLanguage": {
                route: "panels/assistant",
                section: Tr.mark("Translator"),
                title: Tr.mark("Translate to"),
                desc: Tr.mark("A language name or code, such as en or vi. Leave it empty for your system language. Picking one in the tab changes this too"),
                keywords: [Tr.mark("translator"), Tr.mark("translate"), Tr.mark("target"), Tr.mark("language"), Tr.mark("to")],
                type: "string",
                shownBy: "x:assistant.translateTo"
            },
            "x:assistant.translateTo": {
                route: "panels/assistant",
                section: Tr.mark("Translator"),
                title: Tr.mark("Translate to"),
                desc: Tr.mark("A language name or code, such as en or vi. Leave it empty for your system language. Picking one in the tab changes this too"),
                keywords: [Tr.mark("translator"), Tr.mark("translate"), Tr.mark("target"), Tr.mark("language"), Tr.mark("to")],
                type: "string",
                requires: {
                    id: "e4:sidebar.translator.enable",
                    value: true
                }
            },
            "e4:sidebar.translator.delay": {
                route: "panels/assistant",
                section: Tr.mark("Translator"),
                title: Tr.mark("Wait before translating"),
                desc: Tr.mark("How long typing must pause before the text is translated"),
                keywords: [Tr.mark("translator"), Tr.mark("translate"), Tr.mark("delay"), Tr.mark("typing")],
                type: "duration",
                unit: "ms",
                min: 0,
                max: 5000,
                step: 50,
                requires: {
                    id: "e4:sidebar.translator.enable",
                    value: true
                }
            },
            "e4:sidebar.booru.limit": {
                route: "panels/assistant",
                section: Tr.mark("Image sources"),
                title: Tr.mark("Images per page"),
                desc: Tr.mark("How many images the Anime tab loads at a time. waifu.im shows 30 at most"),
                keywords: [Tr.mark("anime"), Tr.mark("booru"), Tr.mark("images"), Tr.mark("limit"), Tr.mark("page")],
                type: "int",
                min: 1,
                max: 100,
                step: 1,
                advanced: true
            },
            // Row-less: a bit string ("010"), shown by x:assistant.wallhavenCategories as a list of categories
            "e4:sidebar.booru.wallhaven.categories": {
                route: "panels/assistant",
                section: Tr.mark("Image sources"),
                title: Tr.mark("Wallhaven categories"),
                desc: Tr.mark("Which kinds of pictures the Wallhaven source shows"),
                keywords: [Tr.mark("anime"), Tr.mark("wallhaven"), Tr.mark("categories"), Tr.mark("general"), Tr.mark("people")],
                type: "string",
                advanced: true,
                shownBy: "x:assistant.wallhavenCategories"
            },
            "x:assistant.wallhavenCategories": {
                route: "panels/assistant",
                section: Tr.mark("Image sources"),
                title: Tr.mark("Wallhaven categories"),
                desc: Tr.mark("Which kinds of pictures the Wallhaven source shows"),
                keywords: [Tr.mark("anime"), Tr.mark("wallhaven"), Tr.mark("categories"), Tr.mark("general"), Tr.mark("people")],
                type: "list",
                advanced: true,
                options: [
                    {
                        value: "general",
                        label: Tr.markCtx("General", "wallhaven category")
                    },
                    {
                        value: "anime",
                        label: Tr.markCtx("Anime", "wallhaven category")
                    },
                    {
                        value: "people",
                        label: Tr.markCtx("People", "wallhaven category")
                    }
                ]
            },
            "e4:sidebar.booru.wallhaven.sorting": {
                route: "panels/assistant",
                section: Tr.mark("Image sources"),
                title: Tr.mark("Wallhaven order"),
                desc: Tr.mark("Order of Wallhaven results when you search for tags. Without tags it shows the top list"),
                keywords: [Tr.mark("anime"), Tr.mark("wallhaven"), Tr.mark("sorting"), Tr.mark("order"), Tr.mark("random")],
                type: "enum",
                advanced: true,
                options: [
                    {
                        value: "relevance",
                        label: Tr.markCtx("Best match", "wallhaven sorting")
                    },
                    {
                        value: "date_added",
                        label: Tr.markCtx("Newest", "wallhaven sorting")
                    },
                    {
                        value: "views",
                        label: Tr.markCtx("Most viewed", "wallhaven sorting")
                    },
                    {
                        value: "favorites",
                        label: Tr.markCtx("Most favourites", "wallhaven sorting")
                    },
                    {
                        value: "toplist",
                        label: Tr.markCtx("Top list", "wallhaven sorting")
                    },
                    {
                        value: "random",
                        label: Tr.markCtx("Random", "wallhaven sorting")
                    }
                ]
            },
            // Row-less: end-4's default is the text "[unset]", shown by x:assistant.zerochanUsername as an empty field
            "e4:sidebar.booru.zerochan.username": {
                route: "panels/assistant",
                section: Tr.mark("Image sources"),
                title: Tr.mark("Zerochan user name"),
                desc: Tr.mark("Zerochan asks apps to send a user name. Sent with each Zerochan request"),
                keywords: [Tr.mark("anime"), Tr.mark("zerochan"), Tr.mark("username"), Tr.mark("user agent")],
                type: "string",
                advanced: true,
                shownBy: "x:assistant.zerochanUsername"
            },
            // caelestia4: the page maps "[unset]" to "" and an empty field back to "[unset]", so clearing the field is
            // the default (no modified dot)
            "x:assistant.zerochanUsername": {
                route: "panels/assistant",
                section: Tr.mark("Image sources"),
                title: Tr.mark("Zerochan user name"),
                desc: Tr.mark("Zerochan asks apps to send a user name. Sent with each Zerochan request"),
                keywords: [Tr.mark("anime"), Tr.mark("zerochan"), Tr.mark("username"), Tr.mark("user agent")],
                type: "string",
                advanced: true
            },
            "e4:workSafety.triggerCondition.networkNameKeywords": {
                route: "panels/launcher",
                section: Tr.mark("Work safety"),
                title: Tr.mark("Public Wi-Fi names"),
                desc: Tr.mark("Clipboard images are hidden only on a Wi-Fi whose name contains one of these words"),
                keywords: [Tr.mark("work safety"), Tr.mark("nsfw"), Tr.mark("wifi"), Tr.mark("network"), Tr.mark("public"), Tr.mark("keywords")],
                type: "list",
                requires: {
                    id: "e4:workSafety.enable.clipboard",
                    value: true
                }
            },
            "e4:workSafety.triggerCondition.linkKeywords": {
                route: "panels/launcher",
                section: Tr.mark("Work safety"),
                title: Tr.mark("Unsafe link words"),
                desc: Tr.mark("A clipboard image next to a copied link with one of these words is hidden"),
                keywords: [Tr.mark("work safety"), Tr.mark("nsfw"), Tr.mark("links"), Tr.mark("keywords"), Tr.mark("clipboard")],
                type: "list",
                requires: {
                    id: "e4:workSafety.enable.clipboard",
                    value: true
                }
            },

            // Panels > Overview & overlay (pages/panels/OverviewPanel.qml)
            "e4:overview.enable": {
                route: "panels/overview",
                section: Tr.mark("Workspace overview"),
                title: Tr.markCtx("Enabled", "toggle label"),
                desc: Tr.mark("Show the grid of workspaces when the overview is opened"),
                keywords: [Tr.mark("overview"), Tr.mark("enable"), Tr.mark("workspaces"), Tr.mark("expo"), Tr.mark("alt tab")],
                type: "bool"
            },
            "e4:overview.orderBottomUp": {
                route: "panels/overview",
                section: Tr.mark("Workspace overview"),
                title: Tr.mark("Fill from the bottom"),
                desc: Tr.mark("Workspace 1 is in the bottom row and numbers go up"),
                keywords: [Tr.mark("overview"), Tr.mark("order"), Tr.mark("bottom"), Tr.mark("grid"), Tr.mark("workspaces")],
                type: "bool",
                requires: {
                    id: "e4:overview.enable",
                    value: true
                }
            },
            "e4:overview.orderRightLeft": {
                route: "panels/overview",
                section: Tr.mark("Workspace overview"),
                title: Tr.mark("Fill from the right"),
                desc: Tr.mark("Workspace 1 is on the right and numbers go left"),
                keywords: [Tr.mark("overview"), Tr.mark("order"), Tr.mark("right"), Tr.mark("left"), Tr.mark("grid"), Tr.mark("workspaces")],
                type: "bool",
                requires: {
                    id: "e4:overview.enable",
                    value: true
                }
            },
            "e4:overlay.clickthroughOpacity": {
                route: "panels/overview",
                section: Tr.mark("Overlay widgets (Super+G)"),
                title: Tr.mark("Pinned widget opacity"),
                desc: Tr.mark("How visible pinned widgets stay while the overlay is closed"),
                keywords: [Tr.mark("overlay"), Tr.mark("opacity"), Tr.mark("pinned"), Tr.mark("transparent"), Tr.mark("widgets")],
                type: "real",
                unit: "%",
                scale: 100,
                min: 0.1,
                max: 1,
                step: 0.05
            },
            "e4:overlay.floatingImage.imageSource": {
                route: "panels/overview",
                section: Tr.mark("Overlay widgets (Super+G)"),
                title: Tr.mark("Floating image"),
                desc: Tr.mark("Picture or web address the floating image widget shows"),
                keywords: [Tr.mark("overlay"), Tr.mark("floating image"), Tr.mark("picture"), Tr.mark("gif"), Tr.mark("url")],
                type: "path",
                pathMode: "file",
                filters: ["png", "jpg", "jpeg", "webp", "gif", "svg"],
                advanced: true
            },

            // Panels > Keybind cheatsheet (pages/panels/CheatsheetPanel.qml)
            "e4:cheatsheet.superKey": {
                route: "panels/cheatsheet",
                section: Tr.mark("Keys"),
                title: Tr.mark("Super key label"),
                desc: Tr.mark("Text or Nerd Font icon shown for the Super key. Empty shows “Super”"),
                keywords: [Tr.mark("cheatsheet"), Tr.mark("keybinds"), Tr.mark("super"), Tr.mark("windows key"), Tr.mark("meta"), Tr.mark("label")],
                type: "string"
            },

            // Panels > Utilities (pages/panels/UtilitiesPanel.qml)
            "e4:osk.pinnedOnStartup": {
                route: "panels/utilities",
                section: Tr.mark("On-screen keyboard"),
                title: Tr.mark("Keyboard starts pinned"),
                desc: Tr.mark("Windows make room for the on-screen keyboard instead of going under it, until you unpin it"),
                keywords: [Tr.mark("on-screen keyboard"), Tr.mark("osk"), Tr.mark("pinned"), Tr.mark("virtual keyboard"), Tr.mark("touch")],
                type: "bool"
            }
        })
}
