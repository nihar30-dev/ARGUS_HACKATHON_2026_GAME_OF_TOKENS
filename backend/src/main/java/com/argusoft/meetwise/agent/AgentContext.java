package com.argusoft.meetwise.agent;

import com.argusoft.meetwise.agent.core.AgentTraceMessage;
import com.argusoft.meetwise.dto.KnowledgeChunkDto;
import com.argusoft.meetwise.entity.MeetingRequest;
import lombok.Getter;
import lombok.RequiredArgsConstructor;

import java.util.*;

@RequiredArgsConstructor
public class AgentContext {

    @Getter
    private final MeetingRequest meetingRequest;

    // Typed named slots — each agent writes to its designated slot
    @Getter private Map<String, Object> meetingContextData = new LinkedHashMap<>();
    @Getter private Map<String, Object> researchInsights   = new LinkedHashMap<>();
    @Getter private Map<String, Object> stakeholderProfile = new LinkedHashMap<>();
    @Getter private Map<String, Object> strategyDraft      = new LinkedHashMap<>();
    @Getter private Map<String, Object> objections         = new LinkedHashMap<>();
    @Getter private Map<String, Object> criticFeedback     = new LinkedHashMap<>();
    @Getter private Map<String, Object> refinedStrategy    = new LinkedHashMap<>();
    @Getter private Map<String, Object> finalSynthesis     = new LinkedHashMap<>();

    // Full results keyed by agent name
    private final Map<String, AgentResult>    agentResults  = new LinkedHashMap<>();

    // Rich trace messages accumulated during the pipeline
    private final List<AgentTraceMessage>     traceMessages = new ArrayList<>();

    // Raw JSON outputs (backward compat + DB persistence)
    private final Map<String, String>         agentOutputs  = new LinkedHashMap<>();

    // RAG context — refreshed by orchestrator before each applicable agent
    @Getter private List<KnowledgeChunkDto>   ragContext     = new ArrayList<>();

    // -----------------------------------------------------------------------
    // Write API
    // -----------------------------------------------------------------------

    /** Stores a result and keeps the raw-JSON map in sync. */
    public void putResult(String agentName, AgentResult result) {
        agentResults.put(agentName, result);
        if (result.getOutputJson() != null) {
            agentOutputs.put(agentName, result.getOutputJson());
        }
        updateTypedSlot(agentName, result.getOutput());
    }

    /** Legacy helper — stores raw JSON only (used by orchestrator before AgentResult existed). */
    public void putOutput(String agentName, String json) {
        agentOutputs.put(agentName, json);
    }

    public void addTraceMessage(AgentTraceMessage message) {
        traceMessages.add(message);
    }

    /** Replaces the current RAG context before each applicable agent runs. */
    public void setRagContext(List<KnowledgeChunkDto> context) {
        this.ragContext = context != null ? context : List.of();
    }

    /**
     * Returns a formatted, prompt-ready text block of the current RAG context.
     * Returns an empty string when no chunks are available.
     */
    public String getRagContextAsText() {
        if (ragContext == null || ragContext.isEmpty()) return "";
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < ragContext.size(); i++) {
            sb.append("Context ").append(i + 1).append(":\n")
              .append(ragContext.get(i).chunkText())
              .append("\n\n");
        }
        return sb.toString().trim();
    }

    // Typed slot setters (called automatically via putResult, or manually)
    public void setResearchInsights(Map<String, Object> data)   { this.researchInsights   = data; }
    public void setStakeholderProfile(Map<String, Object> data) { this.stakeholderProfile = data; }
    public void setStrategyDraft(Map<String, Object> data)      { this.strategyDraft      = data; }
    public void setObjections(Map<String, Object> data)         { this.objections         = data; }
    public void setCriticFeedback(Map<String, Object> data)     { this.criticFeedback     = data; }
    public void setRefinedStrategy(Map<String, Object> data)    { this.refinedStrategy    = data; }
    public void setFinalSynthesis(Map<String, Object> data)     { this.finalSynthesis     = data; }

    // -----------------------------------------------------------------------
    // Read API
    // -----------------------------------------------------------------------

    public String getOutput(String agentName) {
        return agentOutputs.getOrDefault(agentName, "{}");
    }

    public AgentResult getResult(String agentName) {
        return agentResults.get(agentName);
    }

    public boolean hasOutput(String agentName) {
        return agentOutputs.containsKey(agentName);
    }

    public Map<String, String> getAllOutputs() {
        return Collections.unmodifiableMap(agentOutputs);
    }

    public Map<String, AgentResult> getAllResults() {
        return Collections.unmodifiableMap(agentResults);
    }

    public List<AgentTraceMessage> getTraceMessages() {
        return Collections.unmodifiableList(traceMessages);
    }

    // -----------------------------------------------------------------------
    // Private helpers
    // -----------------------------------------------------------------------

    private void updateTypedSlot(String agentName, Map<String, Object> data) {
        if (data == null) return;
        switch (agentName) {
            case "OrganizationResearchAgent"  -> researchInsights   = data;
            case "StakeholderPersonaAgent"    -> stakeholderProfile = data;
            case "EngagementStrategyAgent"    -> strategyDraft      = data;
            case "ObjectionPredictionAgent"   -> objections         = data;
            case "CriticValidatorAgent"       -> criticFeedback     = data;
            case "StrategyRefinementAgent"    -> refinedStrategy    = data;
            case "FinalSynthesisAgent"        -> finalSynthesis     = data;
        }
    }
}
