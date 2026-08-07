#!/usr/bin/env python3
"""
NEXUS Data Ecosystem Agent - Automated data management with forecasting
Extends the NEXUS knowledge system with analytics and ML forecasting tools
"""

import os
import sqlite3
from typing import Annotated, Sequence
from typing_extensions import TypedDict

import pandas as pd
import numpy as np
from statsmodels.tsa.holtwinters import ExponentialSmoothing

from langchain_core.messages import BaseMessage, HumanMessage
from langchain_core.tools import tool
from langchain_openai import ChatOpenAI
from langgraph.prebuilt import ToolNode, tools_condition
from langgraph.graph import StateGraph, START

DB_PATH = os.path.expanduser("~/workspace/projects/nexus/data_ecosystem.db")

@tool
def manage_data_storage(action: str, table_name: str, payload_csv: str = None) -> str:
    """Manages data tracking and access. action: 'insert' or 'query'."""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    cursor.execute(f"""
        CREATE TABLE IF NOT EXISTS {table_name} (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
            metric_value REAL,
            category TEXT
        )
    """)
    conn.commit()

    try:
        if action == "insert" and payload_csv:
            rows = [row.split(',') for row in payload_csv.strip().split('\n') if row]
            cursor.executemany(f"INSERT INTO {table_name} (metric_value, category) VALUES (?, ?)", rows)
            conn.commit()
            return f"SUCCESS: Inserted {len(rows)} rows into '{table_name}'."
        elif action == "query":
            df = pd.read_sql_query(f"SELECT * FROM {table_name} ORDER BY timestamp DESC LIMIT 100", conn)
            return df.to_string()
        else:
            return "Invalid action. Use 'insert' or 'query'."
    except Exception as e:
        return f"ERROR: {str(e)}"
    finally:
        conn.close()

@tool
def analyze_and_aggregate(table_name: str) -> str:
    """Automated data processing with anomaly detection."""
    conn = sqlite3.connect(DB_PATH)
    try:
        df = pd.read_sql_query(f"SELECT * FROM {table_name}", conn)
        if df.empty:
            return "ANALYSIS FAILED: Table contains no data rows."
            
        summary = {
            "total_records": len(df),
            "mean_value": df['metric_value'].mean(),
            "max_value": df['metric_value'].max(),
            "min_value": df['metric_value'].min(),
            "std_deviation": df['metric_value'].std()
        }
        
        mean = summary["mean_value"]
        std = summary["std_deviation"] if not pd.isna(summary["std_deviation"]) else 0
        anomalies = df[np.abs(df['metric_value'] - mean) > (2 * std)]
        
        return (f"--- DATA ANALYSIS REPORT FOR {table_name} ---\n"
                f"Metrics Summary: {summary}\n"
                f"Anomalies Detected: {len(anomalies)} data points.")
    except Exception as e:
        return f"ERROR during analysis: {str(e)}"
    finally:
        conn.close()

@tool
def forecast_trends(table_name: str, steps_ahead: int = 5) -> str:
    """Holt-Winters Exponential Smoothing for time-series forecasting."""
    conn = sqlite3.connect(DB_PATH)
    try:
        df = pd.read_sql_query(f"SELECT metric_value FROM {table_name} ORDER BY id ASC", conn)
        if len(df) < 5:
            return "FORECAST FAILED: Need at least 5 records."
            
        data_series = df['metric_value'].values
        model_fit = ExponentialSmoothing(data_series, trend='add', seasonal=None).fit()
        predictions = model_fit.forecast(steps=steps_ahead)
        
        forecast_string = ", ".join([f"Step+{i+1}: {round(val, 4)}" for i, val in enumerate(predictions)])
        return f"Forecast for next {steps_ahead} periods:\n[{forecast_string}]"
    except Exception as e:
        return f"ERROR during forecasting: {str(e)}"
    finally:
        conn.close()

class AgentState(TypedDict):
    messages: Annotated[Sequence[BaseMessage], "The network messages"]

all_tools = [manage_data_storage, analyze_and_aggregate, forecast_trends]
tool_node = ToolNode(all_tools)

def get_graph():
    api_key = os.environ.get("OPENAI_API_KEY", "")
    if "sk-or-v1-" in api_key:
        llm = ChatOpenAI(
            model="anthropic/claude-3-haiku",
            temperature=0,
            openai_api_key=api_key,
            openai_api_base="https://openrouter.ai/api/v1"
        ).bind_tools(all_tools)
    elif os.environ.get("USE_LOCAL", "").lower() in ("1", "true", "yes"):
        from langchain_ollama import ChatOllama
        llm = ChatOllama(model="llama3.2:latest", temperature=0).bind_tools(all_tools)
    else:
        llm = ChatOpenAI(model="gpt-4o", temperature=0).bind_tools(all_tools)
    def call_agent(state: AgentState):
        return {"messages": [llm.invoke(state['messages'])]}
    builder = StateGraph(AgentState)
    builder.add_node("agent", call_agent)
    builder.add_node("tools", tool_node)
    builder.add_edge(START, "agent")
    builder.add_conditional_edges("agent", tools_condition)
    builder.add_edge("tools", "agent")
    return builder.compile()

def run_agent(prompt: str):
    graph = get_graph()
    inputs = {"messages": [HumanMessage(content=prompt)]}
    for output in graph.stream(inputs, stream_mode="values"):
        last_msg = output["messages"][-1]
        print(f"\n[{last_msg.type.upper()}]: {last_msg.content}")

def test_direct():
    """Test tools directly without LLM (no API key required)."""
    print("=== DIRECT TOOL TEST ===\n")
    
    mock_data = "10.2,sales\n12.5,sales\n11.1,sales\n14.8,sales\n15.2,sales\n19.0,sales"
    
    print("1. Inserting data:")
    print(manage_data_storage.invoke({"action": "insert", "table_name": "revenue_tracker", "payload_csv": mock_data}))
    
    print("\n2. Querying data:")
    print(manage_data_storage.invoke({"action": "query", "table_name": "revenue_tracker"}))
    
    print("\n3. Analysis:")
    print(analyze_and_aggregate.invoke({"table_name": "revenue_tracker"}))
    
    print("\n4. Forecasting:")
    print(forecast_trends.invoke({"table_name": "revenue_tracker", "steps_ahead": 3}))

if __name__ == "__main__":
    import sys
    if "--test" in sys.argv:
        test_direct()
    else:
        api_key = os.environ.get("OPENAI_API_KEY", "")
        use_local = os.environ.get("USE_LOCAL", "").lower() in ("1", "true", "yes")
        
        if not api_key and not use_local:
            print("No valid OPENAI_API_KEY or USE_LOCAL=1 found.")
            print("For LLM mode: export OPENAI_API_KEY='your-key' (or use OpenRouter key)")
            print("For local mode: export USE_LOCAL=1 (requires Ollama)")
            print("For direct tool testing: python3 data_agent.py --test")
            sys.exit(1)
        
        mock_data = "10.2,sales\n12.5,sales\n11.1,sales\n14.8,sales\n15.2,sales\n19.0,sales"
        prompt = (
            f"1. Insert this data into 'revenue_tracker' table:\n{mock_data}\n"
            "2. Run analysis on the metrics.\n"
            "3. Forecast the next 3 values."
        )
        run_agent(prompt)