import QtQuick

QtObject {
    function buildEndpoint(model: AiModel): string { throw new Error("Not implemented") }
    function buildRequestData(model: AiModel, messages, systemPrompt: string, temperature: real, tools: list<var>, filePath: string) { throw new Error("Not implemented") }
    function buildAuthorizationHeader(apiKeyEnvVarName: string): string { throw new Error("Not implemented") }
    function parseResponseLine(line: string, message: AiMessageData) { throw new Error("Not implemented") }
    function onRequestFinished(message: AiMessageData): var { return {} } // Default: no special handling
    function reset() { } // Reset any internal state if needed
    function buildScriptFileSetup(filePath) { return "" } // Default: no setup
    function finalizeScriptContent(scriptContent: string): string { return scriptContent } // Optionally modify/finalize script
    // caelestia4: a curl option that sends the header "<name>: <prefix>$<envVarName>" from a file descriptor filled by
    // bash's printf (a builtin), so the key is never in an argument, which any process can read in /proc while curl runs
    function secretHeader(name: string, prefix: string, envVarName: string): string {
        return `-H @<(printf '${name}: ${prefix}%s\\n' "\$\{${envVarName}\}")`
    }
}
