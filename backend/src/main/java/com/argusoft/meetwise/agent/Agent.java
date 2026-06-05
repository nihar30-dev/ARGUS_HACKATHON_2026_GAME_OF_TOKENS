package com.argusoft.meetwise.agent;

import com.argusoft.meetwise.agent.core.AgentType;

public interface Agent {

    String getName();

    int getOrder();

    AgentType getAgentType();

    AgentResult execute(AgentContext context);
}
