package com.argusoft.meetwise.agent;

import com.argusoft.meetwise.entity.MeetingRequest;
import lombok.Getter;
import lombok.RequiredArgsConstructor;

import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;

@RequiredArgsConstructor
public class AgentContext {

    @Getter
    private final MeetingRequest meetingRequest;

    private final Map<String, String> agentOutputs = new LinkedHashMap<>();

    public void putOutput(String agentName, String json) {
        agentOutputs.put(agentName, json);
    }

    public String getOutput(String agentName) {
        return agentOutputs.getOrDefault(agentName, "{}");
    }

    public boolean hasOutput(String agentName) {
        return agentOutputs.containsKey(agentName);
    }

    public Map<String, String> getAllOutputs() {
        return Collections.unmodifiableMap(agentOutputs);
    }
}
