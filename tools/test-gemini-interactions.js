#!/usr/bin/env node
// caelestia4: tests for services/ai/interactions.js (Gemini Interactions API) with SSE streams shaped like
// the API reference (https://ai.google.dev/api/interactions). Usage: node tools/test-gemini-interactions.js
const fs = require("fs");
const path = require("path");
const assert = require("assert");
const src = fs.readFileSync(path.join(__dirname, "../dots/.config/quickshell/ii/services/ai/interactions.js"), "utf8").replace(/^\.pragma library\s*/, "");
const I = new Function(src + "\nreturn { buildInput, newState, handleLine, finish, stripThink };")();

const msg = () => ({ rawContent: "", content: "", annotations: [], annotationSources: [], searchQueries: [], providerSteps: [] });
const sse = (lines, st, m) => { const out = []; for (const l of lines) out.push(I.handleLine(st, l, m)); return out; };
const ev = o => [`event: ${o.event_type}`, `data: ${JSON.stringify(o)}`, ""];

// 1. Thought summary + search + cited text + usage
{
  const st = I.newState(), m = msg();
  const lines = [
    ...ev({ event_type: "interaction.created", interaction: { id: "v1_x", status: "in_progress" } }),
    ...ev({ event_type: "step.start", index: 0, step: { type: "thought" } }),
    ...ev({ event_type: "step.delta", index: 0, delta: { type: "thought_summary", content: { type: "text", text: "Looking it up." } } }),
    ...ev({ event_type: "step.delta", index: 0, delta: { type: "thought_signature", signature: "c2lnMQ==" } }),
    ...ev({ event_type: "step.stop", index: 0 }),
    ...ev({ event_type: "step.start", index: 1, step: { type: "google_search_call", id: "s1", arguments: { queries: [] } } }),
    ...ev({ event_type: "step.delta", index: 1, delta: { type: "google_search_call", arguments: { queries: ["euro 2024 winner"] } } }),
    ...ev({ event_type: "step.stop", index: 1 }),
    ...ev({ event_type: "step.start", index: 2, step: { type: "google_search_result", call_id: "s1", result: [] } }),
    ...ev({ event_type: "step.delta", index: 2, delta: { type: "google_search_result", result: [{ search_suggestions: "<div/>" }] } }),
    ...ev({ event_type: "step.stop", index: 2 }),
    ...ev({ event_type: "step.start", index: 3, step: { type: "model_output" } }),
    ...ev({ event_type: "step.delta", index: 3, delta: { type: "text", text: "Spain won " } }),
    ...ev({ event_type: "step.delta", index: 3, delta: { type: "text", text: "Euro 2024." } }),
    ...ev({ event_type: "step.delta", index: 3, delta: { type: "text_annotation_delta", annotations: [{ type: "url_citation", url: "https://a.example/euro", title: "a.example", start_index: 0, end_index: 19 }] } }),
    ...ev({ event_type: "step.stop", index: 3 }),
    ...ev({ event_type: "interaction.completed", interaction: { id: "v1_x", status: "completed", usage: { total_tokens: 346, total_input_tokens: 11, total_output_tokens: 90, total_thought_tokens: 245 } } }),
    "event: done", "data: [DONE]"
  ];
  const results = sse(lines, st, m);
  assert.deepStrictEqual(results.find(r => r.tokenUsage).tokenUsage, { input: 11, output: 335, total: 346 });
  const r = I.finish(st, m);
  assert.strictEqual(m.content, "<think>\nLooking it up.\n</think>\n\nSpain won Euro 2024.");
  assert.deepStrictEqual(m.searchQueries, ["euro 2024 winner"]);
  assert.deepStrictEqual(m.annotationSources, [{ type: "url_citation", text: "a.example", url: "https://a.example/euro" }]);
  assert.strictEqual(m.providerSteps.length, 4);
  assert.strictEqual(m.providerSteps[0].signature, "c2lnMQ==");
  assert.deepStrictEqual(m.providerSteps[2].result, [{ search_suggestions: "<div/>" }]);
  assert.strictEqual(m.providerSteps[3].content[0].text, "Spain won Euro 2024.");
  assert.ok(!r.deferredFunctionCall && r.finished);
  console.log("ok 1 thought + search + citations + usage");
}

