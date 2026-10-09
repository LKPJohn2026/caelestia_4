.pragma library

// caelestia4: Gemini Interactions API (https://ai.google.dev/gemini-api/docs/interactions, GA, Google's
// recommended API; generateContent is now "legacy"). Pure JS so it can be tested outside Quickshell
// (tools/test-gemini-interactions.js). Used by InteractionsApiStrategy.qml.
//
// Requests are stateless (store: false): the whole chat is sent as a list of steps every turn, so editing,
// regenerating, switching models mid-chat and loading saved chats keep working like with the other providers.
// Model steps are kept exactly as the API returned them (message.providerSteps) and sent back unchanged, which
// is what Gemini 3 needs for thought signatures across function calls.
//
// Streaming (stream: true) is SSE: interaction.created, step.start / step.delta / step.stop per step,
// interaction.completed (usage, status "requires_action" when a function call waits), then "data: [DONE]".

// ---------------------------------------------------------------- request

function stripThink(text) {
    return (text || "").replace(/<think>[\s\S]*?<\/think>\s*/g, "").trim();
}

function copy(obj) {
    return JSON.parse(JSON.stringify(obj));
}

// messages: AiMessageData-like objects (role, rawContent, functionName, functionCall, functionResponse,
// localFilePath, providerSteps). pendingFilePath: file attached to the message being sent now.
// Returns { input: [Step], attachments: [path] }; attachments appear in input as { "__attach": index } and are
// filled in by the request script (base64 is too big for a QML string / command line).
function buildInput(messages, pendingFilePath) {
    const input = [];
    const attachments = [];
    const callIds = {}; // function name -> id of its latest call
    let lastUserInput = null;

    function attach(path) {
        if (!lastUserInput || !path)
            return;
        lastUserInput.content.push({ "__attach": attachments.length });
        attachments.push(path);
    }

    for (const m of messages) {
        if (m.role === "user" && m.functionName && m.functionName.length > 0) {
            input.push({
                "type": "function_result",
                "name": m.functionName,
                "call_id": callIds[m.functionName] ?? `call_${m.functionName}`,
                "result": [{ "type": "text", "text": (m.functionResponse && m.functionResponse.length > 0) ? m.functionResponse : "(no output)" }]
            });
            continue;
        }
        if (m.role === "user") {
            lastUserInput = { "type": "user_input", "content": [{ "type": "text", "text": m.rawContent ?? "" }] };
            input.push(lastUserInput);
            continue;
        }
        if (m.role !== "assistant")
            continue;
        // The assistant message of a turn holds the file the user attached to that turn
        if (m.localFilePath && m.localFilePath.length > 0)
            attach(m.localFilePath);
        const steps = m.providerSteps ?? [];
        if (steps.length > 0) {
            for (const step of steps) {
                if (step.type === "function_call")
                    callIds[step.name] = step.id;
                input.push(copy(step));
            }
        } else if (m.functionCall?.name) {
            const id = m.functionCall.id ?? `call_${m.functionCall.name}`;
            callIds[m.functionCall.name] = id;
            input.push({ "type": "function_call", "id": id, "name": m.functionCall.name, "arguments": m.functionCall.args ?? {} });
        } else {
            const text = stripThink(m.rawContent);
            if (text.length > 0 && !text.startsWith("**Error"))
                input.push({ "type": "model_output", "content": [{ "type": "text", "text": text }] });
        }
    }
    if (pendingFilePath && pendingFilePath.length > 0)
        attach(pendingFilePath);
    return { "input": input, "attachments": attachments };
}

// ---------------------------------------------------------------- streaming response

function newState() {
    return {
        steps: [],
        args: {}, // step index -> accumulated arguments_delta JSON
        thinkOpen: false,
        calls: [], // completed function calls { name, args, id }
        usage: null,
        sawSse: false,
        raw: "", // non-SSE body (HTTP errors come back as plain JSON)
        error: false
    };
}

function append(msg, text) {
    if (!text)
        return;
    msg.rawContent += text;
    msg.content += text;
}

function closeThink(st, msg) {
    if (!st.thinkOpen)
        return;
    append(msg, "\n</think>\n\n");
    st.thinkOpen = false;
}

function lastText(step) {
    if (!step.content)
        step.content = [];
    let last = step.content[step.content.length - 1];
    if (!last || last.type !== "text") {
        last = { "type": "text", "text": "" };
        step.content.push(last);
    }
    return last;
}

function addSources(msg, annotations) {
    const sources = [...(msg.annotationSources ?? [])];
    const notes = [...(msg.annotations ?? [])];
    for (const a of annotations ?? []) {
        if (a.type !== "url_citation" || !a.url)
            continue;
        notes.push({ "type": "url_citation", "start_index": a.start_index, "end_index": a.end_index, "text": a.title, "url": a.url });
        if (!sources.some(s => s.url === a.url))
            sources.push({ "type": "url_citation", "text": a.title || a.url, "url": a.url });
    }
    msg.annotationSources = sources;
    msg.annotations = notes;
}

function addQueries(msg, queries) {
    if (!queries || queries.length === 0)
        return;
    msg.searchQueries = [...(msg.searchQueries ?? []), ...queries.filter(q => !(msg.searchQueries ?? []).includes(q))];
}

