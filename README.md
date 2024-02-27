# **🌐 Dynamics of Olson's Model: An ABM Exploration**

## **🔍 Overview**
Explore the intricate dynamics of political and economic behavior with **Dynamics of Olson's Model: An ABM Exploration**. Our simulation, developed in NetLogo, offers an immersive dive into Mancur Olson's Roving vs. Stationary Bandits Theory, providing a unique lens to view wealth distribution and bandit behavior in varying conditions. This delivers new perspectives on governance effects on society and the economy.

## **📚 Olson's Model: Key Theories**
In ['Dictatorship, Democracy, and Development'](https://www.jstor.org/stable/2938736) Mancur Olson postulates a theory identifying two types of bandits - roving and stationary. Roving bandits plunder wealth without concern for the long-term consequences, while stationary bandits act with less myopically, balancing their plundering (taxation) with the welfare of the taxed. This model offers a nuanced view of governance, economy, and societal interactions, setting the stage for our simulation.

## **📊 Model Description**
Our ABM simulation vividly brings to life the behaviors and decisions of both roaming and stationary bandits:
- **Agents**: Representing roving and stationary bandits, each with unique strategies and impacts on their territories.
- **Patches**: Simulating territories that bandits interact with, each possessing distinct wealth and growth potential.

### V1:


### V2: Aims to better model based on Olsons original article. 
- **Removes Fighting**: This makes it so instead of making fights occur based on variables, it occurs randomly. 
- **Patch Investment**: Patch investment rate is now a function of how much patches are taxed minus a base amount. Their investment rate will increase each tick they are not taxed by a certain amount, based on their optimism about the future.
- **Roam-Stat Bandits**: These bandits, which are roaming bandits that choose to remain stationary in spite of their lack of ability to invest in patch, are now identifiable. 
- **Movement Updates**: Now prevents roaming bandits from moving onto patches that are stationary as we assume stationary bandits are capable of protecting their lands. 
- **Updated Decision Making**: Now bandits will not choose between the best two move options and staying on their base patch. Rather they will just choose between the single best location and their current location

## **🌟 Scenarios**
### Baseline Scenario
A foundational setting where bandits operate under default parameters, establishing a benchmark for behavior and wealth distribution.

### [Additional Scenarios]
Detail Specific Scenarios conditions and modifications to explore different 'What If' Scenarios based on Olson's theory.

## **💡 Analysis**
Our simulation generates rich data, allowing for a comprehensive analysis of bandit strategies, wealth distribution, and territorial dynamics. It's a powerful tool for understanding the practical ramifications of theoretical models in political economics.

## **🚀 Future Model Updates**
Looking ahead, we plan to introduce more complexity into our simulation to further test and challenge Olson's theory:
- **Enhanced Decision-Making Algorithms**: For more sophisticated bandit behavior and interactions.
- **Complex Territorial Dynamics**: Introducing more nuanced growth and investment opportunities for territories.
- **Deeper Economic Variables**: To simulate a broader range of economic factors and their impact on the model.