// 2. Function call with streamed arguments, then the next request's input
{
  const st = I.newState(), m = msg();
  sse([
    ...ev({ event_type: "step.start", index: 0, step: { type: "thought", signature: "" } }),
    ...ev({ event_type: "step.delta", index: 0, delta: { type: "thought_signature", signature: "c2ln" } }),
    ...ev({ event_type: "step.stop", index: 0 }),
    ...ev({ event_type: "step.start", index: 1, step: { type: "function_call", id: "fc_1", name: "run_shell_command", arguments: {} } }),
    ...ev({ event_type: "step.delta", index: 1, delta: { type: "arguments_delta", arguments: "{\"command\":" } }),
    ...ev({ event_type: "step.delta", index: 1, delta: { type: "arguments_delta", arguments: "\"uname -r\"}" } }),
    ...ev({ event_type: "step.stop", index: 1 }),
    ...ev({ event_type: "interaction.completed", interaction: { status: "requires_action" } }),
    "data: [DONE]"
  ], st, m);
  const r = I.finish(st, m);
  assert.deepStrictEqual(r.deferredFunctionCall, { name: "run_shell_command", args: { command: "uname -r" }, id: "fc_1" });
  assert.ok(m.content.includes("[[ Function: run_shell_command("));
  // History: user, assistant (with steps + attached file), function output, follow-up user
  const history = [
    { role: "user", rawContent: "kernel?" },
    { role: "assistant", rawContent: m.rawContent, providerSteps: m.providerSteps, functionCall: r.deferredFunctionCall, localFilePath: "/tmp/shot.png" },
    { role: "user", rawContent: "[[ Output of run_shell_command ]]", functionName: "run_shell_command", functionResponse: "7.2.9-2-cachyos\n" },
  ];
  const built = I.buildInput(history, "");
  assert.deepStrictEqual(built.attachments, ["/tmp/shot.png"]);
  assert.deepStrictEqual(built.input[0], { type: "user_input", content: [{ type: "text", text: "kernel?" }, { __attach: 0 }] });
  assert.strictEqual(built.input[1].type, "thought");
  assert.strictEqual(built.input[1].signature, "c2ln");
  assert.deepStrictEqual(built.input[2], { type: "function_call", id: "fc_1", name: "run_shell_command", arguments: { command: "uname -r" } });
  assert.deepStrictEqual(built.input[3], { type: "function_result", name: "run_shell_command", call_id: "fc_1", result: [{ type: "text", text: "7.2.9-2-cachyos\n" }] });
  console.log("ok 2 function call round trip");
}

// 3. Errors: SSE error event, and plain JSON HTTP error body
{
  let st = I.newState(), m = msg();
  sse([...ev({ event_type: "error", error: { message: "Deadline expired before operation could complete.", code: "gateway_timeout" } })], st, m);
  I.finish(st, m);
  assert.strictEqual(m.content, "**Error gateway_timeout**: Deadline expired before operation could complete.");
  assert.deepStrictEqual(m.providerSteps, []);
  st = I.newState(); m = msg();
  sse(["{", "  \"error\": {", "    \"code\": 400,", "    \"message\": \"API key not valid. Please pass a valid API key.\",", "    \"status\": \"INVALID_ARGUMENT\"", "  }", "}"], st, m);
  I.finish(st, m);
  assert.strictEqual(m.content, "**Error 400**: API key not valid. Please pass a valid API key.");
  console.log("ok 3 errors");
}

// 4. History from other models / legacy chats, pending attachment, think blocks stripped
{
  const built = I.buildInput([
    { role: "user", rawContent: "hi" },
    { role: "assistant", rawContent: "<think>\nhmm\n</think>\n\nHello!" },
    { role: "assistant", rawContent: "**Error 503**: overloaded" },
    { role: "user", rawContent: "what's this?" },
  ], "/tmp/a.pdf");
  assert.deepStrictEqual(built.input, [
    { type: "user_input", content: [{ type: "text", text: "hi" }] },
    { type: "model_output", content: [{ type: "text", text: "Hello!" }] },
    { type: "user_input", content: [{ type: "text", text: "what's this?" }, { __attach: 0 }] },
  ]);
  assert.deepStrictEqual(built.attachments, ["/tmp/a.pdf"]);
  console.log("ok 4 legacy history + pending file");
}
console.log("all passed");