function errorText(err) {
    const code = err?.code ?? err?.status ?? "";
    return `**Error${code ? " " + code : ""}**: ${err?.message ?? JSON.stringify(err)}`;
}

function handleDelta(st, ev, msg) {
    const step = st.steps[ev.index] ?? (st.steps[ev.index] = { "type": "model_output" });
    const d = ev.delta ?? {};
    switch (d.type) {
    case "text": {
        closeThink(st, msg);
        lastText(step).text += d.text ?? "";
        append(msg, d.text);
        break;
    }
    case "text_annotation_delta": {
        const t = lastText(step);
        t.annotations = [...(t.annotations ?? []), ...(d.annotations ?? [])];
        addSources(msg, d.annotations);
        break;
    }
    case "thought_signature":
        step.signature = (step.signature ?? "") + (d.signature ?? "");
        break;
    case "thought_summary": {
        step.summary = [...(step.summary ?? []), d.content];
        if (d.content?.type === "text" && d.content.text) {
            if (!st.thinkOpen) {
                append(msg, "<think>\n");
                st.thinkOpen = true;
            }
            append(msg, d.content.text);
        }
        break;
    }
    case "arguments_delta":
        st.args[ev.index] = (st.args[ev.index] ?? "") + (d.arguments ?? "");
        break;
    case "google_search_call":
        step.arguments = d.arguments;
        if (d.signature)
            step.signature = d.signature;
        addQueries(msg, d.arguments?.queries);
        break;
    default: {
        // Other tool deltas (google_search_result, url_context, …): merge into the step so it's resent as is
        for (const [k, v] of Object.entries(d)) {
            if (k === "type")
                continue;
            step[k] = Array.isArray(v) && Array.isArray(step[k]) ? [...step[k], ...v] : v;
        }
    }
    }
}

function handleStop(st, ev, msg) {
    const step = st.steps[ev.index];
    if (!step)
        return;
    if (step.type === "thought")
        closeThink(st, msg);
    if (step.type === "function_call") {
        let args = step.arguments;
        if (st.args[ev.index] !== undefined) {
            try {
                args = JSON.parse(st.args[ev.index] || "{}");
            } catch (e) {
                args = {};
            }
        }
        step.arguments = args ?? {};
        st.calls.push({ "name": step.name, "args": step.arguments, "id": step.id });
        closeThink(st, msg);
        append(msg, `\n\n[[ Function: ${step.name}(${JSON.stringify(step.arguments, null, 2)}) ]]\n`);
    }
    if (step.type === "google_search_call")
        addQueries(msg, step.arguments?.queries);
}

// One SSE event (parsed JSON). Returns { tokenUsage } when usage arrives.
function handleEvent(st, ev, msg) {
    switch (ev.event_type) {
    case "step.start":
        st.steps[ev.index] = copy(ev.step ?? {});
        if (ev.step?.type === "model_output")
            for (const c of ev.step.content ?? [])
                if (c.type === "text") {
                    append(msg, c.text);
                    addSources(msg, c.annotations);
                }
        return {};
    case "step.delta":
        handleDelta(st, ev, msg);
        return {};
    case "step.stop":
        handleStop(st, ev, msg);
        return {};
    case "interaction.completed": {
        closeThink(st, msg);
        const u = ev.interaction?.usage;
        if (u) {
            st.usage = { "input": u.total_input_tokens ?? -1, "output": (u.total_output_tokens ?? 0) + (u.total_thought_tokens ?? 0), "total": u.total_tokens ?? -1 };
            return { "tokenUsage": st.usage };
        }
        return {};
    }
    case "error":
        closeThink(st, msg);
        st.error = true;
        append(msg, (msg.rawContent.length > 0 ? "\n\n" : "") + errorText(ev.error));
        return {};
    default:
        return {}; // interaction.created / status_update / new event types: ignore
    }
}

// One stdout line from curl.
function handleLine(st, line, msg) {
    if (line.startsWith("data:")) {
        st.sawSse = true;
        const data = line.slice(5).trim();
        if (data === "[DONE]" || data.length === 0)
            return {};
        return handleEvent(st, JSON.parse(data), msg);
    }
    if (line.startsWith("event:") || line.startsWith("id:") || line.startsWith(":")) {
        st.sawSse = true;
        return {};
    }
    if (!st.sawSse)
        st.raw += line + "\n";
    return {};
}

// After curl exits. Returns { deferredFunctionCall, tokenUsage, finished }.
function finish(st, msg) {
    closeThink(st, msg);
    if (!st.sawSse && st.raw.trim().length > 0) {
        try {
            const body = JSON.parse(st.raw);
            const err = Array.isArray(body) ? body[0]?.error : body.error;
            append(msg, err ? errorText(err) : st.raw);
        } catch (e) {
            append(msg, st.raw);
        }
        st.error = true;
    }
    msg.providerSteps = st.error ? [] : st.steps.filter(s => s && s.type);
    const result = { "finished": true };
    if (st.usage)
        result.tokenUsage = st.usage;
    if (!st.error && st.calls.length > 0)
        result.deferredFunctionCall = st.calls[0];
    return result;
}
