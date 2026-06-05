package com.argusoft.meetwise.agent;

public interface Agent {
    String getName();
    int getOrder();
    AgentOutput execute(AgentContext context);
}
