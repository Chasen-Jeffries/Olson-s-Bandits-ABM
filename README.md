# Dynamics of Olson's Model: An ABM Exploration

## Overview
"Dynamics of Olson's Model: An ABM Exploration" is an Agent-Based Model (ABM) simulation implemented in NetLogo. It's designed to simulate Mancur Olson's Roaming vs. Stationary Bandits Theory. The simulation aims to explore the dynamics of the model and see if they align with Olson's theoretical outcomes, focusing on wealth distribution and behavior of bandits under different conditions.

## Features
- Simulation of roaming (Roam) and stationary (Stat) bandits with distinct behaviors.
- Dynamic wealth accumulation and taxation system for bandits and patches.
- Investment opportunities for bandits and self-investment by patches.
- Conflict resolution mechanics between bandits based on various factors.
- Visualization tools to observe wealth distribution and movements.

## Getting Started

### Prerequisites
- NetLogo 6.3.0 or later

### Installation
1. Clone the repository or download the source code.
2. Open the `.nlogo` file using NetLogo.

### Running the Simulation
1. Set the initial parameters using the NetLogo interface.
2. Press the 'setup' button to initialize the environment.
3. Press the 'go' button to start the simulation. Adjust parameters, pause and resume as needed.

## Model Description

### Agents
- **Bandits**: Agents representing either roaming (Roam) or stationary (Stat) bandits, each with unique attributes like wealth, strength, and taxation rate.

### Patches
- Represents territories with their own wealth, growth rates, and the ability to invest in themselves, enhancing their value over time.

### Dynamics
- **Roaming Bandits (Roam)**: Focus on moving to wealthier patches for taxation.
- **Stationary Bandits (Stat)**: Stay in a territory to tax and potentially invest in it.

### Key Procedures
- **setup**: Initializes the simulation environment.
- **go**: Main loop managing bandit and patch actions.
- **bandit-action**: Defines the actions of bandits each tick.
- **patch-action**: Manages patch growth and investment.

## Analysis
The simulation provides a breadth of data to analyze all aspects, including understanding the relationships between variables and outcomes. This data can be instrumental in studying the efficacy of different bandit strategies and their impact on wealth accumulation and territorial control.

## License
[Insert license info here]