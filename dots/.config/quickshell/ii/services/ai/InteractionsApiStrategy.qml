import QtQuick
import qs.modules.common.functions as CF
import "interactions.js" as Interactions

// caelestia4: Gemini through the Interactions API (api_format "gemini-interactions"), replacing end-4's
// generateContent strategy (GeminiApiStrategy, kept for user-defined "gemini" models). Logic in interactions.js.
// The key goes in the x-goog-api-key header (not the URL). The request body is written to a file with a heredoc
// and attachments are base64-inlined by jq, so big chats / images don't hit the command-line length limit.
ApiStrategy {
    id: root

    property var state: Interactions.newState()
    property var attachments: []
    property string endpoint
    property string body
    readonly property string workDir: "/tmp/quickshell/ai/interactions"

    function buildEndpoint(model: AiModel): string {
        root.endpoint = model.endpoint;
        return model.endpoint;
    }

    function buildRequestData(model: AiModel, messages, systemPrompt: string, temperature: real, tools: list<var>, filePath: string) {
        const built = Interactions.buildInput(messages, CF.FileUtils.trimFileProtocol(filePath ?? ""));
        root.attachments = built.attachments;
        let data = {
            "model": model.model,
            "input": built.input,
            "system_instruction": systemPrompt,
            "tools": tools ?? [],
            "generation_config": {
                "temperature": temperature,
                "thinking_summaries": "auto"
            },
            "stream": true,
            "store": false
        };
        if (model.extraParams)
            data = Object.assign({}, data, model.extraParams);
        root.body = JSON.stringify(data);
        return data;
    }

    function buildAuthorizationHeader(apiKeyEnvVarName: string): string {
        return `-H "x-goog-api-key: \$\{${apiKeyEnvVarName}\}"`;
    }

    function parseResponseLine(line, message) {
        return Interactions.handleLine(root.state, line, message);
    }

    function onRequestFinished(message) {
        return Interactions.finish(root.state, message);
    }

    function reset() {
        root.state = Interactions.newState();
        root.attachments = [];
    }

    // Attachments are handled in finalizeScriptContent (there can be several: earlier turns' files are resent)
    function buildScriptFileSetup(filePath) {
        return "";
    }

    // Replaces end-4's one-line `curl --data '<json>'` script with: body via heredoc, attachments inlined, curl
    // reading the body from the file.
    function finalizeScriptContent(scriptContent: string): string {
        const q = s => `'${CF.StringUtils.shellSingleQuoteEscape(s)}'`;
        let s = "#!/usr/bin/env bash\n";
        s += `dir=${q(root.workDir)}\nmkdir -p "$dir"\nrm -f "$dir"/att_*\n`;
        s += `cat > "$dir/request.json" <<'CAELESTIA4_JSON_EOF'\n${root.body}\nCAELESTIA4_JSON_EOF\n`;
        if (root.attachments.length > 0) {
            root.attachments.forEach((path, i) => {
                const n = String(i).padStart(3, "0");
                s += `f=${q(path)}\nout="$dir/att_${n}.json"\n`;
                s += 'if [ -r "$f" ]; then\n'
                    + '  mime=$(file -b --mime-type "$f")\n'
                    + '  case "$mime" in\n'
                    + '    image/*) t=image ;; audio/*) t=audio ;; video/*) t=video ;;\n'
                    + '    text/*|application/json|application/xml|application/x-shellscript) t=text ;;\n'
                    + '    *) t=document ;;\n'
                    + '  esac\n'
                    + '  if [ "$t" = text ]; then\n'
                    + '    jq -n --arg n "$(basename "$f")" --rawfile c "$f" \'{type: "text", text: ("File " + $n + ":\\n" + $c)}\' > "$out"\n'
                    + '  else\n'
                    + '    base64 -w0 "$f" > "$out.b64"\n'
                    + '    jq -n --arg t "$t" --arg m "$mime" --rawfile d "$out.b64" \'{type: $t, mime_type: $m, data: $d}\' > "$out"\n'
                    + '  fi\n'
                    + 'else\n'
                    + '  jq -n --arg n "$(basename "$f")" \'{type: "text", text: ("[attachment " + $n + " is no longer available]")}\' > "$out"\n'
                    + 'fi\n';
            });
            s += 'jq -s . "$dir"/att_*.json > "$dir/attachments.json"\n';
            s += 'jq --slurpfile a "$dir/attachments.json" \'walk(if type == "object" and has("__attach") then $a[0][.__attach] else . end)\' "$dir/request.json" > "$dir/request.full.json"\n';
        } else {
            s += 'cp "$dir/request.json" "$dir/request.full.json"\n';
        }
        s += `curl --no-buffer -sS ${q(root.endpoint)} -H 'Content-Type: application/json' ${buildAuthorizationHeader("API_KEY")} --data-binary @"$dir/request.full.json"\n`;
        return s;
    }
}
